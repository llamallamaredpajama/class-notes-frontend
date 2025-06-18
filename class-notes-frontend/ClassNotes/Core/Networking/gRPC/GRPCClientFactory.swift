// Standard library
import Foundation
// Third-party dependencies
import GRPCCore
import GRPCNIOTransportHTTP2
import NIOCore
import NIOPosix
// Apple frameworks
import OSLog

/// Factory for creating configured gRPC clients with interceptors
@MainActor
final class GRPCClientFactory {
    
    // MARK: - Singleton
    
    static let shared = GRPCClientFactory()
    
    // MARK: - Properties
    
    private let eventLoopGroup: MultiThreadedEventLoopGroup
    private var transport: HTTP2ClientTransport?
    private let logger = OSLog(subsystem: "com.classnotes", category: "gRPC")
    
    // Cached clients
    private var classNotesClient: Classnotes_V1_ClassNotesAPI.Client<HTTP2ClientTransport>?
    private var subscriptionClient: ClassNotes_V1_SubscriptionService.Client<HTTP2ClientTransport>?
    
    // MARK: - Configuration
    
    struct Configuration {
        let host: String
        let port: Int
        let useTLS: Bool
        
        static let production = Configuration(
            host: "api.classnotes.com",
            port: 443,
            useTLS: true
        )
        
        static let development = Configuration(
            host: "localhost",
            port: 8080,
            useTLS: false
        )
    }
    
    private let configuration: Configuration
    
    // MARK: - Initialization
    
    private init() {
        self.eventLoopGroup = MultiThreadedEventLoopGroup.singleton
        
        #if DEBUG
        self.configuration = .development
        #else
        self.configuration = .production
        #endif
    }
    
    // MARK: - Client Creation
    
    /// Get or create the ClassNotes API client
    func getClassNotesClient() async throws -> Classnotes_V1_ClassNotesAPI.Client<HTTP2ClientTransport> {
        if let client = classNotesClient {
            return client
        }
        
        let transport = try await getOrCreateTransport()
        let interceptors = createInterceptors()
        
        let grpcClient = GRPCClient(
            transport: transport,
            interceptors: interceptors
        )
        
        let client = Classnotes_V1_ClassNotesAPI.Client(wrapping: grpcClient)
        self.classNotesClient = client
        
        logger.info("Created ClassNotes API client")
        return client
    }
    
    /// Get or create the Subscription service client
    func getSubscriptionClient() async throws -> ClassNotes_V1_SubscriptionService.Client<HTTP2ClientTransport> {
        if let client = subscriptionClient {
            return client
        }
        
        let transport = try await getOrCreateTransport()
        let interceptors = createInterceptors()
        
        let grpcClient = GRPCClient(
            transport: transport,
            interceptors: interceptors
        )
        
        let client = ClassNotes_V1_SubscriptionService.Client(wrapping: grpcClient)
        self.subscriptionClient = client
        
        logger.info("Created Subscription service client")
        return client
    }
    
    // MARK: - Transport Management
    
    private func getOrCreateTransport() async throws -> HTTP2ClientTransport {
        if let transport = transport {
            return transport
        }
        
        let newTransport = try await createTransport()
        self.transport = newTransport
        return newTransport
    }
    
    private func createTransport() async throws -> HTTP2ClientTransport {
        let config: HTTP2ClientTransport.Config
        
        if configuration.useTLS {
            // Production configuration with TLS
            config = HTTP2ClientTransport.Config.defaults(
                configure: { transportConfig in
                    transportConfig.connection.idleTimeout = .minutes(5)
                    transportConfig.connection.keepalive = .init(
                        interval: .seconds(30),
                        timeout: .seconds(10)
                    )
                    transportConfig.compression.enabledAlgorithms = [.gzip]
                }
            )
        } else {
            // Development configuration without TLS
            config = HTTP2ClientTransport.Config(
                connection: .defaults,
                http2: .defaults,
                tls: .none,  // No TLS for local development
                compression: .defaults,
                backoff: .defaults
            )
        }
        
        let transport = try HTTP2ClientTransport(
            target: .dns(host: configuration.host, port: configuration.port),
            config: config,
            eventLoopGroup: eventLoopGroup
        )
        
        logger.info("Created transport to \(configuration.host):\(configuration.port) (TLS: \(configuration.useTLS))")
        return transport
    }
    
    private func createInterceptors() -> [any ClientInterceptor] {
        #if DEBUG
        return [
            LoggingInterceptor(logLevel: .detailed),
            AuthInterceptor(),
            RetryInterceptor.conservative,
            AppCheckInterceptor.development
        ]
        #else
        return [
            LoggingInterceptor(logLevel: .basic),
            AuthInterceptor(),
            RetryInterceptor.default,
            AppCheckInterceptor.production
        ]
        #endif
    }
    
    // MARK: - Cleanup
    
    /// Shutdown all connections and cleanup resources
    func shutdown() async throws {
        logger.info("Shutting down gRPC clients")
        
        // Clear cached clients
        classNotesClient = nil
        subscriptionClient = nil
        
        // Shutdown transport
        if let transport = transport {
            try await transport.shutdown()
            self.transport = nil
        }
        
        logger.info("gRPC clients shut down successfully")
    }
    
    /// Reset connections (useful for error recovery)
    func reset() async throws {
        try await shutdown()
        // Clients will be recreated on next access
    }
}

// MARK: - Usage Example

extension GRPCClientFactory {
    /// Example of how to use the factory in your app
    static func exampleUsage() async throws {
        // Get clients from factory
        let classNotesClient = try await GRPCClientFactory.shared.getClassNotesClient()
        let subscriptionClient = try await GRPCClientFactory.shared.getSubscriptionClient()
        
        // Use clients to make calls
        let notesResponse = try await classNotesClient.listClassNotes(.init())
        print("Found \(notesResponse.notes.count) notes")
        
        let statusResponse = try await subscriptionClient.getSubscriptionStatus(.init())
        print("Current tier: \(statusResponse.currentTier)")
        
        // Cleanup when done (e.g., on app termination)
        try await GRPCClientFactory.shared.shutdown()
    }
}

// MARK: - Error Recovery

extension GRPCClientFactory {
    /// Handle connection errors by resetting the transport
    func handleConnectionError(_ error: Error) async {
        logger.error("Connection error: \(error)")
        
        do {
            try await reset()
            logger.info("Successfully reset connections after error")
        } catch {
            logger.error("Failed to reset connections: \(error)")
        }
    }
} 