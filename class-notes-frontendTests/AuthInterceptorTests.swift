// 1. Standard library
import Foundation

// 2. Apple frameworks
import XCTest

// 3. Third-party dependencies
@testable import GRPCCore
@testable import SwiftProtobuf

// 4. Local modules
@testable import class_notes_frontend

/// Unit tests for AuthInterceptor
class AuthInterceptorTests: XCTestCase {
    // MARK: - Properties
    
    var authService: MockAuthenticationService!
    var keychainService: MockKeychainService!
    var logger: MockLogger!
    var interceptor: AuthInterceptor!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        authService = MockAuthenticationService()
        keychainService = MockKeychainService()
        logger = MockLogger()
        
        interceptor = AuthInterceptor(
            authService: authService,
            keychainService: keychainService,
            logger: logger
        )
    }
    
    override func tearDown() async throws {
        authService = nil
        keychainService = nil
        logger = nil
        interceptor = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Tests
    
    func testAuthInterceptor_AddsAuthToken_WhenAvailable() async throws {
        // Given
        let token = "test-auth-token"
        keychainService.authToken = token
        
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        var capturedContext: ClientContext?
        let next = createMockNext(returning: MockResponse()) { request, ctx in
            capturedContext = ctx
            return MockStreamingClientResponse(messages: [MockResponse()])
        }
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertNotNil(capturedContext)
        XCTAssertEqual(
            capturedContext?.metadata["authorization"],
            "Bearer \(token)",
            "Should add Bearer token to authorization header"
        )
    }
    
    func testAuthInterceptor_AddsUserAgent() async throws {
        // Given
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        var capturedContext: ClientContext?
        let next = createMockNext(returning: MockResponse()) { request, ctx in
            capturedContext = ctx
            return MockStreamingClientResponse(messages: [MockResponse()])
        }
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertNotNil(capturedContext)
        XCTAssertEqual(
            capturedContext?.metadata["user-agent"],
            "ClassNotes-iOS/2.0",
            "Should add user agent header"
        )
    }
    
    func testAuthInterceptor_NoToken_WhenNotAvailable() async throws {
        // Given
        keychainService.authToken = nil
        
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        var capturedContext: ClientContext?
        let next = createMockNext(returning: MockResponse()) { request, ctx in
            capturedContext = ctx
            return MockStreamingClientResponse(messages: [MockResponse()])
        }
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertNotNil(capturedContext)
        XCTAssertNil(
            capturedContext?.metadata["authorization"],
            "Should not add authorization header when no token"
        )
        XCTAssertTrue(
            logger.warnings.contains { $0.contains("No auth token available") },
            "Should log warning when no token"
        )
    }
    
    func testAuthInterceptor_HandlesUnauthenticatedError() async throws {
        // Given
        keychainService.authToken = "invalid-token"
        
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        let authError = RPCError.mock(
            code: .unauthenticated,
            message: "Invalid credentials"
        )
        
        let next = createMockNext(throwing: authError) as @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse>
        
        // When/Then
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next
            )
            XCTFail("Should have thrown error")
        } catch let error as RPCError {
            XCTAssertEqual(error.code, .unauthenticated)
            XCTAssertNil(
                keychainService.authToken,
                "Should clear auth token on unauthenticated error"
            )
            XCTAssertTrue(
                logger.errors.contains { $0.contains("Authentication failed") },
                "Should log authentication error"
            )
        }
    }
    
    func testAuthInterceptor_ChecksResponseMetadata_ForAuthChallenge() async throws {
        // Given
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        var responseMetadata = Metadata()
        responseMetadata["www-authenticate"] = "Bearer realm=\"api\""
        
        let next = createMockNext(returning: MockResponse()) { request, context in
            MockStreamingClientResponse(
                metadata: responseMetadata,
                messages: [MockResponse()]
            )
        }
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertTrue(
            logger.warnings.contains { $0.contains("Server requested authentication") },
            "Should log authentication challenge"
        )
    }
    
    func testAuthInterceptor_PropagatesNonAuthErrors() async throws {
        // Given
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        let networkError = RPCError.mock(
            code: .unavailable,
            message: "Service unavailable"
        )
        
        let next = createMockNext(throwing: networkError) as @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse>
        
        // When/Then
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next
            )
            XCTFail("Should have thrown error")
        } catch let error as RPCError {
            XCTAssertEqual(error.code, .unavailable)
            XCTAssertNotNil(
                keychainService.authToken,
                "Should not clear token for non-auth errors"
            )
        }
    }
}

// MARK: - Mock Services

class MockAuthenticationService: AuthenticationService {
    override init() {
        super.init()
    }
}

class MockKeychainService: KeychainService {
    var authToken: String?
    var deletedKeys: [String] = []
    
    override func get(key: String) throws -> String? {
        if key == "auth_token" {
            return authToken
        }
        return nil
    }
    
    override func set(key: String, value: String) throws {
        if key == "auth_token" {
            authToken = value
        }
    }
    
    override func delete(key: String) throws {
        if key == "auth_token" {
            authToken = nil
            deletedKeys.append(key)
        }
    }
}

class MockLogger: Logger {
    var debugMessages: [String] = []
    var infoMessages: [String] = []
    var warnings: [String] = []
    var errors: [String] = []
    
    override func debug(_ message: String) {
        debugMessages.append(message)
    }
    
    override func info(_ message: String) {
        infoMessages.append(message)
    }
    
    override func warning(_ message: String) {
        warnings.append(message)
    }
    
    override func error(_ message: String) {
        errors.append(message)
    }
}

// MARK: - Mock Types

private struct MockRequest: Message {
    var metadata: HPACKHeaders = HPACKHeaders()
    
    // Message conformance
    static var protoMessageName: String { "MockRequest" }
    var unknownFields = UnknownStorage()
    
    mutating func decodeMessage<D>(decoder: inout D) throws where D : Decoder {}
    func traverse<V>(visitor: inout V) throws where V : Visitor {}
    func isEqualTo(message: any Message) -> Bool { true }
}

private struct MockResponse: Message {
    // Message conformance
    static var protoMessageName: String { "MockResponse" }
    var unknownFields = UnknownStorage()
    
    mutating func decodeMessage<D>(decoder: inout D) throws where D : Decoder {}
    func traverse<V>(visitor: inout V) throws where V : Visitor {}
    func isEqualTo(message: any Message) -> Bool { true }
}

private class MockClientInterceptorContext: ClientInterceptorContext {
    var path: String = "/test.Service/Method"
    var type: GRPCInterceptorContextType = .unary
    var logger: Logger = Logger()
    var deadline: NIODeadline = .distantFuture
    var customMetadata: HPACKHeaders = HPACKHeaders()
} 