# Backend Integration Guide

## ⚠️ CRITICAL: gRPC-Swift v2 Package Requirements

**NEVER use gRPC-Swift v1 packages or patterns**. This project uses gRPC-Swift v2 exclusively.

### Correct Package Configuration
```swift
// Package.swift
import PackageDescription

let package = Package(
    name: "ClassNotes",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        // ✅ CORRECT - gRPC-Swift v2 packages
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.25.0"),
        
        // ❌ WRONG - DO NOT USE THESE
        // .package(url: "https://github.com/grpc/grpc-swift.git", ...) // This is v1!
    ],
    targets: [
        .target(
            name: "ClassNotesGRPC",
            dependencies: [
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]
        ),
    ]
)
```

### Proto Generation Best Practice
**MANDATORY**: Generate protos in a separate package to avoid Xcode compilation issues:

```bash
#!/bin/bash
# Scripts/generate-protos-direct.sh

# Generate in external directory
OUTPUT_DIR="../GeneratedProtos"
mkdir -p $OUTPUT_DIR/Sources/GeneratedProtos

# Use buf with v2 plugin
buf generate --template buf.gen.yaml

# Create Package.swift at root (NOT in Sources/)
cat > $OUTPUT_DIR/Package.swift << EOF
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GeneratedProtos",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "GeneratedProtos", targets: ["GeneratedProtos"])
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.25.0")
    ],
    targets: [
        .target(
            name: "GeneratedProtos",
            dependencies: [
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]
        )
    ]
)
EOF
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     iOS/iPadOS Frontend                      │
├─────────────────────────────────────────────────────────────┤
│  Views  │  ViewModels  │  Services  │  gRPC Client  │ Cache │
└────────────────────────┬────────────────────────────────────┘
                         │ gRPC + TLS
┌────────────────────────┴────────────────────────────────────┐
│                    Backend Gateway                           │
├─────────────────────────────────────────────────────────────┤
│  Auth  │  Rate Limiting  │  Load Balancing  │  Routing     │
└────────────────────────┬────────────────────────────────────┘
                         │ Pub/Sub Events
┌────────────────────────┴────────────────────────────────────┐
│                    Microservices                             │
├─────────────────────────────────────────────────────────────┤
│  OCR  │  AI Analysis  │  PDF Gen  │  Notifications  │ Subs │
└─────────────────────────────────────────────────────────────┘
```

## Protocol Buffer Integration

### Setup in Package.swift
```swift
// Package.swift
import PackageDescription

let package = Package(
    name: "ClassNotes",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.25.0"),
    ],
    targets: [
        .target(
            name: "ClassNotesGRPC",
            dependencies: [
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            path: "Sources/ClassNotesGRPC",
            resources: [
                .process("Protos")
            ]
        ),
    ]
)
```

### Proto File Sync Script
```bash
#!/bin/bash
# Scripts/sync-protos.sh

# ⚠️ IMPORTANT: Always regenerate using GeneratedProtos approach
# NEVER put generated files directly in the main project

BACKEND_PROTO_DIR="../class-notes-backend/proto"
GENERATED_DIR="../GeneratedProtos/Sources/GeneratedProtos"

# Copy proto files
cp -r $BACKEND_PROTO_DIR/* ../proto-temp/

# Generate using buf with v2 configuration
cd ../GeneratedProtos
buf generate --template ../class-notes-frontend/buf.gen.yaml

# Ensure no buf.gen.yaml files in Frontend
find ../class-notes-frontend -name "buf.gen.yaml" -delete
```

## Service Integration Patterns

### 1. Document Upload
```swift
extension DocumentService {
    func uploadDocument(_ document: LocalDocument) async throws -> RemoteDocument {
        // 1. Upload to Cloud Storage first
        let uploadURL = try await getUploadURL(for: document)
        try await uploadToStorage(document.data, to: uploadURL)
        
        // 2. Register with backend
        let request = UploadDocumentRequest.with {
            $0.metadata = DocumentMetadata.with {
                $0.title = document.title
                $0.mimeType = document.mimeType
                $0.size = Int64(document.data.count)
                $0.storageURL = uploadURL.absoluteString
                $0.lessonID = document.lessonID
            }
        }
        
        let response = try await grpcClient.uploadDocument(request)
        
        // 3. Start monitoring processing status
        Task {
            await monitorProcessingStatus(documentID: response.documentID)
        }
        
        return RemoteDocument(from: response)
    }
    
    private func monitorProcessingStatus(documentID: String) async {
        let request = StreamProcessingStatusRequest.with {
            $0.documentID = documentID
        }
        
        do {
            for try await status in grpcClient.streamProcessingStatus(request) {
                // Update UI
                await MainActor.run {
                    updateProcessingStatus(documentID: documentID, status: status)
                }
                
                // Check if complete
                if status.stage == .completed || status.stage == .failed {
                    break
                }
            }
        } catch {
            logger.error("Failed to monitor processing: \(error)")
        }
    }
}
```

