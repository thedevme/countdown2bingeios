//
//  GoldenCycleTests.swift
//  Countdown2BingeTests
//
//  The "Golden Test" - validates the complete lifecycle of a show from
//  Anticipated → Airing → Binge Ready → Watched → Next Season Anticipated
//

import Testing
import Foundation
@testable import Countdown2Binge

@Suite("Golden Cycle Tests", .serialized)
@MainActor
struct GoldenCycleTests {
    let lifecycleManager = ShowLifecycleManager()

    // MARK: - Individual State Transitions

    @Test("Show with future premiere is Anticipated")
    func showWithFuturePremiere_isAnticipated() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!

        let show = makeShow(
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: futureDate, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: futureDate),
                    makeEpisode(episodeNumber: 2, airDate: futureDate)
                ])
            ]
        )

        let state = lifecycleManager.deriveState(for: show)

        #expect(state == .anticipated)
        #expect(show.isBingeReady == false)
    }

    @Test("Show that just premiered is Airing")
    func showThatJustPremiered_isAiring() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!

        let show = makeShow(
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: pastDate, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: pastDate),
                    makeEpisode(episodeNumber: 2, airDate: futureDate)
                ])
            ]
        )

        let state = lifecycleManager.deriveState(for: show)

        #expect(state == .airing)
        #expect(show.isBingeReady == false)
    }

    @Test("Show with finished season is Binge Ready")
    func showWithFinishedSeason_isBingeReady() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        let show = makeShow(
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: pastDate, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: pastDate),
                    makeEpisode(episodeNumber: 2, airDate: pastDate)
                ])
            ]
        )

        let state = lifecycleManager.deriveState(for: show)

        #expect(state == .completed)
        #expect(show.isBingeReady == true)
    }

    @Test("Ended show is always Complete")
    func endedShow_isAlwaysComplete() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        let show = makeShow(
            status: .ended,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: pastDate, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: pastDate)
                ])
            ]
        )

        let state = lifecycleManager.deriveState(for: show)

        #expect(state == .completed)
        #expect(show.isBingeReady == true)
    }

    @Test("Cancelled show is Cancelled state")
    func cancelledShow_isCancelledState() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        let show = makeShow(
            status: .cancelled,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: pastDate, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: pastDate)
                ])
            ]
        )

        let state = lifecycleManager.deriveState(for: show)

        #expect(state == .cancelled)
        #expect(show.isBingeReady == true)
    }

    // MARK: - The Golden Cycle Test

    @Test("Full lifecycle: Anticipated → Airing → BingeReady → Watched → NextSeason")
    func goldenCycle_fullLifecycle() async throws {
        // Setup mock repository
        let repository = MockShowRepository()
        let useCase = await MarkWatchedUseCase(repository: repository)

        // PHASE 1: Show announced but not yet airing (Anticipated)
        let futureDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        var show = makeShow(
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: futureDate, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: futureDate)
                ])
            ]
        )
        repository.shows = [show]

        var state = lifecycleManager.deriveState(for: show)
        #expect(state == .anticipated, "Phase 1: Show should be Anticipated before premiere")

        // PHASE 2: Season premieres (Airing)
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        show = makeShow(
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: weekAgo, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: weekAgo),
                    makeEpisode(episodeNumber: 2, airDate: nextWeek)
                ])
            ]
        )
        repository.shows = [show]

        state = lifecycleManager.deriveState(for: show)
        #expect(state == .airing, "Phase 2: Show should be Airing after premiere")

        // PHASE 3: Season finale airs (Binge Ready)
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        show = makeShow(
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: monthAgo, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: monthAgo),
                    makeEpisode(episodeNumber: 2, airDate: monthAgo)
                ])
            ]
        )
        repository.shows = [show]

        state = lifecycleManager.deriveState(for: show)
        #expect(state == .completed, "Phase 3: Show should be Completed (Binge Ready) after finale")
        #expect(show.isBingeReady == true, "Phase 3: Show should be binge ready")

        // PHASE 4: User marks season as watched
        let result = try await useCase.execute(showId: show.id, seasonNumber: 1)
        #expect(result == .nextSeasonPlaceholder(seasonNumber: 2), "Phase 4: Should indicate next season coming")
        #expect(repository.markSeasonWatchedCalls.count == 1, "Phase 4: Should have called markSeasonWatched")

        // PHASE 5: Next season appears in TMDB (Anticipated again)
        show = makeShow(
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: monthAgo, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: monthAgo),
                    makeEpisode(episodeNumber: 2, airDate: monthAgo)
                ], watchedDate: Date()),
                makeSeason(seasonNumber: 2, premiereDate: futureDate, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: futureDate)
                ])
            ]
        )
        repository.shows = [show]

        // Season 2 is now the "current" season and should be anticipated
        let season2State = lifecycleManager.deriveState(for: show, season: show.seasons[1])
        #expect(season2State == .anticipated, "Phase 5: Next season should be Anticipated")

        // Cycle continues!
    }

    // MARK: - Multi-Season Progression

    @Test("Multi-season show progression")
    func multiSeasonProgression() async throws {
        let repository = MockShowRepository()
        let useCase = await MarkWatchedUseCase(repository: repository)

        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let futureDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!

        // Show with 3 seasons: S1 complete, S2 complete, S3 upcoming
        let show = makeShow(
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: pastDate, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: pastDate),
                    makeEpisode(episodeNumber: 2, airDate: pastDate)
                ]),
                makeSeason(seasonNumber: 2, premiereDate: pastDate, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: pastDate),
                    makeEpisode(episodeNumber: 2, airDate: pastDate)
                ]),
                makeSeason(seasonNumber: 3, premiereDate: futureDate, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: futureDate)
                ])
            ]
        )
        repository.shows = [show]

        // Season 1 is binge ready
        #expect(show.seasons[0].isBingeReady == true)

        // Mark season 1 watched
        let result1 = try await useCase.execute(showId: show.id, seasonNumber: 1)
        #expect(result1 == .nextSeasonAdded(seasonNumber: 2))

        // Mark season 2 watched
        let result2 = try await useCase.execute(showId: show.id, seasonNumber: 2)
        #expect(result2 == .nextSeasonAdded(seasonNumber: 3))

        // Season 3 is anticipated (future)
        let s3State = lifecycleManager.deriveState(for: show, season: show.seasons[2])
        #expect(s3State == .anticipated)
    }

    // MARK: - Edge Cases

    @Test("Show with no seasons is Anticipated")
    func showWithNoSeasons_isAnticipated() {
        let show = makeShow(status: .returning, seasons: [])

        let state = lifecycleManager.deriveState(for: show)

        #expect(state == .anticipated)
    }

    @Test("Planned show is Anticipated")
    func plannedShow_isAnticipated() {
        let show = makeShow(status: .planned, seasons: [])

        let state = lifecycleManager.deriveState(for: show)

        #expect(state == .anticipated)
    }

    @Test("Netflix-style drop is immediately Binge Ready")
    func netflixStyleDrop_isImmediatelyBingeReady() {
        // All episodes drop on premiere day
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let show = makeShow(
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, premiereDate: yesterday, episodes: [
                    makeEpisode(episodeNumber: 1, airDate: yesterday),
                    makeEpisode(episodeNumber: 2, airDate: yesterday),
                    makeEpisode(episodeNumber: 3, airDate: yesterday),
                    makeEpisode(episodeNumber: 4, airDate: yesterday),
                    makeEpisode(episodeNumber: 5, airDate: yesterday)
                ])
            ]
        )

        let state = lifecycleManager.deriveState(for: show)

        #expect(state == .completed, "Netflix drop should be Complete immediately")
        #expect(show.isBingeReady == true, "Netflix drop should be binge ready immediately")
    }
}

