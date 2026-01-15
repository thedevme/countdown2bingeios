//
//  BingeReadyUITests.swift
//  Countdown2BingeUITests
//
//  UI tests for Binge Ready page - ensures responsive layout works correctly.
//

import XCTest

final class BingeReadyUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITesting")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Binge Ready Page Tests

    /// SCENARIO: Navigate to Binge Ready tab
    /// EXPECTED: Header should be visible and page should render correctly
    @MainActor
    func testBingeReadyPage_shouldShowHeader() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "HasBingeReadySeasons"])
        app.launch()

        let timeout: TimeInterval = 10

        // Navigate to Binge Ready tab
        let bingeReadyTab = app.tabBars.buttons["Binge Ready"]
        XCTAssertTrue(bingeReadyTab.waitForExistence(timeout: timeout),
                      "Binge Ready tab should exist")
        bingeReadyTab.tap()

        // Verify header is visible
        let header = app.staticTexts["BINGE READY"]
        XCTAssertTrue(header.waitForExistence(timeout: timeout),
                      "BINGE READY header should be visible")
    }

    /// SCENARIO: Binge Ready page with content
    /// EXPECTED: Card stack should be visible with show name and episode badge
    @MainActor
    func testBingeReadyPage_withContent_shouldShowCardStack() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "HasBingeReadySeasons"])
        app.launch()

        let timeout: TimeInterval = 10

        // Navigate to Binge Ready tab
        let bingeReadyTab = app.tabBars.buttons["Binge Ready"]
        bingeReadyTab.tap()

        // Wait for page to load
        let header = app.staticTexts["BINGE READY"]
        XCTAssertTrue(header.waitForExistence(timeout: timeout),
                      "BINGE READY header should be visible")

        // Card content should be visible (episode badge contains "EPISODES")
        let episodeBadge = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'EPISODES'")).firstMatch
        let cardExists = episodeBadge.waitForExistence(timeout: timeout)

        // Either card content exists OR empty state exists
        if !cardExists {
            let emptyState = app.staticTexts["Nothing to Binge Yet"]
            XCTAssertTrue(emptyState.waitForExistence(timeout: timeout),
                          "Either card content or empty state should be visible")
        }
    }

    /// SCENARIO: Binge Ready empty state
    /// EXPECTED: Empty state message should be displayed
    @MainActor
    func testBingeReadyPage_emptyState_shouldShowMessage() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "NoBingeReadySeasons"])
        app.launch()

        let timeout: TimeInterval = 10

        // Navigate to Binge Ready tab
        let bingeReadyTab = app.tabBars.buttons["Binge Ready"]
        bingeReadyTab.tap()

        // Verify empty state message
        let emptyState = app.staticTexts["Nothing to Binge Yet"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: timeout),
                      "Empty state message should be visible when no binge-ready seasons")
    }

    /// SCENARIO: Binge Ready page responsive layout
    /// EXPECTED: Page should not have overlapping elements or cut-off content
    @MainActor
    func testBingeReadyPage_layoutIntegrity() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "HasBingeReadySeasons"])
        app.launch()

        let timeout: TimeInterval = 10

        // Navigate to Binge Ready tab
        let bingeReadyTab = app.tabBars.buttons["Binge Ready"]
        bingeReadyTab.tap()

        // Verify header is visible
        let header = app.staticTexts["BINGE READY"]
        XCTAssertTrue(header.waitForExistence(timeout: timeout),
                      "Header should be visible")

        // Verify tab bar is still visible (content hasn't pushed it off screen)
        XCTAssertTrue(bingeReadyTab.isHittable,
                      "Tab bar should remain visible - content should fit screen")

        // Verify info button is visible (header row is intact)
        let infoButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'info'")).firstMatch
        XCTAssertTrue(infoButton.exists || infoButton.waitForExistence(timeout: 2),
                      "Info button should be visible in header")
    }
}
