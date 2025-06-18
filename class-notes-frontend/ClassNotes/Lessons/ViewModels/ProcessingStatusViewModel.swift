import Foundation
import SwiftUI
import OSLog

/// ViewModel for tracking real-time processing status using server streaming
@MainActor
final class ProcessingStatusViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var status: ProcessingStatus?
    @Published var progress: Double = 0
    @Published var isComplete = false
    @Published var error: Error?
    @Published var stages: [ProcessingStage] = []
    
    // MARK: - Private Properties
    
    private var statusTask: Task<Void, Error>?
    private let classNotesService = ClassNotesService.shared
    private let logger = OSLog(subsystem: "com.classnotes", category: "Processing")
    
    // MARK: - Types
    
    struct ProcessingStage {
        let id = UUID()
        let name: String
        let startTime: Date
        var endTime: Date?
        var status: Status
        
        enum Status {
            case pending
            case inProgress
            case completed
            case failed(String)
        }
    }
    
    // MARK: - Public Methods
    
    /// Start observing processing status for a class note
    func startObserving(classNoteId: String) {
        logger.info("Starting to observe processing status for: \(classNoteId)")
        
        // Cancel any existing observation
        statusTask?.cancel()
        
        // Reset state
        status = nil
        progress = 0
        isComplete = false
        error = nil
        stages = [
            ProcessingStage(name: "Transcription", startTime: Date(), status: .pending),
            ProcessingStage(name: "AI Analysis", startTime: Date(), status: .pending),
            ProcessingStage(name: "PDF Generation", startTime: Date(), status: .pending)
        ]
        
        // Start new observation
        statusTask = Task {
            do {
                for try await update in classNotesService.observeProcessingStatus(classNoteId: classNoteId) {
                    // Check for task cancellation
                    try Task.checkCancellation()
                    
                    // Update status
                    self.status = update
                    self.progress = update.progress
                    self.isComplete = update.isComplete
                    
                    // Update stage based on status
                    updateStages(from: update)
                    
                    logger.debug("Processing update: \(update.stage) - \(Int(update.progress * 100))%")
                    
                    if update.isComplete {
                        logger.info("Processing completed for: \(classNoteId)")
                        break
                    }
                    
                    if let error = update.error {
                        logger.error("Processing error: \(error)")
                        self.error = ProcessingError.processingFailed(error)
                        break
                    }
                }
            } catch is CancellationError {
                logger.info("Processing observation cancelled")
            } catch {
                logger.error("Error observing processing status: \(error)")
                self.error = error
            }
        }
    }
    
    /// Stop observing processing status
    func stopObserving() {
        logger.info("Stopping processing observation")
        statusTask?.cancel()
        statusTask = nil
    }
    
    /// Retry processing for a failed class note
    func retryProcessing(classNoteId: String) async {
        logger.info("Retrying processing for: \(classNoteId)")
        
        do {
            // Assuming there's a retry endpoint
            // let response = try await classNotesService.retryProcessing(classNoteId: classNoteId)
            
            // For now, just restart observation
            startObserving(classNoteId: classNoteId)
        } catch {
            logger.error("Failed to retry processing: \(error)")
            self.error = error
        }
    }
    
    // MARK: - Private Methods
    
    private func updateStages(from update: ProcessingStatus) {
        // Update stages based on the current processing stage
        switch update.stage.lowercased() {
        case "transcription", "transcribing":
            updateStage(at: 0, status: .inProgress)
            
        case "transcription_complete":
            updateStage(at: 0, status: .completed)
            updateStage(at: 1, status: .inProgress)
            
        case "ai_analysis", "analyzing":
            updateStage(at: 0, status: .completed)
            updateStage(at: 1, status: .inProgress)
            
        case "analysis_complete":
            updateStage(at: 1, status: .completed)
            updateStage(at: 2, status: .inProgress)
            
        case "pdf_generation", "generating_pdf":
            updateStage(at: 1, status: .completed)
            updateStage(at: 2, status: .inProgress)
            
        case "complete", "completed":
            updateStage(at: 2, status: .completed)
            
        case let stage where stage.contains("error") || stage.contains("failed"):
            if let error = update.error {
                // Find the appropriate stage to mark as failed
                if stage.contains("transcription") {
                    updateStage(at: 0, status: .failed(error))
                } else if stage.contains("analysis") {
                    updateStage(at: 1, status: .failed(error))
                } else if stage.contains("pdf") {
                    updateStage(at: 2, status: .failed(error))
                }
            }
            
        default:
            break
        }
    }
    
    private func updateStage(at index: Int, status: ProcessingStage.Status) {
        guard stages.indices.contains(index) else { return }
        
        stages[index].status = status
        if case .completed = status, stages[index].endTime == nil {
            stages[index].endTime = Date()
        }
    }
    
    deinit {
        statusTask?.cancel()
    }
}

// MARK: - Error Types

enum ProcessingError: LocalizedError {
    case processingFailed(String)
    case timeout
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .timeout:
            return "Processing timed out"
        case .cancelled:
            return "Processing was cancelled"
        }
    }
}

// MARK: - Mock Implementation

#if DEBUG
class MockProcessingStatusViewModel: ProcessingStatusViewModel {
    override func startObserving(classNoteId: String) {
        // Simulate processing stages
        Task {
            // Transcription
            updateStage(at: 0, status: .inProgress)
            progress = 0.1
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            progress = 0.3
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            updateStage(at: 0, status: .completed)
            
            // AI Analysis
            updateStage(at: 1, status: .inProgress)
            progress = 0.5
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            progress = 0.7
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            updateStage(at: 1, status: .completed)
            
            // PDF Generation
            updateStage(at: 2, status: .inProgress)
            progress = 0.9
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            progress = 1.0
            updateStage(at: 2, status: .completed)
            isComplete = true
        }
    }
}
#endif 