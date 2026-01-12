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
}

// MARK: - Test Helpers

private func makeShow(status: ShowStatus, seasons: [Season]) -> Show {
    Show(
        id: 1,
        name: "Test Show",
        overview: nil,
        posterPath: nil,
        backdropPath: nil,
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
