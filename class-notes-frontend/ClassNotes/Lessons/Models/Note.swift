//
//  Note.swift
//  class-notes-frontend
//
//  Model representing a note within a lesson
//

import Foundation
import SwiftData

/// Represents a note within a lesson
@Model
final class Note {
    /// Unique identifier for the note
    @Attribute(.unique) var id: UUID
    
    /// Content of the note
    var content: String
    
    /// Type of note (text, audio transcription, etc.)
    var noteType: NoteType
    
    /// Date when the note was created
    var createdAt: Date
    
    /// Date when the note was last modified
    var lastModified: Date
    
    /// Whether the note is pinned
    var isPinned: Bool
    
    /// Color tag for the note (hex string)
    var colorTag: String?
    
    /// Associated timestamp in the lesson (in seconds)
    var timestamp: TimeInterval
    
    // MARK: - Relationships
    
    /// The lesson this note belongs to
    var lesson: Lesson?
    
    /// Associated audio recording, if any
    var audioRecording: AudioRecording?
    
    // MARK: - Initialization
    
    init(
        content: String,
        noteType: NoteType = .text,
        lesson: Lesson? = nil,
        timestamp: TimeInterval = 0
    ) {
        self.id = UUID()
        self.content = content
        self.noteType = noteType
        self.createdAt = Date()
        self.lastModified = Date()
        self.isPinned = false
        self.lesson = lesson
        self.timestamp = timestamp
    }
}

/// Type of note
enum NoteType: String, Codable, CaseIterable {
    case text = "text"
    case audioTranscription = "audio_transcription"
    case drawing = "drawing"
    case formula = "formula"
    case keyPoint = "key_point"
    case question = "question"
    
    var displayName: String {
        switch self {
        case .text:
            return "Text Note"
        case .audioTranscription:
            return "Audio Transcription"
        case .drawing:
            return "Drawing"
        case .formula:
            return "Formula"
        case .keyPoint:
            return "Key Point"
        case .question:
            return "Question"
        }
    }
    
    var iconName: String {
        switch self {
        case .text:
            return "doc.text"
        case .audioTranscription:
            return "mic.fill"
        case .drawing:
            return "pencil.tip"
        case .formula:
            return "function"
        case .keyPoint:
            return "star.fill"
        case .question:
            return "questionmark.circle"
        }
    }
}

// MARK: - Extensions

extension Note {
    /// Formatted creation date
    var formattedCreatedDate: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }
    
    /// Formatted timestamp
    var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Preview of the content (first 100 characters)
    var preview: String {
        let maxLength = 100
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }
    
    /// Update the last modified date
    func touch() {
        lastModified = Date()
    }
} 