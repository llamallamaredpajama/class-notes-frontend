import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import SwiftProtobuf

/// Main service for Class Notes operations using gRPC-Swift v2
@MainActor
final class ClassNotesService: ObservableObject {
    static let shared = ClassNotesService()
    
    private let grpcClient: GRPCClient
    private let classNotesClient: Classnotes_V1_ClassNotesService.Client
    
    private init() {
        Task {
            self.grpcClient = await GRPCClientProvider.shared.makeGRPCClient()
            self.classNotesClient = Classnotes_V1_ClassNotesService.Client(
                wrapping: grpcClient
            )
        }
        
        // Initialize with temporary client until async init completes
        self.grpcClient = GRPCClient(
            transport: EmptyTransport(),
            interceptors: []
        )
        self.classNotesClient = Classnotes_V1_ClassNotesService.Client(
            wrapping: self.grpcClient
        )
    }
    
    // MARK: - Transcript Operations
    
    /// Upload a transcript for a class note
    func uploadTranscript(
        classNoteId: String,
        transcript: String,
        metadata: TranscriptMetadata
    ) async throws -> Classnotes_V1_UploadTranscriptResponse {
        let request = Classnotes_V1_UploadTranscriptRequest.with {
            $0.classNoteID = classNoteId
            $0.transcript = transcript
            $0.metadata = metadata.toProto()
        }
        
        return try await classNotesClient.uploadTranscript(request)
    }
    
    // MARK: - Document Operations (Client Streaming)
    
    /// Upload multiple documents for a class note
    func uploadDocuments(
        classNoteId: String,
        documents: [DocumentData]
    ) async throws -> Classnotes_V1_UploadDocumentsResponse {
        // Create stream of document requests
        let requests = documents.map { doc in
            Classnotes_V1_UploadDocumentRequest.with {
                $0.classNoteID = classNoteId
                $0.document = doc.toProto()
            }
        }
        
        // Use client streaming
        return try await classNotesClient.uploadDocuments(
            .init(elements: requests)
        )
    }
    
    // MARK: - Processing Status (Server Streaming)
    
    /// Observe processing status updates for a class note
    func observeProcessingStatus(
        classNoteId: String
    ) -> AsyncThrowingStream<ProcessingStatus, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = Classnotes_V1_GetProcessingStatusRequest.with {
                        $0.classNoteID = classNoteId
                    }
                    
                    let stream = try await classNotesClient.getProcessingStatus(request)
                    
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
    
    // MARK: - Class Note Operations
    
    /// List class notes with pagination
    func listClassNotes(
        pageSize: Int32 = 20,
        pageToken: String? = nil
    ) async throws -> Classnotes_V1_ListClassNotesResponse {
        let request = Classnotes_V1_ListClassNotesRequest.with {
            $0.pageSize = pageSize
            if let token = pageToken {
                $0.pageToken = token
            }
        }
        
        return try await classNotesClient.listClassNotes(request)
    }
    
    /// Get a specific class note by ID
    func getClassNote(id: String) async throws -> ClassNote {
        let request = Classnotes_V1_GetClassNoteRequest.with {
            $0.classNoteID = id
        }
        
        let response = try await classNotesClient.getProcessedClassNote(request)
        return ClassNote(from: response.classNote)
    }
    
    /// Delete a class note
    func deleteClassNote(id: String) async throws {
        let request = Classnotes_V1_DeleteClassNoteRequest.with {
            $0.classNoteID = id
        }
        
        _ = try await classNotesClient.deleteClassNote(request)
    }
    
    // MARK: - Search Operations
    
    /// Search class notes
    func searchClassNotes(
        query: String,
        filters: SearchFilters? = nil,
        pageSize: Int32 = 20,
        pageToken: String? = nil
    ) async throws -> Classnotes_V1_SearchClassNotesResponse {
        let request = Classnotes_V1_SearchClassNotesRequest.with {
            $0.query = query
            $0.pageSize = pageSize
            if let token = pageToken {
                $0.pageToken = token
            }
            if let filters = filters {
                $0.filters = filters.toProto()
            }
        }
        
        return try await classNotesClient.searchClassNotes(request)
    }
}

// MARK: - Data Models

/// Transcript metadata
struct TranscriptMetadata {
    let duration: TimeInterval
    let language: String
    let confidence: Float?
    
    func toProto() -> Classnotes_V1_TranscriptMetadata {
        return Classnotes_V1_TranscriptMetadata.with {
            $0.duration = Int64(duration)
            $0.language = language
            if let confidence = confidence {
                $0.confidence = confidence
            }
        }
    }
}

/// Document data for upload
struct DocumentData {
    let filename: String
    let mimeType: String
    let data: Data
    
    func toProto() -> Classnotes_V1_Document {
        return Classnotes_V1_Document.with {
            $0.filename = filename
            $0.mimeType = mimeType
            $0.data = data
        }
    }
}

/// Processing status
struct ProcessingStatus {
    let stage: String
    let progress: Double
    let isComplete: Bool
    let error: String?
    
    init(from proto: Classnotes_V1_ProcessingStatus) {
        self.stage = proto.stage
        self.progress = proto.progress
        self.isComplete = proto.isComplete
        self.error = proto.error.isEmpty ? nil : proto.error
    }
}

/// Search filters
struct SearchFilters {
    let courseIds: [String]?
    let startDate: Date?
    let endDate: Date?
    let tags: [String]?
    
    func toProto() -> Classnotes_V1_SearchFilters {
        return Classnotes_V1_SearchFilters.with {
            if let courseIds = courseIds {
                $0.courseIds = courseIds
            }
            if let startDate = startDate {
                $0.startDate = Google_Protobuf_Timestamp(date: startDate)
            }
            if let endDate = endDate {
                $0.endDate = Google_Protobuf_Timestamp(date: endDate)
            }
            if let tags = tags {
                $0.tags = tags
            }
        }
    }
}

// MARK: - Empty Transport

/// Temporary transport for initialization
private struct EmptyTransport: ClientTransport {
    func connect(lazily: Bool) async throws -> any Streaming {
        throw GRPCError.transportNotInitialized
    }
    
    func close() async {
        // No-op
    }
} 