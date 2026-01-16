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

    // MARK: - Connector Visibility Tests

    /// SCENARIO: Airing show exists but no premiering soon or anticipated shows
    /// EXPECTED: Dashed connector line below countdown should be hidden
    @MainActor
    func testAiringOnlyNoBottomSections_connectorShouldBeHidden() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "AiringOnlyNoBottomSections"])
        app.launch()

        let timeout: TimeInterval = 10

        // The airing show should appear in hero section
        let showName = app.staticTexts["Airing Only Show"]
        XCTAssertTrue(showName.waitForExistence(timeout: timeout),
                      "Airing show should appear in hero section")

        // Section connector should NOT exist (no bottom sections to connect to)
        let connector = app.otherElements["SectionConnector"]
        XCTAssertFalse(connector.exists,
                       "Dashed connector should be hidden when no bottom sections exist")

        // Section headers should also NOT be visible
        let premieringHeader = app.staticTexts["PREMIERING SOON"]
        let anticipatedHeader = app.staticTexts["ANTICIPATED"]
        XCTAssertFalse(premieringHeader.exists,
                       "PREMIERING SOON should not appear when no shows in that category")
        XCTAssertFalse(anticipatedHeader.exists,
                       "ANTICIPATED should not appear when no shows in that category")
    }

    /// SCENARIO: Active shows exist in bottom sections
    /// EXPECTED: Dashed connector line should be visible
    @MainActor
    func testHasActiveShows_connectorShouldBeVisible() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "HasActiveShows"])
        app.launch()

        let timeout: TimeInterval = 10

        // Wait for app to load
        let showName = app.staticTexts["Currently Airing"]
        XCTAssertTrue(showName.waitForExistence(timeout: timeout),
                      "Currently Airing show should appear")

        // Section connector SHOULD exist (there are bottom sections)
        let connector = app.otherElements["SectionConnector"]
        XCTAssertTrue(connector.waitForExistence(timeout: timeout),
                      "Dashed connector should be visible when bottom sections exist")
    }

    // MARK: - TBD Countdown Tests (The Rookie Bug Prevention)

    /// SCENARIO: Airing show with no confirmed finale date (SVU case)
    /// EXPECTED: "TBD" should display in the countdown, NOT an empty box
    @MainActor
    func testAiringNoFinaleDate_shouldShowTBD() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "AiringNoFinaleDate"])
        app.launch()

        let timeout: TimeInterval = 10

        // The test show should appear in hero section
        let showName = app.staticTexts["The Rookie Test"]
        XCTAssertTrue(showName.waitForExistence(timeout: timeout),
                      "The Rookie Test show should appear in hero section")

        // The countdown should show "TBD" text (not empty)
        let tbdText = app.staticTexts["TBD"]
        XCTAssertTrue(tbdText.waitForExistence(timeout: timeout),
                      "TBD should be displayed when finale date is unknown")

        // VoiceOver accessibility should describe it as TBD
        let accessibilityLabel = app.otherElements.matching(
            NSPredicate(format: "label CONTAINS[c] 'to be determined'")
        ).firstMatch
        XCTAssertTrue(accessibilityLabel.exists || tbdText.exists,
                      "Countdown should either show TBD text or have TBD accessibility label")
    }

    /// SCENARIO: Finale episode is marked but has nil air date
    /// EXPECTED: "TBD" should display (finale exists but date unknown)
    @MainActor
    func testFinaleTypeButNoAirDate_shouldShowTBD() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "FinaleTypeButNoAirDate"])
        app.launch()

        let timeout: TimeInterval = 10

        // The test show should appear in hero section
        let showName = app.staticTexts["Finale No Date Test"]
        XCTAssertTrue(showName.waitForExistence(timeout: timeout),
                      "Finale No Date Test show should appear in hero section")

        // The countdown should show "TBD" text
        let tbdText = app.staticTexts["TBD"]
        XCTAssertTrue(tbdText.waitForExistence(timeout: timeout),
                      "TBD should be displayed when finale has no air date")
    }

    /// SCENARIO: Season exists but episodes array is empty (data not loaded)
    /// EXPECTED: Should handle gracefully - either TBD or not show in airing
    @MainActor
    func testEmptyEpisodesArray_shouldNotCrash() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "EmptyEpisodesArray"])
        app.launch()

        let timeout: TimeInterval = 10

        // App should launch without crashing
        // Either the show appears with TBD or it doesn't appear in airing section
        let showName = app.staticTexts["Empty Episodes Test"]
        let tbdText = app.staticTexts["TBD"]
        let nothingText = app.staticTexts["Nothing on the Timeline"]

        // Wait for something to appear
        _ = showName.waitForExistence(timeout: timeout)

        // One of these should be true - show with TBD, or empty timeline
        let showsWithTBD = showName.exists && tbdText.exists
        let emptyTimeline = nothingText.exists
        let showNotInAiring = !showName.exists

        XCTAssertTrue(showsWithTBD || emptyTimeline || showNotInAiring,
                      "App should handle empty episodes gracefully without crashing")
    }

    /// SCENARIO: Finale is TODAY (0 days countdown)
    /// EXPECTED: Should show "00" in countdown
    @MainActor
    func testFinaleIsToday_shouldShowZero() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "FinaleIsToday"])
        app.launch()

        let timeout: TimeInterval = 10

        // The test show should appear
        let showName = app.staticTexts["Finale Today Test"]
        XCTAssertTrue(showName.waitForExistence(timeout: timeout),
                      "Finale Today Test show should appear")

        // Should show "00" for today
        let zeroText = app.staticTexts["00"]
        XCTAssertTrue(zeroText.waitForExistence(timeout: timeout),
                      "Should show 00 when finale is today")
    }

    /// SCENARIO: Finale was in the past (negative days)
    /// EXPECTED: Should show TBD or handle gracefully (not negative number)
    @MainActor
    func testFinaleInPast_shouldNotShowNegative() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "FinaleInPast"])
        app.launch()

        let timeout: TimeInterval = 10

        // Wait for app to load
        _ = app.staticTexts["Finale Past Test"].waitForExistence(timeout: timeout)

        // Should NOT show negative numbers - either TBD or not in airing
        // Check that no negative sign appears in countdown area
        let negativeText = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '-'")).firstMatch
        XCTAssertFalse(negativeText.exists,
                       "Should not display negative countdown values")
    }

    /// SCENARIO: Finale is 150+ days away (exceeds 99)
    /// EXPECTED: Should show TBD (can't display 3 digits)
    @MainActor
    func testFinaleOver99Days_shouldShowTBD() throws {
        app.launchArguments.append(contentsOf: ["-UITestScenario", "FinaleOver99Days"])
        app.launch()

        let timeout: TimeInterval = 10

        // The test show should appear
        let showName = app.staticTexts["Finale Far Future Test"]
        XCTAssertTrue(showName.waitForExistence(timeout: timeout),
                      "Finale Far Future Test show should appear")

        // Should show TBD since we can't display 150
        let tbdText = app.staticTexts["TBD"]
        XCTAssertTrue(tbdText.waitForExistence(timeout: timeout),
                      "Should show TBD when finale is > 99 days away")
    }
}
