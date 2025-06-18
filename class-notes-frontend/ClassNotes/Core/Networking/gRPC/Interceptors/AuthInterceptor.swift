// Standard library
import Foundation
// Third-party dependencies
import GRPCCore
import OSLog

/// Interceptor for handling authentication in gRPC requests
/// Automatically adds auth tokens and handles token refresh
struct AuthInterceptor: ClientInterceptor, Sendable {

    // MARK: - Properties

    private let logger: OSLog

    // MARK: - Initialization

    init(
        logger: OSLog = OSLog(subsystem: "com.classnotes", category: "Networking")
    ) {
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
        
        // Add auth token if available
        if let token = getStoredAuthToken() {
            logger.info("Adding auth token to request")
            headers.append((Constants.authorizationHeader, "\(Constants.bearerPrefix)\(token)"))
        } else {
            logger.debug("No auth token available for request")
        }
        
        // Add User-Agent header
        headers.append((Constants.userAgentHeader, Constants.userAgent))
        
        // Create new metadata with all headers
        let newMetadata = Metadata(headers)
        
        // Create new request with updated metadata
        let modifiedRequest = ClientRequest(
            message: request.message,
            metadata: newMetadata
        )
        
        // Execute the request with modified headers
        let response = try await next(modifiedRequest, context)
        
        // Check if we received a new auth token in the response
        if let newTokenValues = response.metadata[Constants.authorizationHeader] {
            // Get the first value if multiple are present
            if let firstValue = newTokenValues.first {
                if let newToken = extractTokenFromHeader(firstValue) {
                    logger.info("Received new auth token in response, storing it")
                    try storeAuthToken(newToken)
                }
            }
        }
        
        return response
    }

    // MARK: - Private Helper Methods

    private func extractTokenFromHeader(_ headerValue: String) -> String? {
        if headerValue.hasPrefix(Constants.bearerPrefix) {
            return String(headerValue.dropFirst(Constants.bearerPrefix.count))
        }
        return nil
    }

    private func getStoredAuthToken() -> String? {
        return KeychainService.shared.loadString(key: "auth_token")
    }

    private func storeAuthToken(_ token: String) throws {
        _ = KeychainService.shared.saveString(token, for: "auth_token")
    }

    private func removeStoredAuthToken() {
        _ = KeychainService.shared.delete(key: "auth_token")
    }
}

// MARK: - Constants

extension AuthInterceptor {
    fileprivate enum Constants {
        static let authorizationHeader = "authorization"
        static let userAgentHeader = "user-agent"
        static let bearerPrefix = "Bearer "
        static let userAgent = "ClassNotes-iOS/1.0"
    }
}

// MARK: - KeychainService Extension
extension KeychainService {
    func getAuthToken() throws -> String? {
        return loadString(key: "auth_token")
    }

    func setAuthToken(_ token: String) throws {
        _ = saveString(token, for: "auth_token")
    }

    func deleteAuthToken() {
        _ = delete(key: "auth_token")
    }
}
