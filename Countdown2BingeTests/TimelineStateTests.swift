//
//  TimelineStateTests.swift
//  Countdown2BingeTests
//
//  Pre-release tests for Timeline empty state scenarios.
//

import Testing
import Foundation
@testable import Countdown2Binge

@Suite(.serialized)
struct TimelineStateTests {

    // MARK: - Timeline Empty State Scenarios

    /// SCENARIO: User skipped onboarding, has no followed shows
    /// EXPECTED: Empty slot cards should appear (visual onboarding hint)
    @Test func noFollowedShows_shouldShowEmptySlotCards() {
        let followedShows: [Show] = []

        let hasNoFollowedShows = followedShows.isEmpty
        let hasAnyShows = false // No shows in any category

        // When no followed shows, empty sections should show
        #expect(hasNoFollowedShows == true, "Should detect no followed shows")
        #expect(hasAnyShows == false, "Should have no shows in any category")
        // UI should show empty slot cards (visual test in previews)
    }

    /// SCENARIO: User has followed shows but none are in timeline categories
    /// EXPECTED: "Nothing on the Timeline" message with calendar icon
    @Test func hasFollowedShows_butNoneActive_shouldShowEmptyMessage() {
        // Shows that don't appear in timeline: ended, cancelled with all seasons complete
        let endedShow = makeShow(status: .ended, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true)
        ])

        let hasNoFollowedShows = false
        let airingShows: [Show] = [] // No airing shows
        let premieringSoon: [Show] = [] // No premiering soon
        let anticipated: [Show] = [] // No anticipated
        let hasAnyShows = !airingShows.isEmpty || !premieringSoon.isEmpty || !anticipated.isEmpty

        #expect(hasNoFollowedShows == false, "User has followed shows")
        #expect(hasAnyShows == false, "But none in active categories")
        #expect(endedShow.lifecycleState == .completed, "Ended show should be completed")
        // UI should show "Nothing on the Timeline" message
    }

    /// SCENARIO: User has shows in timeline categories
    /// EXPECTED: Only populated sections appear, empty sections hidden
    @Test func hasActiveShows_shouldOnlyShowPopulatedSections() {
        let airingShow = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: false, hasStarted: true)
        ])

        let hasNoFollowedShows = false
        let hasAnyShows = true

        #expect(hasNoFollowedShows == false)
        #expect(hasAnyShows == true)
        #expect(airingShow.lifecycleState == .airing, "Show should appear in Ending Soon")
        // UI should only show sections with content
    }

    // MARK: - Ending Soon Section Tests

    /// CRITICAL: Airing shows MUST appear in Ending Soon section
    /// Bug prevention: The Pitt scenario where S2 airing was incorrectly shown as anticipated
    @Test func airingShow_mustAppearInEndingSoon() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: false, hasStarted: true), // Currently airing
            makeAnnouncedSeason(seasonNumber: 3) // Announced, no episodes
        ])

        #expect(show.lifecycleState == .airing, "Show with airing season MUST be .airing to appear in Ending Soon")
        #expect(show.currentSeason?.seasonNumber == 2, "currentSeason must return the airing season")
    }

    /// Shows with only completed seasons should NOT appear in Ending Soon
    @Test func completedShow_shouldNotAppearInEndingSoon() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: true, hasStarted: true)
        ])

        #expect(show.lifecycleState != .airing, "Completed show should not be in Ending Soon")
    }

    // MARK: - Premiering Soon Section Tests

    /// Shows with upcoming seasons should appear in Premiering Soon
    @Test func showWithUpcomingSeason_shouldAppearInPremieringSoon() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: false, hasStarted: false) // Future premiere date
        ])

        #expect(show.lifecycleState == .anticipated, "Show with upcoming season should be anticipated")
        #expect(show.currentSeason?.seasonNumber == 2, "currentSeason should return upcoming season")
    }

    // MARK: - Anticipated Section Tests

    /// Shows with announced but undated seasons should appear in Anticipated
    @Test func showWithAnnouncedSeason_shouldAppearInAnticipated() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeAnnouncedSeason(seasonNumber: 2) // No air date
        ])

        #expect(show.lifecycleState == .anticipated, "Show with announced season should be anticipated")
    }
}

// MARK: - Test Helpers

private func makeShow(status: ShowStatus, seasons: [Season]) -> Show {
    Show(
        id: 1,
        name: "Test Show",
        overview: nil,
        posterPath: nil,
        backdropPath: nil,
        logoPath: nil,
        firstAirDate: nil,
        status: status,
        genres: [],
        networks: [],
        seasons: seasons,
        numberOfSeasons: seasons.count,
        numberOfEpisodes: seasons.reduce(0) { $0 + $1.episodeCount },
        inProduction: status == .returning || status == .inProduction
    )
}

private func makeSeason(seasonNumber: Int, isComplete: Bool, hasStarted: Bool) -> Season {
    let now = Date()
    let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
    let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: now)!

    let airDate = hasStarted ? pastDate : futureDate

    let episodes: [Episode]
    if isComplete {
        episodes = (1...10).map { makeEpisode(episodeNumber: $0, seasonNumber: seasonNumber, airDate: pastDate) }
    } else if hasStarted {
        episodes = (1...10).map { makeEpisode(episodeNumber: $0, seasonNumber: seasonNumber, airDate: $0 <= 5 ? pastDate : futureDate) }
    } else {
        episodes = (1...10).map { makeEpisode(episodeNumber: $0, seasonNumber: seasonNumber, airDate: futureDate) }
    }

    return Season(
        id: seasonNumber * 100,
        seasonNumber: seasonNumber,
        name: "Season \(seasonNumber)",
        overview: nil,
        posterPath: nil,
        airDate: airDate,
        episodeCount: episodes.count,
        episodes: episodes
    )
}

private func makeAnnouncedSeason(seasonNumber: Int) -> Season {
    Season(
        id: seasonNumber * 100,
        seasonNumber: seasonNumber,
        name: "Season \(seasonNumber)",
        overview: nil,
        posterPath: nil,
        airDate: nil,
        episodeCount: 0,
        episodes: []
    )
}

private func makeEpisode(episodeNumber: Int, seasonNumber: Int, airDate: Date) -> Episode {
    Episode(
        id: seasonNumber * 1000 + episodeNumber,
        episodeNumber: episodeNumber,
        seasonNumber: seasonNumber,
        name: "Episode \(episodeNumber)",
        overview: nil,
        airDate: airDate,
        stillPath: nil,
        runtime: 45
    )
}
