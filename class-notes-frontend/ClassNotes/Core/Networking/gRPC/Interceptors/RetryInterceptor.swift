// Standard library
import Foundation
// Third-party dependencies
import GeneratedProtos
import NIOCore
// Apple frameworks
import OSLog

/// Retry interceptor following gRPC-Swift v2 cursor rules
struct RetryInterceptor: ClientInterceptor {
    typealias Output = ClientResponse

    private let maxRetries: Int
    private let retryableStatusCodes: Set<GRPCCore.Status.Code>

    init(
        maxRetries: Int = 3,
        retryableStatusCodes: Set<GRPCCore.Status.Code> = [.unavailable, .deadlineExceeded]
    ) {
        self.maxRetries = maxRetries
        self.retryableStatusCodes = retryableStatusCodes
    }

    func intercept<Input: Sendable, Interceptor>(
        request: ClientRequest<Input>,
        context: ClientInterceptorContext<Input, ClientResponse>,
        next: @Sendable (
            ClientRequest<Input>,
            ClientInterceptorContext<Input, ClientResponse>
        ) async throws -> ClientResponse
    ) async throws -> ClientResponse {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                return try await next(request, context)
            } catch let error as RPCError {
                lastError = error

                // Check if retryable
                if !retryableStatusCodes.contains(error.code) {
                    throw error
                }

                // Exponential backoff
                if attempt < maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt)) * 0.1
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                // Non-RPC errors are not retryable
                throw error
            }
        }

        throw lastError ?? RPCError(code: .unknown, message: "Retry failed")
    }

    // Simplified factory methods
    static let `default` = RetryInterceptor(maxRetries: 3)
    static let aggressive = RetryInterceptor(maxRetries: 5)
    static let noRetry = RetryInterceptor(maxRetries: 0)
}

extension OSLog {
    static let retryLogger = OSLog(subsystem: "com.classnotes.grpc", category: "Retry")
}

// MARK: - Status helpers will be added once basic connectivity works
