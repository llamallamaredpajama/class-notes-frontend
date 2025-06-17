// 1. Standard library
import Foundation

// 2. Apple frameworks
import XCTest

// 3. Third-party dependencies
import GRPCCore
import SwiftProtobuf

// 4. Local modules
@testable import class_notes_frontend

// MARK: - Mock Request/Response Types

struct MockRequest: Sendable {
    let id: String
    let data: String
    
    init(id: String = UUID().uuidString, data: String = "test") {
        self.id = id
        self.data = data
    }
}

struct MockResponse: Sendable {
    let id: String
    let result: String
    
    init(id: String = UUID().uuidString, result: String = "success") {
        self.id = id
        self.result = result
    }
}

// MARK: - Mock Streaming Types

final class MockStreamingClientRequest<Input: Sendable>: StreamingClientRequest<Input> {
    private let _metadata: Metadata
    private var messages: [Input] = []
    
    init(metadata: Metadata = Metadata()) {
        self._metadata = metadata
    }
    
    var metadata: Metadata {
        return _metadata
    }
    
    func send(_ message: Input) async throws {
        messages.append(message)
    }
    
    func finish() async throws {
        // No-op for mock
    }
}

final class MockStreamingClientResponse<Output: Sendable>: StreamingClientResponse<Output> {
    private let _metadata: Metadata
    private let _messages: [Output]
    private var index = 0
    
    init(metadata: Metadata = Metadata(), messages: [Output] = []) {
        self._metadata = metadata
        self._messages = messages
    }
    
    var metadata: Metadata {
        return _metadata
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(messages: _messages)
    }
    
    struct AsyncIterator: AsyncIteratorProtocol {
        private let messages: [Output]
        private var index = 0
        
        init(messages: [Output]) {
            self.messages = messages
        }
        
        mutating func next() async throws -> Output? {
            guard index < messages.count else { return nil }
            let message = messages[index]
            index += 1
            return message
        }
    }
}

// MARK: - Mock Client Context

struct MockClientContext: Sendable {
    let path: String
    var metadata: Metadata
    let descriptor: MethodDescriptor
    
    init(
        path: String = "/test.Service/TestMethod",
        metadata: Metadata = Metadata()
    ) {
        self.path = path
        self.metadata = metadata
        self.descriptor = MethodDescriptor(
            service: "test.Service",
            method: "TestMethod"
        )
    }
}

// MARK: - Mock Interceptor for Testing

struct MockInterceptor: ClientInterceptor {
    let onIntercept: @Sendable (ClientContext) async throws -> Void
    
    init(onIntercept: @escaping @Sendable (ClientContext) async throws -> Void = { _ in }) {
        self.onIntercept = onIntercept
    }
    
    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: @Sendable (
            StreamingClientRequest<Input>,
            ClientContext
        ) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        try await onIntercept(context)
        return try await next(request, context)
    }
}

// MARK: - Test Helpers

extension ClientContext {
    static func mock(
        path: String = "/test.Service/TestMethod",
        metadata: Metadata = Metadata()
    ) -> ClientContext {
        ClientContext(
            descriptor: MethodDescriptor(
                service: "test.Service",
                method: "TestMethod"
            ),
            metadata: metadata
        )
    }
}

extension Metadata {
    static func with(_ pairs: KeyValuePairs<String, String>) -> Metadata {
        var metadata = Metadata()
        for (key, value) in pairs {
            metadata[key] = value
        }
        return metadata
    }
}

// MARK: - Method Descriptor Helper

struct MethodDescriptor {
    let service: String
    let method: String
    
    var path: String {
        "/\(service)/\(method)"
    }
}

// MARK: - Error Helpers

extension RPCError {
    static func mock(
        code: Code = .unknown,
        message: String = "Test error",
        metadata: Metadata = Metadata()
    ) -> RPCError {
        RPCError(
            code: code,
            message: message,
            metadata: metadata
        )
    }
}

// MARK: - Next Handler Helper

func createMockNext<Input: Sendable, Output: Sendable>(
    returning response: Output? = nil,
    throwing error: Error? = nil,
    delay: Duration? = nil
) -> @Sendable (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output> {
    return { request, context in
        if let delay = delay {
            try await Task.sleep(for: delay)
        }
        
        if let error = error {
            throw error
        }
        
        let messages: [Output] = if let response = response {
            [response]
        } else {
            []
        }
        
        return MockStreamingClientResponse(
            metadata: context.metadata,
            messages: messages
        )
    }
} 