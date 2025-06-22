# gRPC Swift v2 - Consolidated Documentation

## Overview

This document consolidates all gRPC Swift v2 migration information for the Class Notes iOS/iPadOS frontend. It replaces the following documents:
- GRPC_SWIFT_2_MIGRATION.md
- GRPC_V2_FRONTEND_SUMMARY.md
- GRPC_RESOLUTION_FINAL.md
- GRPC_SWIFT_V2_FIX_GUIDE.md
- GRPC_V2_FINAL_FIX_SUMMARY.md
- GRPC_V2_INTERCEPTOR_FIXES_SUMMARY.md
- GRPC_V2_METADATA_FIX_SUMMARY.md
- GRPC_V2_URL_FIXES_SUMMARY.md
- GRPC_IMPLEMENTATION_REPORT.md
- GRPC_ERROR_RECURRENCE_REPORT.md
- And other gRPC-related files

**Migration Status: ✅ COMPLETE**

## Quick Reference

### Package Dependencies
```swift
dependencies: [
    .package(url: "https://github.com/grpc/grpc-swift-2", exact: "1.0.0"),
    .package(url: "https://github.com/grpc/grpc-swift-nio-transport", exact: "1.0.0"),
    .package(url: "https://github.com/grpc/grpc-swift-protobuf", exact: "2.0.0")
]
```

### Import Changes
- Old: `import GRPC` → New: `import GRPCCore, GRPCProtobuf, GRPCNIOTransportHTTP2`
- Client: `EventLoop-based` → `async/await with GRPCClient`
- Errors: `GRPCStatus` → `RPCError`

## Architecture

### Transport Configuration
```swift
// Development
HTTP2ClientTransport.Posix(
    target: .dns(host: "localhost", port: 8080),
    config: .defaults()
)

// Production
HTTP2ClientTransport.Posix(
    target: .dns(host: "api.classnotes.com", port: 443),
    config: .defaults(configure: { config in
        config.tls.configure { tls in
            tls.updateFromEnvironment()
        }
    })
)
```

### Service Pattern
```swift
@MainActor
final class ClassNotesService {
    static let shared = ClassNotesService()
    private let client: Classnotes_V1_ClassNotesAPI.Client
    
    func getClassNote(id: String) async throws -> Lesson {
        let request = Classnotes_V1_GetClassNoteRequest.with { $0.id = id }
        let response = try await client.getClassNote(request)
        return Lesson(from: response.note)
    }
}
```

### Interceptor Implementation
```swift
struct AuthInterceptor<Output: Sendable>: ClientInterceptor {
    func intercept<Input: Sendable>(
        request: inout ClientRequest<Input>,
        context: ClientContext,
        next: (ClientRequest<Input>, ClientContext) async throws -> ClientResponse<Output>
    ) async throws -> ClientResponse<Output> {
        if let token = await getAuthToken() {
            request.metadata["authorization"] = "Bearer \(token)"
        }
        return try await next(request, context)
    }
}
```

## Key Components

- **GRPCClientProvider**: Centralized client management with @GRPCClientActor
- **AuthenticationService**: Firebase Auth integration with @MainActor
- **AppCheckServiceV2**: App attestation with custom @AppCheckActor
- **Interceptors**: Auth, AppCheck, Logging, Retry - all using ClientInterceptor protocol

## Migration Guidelines

### From v1 to v2
1. Update Package.swift dependencies
2. Replace imports throughout codebase
3. Convert completion handlers to async/await
4. Update interceptors to new protocol
5. Add actor isolation where appropriate
6. Update error handling to use RPCError

### Common Issues & Solutions
- **Package Conflicts**: Run `Scripts/clean-packages.sh` to clear all caches
- **Import Errors**: Use the correct module imports (GRPCCore, not GRPC)
- **Xcode Issues**: Use Scripts/generate-protos-direct.sh for external generation

## Proto Generation

### Using buf (Recommended)
```yaml
# buf.gen.yaml
version: v2
plugins:
  - remote: buf.build/apple/swift:v2.0.0
    out: GeneratedProtos/Sources/GeneratedProtos
  - remote: buf.build/grpc/swift:v2.0.0
    out: GeneratedProtos/Sources/GeneratedProtos
```

### Manual Generation
```bash
./Scripts/generate-protos-direct.sh
```

## Testing

### Unit Tests
- All interceptor tests migrated to async/await
- Mock infrastructure in GRPCTestMocks.swift
- Use XCTestExpectation for async operations

### Integration Tests
- Full end-to-end flow testing
- Proper task cancellation in tearDown
- Environment-specific configurations

## Production Deployment

### Requirements
- iOS 18.0+ / macOS 15.0+
- Xcode 16.0+
- Swift 6.0+

### Performance Optimizations
- HTTP/2 multiplexing
- Connection pooling
- Request coalescing
- Proper task lifecycle management

## Related Resources
- [gRPC Swift 2 Documentation](https://swiftpackageindex.com/grpc/grpc-swift-2/documentation)
- [Migration Guide](https://github.com/grpc/grpc-swift-2/blob/main/docs/migration-guide.md) 