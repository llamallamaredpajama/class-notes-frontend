// 1. Standard library
import Foundation

// 2. Apple frameworks
import XCTest
import SwiftData

// 3. Third-party dependencies

// 4. Local modules
@testable import class_notes_frontend

/// Unit tests for CacheManager
@MainActor
class CacheManagerTests: XCTestCase {
    // MARK: - Properties
    
    var cacheManager: CacheManager!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: Lesson.self, Course.self, PendingOperation.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
        cacheManager = CacheManager(modelContext: modelContext)
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "lastLessonSync")
        UserDefaults.standard.removeObject(forKey: "lastCourseSync")
    }
    
    override func tearDown() async throws {
        cacheManager = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Lesson Cache Tests
    
    func testCacheLessons() async throws {
        // Given
        let lessons = [
            Lesson(title: "Lesson 1", transcript: "Content 1"),
            Lesson(title: "Lesson 2", transcript: "Content 2")
        ]
        
        // When
        try cacheManager.cacheLessons(lessons)
        
        // Then
        let cachedLessons = try cacheManager.getCachedLessons()
        XCTAssertEqual(cachedLessons.count, 2)
        XCTAssertTrue(cachedLessons.contains { $0.title == "Lesson 1" })
        XCTAssertTrue(cachedLessons.contains { $0.title == "Lesson 2" })
    }
    
    func testGetCachedLessonsSortedByDate() async throws {
        // Given
        let lesson1 = Lesson(title: "Old Lesson", transcript: "Content")
        lesson1.createdAt = Date().addingTimeInterval(-3600) // 1 hour ago
        
        let lesson2 = Lesson(title: "New Lesson", transcript: "Content")
        lesson2.createdAt = Date()
        
        try cacheManager.cacheLessons([lesson1, lesson2])
        
        // When
        let cachedLessons = try cacheManager.getCachedLessons()
        
        // Then
        XCTAssertEqual(cachedLessons.count, 2)
        XCTAssertEqual(cachedLessons[0].title, "New Lesson")
        XCTAssertEqual(cachedLessons[1].title, "Old Lesson")
    }
    
    func testIsLessonCacheExpired() async throws {
        // Given - No sync date
        XCTAssertTrue(cacheManager.isLessonCacheExpired())
        
        // When - Cache lessons (sets sync date)
        try cacheManager.cacheLessons([])
        
        // Then - Should not be expired immediately
        XCTAssertFalse(cacheManager.isLessonCacheExpired())
        
        // When - Set old sync date
        UserDefaults.standard.set(
            Date().addingTimeInterval(-7200), // 2 hours ago
            forKey: "lastLessonSync"
        )
        
        // Then - Should be expired
        XCTAssertTrue(cacheManager.isLessonCacheExpired())
    }
    
    func testUpdateCachedLesson() async throws {
        // Given
        let lesson = Lesson(title: "Original", transcript: "Content")
        try cacheManager.cacheLessons([lesson])
        
        // When
        lesson.title = "Updated"
        try cacheManager.updateCachedLesson(lesson)
        
        // Then
        let cachedLessons = try cacheManager.getCachedLessons()
        XCTAssertEqual(cachedLessons.count, 1)
        XCTAssertEqual(cachedLessons[0].title, "Updated")
        XCTAssertNotNil(cachedLessons[0].lastModified)
    }
    
    func testDeleteCachedLesson() async throws {
        // Given
        let lesson = Lesson(title: "To Delete", transcript: "Content")
        try cacheManager.cacheLessons([lesson])
        
        // When
        try cacheManager.deleteCachedLesson(lesson)
        
        // Then
        let cachedLessons = try cacheManager.getCachedLessons()
        XCTAssertEqual(cachedLessons.count, 0)
    }
    
    // MARK: - Course Cache Tests
    
    func testCacheCourses() async throws {
        // Given
        let courses = [
            Course(name: "Math 101"),
            Course(name: "Physics 201")
        ]
        
        // When
        try cacheManager.cacheCourses(courses)
        
        // Then
        let cachedCourses = try cacheManager.getCachedCourses()
        XCTAssertEqual(cachedCourses.count, 2)
        XCTAssertTrue(cachedCourses.contains { $0.name == "Math 101" })
        XCTAssertTrue(cachedCourses.contains { $0.name == "Physics 201" })
    }
    
    func testGetCachedCoursesSortedByName() async throws {
        // Given
        let courses = [
            Course(name: "Zebra Studies"),
            Course(name: "Algebra"),
            Course(name: "Music Theory")
        ]
        
        // When
        try cacheManager.cacheCourses(courses)
        let cachedCourses = try cacheManager.getCachedCourses()
        
        // Then
        XCTAssertEqual(cachedCourses.count, 3)
        XCTAssertEqual(cachedCourses[0].name, "Algebra")
        XCTAssertEqual(cachedCourses[1].name, "Music Theory")
        XCTAssertEqual(cachedCourses[2].name, "Zebra Studies")
    }
    
    // MARK: - Pending Operations Tests
    
    func testSavePendingOperation() async throws {
        // Given
        let operation = PendingOperation(
            type: .create,
            entityId: UUID(),
            entityType: "Lesson"
        )
        
        // When
        try cacheManager.savePendingOperation(operation)
        
        // Then
        let operations = try cacheManager.getPendingOperations()
        XCTAssertEqual(operations.count, 1)
        XCTAssertEqual(operations[0].type, .create)
        XCTAssertEqual(operations[0].entityType, "Lesson")
    }
    
    func testGetPendingOperationsSortedByDate() async throws {
        // Given
        let op1 = PendingOperation(type: .create, entityId: UUID(), entityType: "Lesson")
        let op2 = PendingOperation(type: .update, entityId: UUID(), entityType: "Lesson")
        
        // Save with delay to ensure different timestamps
        try cacheManager.savePendingOperation(op1)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        try cacheManager.savePendingOperation(op2)
        
        // When
        let operations = try cacheManager.getPendingOperations()
        
        // Then
        XCTAssertEqual(operations.count, 2)
        XCTAssertEqual(operations[0].type, .create)
        XCTAssertEqual(operations[1].type, .update)
    }
    
    func testRemovePendingOperation() async throws {
        // Given
        let operation = PendingOperation(
            type: .delete,
            entityId: UUID(),
            entityType: "Lesson"
        )
        try cacheManager.savePendingOperation(operation)
        
        // When
        try cacheManager.removePendingOperation(operation)
        
        // Then
        let operations = try cacheManager.getPendingOperations()
        XCTAssertEqual(operations.count, 0)
    }
    
    // MARK: - Cache Management Tests
    
    func testClearCache() async throws {
        // Given
        let lessons = [Lesson(title: "Test", transcript: "Content")]
        let courses = [Course(name: "Test Course")]
        let operation = PendingOperation(type: .create, entityId: UUID(), entityType: "Lesson")
        
        try cacheManager.cacheLessons(lessons)
        try cacheManager.cacheCourses(courses)
        try cacheManager.savePendingOperation(operation)
        
        // When
        try cacheManager.clearCache()
        
        // Then
        let cachedLessons = try cacheManager.getCachedLessons()
        let cachedCourses = try cacheManager.getCachedCourses()
        let operations = try cacheManager.getPendingOperations()
        
        XCTAssertEqual(cachedLessons.count, 0)
        XCTAssertEqual(cachedCourses.count, 0)
        XCTAssertEqual(operations.count, 0)
        
        // Sync timestamps should be cleared
        XCTAssertNil(UserDefaults.standard.object(forKey: "lastLessonSync"))
        XCTAssertNil(UserDefaults.standard.object(forKey: "lastCourseSync"))
    }
    
    func testGetCacheSize() async throws {
        // Given
        let lessons = [
            Lesson(title: "Lesson 1", transcript: "Content"),
            Lesson(title: "Lesson 2", transcript: "Content")
        ]
        let courses = [Course(name: "Course 1")]
        let operation = PendingOperation(type: .create, entityId: UUID(), entityType: "Lesson")
        
        try cacheManager.cacheLessons(lessons)
        try cacheManager.cacheCourses(courses)
        try cacheManager.savePendingOperation(operation)
        
        // When
        let cacheSize = try cacheManager.getCacheSize()
        
        // Then
        // Expected: 2 lessons * 10KB + 1 course * 5KB + 1 operation * 2KB = 27KB
        XCTAssertEqual(cacheSize, 27_000)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyCache() async throws {
        // When
        let lessons = try cacheManager.getCachedLessons()
        let courses = try cacheManager.getCachedCourses()
        let operations = try cacheManager.getPendingOperations()
        
        // Then
        XCTAssertEqual(lessons.count, 0)
        XCTAssertEqual(courses.count, 0)
        XCTAssertEqual(operations.count, 0)
    }
    
    func testCacheSizeWithEmptyCache() async throws {
        // When
        let cacheSize = try cacheManager.getCacheSize()
        
        // Then
        XCTAssertEqual(cacheSize, 0)
    }
} 