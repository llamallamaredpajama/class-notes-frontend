# Networking & gRPC Integration

## Overview

This document covers networking patterns for the Class Notes iOS application, focusing on gRPC-Swift integration, offline support, and seamless backend communication.

## gRPC Client Architecture

### Client Manager
```swift
import GRPC
import NIO

final class GRPCClientManager {
    static let shared = GRPCClientManager()
    
    private let eventLoopGroup: EventLoopGroup
    private var channel: GRPCChannel?
    private let configuration: ClientConfiguration
    
    init(configuration: ClientConfiguration = .default) {
        self.configuration = configuration
        self.eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1)
    }
    
    private func createChannel() throws -> GRPCChannel {
        let keepalive = ClientConnectionKeepalive(
            interval: .seconds(30),
            timeout: .seconds(10)
        )
        
        return try GRPCChannelPool.with(
            target: .host(configuration.host, port: configuration.port),
            transportSecurity: configuration.useTLS ? .tls(
                GRPCTLSConfiguration.makeClientDefault(
                    certificateVerification: .fullVerification
                )
            ) : .plaintext,
            eventLoopGroup: eventLoopGroup
        ) {
            $0.keepalive = keepalive
            $0.connectionBackoff = ConnectionBackoff(
                initialBackoff: 1.0,
                maximumBackoff: 60.0,
                multiplier: 1.6
            )
        }
    }
    
    func makeClient() throws -> ClassNotesServiceAsyncClient {
        if channel == nil {
            channel = try createChannel()
        }
        
        return ClassNotesServiceAsyncClient(
            channel: channel!,
            defaultCallOptions: CallOptions(
                customMetadata: HPACKHeaders(),
                timeLimit: .timeout(.seconds(30))
            ),
            interceptors: ClientInterceptorFactory()
        )
    }
    
    func shutdown() async throws {
        try await channel?.close()
        try await eventLoopGroup.shutdownGracefully()
    }
}
```

### Configuration
```swift
struct ClientConfiguration {
    let host: String
    let port: Int
    let useTLS: Bool
    
    static let `default` = ClientConfiguration(
        host: "api.classnotes.app",
        port: 443,
        useTLS: true
    )
    
    static let local = ClientConfiguration(
        host: "localhost",
        port: 8080,
        useTLS: false
    )
    
    #if DEBUG
    static var current: ClientConfiguration {
        ProcessInfo.processInfo.environment["USE_LOCAL_BACKEND"] != nil ? .local : .default
    }
    #else
    static let current = ClientConfiguration.default
    #endif
}
```

## Interceptors

### Authentication Interceptor
```swift
final class AuthInterceptor: ClientInterceptor<ClassNotesRequest, ClassNotesResponse> {
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService = .shared) {
        self.authService = authService
    }
    
    override func send(
        _ part: GRPCClientRequestPart<ClassNotesRequest>,
        promise: EventLoopPromise<Void>?,
        context: ClientInterceptorContext<ClassNotesRequest, ClassNotesResponse>
    ) {
        switch part {
        case .metadata(var headers):
            // Add Firebase auth token
            if let token = authService.currentToken {
                headers.add(name: "authorization", value: "Bearer \(token)")
            }
            
            // Add app check token
            if let appCheckToken = authService.appCheckToken {
                headers.add(name: "x-firebase-appcheck", value: appCheckToken)
            }
            
            // Add client metadata
            headers.add(name: "x-client-version", value: Bundle.main.appVersion)
            headers.add(name: "x-client-platform", value: "iOS")
            
            context.send(.metadata(headers), promise: promise)
            
        default:
            context.send(part, promise: promise)
        }
    }
}
```

### Logging Interceptor
```swift
final class LoggingInterceptor: ClientInterceptor<ClassNotesRequest, ClassNotesResponse> {
    private let logger = Logger(subsystem: "com.classnotes.grpc", category: "requests")
    
    override func send(
        _ part: GRPCClientRequestPart<ClassNotesRequest>,
        promise: EventLoopPromise<Void>?,
        context: ClientInterceptorContext<ClassNotesRequest, ClassNotesResponse>
    ) {
        switch part {
        case .metadata(let headers):
            logger.debug("Sending request to \(context.path)")
            #if DEBUG
            logger.debug("Headers: \(headers)")
            #endif
        case .message(let request, _):
            logger.debug("Request payload: \(type(of: request))")
        default:
            break
        }
        
        context.send(part, promise: promise)
    }
    
    override func receive(
        _ part: GRPCClientResponsePart<ClassNotesResponse>,
        context: ClientInterceptorContext<ClassNotesRequest, ClassNotesResponse>
    ) {
        switch part {
        case .metadata(let headers):
            logger.debug("Received response headers")
        case .message(let response):
            logger.debug("Response received: \(type(of: response))")
        case .end(let status, _):
            if status.isOk {
                logger.debug("Request completed successfully")
            } else {
                logger.error("Request failed: \(status)")
            }
        }
        
        context.receive(part)
    }
}
```

