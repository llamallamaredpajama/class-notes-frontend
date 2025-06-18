import Foundation
import FirebaseAppCheck
import OSLog

/// App Check service using modern Swift concurrency and actor isolation
@globalActor
actor AppCheckActor {
    static let shared = AppCheckActor()
}

@AppCheckActor
final class AppCheckServiceV2 {
    static let shared = AppCheckServiceV2()
    
    private let logger = OSLog(subsystem: "com.classnotes", category: "Security")
    
    private init() {}
    
    /// Configure App Check with the appropriate provider
    func configure() {
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        let providerFactory = AppAttestProviderFactory()
        #endif
        
        AppCheck.setAppCheckProviderFactory(providerFactory)
        logger.info("App Check configured successfully")
    }
    
    /// Get App Check token for API requests
    func getToken() async throws -> String {
        guard let appCheck = AppCheck.appCheck() else {
            throw AppCheckError.notConfigured
        }
        
        do {
            // Use withCheckedThrowingContinuation to bridge callback-based API
            let token = try await withCheckedThrowingContinuation { continuation in
                appCheck.token(forcingRefresh: false) { token, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let token = token {
                        continuation.resume(returning: token.token)
                    } else {
                        continuation.resume(throwing: AppCheckError.noToken)
                    }
                }
            }
            
            logger.debug("App Check token retrieved successfully")
            return token
        } catch {
            logger.error("Failed to get App Check token: \(error)")
            throw AppCheckError.tokenRetrievalFailed(underlying: error)
        }
    }
    
    /// Force refresh the App Check token
    func refreshToken() async throws -> String {
        guard let appCheck = AppCheck.appCheck() else {
            throw AppCheckError.notConfigured
        }
        
        do {
            let token = try await withCheckedThrowingContinuation { continuation in
                appCheck.token(forcingRefresh: true) { token, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let token = token {
                        continuation.resume(returning: token.token)
                    } else {
                        continuation.resume(throwing: AppCheckError.noToken)
                    }
                }
            }
            
            logger.info("App Check token refreshed successfully")
            return token
        } catch {
            logger.error("Failed to refresh App Check token: \(error)")
            throw AppCheckError.tokenRetrievalFailed(underlying: error)
        }
    }
}

// MARK: - Error Types

enum AppCheckError: Error, LocalizedError {
    case notConfigured
    case noToken
    case tokenRetrievalFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "App Check is not configured"
        case .noToken:
            return "No App Check token available"
        case .tokenRetrievalFailed(let error):
            return "Failed to retrieve App Check token: \(error.localizedDescription)"
        }
    }
} 