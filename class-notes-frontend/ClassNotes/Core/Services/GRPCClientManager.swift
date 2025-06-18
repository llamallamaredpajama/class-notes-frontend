// 1. Standard library
import Foundation
// 3. Third-party dependencies
import GRPCCore
import GRPCNIOTransportHTTP2

/// Manager for gRPC client connections using grpc-swift-2
@MainActor
final class GRPCClientManager {
    // MARK: - Singleton
    static let shared = GRPCClientManager()

    // MARK: - Properties
    private var client: GRPCClient<HTTP2ClientTransport.Posix>?
    
    // MARK: - Configuration
    private enum Config {
        static let apiHost = ProcessInfo.processInfo.environment["API_HOST"] ?? "api.classnotes.app"
        static let apiPort = Int(ProcessInfo.processInfo.environment["API_PORT"] ?? "443") ?? 443
        static let useSSL = ProcessInfo.processInfo.environment["USE_SSL"] != "false"
    }

    // MARK: - Initialization
    private init() {
        // Remove authService initialization to avoid MainActor isolation issue
    }

    // MARK: - Client Access
    /// Get or create the ClassNotes service client
    func getClassNotesClient() async throws -> Classnotes_V1_ClassNotesAPI.Client<HTTP2ClientTransport.Posix> {
        if client == nil {
            client = try await createClient()
        }

        guard let client = client else {
            throw AppError.network(GRPCError.connectionFailed)
        }

        return Classnotes_V1_ClassNotesAPI.Client(wrapping: client)
    }
    
    /// Get or create the Subscription service client
    func getSubscriptionClient() async throws -> ClassNotes_V1_SubscriptionService.Client<HTTP2ClientTransport.Posix> {
        if client == nil {
            client = try await createClient()
        }

        guard let client = client else {
            throw AppError.network(GRPCError.connectionFailed)
        }

        return ClassNotes_V1_SubscriptionService.Client(wrapping: client)
    }

    // MARK: - Private Methods
    private func createClient() async throws -> GRPCClient<HTTP2ClientTransport.Posix> {
        // Create HTTP/2 transport
        let transport = try HTTP2ClientTransport.Posix(
            target: .ipv4(host: Config.apiHost, port: Config.apiPort),
            transportSecurity: Config.useSSL ? .tls : .plaintext
        )
        
        // Create client with interceptors
        let client = GRPCClient(
            transport: transport,
            interceptors: [
                AuthInterceptor(),
                AppCheckInterceptor(),
                LoggingInterceptor(logLevel: .basic),
                RetryInterceptor()
            ]
        )
        
        // Note: grpc-swift-2 clients don't need explicit run() call
        return client
    }

    /// Reset the connection (useful after auth changes)
    func resetConnection() async {
        if client != nil {
            // In grpc-swift-2, clients don't need explicit close() call
            // Just reset the reference and it will be cleaned up
            self.client = nil
        }
    }
}

// MARK: - Supporting Types

/// gRPC error types
enum GRPCError: LocalizedError {
    case connectionFailed
    case notAuthenticated
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to server"
        case .notAuthenticated:
            return "Authentication required"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - Interceptor Protocols (grpc-swift-2 style)

/// Protocol for auth interceptor configuration
protocol AuthInterceptorProtocol: ClientInterceptor {
    var authService: AuthenticationService { get }
}

/// Protocol for logging interceptor configuration
protocol LoggingInterceptorProtocol: ClientInterceptor {
    var logLevel: LogLevel { get }
}

/// Protocol for retry interceptor configuration
protocol RetryInterceptorProtocol: ClientInterceptor {
    var maxRetries: Int { get }
}

// MARK: - Log Level
enum LogLevel {
    case none
    case basic
    case detailed
}
