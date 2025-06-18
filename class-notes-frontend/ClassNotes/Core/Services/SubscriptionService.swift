// 1. Standard library
import Foundation
// 3. Third-party imports
import GRPCCore
import GRPCNIOTransportHTTP2
import OSLog
// 2. Apple frameworks
import StoreKit
import SwiftProtobuf

/// Service for managing subscriptions and in-app purchases
@MainActor
final class SubscriptionService: NSObject, ObservableObject {
    // MARK: - Properties

    static let shared = SubscriptionService()

    @Published private(set) var availableProducts: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    @Published private(set) var isProcessingPurchase = false
    @Published private(set) var error: Error?
    @Published private(set) var usageStatistics: UsageStatistics?

    private var updateListenerTask: Task<Void, Error>?
    private let keychainService = KeychainService.shared
    private let logger = OSLog.subscription
    private let baseURL = "https://api.classnotes.app"  // Will be configured from environment

    private let grpcClient: GRPCClient
    private let subscriptionClient: Classnotes_V1_SubscriptionService.Client

    // Product identifiers matching the Tier Management Guide
    enum ProductIdentifier: String, CaseIterable {
        case monthlyBasic = "com.classnotes.subscription.monthly.basic"
        case monthlyAdvanced = "com.classnotes.subscription.monthly.advanced"
        case monthlyPro = "com.classnotes.subscription.monthly.pro"
        case yearlyBasic = "com.classnotes.subscription.yearly.basic"
        case yearlyAdvanced = "com.classnotes.subscription.yearly.advanced"
        case yearlyPro = "com.classnotes.subscription.yearly.pro"

        var tier: SubscriptionTier {
            switch self {
            case .monthlyBasic, .yearlyBasic:
                return .basic
            case .monthlyAdvanced, .yearlyAdvanced:
                return .advanced
            case .monthlyPro, .yearlyPro:
                return .pro
            }
        }

        var isYearly: Bool {
            rawValue.contains("yearly")
        }
    }

    enum SubscriptionTier: String {
        case free = "FREE"
        case basic = "BASIC"
        case advanced = "ADVANCED"
        case pro = "PRO"

        var displayName: String {
            switch self {
            case .free: return "Free"
            case .basic: return "Basic"
            case .advanced: return "Advanced"
            case .pro: return "Pro"
            }
        }

        var monthlyPrice: String {
            switch self {
            case .free: return "$0"
            case .basic: return "$5.99"
            case .advanced: return "$17.99"
            case .pro: return "$34.99"
            }
        }
    }

    enum SubscriptionStatus: Equatable {
        case unknown
        case free
        case active(tier: SubscriptionTier, expiresAt: Date)
        case expired
        case cancelled(expiresAt: Date)
        case gracePeriod(tier: SubscriptionTier, expiresAt: Date)
    }

    struct UsageStatistics {
        let lecturesUsed: Int
        let lecturesLimit: Int
        let transcriptMinutesUsed: Int
        let transcriptMinutesLimit: Int
        let ocrPagesUsed: Int
        let ocrPagesLimit: Int
        let aiTokensUsedToday: Int
        let aiTokensDailyLimit: Int
        let storageUsedBytes: Int64
        let storageLimitBytes: Int64
        let nextResetDate: Date
        let recommendations: [String]

        var lectureUsagePercentage: Double {
            guard lecturesLimit > 0 else { return 0 }
            return Double(lecturesUsed) / Double(lecturesLimit) * 100
        }

        var storageUsagePercentage: Double {
            guard storageLimitBytes > 0 else { return 0 }
            return Double(storageUsedBytes) / Double(storageLimitBytes) * 100
        }
    }

    // MARK: - Initialization

    private init() {
        Task {
            self.grpcClient = await GRPCClientProvider.shared.makeGRPCClient()
            self.subscriptionClient = Classnotes_V1_SubscriptionService.Client(
                wrapping: grpcClient
            )
        }
        
        // Initialize with temporary client until async init completes
        self.grpcClient = GRPCClient(
            transport: EmptyTransport(),
            interceptors: []
        )
        self.subscriptionClient = Classnotes_V1_SubscriptionService.Client(
            wrapping: self.grpcClient
        )

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products and check status
        Task {
            await loadProducts()
            await refreshSubscriptionStatus()
        }
    }

    // MARK: - Public Methods

    /// Load available subscription products from the App Store
    func loadProducts() async {
        logger.info("Loading subscription products")

        do {
            let products = try await Product.products(
                for: ProductIdentifier.allCases.map { $0.rawValue }
            )

            await MainActor.run {
                self.availableProducts = products.sorted { $0.price < $1.price }
            }

            logger.info("Loaded \(products.count) products")
        } catch {
            logger.error("Failed to load products: \(error)")
            await MainActor.run {
                self.error = error
            }
        }
    }

    /// Purchase a subscription
    func purchase(_ product: Product) async throws {
        logger.info("Starting purchase for product: \(product.id)")

        await MainActor.run {
            isProcessingPurchase = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isProcessingPurchase = false
            }
        }

