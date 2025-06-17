// 1. Standard library
import Foundation

// 2. Apple frameworks
import SwiftData
import Combine
import OSLog

// 3. Third-party dependencies

// 4. Local modules

/// Offline-first implementation of LessonServiceProtocol
@MainActor
class OfflineFirstLessonService: LessonServiceProtocol, ObservableObject {
    // MARK: - Properties
    
    private let cacheManager: CacheManager
    private let networkMonitor: NetworkMonitor
    private let grpcClient: GRPCClientManager
    private let modelContext: ModelContext
    
    @Published var isSyncing = false
    @Published var syncError: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, grpcClient: GRPCClientManager) {
        self.modelContext = modelContext
        self.cacheManager = CacheManager(modelContext: modelContext)
        self.networkMonitor = NetworkMonitor.shared
        self.grpcClient = grpcClient
        
        setupNetworkObserver()
    }
    
    // MARK: - Setup
    
    private func setupNetworkObserver() {
        // Auto-sync when network becomes available
        networkMonitor.$isConnected
            .removeDuplicates()
            .filter { $0 } // Only when connected
            .sink { [weak self] _ in
                Task {
                    await self?.syncPendingOperations()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - LessonServiceProtocol Implementation
    
    func fetchLessons() async throws -> [Lesson] {
        // 1. Return cached data immediately
        let cachedLessons = try cacheManager.getCachedLessons()
        
        // 2. If online and cache is expired, fetch fresh data in background
        if networkMonitor.isConnected && cacheManager.isLessonCacheExpired() {
            Task {
                do {
                    let freshLessons = try await fetchLessonsFromNetwork()
                    try cacheManager.cacheLessons(freshLessons)
                } catch {
                    OSLog.networking.error("Failed to sync lessons: \(error)")
                    syncError = error
                }
            }
        }
        
        return cachedLessons
    }
    
    func fetchLesson(id: UUID) async throws -> Lesson {
        // Try cache first
        let descriptor = FetchDescriptor<Lesson>(
            predicate: #Predicate { $0.id == id }
        )
        
        if let cachedLesson = try modelContext.fetch(descriptor).first {
            // If online, refresh in background
            if networkMonitor.isConnected {
                Task {
                    do {
                        let freshLesson = try await fetchLessonFromNetwork(id: id)
                        try cacheManager.updateCachedLesson(freshLesson)
                    } catch {
                        OSLog.networking.error("Failed to sync lesson: \(error)")
                    }
                }
            }
            return cachedLesson
        }
        
        // If not in cache and offline, throw error
        guard networkMonitor.isConnected else {
            throw AppError.network(NSError(
                domain: "OfflineError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Lesson not available offline"]
            ))
        }
        
        // Fetch from network
        let lesson = try await fetchLessonFromNetwork(id: id)
        try cacheManager.cacheLessons([lesson])
        return lesson
    }
    
    func createLesson(_ lesson: Lesson) async throws -> Lesson {
        // Save to cache immediately
        modelContext.insert(lesson)
        try modelContext.save()
        
        if networkMonitor.isConnected {
            // Try to sync immediately
            do {
                let createdLesson = try await createLessonOnNetwork(lesson)
                // Update with server-generated fields
                lesson.id = createdLesson.id
                try modelContext.save()
                return lesson
            } catch {
                // Save as pending operation
                let payload = try JSONEncoder().encode(lesson.codable)
                let operation = PendingOperation(
                    type: .create,
                    entityId: lesson.id,
                    entityType: "Lesson",
                    payload: payload
                )
                try cacheManager.savePendingOperation(operation)
                throw AppError.network(error)
            }
        } else {
            // Save as pending operation for later sync
            let payload = try JSONEncoder().encode(lesson.codable)
            let operation = PendingOperation(
                type: .create,
                entityId: lesson.id,
                entityType: "Lesson",
                payload: payload
            )
            try cacheManager.savePendingOperation(operation)
        }
        
        return lesson
    }
    
    func updateLesson(_ lesson: Lesson) async throws -> Lesson {
        // Update cache immediately
        try cacheManager.updateCachedLesson(lesson)
        
        if networkMonitor.isConnected {
            // Try to sync immediately
            do {
                let updatedLesson = try await updateLessonOnNetwork(lesson)
                return updatedLesson
            } catch {
                // Save as pending operation
                let payload = try JSONEncoder().encode(lesson.codable)
                let operation = PendingOperation(
                    type: .update,
                    entityId: lesson.id,
                    entityType: "Lesson",
                    payload: payload
                )
                try cacheManager.savePendingOperation(operation)
                throw AppError.network(error)
            }
        } else {
            // Save as pending operation
            let payload = try JSONEncoder().encode(lesson.codable)
            let operation = PendingOperation(
                type: .update,
                entityId: lesson.id,
                entityType: "Lesson",
                payload: payload
            )
            try cacheManager.savePendingOperation(operation)
        }
        
        return lesson
    }
    
    func deleteLesson(_ id: UUID) async throws {
        // Delete from cache
        let descriptor = FetchDescriptor<Lesson>(
            predicate: #Predicate { $0.id == id }
        )
        
        if let lesson = try modelContext.fetch(descriptor).first {
            try cacheManager.deleteCachedLesson(lesson)
        }
        
        if networkMonitor.isConnected {
            // Try to sync immediately
            do {
                try await deleteLessonOnNetwork(id)
            } catch {
                // Save as pending operation
                let operation = PendingOperation(
                    type: .delete,
                    entityId: id,
                    entityType: "Lesson"
                )
                try cacheManager.savePendingOperation(operation)
                throw AppError.network(error)
            }
        } else {
            // Save as pending operation
            let operation = PendingOperation(
                type: .delete,
                entityId: id,
                entityType: "Lesson"
            )
            try cacheManager.savePendingOperation(operation)
        }
    }
    
    func exportLessonToPDF(_ lesson: Lesson) async throws -> URL {
        // This operation requires network
        guard networkMonitor.isConnected else {
            throw AppError.network(NSError(
                domain: "OfflineError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "PDF export requires internet connection"]
            ))
        }
        
        return try await exportLessonToPDFOnNetwork(lesson)
    }
    
    func searchLessons(query: String) async throws -> [Lesson] {
        // Search in cache first
        let cachedLessons = try cacheManager.getCachedLessons()
        let filteredLessons = cachedLessons.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.transcript.localizedCaseInsensitiveContains(query) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
        
        // If online, also search on network
        if networkMonitor.isConnected {
            Task {
                do {
                    let networkResults = try await searchLessonsOnNetwork(query: query)
                    // Update cache with network results
                    try cacheManager.cacheLessons(networkResults)
                } catch {
                    OSLog.networking.error("Failed to search lessons online: \(error)")
                }
            }
        }
        
        return filteredLessons
    }
    
    // MARK: - Sync Methods
    
    /// Sync all pending operations
    private func syncPendingOperations() async {
        guard networkMonitor.isConnected else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let operations = try cacheManager.getPendingOperations()
            
            for operation in operations {
                do {
                    switch operation.type {
                    case .create:
                        if let payload = operation.payload,
                           let codableLesson = try? JSONDecoder().decode(CodableLesson.self, from: payload) {
                            let lesson = codableLesson.toLesson()
                            _ = try await createLessonOnNetwork(lesson)
                        }
                    case .update:
                        if let payload = operation.payload,
                           let codableLesson = try? JSONDecoder().decode(CodableLesson.self, from: payload) {
                            let lesson = codableLesson.toLesson()
                            _ = try await updateLessonOnNetwork(lesson)
                        }
                    case .delete:
                        try await deleteLessonOnNetwork(operation.entityId)
                    }
                    
                    // Remove successful operation
                    try cacheManager.removePendingOperation(operation)
                } catch {
                    // Increment retry count
                    operation.retryCount += 1
                    
                    // Remove operation if too many retries
                    if operation.retryCount > 3 {
                        try cacheManager.removePendingOperation(operation)
                        OSLog.networking.error("Removed pending operation after 3 retries: \(operation.id)")
                    }
                }
            }
            
            // Sync latest data
            let freshLessons = try await fetchLessonsFromNetwork()
            try cacheManager.cacheLessons(freshLessons)
            
        } catch {
            OSLog.networking.error("Failed to sync pending operations: \(error)")
            syncError = error
        }
    }
    
    // MARK: - Network Methods (Placeholder implementations)
    
    private func fetchLessonsFromNetwork() async throws -> [Lesson] {
        // TODO: Implement actual gRPC call
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
    
    private func fetchLessonFromNetwork(id: UUID) async throws -> Lesson {
        // TODO: Implement actual gRPC call
        throw AppError.lesson("Not implemented")
    }
    
    private func createLessonOnNetwork(_ lesson: Lesson) async throws -> Lesson {
        // TODO: Implement actual gRPC call
        return lesson
    }
    
    private func updateLessonOnNetwork(_ lesson: Lesson) async throws -> Lesson {
        // TODO: Implement actual gRPC call
        return lesson
    }
    
    private func deleteLessonOnNetwork(_ id: UUID) async throws {
        // TODO: Implement actual gRPC call
    }
    
    private func exportLessonToPDFOnNetwork(_ lesson: Lesson) async throws -> URL {
        // TODO: Implement actual gRPC call
        throw AppError.lesson("Not implemented")
    }
    
    private func searchLessonsOnNetwork(query: String) async throws -> [Lesson] {
        // TODO: Implement actual gRPC call
        return []
    }
} 