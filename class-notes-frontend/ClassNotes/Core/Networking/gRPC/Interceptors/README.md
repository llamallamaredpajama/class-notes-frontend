# gRPC Swift v2 Interceptors

This directory contains gRPC interceptors that have been migrated to work with gRPC Swift v2.

## Quick Start

### Creating a gRPC Client

```swift
import GRPCCore
import GRPCNIOTransportHTTP2
import NIOCore
import NIOPosix

// 1. Create transport
let transport = try HTTP2ClientTransport(
    target: .dns(host: "api.example.com", port: 443),
    config: .defaults,
    eventLoopGroup: .singleton
)

// 2. Create gRPC client with interceptors
let grpcClient = GRPCClient(
    transport: transport,
    interceptors: [
        LoggingInterceptor(),
        AuthInterceptor(),
        RetryInterceptor.default,
        AppCheckInterceptor.production
    ]
)

// 3. Create service-specific client
let serviceClient = YourService.Client(wrapping: grpcClient)

// 4. Make calls
let response = try await serviceClient.yourMethod(request)
```

## Available Interceptors

### AuthInterceptor
Automatically adds authentication tokens to requests.

```swift
let auth = AuthInterceptor()
```

### LoggingInterceptor
Logs gRPC requests and responses for debugging.

```swift
let logger = LoggingInterceptor(logLevel: .basic)  // .none, .basic, .detailed
```

### RetryInterceptor
Automatically retries failed requests with exponential backoff.

```swift
let retry = RetryInterceptor.default       // Standard retry policy
let retry = RetryInterceptor.aggressive    // More retries, shorter backoff
let retry = RetryInterceptor.conservative  // Fewer retries, longer backoff
let retry = RetryInterceptor.noRetry       // Disable retries
```

### AppCheckInterceptor
Adds Firebase App Check tokens for security.

```swift
let appCheck = AppCheckInterceptor.production   // Requires valid App Check
let appCheck = AppCheckInterceptor.development  // Allows failures
```

## Transport Configuration

### Basic TLS Configuration

```swift
let transport = try HTTP2ClientTransport(
    target: .dns(host: "api.example.com", port: 443),
    config: .defaults,  // Uses TLS by default
    eventLoopGroup: .singleton
)
```

### Custom Configuration

```swift
let config = HTTP2ClientTransport.Config(
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
        enabledAlgorithms: [.gzip]
    ),
    backoff: .defaults
)

let transport = try HTTP2ClientTransport(
    target: .dns(host: "api.example.com", port: 443),
    config: config,
    eventLoopGroup: eventLoopGroup
)
```

## Metadata Handling

Metadata in gRPC Swift v2 is immutable. To add headers:

```swift
// Create metadata
var headers: [(String, String)] = []
headers.append(("x-request-id", UUID().uuidString))
headers.append(("x-custom-header", "value"))
let metadata = Metadata(headers)

// Use in request
let response = try await client.yourMethod(
    request,
    metadata: metadata
)
```

## Complete Example

See `InterceptorChainExample.swift` for a complete working example that demonstrates:

- Creating typed service clients
- Configuring interceptors for production/development
- Custom transport configuration
- Proper resource cleanup
- Making authenticated calls with custom metadata

## Common Issues

### Issue: "Reference to generic type 'GRPCClient' requires arguments"
**Solution**: GRPCClient needs the transport type:
```swift
let grpcClient = GRPCClient(transport: transport, interceptors: [...])
let serviceClient = YourService.Client(wrapping: grpcClient)
```

### Issue: "Cannot assign through subscript: subscript is get-only"
**Solution**: Metadata is immutable, create new instances:
```swift
var headers: [(String, String)] = []
headers.append(("key", "value"))
let metadata = Metadata(headers)
```

### Issue: Transport configuration errors
**Solution**: Use HTTP2ClientTransport with proper config:
```swift
let transport = try HTTP2ClientTransport(
    target: .dns(host: "host", port: 443),
    config: .defaults,
    eventLoopGroup: .singleton
)
```

## Migration from v1

See `GRPC_V2_INTERCEPTOR_MIGRATION.md` for detailed migration guide from gRPC Swift v1 to v2. 