        // Initiate purchase
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Handle successful purchase
            let transaction = try checkVerified(verification)

            // Validate receipt with backend
            try await validateReceipt(transaction: transaction)

            // Finish the transaction
            await transaction.finish()

            // Refresh subscription status
            await refreshSubscriptionStatus()

            // Refresh usage statistics
            await refreshUsageStatistics()

            logger.info("Purchase successful for product: \(product.id)")

        case .userCancelled:
            logger.info("User cancelled purchase")
            throw SubscriptionError.purchaseCancelled

        case .pending:
            logger.info("Purchase pending")
            throw SubscriptionError.purchasePending

        @unknown default:
            throw SubscriptionError.unknownPurchaseResult
        }
    }

    /// Restore previous purchases
    func restorePurchases() async throws {
        logger.info("Starting purchase restoration")

        try await AppStore.sync()

        // Verify all transactions
        var restoredCount = 0

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Validate with backend
                try await validateReceipt(transaction: transaction)
                restoredCount += 1
            }
        }

        // Refresh subscription status
        await refreshSubscriptionStatus()

        logger.info("Restored \(restoredCount) purchases")

        if restoredCount == 0 {
            throw SubscriptionError.noPurchasesToRestore
        }
    }

    /// Register the current device
    func registerDevice() async throws {
        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else {
            throw SubscriptionError.deviceRegistrationFailed("Unable to get device ID")
        }

        let request = ClassNotes_V1_RegisterDeviceRequest.with {
            $0.deviceID = deviceID
            $0.deviceName = UIDevice.current.name
            $0.platform = "iOS"
            $0.osVersion = UIDevice.current.systemVersion
        }

        _ = try await performGRPCCall { client in
            try await client.registerDevice(request)
        }

        logger.info("Device registered successfully")
    }

    /// Validate receipt with backend
    private func validateReceipt(transaction: Transaction) async throws {
        logger.info("Validating receipt for transaction: \(transaction.id)")

        // For iOS 18.0+, use StoreKit 2 transaction data
        // The transaction itself contains all verification data needed
        var receiptString = ""
        
        if #available(iOS 15.0, *) {
            // Use StoreKit 2 approach - transaction already contains verification data
            // Convert transaction data to a format compatible with backend
            if let jsonData = try? JSONEncoder().encode(transaction),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                receiptString = Data(jsonString.utf8).base64EncodedString()
            } else {
                // Fallback to transaction ID if encoding fails
                receiptString = Data(String(transaction.id).utf8).base64EncodedString()
            }
        } else {
            // Legacy approach for older iOS versions
            guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
                FileManager.default.fileExists(atPath: appStoreReceiptURL.path)
            else {
                throw SubscriptionError.receiptNotFound
            }
            
            let receiptData = try Data(contentsOf: appStoreReceiptURL)
            receiptString = receiptData.base64EncodedString()
        }

        // Create validation request
        let request = ClassNotes_V1_ValidateReceiptRequest.with {
            $0.receiptData = receiptString
            $0.transactionID = String(transaction.id)
            $0.productID = transaction.productID
            $0.originalTransactionID = String(transaction.originalID)
            $0.purchaseDate = Google_Protobuf_Timestamp(date: transaction.purchaseDate)
            $0.originalPurchaseDate = Google_Protobuf_Timestamp(date: transaction.originalPurchaseDate)

            if let expirationDate = transaction.expirationDate {
                $0.expirationDate = Google_Protobuf_Timestamp(date: expirationDate)
            }
        }

        // Make gRPC call with retry logic
        let response = try await performGRPCCall { client in
            try await client.validateReceipt(request)
        }

        if response.isValid {
            logger.info("Receipt validated successfully - Tier: \(response.tier)")
        } else {
            throw SubscriptionError.invalidReceipt(response.rejectionReason)
        }
    }

    /// Refresh current subscription status from backend
    func refreshSubscriptionStatus() async {
        logger.info("Refreshing subscription status")

        do {
            let response = try await performGRPCCall { client in
                try await client.getSubscriptionStatus(Google_Protobuf_Empty())
            }

            await MainActor.run {
                self.subscriptionStatus = mapSubscriptionStatus(from: response)
            }

            logger.info(
                "Subscription status updated - Tier: \(response.tier), Status: \(response.status)")
        } catch {
            logger.error("Failed to refresh subscription status: \(error)")
            await MainActor.run {
                self.error = error
                // Default to free tier on error
                self.subscriptionStatus = .free
            }
        }
    }

    /// Refresh usage statistics
    func refreshUsageStatistics() async {
        do {
            let response = try await performGRPCCall { client in
                try await client.getUsageStatistics(Google_Protobuf_Empty())
            }

            await MainActor.run {
                self.usageStatistics = mapUsageStatistics(from: response)
            }

            logger.info("Usage statistics refreshed")
        } catch {
            logger.error("Failed to refresh usage statistics: \(error)")
        }
    }

    /// Perform gRPC call with authentication and retry logic
    private func performGRPCCall<T>(
        _ operation: @escaping (ClassNotes_V1_SubscriptionService.Client<HTTP2ClientTransport.Posix>) async throws -> T
    ) async throws -> T {
        // Get subscription client from the manager
        let client = try await GRPCClientManager.shared.getSubscriptionClient()
        
        // Perform the operation - retry is handled by the RetryInterceptor
        return try await operation(client)
    }

    /// Retry logic for network operations
    private func withRetry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                logger.warning("Attempt \(attempt) failed: \(error)")

                // Check if retryable
                if let rpcError = error as? RPCError {
                    switch rpcError.code {
                    case .unavailable, .deadlineExceeded, .unknown:
                        // Retryable - continue
                        break
                    default:
                        // Not retryable - throw immediately
                        throw error
                    }
                }

                // Wait before retry (exponential backoff)
                if attempt < maxAttempts {
                    try await Task.sleep(
                        nanoseconds: UInt64(delay * pow(2, Double(attempt - 1)) * 1_000_000_000))
                }
            }
        }

        throw lastError ?? SubscriptionError.unknownError
    }

    /// Check StoreKit verification result
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transaction updates
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Validate with backend
                    try await self.validateReceipt(transaction: transaction)

                    // Always finish transactions
                    await transaction.finish()

                    // Update subscription status
                    await self.refreshSubscriptionStatus()
                } catch {
                    self.logger.error("Transaction update failed: \(error)")
                }
            }
        }
    }

    /// Map backend response to subscription status
    private func mapSubscriptionStatus(from response: ClassNotes_V1_SubscriptionStatusResponse)
        -> SubscriptionStatus
    {
        guard let tier = SubscriptionTier(rawValue: response.tier) else {
            return .free
        }

        let expiresAt = response.expiresAt.date

        switch response.status {
        case "ACTIVE":
            return .active(tier: tier, expiresAt: expiresAt)
        case "EXPIRED":
            return .expired
        case "CANCELLED":
            return .cancelled(expiresAt: expiresAt)
        case "GRACE_PERIOD":
            return .gracePeriod(tier: tier, expiresAt: expiresAt)
        default:
            return .free
        }
    }

    /// Map backend response to usage statistics
    private func mapUsageStatistics(from response: ClassNotes_V1_UsageStatisticsResponse)
        -> UsageStatistics
    {
        return UsageStatistics(
            lecturesUsed: Int(response.usage.lecturesUsed),
            lecturesLimit: Int(response.usage.lecturesLimit),
            transcriptMinutesUsed: Int(response.usage.transcriptMinutesUsed),
            transcriptMinutesLimit: Int(response.usage.transcriptMinutesLimit),
            ocrPagesUsed: Int(response.usage.ocrPagesUsed),
            ocrPagesLimit: Int(response.usage.ocrPagesLimit),
            aiTokensUsedToday: Int(response.usage.aiTokensUsedToday),
            aiTokensDailyLimit: Int(response.usage.aiTokensDailyLimit),
            storageUsedBytes: response.usage.storageUsedBytes,
            storageLimitBytes: response.usage.storageLimitBytes,
            nextResetDate: response.nextResetDate.date,
            recommendations: response.recommendations
        )
    }

    deinit {
        updateListenerTask?.cancel()
    }
}

