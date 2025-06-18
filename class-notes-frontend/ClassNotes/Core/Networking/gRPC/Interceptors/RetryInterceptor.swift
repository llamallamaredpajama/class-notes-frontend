// Standard library
import Foundation
// Third-party dependencies
import GRPCCore
import OSLog

/// Interceptor that handles automatic retries for failed requests
struct RetryInterceptor: ClientInterceptor, Sendable {
    
    // MARK: - Properties
    
    let maxRetries: Int
    let retryableStatusCodes: Set<RPCError.Code>
    let initialBackoff: TimeInterval
    let backoffMultiplier: Double
    let maxBackoff: TimeInterval
    private let logger: OSLog
    
    // MARK: - Initialization
    
    init(
        maxRetries: Int = 3,
        retryableStatusCodes: Set<RPCError.Code> = [.unavailable, .deadlineExceeded, .resourceExhausted],
        initialBackoff: TimeInterval = 0.1,
        backoffMultiplier: Double = 2.0,
        maxBackoff: TimeInterval = 5.0,
        logger: OSLog = OSLog(subsystem: "com.classnotes", category: "Networking")
    ) {
        self.maxRetries = maxRetries
        self.retryableStatusCodes = retryableStatusCodes
        self.initialBackoff = initialBackoff
        self.backoffMultiplier = backoffMultiplier
        self.maxBackoff = maxBackoff
        self.logger = logger
    }
    
    // MARK: - ClientInterceptor Implementation
    
    func intercept<Input: Sendable, Output: Sendable>(
        request: ClientRequest<Input>,
        context: ClientContext,
        next: @Sendable (
            ClientRequest<Input>,
            ClientContext
        ) async throws -> ClientResponse<Output>
    ) async throws -> ClientResponse<Output> {
        var lastError: Error?
        var currentBackoff = initialBackoff
        
        for attempt in 0...maxRetries {
            do {
                if attempt > 0 {
                    logger.info("Retrying request (attempt \(attempt + 1)/\(maxRetries + 1)) for \(context.descriptor.fullyQualifiedMethod)")
                    try await Task.sleep(nanoseconds: UInt64(currentBackoff * 1_000_000_000))
                }
                
                // Attempt the request
                let response = try await next(request, context)
                
                if attempt > 0 {
                    logger.info("Request succeeded after \(attempt) retries")
                }
                
                return response
                
            } catch let error as RPCError {
                lastError = error
                
                // Check if error is retryable
                if !isRetryable(error: error) {
                    logger.debug("Non-retryable error for \(context.descriptor.fullyQualifiedMethod): \(error)")
                    throw error
                }
                
                // Check if we've exhausted retries
                if attempt == maxRetries {
                    logger.error("Max retries (\(maxRetries)) exceeded for \(context.descriptor.fullyQualifiedMethod)")
                    throw error
                }
                
                // Log retry attempt
                logger.warning("Retryable error for \(context.descriptor.fullyQualifiedMethod): \(error.code) - \(error.message)")
                
                // Update backoff for next attempt
                currentBackoff = min(currentBackoff * backoffMultiplier, maxBackoff)
                
            } catch {
                // Non-RPC errors are not retryable
                logger.error("Non-RPC error (not retryable) for \(context.descriptor.fullyQualifiedMethod): \(error)")
                throw error
            }
        }
        
        // This should never be reached due to the logic above
        throw lastError ?? RetryError.exhaustedRetries
    }
    
    // MARK: - Private Methods
    
    private func isRetryable(error: RPCError) -> Bool {
        // Check if the error code is in our retryable set
        guard retryableStatusCodes.contains(error.code) else {
            return false
        }
        
        // Check for retry-after header in metadata
        if let retryAfterValues = error.metadata["retry-after"],
           let retryAfterValue = retryAfterValues.first {
            logger.debug("Server requested retry after: \(retryAfterValue)")
        }
        
        return true
    }
}

// MARK: - Error Types

enum RetryError: Error, Sendable {
    case exhaustedRetries
    
    var localizedDescription: String {
        switch self {
        case .exhaustedRetries:
            return "Exhausted retry attempts"
        }
    }
}

// MARK: - Retry Configuration

extension RetryInterceptor {
    /// Default retry configuration for production use
    static var `default`: RetryInterceptor {
        RetryInterceptor()
    }
    
    /// Aggressive retry configuration for unreliable networks
    static var aggressive: RetryInterceptor {
        RetryInterceptor(
            maxRetries: 5,
            retryableStatusCodes: [
                .unavailable,
                .deadlineExceeded,
                .resourceExhausted,
                .aborted,
                .internal
            ],
            initialBackoff: 0.05,
            backoffMultiplier: 1.5,
            maxBackoff: 10.0
        )
    }
    
    /// Conservative retry configuration to minimize retries
    static var conservative: RetryInterceptor {
        RetryInterceptor(
            maxRetries: 1,
            retryableStatusCodes: [.unavailable],
            initialBackoff: 0.5,
            backoffMultiplier: 2.0,
            maxBackoff: 2.0
        )
    }
    
    /// No retry configuration for critical operations
    static var noRetry: RetryInterceptor {
        RetryInterceptor(
            maxRetries: 0,
            retryableStatusCodes: []
        )
    }
}
