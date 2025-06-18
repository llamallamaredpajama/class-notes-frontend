import Foundation
import OSLog
import SwiftUI
import GRPCCore

/// Updated LessonListViewModel using gRPC-Swift v2
@MainActor
final class LessonListViewModelV2: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var lessons: [Lesson] = []
    @Published private(set) var filteredLessons: [Lesson] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var nextPageToken: String?
    @Published private(set) var hasMorePages = true
    
    @Published var searchText = "" {
        didSet {
            Task {
                await performSearch()
            }
        }
    }
    
    @Published var sortOrder: SortOrder = .dateDescending {
        didSet {
            sortLessons()
        }
    }
    
    // MARK: - Types
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case titleAscending = "Title A-Z"
        case titleDescending = "Title Z-A"
        case durationAscending = "Shortest First"
        case durationDescending = "Longest First"
    }
    
    // MARK: - Private Properties
    
    private let classNotesService = ClassNotesService.shared
    private let logger = OSLog(subsystem: "com.classnotes", category: "LessonList")
    
    // MARK: - Initialization
    
    init() {
        logger.debug("LessonListViewModelV2 initialized")
    }
    
    // MARK: - Public Methods
    
    /// Load initial lessons
    func loadLessons() async {
        logger.info("Loading lessons...")
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let response = try await classNotesService.listClassNotes(
                pageSize: 20,
                pageToken: nil
            )
            
            self.lessons = response.classNotes.map { classNote in
                Lesson(from: classNote)
            }
            
            self.nextPageToken = response.nextPageToken.isEmpty ? nil : response.nextPageToken
            self.hasMorePages = !response.nextPageToken.isEmpty
            
            filterLessons()
            sortLessons()
            
            logger.info("Successfully loaded \(self.lessons.count) lessons")
        } catch {
            logger.error("Failed to load lessons: \(error)")
            self.error = ClassNotesError(from: error)
        }
    }
    
    /// Load more lessons (pagination)
    func loadMoreLessons() async {
        guard !isLoading, hasMorePages, let token = nextPageToken else { return }
        
        logger.info("Loading more lessons...")
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await classNotesService.listClassNotes(
                pageSize: 20,
                pageToken: token
            )
            
            let newLessons = response.classNotes.map { classNote in
                Lesson(from: classNote)
            }
            
            self.lessons.append(contentsOf: newLessons)
            self.nextPageToken = response.nextPageToken.isEmpty ? nil : response.nextPageToken
            self.hasMorePages = !response.nextPageToken.isEmpty
            
            filterLessons()
            sortLessons()
            
            logger.info("Loaded \(newLessons.count) more lessons")
        } catch {
            logger.error("Failed to load more lessons: \(error)")
            self.error = ClassNotesError(from: error)
        }
    }
    
    /// Refresh all lessons
    func refreshLessons() async {
        logger.debug("Refreshing lessons...")
        self.lessons = []
        self.nextPageToken = nil
        self.hasMorePages = true
        await loadLessons()
    }
    
    /// Delete a lesson
    func deleteLesson(_ lesson: Lesson) async {
        logger.info("Deleting lesson: \(lesson.id)")
        
        do {
            try await classNotesService.deleteClassNote(id: lesson.id)
            
            // Remove from local arrays
            lessons.removeAll { $0.id == lesson.id }
            filteredLessons.removeAll { $0.id == lesson.id }
            
            logger.info("Successfully deleted lesson: \(lesson.title)")
        } catch {
            logger.error("Failed to delete lesson: \(error)")
            self.error = ClassNotesError(from: error)
        }
    }
    
    /// Create a new lesson
    func createLesson(title: String) async -> Lesson? {
        logger.info("Creating lesson: \(title)")
        
        do {
            // Create a new class note
            let request = Classnotes_V1_CreateClassNoteRequest.with {
                $0.title = title
                $0.courseID = "" // Will be set by the backend if not provided
            }
            
            // Note: This assumes you have a createClassNote method in ClassNotesService
            // If not, you might need to implement it
            // let response = try await classNotesService.createClassNote(request)
            
            // For now, create a local lesson
            let newLesson = Lesson(
                id: UUID().uuidString,
                title: title,
                date: Date(),
                duration: 0,
                transcript: "",
                summary: nil,
                pdfURL: nil
            )
            
            // Add to local arrays
            lessons.insert(newLesson, at: 0)
            filterLessons()
            sortLessons()
            
            logger.info("Successfully created lesson: \(newLesson.title)")
            return newLesson
        } catch {
            logger.error("Failed to create lesson: \(error)")
            self.error = ClassNotesError(from: error)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Perform search with debouncing
    private func performSearch() async {
        if searchText.isEmpty {
            filterLessons()
            return
        }
        
        // Add a small delay for debouncing
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        // Check if search text hasn't changed
        guard !searchText.isEmpty else {
            filterLessons()
            return
        }
        
        logger.info("Searching for: \(searchText)")
        
        do {
            let response = try await classNotesService.searchClassNotes(
                query: searchText,
                pageSize: 20
            )
            
            self.filteredLessons = response.classNotes.map { classNote in
                Lesson(from: classNote)
            }
            
            sortLessons()
            logger.info("Search returned \(self.filteredLessons.count) results")
        } catch {
            logger.error("Search failed: \(error)")
            // Fall back to local filtering
            filterLessons()
        }
    }
    
    /// Filter lessons locally
    private func filterLessons() {
        if searchText.isEmpty {
            filteredLessons = lessons
        } else {
            filteredLessons = lessons.filter { lesson in
                lesson.title.localizedCaseInsensitiveContains(searchText) ||
                lesson.transcript.localizedCaseInsensitiveContains(searchText) ||
                (lesson.summary?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        logger.debug("Filtered lessons: \(filteredLessons.count) of \(lessons.count)")
    }
    
    /// Sort filtered lessons
    private func sortLessons() {
        switch sortOrder {
        case .dateDescending:
            filteredLessons.sort { $0.date > $1.date }
        case .dateAscending:
            filteredLessons.sort { $0.date < $1.date }
        case .titleAscending:
            filteredLessons.sort { $0.title < $1.title }
        case .titleDescending:
            filteredLessons.sort { $0.title > $1.title }
        case .durationAscending:
            filteredLessons.sort { $0.duration < $1.duration }
        case .durationDescending:
            filteredLessons.sort { $0.duration > $1.duration }
        }
        
        logger.debug("Sorted lessons by: \(sortOrder.rawValue)")
    }
}

// MARK: - Lesson Extension

extension Lesson {
    /// Initialize from protobuf class note
    init(from proto: Classnotes_V1_ClassNote) {
        self.init(
            id: proto.id,
            title: proto.title,
            date: proto.createdAt.date,
            duration: TimeInterval(proto.duration),
            transcript: proto.transcript,
            summary: proto.summary.isEmpty ? nil : proto.summary,
            pdfURL: proto.pdfURL.isEmpty ? nil : URL(string: proto.pdfURL)
        )
    }
}

// MARK: - Error Handling

enum ClassNotesError: LocalizedError {
    case unauthenticated
    case quotaExceeded
    case networkError(Error)
    case serverError(String)
    case unknown(Error)
    
    init(from error: Error) {
        if let rpcError = error as? RPCError {
            switch rpcError.code {
            case .unauthenticated:
                self = .unauthenticated
            case .resourceExhausted:
                self = .quotaExceeded
            default:
                self = .serverError(rpcError.message)
            }
        } else {
            self = .unknown(error)
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "Please sign in to continue"
        case .quotaExceeded:
            return "You've reached your usage limit. Please upgrade your subscription."
        case .networkError:
            return "Network error. Please check your connection."
        case .serverError(let message):
            return message
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Mock Implementation for Previews

#if DEBUG
class MockLessonListViewModelV2: LessonListViewModelV2 {
    override init() {
        super.init()
        
        // Pre-populate with mock data
        self.lessons = [
            Lesson(
                id: "1",
                title: "Introduction to SwiftUI",
                date: Date().addingTimeInterval(-86400),
                duration: 3600,
                transcript: "Today we'll learn about SwiftUI...",
                summary: "An introduction to SwiftUI framework",
                pdfURL: nil
            ),
            Lesson(
                id: "2",
                title: "Advanced Swift Concurrency",
                date: Date().addingTimeInterval(-172800),
                duration: 5400,
                transcript: "Swift concurrency with async/await...",
                summary: "Deep dive into Swift's concurrency model",
                pdfURL: nil
            )
        ]
        
        self.filteredLessons = self.lessons
    }
}
#endif 