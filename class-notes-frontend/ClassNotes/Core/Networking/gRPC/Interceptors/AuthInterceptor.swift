// Standard library
import Foundation
// Third-party dependencies
import GRPCCore
import OSLog

/// Interceptor for handling authentication in gRPC requests
/// Automatically adds auth tokens and handles token refresh
struct AuthInterceptor: ClientInterceptor {
    
    // MARK: - Properties
    
    private let keychainService: KeychainService
    private let logger: OSLog
    
    // MARK: - Initialization
    
    init(
        keychainService: KeychainService = KeychainService.shared,
        logger: OSLog = OSLog(subsystem: "com.classnotes", category: "Networking")
    ) {
        self.keychainService = keychainService
        self.logger = logger
    }
    
    // MARK: - ClientInterceptor Protocol
    
    func intercept<Input: Sendable, Output: Sendable>(
        request: ClientRequest<Input>,
        context: ClientContext,
        next: @Sendable (ClientRequest<Input>, ClientContext) async throws -> ClientResponse<Output>
    ) async throws -> ClientResponse<Output> {
        
        var modifiedRequest = request
        
        // Add authentication token if available
        if let token = getStoredAuthToken() {
            var metadata = request.metadata
            metadata.addString(
                "\(Constants.bearerPrefix)\(token)",
                forKey: Constants.authorizationHeader
            )
            modifiedRequest = ClientRequest(
                message: request.message,
                metadata: metadata
            )
            
            logger.info("Added auth token to request")
        }
        
        // Add user agent header
        var metadata = modifiedRequest.metadata
        metadata.addString(Constants.userAgent, forKey: Constants.userAgentHeader)
        modifiedRequest = ClientRequest(
            message: modifiedRequest.message,
            metadata: metadata
        )
        
        return try await next(modifiedRequest, context)
    }
    
    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: @Sendable (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        
        var modifiedRequest = request
        
        // Add authentication token if available
        if let token = getStoredAuthToken() {
            var metadata = request.metadata
            metadata.addString(
                "\(Constants.bearerPrefix)\(token)",
                forKey: Constants.authorizationHeader
            )
            modifiedRequest = StreamingClientRequest(
                metadata: metadata,
                producer: request.producer
            )
            
            logger.info("Added auth token to streaming request")
        }
        
        // Add user agent header
        var metadata = modifiedRequest.metadata
        metadata.addString(Constants.userAgent, forKey: Constants.userAgentHeader)
        modifiedRequest = StreamingClientRequest(
            metadata: metadata,
            producer: modifiedRequest.producer
        )
        
        return try await next(modifiedRequest, context)
    }
    
    // MARK: - Private Helper Methods
    
    private func extractTokenFromHeader(_ headerValue: String) -> String? {
        if headerValue.hasPrefix(Constants.bearerPrefix) {
            return String(headerValue.dropFirst(Constants.bearerPrefix.count))
        }
        return nil
    }
    
    private func getStoredAuthToken() -> String? {
        return keychainService.loadString(key: "auth_token")
    }
    
    private func storeAuthToken(_ token: String) throws {
        _ = keychainService.saveString(token, for: "auth_token")
    }
    
    private func removeStoredAuthToken() {
        _ = keychainService.delete(key: "auth_token")
    }
}

// MARK: - Constants

private extension AuthInterceptor {
    enum Constants {
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