### Retry Interceptor
```swift
final class RetryInterceptor: ClientInterceptor<ClassNotesRequest, ClassNotesResponse> {
    private let maxRetries: Int
    private let retryableStatusCodes: Set<GRPCStatus.Code>
    
    init(
        maxRetries: Int = 3,
        retryableStatusCodes: Set<GRPCStatus.Code> = [.unavailable, .deadlineExceeded]
    ) {
        self.maxRetries = maxRetries
        self.retryableStatusCodes = retryableStatusCodes
    }
    
    // Implementation of exponential backoff retry logic
}
```

## Service Layer

### Protocol Definition
```swift
protocol LessonServiceProtocol {
    func createLesson(_ lesson: Lesson) async throws -> Lesson
    func fetchLessons() async throws -> [Lesson]
    func updateLesson(_ lesson: Lesson) async throws -> Lesson
    func deleteLesson(id: String) async throws
    func streamProcessingStatus(for lessonID: String) -> AsyncStream<ProcessingStatus>
}
```

### Service Implementation
```swift
final class LessonService: LessonServiceProtocol {
    static let shared = LessonService()
    
    private let grpcClient: ClassNotesServiceAsyncClient
    private let cacheManager: CacheManager
    private let offlineQueue: OfflineOperationQueue
    
    init(
        grpcClient: ClassNotesServiceAsyncClient? = nil,
        cacheManager: CacheManager = .shared,
        offlineQueue: OfflineOperationQueue = .shared
    ) {
        self.grpcClient = grpcClient ?? (try? GRPCClientManager.shared.makeClient()) ?? ClassNotesServiceAsyncClient.mock
        self.cacheManager = cacheManager
        self.offlineQueue = offlineQueue
    }
    
    func createLesson(_ lesson: Lesson) async throws -> Lesson {
        // Check network availability
        guard NetworkMonitor.shared.isConnected else {
            // Queue for later
            try await offlineQueue.enqueue(.createLesson(lesson))
            // Return with temporary ID
            return lesson.withTemporaryID()
        }
        
        // Create request
        let request = CreateLessonRequest.with {
            $0.title = lesson.title
            $0.subject = lesson.subject
            $0.date = lesson.date.toTimestamp()
        }
        
        // Make gRPC call
        do {
            let response = try await grpcClient.createLesson(request)
            let createdLesson = Lesson(from: response.lesson)
            
            // Update cache
            try await cacheManager.cache(createdLesson)
            
            return createdLesson
        } catch {
            throw mapGRPCError(error)
        }
    }
    
    func fetchLessons() async throws -> [Lesson] {
        // Always return cached data first
        let cachedLessons = try await cacheManager.fetchLessons()
        
        // Fetch fresh data in background
        Task.detached { [weak self] in
            guard let self else { return }
            
            do {
                let request = ListLessonsRequest()
                let response = try await self.grpcClient.listLessons(request)
                let lessons = response.lessons.map { Lesson(from: $0) }
                
                // Update cache
                try await self.cacheManager.syncLessons(lessons)
            } catch {
                // Log but don't throw - we have cached data
                Logger.shared.error("Failed to sync lessons: \(error)")
            }
        }
        
        return cachedLessons
    }
    
    func streamProcessingStatus(for lessonID: String) -> AsyncStream<ProcessingStatus> {
        AsyncStream { continuation in
            Task {
                do {
                    let request = StreamProcessingStatusRequest.with {
                        $0.lessonID = lessonID
                    }
                    
                    let stream = grpcClient.streamProcessingStatus(request)
                    
                    for try await status in stream {
                        continuation.yield(ProcessingStatus(from: status))
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
```

## Error Handling

### Error Mapping
```swift
enum NetworkError: LocalizedError {
    case offline
    case unauthorized
    case quotaExceeded(message: String)
    case serverError(code: String, message: String)
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection"
        case .unauthorized:
            return "Authentication required"
        case .quotaExceeded(let message):
            return "Quota exceeded: \(message)"
        case .serverError(_, let message):
            return message
        case .timeout:
            return "Request timed out"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .offline:
            return "Please check your internet connection"
        case .unauthorized:
            return "Please sign in again"
        case .quotaExceeded:
            return "Upgrade your plan or wait for quota reset"
        case .serverError(let code, _):
            return "Error code: \(code)"
        case .timeout:
            return "Please try again"
        case .unknown:
            return nil
        }
    }
}

func mapGRPCError(_ error: Error) -> NetworkError {
    guard let grpcError = error as? GRPCStatus else {
        return .unknown(error)
    }
    
    switch grpcError.code {
    case .unavailable:
        return .offline
    case .unauthenticated:
        return .unauthorized
    case .resourceExhausted:
        return .quotaExceeded(message: grpcError.message ?? "")
    case .deadlineExceeded:
        return .timeout
    default:
        return .serverError(
            code: "\(grpcError.code)",
            message: grpcError.message ?? "Unknown error"
        )
    }
}
```

## Offline Support

