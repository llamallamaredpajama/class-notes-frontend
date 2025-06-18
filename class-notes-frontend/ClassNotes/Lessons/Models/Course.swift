//
//  Course.swift
//  class-notes-frontend
//
//  Model representing a course that contains multiple lessons
//

import Foundation
import SwiftData

/// Represents a course containing multiple lessons
@Model
final class Course {
    /// Unique identifier for the course
    @Attribute(.unique) var id: UUID
    
    /// Title of the course
    var name: String
    
    /// Course code (e.g., "CS101")
    var courseCode: String?
    
    /// Instructor name
    var instructor: String?
    
    /// Semester or term
    var semester: String?
    
    /// Color theme for the course (hex string)
    var color: String
    
    /// Icon for the course
    var icon: String
    
    /// Date when the course was created
    var createdAt: Date
    
    /// Date when the course was last modified
    var lastModified: Date
    
    /// Whether the course is currently active
    var isActive: Bool
    
    // MARK: - Relationships
    
    /// Lessons in this course
    @Relationship(deleteRule: .cascade, inverse: \Lesson.course)
    var lessons: [Lesson]
    
    // MARK: - Initialization
    
    init(
        name: String,
        courseCode: String? = nil,
        instructor: String? = nil,
        semester: String? = nil,
        color: CourseColor = .blue,
        icon: String = "book.fill"
    ) {
        self.id = UUID()
        self.name = name
        self.courseCode = courseCode
        self.instructor = instructor
        self.semester = semester
        self.color = color.hexString
        self.icon = icon
        self.createdAt = Date()
        self.lastModified = Date()
        self.isActive = true
        self.lessons = []
    }
}

// MARK: - Extensions

extension Course {
    /// CourseColor enum representation
    var courseColor: CourseColor {
        CourseColor(hexString: color) ?? .blue
    }
    
    /// Total number of lessons
    var lessonCount: Int {
        lessons.count
    }
    
    /// Number of completed lessons
    var completedLessonCount: Int {
        lessons.filter { $0.isCompleted }.count
    }
    
    /// Overall progress percentage
    var progress: Double {
        guard !lessons.isEmpty else { return 0 }
        let totalProgress = lessons.reduce(0) { $0 + $1.progress }
        return totalProgress / Double(lessons.count)
    }
    
    /// Formatted progress string
    var formattedProgress: String {
        "\(Int(progress * 100))%"
    }
    
    /// Update the last modified date
    func touch() {
        lastModified = Date()
    }
} 