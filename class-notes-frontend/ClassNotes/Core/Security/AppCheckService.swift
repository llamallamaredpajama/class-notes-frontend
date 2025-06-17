// 1. Standard library
import Foundation

// 2. Apple frameworks
import CryptoKit
import OSLog

// 3. Third-party dependencies
import FirebaseCore
import FirebaseAppCheck

/// Service for managing App Check to protect APIs from abuse
@MainActor
final class AppCheckService: NSObject {
    // MARK: - Properties
    
    static let shared = AppCheckService()
    private var appCheck: AppCheck?
    @Published private(set) var isInitialized = false
    @Published private(set) var currentToken: String?
    
    // Token refresh timer
    private var tokenRefreshTimer: Timer?
    private let tokenRefreshInterval: TimeInterval = 3300 // 55 minutes (tokens last 1 hour)
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    /// Initialize App Check with the appropriate provider
    func initialize() {
        OSLog.security.functionEntry("AppCheckService.initialize")
        
        #if DEBUG
        // Use debug provider for development
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        // Use App Attest for production (iOS 14+) or Device Check as fallback
        let providerFactory: AppCheckProviderFactory
        if #available(iOS 14.0, *) {
            providerFactory = CustomAppAttestProviderFactory()
        } else {
            providerFactory = CustomDeviceCheckProviderFactory()
        }
        #endif
        
        AppCheck.setAppCheckProviderFactory(providerFactory)
        appCheck = AppCheck.appCheck()
        
        isInitialized = true
        
        // Get initial token
        Task {
            await refreshToken()
        }
        
        // Setup periodic token refresh
        setupTokenRefreshTimer()
        
        OSLog.security.info("App Check initialized successfully")
    }
    
    // MARK: - Public Methods
    
    /// Get current App Check token for API requests
    func getToken() async throws -> String {
        guard let appCheck = appCheck else {
            throw AppError.security("App Check not initialized")
        }
        
        do {
            let token = try await appCheck.token(forcingRefresh: false)
            currentToken = token.token
            
            OSLog.security.debug("App Check token retrieved", metadata: [
                "tokenLength": "\(token.token.count)"
            ])
            
            return token.token
        } catch {
            OSLog.security.error("Failed to get App Check token: \(error)")
            throw AppError.security("Failed to get App Check token: \(error.localizedDescription)")
        }
    }
    
    /// Force refresh the App Check token
    func refreshToken() async {
        guard let appCheck = appCheck else { return }
        
        do {
            let token = try await appCheck.token(forcingRefresh: true)
            currentToken = token.token
            
            OSLog.security.info("App Check token refreshed")
        } catch {
            OSLog.security.error("Failed to refresh App Check token: \(error)")
        }
    }
    
    /// Limited use token for specific operations
    func getLimitedUseToken() async throws -> String {
        guard let appCheck = appCheck else {
            throw AppError.security("App Check not initialized")
        }
        
        do {
            let token = try await appCheck.limitedUseToken()
            
            OSLog.security.debug("Limited use App Check token retrieved")
            
            return token.token
        } catch {
            OSLog.security.error("Failed to get limited use token: \(error)")
            throw AppError.security("Failed to get limited use token")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupTokenRefreshTimer() {
        tokenRefreshTimer?.invalidate()
        
        tokenRefreshTimer = Timer.scheduledTimer(
            withTimeInterval: tokenRefreshInterval,
            repeats: true
        ) { _ in
            Task { @MainActor in
                await self.refreshToken()
            }
        }
    }
    
    deinit {
        tokenRefreshTimer?.invalidate()
    }
}

// MARK: - Custom App Attest Provider Factory

@available(iOS 14.0, *)
class CustomAppAttestProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
}

// MARK: - Custom Device Check Provider Factory

class CustomDeviceCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return DeviceCheckProvider(app: app)
    }
}

// MARK: - App Error Extension

extension AppError {
    static func security(_ message: String) -> AppError {
        return AppError.authentication(message)
    }
} 