### 2. Real-time Lesson Updates
```swift
@MainActor
final class LessonSyncManager: ObservableObject {
    @Published private(set) var syncStatus: SyncStatus = .idle
    private var updateStream: AsyncThrowingStream<LessonUpdate, Error>?
    
    func startSync() {
        Task {
            do {
                let stream = grpcClient.streamLessonUpdates(Empty())
                
                for try await update in stream {
                    await handleUpdate(update)
                }
            } catch {
                syncStatus = .error(error)
            }
        }
    }
    
    private func handleUpdate(_ update: LessonUpdate) async {
        switch update.updateType {
        case .created:
            await createLesson(from: update.lesson)
        case .updated:
            await updateLesson(from: update.lesson)
        case .deleted:
            await deleteLesson(id: update.lesson.id)
        case .processingComplete:
            await notifyProcessingComplete(for: update.lesson)
        default:
            break
        }
    }
}
```

### 3. Batch Operations
```swift
extension LessonService {
    func batchDelete(lessonIDs: [String]) async throws {
        // Show progress
        let progress = Progress(totalUnitCount: Int64(lessonIDs.count))
        
        // Batch into chunks
        let chunks = lessonIDs.chunked(into: 10)
        
        for chunk in chunks {
            let request = BatchDeleteLessonsRequest.with {
                $0.lessonIds = chunk
            }
            
            _ = try await grpcClient.batchDeleteLessons(request)
            progress.completedUnitCount += Int64(chunk.count)
        }
    }
}
```

## Authentication Integration

### Token Management
```swift
final class AuthTokenManager {
    private let keychain = KeychainService()
    private var currentToken: String?
    private var tokenRefreshTask: Task<String, Error>?
    
    func getValidToken() async throws -> String {
        // Check if we have a valid token
        if let token = currentToken, !isTokenExpired(token) {
            return token
        }
        
        // Check if refresh is already in progress
        if let refreshTask = tokenRefreshTask {
            return try await refreshTask.value
        }
        
        // Start refresh
        tokenRefreshTask = Task {
            defer { tokenRefreshTask = nil }
            
            let firebaseToken = try await Auth.auth().currentUser?.getIDToken()
            guard let token = firebaseToken else {
                throw AuthError.notAuthenticated
            }
            
            self.currentToken = token
            try keychain.store(token, for: .authToken)
            
            return token
        }
        
        return try await tokenRefreshTask!.value
    }
}
```

### Interceptor Implementation
```swift
final class AuthInterceptor: ClientInterceptor<Request, Response> {
    private let tokenManager: AuthTokenManager
    
    override func send(
        _ part: GRPCClientRequestPart<Request>,
        promise: EventLoopPromise<Void>?,
        context: ClientInterceptorContext<Request, Response>
    ) {
        switch part {
        case .metadata(var headers):
            // Get token synchronously from cache or fail
            if let token = tokenManager.cachedToken {
                headers.add(name: "authorization", value: "Bearer \(token)")
            }
            context.send(.metadata(headers), promise: promise)
            
        default:
            context.send(part, promise: promise)
        }
    }
}
```

## Error Handling

### Backend Error Mapping
```swift
extension GRPCStatus {
    var userFacingError: AppError {
        switch self.code {
        case .unauthenticated:
            return .authentication("Please sign in again")
            
        case .permissionDenied:
            return .authorization("You don't have permission")
            
        case .resourceExhausted:
            // Parse details for quota info
            if let details = self.message?.data(using: .utf8),
               let quota = try? JSONDecoder().decode(QuotaError.self, from: details) {
                return .quotaExceeded(
                    limit: quota.limit,
                    used: quota.used,
                    resetDate: quota.resetDate
                )
            }
            return .quotaExceeded(limit: 0, used: 0, resetDate: nil)
            
        case .notFound:
            return .notFound("Resource not found")
            
        case .alreadyExists:
            return .duplicate("This item already exists")
            
        case .deadlineExceeded:
            return .timeout("Request took too long")
            
        case .unavailable:
            return .offline("Service temporarily unavailable")
            
        default:
            return .unknown(self.message ?? "Unknown error")
        }
    }
}
```

### Retry Logic
```swift
func withRetry<T>(
    maxAttempts: Int = 3,
    delay: TimeInterval = 1.0,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            
            // Check if retryable
            if let grpcError = error as? GRPCStatus {
                switch grpcError.code {
                case .unavailable, .deadlineExceeded, .unknown:
                    // Retryable - continue
                    break
                default:
                    // Not retryable - throw immediately
                    throw error
                }
            }
            
            // Wait before retry (exponential backoff)
            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: UInt64(delay * pow(2, Double(attempt - 1)) * 1_000_000_000))
            }
        }
    }
    
    throw lastError ?? AppError.unknown("Retry failed")
}
```

