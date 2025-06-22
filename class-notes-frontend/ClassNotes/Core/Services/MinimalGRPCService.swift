import Foundation
import GeneratedProtos
import OSLog

/// Minimal gRPC service to establish a working baseline
/// Step 1: Get ONE successful gRPC call working
final class MinimalGRPCService {
    static let shared = MinimalGRPCService()
    private let logger = OSLog(subsystem: "com.classnotes", category: "MinimalGRPC")

    private var client: GRPCClient<HTTP2ClientTransport.Posix>?
    private var transport: HTTP2ClientTransport.Posix?

    private init() {}

    /// The absolute minimal interceptor setup - just AppCheckInterceptor which we know works
    private var interceptors: [any ClientInterceptor] {
        return [
            AppCheckInterceptor.development  // Start with development mode
        ]
    }

    /// Create or get the gRPC client
    private func getClient() async throws -> GRPCClient<HTTP2ClientTransport.Posix> {
        if let existingClient = client {
            return existingClient
        }

        // Create transport with minimal config
        let newTransport = try HTTP2ClientTransport.Posix(
            target: .dns(host: "localhost", port: 8080),
            transportSecurity: .plaintext
        )

        // Create client
        let newClient = GRPCClient(
            transport: newTransport,
            interceptors: interceptors
        )

        self.transport = newTransport
        self.client = newClient

        return newClient
    }

    /// Make a simple list request - the most basic gRPC call
    func testListClassNotes() async throws {
        os_log("🚀 Starting minimal gRPC test", log: logger, type: .info)

        do {
            let grpcClient = try await getClient()

            // Create the service client
            let client = Classnotes_V1_ClassNotesAPI.Client(wrapping: grpcClient)

            // Create the simplest possible request
            let request = Classnotes_V1_ListClassNotesRequest()

            // Make the call
            os_log("📤 Sending ListClassNotes request", log: self.logger, type: .debug)
            let response = try await client.listClassNotes(request)

            // Success!
            os_log(
                "✅ Success! Received %d class notes", log: self.logger, type: .info,
                response.classNotes.count)

            // Print first note title if available
            if let firstNote = response.classNotes.first {
                os_log(
                    "📝 First note title: %{public}@", log: self.logger, type: .info, firstNote.title
                )
            }
        } catch {
            os_log(
                "❌ gRPC call failed: %{public}@", log: logger, type: .error,
                String(describing: error))
            throw error
        }
    }

    /// Test the connection with proper error handling
    func testConnection() async -> Bool {
        do {
            try await testListClassNotes()
            return true
        } catch {
            os_log(
                "Connection test failed: %{public}@", log: logger, type: .error,
                String(describing: error))
            return false
        }
    }

    /// Clean up resources
    func close() async {
        await client?.close()
        client = nil
        transport = nil
    }
}

// MARK: - Usage in SwiftUI

extension MinimalGRPCService {
    /// Call this from a SwiftUI view to test
    /// Example:
    /// ```
    /// Button("Test gRPC") {
    ///     Task {
    ///         await MinimalGRPCService.shared.testConnection()
    ///     }
    /// }
    /// ```
    static func runTest() {
        Task {
            let success = await MinimalGRPCService.shared.testConnection()
            print("gRPC Test Result: \(success ? "✅ Success" : "❌ Failed")")
        }
    }
}
