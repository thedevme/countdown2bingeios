//
//  TimelineUITests.swift
//  Countdown2BingeUITests
//
//  UI tests for timeline scenarios - part of store release verification.
//

import XCTest

final class TimelineUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITesting")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Timeline Empty State Tests

    /// SCENARIO: User skipped onboarding, has no followed shows
    /// EXPECTED: Empty slot cards should appear with section headers
    @MainActor
    func testNoFollowedShows_shouldShowEmptySlotCards() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "NoFollowedShows"])
        app.launch()

        let timeout: TimeInterval = 10

        // Look for the "PREMIERING SOON" header text which indicates the section is showing
        let premieringHeader = app.staticTexts["PREMIERING SOON"]
        XCTAssertTrue(premieringHeader.waitForExistence(timeout: timeout),
                      "PREMIERING SOON header should be visible for empty onboarding state")

        // Look for "ANTICIPATED" header
        let anticipatedHeader = app.staticTexts["ANTICIPATED"]
        XCTAssertTrue(anticipatedHeader.waitForExistence(timeout: timeout),
                      "ANTICIPATED header should be visible for empty onboarding state")

        // Should NOT show the "Nothing on the Timeline" message
        let nothingOnTimeline = app.staticTexts["Nothing on the Timeline"]
        XCTAssertFalse(nothingOnTimeline.exists,
                       "Should NOT show 'Nothing on Timeline' when in empty onboarding state")
    }

    /// SCENARIO: User has followed shows but none are in timeline categories
    /// EXPECTED: "Nothing on the Timeline" message with calendar icon
    @MainActor
    func testHasFollowedShows_butNoneActive_shouldShowEmptyMessage() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "HasShowsButNoneActive"])
        app.launch()

        let timeout: TimeInterval = 10

        // Should show "Nothing on the Timeline" text
        let nothingText = app.staticTexts["Nothing on the Timeline"]
        XCTAssertTrue(nothingText.waitForExistence(timeout: timeout),
                      "Should show 'Nothing on the Timeline' message when user has shows but none in active categories")

        // The explanatory text should also be visible
        let explanatoryText = app.staticTexts["Your followed shows aren't currently\nairing or premiering soon"]
        XCTAssertTrue(explanatoryText.exists || app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'followed shows'")).count > 0,
                      "Should show explanatory text about followed shows")

        // Section headers should NOT be visible (sections are hidden)
        let premieringHeader = app.staticTexts["PREMIERING SOON"]
        let anticipatedHeader = app.staticTexts["ANTICIPATED"]

        XCTAssertFalse(premieringHeader.exists,
                       "PREMIERING SOON section should be hidden when no content")
        XCTAssertFalse(anticipatedHeader.exists,
                       "ANTICIPATED section should be hidden when no content")
    }

    /// SCENARIO: User has shows in timeline categories
    /// EXPECTED: Hero card stack with airing shows, no empty message
    @MainActor
    func testHasActiveShows_shouldShowHeroSection() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "HasActiveShows"])
        app.launch()

        let timeout: TimeInterval = 10

        // Look for the "Currently Airing" show name in the hero section
        let showName = app.staticTexts["Currently Airing"]
        XCTAssertTrue(showName.waitForExistence(timeout: timeout),
                      "Currently Airing show should appear in hero section")

        // Should NOT show "Nothing on the Timeline"
        let nothingText = app.staticTexts["Nothing on the Timeline"]
        XCTAssertFalse(nothingText.exists,
                       "Should NOT show 'Nothing on Timeline' when there are active shows")
    }

    // MARK: - The Pitt Bug Prevention Test

    /// CRITICAL: The Pitt scenario - S1 complete, S2 airing, S3 announced
    /// EXPECTED: Show should appear in hero section (Ending Soon), NOT be missing
    @MainActor
    func testThePittScenario_showAppearsInEndingSoon() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "ThePittScenario"])
        app.launch()

        let timeout: TimeInterval = 10

        // The Pitt should appear in the hero section (it's an airing show)
        let showName = app.staticTexts["The Pitt"]
        XCTAssertTrue(showName.waitForExistence(timeout: timeout),
                      "The Pitt (with S2 airing) MUST appear in hero section (Ending Soon)")

        // Should NOT show "Nothing on the Timeline" (that would mean the show is incorrectly categorized)
        let nothingText = app.staticTexts["Nothing on the Timeline"]
        XCTAssertFalse(nothingText.exists,
                       "The Pitt should NOT be hidden - it must appear in Ending Soon")
    }
}
