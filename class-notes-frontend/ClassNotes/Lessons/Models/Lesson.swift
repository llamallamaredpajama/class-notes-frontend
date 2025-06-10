//
//  Lesson.swift
//  class-notes-frontend
//
//  Model representing a lesson/class recording
//

import Foundation
import SwiftData

/// Represents a lesson in the app
@Model
final class Lesson {
    /// Unique identifier for the lesson
    @Attribute(.unique) var id: UUID
    
    /// Title of the lesson
    var title: String
    
    /// Date when the lesson was created
    var createdAt: Date
    
    /// Date when the lesson was last modified
    var lastModified: Date
    
    /// Progress percentage (0.0 to 1.0)
    var progress: Double
    
    /// Order index for sorting lessons
    var orderIndex: Int
    
    /// Whether the lesson is marked as favorite
    var isFavorite: Bool
    
    /// Tags associated with the lesson
    var tags: [String]
    
    /// Date when the lesson was recorded
    var date: Date
    
    /// Duration of the lesson in seconds
    var duration: Int
    
    /// Transcript of the lesson
    var transcript: String
    
    /// URL to the audio recording of the lesson
    var audioURL: URL?
    
    /// URL to the PDF of the lesson
    var pdfURL: URL?
    
    /// Sync status of the lesson
    var syncStatus: SyncStatus
    
    // MARK: - Relationships
    
    /// The course this lesson belongs to
    var course: Course?
    
    /// Notes associated with this lesson
    @Relationship(deleteRule: .cascade)
    var notes: [Note]
    
    /// Audio recordings for this lesson
    @Relationship(deleteRule: .cascade)
    var audioRecordings: [AudioRecording]
    
    /// Drawing canvases for this lesson
    @Relationship(deleteRule: .cascade)
    var drawingCanvases: [DrawingCanvas]
    
    // MARK: - Initialization
    
    init(
        title: String,
        date: Date = Date(),
        duration: Int = 0,
        transcript: String = "",
        audioURL: URL? = nil,
        pdfURL: URL? = nil,
        tags: [String] = [],
        isFavorite: Bool = false,
        lastModified: Date = Date(),
        syncStatus: SyncStatus = .notSynced
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.lastModified = lastModified
        self.progress = 0.0
        self.orderIndex = 0
        self.isFavorite = isFavorite
        self.tags = tags
        self.date = date
        self.duration = duration
        self.transcript = transcript
        self.audioURL = audioURL
        self.pdfURL = pdfURL
        self.syncStatus = syncStatus
        self.course = nil
        self.notes = []
        self.audioRecordings = []
        self.drawingCanvases = []
    }
}

// MARK: - Sync Status
enum SyncStatus: String, Codable {
    case synced
    case syncing
    case notSynced
    case error
}

// MARK: - Extensions

extension Lesson {
    /// Computed property for completion status
    var isCompleted: Bool {
        progress >= 1.0
    }
    
    /// Formatted creation date
    var formattedCreatedDate: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }
    
    /// Formatted last modified date
    var formattedLastModifiedDate: String {
        lastModified.formatted(date: .abbreviated, time: .shortened)
    }
    
    /// Total duration of all audio recordings
    var totalAudioDuration: TimeInterval {
        audioRecordings.reduce(0) { $0 + $1.duration }
    }
    
    /// Update the last modified date
    func touch() {
        lastModified = Date()
    }
    
    /// Formatted duration string (e.g., "1h 23m")
    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(duration)s"
        }
    }
    
    /// Short date format for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Summary of transcript (first 200 characters)
    var transcriptSummary: String {
        let maxLength = 200
        if transcript.count > maxLength {
            return String(transcript.prefix(maxLength)) + "..."
        }
        return transcript
    }
    
    /// Check if lesson has audio
    var hasAudio: Bool {
        audioURL != nil
    }
    
    /// Check if lesson has PDF
    var hasPDF: Bool {
        pdfURL != nil
    }
} 