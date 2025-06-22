// Standard library
import Foundation
// Third-party dependencies
import GeneratedProtos
import OSLog

/// Auth interceptor following gRPC-Swift v2 cursor rules exactly
struct AuthInterceptor<Output: Sendable>: ClientInterceptor {
    func intercept<Input: Sendable>(
        request: inout ClientRequest<Input>,
        context: ClientContext,
        next: (ClientRequest<Input>, ClientContext) async throws -> ClientResponse<Output>
    ) async throws -> ClientResponse<Output> {
        // Add auth token to metadata
        if let token = await AuthenticationService.shared.currentToken {
            request.metadata["authorization"] = "Bearer \(token)"
        }

        return try await next(request, context)
    }
}
