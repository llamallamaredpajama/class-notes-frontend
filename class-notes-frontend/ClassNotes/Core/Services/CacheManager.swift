// 1. Standard library
import Foundation

// 2. Apple frameworks
import SwiftData

/// Manages local caching for offline-first functionality
@MainActor
class CacheManager: ObservableObject {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    
    // MARK: - Cache Keys
    
    private enum CacheKey: String {
        case lastLessonSync = "lastLessonSync"
        case lastCourseSync = "lastCourseSync"
        case pendingOperations = "pendingOperations"
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Lesson Cache Methods
    
    /// Save lessons to cache
    func cacheLessons(_ lessons: [Lesson]) throws {
        for lesson in lessons {
            modelContext.insert(lesson)
        }
        try modelContext.save()
        UserDefaults.standard.set(Date(), forKey: CacheKey.lastLessonSync.rawValue)
    }
    
    /// Get cached lessons
    func getCachedLessons() throws -> [Lesson] {
        let descriptor = FetchDescriptor<Lesson>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Check if cache is expired
    func isLessonCacheExpired() -> Bool {
        guard let lastSync = UserDefaults.standard.object(forKey: CacheKey.lastLessonSync.rawValue) as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastSync) > cacheExpirationInterval
    }
    
    /// Update cached lesson
    func updateCachedLesson(_ lesson: Lesson) throws {
        // SwiftData automatically tracks changes
        lesson.lastModified = Date()
        try modelContext.save()
    }
    
    /// Delete cached lesson
    func deleteCachedLesson(_ lesson: Lesson) throws {
        modelContext.delete(lesson)
        try modelContext.save()
    }
    
    // MARK: - Course Cache Methods
    
    /// Save courses to cache
    func cacheCourses(_ courses: [Course]) throws {
        for course in courses {
            modelContext.insert(course)
        }
        try modelContext.save()
        UserDefaults.standard.set(Date(), forKey: CacheKey.lastCourseSync.rawValue)
    }
    
    /// Get cached courses
    func getCachedCourses() throws -> [Course] {
        let descriptor = FetchDescriptor<Course>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Check if course cache is expired
    func isCourseCacheExpired() -> Bool {
        guard let lastSync = UserDefaults.standard.object(forKey: CacheKey.lastCourseSync.rawValue) as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastSync) > cacheExpirationInterval
    }
    
    // MARK: - Pending Operations
    
    /// Save pending operation for later sync
    func savePendingOperation(_ operation: PendingOperation) throws {
        modelContext.insert(operation)
        try modelContext.save()
    }
    
    /// Get all pending operations
    func getPendingOperations() throws -> [PendingOperation] {
        let descriptor = FetchDescriptor<PendingOperation>(sortBy: [SortDescriptor(\.createdAt)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Remove completed operation
    func removePendingOperation(_ operation: PendingOperation) throws {
        modelContext.delete(operation)
        try modelContext.save()
    }
    
    // MARK: - Cache Management
    
    /// Clear all cached data
    func clearCache() throws {
        // Delete all lessons
        let lessons = try getCachedLessons()
        for lesson in lessons {
            modelContext.delete(lesson)
        }
        
        // Delete all courses
        let courses = try getCachedCourses()
        for course in courses {
            modelContext.delete(course)
        }
        
        // Delete all pending operations
        let operations = try getPendingOperations()
        for operation in operations {
            modelContext.delete(operation)
        }
        
        try modelContext.save()
        
        // Clear sync timestamps
        UserDefaults.standard.removeObject(forKey: CacheKey.lastLessonSync.rawValue)
        UserDefaults.standard.removeObject(forKey: CacheKey.lastCourseSync.rawValue)
    }
    
    /// Get cache size
    func getCacheSize() throws -> Int64 {
        // This is a simplified implementation
        // In production, you'd calculate actual storage usage
        let lessonCount = try modelContext.fetchCount(FetchDescriptor<Lesson>())
        let courseCount = try modelContext.fetchCount(FetchDescriptor<Course>())
        let operationCount = try modelContext.fetchCount(FetchDescriptor<PendingOperation>())
        
        // Rough estimate: 10KB per lesson, 5KB per course, 2KB per operation
        return Int64((lessonCount * 10_000) + (courseCount * 5_000) + (operationCount * 2_000))
    }
}

// MARK: - Pending Operation Model

/// Represents an operation that needs to be synced when online
@Model
final class PendingOperation {
    // MARK: - Properties
    
    var id: UUID
    var type: OperationType
    var entityId: UUID
    var entityType: String
    var payload: Data?
    var createdAt: Date
    var retryCount: Int
    
    // MARK: - Operation Types
    
    enum OperationType: String, Codable {
        case create
        case update
        case delete
    }
    
    // MARK: - Initialization
    
    init(type: OperationType, entityId: UUID, entityType: String, payload: Data? = nil) {
        self.id = UUID()
        self.type = type
        self.entityId = entityId
        self.entityType = entityType
        self.payload = payload
        self.createdAt = Date()
        self.retryCount = 0
    }
} 