// 1. Standard library
import Foundation

// 2. Apple frameworks
import XCTest

/// UI tests for lesson creation and management flows
class LessonFlowUITests: XCTestCase {
    // MARK: - Properties
    
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing", "Authenticated"] // Skip auth for these tests
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Test Lessons List
    
    func testLessonsListScreen() throws {
        // Given - User is on lessons tab
        let lessonsTab = app.tabBars.buttons["Lessons"]
        lessonsTab.tap()
        
        // Then - Verify navigation title
        XCTAssertTrue(app.navigationBars["Lessons"].exists)
        
        // Verify add button exists
        let addButton = app.navigationBars["Lessons"].buttons["plus"]
        XCTAssertTrue(addButton.exists)
        XCTAssertTrue(addButton.isEnabled)
        
        // Verify search field
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists)
    }
    
    func testEmptyLessonsState() throws {
        // Given - No lessons exist (would need mock data)
        let lessonsTab = app.tabBars.buttons["Lessons"]
        lessonsTab.tap()
        
        // Then - Check for empty state elements
        if app.staticTexts["No Lessons Yet"].exists {
            XCTAssertTrue(app.staticTexts["Start by creating your first lesson"].exists)
            XCTAssertTrue(app.buttons["Create Lesson"].exists)
        }
    }
    
    func testLessonSearch() throws {
        // Given - User is on lessons list with existing lessons
        let lessonsTab = app.tabBars.buttons["Lessons"]
        lessonsTab.tap()
        
        let searchField = app.searchFields.firstMatch
        guard searchField.exists else {
            XCTFail("Search field not found")
            return
        }
        
        // When - User searches
        searchField.tap()
        searchField.typeText("Math")
        
        // Then - Results should filter (requires test data)
        // This is a placeholder - actual test would verify filtered results
    }
    
    // MARK: - Test Lesson Creation
    
    func testCreateNewLesson() throws {
        // Given - User is on lessons list
        let lessonsTab = app.tabBars.buttons["Lessons"]
        lessonsTab.tap()
        
        // When - User taps add button
        let addButton = app.navigationBars["Lessons"].buttons["plus"]
        addButton.tap()
        
        // Then - Add lesson sheet should appear
        // This is a placeholder - actual implementation would show create view
        XCTAssertTrue(app.staticTexts["Add Lesson View"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Test Lesson Detail
    
    func testNavigateToLessonDetail() throws {
        // Given - User has lessons in list
        let lessonsTab = app.tabBars.buttons["Lessons"]
        lessonsTab.tap()
        
        // When - User taps on a lesson
        let firstLesson = app.cells.firstMatch
        if firstLesson.exists {
            firstLesson.tap()
            
            // Then - Lesson detail should appear
            XCTAssertTrue(app.navigationBars["Lesson Detail"].waitForExistence(timeout: 2))
        }
    }
    
    func testLessonDetailElements() throws {
        // Navigate to lesson detail
        navigateToFirstLesson()
        
        // Verify key elements exist
        XCTAssertTrue(app.textFields.firstMatch.exists, "Title field should exist")
        XCTAssertTrue(app.textViews.firstMatch.exists, "Transcript text view should exist")
        XCTAssertTrue(app.buttons["Start Recording"].exists || app.buttons["stop.fill"].exists)
    }
    
    func testStartRecording() throws {
        // Navigate to lesson detail
        navigateToFirstLesson()
        
        // Given
        let recordButton = app.buttons["Start Recording"]
        
        if recordButton.exists {
            // When
            recordButton.tap()
            
            // Then - Recording UI should appear
            let stopButton = app.buttons.containing(.image, identifier: "stop.fill").firstMatch
            XCTAssertTrue(stopButton.waitForExistence(timeout: 2), "Stop button should appear")
        }
    }
    
    func testEditLessonTitle() throws {
        // Navigate to lesson detail
        navigateToFirstLesson()
        
        // Given
        let titleField = app.textFields.firstMatch
        guard titleField.exists else {
            XCTFail("Title field not found")
            return
        }
        
        // When
        titleField.tap()
        titleField.clearText()
        titleField.typeText("Updated Lesson Title")
        
        // Then - Save button should be enabled
        let saveButton = app.buttons["Save Changes"]
        if saveButton.exists {
            XCTAssertTrue(saveButton.isEnabled)
        }
    }
    
    // MARK: - Test Lesson Actions
    
    func testFavoriteLesson() throws {
        // Navigate to lesson detail
        navigateToFirstLesson()
        
        // Given
        let moreButton = app.navigationBars.buttons["ellipsis.circle"]
        guard moreButton.exists else {
            XCTFail("More button not found")
            return
        }
        
        // When
        moreButton.tap()
        
        // Then
        let favoriteButton = app.buttons["Add to Favorites"]
        let unfavoriteButton = app.buttons["Remove from Favorites"]
        
        XCTAssertTrue(favoriteButton.exists || unfavoriteButton.exists)
    }
    
    func testShareLesson() throws {
        // Navigate to lesson detail
        navigateToFirstLesson()
        
        // Given
        let moreButton = app.navigationBars.buttons["ellipsis.circle"]
        moreButton.tap()
        
        // When
        let shareButton = app.buttons["Share"]
        if shareButton.exists {
            shareButton.tap()
            
            // Then - Share sheet should appear
            // Note: Share sheet is system UI, limited testing capability
        }
    }
    
    func testDeleteLesson() throws {
        // Navigate to lesson list
        let lessonsTab = app.tabBars.buttons["Lessons"]
        lessonsTab.tap()
        
        // Given - A lesson exists
        let cell = app.cells.firstMatch
        guard cell.exists else { return }
        
        // When - Swipe to delete
        cell.swipeLeft()
        
        // Then - Delete button should appear
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.exists)
    }
    
    // MARK: - Test Drawing Features
    
    func testNavigateToDrawings() throws {
        // Navigate to lesson detail
        navigateToFirstLesson()
        
        // Scroll to drawings section
        app.swipeUp()
        
        // Check for drawing elements
        if app.staticTexts["Drawings"].exists {
            // Check for create drawing button
            let createButton = app.buttons["Create Drawing"]
            if createButton.exists {
                createButton.tap()
                
                // Verify drawing editor appears
                XCTAssertTrue(app.navigationBars["New Drawing"].waitForExistence(timeout: 2))
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testLessonListScrollPerformance() throws {
        let lessonsTab = app.tabBars.buttons["Lessons"]
        lessonsTab.tap()
        
        measure {
            // Scroll down
            app.swipeUp()
            app.swipeUp()
            
            // Scroll back up
            app.swipeDown()
            app.swipeDown()
        }
    }
    
    func testLessonDetailLoadPerformance() throws {
        let lessonsTab = app.tabBars.buttons["Lessons"]
        lessonsTab.tap()
        
        measure {
            let firstLesson = app.cells.firstMatch
            if firstLesson.exists {
                firstLesson.tap()
                _ = app.navigationBars["Lesson Detail"].waitForExistence(timeout: 2)
                app.navigationBars.buttons.firstMatch.tap() // Back button
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToFirstLesson() {
        let lessonsTab = app.tabBars.buttons["Lessons"]
        lessonsTab.tap()
        
        let firstLesson = app.cells.firstMatch
        if firstLesson.exists {
            firstLesson.tap()
            _ = app.navigationBars["Lesson Detail"].waitForExistence(timeout: 2)
        }
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else { return }
        
        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
} 