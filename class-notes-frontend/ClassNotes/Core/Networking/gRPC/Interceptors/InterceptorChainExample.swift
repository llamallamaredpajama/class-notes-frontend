// Standard library
import Foundation
// Third-party dependencies
import GRPCCore
import GRPCNIOTransportHTTP2
import NIOCore
import NIOPosix
// Apple frameworks
import OSLog

/// Example of how to configure and use the interceptors with gRPC Swift v2
struct InterceptorChainExample {
    
    /// Creates a properly configured interceptor chain for production use
    static func createProductionInterceptors() -> [any ClientInterceptor] {
        return [
            // Logging should be first to capture all requests/responses
            LoggingInterceptor(logLevel: .basic),
            
            // Auth adds authentication headers
            AuthInterceptor(),
            
            // Retry handles transient failures
            RetryInterceptor.default,
            
            // App Check adds security tokens (last to ensure retries have auth)
            AppCheckInterceptor.production
        ]
    }
    
    /// Creates interceptors configured for development/debugging
    static func createDevelopmentInterceptors() -> [any ClientInterceptor] {
        return [
            // Detailed logging for debugging
            LoggingInterceptor(logLevel: .detailed),
            
            // Auth interceptor
            AuthInterceptor(),
            
            // Conservative retry to fail fast during development
            RetryInterceptor.conservative,
            
            // App Check in development mode (allows failures)
            AppCheckInterceptor.development
        ]
    }
    
    /// Example of creating a gRPC client with interceptors
    static func createConfiguredTransport() async throws -> HTTP2ClientTransport {
        // Create event loop group
        let eventLoopGroup = MultiThreadedEventLoopGroup.singleton
        
        // Configure HTTP2 transport with TLS
        let transportConfig = HTTP2ClientTransport.Config.defaults(
            configure: { config in
                // Configure TLS for production
                config.tls.configure {
                    $0.trustRoots = .certificates([]) // Use system certificates
                }
            }
        )
        
        // Create transport with target
        let transport = try HTTP2ClientTransport(
            target: .dns(host: "api.classnotes.com", port: 443),
            config: transportConfig,
            eventLoopGroup: eventLoopGroup
        )
        
        return transport
    }
    
    /// Example of creating a typed service client with interceptors
    static func createClassNotesClient() async throws -> Classnotes_V1_ClassNotesAPI.Client<HTTP2ClientTransport> {
        let transport = try await createConfiguredTransport()
        
        // Get appropriate interceptors based on build configuration
        let interceptors: [any ClientInterceptor]
        #if DEBUG
        interceptors = createDevelopmentInterceptors()
        #else
        interceptors = createProductionInterceptors()
        #endif
        
        // Create gRPC client with transport and interceptors
        let grpcClient = GRPCClient(
            transport: transport,
            interceptors: interceptors
        )
        
        // Create service-specific client
        let classNotesClient = Classnotes_V1_ClassNotesAPI.Client(wrapping: grpcClient)
        
        return classNotesClient
    }
    
    /// Example of creating a subscription service client
    static func createSubscriptionClient() async throws -> ClassNotes_V1_SubscriptionService.Client<HTTP2ClientTransport> {
        let transport = try await createConfiguredTransport()
        
        // Get appropriate interceptors based on build configuration
        let interceptors: [any ClientInterceptor]
        #if DEBUG
        interceptors = createDevelopmentInterceptors()
        #else
        interceptors = createProductionInterceptors()
        #endif
        
        // Create gRPC client with transport and interceptors
        let grpcClient = GRPCClient(
            transport: transport,
            interceptors: interceptors
        )
        
        // Create service-specific client
        let subscriptionClient = ClassNotes_V1_SubscriptionService.Client(wrapping: grpcClient)
        
        return subscriptionClient
    }
    