### Operation Queue
```swift
enum OfflineOperation: Codable {
    case createLesson(Lesson)
    case updateLesson(Lesson)
    case deleteLesson(id: String)
    case uploadDocument(Document)
}

final class OfflineOperationQueue {
    static let shared = OfflineOperationQueue()
    
    private let queue = DispatchQueue(label: "offline.queue", attributes: .concurrent)
    private let storage: UserDefaults
    private let key = "offline_operations"
    
    func enqueue(_ operation: OfflineOperation) async throws {
        queue.async(flags: .barrier) {
            var operations = self.loadOperations()
            operations.append(operation)
            self.saveOperations(operations)
        }
    }
    
    func processQueue() async {
        guard NetworkMonitor.shared.isConnected else { return }
        
        let operations = loadOperations()
        var failedOperations: [OfflineOperation] = []
        
        for operation in operations {
            do {
                try await processOperation(operation)
            } catch {
                failedOperations.append(operation)
                Logger.shared.error("Failed to process offline operation: \(error)")
            }
        }
        
        // Save failed operations back to queue
        saveOperations(failedOperations)
    }
    
    private func processOperation(_ operation: OfflineOperation) async throws {
        switch operation {
        case .createLesson(let lesson):
            _ = try await LessonService.shared.createLesson(lesson)
        case .updateLesson(let lesson):
            _ = try await LessonService.shared.updateLesson(lesson)
        case .deleteLesson(let id):
            try await LessonService.shared.deleteLesson(id: id)
        case .uploadDocument(let document):
            _ = try await DocumentService.shared.upload(document)
        }
    }
}
```

### Network Monitor
```swift
import Network

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "network.monitor")
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        
        monitor.start(queue: queue)
    }
}
```

## Streaming Patterns

### Server-Side Streaming
```swift
extension LessonService {
    func observeProcessingUpdates() -> AsyncStream<ProcessingUpdate> {
        AsyncStream { continuation in
            let task = Task {
                do {
                    let stream = grpcClient.streamAllProcessingUpdates(Empty())
                    
                    for try await update in stream {
                        // Filter updates for current user
                        if update.userID == AuthService.shared.currentUserID {
                            continuation.yield(ProcessingUpdate(from: update))
                        }
                    }
                } catch {
                    Logger.shared.error("Stream error: \(error)")
                }
                
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
```

### Bidirectional Streaming
```swift
func syncDocuments() async throws {
    let call = grpcClient.syncDocuments()
    
    // Send local changes
    let localChanges = try await DocumentStore.shared.getPendingChanges()
    for change in localChanges {
        try await call.sendMessage(change.toProto())
    }
    try await call.sendEnd()
    
    // Receive remote changes
    for try await remoteChange in call.responseMessages {
        try await DocumentStore.shared.applyRemoteChange(remoteChange)
    }
}
```

## Performance Optimization

### Request Batching
```swift
actor BatchedRequestManager {
    private var pendingRequests: [String: PendingRequest] = [:]
    private let batchSize = 10
    private let batchDelay: TimeInterval = 0.5
    
    func fetchDocument(id: String) async throws -> Document {
        if let pending = pendingRequests[id] {
            return try await pending.continuation.value
        }
        
        let continuation = AsyncThrowingStream<Document, Error>.Continuation()
        pendingRequests[id] = PendingRequest(id: id, continuation: continuation)
        
        // Schedule batch processing
        Task {
            try await Task.sleep(nanoseconds: UInt64(batchDelay * 1_000_000_000))
            await processBatch()
        }
        
        return try await withTaskCancellationHandler {
            try await continuation.value
        } onCancel: {
            Task { await self.cancelRequest(id: id) }
        }
    }
    
    private func processBatch() async {
        let batch = Array(pendingRequests.prefix(batchSize))
        guard !batch.isEmpty else { return }
        
        // Remove from pending
        batch.forEach { pendingRequests.removeValue(forKey: $0.key) }
        
        do {
            let request = BatchGetDocumentsRequest.with {
                $0.documentIds = batch.map { $0.value.id }
            }
            
            let response = try await grpcClient.batchGetDocuments(request)
            
            // Resolve continuations
            for document in response.documents {
                if let pending = batch.first(where: { $0.value.id == document.id }) {
                    pending.value.continuation.yield(Document(from: document))
                    pending.value.continuation.finish()
                }
            }
        } catch {
            // Reject all continuations
            batch.forEach { $0.value.continuation.finish(throwing: error) }
        }
    }
}
```

## Best Practices

1. **Always handle offline scenarios** - Queue operations when offline
2. **Use streaming for real-time updates** - Avoid polling
3. **Implement proper retry logic** - With exponential backoff
4. **Add request/response logging** - But sanitize sensitive data
5. **Use interceptors for cross-cutting concerns** - Auth, logging, metrics
6. **Cache aggressively** - Reduce network calls
7. **Batch requests when possible** - Improve efficiency
8. **Handle errors gracefully** - Map to user-friendly messages
9. **Monitor network status** - Adapt behavior accordingly
10. **Test with network conditions** - Simulate poor connectivity 