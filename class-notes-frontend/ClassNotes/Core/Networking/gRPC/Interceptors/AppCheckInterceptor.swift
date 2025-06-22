// Standard library
import Foundation
// Third-party dependencies
import GeneratedProtos
import OSLog

/// App Check interceptor following gRPC-Swift v2 cursor rules
struct AppCheckInterceptor: ClientInterceptor {
    typealias Output = ClientResponse

    private let logger = Logger(subsystem: "com.classnotes", category: "appcheck")

    func intercept<Input: Sendable, Interceptor>(
        request: ClientRequest<Input>,
        context: ClientInterceptorContext<Input, ClientResponse>,
        next: @Sendable (
            ClientRequest<Input>,
            ClientInterceptorContext<Input, ClientResponse>
        ) async throws -> ClientResponse
    ) async throws -> ClientResponse {
        var modifiedRequest = request

        // Get App Check token
        if let appCheckToken = await getAppCheckToken() {
            var newMetadata = request.metadata
            newMetadata.addString(appCheckToken, forKey: "X-Firebase-AppCheck")
            modifiedRequest.metadata = newMetadata
            logger.debug("Added App Check token to request")
        } else {
            logger.warning("No App Check token available")
        }

        return try await next(modifiedRequest, context)
    }

    private func getAppCheckToken() async -> String? {
        // Get token from AppCheckServiceV2
        do {
            return try await AppCheckServiceV2.shared.getToken()
        } catch {
            logger.error("Failed to get App Check token: \(error)")
            return nil
        }
    }
}

enum AppCheckError: Error {
    case tokenUnavailable
    case tokenExpired

    var localizedDescription: String {
        switch self {
        case .tokenUnavailable:
            return "App Check token is not available"
        case .tokenExpired:
            return "App Check token has expired"
        }
    }
}
