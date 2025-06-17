// 1. Standard library
import Foundation

// 2. Apple frameworks
import XCTest
import OSLog

// 3. Third-party dependencies
@testable import GRPCCore

// 4. Local modules
@testable import class_notes_frontend

/// Unit tests for LoggingInterceptor
class LoggingInterceptorTests: XCTestCase {
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
    
    func testLoggingInterceptor_NoLogging_WhenLevelIsNone() async throws {
        // Given
        let interceptor = LoggingInterceptor(logLevel: .none, logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        let next = createMockNext(returning: MockResponse())
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertTrue(logger.infoMessages.isEmpty, "Should not log at none level")
        XCTAssertTrue(logger.errors.isEmpty, "Should not log at none level")
    }
    
    func testLoggingInterceptor_LogsBasicInfo_WhenLevelIsBasic() async throws {
        // Given
        let interceptor = LoggingInterceptor(logLevel: .basic, logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock(path: "/test.Service/TestMethod")
        
        let next = createMockNext(returning: MockResponse())
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertFalse(logger.infoMessages.isEmpty, "Should log at basic level")
        XCTAssertTrue(
            logger.infoMessages.contains { msg in
                msg.contains("gRPC Request") && msg.contains("/test.Service/TestMethod")
            },
            "Should log request with method path"
        )
        XCTAssertTrue(
            logger.infoMessages.contains { msg in
                msg.contains("gRPC Response") && msg.contains("Success")
            },
            "Should log successful response"
        )
    }
    
    func testLoggingInterceptor_LogsDetailed_WhenLevelIsDetailed() async throws {
        // Given
        let interceptor = LoggingInterceptor(logLevel: .detailed, logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        
        var metadata = Metadata()
        metadata["custom-header"] = "test-value"
        let context = ClientContext.mock(
            path: "/test.Service/TestMethod",
            metadata: metadata
        )
        
        let next = createMockNext(returning: MockResponse())
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertTrue(
            logger.infoMessages.contains { msg in
                msg.contains("Metadata:") && msg.contains("custom-header: test-value")
            },
            "Should log metadata at detailed level"
        )
    }
    
    func testLoggingInterceptor_LogsErrors() async throws {
        // Given
        let interceptor = LoggingInterceptor(logLevel: .basic, logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        let expectedError = RPCError.mock(
            code: .notFound,
            message: "Resource not found"
        )
        
        let next = createMockNext(
            throwing: expectedError
        ) as @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse>
        
        // When/Then
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next
            )
            XCTFail("Should have thrown error")
        } catch {
            // Then
            XCTAssertTrue(
                logger.errors.contains { msg in
                    msg.contains("gRPC Response") && 
                    msg.contains("Failed") &&
                    msg.contains("Resource not found")
                },
                "Should log error response"
            )
        }
    }
    
    func testLoggingInterceptor_LogsErrorDetails_WhenLevelIsDetailed() async throws {
        // Given
        let interceptor = LoggingInterceptor(logLevel: .detailed, logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        let expectedError = RPCError.mock(
            code: .permissionDenied,
            message: "Access denied"
        )
        
        let next = createMockNext(
            throwing: expectedError
        ) as @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse>
        
        // When/Then
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next
            )
            XCTFail("Should have thrown error")
        } catch {
            // Then
            XCTAssertTrue(
                logger.errors.contains { msg in
                    msg.contains("Code: permissionDenied") &&
                    msg.contains("Message: Access denied")
                },
                "Should log detailed error information"
            )
        }
    }
    
    func testLoggingInterceptor_MeasuresTiming() async throws {
        // Given
        let interceptor = LoggingInterceptor(logLevel: .basic, logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        // Add delay to measure timing
        let next = createMockNext(
            returning: MockResponse(),
            delay: .milliseconds(100)
        )
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertTrue(
            logger.infoMessages.contains { msg in
                // Should log duration in milliseconds
                msg.contains("ms)") || msg.contains("s)")
            },
            "Should log request duration"
        )
    }
    
    func testLoggingInterceptor_FormatsShortDuration() async throws {
        // Given
        let interceptor = LoggingInterceptor(logLevel: .basic, logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        // Very short delay
        let next = createMockNext(returning: MockResponse())
        
        // When
        _ = try await interceptor.intercept(
            request: request,
            context: context,
            next: next
        )
        
        // Then
        XCTAssertTrue(
            logger.infoMessages.contains { msg in
                // Should format as microseconds or milliseconds
                msg.contains("µs)") || msg.contains("ms)")
            },
            "Should format short durations appropriately"
        )
    }
    
    func testLoggingInterceptor_PropagatesErrors() async throws {
        // Given
        let interceptor = LoggingInterceptor(logLevel: .basic, logger: logger)
        let request = MockStreamingClientRequest<MockRequest>()
        let context = ClientContext.mock()
        
        let expectedError = RPCError.mock(code: .unknown, message: "Test error")
        let next = createMockNext(
            throwing: expectedError
        ) as @Sendable (StreamingClientRequest<MockRequest>, ClientContext) async throws -> StreamingClientResponse<MockResponse>
        
        // When/Then
        do {
            _ = try await interceptor.intercept(
                request: request,
                context: context,
                next: next
            )
            XCTFail("Should have propagated error")
        } catch let error as RPCError {
            XCTAssertEqual(error.code, expectedError.code)
            XCTAssertEqual(error.message, expectedError.message)
        }
    }
}

// MARK: - Reuse Mock Logger from AuthInterceptorTests
// The MockLogger class is already defined in AuthInterceptorTests.swift 