## Event Handling

### CloudEvents Integration
```swift
struct CloudEvent: Codable {
    let id: String
    let source: String
    let type: String
    let specversion: String
    let time: Date
    let data: Data
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}

extension NotificationService {
    func handleCloudEvent(_ event: CloudEvent) async throws {
        switch event.type {
        case "com.classnotes.document.processed":
            let data = try event.decode(DocumentProcessedData.self)
            await handleDocumentProcessed(data)
            
        case "com.classnotes.quota.warning":
            let data = try event.decode(QuotaWarningData.self)
            await showQuotaWarning(data)
            
        case "com.classnotes.subscription.changed":
            let data = try event.decode(SubscriptionChangedData.self)
            await updateSubscriptionStatus(data)
            
        default:
            logger.warning("Unknown event type: \(event.type)")
        }
    }
}
```

## Performance Optimization

### Connection Pooling
```swift
final class GRPCConnectionPool {
    private let maxConnections = 3
    private var connections: [GRPCChannel] = []
    private var currentIndex = 0
    
    func getConnection() -> GRPCChannel {
        if connections.isEmpty {
            // Create initial connections
            for _ in 0..<maxConnections {
                connections.append(createChannel())
            }
        }
        
        // Round-robin selection
        let connection = connections[currentIndex]
        currentIndex = (currentIndex + 1) % connections.count
        
        return connection
    }
}
```

### Request Coalescing
```swift
actor RequestCoalescer<Request: Hashable, Response> {
    private var pendingRequests: [Request: [CheckedContinuation<Response, Error>]] = [:]
    private let processor: (Request) async throws -> Response
    
    init(processor: @escaping (Request) async throws -> Response) {
        self.processor = processor
    }
    
    func request(_ request: Request) async throws -> Response {
        // Check if request is already pending
        if pendingRequests[request] != nil {
            // Add to waiting list
            return try await withCheckedThrowingContinuation { continuation in
                pendingRequests[request]?.append(continuation)
            }
        }
        
        // First request - process it
        pendingRequests[request] = []
        
        do {
            let response = try await processor(request)
            
            // Fulfill all waiting requests
            let waiting = pendingRequests.removeValue(forKey: request) ?? []
            for continuation in waiting {
                continuation.resume(returning: response)
            }
            
            return response
        } catch {
            // Reject all waiting requests
            let waiting = pendingRequests.removeValue(forKey: request) ?? []
            for continuation in waiting {
                continuation.resume(throwing: error)
            }
            
            throw error
        }
    }
}
```

## Testing with Backend

### Mock gRPC Client
```swift
final class MockGRPCClient: ClassNotesServiceAsyncClient {
    var lessons: [Lesson_V1] = []
    var shouldFail = false
    var delay: TimeInterval = 0
    
    override func listLessons(
        _ request: ListLessonsRequest,
        callOptions: CallOptions? = nil
    ) async throws -> ListLessonsResponse {
        if shouldFail {
            throw GRPCStatus(code: .unavailable, message: "Mock error")
        }
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        return ListLessonsResponse.with {
            $0.lessons = lessons
        }
    }
}
```

### Integration Test Setup
```swift
class BackendIntegrationTests: XCTestCase {
    var client: ClassNotesServiceAsyncClient!
    
    override func setUp() async throws {
        // Use local backend for tests
        let channel = try GRPCChannelPool.with(
            target: .host("localhost", port: 8080),
            transportSecurity: .plaintext,
            eventLoopGroup: PlatformSupport.makeEventLoopGroup(loopCount: 1)
        )
        
        client = ClassNotesServiceAsyncClient(channel: channel)
    }
    
    func testDocumentProcessingFlow() async throws {
        // 1. Upload document
        let uploadResponse = try await client.uploadDocument(...)
        
        // 2. Monitor processing
        let statusStream = client.streamProcessingStatus(...)
        
        var lastStatus: ProcessingStatus?
        for try await status in statusStream {
            lastStatus = status
            if status.stage == .completed {
                break
            }
        }
        
        // 3. Verify completion
        XCTAssertEqual(lastStatus?.stage, .completed)
    }
}
```

## Best Practices

1. **Always use async/await** - Avoid callback-based APIs
2. **Handle offline gracefully** - Queue operations when offline
3. **Implement proper timeout handling** - Don't wait forever
4. **Use streaming for real-time updates** - Avoid polling
5. **Cache aggressively** - Reduce backend load
6. **Batch operations when possible** - Improve efficiency
7. **Monitor performance** - Track API latency
8. **Test with poor network** - Use Network Link Conditioner
9. **Implement circuit breakers** - Fail fast when backend is down
10. **Version your API calls** - Support backward compatibility 