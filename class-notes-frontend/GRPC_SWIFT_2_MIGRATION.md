# gRPC Swift 2 Migration Guide

## Overview

This guide covers the migration from grpc-swift 1.x to grpc-swift 2.x for the ClassNotes iOS app.

## What's Changed

### 1. **Package Dependencies**

**Old packages (grpc-swift 1.x):**
- `grpc-swift` (single package)

**New packages (grpc-swift 2.x):**
- `grpc-swift-2` - Core runtime
- `grpc-swift-nio-transport` - HTTP/2 transport  
- `grpc-swift-protobuf` - Protocol Buffers integration

### 2. **Imports**

**Old:**
```swift
import GRPC
import NIO
```

**New:**
```swift
import GRPCCore
import GRPCNIOTransportHTTP2
```

### 3. **Client Creation**

**Old (EventLoop-based):**
```swift
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let channel = ClientConnection.usingPlatformAppropriateTLS(for: eventLoopGroup)
    .connect(host: host, port: port)
let client = Classnotes_V1_ClassNotesAPIAsyncClient(channel: channel)
```

**New (async/await):**
```swift
let transport = try HTTP2ClientTransport.Posix(
    target: .ipv4(host: host, port: port),
    transportSecurity: .tls
)
let client = GRPCClient(transport: transport)
let apiClient = Classnotes_V1_ClassNotesAPIClient(wrapping: client)
```

### 4. **Interceptors**

**Old:**
```swift
class AuthInterceptor<Request, Response>: ClientInterceptor<Request, Response> {
    override func send(_ part: GRPCClientRequestPart<Request>, ...) { }
    override func receive(_ part: GRPCClientResponsePart<Response>, ...) { }
}
```

**New:**
```swift
struct AuthInterceptor: ClientInterceptor {
    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: @Sendable (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> { }
}
```

### 5. **Error Handling**

**Old:**
```swift
catch let status as GRPCStatus {
    if status.code == .unauthenticated { }
}
```

**New:**
```swift
catch let error as RPCError {
    if error.code == .unauthenticated { }
}
```

## Migration Steps

### Step 1: Update Package Dependencies
✅ Remove old `grpc-swift` package
✅ Add new packages:
   - `grpc-swift-2`
   - `grpc-swift-nio-transport`
   - `grpc-swift-protobuf`

### Step 2: Update Core Components
✅ `GRPCClientManager.swift` - Updated to use new client creation
✅ `AuthInterceptor.swift` - Updated to new interceptor API
✅ `LoggingInterceptor.swift` - Updated to new interceptor API
✅ `RetryInterceptor.swift` - Updated with built-in retry logic
✅ `SubscriptionService.swift` - Updated to use new client

### Step 3: Install Code Generation Tools
Run the installation script:
```bash
cd Frontend/class-notes-frontend/Scripts
./install-grpc-tools.sh
```

### Step 4: Regenerate Proto Files
Run the generation script:
```bash
cd Frontend/class-notes-frontend/Scripts
./generate-protos-simple.sh
```

### Step 5: Update Remaining Code
- Update any other files importing `GRPC` to use `GRPCCore`
- Update error handling from `GRPCStatus` to `RPCError`
- Update any direct gRPC calls to use the new async/await API

## Benefits of Migration

1. **Modern Swift Concurrency**: Full async/await support
2. **Simpler API**: More intuitive and Swift-like
3. **Better Performance**: Optimized for modern Swift
4. **Active Development**: grpc-swift 1.x is in maintenance mode
5. **Better Error Handling**: More consistent error types

## Testing

After migration:
1. Build the project
2. Run all unit tests
3. Test gRPC connectivity
4. Verify interceptors are working (auth, logging, retry)
5. Test subscription features

## Troubleshooting

### Common Issues:

1. **Import errors**: Make sure all three packages are added to your target
2. **Proto generation fails**: Ensure `protoc-gen-grpc-swift` is installed
3. **Runtime errors**: Check that the client is started with `await client.run()`
4. **Auth failures**: Verify the AuthInterceptor is properly adding headers

## Resources

- [gRPC Swift 2 Documentation](https://swiftpackageindex.com/grpc/grpc-swift-2/documentation)
- [Migration Guide](https://github.com/grpc/grpc-swift-2/blob/main/docs/migration-guide.md)
- [Examples](https://github.com/grpc/grpc-swift-2/tree/main/Examples) 