    /// Example of custom interceptor configuration
    static func createCustomInterceptors() -> [any ClientInterceptor] {
        return [
            // Custom logging configuration
            LoggingInterceptor(
                logLevel: .basic,
                logger: OSLog(subsystem: "com.classnotes.custom", category: "API")
            ),
            
            // Auth with custom logger
            AuthInterceptor(
                logger: OSLog(subsystem: "com.classnotes.custom", category: "Auth")
            ),
            
            // Aggressive retry for unreliable networks
            RetryInterceptor.aggressive,
            
            // App Check with custom configuration
            AppCheckInterceptor(
                requireAppCheck: false,
                logger: OSLog(subsystem: "com.classnotes.custom", category: "AppCheck")
            )
        ]
    }
    
    /// Example showing how to make an authenticated call with custom metadata
    static func makeAuthenticatedCall() async throws {
        let client = try await createClassNotesClient()
        
        // Example: Create custom metadata for a specific call
        var headers: [(String, String)] = []
        headers.append(("x-request-id", UUID().uuidString))
        headers.append(("x-client-version", "1.0.0"))
        let customMetadata = Metadata(headers)
        
        // Make a gRPC call with custom metadata
        // The interceptors will add their own headers on top of these
        let request = Classnotes_V1_ListClassNotesRequest()
        let response = try await client.listClassNotes(
            request,
            metadata: customMetadata
        )
        
        print("Received \(response.notes.count) notes")
    }
    
    /// Example with custom transport configuration
    static func createCustomTransport() async throws -> HTTP2ClientTransport {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
        
        // Custom transport configuration
        let transportConfig = HTTP2ClientTransport.Config(
            connection: .init(
                idleTimeout: .minutes(5),
                keepalive: .init(
                    interval: .seconds(30),
                    timeout: .seconds(10)
                )
            ),
            http2: .init(
                targetWindowSize: 65536,
                maxFrameSize: 16384
            ),
            tls: .makeClientDefault(),
            compression: .init(
                enabledAlgorithms: [.gzip, .deflate]
            ),
            backoff: .defaults
        )
        
        let transport = try HTTP2ClientTransport(
            target: .unixDomainSocket(path: "/tmp/grpc.sock"),
            config: transportConfig,
            eventLoopGroup: eventLoopGroup
        )
        
        return transport
    }
}

// MARK: - Usage Example

/// Example of how to use the configured client in your services
@MainActor
class ExampleService {
    private let classNotesClient: Classnotes_V1_ClassNotesAPI.Client<HTTP2ClientTransport>
    private let subscriptionClient: ClassNotes_V1_SubscriptionService.Client<HTTP2ClientTransport>
    
    init() async throws {
        self.classNotesClient = try await InterceptorChainExample.createClassNotesClient()
        self.subscriptionClient = try await InterceptorChainExample.createSubscriptionClient()
    }
    
    /// Example method showing how interceptors work transparently
    func uploadTranscript(audioData: Data) async throws {
        // When you make a gRPC call, all interceptors are automatically applied:
        // 1. LoggingInterceptor logs the request
        // 2. AuthInterceptor adds auth token
        // 3. RetryInterceptor handles failures
        // 4. AppCheckInterceptor adds security token
        
        let request = Classnotes_V1_UploadTranscriptRequest.with {
            $0.audioData = audioData
            $0.mimeType = "audio/m4a"
        }
        
        let response = try await classNotesClient.uploadTranscript(request)
        print("Transcript uploaded: \(response.transcriptID)")
    }
    
    /// Example of checking subscription status
    func checkSubscription() async throws {
        let status = try await subscriptionClient.getSubscriptionStatus(.init())
        print("Subscription tier: \(status.currentTier)")
    }
}

// MARK: - Cleanup Example

/// Example showing proper cleanup of resources
struct ClientLifecycleExample {
    static func performOperationWithCleanup() async throws {
        // Create a dedicated event loop group
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            // Ensure cleanup happens
            try? eventLoopGroup.syncShutdownGracefully()
        }
        
        // Create transport
        let transport = try HTTP2ClientTransport(
            target: .dns(host: "api.classnotes.com", port: 443),
            config: .defaults,
            eventLoopGroup: eventLoopGroup
        )
        
        // Use transport...
        let grpcClient = GRPCClient(
            transport: transport,
            interceptors: InterceptorChainExample.createProductionInterceptors()
        )
        
        // Shutdown transport when done
        try await transport.shutdown()
    }
} 