// MARK: - Error Types

enum SubscriptionError: LocalizedError {
    case receiptNotFound
    case notAuthenticated
    case verificationFailed
    case invalidReceipt(String)
    case validationFailed(Error)
    case purchaseCancelled
    case purchasePending
    case unknownPurchaseResult
    case noPurchasesToRestore
    case deviceRegistrationFailed(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .receiptNotFound:
            return "Purchase receipt not found"
        case .notAuthenticated:
            return "Please sign in to purchase a subscription"
        case .verificationFailed:
            return "Purchase verification failed"
        case .invalidReceipt(let reason):
            return "Invalid receipt: \(reason)"
        case .validationFailed(let error):
            return "Validation failed: \(error.localizedDescription)"
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .unknownPurchaseResult:
            return "Unknown purchase result"
        case .noPurchasesToRestore:
            return "No purchases to restore"
        case .deviceRegistrationFailed(let reason):
            return "Device registration failed: \(reason)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

// MARK: - SwiftProtobuf Extensions
extension SwiftProtobuf.Google_Protobuf_Timestamp {
    init(date: Date) {
        let seconds = Int64(date.timeIntervalSince1970)
        let nanos = Int32((date.timeIntervalSince1970 - Double(seconds)) * 1_000_000_000)
        self.init(seconds: seconds, nanos: nanos)
    }
    
    var date: Date {
        return Date(timeIntervalSince1970: Double(seconds) + Double(nanos) / 1_000_000_000)
    }
}

// MARK: - Empty Transport

/// Temporary transport for initialization
private struct EmptyTransport: ClientTransport {
    func connect(lazily: Bool) async throws -> any Streaming {
        throw GRPCError.transportNotInitialized
    }
    
    func close() async {
        // No-op
    }
}


