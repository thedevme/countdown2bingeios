//
//  MarkWatchedTests.swift
//  Countdown2BingeTests
//
//  Tests for the MarkWatchedUseCase lifecycle transitions.
//

import Testing
import Foundation
@testable import Countdown2Binge

@Suite(.serialized)
@MainActor
struct MarkWatchedTests {

    // MARK: - Mark Watched Returns Correct Result

    @Test func markWatched_endedShow_returnsShowComplete() async throws {
        let repository = MockShowRepository()
        let show = makeShow(
            id: 1,
            status: .ended,
            seasons: [
                makeSeason(seasonNumber: 1, isComplete: true)
            ]
        )
        repository.shows = [show]

        let useCase = await MarkWatchedUseCase(repository: repository)
        let result = try await useCase.execute(showId: 1, seasonNumber: 1)

        #expect(result == .showComplete)
    }

    @Test func markWatched_cancelledShow_returnsShowComplete() async throws {
        let repository = MockShowRepository()
        let show = makeShow(
            id: 1,
            status: .cancelled,
            seasons: [
                makeSeason(seasonNumber: 1, isComplete: true)
            ]
        )
        repository.shows = [show]

        let useCase = await MarkWatchedUseCase(repository: repository)
        let result = try await useCase.execute(showId: 1, seasonNumber: 1)

        #expect(result == .showComplete)
    }

    @Test func markWatched_returningShow_withNextSeason_returnsNextSeasonAdded() async throws {
        let repository = MockShowRepository()
        let show = makeShow(
            id: 1,
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, isComplete: true),
                makeSeason(seasonNumber: 2, isComplete: false)
            ]
        )
        repository.shows = [show]

        let useCase = await MarkWatchedUseCase(repository: repository)
        let result = try await useCase.execute(showId: 1, seasonNumber: 1)

        #expect(result == .nextSeasonAdded(seasonNumber: 2))
    }

    @Test func markWatched_returningShow_withoutNextSeason_returnsPlaceholder() async throws {
        let repository = MockShowRepository()
        let show = makeShow(
            id: 1,
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, isComplete: true)
            ]
        )
        repository.shows = [show]

        let useCase = await MarkWatchedUseCase(repository: repository)
        let result = try await useCase.execute(showId: 1, seasonNumber: 1)

        #expect(result == .nextSeasonPlaceholder(seasonNumber: 2))
    }

    @Test func markWatched_inProductionShow_withNextSeason_returnsNextSeasonAdded() async throws {
        let repository = MockShowRepository()
        let show = makeShow(
            id: 1,
            status: .inProduction,
            seasons: [
                makeSeason(seasonNumber: 1, isComplete: true),
                makeSeason(seasonNumber: 2, isComplete: true),
                makeSeason(seasonNumber: 3, isComplete: false)
            ]
        )
        repository.shows = [show]

        let useCase = await MarkWatchedUseCase(repository: repository)
        let result = try await useCase.execute(showId: 1, seasonNumber: 2)

        #expect(result == .nextSeasonAdded(seasonNumber: 3))
    }

    // MARK: - Mark Watched Updates Repository

    @Test func markWatched_callsRepositoryMarkSeasonWatched() async throws {
        let repository = MockShowRepository()
        let show = makeShow(
            id: 42,
            status: .ended,
            seasons: [makeSeason(seasonNumber: 3, isComplete: true)]
        )
        repository.shows = [show]

        let useCase = await MarkWatchedUseCase(repository: repository)
        _ = try await useCase.execute(showId: 42, seasonNumber: 3)

        #expect(repository.markSeasonWatchedCalls.count == 1)
        #expect(repository.markSeasonWatchedCalls.first?.showId == 42)
        #expect(repository.markSeasonWatchedCalls.first?.seasonNumber == 3)
    }

    // MARK: - Error Cases

    @Test func markWatched_showNotFound_throws() async throws {
        let repository = MockShowRepository()
        repository.shows = []

        let useCase = await MarkWatchedUseCase(repository: repository)

        await #expect(throws: MarkWatchedError.showNotFound) {
            _ = try await useCase.execute(showId: 999, seasonNumber: 1)
        }
    }

    @Test func markWatched_seasonNotFound_throws() async throws {
        let repository = MockShowRepository()
        let show = makeShow(
            id: 1,
            status: .returning,
            seasons: [makeSeason(seasonNumber: 1, isComplete: true)]
        )
        repository.shows = [show]

        let useCase = await MarkWatchedUseCase(repository: repository)

        await #expect(throws: MarkWatchedError.seasonNotFound) {
            _ = try await useCase.execute(showId: 1, seasonNumber: 99)
        }
    }

    // MARK: - Full Cycle Simulation

    @Test func fullCycle_markMultipleSeasonsWatched() async throws {
        let repository = MockShowRepository()
        let show = makeShow(
            id: 1,
            status: .returning,
            seasons: [
                makeSeason(seasonNumber: 1, isComplete: true),
                makeSeason(seasonNumber: 2, isComplete: true),
                makeSeason(seasonNumber: 3, isComplete: false)
            ]
        )
        repository.shows = [show]

        let useCase = await MarkWatchedUseCase(repository: repository)

        // Mark season 1 watched
        let result1 = try await useCase.execute(showId: 1, seasonNumber: 1)
        #expect(result1 == .nextSeasonAdded(seasonNumber: 2))

        // Mark season 2 watched
        let result2 = try await useCase.execute(showId: 1, seasonNumber: 2)
        #expect(result2 == .nextSeasonAdded(seasonNumber: 3))

        // Mark season 3 watched (last known season)
        let result3 = try await useCase.execute(showId: 1, seasonNumber: 3)
        #expect(result3 == .nextSeasonPlaceholder(seasonNumber: 4))

        // Verify all seasons were marked
        #expect(repository.markSeasonWatchedCalls.count == 3)
    }

    @Test func fullCycle_endedShowAfterAllSeasons() async throws {
        let repository = MockShowRepository()
        let show = makeShow(
            id: 1,
            status: .ended,
            seasons: [
                makeSeason(seasonNumber: 1, isComplete: true),
                makeSeason(seasonNumber: 2, isComplete: true)
            ]
        )
        repository.shows = [show]

        let useCase = await MarkWatchedUseCase(repository: repository)

        // Mark season 1 - show is ended but has season 2
        // Note: determineResult checks show status first
        let result1 = try await useCase.execute(showId: 1, seasonNumber: 1)
        #expect(result1 == .showComplete) // Ended shows always return .showComplete

        // Mark season 2 - final season
        let result2 = try await useCase.execute(showId: 1, seasonNumber: 2)
        #expect(result2 == .showComplete)
    }
}