// MARK: - Mock Repository

@MainActor
private class MockShowRepository: ShowRepositoryProtocol {
    var shows: [Show] = []
    var markSeasonWatchedCalls: [(showId: Int, seasonNumber: Int)] = []
    var markEpisodeWatchedCalls: [(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool)] = []

    func save(_ show: Show) async throws {
        if let index = shows.firstIndex(where: { $0.id == show.id }) {
            shows[index] = show
        } else {
            shows.append(show)
        }
    }

    func fetchAllShows() -> [Show] { shows }

    func fetchShow(byTmdbId id: Int) -> Show? {
        shows.first { $0.id == id }
    }

    func fetchTimelineShows() -> [Show] {
        shows.filter { $0.status == .returning || $0.status == .inProduction }
    }

    func fetchBingeReadySeasons() -> [Season] {
        shows.flatMap { $0.seasons.filter { $0.isBingeReady } }
    }

    func delete(_ show: Show) async throws {
        shows.removeAll { $0.id == show.id }
    }

    func isShowFollowed(tmdbId: Int) -> Bool {
        shows.contains { $0.id == tmdbId }
    }

    func markSeasonWatched(showId: Int, seasonNumber: Int) async throws {
        markSeasonWatchedCalls.append((showId: showId, seasonNumber: seasonNumber))
    }

    func markEpisodeWatched(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool) async throws {
        markEpisodeWatchedCalls.append((showId: showId, seasonNumber: seasonNumber, episodeNumber: episodeNumber, watched: watched))
    }
}

// MARK: - Test Helpers

private func makeShow(
    id: Int = 1,
    status: ShowStatus,
    seasons: [Season]
) -> Show {
    Show(
        id: id,
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

private func makeSeason(
    seasonNumber: Int,
    premiereDate: Date,
    episodes: [Episode],
    watchedDate: Date? = nil
) -> Season {
    Season(
        id: seasonNumber * 100,
        seasonNumber: seasonNumber,
        name: "Season \(seasonNumber)",
        overview: nil,
        posterPath: nil,
        airDate: premiereDate,
        episodeCount: episodes.count,
        episodes: episodes,
        watchedDate: watchedDate
    )
}

private func makeEpisode(
    episodeNumber: Int,
    airDate: Date,
    seasonNumber: Int = 1
) -> Episode {
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
