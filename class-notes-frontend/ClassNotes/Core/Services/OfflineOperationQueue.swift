import Foundation
import OSLog

/// Offline operations following cursor rules pattern
enum OfflineOperation: Codable {
    case createLesson(Lesson)
    case updateLesson(Lesson)
    case deleteLesson(id: String)
    case uploadDocument(Document)
}

/// Offline operation queue following cursor rules pattern
final class OfflineOperationQueue {
    static let shared = OfflineOperationQueue()

    private let queue = DispatchQueue(label: "offline.queue", attributes: .concurrent)
    private let storage: UserDefaults
    private let key = "offline_operations"
    private let logger = Logger(subsystem: "com.classnotes", category: "offline")

    private init(storage: UserDefaults = .standard) {
        self.storage = storage
    }

    func enqueue(_ operation: OfflineOperation) async throws {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                var operations = self.loadOperations()
                operations.append(operation)
                self.saveOperations(operations)
                continuation.resume()
            }
        }
    }

    func processQueue() async {
        guard NetworkMonitor.shared.isConnected else { return }

        let operations = loadOperations()
        var failedOperations: [OfflineOperation] = []

        for operation in operations {
            do {
                try await processOperation(operation)
            } catch {
                failedOperations.append(operation)
                logger.error("Failed to process offline operation: \(error)")
            }
        }

        // Save failed operations back to queue
        saveOperations(failedOperations)
    }

    private func processOperation(_ operation: OfflineOperation) async throws {
        switch operation {
        case .createLesson(let lesson):
            _ = try await LessonService.shared.createLesson(lesson)
        case .updateLesson(let lesson):
            _ = try await LessonService.shared.updateLesson(lesson)
        case .deleteLesson(let id):
            try await LessonService.shared.deleteLesson(id: id)
        case .uploadDocument(let document):
            _ = try await DocumentService.shared.upload(document)
        }
    }

    private func loadOperations() -> [OfflineOperation] {
        guard let data = storage.data(forKey: key),
            let operations = try? JSONDecoder().decode([OfflineOperation].self, from: data)
        else {
            return []
        }
        return operations
    }

    private func saveOperations(_ operations: [OfflineOperation]) {
        guard let data = try? JSONEncoder().encode(operations) else { return }
        storage.set(data, forKey: key)
    }
}
