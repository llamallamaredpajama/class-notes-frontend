// Standard library
import Foundation
// Third-party dependencies
import GRPCCore
import OSLog

/// Interceptor for handling Firebase App Check in gRPC requests
/// Automatically adds App Check tokens to protect against abuse
struct AppCheckInterceptor: ClientInterceptor, Sendable {

    // MARK: - Properties

    private let logger: OSLog
    private let requireAppCheck: Bool

    // MARK: - Initialization

    init(
        requireAppCheck: Bool = true,
        logger: OSLog = OSLog(subsystem: "com.classnotes", category: "Security")
    ) {
        self.requireAppCheck = requireAppCheck
        self.logger = logger
    }

    // MARK: - ClientInterceptor Protocol

    func intercept<Input: Sendable, Output: Sendable>(
        request: ClientRequest<Input>,
        context: ClientContext,
        next: @Sendable (
            ClientRequest<Input>,
            ClientContext
        ) async throws -> ClientResponse<Output>
    ) async throws -> ClientResponse<Output> {
        
        // Collect headers to add
        var headers: [(String, String)] = []
        
        // Add existing metadata
        for (key, values) in request.metadata {
            for value in values {
                headers.append((key, value))
            }
        }
        
        do {
            // Get App Check token
            let token = try await AppCheckServiceV2.shared.getToken()
            logger.debug("Retrieved App Check token for \(context.descriptor.fullyQualifiedMethod)")
            
            // Add App Check token to headers
            headers.append((Constants.appCheckHeader, token))
            
            // Add additional security headers
            headers.append((Constants.platformHeader, Constants.platform))
            headers.append((Constants.bundleIdHeader, Bundle.main.bundleIdentifier ?? "unknown"))
            
        } catch {
            logger.error("Failed to retrieve App Check token: \(error)")
            
            // Decide whether to continue without token based on configuration
            if requireAppCheck {
                #if DEBUG
                    logger.warning("App Check required but failed in DEBUG mode - continuing anyway")
                    // In debug mode, add a debug token header
                    headers.append((Constants.debugTokenHeader, "debug-token"))
                #else
                    // Fail the request in production if App Check is required
                    throw AppCheckError.tokenRetrievalFailed(underlying: error)
                #endif
            } else {
                logger.debug("App Check failed but not required - continuing without token")
            }
        }
        
        // Create new metadata with all headers
        let newMetadata = Metadata(headers)
        
        // Create new request with updated metadata
        let modifiedRequest = ClientRequest(
            message: request.message,
            metadata: newMetadata
        )
        
        // Execute the request with modified headers
        return try await next(modifiedRequest, context)
    }
}

// MARK: - Constants

extension AppCheckInterceptor {
    fileprivate enum Constants {
        static let appCheckHeader = "X-Firebase-AppCheck"
        static let platformHeader = "X-Client-Platform"
        static let bundleIdHeader = "X-Bundle-ID"
        static let debugTokenHeader = "X-Debug-Token"
        static let platform = "iOS"
    }
}

// MARK: - Error Types

enum AppCheckError: Error, LocalizedError, Sendable {
    case tokenRetrievalFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .tokenRetrievalFailed(let error):
            return "Failed to retrieve App Check token: \(error.localizedDescription)"
        }
    }
}

// MARK: - Configuration

extension AppCheckInterceptor {
    /// Production configuration that requires App Check
    static var production: AppCheckInterceptor {
        AppCheckInterceptor(requireAppCheck: true)
    }
    
    /// Development configuration that allows requests without App Check
    static var development: AppCheckInterceptor {
        AppCheckInterceptor(requireAppCheck: false)
    }
}
