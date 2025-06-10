//
//  AudioServiceProtocol.swift
//  class-notes-frontend
//
//  Protocol defining audio recording operations
//

import Foundation
import AVFoundation

protocol AudioServiceProtocol {
    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool
    
    /// Start recording audio for a lesson
    func startRecording(for lessonId: UUID) async throws
    
    /// Pause the current recording
    func pauseRecording()
    
    /// Resume the current recording
    func resumeRecording()
    
    /// Stop recording and return the audio file URL
    func stopRecording() async throws -> URL
    
    /// Get current recording status
    var isRecording: Bool { get }
    
    /// Get current recording duration
    var recordingDuration: TimeInterval { get }
}

// MARK: - Transcription Service Protocol
protocol TranscriptionServiceProtocol {
    /// Transcribe audio file to text
    func transcribe(audioURL: URL) async throws -> String
    
    /// Cancel ongoing transcription
    func cancelTranscription()
    
    /// Check if transcription is in progress
    var isTranscribing: Bool { get }
} 