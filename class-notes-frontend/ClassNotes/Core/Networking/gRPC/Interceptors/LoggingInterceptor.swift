// Standard library
import Foundation
// Third-party dependencies
import GeneratedProtos
// Apple frameworks
import OSLog

/// Logging interceptor following gRPC-Swift v2 cursor rules exactly
struct LoggingInterceptor: ClientInterceptor {
    typealias Output = ClientResponse

    private let logger = Logger(subsystem: "com.classnotes", category: "grpc")

    func intercept<Input: Sendable, Interceptor>(
        request: ClientRequest<Input>,
        context: ClientInterceptorContext<Input, ClientResponse>,
        next: @Sendable (
            ClientRequest<Input>,
            ClientInterceptorContext<Input, ClientResponse>
        ) async throws -> ClientResponse
    ) async throws -> ClientResponse {
        logger.debug("Request to \(context.method)")

        do {
            let response = try await next(request, context)
            logger.debug("Response received")
            return response
        } catch {
            logger.error("Request failed: \(error)")
            throw error
        }
    }
}

extension OSLog {
    static let grpcLogger = OSLog(subsystem: "com.classnotes.grpc", category: "gRPC")
}

// MARK: - Request/Response Logging Extensions
// Note: ClientContext in grpc-swift-2 doesn't expose service/method information directly
