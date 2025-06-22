import Foundation
import GeneratedProtos
import OSLog

/// Centralizes gRPC client creation for the application.
/// This implementation follows gRPC-Swift v2 cursor rules exactly.
@GRPCClientActor
final class GRPCClientProvider {
    static let shared = GRPCClientProvider()

    private let transport: HTTP2ClientTransport.Posix
    private let client: GRPCClient<HTTP2ClientTransport.Posix>

    private enum Config {
        static let apiHost = ProcessInfo.processInfo.environment["API_HOST"] ?? "api.classnotes.com"
        static let apiPort = Int(ProcessInfo.processInfo.environment["API_PORT"] ?? "443") ?? 443
        static let useSSL = ProcessInfo.processInfo.environment["USE_SSL"] != "false"
    }

    init() {
        // Create transport following cursor rules
        self.transport = HTTP2ClientTransport.Posix(
            target: .dns(host: Config.apiHost, port: Config.apiPort),
            config: .defaults(transportSecurity: Config.useSSL ? .tls : .plaintext)
        )

        // Use concrete type, NOT protocol as per cursor rules
        self.client = GRPCClient(
            transport: transport,
            interceptors: [
                AuthInterceptor(),
                AppCheckInterceptor(),
                LoggingInterceptor(),
                RetryInterceptor(),
            ]
        )
    }

    func getServiceClient() -> Classnotes_V1_ClassNotesAPI.Client {
        return Classnotes_V1_ClassNotesAPI.Client(wrapping: client)
    }

    func getSubscriptionClient() -> Classnotes_V1_SubscriptionService.Client {
        return Classnotes_V1_SubscriptionService.Client(wrapping: client)
    }
}
