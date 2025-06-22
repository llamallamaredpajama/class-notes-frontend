# gRPC-Swift v2 Migration Guide

## ⚠️ CRITICAL WARNING: Version Confusion

The most common and frustrating error when working with gRPC-Swift is using v1 APIs while thinking you're using v2.

### The Version Number Trap
- ❌ **grpc-swift** repository shows version 2.x.x but is actually v1 in maintenance mode
- ✅ **grpc-swift-2** repository shows version 1.x.x and is the actual v2 with new APIs

### Correct Repository URLs
```swift
// ✅ CORRECT - gRPC-Swift v2
.package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0")
.package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.0.0")
.package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0")

// ❌ WRONG - gRPC-Swift v1 (despite showing 2.x.x versions)
.package(url: "https://github.com/grpc/grpc-swift.git", ...)
```

## Common Compilation Errors and Solutions

### Error: "Type 'X' does not conform to protocol 'ClientInterceptor'"
**Cause**: Using v1 interceptor pattern with v2
**Solution**: Use correct v2 signature with Output as second generic parameter:
```swift
// ✅ CORRECT v2
struct AuthInterceptor: ClientInterceptor {
    typealias Output = ClientResponse
    
    func intercept<Input: Sendable, Interceptor>(...) async throws -> ClientResponse
}

// ❌ WRONG v1
class AuthInterceptor: ClientInterceptor<Request, Response> {
    override func send(...) { }
}
```

### Error: "Cannot convert Metadata.Value to String"
**Cause**: v2 Metadata API is different from v1
**Solution**:
```swift
// ✅ CORRECT v2
for (key, value) in metadata {
    let stringValue = String(value)  // Convert explicitly
}

// ❌ WRONG v1
for (key, values) in metadata {  // Note: values is plural in v1
    let value = values.first
}
```

### Error: "Value of type 'Metadata' has no member 'add'"
**Cause**: v2 Metadata is immutable
**Solution**:
```swift
// ✅ CORRECT v2
var newMetadata = request.metadata
newMetadata.addString("value", forKey: "key")
modifiedRequest.metadata = newMetadata

// ❌ WRONG v1
request.metadata.add(name: "key", value: "value")
```

### Error: "Firebase/WhisperKit test warnings from .build directories"
**Cause**: Package resolution creates .build directories that Xcode scans
**Solution**:
1. Delete all .build directories
2. Clean derived data
3. Use GeneratedProtos package approach

## Proto Generation Best Practices

### The buf.gen.yaml Problem
**Issue**: Having buf.gen.yaml files in Frontend directories causes Xcode to regenerate protos during build, leading to version conflicts.

**Solution**: NEVER place buf.gen.yaml in Frontend directories. Generate protos externally:

```bash
# Generate in separate package
cd GeneratedProtos
buf generate --template ../DevOps/proto-management/buf.gen.yaml

# Remove any Frontend buf.gen.yaml files
find Frontend -name "buf.gen.yaml" -delete
```

### GeneratedProtos Package Structure
```
GeneratedProtos/
├── Package.swift          # ⚠️ MUST be at root, NOT in Sources/
├── README.md
└── Sources/
    └── GeneratedProtos/
        ├── classnotes_service.pb.swift
        └── classnotes_service.grpc.swift
```

## Client Implementation Patterns

### Use Concrete Types, Not Protocols
```swift
// ✅ CORRECT - Concrete type
private let client: GRPCClient<HTTP2ClientTransport.Posix>

// ❌ WRONG - Protocol doesn't exist in v2
private let client: ClientProtocol
```

### Correct Transport Configuration
```swift
// ✅ CORRECT v2
let transport = HTTP2ClientTransport.Posix(
    target: .dns(host: "api.example.com", port: 443),
    config: .defaults(transportSecurity: .tls)
)

// ❌ WRONG v1
let channel = ClientConnection(configuration: ...)
```

## Interceptor Patterns

### Complete v2 Interceptor Template
```swift
import GRPCCore

struct MyInterceptor: ClientInterceptor {
    typealias Output = ClientResponse
    
    func intercept<Input: Sendable, Interceptor>(
        request: ClientRequest<Input>,
        context: ClientInterceptorContext<Input, ClientResponse>,
        next: @Sendable (
            ClientRequest<Input>,
            ClientInterceptorContext<Input, ClientResponse>
        ) async throws -> ClientResponse
    ) async throws -> ClientResponse {
        // Modify request if needed
        var modifiedRequest = request
        
        // Call next interceptor
        let response = try await next(modifiedRequest, context)
        
        // Return response
        return response
    }
}
```

### Common Interceptor Mistakes
1. **Using @escaping instead of @Sendable**
2. **Missing typealias Output = ClientResponse**
3. **Using wrong generic parameters**
4. **Trying to mutate metadata directly**

## Debugging Tips

### 1. Verify Package Versions
```bash
# Check Package.resolved
cat Package.resolved | grep -A 3 "grpc-swift"
```

### 2. Clean Everything
```bash
# Complete cleanup script
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf .build
rm -rf .swiftpm
find . -name "Package.resolved" -delete
find . -name "buf.gen.yaml" -path "*/Frontend/*" -delete
```

### 3. Check Import Statements
```swift
// ✅ CORRECT v2 imports
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf

// ❌ WRONG v1 imports
import GRPC
import NIO
```

## Memory Aids

### Quick Version Check
- If you see `ClientConnection`, `EventLoopGroup`, `CallOptions` → You're using v1
- If you see `GRPCClient`, `HTTP2ClientTransport`, `ClientRequest` → You're using v2

### API Mapping v1 → v2
| v1 API | v2 API |
|--------|--------|
| ClientConnection | HTTP2ClientTransport.Posix |
| EventLoopGroup | Not needed |
| CallOptions | Part of ClientRequest |
| GRPCChannel | GRPCClient |
| ClientInterceptor<Req,Res> | ClientInterceptor with Output typealias |
| metadata.add() | Create new metadata instance |

## Troubleshooting Checklist

When encountering gRPC errors:
1. ✓ Verify using grpc-swift-2 repository (not grpc-swift)
2. ✓ Check Package.resolved for correct versions
3. ✓ Ensure no buf.gen.yaml in Frontend directories
4. ✓ Verify GeneratedProtos Package.swift is at root
5. ✓ Check all interceptors use v2 pattern
6. ✓ Ensure using concrete GRPCClient type
7. ✓ Clean all build artifacts and derived data
8. ✓ Re-add packages in Xcode if needed

## References
- [gRPC-Swift v2 Repository](https://github.com/grpc/grpc-swift-2)
- [Migration Guide](https://github.com/grpc/grpc-swift/blob/main/docs/v2-migration-guide.md)
- [v2 Documentation](https://swiftpackageindex.com/grpc/grpc-swift-2/documentation) 