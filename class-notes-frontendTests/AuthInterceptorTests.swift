// 1. Standard library
import Foundation
// 2. Apple frameworks
import XCTest

// 3. Third-party dependencies
@testable import GRPCCore
// 4. Local modules
@testable import class_notes_frontend

/// Unit tests for AuthInterceptor
class AuthInterceptorTests: XCTestCase {
    // MARK: - Properties

    var interceptor: AuthInterceptor!
    var originalKeychainService: KeychainService!

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()

        // Store the original KeychainService.shared
        originalKeychainService = KeychainService.shared

        interceptor = AuthInterceptor()
    }

    override func tearDown() async throws {
        // Restore the original KeychainService.shared
        KeychainService.shared = originalKeychainService

        interceptor = nil
        originalKeychainService = nil

        try await super.tearDown()
    }

    // MARK: - Tests

    func testAuthInterceptor_AddsAuthToken_WhenAvailable() async throws {
        // Given
        let token = "test-auth-token"
        let mockKeychainService = MockKeychainService()
        mockKeychainService.authToken = token
        KeychainService.shared = mockKeychainService

        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()

        var capturedRequest: StreamingClientRequest<MockRequest>?
        let next = createMockNext(returning: MockResponse()) { request, ctx in
            capturedRequest = request
            return MockStreamingClientResponse(messages: [MockResponse()])
        }

        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )

        // Then
        XCTAssertNotNil(capturedRequest)
        XCTAssertEqual(
            capturedRequest?.metadata["authorization"],
            "Bearer \(token)",
            "Should add Bearer token to authorization header"
        )
    }

    func testAuthInterceptor_AddsUserAgent() async throws {
        // Given
        let mockKeychainService = MockKeychainService()
        KeychainService.shared = mockKeychainService

        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()

        var capturedRequest: StreamingClientRequest<MockRequest>?
        let next = createMockNext(returning: MockResponse()) { request, ctx in
            capturedRequest = request
            return MockStreamingClientResponse(messages: [MockResponse()])
        }

        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )

        // Then
        XCTAssertNotNil(capturedRequest)
        XCTAssertEqual(
            capturedRequest?.metadata["user-agent"],
            "ClassNotes-iOS/1.0",
            "Should add user agent header"
        )
    }

    func testAuthInterceptor_NoToken_WhenNotAvailable() async throws {
        // Given
        let mockKeychainService = MockKeychainService()
        mockKeychainService.authToken = nil
        KeychainService.shared = mockKeychainService

        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()

        var capturedRequest: StreamingClientRequest<MockRequest>?
        let next = createMockNext(returning: MockResponse()) { request, ctx in
            capturedRequest = request
            return MockStreamingClientResponse(messages: [MockResponse()])
        }

        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )

        // Then
        XCTAssertNotNil(capturedRequest)
        XCTAssertNil(
            capturedRequest?.metadata["authorization"],
            "Should not add authorization header when no token"
        )
    }

    func testAuthInterceptor_HandlesUnauthenticatedError() async throws {
        // Given
        let mockKeychainService = MockKeychainService()
        mockKeychainService.authToken = "invalid-token"
        KeychainService.shared = mockKeychainService

        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()

        let authError = RPCError.mock(
            code: .unauthenticated,
            message: "Invalid credentials"
        )

        let next =
            createMockNext(throwing: authError)
            as @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws ->
            StreamingClientResponse<MockResponse>

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
            // Note: Current AuthInterceptor implementation doesn't clear token on error
            // This would need to be implemented if desired
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
        let mockKeychainService = MockKeychainService()
        mockKeychainService.authToken = "valid-token"
        KeychainService.shared = mockKeychainService

        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()

        let networkError = RPCError.mock(
            code: .unavailable,
            message: "Service unavailable"
        )

        let next =
            createMockNext(throwing: networkError)
            as @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws ->
            StreamingClientResponse<MockResponse>

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
                mockKeychainService.authToken,
                "Should not clear token for non-auth errors"
            )
        }
    }
}

// MARK: - Mock Services

class MockKeychainService: KeychainService {
    var authToken: String?
    var deletedKeys: [String] = []

    override func loadString(key: String) -> String? {
        if key == "auth_token" {
            return authToken
        }
        return nil
    }

    override func saveString(_ value: String, for key: String) -> Bool {
        if key == "auth_token" {
            authToken = value
            return true
        }
        return false
    }

    override func delete(key: String) -> Bool {
        if key == "auth_token" {
            authToken = nil
            deletedKeys.append(key)
            return true
        }
        return false
    }
}

// MARK: - Mock Types

private struct MockRequest: Sendable {
    // Simple mock request for testing
}

private struct MockResponse: Sendable {
    // Simple mock response for testing
}
