# Networking & gRPC Integration

## ⚠️ CRITICAL: gRPC-Swift v2 Requirements

**ALWAYS USE gRPC-Swift v2 (NOT v1)**
- **Repository**: `https://github.com/grpc/grpc-swift-2` (NOT grpc-swift)
- **Version**: 2.0.0 or later
- **Required Packages**:
  - `grpc-swift-2` → Provides GRPCCore module
  - `grpc-swift-nio-transport` → Provides GRPCNIOTransportHTTP2 module
  - `grpc-swift-protobuf` → Provides GRPCProtobuf module (v2.x from https://github.com/grpc/grpc-swift-protobuf)

**⚠️ COMMON MISTAKES TO AVOID**:
- DO NOT use `https://github.com/grpc/grpc-swift` (this is v1 in maintenance mode)
- DO NOT trust version numbers alone - grpc-swift v1 shows 2.x.x versions but is still v1 API
- DO NOT regenerate protos inside Xcode - use GeneratedProtos package approach
- DO NOT put buf.gen.yaml files in Frontend directories

## Proto Generation Strategy

### MANDATORY: Use External Proto Generation
To prevent Xcode compilation errors, protos MUST be generated outside of Xcode:

```bash
# Use Scripts/generate-protos-direct.sh
# This creates a GeneratedProtos package that's added as a local dependency
# NEVER generate protos directly in the main project
```

### GeneratedProtos Package Structure
```
GeneratedProtos/
├── Package.swift          # At root, NOT in Sources/
├── Sources/
│   └── GeneratedProtos/
│       ├── classnotes_service.pb.swift
│       └── classnotes_service.grpc.swift
```

## gRPC Client Architecture (v2)

### Client Manager (gRPC-Swift v2)
```swift
import GRPCCore
import GRPCNIOTransportHTTP2

@GRPCClientActor
final class GRPCClientProvider {
    static let shared = GRPCClientProvider()
    
    private let transport: HTTP2ClientTransport.Posix
    private let client: GRPCClient<HTTP2ClientTransport.Posix>
    
    init() {
        self.transport = HTTP2ClientTransport.Posix(
            target: .dns(host: Config.apiHost, port: Config.apiPort),
            config: .defaults(transportSecurity: .tls)
        )
        
        // Use concrete type, NOT protocol
        self.client = GRPCClient(
            transport: transport,
            interceptors: [
                AuthInterceptor(),
                AppCheckInterceptor(),
                LoggingInterceptor(),
                RetryInterceptor()
            ]
        )
    }
    
    func getServiceClient() -> Classnotes_V1_ClassNotesAPI.Client {
        return Classnotes_V1_ClassNotesAPI.Client(wrapping: client)
    }
}
```

## Interceptors (gRPC-Swift v2)

### CRITICAL: Correct v2 Interceptor Pattern
```swift
import GRPCCore

// CORRECT v2.0.0 signature - Output is the second generic parameter
struct AuthInterceptor: ClientInterceptor {
    typealias Output = ClientResponse
    
    func intercept<Input: Sendable, Interceptor>(
        request: ClientRequest<Input>,
        context: ClientInterceptorContext<Input, ClientResponse>,
        next: @Sendable (
            ClientRequest<Input>,
            ClientInterceptorContext<Input, ClientResponse>
        ) async throws -> ClientResponse
    ) async throws -> ClientResponse {
        var modifiedRequest = request
        
        // v2 Metadata is immutable - create new instance
        if let token = await AuthenticationService.shared.currentToken {
            var newMetadata = request.metadata
            newMetadata.addString("Bearer \(token)", forKey: "authorization")
            modifiedRequest.metadata = newMetadata
        }
        
        return try await next(modifiedRequest, context)
    }
}
```

### Metadata Handling in v2
```swift
// WRONG - v1 pattern
metadata["key"] = "value"
metadata.add(name: "key", value: "value")

// CORRECT - v2 pattern
var newMetadata = metadata
newMetadata.addString("value", forKey: "key")

// Reading metadata in v2
if let values = metadata.strings(forKey: "key") {
    let value = values.first ?? ""
}

// Iterating metadata in v2
for (key, value) in metadata {
    // Note: NOT (key, values) - singular value
    print("\(key): \(String(value))")
}
```

### Logging Interceptor (v2)
```swift
import GRPCCore
import OSLog

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
    
    private let grpcClient: Classnotes_V1_ClassNotesAPI.Client
    private let cacheManager: CacheManager
    private let offlineQueue: OfflineOperationQueue
    
    init(
        grpcClient: Classnotes_V1_ClassNotesAPI.Client? = nil,
        cacheManager: CacheManager = .shared,
        offlineQueue: OfflineOperationQueue = .shared
    ) {
        self.grpcClient = grpcClient ?? GRPCClientProvider.shared.getServiceClient()
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
        let request = Classnotes_V1_CreateLessonRequest.with {
            $0.title = lesson.title
            $0.subject = lesson.subject
            $0.classroomID = lesson.classroomId
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