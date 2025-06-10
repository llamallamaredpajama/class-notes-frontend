//
//  AudioRecording.swift
//  class-notes-frontend
//
//  Model representing an audio recording within a lesson
//

import Foundation
import SwiftData

/// Represents an audio recording in a lesson
@Model
final class AudioRecording {
    /// Unique identifier for the recording
    @Attribute(.unique) var id: UUID
    
    /// Title of the recording
    var title: String
    
    /// File URL for the audio file
    var fileURL: URL
    
    /// Duration in seconds
    var duration: TimeInterval
    
    /// File size in bytes
    var fileSize: Int64
    
    /// Date when the recording was created
    var createdAt: Date
    
    /// Whether transcription is available
    var isTranscribed: Bool
    
    /// Transcription status
    var transcriptionStatus: TranscriptionStatus
    
    /// Audio quality settings
    var quality: AudioQuality
    
    // MARK: - Relationships
    
    /// The lesson this recording belongs to
    var lesson: Lesson?
    
    /// Notes created from this recording
    @Relationship(deleteRule: .nullify, inverse: \Note.audioRecording)
    var notes: [Note]
    
    // MARK: - Initialization
    
    init(
        title: String,
        fileURL: URL,
        duration: TimeInterval,
        fileSize: Int64,
        quality: AudioQuality = .high,
        lesson: Lesson? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.fileURL = fileURL
        self.duration = duration
        self.fileSize = fileSize
        self.createdAt = Date()
        self.isTranscribed = false
        self.transcriptionStatus = .notStarted
        self.quality = quality
        self.lesson = lesson
        self.notes = []
    }
}

/// Audio quality settings
enum AudioQuality: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low Quality"
        case .medium:
            return "Medium Quality"
        case .high:
            return "High Quality"
        }
    }
    
    var sampleRate: Double {
        switch self {
        case .low:
            return 22050
        case .medium:
            return 44100
        case .high:
            return 48000
        }
    }
    
    var bitRate: Int {
        switch self {
        case .low:
            return 64000
        case .medium:
            return 128000
        case .high:
            return 256000
        }
    }
}

/// Transcription status
enum TranscriptionStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
    
    var iconName: String {
        switch self {
        case .notStarted:
            return "circle"
        case .inProgress:
            return "arrow.clockwise"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Extensions

extension AudioRecording {
    /// Formatted duration string
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formatted file size
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// Formatted creation date
    var formattedCreatedDate: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }
    
    /// File name from URL
    var fileName: String {
        fileURL.lastPathComponent
    }
} 