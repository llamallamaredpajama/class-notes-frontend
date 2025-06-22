import Foundation
import GeneratedProtos
import OSLog

/// gRPC implementation of LessonServiceProtocol using ClassNotesService
final class LessonServiceGRPCImplementation: LessonServiceProtocol {
    private let classNotesService = ClassNotesService.shared
    private let logger = OSLog(subsystem: "com.classnotes", category: "LessonService")

    func createLesson(_ lesson: Lesson) async throws -> Lesson {
        logger.info("Creating lesson via gRPC: \(lesson.title)")

        // For now, we'll use the upload transcript flow
        // In a real implementation, you'd have a CreateClassNote RPC
        let audioData = Data()  // Empty data for new lesson

        let response = try await classNotesService.uploadTranscript(
            classNoteId: lesson.id.uuidString,
            audioData: audioData,
            mimeType: "audio/m4a",
            durationSeconds: 0,
            language: "en-US"
        )

        // Map response back to Lesson
        var updatedLesson = lesson
        updatedLesson.processingStatus = mapProcessingStatus(response.status)

        return updatedLesson
    }

    func updateLesson(_ lesson: Lesson) async throws -> Lesson {
        logger.info("Updating lesson via gRPC: \(lesson.id)")

        // In a real implementation, you'd have an UpdateClassNote RPC
        // For now, return the lesson as-is
        return lesson
    }

    func deleteLesson(_ lesson: Lesson) async throws {
        logger.info("Deleting lesson via gRPC: \(lesson.id)")

        try await classNotesService.deleteClassNote(id: lesson.id.uuidString)
    }

    func fetchLessons() async throws -> [Lesson] {
        logger.info("Fetching lessons via gRPC")

        let response = try await classNotesService.listClassNotes(
            pageSize: 50,
            pageToken: nil
        )

        return response.classNotes.map { classNote in
            Lesson(from: classNote)
        }
    }

    func exportLessonToPDF(_ lesson: Lesson) async throws -> URL {
        logger.info("Exporting lesson to PDF: \(lesson.id)")

        // Get the processed class note which should have a PDF URL
        let response = try await classNotesService.getClassNote(id: lesson.id.uuidString)

        // In a real implementation, you'd download the PDF from the URL
        // For now, create a temporary file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(lesson.id).pdf")

        // You would download the PDF content here
        // For demo, just return the temp URL
        return tempURL
    }

    func syncLesson(_ lesson: Lesson) async throws -> Lesson {
        logger.info("Syncing lesson: \(lesson.id)")

        // Fetch the latest version from the server
        let response = try await classNotesService.getClassNote(id: lesson.id.uuidString)

        // Map the response to a Lesson
        var syncedLesson = lesson
        syncedLesson.title = response.title
        syncedLesson.transcript = response.content
        syncedLesson.processingStatus = mapProcessingStatus(response.status)
        syncedLesson.lastModified = response.hasModifiedAt ? response.modifiedAt.date : Date()
        syncedLesson.syncStatus = .synced

        return syncedLesson
    }

    // MARK: - Helper Methods

    private func mapProcessingStatus(_ status: Classnotes_V1_ProcessingStatus) -> Lesson
        .ProcessingStatus?
    {
        switch status {
        case .pending, .transcriptProcessing, .ocrProcessing, .aiAnalysis, .pdfGeneration:
            return .processing
        case .completed:
            return .completed
        case .failed, .cancelled:
            return .failed
        case .unspecified:
            return nil
        }
    }
}

// MARK: - Lesson Extension for gRPC Integration

extension Lesson {
    /// Initialize from protobuf class note summary
    init(from proto: Classnotes_V1_ClassNoteSummary) {
        self.init(
            title: proto.title,
            date: proto.hasCreatedAt ? proto.createdAt.date : Date(),
            duration: 0,  // Not available in summary
            transcript: proto.textPreview,
            audioURL: nil,
            pdfURL: nil,
            tags: proto.tags,
            isFavorite: false,
            lastModified: proto.hasModifiedAt ? proto.modifiedAt.date : Date(),
            syncStatus: .synced
        )

        // Handle ID mapping
        if let uuid = UUID(uuidString: proto.classNoteID) {
            self.id = uuid
        }

        self.summary = proto.summary

        // Map processing status
        switch proto.status {
        case .pending, .transcriptProcessing, .ocrProcessing, .aiAnalysis, .pdfGeneration:
            self.processingStatus = .processing
        case .completed:
            self.processingStatus = .completed
        case .failed, .cancelled:
            self.processingStatus = .failed
        case .unspecified:
            self.processingStatus = nil
        }
    }
}
