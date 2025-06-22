import Foundation
import GeneratedProtos
import OSLog
import SwiftProtobuf

/// Main service for Class Notes operations following cursor rules patterns
@MainActor
final class ClassNotesService: ObservableObject {
    static let shared = ClassNotesService()

    private let provider = GRPCClientProvider.shared
    private let cacheManager = CacheManager.shared
    private let offlineQueue = OfflineOperationQueue.shared
    private let logger = Logger(subsystem: "com.classnotes", category: "service")

    private init() {}

    // MARK: - Lesson Operations

    /// Create a new lesson with offline support
    func createLesson(_ lesson: Lesson) async throws -> Lesson {
        // Check network availability
        guard NetworkMonitor.shared.isConnected else {
            // Queue for later
            try await offlineQueue.enqueue(.createLesson(lesson))
            // Return with temporary ID
            return lesson.withTemporaryID()
        }

        // Create request
        let request = Classnotes_V1_CreateLessonRequest.with {
            $0.title = lesson.title
            $0.subject = lesson.subject
            $0.classroomID = lesson.classroomId
        }

        // Make gRPC call
        do {
            let client = provider.getServiceClient()
            let response = try await client.createLesson(request)
            let createdLesson = Lesson(from: response.lesson)

            // Update cache
            try await cacheManager.cache(createdLesson)

            return createdLesson
        } catch {
            throw mapGRPCError(error)
        }
    }

    /// Fetch lessons with cache-first approach
    func fetchLessons() async throws -> [Lesson] {
        // Always return cached data first
        let cachedLessons = try await cacheManager.fetchLessons()

        // Fetch fresh data in background
        Task.detached { [weak self] in
            guard let self else { return }

            do {
                let request = Classnotes_V1_ListClassNotesRequest()
                let client = await self.provider.getServiceClient()
                let response = try await client.listClassNotes(request)
                let lessons = response.classNotes.map { Lesson(from: $0) }

                // Update cache
                try await self.cacheManager.syncLessons(lessons)
            } catch {
                // Log but don't throw - we have cached data
                self.logger.error("Failed to sync lessons: \(error)")
            }
        }

        return cachedLessons
    }

    /// Stream processing status for a lesson
    func streamProcessingStatus(for lessonID: String) -> AsyncStream<ProcessingStatus> {
        AsyncStream { continuation in
            Task {
                do {
                    let request = Classnotes_V1_StreamProcessingStatusRequest.with {
                        $0.lessonID = lessonID
                    }

                    let client = provider.getServiceClient()
                    let stream = client.streamProcessingStatus(request)

                    for try await status in stream {
                        continuation.yield(ProcessingStatus(from: status))
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Document Operations

    /// Upload a transcript with audio
    func uploadTranscript(
        classNoteId: String,
        audioData: Data,
        mimeType: String,
        duration: Double,
        language: String = "en"
    ) async throws -> Classnotes_V1_UploadTranscriptResponse {
        let request = Classnotes_V1_UploadTranscriptRequest.with {
            $0.classNoteID = classNoteId
            $0.audioData = audioData
            $0.mimeType = mimeType
            $0.durationSeconds = duration
            $0.language = language
        }

        do {
            let client = provider.getServiceClient()
            return try await client.uploadTranscript(request)
        } catch {
            throw mapGRPCError(error)
        }
    }

    // MARK: - Batch Operations

    /// Batch delete lessons with progress tracking
    func batchDeleteLessons(_ lessonIDs: [String]) async throws {
        // Show progress
        let progress = Progress(totalUnitCount: Int64(lessonIDs.count))

        // Batch into chunks
        let chunks = lessonIDs.chunked(into: 10)

        for chunk in chunks {
            let request = Classnotes_V1_BatchDeleteLessonsRequest.with {
                $0.lessonIds = chunk
            }

            do {
                let client = provider.getServiceClient()
                _ = try await client.batchDeleteLessons(request)
                progress.completedUnitCount += Int64(chunk.count)
            } catch {
                throw mapGRPCError(error)
            }
        }
    }

    // MARK: - Real-time Updates

    /// Observe all processing updates for current user
    func observeProcessingUpdates() -> AsyncStream<ProcessingUpdate> {
        AsyncStream { continuation in
            let task = Task {
                do {
                    let client = provider.getServiceClient()
                    let stream = client.streamAllProcessingUpdates(Google_Protobuf_Empty())

                    for try await update in stream {
                        // Filter updates for current user
                        if update.userID == AuthenticationService.shared.currentUser?.id.uuidString
                        {
                            continuation.yield(ProcessingUpdate(from: update))
                        }
                    }
                } catch {
                    logger.error("Stream error: \(error)")
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
