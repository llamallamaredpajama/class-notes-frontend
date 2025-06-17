// 1. Standard library
import Foundation

// MARK: - Lesson Detail State

/// Equatable state representation for LessonDetailViewModel
/// This enables SwiftUI to efficiently determine when views need to be redrawn
struct LessonDetailState: Equatable {
    var lesson: LessonInfo
    var isRecording: Bool = false
    var isPaused: Bool = false
    var recordingDuration: TimeInterval = 0
    var isTranscribing: Bool = false
    var isSaving: Bool = false
    var recordingState: RecordingState = .idle
    var editedTitle: String
    var editedTranscript: String
    var error: ErrorInfo? = nil
    
    /// Lightweight lesson representation for state comparison
    struct LessonInfo: Equatable {
        let id: UUID
        let title: String
        let date: Date
        let duration: Int
        let transcript: String
        let hasAudio: Bool
        let hasPDF: Bool
        let isFavorite: Bool
        let syncStatus: String
        
        init(from lesson: Lesson) {
            self.id = lesson.id
            self.title = lesson.title
            self.date = lesson.date
            self.duration = lesson.duration
            self.transcript = lesson.transcript
            self.hasAudio = lesson.hasAudio
            self.hasPDF = lesson.hasPDF
            self.isFavorite = lesson.isFavorite
            self.syncStatus = lesson.syncStatus.rawValue
        }
    }
    
    /// Equatable recording state
    enum RecordingState: String, Equatable {
        case idle
        case recording
        case paused
        case transcribing
    }
    
    /// Equatable error representation
    struct ErrorInfo: Equatable {
        let message: String
        let code: String
        
        init(from error: Error) {
            if let appError = error as? AppError {
                self.message = appError.errorDescription ?? "Unknown error"
                self.code = appError.errorCode
            } else {
                self.message = error.localizedDescription
                self.code = "system"
            }
        }
    }
    
    /// Initialize from lesson
    init(lesson: Lesson, editedTitle: String, editedTranscript: String) {
        self.lesson = LessonInfo(from: lesson)
        self.editedTitle = editedTitle
        self.editedTranscript = editedTranscript
    }
}

// MARK: - ViewModel Extension

extension LessonDetailViewModel {
    /// Current state for efficient SwiftUI updates
    var state: LessonDetailState {
        var state = LessonDetailState(
            lesson: lesson,
            editedTitle: editedTitle,
            editedTranscript: editedTranscript
        )
        
        state.isRecording = isRecording
        state.isPaused = isPaused
        state.recordingDuration = recordingDuration
        state.isTranscribing = isTranscribing
        state.isSaving = isSaving
        state.recordingState = LessonDetailState.RecordingState(rawValue: recordingState.description) ?? .idle
        state.error = error.map { LessonDetailState.ErrorInfo(from: $0) }
        
        return state
    }
    
    /// Check if state has changed in a way that requires view update
    func shouldUpdateView(oldState: LessonDetailState, newState: LessonDetailState) -> Bool {
        // Check for significant changes that require view updates
        if oldState.recordingState != newState.recordingState { return true }
        if oldState.isTranscribing != newState.isTranscribing { return true }
        if oldState.isSaving != newState.isSaving { return true }
        if oldState.error != newState.error { return true }
        
        // For recording duration, only update at second intervals
        if oldState.isRecording && abs(oldState.recordingDuration - newState.recordingDuration) >= 1.0 {
            return true
        }
        
        // Check lesson content changes
        if oldState.lesson != newState.lesson { return true }
        if oldState.editedTitle != newState.editedTitle { return true }
        if oldState.editedTranscript != newState.editedTranscript { return true }
        
        return false
    }
}

// MARK: - Recording State Description

extension LessonDetailViewModel.RecordingState {
    var description: String {
        switch self {
        case .idle:
            return "idle"
        case .recording:
            return "recording"
        case .paused:
            return "paused"
        case .transcribing:
            return "transcribing"
        }
    }
} 