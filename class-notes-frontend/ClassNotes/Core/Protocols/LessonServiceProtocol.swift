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
        private let sampleLessons = [
            Lesson(
                title: "Introduction to SwiftUI",
                date: Date(),
                duration: 3600,
                transcript: "Welcome to SwiftUI fundamentals. Today we'll explore the declarative syntax and learn how to build beautiful user interfaces."
            ),
            Lesson(
                title: "Advanced SwiftUI Patterns",
                date: Date().addingTimeInterval(-86400),
                duration: 5400,
                transcript: "Building on our SwiftUI knowledge, let's explore advanced patterns like custom view modifiers and environment values."
            ),
            Lesson(
                title: "Core Data Integration",
                date: Date().addingTimeInterval(-172800),
                duration: 4200,
                transcript: "Persisting data with Core Data in SwiftUI applications. We'll cover NSManagedObject and @FetchRequest."
            )
        ]
        
        func fetchLessons() async throws -> [Lesson] {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000)
            return sampleLessons
        }

        func fetchLesson(id: UUID) async throws -> Lesson {
            guard let lesson = sampleLessons.first(where: { $0.id == id }) else {
                throw AppError.lesson("Lesson not found")
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
            return sampleLessons.filter {
                $0.title.localizedCaseInsensitiveContains(query)
                    || $0.transcript.localizedCaseInsensitiveContains(query)
            }
        }
    }
#endif
