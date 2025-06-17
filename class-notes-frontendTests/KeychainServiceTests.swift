// 1. Standard library
import Foundation

// 2. Apple frameworks
import XCTest

// 3. Third-party dependencies

// 4. Local modules
@testable import class_notes_frontend

/// Unit tests for KeychainService
class KeychainServiceTests: XCTestCase {
    // MARK: - Properties
    
    let testAccessToken = "test-access-token-12345"
    let testRefreshToken = "test-refresh-token-67890"
    let testUserId = "test-user-id"
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        // Clear all keychain items before each test
        KeychainService.shared.removeAccessToken()
        KeychainService.shared.removeRefreshToken()
        KeychainService.shared.removeUserId()
    }
    
    override func tearDown() {
        // Clean up after each test
        KeychainService.shared.removeAccessToken()
        KeychainService.shared.removeRefreshToken()
        KeychainService.shared.removeUserId()
        super.tearDown()
    }
    
    // MARK: - Access Token Tests
    
    func testSaveAndGetAccessToken() {
        // When
        KeychainService.shared.saveAccessToken(testAccessToken)
        
        // Then
        let retrievedToken = KeychainService.shared.getAccessToken()
        XCTAssertEqual(retrievedToken, testAccessToken)
    }
    
    func testRemoveAccessToken() {
        // Given
        KeychainService.shared.saveAccessToken(testAccessToken)
        
        // When
        KeychainService.shared.removeAccessToken()
        
        // Then
        let retrievedToken = KeychainService.shared.getAccessToken()
        XCTAssertNil(retrievedToken)
    }
    
    func testUpdateAccessToken() {
        // Given
        KeychainService.shared.saveAccessToken(testAccessToken)
        let newToken = "new-access-token"
        
        // When
        KeychainService.shared.saveAccessToken(newToken)
        
        // Then
        let retrievedToken = KeychainService.shared.getAccessToken()
        XCTAssertEqual(retrievedToken, newToken)
        XCTAssertNotEqual(retrievedToken, testAccessToken)
    }
    
    // MARK: - Refresh Token Tests
    
    func testSaveAndGetRefreshToken() {
        // When
        KeychainService.shared.saveRefreshToken(testRefreshToken)
        
        // Then
        let retrievedToken = KeychainService.shared.getRefreshToken()
        XCTAssertEqual(retrievedToken, testRefreshToken)
    }
    
    func testRemoveRefreshToken() {
        // Given
        KeychainService.shared.saveRefreshToken(testRefreshToken)
        
        // When
        KeychainService.shared.removeRefreshToken()
        
        // Then
        let retrievedToken = KeychainService.shared.getRefreshToken()
        XCTAssertNil(retrievedToken)
    }
    
    // MARK: - User ID Tests
    
    func testSaveAndGetUserId() {
        // When
        KeychainService.shared.saveUserId(testUserId)
        
        // Then
        let retrievedUserId = KeychainService.shared.getUserId()
        XCTAssertEqual(retrievedUserId, testUserId)
    }
    
    func testRemoveUserId() {
        // Given
        KeychainService.shared.saveUserId(testUserId)
        
        // When
        KeychainService.shared.removeUserId()
        
        // Then
        let retrievedUserId = KeychainService.shared.getUserId()
        XCTAssertNil(retrievedUserId)
    }
    
    // MARK: - Clear All Tests
    
    func testClearAll() {
        // Given
        KeychainService.shared.saveAccessToken(testAccessToken)
        KeychainService.shared.saveRefreshToken(testRefreshToken)
        KeychainService.shared.saveUserId(testUserId)
        
        // When
        KeychainService.shared.clearAll()
        
        // Then
        XCTAssertNil(KeychainService.shared.getAccessToken())
        XCTAssertNil(KeychainService.shared.getRefreshToken())
        XCTAssertNil(KeychainService.shared.getUserId())
    }
    
    // MARK: - Edge Cases
    
    func testEmptyStringHandling() {
        // When
        KeychainService.shared.saveAccessToken("")
        
        // Then
        let retrievedToken = KeychainService.shared.getAccessToken()
        XCTAssertEqual(retrievedToken, "")
    }
    
    func testLongStringHandling() {
        // Given
        let longToken = String(repeating: "a", count: 10000)
        
        // When
        KeychainService.shared.saveAccessToken(longToken)
        
        // Then
        let retrievedToken = KeychainService.shared.getAccessToken()
        XCTAssertEqual(retrievedToken, longToken)
    }
    
    func testSpecialCharactersHandling() {
        // Given
        let specialToken = "test!@#$%^&*()_+-=[]{}|;':\",./<>?"
        
        // When
        KeychainService.shared.saveAccessToken(specialToken)
        
        // Then
        let retrievedToken = KeychainService.shared.getAccessToken()
        XCTAssertEqual(retrievedToken, specialToken)
    }
    
    func testUnicodeHandling() {
        // Given
        let unicodeToken = "test-🔐-👍-😀-token"
        
        // When
        KeychainService.shared.saveAccessToken(unicodeToken)
        
        // Then
        let retrievedToken = KeychainService.shared.getAccessToken()
        XCTAssertEqual(retrievedToken, unicodeToken)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() {
        // Given
        let expectation = expectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 100
        
        // When
        DispatchQueue.concurrentPerform(iterations: 100) { index in
            if index % 2 == 0 {
                KeychainService.shared.saveAccessToken("token-\(index)")
            } else {
                _ = KeychainService.shared.getAccessToken()
            }
            expectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testGetNonExistentToken() {
        // When
        let token = KeychainService.shared.getAccessToken()
        
        // Then
        XCTAssertNil(token, "Should return nil for non-existent token")
    }
    
    func testRemoveNonExistentToken() {
        // When/Then - Should not crash
        KeychainService.shared.removeAccessToken()
        KeychainService.shared.removeRefreshToken()
        KeychainService.shared.removeUserId()
    }
} 