import Foundation

/// Batched request manager following cursor rules pattern
actor BatchedRequestManager {
    struct PendingRequest {
        let id: String
        let continuation: AsyncThrowingStream<Document, Error>.Continuation
    }

    private var pendingRequests: [String: PendingRequest] = [:]
    private let batchSize = 10
    private let batchDelay: TimeInterval = 0.5
    private var batchTask: Task<Void, Never>?

    func fetchDocument(id: String) async throws -> Document {
        if let pending = pendingRequests[id] {
            return try await withAsyncThrowingStream { continuation in
                continuation = pending.continuation
            }
        }

        return try await withAsyncThrowingStream { continuation in
            pendingRequests[id] = PendingRequest(id: id, continuation: continuation)

            // Schedule batch processing if not already scheduled
            if batchTask == nil {
                batchTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(batchDelay * 1_000_000_000))
                    await processBatch()
                    batchTask = nil
                }
            }
        }
    }

    private func processBatch() async {
        let batch = Array(pendingRequests.prefix(batchSize))
        guard !batch.isEmpty else { return }

        // Remove from pending
        batch.forEach { pendingRequests.removeValue(forKey: $0.key) }

        do {
            let request = Classnotes_V1_BatchGetDocumentsRequest.with {
                $0.documentIds = batch.map { $0.value.id }
            }

            let client = await GRPCClientProvider.shared.getServiceClient()
            let response = try await client.batchGetDocuments(request)

            // Resolve continuations
            for document in response.documents {
                if let pending = batch.first(where: { $0.value.id == document.id }) {
                    pending.value.continuation.yield(Document(from: document))
                    pending.value.continuation.finish()
                }
            }

            // Handle any missing documents
            for pending in batch {
                pending.value.continuation.finish(
                    throwing: NetworkError.serverError(
                        code: "NOT_FOUND",
                        message: "Document not found"
                    ))
            }
        } catch {
            // Reject all continuations
            batch.forEach { $0.value.continuation.finish(throwing: error) }
        }
    }

    func cancelRequest(id: String) async {
        if let pending = pendingRequests.removeValue(forKey: id) {
            pending.continuation.finish()
        }
    }
}

// Helper to work with AsyncThrowingStream
private func withAsyncThrowingStream<T>(
    _ body: (AsyncThrowingStream<T, Error>.Continuation) async throws -> Void
) async throws -> T {
    let stream = AsyncThrowingStream<T, Error> { continuation in
        Task {
            try await body(continuation)
        }
    }

    for try await value in stream {
        return value
    }

    throw NetworkError.unknown(NSError(domain: "BatchError", code: -1))
}
