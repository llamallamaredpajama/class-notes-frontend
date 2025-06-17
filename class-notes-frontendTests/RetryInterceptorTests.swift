// 1. Standard library
import Foundation

// 2. Apple frameworks
import XCTest

// 3. Third-party dependencies
@testable import GRPCCore

// 4. Local modules
@testable import class_notes_frontend

/// Unit tests for RetryInterceptor
class RetryInterceptorTests: XCTestCase {
    // MARK: - Properties
    
    var logger: MockLogger!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        logger = MockLogger()
    }
    
    override func tearDown() async throws {
        logger = nil
        try await super.tearDown()
    }
    
    // MARK: - Tests
    
    func testRetryInterceptor_SuccessOnFirstAttempt() async throws {
        // Given
        let interceptor = RetryInterceptor(logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        var callCount = 0
        let next = createMockNext(returning: MockResponse()) { request, context in
            callCount += 1
            return MockStreamingClientResponse(messages: [MockResponse()])
        }
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertEqual(callCount, 1, "Should only call once on success")
        XCTAssertTrue(logger.infoMessages.isEmpty, "Should not log retries on success")
    }
    
    func testRetryInterceptor_RetriesOnTransientError() async throws {
        // Given
        let interceptor = RetryInterceptor(
            maxRetries: 3,
            initialBackoff: 0.01, // Short delay for tests
            logger: logger
        )
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock(path: "/test.Service/TestMethod")
        
        var callCount = 0
        let next: @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse> = { request, context in
            callCount += 1
            if callCount < 3 {
                throw RPCError.mock(code: .unavailable, message: "Service unavailable")
            }
            return MockStreamingClientResponse(messages: [MockResponse()])
        }
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertEqual(callCount, 3, "Should retry twice before succeeding")
        XCTAssertTrue(
            logger.infoMessages.contains { $0.contains("Request succeeded after 2 retries") },
            "Should log successful retry"
        )
    }
    
    func testRetryInterceptor_DoesNotRetryNonTransientErrors() async throws {
        // Given
        let interceptor = RetryInterceptor(logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        var callCount = 0
        let expectedError = RPCError.mock(code: .notFound, message: "Not found")
        
        let next: @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse> = { request, context in
            callCount += 1
            throw expectedError
        }
        
        // When/Then
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next
            )
            XCTFail("Should have thrown error")
        } catch let error as RPCError {
            XCTAssertEqual(callCount, 1, "Should not retry non-transient errors")
            XCTAssertEqual(error.code, expectedError.code)
            XCTAssertTrue(
                logger.debugMessages.contains { $0.contains("Non-retryable error") },
                "Should log non-retryable error"
            )
        }
    }
    
    func testRetryInterceptor_RespectsMaxRetries() async throws {
        // Given
        let maxRetries = 3
        let interceptor = RetryInterceptor(
            maxRetries: maxRetries,
            initialBackoff: 0.01,
            logger: logger
        )
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock(path: "/test.Service/TestMethod")
        
        var callCount = 0
        let next: @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse> = { request, context in
            callCount += 1
            throw RPCError.mock(code: .unavailable, message: "Always fails")
        }
        
        // When/Then
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(callCount, maxRetries + 1, "Should try original + max retries")
            XCTAssertTrue(
                logger.errors.contains { $0.contains("Max retries (\(maxRetries)) exceeded") },
                "Should log max retries exceeded"
            )
        }
    }
    
    func testRetryInterceptor_AggressiveConfiguration() async throws {
        // Given
        let interceptor = RetryInterceptor.aggressive
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        var callCount = 0
        let next: @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse> = { request, context in
            callCount += 1
            throw RPCError.mock(code: .resourceExhausted, message: "Resources exhausted")
        }
        
        // When/Then
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(callCount, 6, "Aggressive config should try original + 5 retries")
        }
    }
    
    func testRetryInterceptor_ConservativeConfiguration() async throws {
        // Given
        let interceptor = RetryInterceptor.conservative
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        var callCount = 0
        let next: @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse> = { request, context in
            callCount += 1
            throw RPCError.mock(code: .unavailable, message: "Service unavailable")
        }
        
        // When/Then
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(callCount, 2, "Conservative config should try original + 1 retry")
        }
    }
    
    func testRetryInterceptor_BackoffDelay() async throws {
        // Given
        let interceptor = RetryInterceptor(
            maxRetries: 2,
            initialBackoff: 0.1,
            backoffMultiplier: 2.0,
            logger: logger
        )
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        var callTimes: [Date] = []
        var callCount = 0
        
        let next: @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse> = { request, context in
            callTimes.append(Date())
            callCount += 1
            if callCount < 3 {
                throw RPCError.mock(code: .unavailable, message: "Retry me")
            }
            return MockStreamingClientResponse(messages: [MockResponse()])
        }
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertEqual(callTimes.count, 3)
        
        // Verify delays between retries
        if callTimes.count >= 3 {
            let firstDelay = callTimes[1].timeIntervalSince(callTimes[0])
            let secondDelay = callTimes[2].timeIntervalSince(callTimes[1])
            
            // First retry should be around 0.1 seconds
            XCTAssertGreaterThan(firstDelay, 0.09, "First retry delay too short")
            XCTAssertLessThan(firstDelay, 0.15, "First retry delay too long")
            
            // Second retry should be longer (exponential backoff)
            XCTAssertGreaterThan(secondDelay, firstDelay * 1.5, "Backoff should increase")
        }
    }
    
    func testRetryInterceptor_PropagatesNonRPCErrors() async throws {
        // Given
        let interceptor = RetryInterceptor(logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        var callCount = 0
        let customError = NSError(domain: "TestDomain", code: 123, userInfo: nil)
        
        let next: @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse> = { request, context in
            callCount += 1
            throw customError
        }
        
        // When/Then
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next
            )
            XCTFail("Should have thrown error")
        } catch let error as NSError {
            XCTAssertEqual(callCount, 1, "Should not retry non-RPC errors")
            XCTAssertEqual(error.domain, customError.domain)
            XCTAssertEqual(error.code, customError.code)
            XCTAssertTrue(
                logger.debugMessages.contains { $0.contains("Non-RPC error") },
                "Should log non-RPC error"
            )
        }
    }
    
    func testRetryInterceptor_RetryableStatusCodes() async throws {
        // Given
        let retryableCodes: Set<RPCError.Code> = [.unavailable, .deadlineExceeded]
        let interceptor = RetryInterceptor(
            maxRetries: 1,
            retryableStatusCodes: retryableCodes,
            initialBackoff: 0.01,
            logger: logger
        )
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        // Test retryable code
        var callCount = 0
        let retryableError = RPCError.mock(code: .deadlineExceeded, message: "Timeout")
        
        let next1: @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse> = { request, context in
            callCount += 1
            if callCount == 1 {
                throw retryableError
            }
            return MockStreamingClientResponse(messages: [MockResponse()])
        }
        
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next1
        )
        
        XCTAssertEqual(callCount, 2, "Should retry deadline exceeded error")
        
        // Test non-retryable code
        callCount = 0
        let nonRetryableError = RPCError.mock(code: .aborted, message: "Aborted")
        
        let next2: @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse> = { request, context in
            callCount += 1
            throw nonRetryableError
        }
        
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next2
            )
            XCTFail("Should have thrown error")
        } catch let error as RPCError {
            XCTAssertEqual(callCount, 1, "Should not retry aborted error")
            XCTAssertEqual(error.code, .aborted)
        }
    }
}

// MARK: - Reuse MockLogger from AuthInterceptorTests
// The MockLogger class is already defined in AuthInterceptorTests.swift 