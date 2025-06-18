# gRPC Swift v2 Interceptor Migration Guide

## Overview

All gRPC interceptors have been successfully migrated from gRPC Swift v1 to v2. This guide documents the changes made and how to use the updated interceptors.

## Key Changes in gRPC Swift v2

### 1. Protocol Changes
- **Old**: Multiple protocols (`UnaryInterceptor`, `StreamingInterceptor`)
- **New**: Single unified `ClientInterceptor` protocol

### 2. Method Signature
```swift
// Old (v1)
func intercept<Input, Output>(
    request: StreamingClientRequest<Input>,
    context: ClientContext,
    next: @escaping @Sendable (
        StreamingClientRequest<Input>,
        ClientContext
    ) async throws -> StreamingClientResponse<Output>
) async throws -> StreamingClientResponse<Output>

// New (v2)
func intercept<Input, Output>(
    request: ClientRequest<Input>,
    context: ClientContext,
    next: @Sendable (
        ClientRequest<Input>,
        ClientContext
    ) async throws -> ClientResponse<Output>
) async throws -> ClientResponse<Output>
```

### 3. Request/Response Types
- **Old**: `StreamingClientRequest`/`StreamingClientResponse`
- **New**: `ClientRequest`/`ClientResponse` (unified for both unary and streaming)

### 4. Metadata Handling
- **Old**: Complex metadata API
- **New**: Immutable `Metadata` type that requires creating new instances

#### Important: Metadata is Immutable in v2

```swift
// ❌ WRONG - This doesn't work in v2
modifiedRequest.metadata[key] = value

// ✅ CORRECT - Create new metadata
// 1. Collect headers from existing metadata
var headers: [(String, String)] = []
for (key, values) in request.metadata {
    for value in values {
        headers.append((key, value))
    }
}

// 2. Add new headers
headers.append(("authorization", "Bearer token"))

// 3. Create new metadata instance
let newMetadata = Metadata(headers)

// 4. Create new request with updated metadata
let modifiedRequest = ClientRequest(
    message: request.message,
    metadata: newMetadata
)
```

#### Metadata Values are Arrays

When reading metadata, remember that values are arrays:

```swift
// Reading metadata values
if let values = response.metadata["key"] {
    // values is [String], not String
    if let firstValue = values.first {
        // Use firstValue
    }
}
```

## Updated Interceptors

### 1. AuthInterceptor
**Purpose**: Handles authentication by adding Bearer tokens to requests

**Key Features**:
- Automatically adds auth token from Keychain
- Adds User-Agent header
- Can extract and store new tokens from responses
- Thread-safe with Sendable conformance

**Usage**:
```swift
let authInterceptor = AuthInterceptor()
```

### 2. LoggingInterceptor
**Purpose**: Logs gRPC requests and responses for debugging

**Key Features**:
- Three log levels: `.none`, `.basic`, `.detailed`
- Logs method names, duration, and status
- Safely logs headers (excludes sensitive data in production)
- Formatted duration output (µs, ms, s)

**Usage**:
```swift
// Basic logging
let logger = LoggingInterceptor(logLevel: .basic)

// Detailed logging for debugging
let detailedLogger = LoggingInterceptor(logLevel: .detailed)
```

### 3. RetryInterceptor
**Purpose**: Automatically retries failed requests with exponential backoff

**Key Features**:
- Configurable retry count and backoff strategy
- Only retries specific error codes
- Respects server retry-after headers
- Pre-configured profiles (default, aggressive, conservative)

**Usage**:
```swift
// Default configuration
let retry = RetryInterceptor.default

// Aggressive retries for unreliable networks
let aggressiveRetry = RetryInterceptor.aggressive

// Custom configuration
let customRetry = RetryInterceptor(
    maxRetries: 5,
    retryableStatusCodes: [.unavailable, .deadlineExceeded],
    initialBackoff: 0.1,
    backoffMultiplier: 2.0,
    maxBackoff: 10.0
)
```

### 4. AppCheckInterceptor
**Purpose**: Adds Firebase App Check tokens for security

**Key Features**:
- Integrates with Firebase App Check
- Different behavior for debug/release builds
- Adds platform and bundle ID headers
- Configurable requirement level

**Usage**:
```swift
// Production mode (requires App Check)
let appCheck = AppCheckInterceptor.production

// Development mode (allows failures)
let devAppCheck = AppCheckInterceptor.development
```

## Interceptor Chaining

Interceptors should be ordered carefully for proper functionality:

```swift
let interceptors: [any ClientInterceptor] = [
    LoggingInterceptor(),      // First: logs all activity
    AuthInterceptor(),         // Second: adds auth
    RetryInterceptor(),        // Third: handles retries
    AppCheckInterceptor()      // Last: adds security tokens
]
```

## Integration with gRPC Client

```swift
import GRPCCore
import GRPCNIOTransportHTTP2

// Create transport
let transport = try GRPCNIOTransportHTTP2.TransportConnector(
    target: .host("api.example.com", port: 443),
    config: .defaults(transportSecurity: .tls)
)

// Create client with interceptors
let client = GRPCClient(
    transport: transport,
    interceptors: [
        LoggingInterceptor(logLevel: .basic),
        AuthInterceptor(),
        RetryInterceptor.default,
        AppCheckInterceptor.production
    ]
)
```

## Testing

All interceptors are designed to be testable:

```swift
// Test interceptor chain
let testInterceptors: [any ClientInterceptor] = [
    LoggingInterceptor(logLevel: .detailed),
    AuthInterceptor(),
    RetryInterceptor.noRetry,  // No retries in tests
    AppCheckInterceptor.development
]
```

## Migration Checklist

- [x] Update all interceptors to implement `ClientInterceptor`
- [x] Change request/response types from Streaming variants
- [x] Update metadata handling to create new instances
- [x] Handle metadata values as arrays
- [x] Ensure Sendable conformance
- [x] Remove @escaping from next parameter
- [x] Test interceptor chaining
- [x] Update error handling for RPCError

## Common Issues and Solutions

### Issue 1: Metadata not being added
**Solution**: Metadata is immutable, create new instances:
```swift
// Collect existing headers
var headers: [(String, String)] = []
for (key, values) in request.metadata {
    for value in values {
        headers.append((key, value))
    }
}
// Add new headers
headers.append(("key", "value"))
// Create new metadata
let newMetadata = Metadata(headers)
```

### Issue 2: Type errors with metadata values
**Solution**: Metadata values are arrays, not single values:
```swift
// Wrong
let value: String = metadata["key"]  // ❌

// Correct
if let values = metadata["key"], let value = values.first {
    // Use value
}  // ✅
```

### Issue 3: Cannot assign through subscript
**Solution**: Create new `ClientRequest` with new metadata:
```swift
let modifiedRequest = ClientRequest(
    message: request.message,
    metadata: newMetadata
)
```

## Best Practices

1. **Order matters**: Place logging first, authentication/retry in middle, security last
2. **Error handling**: Let RPCErrors propagate, wrap other errors appropriately
3. **Performance**: Avoid expensive operations in interceptors
4. **Testing**: Use mock interceptors for unit tests
5. **Configuration**: Use static factory methods for common configurations
6. **Metadata handling**: Always create new metadata instances, never try to mutate 