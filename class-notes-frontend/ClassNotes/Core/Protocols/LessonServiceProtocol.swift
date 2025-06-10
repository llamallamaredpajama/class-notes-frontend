//
//  LessonServiceProtocol.swift
//  class-notes-frontend
//
//  Protocol defining lesson-related operations
//

import Foundation

@MainActor
protocol LessonServiceProtocol {
    /// Fetch all lessons for the current user
    func fetchLessons() async throws -> [Lesson]
    
    /// Fetch a specific lesson by ID
    func fetchLesson(id: UUID) async throws -> Lesson
    
    /// Create a new lesson
    func createLesson(_ lesson: Lesson) async throws -> Lesson
    
    /// Update an existing lesson
    func updateLesson(_ lesson: Lesson) async throws -> Lesson
    
    /// Delete a lesson
    func deleteLesson(_ id: UUID) async throws
    
    /// Export lesson to PDF
    func exportLessonToPDF(_ lesson: Lesson) async throws -> URL
    
    /// Search lessons
    func searchLessons(query: String) async throws -> [Lesson]
}

// MARK: - Mock Implementation
#if DEBUG
@MainActor
class MockLessonService: LessonServiceProtocol {
    func fetchLessons() async throws -> [Lesson] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        return MockData.sampleLessons
    }
    
    func fetchLesson(id: UUID) async throws -> Lesson {
        guard let lesson = MockData.sampleLessons.first(where: { $0.id == id }) else {
            throw LessonError.notFound
        }
        return lesson
    }
    
    func createLesson(_ lesson: Lesson) async throws -> Lesson {
        try await Task.sleep(nanoseconds: 300_000_000)
        return lesson
    }
    
    func updateLesson(_ lesson: Lesson) async throws -> Lesson {
        try await Task.sleep(nanoseconds: 300_000_000)
        return lesson
    }
    
    func deleteLesson(_ id: UUID) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    
    func exportLessonToPDF(_ lesson: Lesson) async throws -> URL {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return URL(fileURLWithPath: "/mock/lesson.pdf")
    }
    
    func searchLessons(query: String) async throws -> [Lesson] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return MockData.sampleLessons.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.transcript.localizedCaseInsensitiveContains(query)
        }
    }
}

enum LessonError: LocalizedError {
    case notFound
    case invalidData
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Lesson not found"
        case .invalidData:
            return "Invalid lesson data"
        case .networkError:
            return "Network error occurred"
        }
    }
}
#endif 