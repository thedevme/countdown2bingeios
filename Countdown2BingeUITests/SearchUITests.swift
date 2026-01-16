//
//  SearchUITests.swift
//  Countdown2BingeUITests
//
//  UI tests for Search page - ensures layout doesn't break on focus changes.
//

import XCTest

final class SearchUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITesting")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Search Page Layout Tests

    /// SCENARIO: Navigate to Search tab
    /// EXPECTED: Page header and search field should be visible and not cut off
    @MainActor
    func testSearchPage_initialLoad_shouldNotBeCutOff() throws {
        app.launch()

        let timeout: TimeInterval = 10

        // Navigate to Search tab
        let searchTab = app.tabBars.buttons["Search"]
        XCTAssertTrue(searchTab.waitForExistence(timeout: timeout),
                      "Search tab should exist")
        searchTab.tap()

        // Verify header is visible
        let header = app.staticTexts["SEARCH"]
        XCTAssertTrue(header.waitForExistence(timeout: timeout),
                      "SEARCH header should be visible")

        // Verify search field is visible and hittable (not cut off)
        let searchField = app.textFields["Search shows to binge"]
        XCTAssertTrue(searchField.waitForExistence(timeout: timeout),
                      "Search field should be visible")
        XCTAssertTrue(searchField.isHittable,
                      "Search field should be hittable (not cut off)")

        // Verify SEE ALL button is visible (tests right edge isn't cut off)
        let seeAllButton = app.buttons["SEE ALL"].firstMatch
        if seeAllButton.exists {
            XCTAssertTrue(seeAllButton.isHittable,
                          "SEE ALL button should be hittable (right edge not cut off)")
        }
    }

    /// SCENARIO: Focus on search field
    /// EXPECTED: Layout should remain intact, content should not grow or get cut off
    @MainActor
    func testSearchPage_onFocus_shouldNotGrowOrCutOff() throws {
        app.launch()

        let timeout: TimeInterval = 10

        // Navigate to Search tab
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()

        // Wait for page to load
        let header = app.staticTexts["SEARCH"]
        XCTAssertTrue(header.waitForExistence(timeout: timeout),
                      "SEARCH header should be visible")

        // Get search field and tap to focus
        let searchField = app.textFields["Search shows to binge"]
        XCTAssertTrue(searchField.waitForExistence(timeout: timeout),
                      "Search field should exist")

        // Record frame before focus
        let frameBefore = searchField.frame

        // Focus the search field
        searchField.tap()

        // Small delay for any animations
        Thread.sleep(forTimeInterval: 0.3)

        // Verify search field is still hittable after focus
        XCTAssertTrue(searchField.isHittable,
                      "Search field should still be hittable after focus")

        // Verify header is still visible (layout didn't shift badly)
        XCTAssertTrue(header.isHittable,
                      "Header should still be visible after focus")

        // Verify frame didn't grow significantly (allowing small animation tolerance)
        let frameAfter = searchField.frame
        let widthGrowth = frameAfter.width - frameBefore.width
        XCTAssertLessThan(widthGrowth, 50,
                          "Search field should not grow significantly on focus (grew by \(widthGrowth))")

        // Dismiss keyboard by tapping outside the text field
        header.tap()
    }

    /// SCENARIO: Search page with content loaded
    /// EXPECTED: Trending shows and category chips should be visible and not cut off
    @MainActor
    func testSearchPage_withContent_shouldShowAllElements() throws {
        app.launch()

        let timeout: TimeInterval = 10

        // Navigate to Search tab
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()

        // Wait for page to load
        let header = app.staticTexts["SEARCH"]
        XCTAssertTrue(header.waitForExistence(timeout: timeout),
                      "SEARCH header should be visible")

        // Verify category section is visible
        let browseByCategory = app.staticTexts["BROWSE BY CATEGORY"]
        XCTAssertTrue(browseByCategory.waitForExistence(timeout: timeout),
                      "BROWSE BY CATEGORY section should be visible")

        // Verify at least one category chip exists
        let categoryChips = app.buttons.matching(NSPredicate(format: "label CONTAINS 'category'"))
        XCTAssertGreaterThan(categoryChips.count, 0,
                             "At least one category chip should exist")

        // Tab bar should still be visible (content not pushed off screen)
        XCTAssertTrue(searchTab.isHittable,
                      "Tab bar should remain visible")
    }

    /// Diagnostic test to capture screenshots and frame info
    @MainActor
    func testSearchPage_diagnosticCapture() throws {
        app.launch()

        let timeout: TimeInterval = 10

        // Navigate to Search tab
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()

        // Wait for page to load
        let header = app.staticTexts["SEARCH"]
        XCTAssertTrue(header.waitForExistence(timeout: timeout))

        // Wait for content to load
        Thread.sleep(forTimeInterval: 3)

        // Screenshot
        let screenshot1 = XCUIScreen.main.screenshot()
        let attach1 = XCTAttachment(screenshot: screenshot1)
        attach1.name = "SearchPage"
        attach1.lifetime = .keepAlways
        add(attach1)

        // Print screen and element frames
        let screenBounds = app.windows.firstMatch.frame
        print("DIAGNOSTIC: Screen/Window bounds: \(screenBounds)")
        print("DIAGNOSTIC: Header frame: \(header.frame)")

        let searchField = app.textFields["Search shows to binge"]
        if searchField.exists {
            print("DIAGNOSTIC: Search field frame: \(searchField.frame)")
        }

        let browseLabel = app.staticTexts["BROWSE BY CATEGORY"]
        if browseLabel.exists {
            print("DIAGNOSTIC: BROWSE BY CATEGORY frame: \(browseLabel.frame)")
            print("DIAGNOSTIC: BROWSE BY CATEGORY isHittable: \(browseLabel.isHittable)")

            // Check left edge
            XCTAssertGreaterThanOrEqual(browseLabel.frame.minX, 0,
                "BROWSE BY CATEGORY left edge cut off: \(browseLabel.frame.minX)")
        }

        let trendingLabel = app.staticTexts["TRENDING SHOWS"]
        if trendingLabel.exists {
            print("DIAGNOSTIC: TRENDING SHOWS frame: \(trendingLabel.frame)")

            // Check left edge
            XCTAssertGreaterThanOrEqual(trendingLabel.frame.minX, 0,
                "TRENDING SHOWS left edge cut off: \(trendingLabel.frame.minX)")
        }

        let seeAllButton = app.buttons["SEE ALL"].firstMatch
        if seeAllButton.exists {
            print("DIAGNOSTIC: SEE ALL frame: \(seeAllButton.frame)")
            print("DIAGNOSTIC: SEE ALL isHittable: \(seeAllButton.isHittable)")

            // Check right edge
            XCTAssertLessThanOrEqual(seeAllButton.frame.maxX, screenBounds.width,
                "SEE ALL right edge cut off: \(seeAllButton.frame.maxX) > \(screenBounds.width)")
        }
    }
}