// MARK: - Mock Repository

@MainActor
private class MockShowRepository: ShowRepositoryProtocol {
    var shows: [Show] = []
    var markSeasonWatchedCalls: [(showId: Int, seasonNumber: Int)] = []
    var markEpisodeWatchedCalls: [(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool)] = []
    var savedShows: [Show] = []
    var deletedShows: [Show] = []

    func save(_ show: Show) async throws {
        savedShows.append(show)
        if let index = shows.firstIndex(where: { $0.id == show.id }) {
            shows[index] = show
        } else {
            shows.append(show)
        }
    }

    func fetchAllShows() -> [Show] {
        shows
    }

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
        deletedShows.append(show)
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

private func makeShow(id: Int, status: ShowStatus, seasons: [Season]) -> Show {
    Show(
        id: id,
        name: "Test Show \(id)",
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

private func makeSeason(seasonNumber: Int, isComplete: Bool, watchedDate: Date? = nil) -> Season {
    let now = Date()
    let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
    let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: now)!

    let episodes: [Episode]
    if isComplete {
        // All episodes have aired
        episodes = (1...10).map { episodeNum in
            Episode(
                id: seasonNumber * 1000 + episodeNum,
                episodeNumber: episodeNum,
                seasonNumber: seasonNumber,
                name: "Episode \(episodeNum)",
                overview: nil,
                airDate: pastDate,
                stillPath: nil,
                runtime: 45
            )
        }
    } else {
        // Some episodes aired, some haven't
        episodes = (1...10).map { episodeNum in
            Episode(
                id: seasonNumber * 1000 + episodeNum,
                episodeNumber: episodeNum,
                seasonNumber: seasonNumber,
                name: "Episode \(episodeNum)",
                overview: nil,
                airDate: episodeNum <= 5 ? pastDate : futureDate,
                stillPath: nil,
                runtime: 45
            )
        }
    }

    return Season(
        id: seasonNumber * 100,
        seasonNumber: seasonNumber,
        name: "Season \(seasonNumber)",
        overview: nil,
        posterPath: nil,
        airDate: pastDate,
        episodeCount: episodes.count,
        episodes: episodes,
        watchedDate: watchedDate
    )
}
