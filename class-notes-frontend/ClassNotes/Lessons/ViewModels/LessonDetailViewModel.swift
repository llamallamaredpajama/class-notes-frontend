//
//  LessonDetailViewModel.swift
//  class-notes-frontend
//
//  ViewModel for managing lesson details and recording
//

import AVFoundation
import Foundation
import OSLog
import SwiftUI

@MainActor
class LessonDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var lesson: Lesson
    @Published private(set) var isRecording = false
    @Published private(set) var isPaused = false
    @Published private(set) var recordingDuration: TimeInterval = 0
    @Published private(set) var isTranscribing = false
    @Published private(set) var isSaving = false
    @Published private(set) var error: Error?
    @Published var editedTitle: String
    @Published var editedTranscript: String

    // MARK: - Recording State
    enum RecordingState {
        case idle
        case recording
        case paused
        case transcribing
    }

    @Published private(set) var recordingState: RecordingState = .idle

    // MARK: - Private Properties
    private let lessonService: LessonServiceProtocol
    private let audioService: AudioServiceProtocol
    private let transcriptionService: TranscriptionServiceProtocol
    private let logger = OSLog.lessons
    private var recordingTimer: Timer?

    // MARK: - Initialization
    init(
        lesson: Lesson,
        lessonService: LessonServiceProtocol,
        audioService: AudioServiceProtocol,
        transcriptionService: TranscriptionServiceProtocol
    ) {
        self.lesson = lesson
        self.lessonService = lessonService
        self.audioService = audioService
        self.transcriptionService = transcriptionService
        self.editedTitle = lesson.title
        self.editedTranscript = lesson.transcript

        logger.debug("LessonDetailViewModel initialized for lesson: \(lesson.title)")
    }

    // MARK: - Public Methods

    // MARK: Recording Control
    func startRecording() async {
        logger.functionEntry("startRecording")

        do {
            // Request microphone permission if needed
            let hasPermission = await audioService.requestMicrophonePermission()
            guard hasPermission else {
                throw AppError.audio("Microphone permission is required to record audio.")
            }

            // Start audio recording
            try await audioService.startRecording(for: lesson.id)

            isRecording = true
            isPaused = false
            recordingState = .recording
            startRecordingTimer()

            logger.info("Started recording for lesson: \(self.lesson.title)")
        } catch {
            logger.error("Failed to start recording: \(error)")
            self.error = error
        }
    }

    func pauseRecording() {
        logger.debug("Pausing recording")

        audioService.pauseRecording()
        isPaused = true
        recordingState = .paused
        stopRecordingTimer()
    }

    func resumeRecording() {
        logger.debug("Resuming recording")

        audioService.resumeRecording()
        isPaused = false
        recordingState = .recording
        startRecordingTimer()
    }

    func stopRecording() async {
        logger.functionEntry("stopRecording")

        stopRecordingTimer()
        isRecording = false
        isPaused = false
        recordingState = .transcribing
        isTranscribing = true

        do {
            // Stop audio recording and get the file URL
            let audioURL = try await audioService.stopRecording()
            logger.debug("Audio saved to: \(audioURL.path)")

            // Start transcription
            logger.debug("Starting transcription...")
            let transcript = try await transcriptionService.transcribe(audioURL: audioURL)

            // Update lesson with new transcript
            lesson.transcript = transcript
            lesson.duration = Int(recordingDuration)
            editedTranscript = transcript

            // Save to backend
            try await saveLesson()

            recordingState = .idle
            isTranscribing = false

            logger.info("Successfully completed recording and transcription")
        } catch {
            logger.error("Failed to stop recording: \(error)")
            self.error = error
            recordingState = .idle
            isTranscribing = false
        }
    }

    // MARK: Editing
    func saveLesson() async throws {
        logger.functionEntry("saveLesson")

        isSaving = true
        defer { isSaving = false }

        // Update lesson with edited values
        lesson.title = editedTitle
        lesson.transcript = editedTranscript

        do {
            let updatedLesson = try await lessonService.updateLesson(lesson)
            self.lesson = updatedLesson

            logger.info("Successfully saved lesson: \(self.lesson.title)")
        } catch {
            logger.error("Failed to save lesson: \(error)")
            throw error
        }
    }

    func exportToPDF() async -> URL? {
        logger.functionEntry("exportToPDF")

        do {
            let pdfURL = try await lessonService.exportLessonToPDF(lesson)
            logger.info("Successfully exported lesson to PDF: \(pdfURL)")
            return pdfURL
        } catch {
            logger.error("Failed to export to PDF: \(error)")
            self.error = error
            return nil
        }
    }

    func shareLesson() async -> URL? {
        logger.debug("Sharing lesson: \(self.lesson.title)")

        // For now, export to PDF for sharing
        return await exportToPDF()
    }

    // MARK: - Private Methods
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.recordingDuration += 1
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

// MARK: - Mock Implementation for Previews
#if DEBUG
    class MockLessonDetailViewModel: LessonDetailViewModel {
        init(lesson: Lesson) {
            super.init(
                lesson: lesson,
                lessonService: MockLessonService(),
                audioService: MockAudioService(),
                transcriptionService: MockTranscriptionService()
            )
        }
    }

    // Mock Services
    class MockAudioService: AudioServiceProtocol {
        var isRecording: Bool = false
        var recordingDuration: TimeInterval = 0

        func requestMicrophonePermission() async -> Bool {
            return true
        }

        func startRecording(for lessonId: UUID) async throws {
            // Mock implementation
            isRecording = true
        }

        func pauseRecording() {
            // Mock implementation
        }

        func resumeRecording() {
            // Mock implementation
        }

        func stopRecording() async throws -> URL {
            isRecording = false
            return URL(fileURLWithPath: "/mock/audio.m4a")
        }
    }

    class MockTranscriptionService: TranscriptionServiceProtocol {
        var isTranscribing: Bool = false

        func transcribe(audioURL: URL) async throws -> String {
            isTranscribing = true
            // Simulate transcription delay
            try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
            isTranscribing = false
            return "This is a mock transcript for testing purposes."
        }

        func cancelTranscription() {
            // Mock implementation
            isTranscribing = false
        }
    }
#endif
