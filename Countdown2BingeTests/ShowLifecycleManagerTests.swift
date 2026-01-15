//
//  ShowLifecycleManagerTests.swift
//  Countdown2BingeTests
//

import Testing
import Foundation
@testable import Countdown2Binge

@Suite(.serialized)
struct ShowLifecycleManagerTests {
    let manager = ShowLifecycleManager()

    // MARK: - Cancelled Shows

    @Test func cancelledShow_returnsCancel() {
        let show = makeShow(status: .cancelled, seasons: [
            makeSeason(seasonNumber: 1, isComplete: false, hasStarted: true)
        ])

        let state = manager.deriveState(for: show)

        #expect(state == .cancelled)
    }

    @Test func cancelledShow_withCompleteSeason_stillReturnsCancelled() {
        let show = makeShow(status: .cancelled, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true)
        ])

        let state = manager.deriveState(for: show)

        #expect(state == .cancelled)
    }

    // MARK: - Ended Shows

    @Test func endedShow_returnsCompleted() {
        let show = makeShow(status: .ended, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true)
        ])

        let state = manager.deriveState(for: show)

        #expect(state == .completed)
    }

    // MARK: - Airing Shows

    @Test func airingShow_withIncompleteSeason_returnsAiring() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: false, hasStarted: true)
        ])

        let state = manager.deriveState(for: show)

        #expect(state == .airing)
    }

    @Test func airingShow_withCompleteSeason_returnsCompleted() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true)
        ])

        let state = manager.deriveState(for: show)

        #expect(state == .completed)
    }

    // MARK: - Anticipated Shows

    @Test func show_withNoSeasons_returnsAnticipated() {
        let show = makeShow(status: .returning, seasons: [])

        let state = manager.deriveState(for: show)

        #expect(state == .anticipated)
    }

    @Test func show_withUnstartedSeason_returnsAnticipated() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: false, hasStarted: false)
        ])

        let state = manager.deriveState(for: show)

        #expect(state == .anticipated)
    }

    @Test func plannedShow_returnsAnticipated() {
        let show = makeShow(status: .planned, seasons: [])

        let state = manager.deriveState(for: show)

        #expect(state == .anticipated)
    }

    // MARK: - Per-Season State

    @Test func seasonState_unstarted_returnsAnticipated() {
        let show = makeShow(status: .returning, seasons: [])
        let season = makeSeason(seasonNumber: 1, isComplete: false, hasStarted: false)

        let state = manager.deriveState(for: show, season: season)

        #expect(state == .anticipated)
    }

    @Test func seasonState_airing_returnsAiring() {
        let show = makeShow(status: .returning, seasons: [])
        let season = makeSeason(seasonNumber: 1, isComplete: false, hasStarted: true)

        let state = manager.deriveState(for: show, season: season)

        #expect(state == .airing)
    }

    @Test func seasonState_complete_returnsCompleted() {
        let show = makeShow(status: .returning, seasons: [])
        let season = makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true)

        let state = manager.deriveState(for: show, season: season)

        #expect(state == .completed)
    }

    @Test func seasonState_cancelledShow_returnsCancelled() {
        let show = makeShow(status: .cancelled, seasons: [])
        let season = makeSeason(seasonNumber: 1, isComplete: false, hasStarted: true)

        let state = manager.deriveState(for: show, season: season)

        #expect(state == .cancelled)
    }

    // MARK: - Binge Ready

    @Test func bingeReady_forCompletedShow() {
        let show = makeShow(status: .ended, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true)
        ])

        #expect(show.isBingeReady == true)
    }

    @Test func bingeReady_forCancelledShow() {
        let show = makeShow(status: .cancelled, seasons: [
            makeSeason(seasonNumber: 1, isComplete: false, hasStarted: true)
        ])

        #expect(show.isBingeReady == true)
    }

    @Test func notBingeReady_forAiringShow() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: false, hasStarted: true)
        ])

        #expect(show.isBingeReady == false)
    }

    // MARK: - Multiple Seasons

    @Test func multipleSeasons_usesCurrentSeason() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: false, hasStarted: true)
        ])

        let state = manager.deriveState(for: show)

        // Should use season 2 (current/latest) which is airing
        #expect(state == .airing)
    }

    @Test func multipleSeasons_allComplete_returnsCompleted() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: true, hasStarted: true)
        ])

        let state = manager.deriveState(for: show)

        #expect(state == .completed)
    }

    // MARK: - Critical Bug Prevention Tests
    // These tests verify scenarios that have caused production bugs

    /// THE PITT SCENARIO: S1 complete, S2 airing, S3 announced with no episodes
    /// Bug: currentSeason picked S3 (highest number) instead of S2 (actually airing)
    /// Expected: Show should be AIRING because S2 is currently airing
    @Test func thePittScenario_S1CompleteS2AiringS3Announced_returnsAiring() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: false, hasStarted: true),
            makeAnnouncedSeason(seasonNumber: 3) // 0 episodes, no air date
        ])

        let state = manager.deriveState(for: show)

        #expect(state == .airing, "Show with S2 currently airing should be .airing, not .anticipated")
    }

    /// Ensure show with airing season appears in "Ending Soon" timeline section
    @Test func airingShow_shouldHaveAiringLifecycleState() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: false, hasStarted: true)
        ])

        #expect(show.lifecycleState == .airing, "Show with airing season must have .airing lifecycle state to appear in Ending Soon")
    }

    /// S1 complete, S2 premiering soon (has air date in future)
    @Test func S1CompleteS2PremieringSoon_returnsAnticipated() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: false, hasStarted: false) // Future premiere
        ])

        let state = manager.deriveState(for: show)

        // S2 hasn't started, so show is anticipated/premiering soon
        #expect(state == .anticipated)
    }

    /// S1 complete, S2 complete, S3 announced - should be anticipated (waiting for S3)
    @Test func S1CompleteS2CompleteS3Announced_returnsAnticipated() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: true, hasStarted: true),
            makeAnnouncedSeason(seasonNumber: 3)
        ])

        let state = manager.deriveState(for: show)

        // S3 announced but not started = anticipated
        #expect(state == .anticipated, "Completed seasons with announced future season should be anticipated")
    }

    /// Only specials (season 0) should be ignored
    @Test func showWithOnlySpecials_returnsAnticipated() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 0, isComplete: true, hasStarted: true) // Specials
        ])

        let state = manager.deriveState(for: show)

        #expect(state == .anticipated, "Show with only specials should be anticipated")
    }

    // MARK: - currentSeason Tests

    @Test func currentSeason_prefersAiringSeason() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: false, hasStarted: true), // Airing
            makeAnnouncedSeason(seasonNumber: 3)
        ])

        #expect(show.currentSeason?.seasonNumber == 2, "currentSeason should return the airing season, not the announced one")
    }

    @Test func currentSeason_returnsAnnouncedSeasonOverComplete() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: true, hasStarted: true),
            makeAnnouncedSeason(seasonNumber: 3)
        ])

        // With announced S3, currentSeason returns S3 so show appears in "Anticipated"
        #expect(show.currentSeason?.seasonNumber == 3, "currentSeason should return announced season for anticipated state")
    }

    @Test func currentSeason_fallsBackToMostRecentComplete_whenNoUpcoming() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: true, hasStarted: true)
            // No S3 announced
        ])

        #expect(show.currentSeason?.seasonNumber == 2, "currentSeason should return most recent complete when no upcoming")
    }

    @Test func currentSeason_excludesSpecials() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 0, isComplete: true, hasStarted: true), // Specials
            makeSeason(seasonNumber: 1, isComplete: false, hasStarted: true)
        ])

        #expect(show.currentSeason?.seasonNumber == 1, "currentSeason should exclude season 0 (specials)")
    }

    // MARK: - upcomingSeason Tests

    @Test func upcomingSeason_returnsNextUnstartedSeason() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: false, hasStarted: false) // Not started
        ])

        #expect(show.upcomingSeason?.seasonNumber == 2)
    }

    @Test func upcomingSeason_nil_whenAllStarted() {
        let show = makeShow(status: .returning, seasons: [
            makeSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
            makeSeason(seasonNumber: 2, isComplete: false, hasStarted: true)
        ])

        #expect(show.upcomingSeason == nil)
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
        // All episodes have aired
        episodes = (1...10).map { episodeNum in
            makeEpisode(
                episodeNumber: episodeNum,
                seasonNumber: seasonNumber,
                airDate: pastDate
            )
        }
    } else if hasStarted {
        // Some episodes aired, some haven't
        episodes = (1...10).map { episodeNum in
            makeEpisode(
                episodeNumber: episodeNum,
                seasonNumber: seasonNumber,
                airDate: episodeNum <= 5 ? pastDate : futureDate
            )
        }
    } else {
        // No episodes have aired
        episodes = (1...10).map { episodeNum in
            makeEpisode(
                episodeNumber: episodeNum,
                seasonNumber: seasonNumber,
                airDate: futureDate
            )
        }
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

/// Creates an announced season with no episodes and no air date (like The Pitt S3)
private func makeAnnouncedSeason(seasonNumber: Int) -> Season {
    Season(
        id: seasonNumber * 100,
        seasonNumber: seasonNumber,
        name: "Season \(seasonNumber)",
        overview: nil,
        posterPath: nil,
        airDate: nil, // No air date yet
        episodeCount: 0,
        episodes: [] // No episodes
    )
}
