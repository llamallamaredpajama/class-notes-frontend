//
//  LessonListViewModel.swift
//  class-notes-frontend
//
//  ViewModel for managing the lesson list
//

import Foundation
import OSLog
import SwiftUI

@MainActor
class LessonListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var lessons: [Lesson] = []
    @Published private(set) var filteredLessons: [Lesson] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var searchText = "" {
        didSet {
            filterLessons()
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
    private let lessonService: LessonServiceProtocol
    private let logger = Logger.lessons
    
    // MARK: - Initialization
    init(lessonService: LessonServiceProtocol) {
        self.lessonService = lessonService
        logger.debug("LessonListViewModel initialized")
    }
    
    // MARK: - Public Methods
    func loadLessons() async {
        logger.functionEntry("loadLessons")
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            logger.debug("Fetching lessons from service...")
            let fetchedLessons = try await lessonService.fetchLessons()
            self.lessons = fetchedLessons
            logger.info("Successfully loaded \(self.lessons.count) lessons")
            
            filterLessons()
            sortLessons()
            
            logger.functionExit("loadLessons", result: "count: \(self.lessons.count)")
        } catch {
            logger.error("Failed to load lessons: \(error)")
            self.error = error
        }
    }
    
    func refreshLessons() async {
        logger.debug("Refreshing lessons...")
        await loadLessons()
    }
    
    func deleteLesson(_ lesson: Lesson) async {
        logger.functionEntry("deleteLesson", parameters: "id: \(lesson.id)")
        
        do {
            try await lessonService.deleteLesson(lesson.id)
            
            // Remove from local arrays
            lessons.removeAll { $0.id == lesson.id }
            filteredLessons.removeAll { $0.id == lesson.id }
            
            logger.info("Successfully deleted lesson: \(lesson.title)")
        } catch {
            logger.error("Failed to delete lesson: \(error)")
            self.error = error
        }
    }
    
    func createLesson(title: String) async -> Lesson? {
        logger.functionEntry("createLesson", parameters: "title: \(title)")
        
        do {
            let newLesson = Lesson(
                title: title,
                date: Date(),
                duration: 0,
                transcript: ""
            )
            
            let createdLesson = try await lessonService.createLesson(newLesson)
            
            // Add to local arrays
            lessons.append(createdLesson)
            filterLessons()
            sortLessons()
            
            logger.info("Successfully created lesson: \(createdLesson.title)")
            return createdLesson
        } catch {
            logger.error("Failed to create lesson: \(error)")
            self.error = error
            return nil
        }
    }
    
    // MARK: - Private Methods
    private func filterLessons() {
        if searchText.isEmpty {
            filteredLessons = lessons
        } else {
            filteredLessons = lessons.filter { lesson in
                lesson.title.localizedCaseInsensitiveContains(self.searchText) ||
                lesson.transcript.localizedCaseInsensitiveContains(self.searchText)
            }
        }
        
        logger.debug("Filtered lessons: \(self.filteredLessons.count) of \(self.lessons.count)")
    }
    
    private func sortLessons() {
        switch self.sortOrder {
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
        
        logger.debug("Sorted lessons by: \(self.sortOrder.rawValue)")
    }
}

// MARK: - Mock Implementation for Previews
#if DEBUG
class MockLessonListViewModel: LessonListViewModel {
    init() {
        super.init(lessonService: MockLessonService())
        
        // Pre-populate with mock data
        Task {
            await loadLessons()
        }
    }
}
#endif 