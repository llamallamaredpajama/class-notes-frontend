import Foundation

/// Request coalescer following cursor rules pattern for performance optimization
actor RequestCoalescer<Request: Hashable, Response> {
    private var pendingRequests: [Request: [CheckedContinuation<Response, Error>]] = [:]
    private let processor: (Request) async throws -> Response

    init(processor: @escaping (Request) async throws -> Response) {
        self.processor = processor
    }

    func request(_ request: Request) async throws -> Response {
        // Check if there's already a pending request
        if pendingRequests[request] != nil {
            // Join the existing request
            return try await withCheckedThrowingContinuation { continuation in
                pendingRequests[request]?.append(continuation)
            }
        }

        // Start new request
        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[request] = [continuation]

            Task {
                do {
                    let response = try await processor(request)

                    // Fulfill all waiting continuations
                    if let continuations = pendingRequests.removeValue(forKey: request) {
                        for cont in continuations {
                            cont.resume(returning: response)
                        }
                    }
                } catch {
                    // Reject all waiting continuations
                    if let continuations = pendingRequests.removeValue(forKey: request) {
                        for cont in continuations {
                            cont.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
}
