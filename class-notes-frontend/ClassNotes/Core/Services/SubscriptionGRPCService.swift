import Foundation
import GeneratedProtos
import SwiftProtobuf

/// Service for managing user subscriptions using gRPC-Swift v2
@MainActor
final class SubscriptionGRPCService: ObservableObject {
    static let shared = SubscriptionGRPCService()

    @Published var subscriptionStatus: SubscriptionStatus?
    @Published var isLoading = false
    @Published var error: Error?

    private var grpcClient: GRPCClient?
    private var subscriptionClient: Classnotes_V1_SubscriptionService.Client?

    private init() {
        Task {
            await initialize()
        }
    }

    private func initialize() async {
        self.grpcClient = await GRPCClientProvider.shared.makeGRPCClient()
        self.subscriptionClient = Classnotes_V1_SubscriptionService.Client(
            wrapping: grpcClient!
        )
    }

    // MARK: - Receipt Validation

    /// Validate App Store receipt
    func validateReceipt(_ receiptData: Data) async throws -> SubscriptionValidation {
        guard let client = subscriptionClient else {
            throw GRPCError.transportNotInitialized
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let request = Classnotes_V1_ValidateReceiptRequest.with {
            $0.receiptData = receiptData
            $0.platform = .ios
        }

        do {
            let response = try await client.validateReceipt(request)

            // Update published status
            self.subscriptionStatus = SubscriptionStatus(from: response)

            return SubscriptionValidation(from: response)
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Subscription Status

    /// Get current subscription status
    func getSubscriptionStatus() async throws {
        guard let client = subscriptionClient else {
            throw GRPCError.transportNotInitialized
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let request = Classnotes_V1_GetSubscriptionStatusRequest()

        do {
            let response = try await client.getSubscriptionStatus(request)
            self.subscriptionStatus = SubscriptionStatus(from: response)
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Subscription Management

    /// Create a new subscription
    func createSubscription(
        planId: String,
        paymentToken: String
    ) async throws -> SubscriptionStatus {
        guard let client = subscriptionClient else {
            throw GRPCError.transportNotInitialized
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let request = Classnotes_V1_CreateSubscriptionRequest.with {
            $0.planID = planId
            $0.paymentToken = paymentToken
            $0.platform = .ios
        }

        do {
            let response = try await client.createSubscription(request)
            self.subscriptionStatus = SubscriptionStatus(from: response.subscription)
            return self.subscriptionStatus!
        } catch {
            self.error = error
            throw error
        }
    }

    /// Cancel subscription
    func cancelSubscription() async throws {
        guard let client = subscriptionClient else {
            throw GRPCError.transportNotInitialized
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let request = Classnotes_V1_CancelSubscriptionRequest()

        do {
            _ = try await client.cancelSubscription(request)

            // Refresh status after cancellation
            try await getSubscriptionStatus()
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Usage Information

    /// Get current usage statistics
    func getUsageStats() async throws -> UsageStats {
        guard let client = subscriptionClient else {
            throw GRPCError.transportNotInitialized
        }

        let request = Classnotes_V1_GetUsageStatsRequest()

        let response = try await client.getUsageStats(request)
        return UsageStats(from: response)
    }
}

// MARK: - Data Models

/// Subscription status model
struct SubscriptionStatus: Equatable {
    let isActive: Bool
    let tier: SubscriptionTier
    let expiresAt: Date?
    let autoRenewEnabled: Bool
    let gracePeriodEndsAt: Date?

    init(from proto: Classnotes_V1_SubscriptionStatus) {
        self.isActive = proto.isActive
        self.tier = SubscriptionTier(from: proto.tier)
        self.expiresAt = proto.hasExpiresAt ? proto.expiresAt.date : nil
        self.autoRenewEnabled = proto.autoRenewEnabled
        self.gracePeriodEndsAt = proto.hasGracePeriodEndsAt ? proto.gracePeriodEndsAt.date : nil
    }

    init(from proto: Classnotes_V1_ValidateReceiptResponse) {
        self.isActive = proto.isValid
        self.tier = SubscriptionTier(from: proto.subscriptionTier)
        self.expiresAt = proto.hasExpiresAt ? proto.expiresAt.date : nil
        self.autoRenewEnabled = proto.autoRenewEnabled
        self.gracePeriodEndsAt = nil
    }
}

/// Subscription tier
enum SubscriptionTier: String, CaseIterable {
    case free = "FREE"
    case basic = "BASIC"
    case premium = "PREMIUM"
    case enterprise = "ENTERPRISE"

    init(from proto: Classnotes_V1_SubscriptionTier) {
        switch proto {
        case .free:
            self = .free
        case .basic:
            self = .basic
        case .premium:
            self = .premium
        case .enterprise:
            self = .enterprise
        case .UNRECOGNIZED:
            self = .free
        }
    }

    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .basic:
            return "Basic"
        case .premium:
            return "Premium"
        case .enterprise:
            return "Enterprise"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "5 lessons per month",
                "Basic transcription",
                "Limited AI features",
            ]
        case .basic:
            return [
                "50 lessons per month",
                "Advanced transcription",
                "AI summaries",
                "PDF export",
            ]
        case .premium:
            return [
                "Unlimited lessons",
                "Priority transcription",
                "All AI features",
                "Cloud sync",
                "Collaboration",
            ]
        case .enterprise:
            return [
                "Everything in Premium",
                "Team management",
                "API access",
                "Priority support",
            ]
        }
    }
}

/// Subscription validation result
struct SubscriptionValidation {
    let isValid: Bool
    let tier: SubscriptionTier
    let expiresAt: Date?
    let message: String?

    init(from proto: Classnotes_V1_ValidateReceiptResponse) {
        self.isValid = proto.isValid
        self.tier = SubscriptionTier(from: proto.subscriptionTier)
        self.expiresAt = proto.hasExpiresAt ? proto.expiresAt.date : nil
        self.message = proto.message.isEmpty ? nil : proto.message
    }
}

/// Usage statistics
struct UsageStats {
    let lessonsThisMonth: Int
    let totalLessons: Int
    let storageUsedMB: Int
    let monthlyLimitLessons: Int?
    let monthlyLimitStorageMB: Int?

    init(from proto: Classnotes_V1_GetUsageStatsResponse) {
        self.lessonsThisMonth = Int(proto.lessonsThisMonth)
        self.totalLessons = Int(proto.totalLessons)
        self.storageUsedMB = Int(proto.storageUsedMb)
        self.monthlyLimitLessons =
            proto.hasMonthlyLimitLessons ? Int(proto.monthlyLimitLessons) : nil
        self.monthlyLimitStorageMB =
            proto.hasMonthlyLimitStorageMb ? Int(proto.monthlyLimitStorageMb) : nil
    }

    var isAtLessonLimit: Bool {
        guard let limit = monthlyLimitLessons else { return false }
        return lessonsThisMonth >= limit
    }

    var lessonUsagePercentage: Double? {
        guard let limit = monthlyLimitLessons, limit > 0 else { return nil }
        return Double(lessonsThisMonth) / Double(limit)
    }
}
