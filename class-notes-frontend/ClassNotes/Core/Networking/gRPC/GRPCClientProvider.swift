import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import NIOCore
import NIOPosix
import OSLog

/// Global actor for gRPC client operations
@globalActor
actor GRPCClientActor {
    static let shared = GRPCClientActor()
}

/// Provider for gRPC client instances with v2 architecture
@GRPCClientActor
final class GRPCClientProvider {
    static let shared = GRPCClientProvider()
    
    private var transport: (any ClientTransport)?
    private let interceptors: [any ClientInterceptor]
    private let logger = OSLog(subsystem: "com.classnotes", category: "Networking")
    
    private init() {
        self.interceptors = Self.createInterceptors()
        Task {
            await self.initialize()
        }
    }
    
    /// Initialize the transport asynchronously
    private func initialize() async {
        do {
            self.transport = try await createTransport()
            logger.info("gRPC transport initialized successfully")
        } catch {
            logger.error("Failed to initialize gRPC transport: \(error)")
        }
    }
    
    /// Create the appropriate transport based on environment
    private func createTransport() async throws -> HTTP2ClientTransport {
        let group = MultiThreadedEventLoopGroup.singleton
        
        #if DEBUG
        // Development configuration without TLS
        logger.info("Creating development transport for localhost:8080")
        return try HTTP2ClientTransport(
            target: .dns(host: "localhost", port: 8080),
            config: .defaults(configure: { config in
                config.connectionPool.configuration.connectionIdleTimeout = .minutes(5)
                config.connectionPool.configuration.reservationLoadThreshold = 0.8
                config.connectionPool.configuration.maximumConnectionsPerEventLoop = 8
            }),
            eventLoopGroup: group
        )
        #else
        // Production configuration with TLS
        logger.info("Creating production transport for api.classnotes.com:443")
        return try HTTP2ClientTransport(
            target: .dns(host: "api.classnotes.com", port: 443),
            config: .defaults(configure: { config in
                // Configure TLS
                config.tls.configure {
                    $0.trustRoots = .default
                    $0.minimumTLSVersion = .tlsv13
                }
                
                // Configure connection pool
                config.connectionPool.configuration.connectionIdleTimeout = .minutes(10)
                config.connectionPool.configuration.reservationLoadThreshold = 0.9
                config.connectionPool.configuration.maximumConnectionsPerEventLoop = 16
            }),
            eventLoopGroup: group
        )
        #endif
    }
    
    /// Create interceptors based on environment
    private static func createInterceptors() -> [any ClientInterceptor] {
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
    
    /// Make a new gRPC client instance
    func makeGRPCClient() -> GRPCClient {
        guard let transport = transport else {
            logger.error("Transport not initialized, using empty transport")
            return GRPCClient(
                transport: EmptyTransport(),
                interceptors: interceptors
            )
        }
        
        return GRPCClient(
            transport: transport,
            interceptors: interceptors
        )
    }
    
    /// Shutdown the transport gracefully
    func shutdown() async {
        logger.info("Shutting down gRPC transport")
        await transport?.close()
        transport = nil
    }
}

// MARK: - Empty Transport

/// Empty transport for initialization phase
private struct EmptyTransport: ClientTransport {
    func connect(lazily: Bool) async throws -> any Streaming {
        throw GRPCError.transportNotInitialized
    }
    
    func close() async {
        // No-op
    }
}

// MARK: - Error Types

enum GRPCError: Error, LocalizedError {
    case transportNotInitialized
    
    var errorDescription: String? {
        switch self {
        case .transportNotInitialized:
            return "gRPC transport is not initialized"
        }
    }
} 