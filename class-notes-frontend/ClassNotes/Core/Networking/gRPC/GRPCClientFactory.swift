// Standard library
import Foundation
// Third-party dependencies
import GeneratedProtos
// Apple frameworks
import OSLog

/// Factory for creating type-safe gRPC service clients.
/// Compatible with grpc-swift-2 version 2.0.0.
final class GRPCClientFactory {
    static let shared = GRPCClientFactory()
    private let provider = GRPCClientProvider.shared

    private init() {}

    /// Executes a closure with a ClassNotes client.
    /// This is the preferred way to make gRPC calls.
    func withClassNotesClient<R>(
        _ body: (Classnotes_V1_ClassNotesAPI.Client<GRPCClient<HTTP2ClientTransport.Posix>>)
            async throws -> R
    ) async throws -> R {
        return try await provider.withClassNotesClient(body)
    }
}

// MARK: - Usage Example

extension GRPCClientFactory {
    /// Example showing how to use the factory to make a gRPC call.
    static func demonstrateUsage() async throws {
        try await GRPCClientFactory.shared.withClassNotesClient { client in
            let request = Classnotes_V1_ListClassNotesRequest()
            let response = try await client.listClassNotes(request)
            print("Usage example: received \(response.classNotes.count) notes.")
        }
    }
}
