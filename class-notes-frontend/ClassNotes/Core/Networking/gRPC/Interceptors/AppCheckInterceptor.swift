// Standard library
import Foundation
// Third-party dependencies
import GRPCCore
import OSLog

/// Interceptor for handling Firebase App Check in gRPC requests
/// Automatically adds App Check tokens to protect against abuse
struct AppCheckInterceptor: ClientInterceptor {
    
    // MARK: - Properties
    
    private let appCheckService: AppCheckService
    private let logger: OSLog
    
    // MARK: - Initialization
    
    init(
        appCheckService: AppCheckService = AppCheckService.shared,
        logger: OSLog = OSLog.security
    ) {
        self.appCheckService = appCheckService
        self.logger = logger
    }
    
    // MARK: - ClientInterceptor Protocol
    
    func intercept<Input: Sendable, Output: Sendable>(
        request: ClientRequest<Input>,
        context: ClientContext,
        next: @Sendable (ClientRequest<Input>, ClientContext) async throws -> ClientResponse<Output>
    ) async throws -> ClientResponse<Output> {
        
        var modifiedRequest = request
        
        // Add App Check token if available
        do {
            let token = try await appCheckService.getToken()
            var metadata = request.metadata
            metadata.addString(token, forKey: Constants.appCheckHeader)
            modifiedRequest = ClientRequest(
                message: request.message,
                metadata: metadata
            )
            
            logger.debug("Added App Check token to request headers")
        } catch {
            logger.error("Failed to add App Check token: \(error)")
            
            // Continue without token in development
            #if DEBUG
            logger.debug("Continuing without App Check token in DEBUG mode")
            #else
            // Fail the request in production
            throw error
            #endif
        }
        
        return try await next(modifiedRequest, context)
    }
    
    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: @Sendable (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        
        var modifiedRequest = request
        
        // Add App Check token if available
        do {
            let token = try await appCheckService.getToken()
            var metadata = request.metadata
            metadata.addString(token, forKey: Constants.appCheckHeader)
            modifiedRequest = StreamingClientRequest(
                metadata: metadata,
                producer: request.producer
            )
            
            logger.debug("Added App Check token to streaming request headers")
        } catch {
            logger.error("Failed to add App Check token: \(error)")
            
            // Continue without token in development
            #if DEBUG
            logger.debug("Continuing without App Check token in DEBUG mode")
            #else
            // Fail the request in production
            throw error
            #endif
        }
        
        return try await next(modifiedRequest, context)
    }
}

// MARK: - Constants

private extension AppCheckInterceptor {
    enum Constants {
        static let appCheckHeader = "X-Firebase-AppCheck"
    }
} 