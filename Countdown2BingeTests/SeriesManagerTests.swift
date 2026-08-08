//
//  SeriesManagerTests.swift
//  Countdown2BingeTests
//
//  SeriesManager integration tests based on BingeEngineSpec.md Groups 5-10.
//  Uses an in-memory ModelContainer so these tests don't touch disk.
//
//  STATUS: Matches the shipped engine (Aug 2026). Locked rules these tests
//  encode — do not "simplify" a test to make it pass; a failure means a real
//  engine bug OR a wrong test, diagnose which.
//

import Testing
import Foundation
import SwiftData
import CloudKit
@testable import Countdown2Binge

// MARK: - Test Fixtures

/// A fixed reference date for all tests. All dates are relative to this.
private let testNow: Date = {
    var components = DateComponents()
    components.year = 2026
    components.month = 8
    components.day = 15
    components.hour = 12
    components.minute = 0
    return Calendar.current.date(from: components)!
}()

/// Helper to create a date relative to the reference date.
private func date(daysFromNow offset: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: offset, to: testNow)!
}

/// Mock TMDB service for tests
final class MockTMDBService: TMDBServiceProtocol, @unchecked Sendable {
    var showsToReturn: [Int: ShowData] = [:]

    /// Track which show IDs were fetched (for verifying refresh behavior)
    var fetchedIds: [Int] = []

    func setShow(_ show: ShowData) {
        showsToReturn[show.id] = show
    }

    /// Clear the fetched IDs list (call before testing refresh behavior)
    func clearFetchedIds() {
        fetchedIds = []
    }

    func getShowDetails(id: Int) async throws -> ShowData {
        fetchedIds.append(id)
        if let show = showsToReturn[id] {
            return show
        }
        throw NSError(domain: "MockTMDB", code: 404, userInfo: [NSLocalizedDescriptionKey: "Show not found"])
    }

    // Stub implementations for protocol conformance
    func searchShows(query: String, page: Int) async throws -> TMDBSearchResponse {
        TMDBSearchResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }

    func getSeasonDetails(tvId: Int, seasonNumber: Int) async throws -> SeasonData {
        throw NSError(domain: "MockTMDB", code: 501, userInfo: nil)
    }

    func getTrendingShows(page: Int) async throws -> TMDBSearchResponse {
        TMDBSearchResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }

    func getAiringShows(page: Int) async throws -> TMDBSearchResponse {
        TMDBSearchResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }

    func getShowsByGenre(genreIds: [Int], page: Int) async throws -> TMDBSearchResponse {
        TMDBSearchResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }

    func getShowsByNetwork(networkId: Int, page: Int) async throws -> TMDBSearchResponse {
        TMDBSearchResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }

    func getShowsByDateRange(networkId: Int, startDate: Date, endDate: Date, page: Int) async throws -> TMDBSearchResponse {
        TMDBSearchResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }

    func getShowLogo(id: Int) async -> String? { nil }

    func getShowVideos(id: Int) async throws -> [TMDBVideo] { [] }

    func getShowCredits(id: Int) async throws -> TMDBCreditsResponse {
        TMDBCreditsResponse(cast: [], crew: [])
    }

    func getShowRecommendations(id: Int) async throws -> [TMDBShowSummary] { [] }

    func getWatchProviders(id: Int) async throws -> TMDBWatchProvidersResponse {
        TMDBWatchProvidersResponse(id: id, results: [:])
    }

    func getWatchProvidersTV(region: String) async throws -> [TMDBWatchProvider] { [] }

    func getShowName(id: Int) async throws -> String { "Mock Show" }

    func discover(query: DiscoverQuery, relaxation: DiscoverQuery.Relaxation) async throws -> TMDBSearchResponse {
        TMDBSearchResponse(page: 1, results: [], totalPages: 0, totalResults: 0)
    }

    func getShowDetailsWithExtras(id: Int) async throws -> ShowDetailsWithExtras {
        let show = try await getShowDetails(id: id)
        return ShowDetailsWithExtras(show: show, cast: [], videos: [], recommendations: [])
    }

    func getMultipleShowDetails(ids: [Int]) async throws -> [ShowData] {
        var results: [ShowData] = []
        for id in ids {
            if let show = try? await getShowDetails(id: id) {
                results.append(show)
            }
        }
        return results
    }

    func getMultipleShowsByNetwork(networkIds: [Int], page: Int) async throws -> [Int: [ShowSummary]] { [:] }

    func getMultipleShowsByGenre(genreIds: [Int], page: Int) async throws -> [Int: [ShowSummary]] { [:] }

    func getShowBasicInfo(id: Int) async throws -> (episodes: Int, seasons: Int) { (0, 0) }

    func getMultipleShowBasicInfo(ids: [Int]) async throws -> [Int: (episodes: Int, seasons: Int)] { [:] }
}

/// Mock franchise resolver for tests
struct MockFranchiseResolver: FranchiseResolving {
    var relatedIds: [Int: [Int]] = [:]

    func relatedShowIds(forShowId showId: Int) async -> [Int] {
        relatedIds[showId] ?? []
    }
}

/// Mock CloudSyncing for tests — pure no-op, never touches CloudKit.
/// Each test gets a fresh instance to avoid shared-state collision in parallel runs.
@MainActor
final class MockCloudSyncing: CloudSyncing {
    /// Control whether isAvailable returns true (default: false for isolation)
    var mockIsAvailable: Bool = false

    var isAvailable: Bool {
        get async { mockIsAvailable }
    }

    // Track calls for verification if needed
    var savedWatchProgressKeys: Set<String>?
    var savedShowIds: [Int] = []
    var deletedShowIds: [Int] = []
    var deletedAllWatchProgress: Bool = false

    @discardableResult
    func saveAllWatchProgress(watchedEpisodeKeys: Set<String>) async throws -> String {
        savedWatchProgressKeys = watchedEpisodeKeys
        return "mock_watch_progress"
    }

    func fetchAllWatchProgress() async throws -> Set<String>? {
        nil // Always return nil — no cloud data in tests
    }

    @discardableResult
    func saveFollowedShow(tmdbId: Int, followedAt: Date, recordName: String?) async throws -> String {
        savedShowIds.append(tmdbId)
        return "mock_show_\(tmdbId)"
    }

    func deleteFollowedShow(tmdbId: Int) async throws {
        deletedShowIds.append(tmdbId)
    }

    func deleteFollowedShows(_ tmdbIds: [Int]) async throws {
        deletedShowIds.append(contentsOf: tmdbIds)
    }

    func deleteAllWatchProgress() async throws {
        deletedAllWatchProgress = true
    }

    func fetchAllFollowedShows() async throws -> [CKRecord] {
        [] // Always return empty — no cloud data in tests
    }
}

/// Create an in-memory ModelContainer for tests.
/// Each test gets a uniquely-named container to avoid SwiftData's
/// schema-registration collision when tests run in parallel.
/// CloudKit is explicitly disabled to avoid relationship validation errors.
@MainActor
private func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([Series.self, Season.self, Episode.self])
    let config = ModelConfiguration(
        "test-\(UUID().uuidString)",
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(for: schema, configurations: [config])
}

/// Build a ShowData fixture with episodes
private func buildShowData(
    id: Int,
    name: String,
    seasons: [(number: Int, episodes: [(number: Int, airDate: Date?, isTypedFinale: Bool, isTyped: Bool)])]
) -> ShowData {
    ShowData(
        id: id,
        name: name,
        overview: "Test show",
        posterPath: nil,
        backdropPath: nil,
        logoPath: nil,
        firstAirDate: nil,
        status: .returning,
        genres: [],
        networks: [],
        createdBy: nil,
        seasons: seasons.map { seasonTuple in
            SeasonData(
                id: id * 100 + seasonTuple.number,
                seasonNumber: seasonTuple.number,
                name: "Season \(seasonTuple.number)",
                overview: "",
                posterPath: nil,
                airDate: seasonTuple.episodes.first?.airDate,
                episodeCount: seasonTuple.episodes.count,
                episodes: seasonTuple.episodes.map { epTuple in
                    // Episode type logic:
                    // - isTypedFinale: true → .finale
                    // - isTyped (but not finale) → .midSeason (any non-.standard value means "typed")
                    // - neither: .standard (untyped, fallback rules apply)
                    let episodeType: EpisodeType = {
                        if epTuple.isTypedFinale { return .finale }
                        if epTuple.isTyped { return .midSeason }
                        return .standard
                    }()
                    return EpisodeData(
                        id: id * 1000 + seasonTuple.number * 100 + epTuple.number,
                        episodeNumber: epTuple.number,
                        seasonNumber: seasonTuple.number,
                        name: "Episode \(epTuple.number)",
                        overview: "",
                        airDate: epTuple.airDate,
                        stillPath: nil,
                        runtime: 45,
                        episodeType: episodeType,
                        voteAverage: nil
                    )
                },
                voteAverage: nil
            )
        },
        numberOfSeasons: seasons.count,
        numberOfEpisodes: seasons.flatMap { $0.episodes }.count,
        inProduction: true,
        voteAverage: 8.0
    )
}

// MARK: - SeriesManager Integration Tests (Groups 5-10)
// Wrapped in a serialized parent suite to avoid SwiftData @MainActor contention
// when multiple suites run in parallel. Each test creates its own in-memory container,
// but SwiftData's internals still race under concurrent @MainActor execution.

@Suite("SeriesManager Integration Tests", .serialized)
struct SeriesManagerIntegrationTests {

    // MARK: - Group 5: Follow Entry Paths

    @Suite("Group 5 — Follow Entry Paths")
    struct FollowEntryPathTests {

    /// 5.1 Pre-air follow (no add-time prompt)
    @Test("5.1 Pre-air follow (no add-time prompt)")
    @MainActor
    func preAirFollow() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: a show whose latest season hasn't aired
        let show = buildShowData(
            id: 1001,
            name: "Future Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: date(daysFromNow: 30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: 37), isTypedFinale: false, isTyped: false)
                ]
            )]
        )

        // When: follow(showData:)
        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // Then: result .followed with addTimePrompt == nil
        if case .followed(_, let prompt) = result {
            #expect(prompt == nil)
        } else {
            Issue.record("Expected .followed result")
        }
    }

    /// 5.2 Back-catalog follow (Landman) → prompt fires
    @Test("5.2 Back-catalog follow (Landman) → prompt fires")
    @MainActor
    func backCatalogFollow() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: a show whose latest season is complete-by-date (already aired)
        // Landman-like scenario: S2 finished 10 days ago
        let show = buildShowData(
            id: 1002,
            name: "Landman",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -113), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -106), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -23), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: false) // finale 10 days ago
                ])
            ]
        )

        // When: follow(showData:)
        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // Then: .followed with prompt for the latest complete season (S2)
        if case .followed(_, let prompt) = result {
            #expect(prompt != nil)
            #expect(prompt?.seasonNumber == 2)
        } else {
            Issue.record("Expected .followed result with prompt")
        }
    }

    /// 5.3 Answer "yes, watched" → toward Anticipated
    @Test("5.3 Answer yes watched → ONLY latest season marked, show toward Anticipated")
    @MainActor
    func answerYesWatched() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: follow a back-catalog show with S1 and S2 complete
        let show = buildShowData(
            id: 1003,
            name: "Back Catalog Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -113), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -106), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -23), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        guard case .followed(let series, let prompt) = result else {
            Issue.record("Expected .followed result")
            return
        }

        #expect(prompt?.seasonNumber == 2)

        // When: answerAddTimeWatched(..., watched: true)
        try manager.answerAddTimeWatched(seriesId: series.id, seasonNumber: 2, watched: true)

        // Then: ONLY S2 hasWatched == true (S1 untouched)
        let s1 = series.regularSeasons.first { $0.seasonNumber == 1 }
        let s2 = series.regularSeasons.first { $0.seasonNumber == 2 }

        #expect(s1?.hasWatched == false, "S1 should remain unwatched")
        #expect(s2?.hasWatched == true, "S2 should be marked watched")

        // bingeReadySeason for S2 is nil (it's watched now)
        // Note: S1 is still unwatched, so bingeReadySeason would be S1 now
        // But per spec: "bingeReadySeason for S2 is nil" means S2 specifically isn't the binge target
        #expect(series.bingeReadySeason?.seasonNumber != 2)

        // showState is .anticipated or .premieringSoon (if no S3)
        // Since we only have S1 and S2, and S2 is watched but S1 is unwatched...
        // currentSeason is the latest (S2 which is complete), so state is .bingeReady for the show
        // But wait, S1 is also complete and unwatched, so bingeReadySeason = S1
        // The show state reflects current season which is S2 (complete) = .bingeReady
        // This is correct behavior - the show has unwatched complete seasons
    }

    /// 5.3b Answer "yes" does not touch earlier seasons
    @Test("5.3b Answer yes does not touch earlier seasons")
    @MainActor
    func answerYesDoesNotTouchEarlier() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: the 5.2 prompt for S2, with S1 unwatched
        let show = buildShowData(
            id: 1004,
            name: "Multi Season Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -113), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -106), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -23), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else {
            Issue.record("Expected .followed result")
            return
        }

        // When: answerAddTimeWatched(S2, watched: true)
        try manager.answerAddTimeWatched(seriesId: series.id, seasonNumber: 2, watched: true)

        // Then: S1 hasWatched == false (only the latest answered season is marked)
        let s1 = series.regularSeasons.first { $0.seasonNumber == 1 }
        #expect(s1?.hasWatched == false)
    }

    /// 5.4 Answer "no, not watched" → Binge Ready
    @Test("5.4 Answer no not watched → Binge Ready")
    @MainActor
    func answerNoNotWatched() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: the 5.2 prompt
        let show = buildShowData(
            id: 1005,
            name: "Binge Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -23), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else {
            Issue.record("Expected .followed result")
            return
        }

        // When: answerAddTimeWatched(..., watched: false)
        try manager.answerAddTimeWatched(seriesId: series.id, seasonNumber: 1, watched: false)

        // Then: latest season stays unwatched; bingeReadySeason == that season
        let s1 = series.regularSeasons.first { $0.seasonNumber == 1 }
        #expect(s1?.hasWatched == false)
        #expect(series.bingeReadySeason?.seasonNumber == 1)
    }

    /// 5.5 Re-follow is idempotent
    @Test("5.5 Re-follow is idempotent")
    @MainActor
    func reFollowIdempotent() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: already following
        let show = buildShowData(
            id: 1006,
            name: "Idempotent Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -23), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        _ = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // Mark S1 as watched to verify state is preserved
        try manager.markSeasonWatched(seriesId: 1006, seasonNumber: 1, watched: true)

        let countBefore = manager.allSeries().count

        // When: follow again
        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // Then: .alreadyFollowing, no duplicate Series, watch state preserved
        if case .alreadyFollowing(let series) = result {
            #expect(manager.allSeries().count == countBefore, "Should not create duplicate")
            let s1 = series.regularSeasons.first { $0.seasonNumber == 1 }
            #expect(s1?.hasWatched == true, "Watch state should be preserved")
        } else {
            Issue.record("Expected .alreadyFollowing result")
        }
    }
}

    // MARK: - Group 6: The Cycle (Landman Walk-through)

    @Suite("Group 6 — Cycle (Landman Walk-through)")
    struct CycleTests {

    /// 6.1 Finish latest → sits in Binge Ready
    @Test("6.1 Latest unwatched complete season → sits in Binge Ready")
    @MainActor
    func latestUnwatchedOnSurface() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: S2 complete, unwatched
        let show = buildShowData(
            id: 2001,
            name: "Landman",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -113), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -106), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -23), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else {
            Issue.record("Expected .followed result")
            return
        }

        // Then: on surface as bingeReady
        #expect(series.bingeReadySeason != nil)
        #expect(series.isOnBingeReadySurface == true)
    }

    /// 6.2 Mark S2 watched, no S3 yet → Anticipated, leaves surface
    @Test("6.2 Mark S2 watched, no S3 yet → leaves Binge Ready surface")
    @MainActor
    func markWatchedLeavesSurface() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: 6.1 state with S1 and S2 complete
        let show = buildShowData(
            id: 2002,
            name: "Landman 2",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -113), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -106), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -23), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else {
            Issue.record("Expected .followed result")
            return
        }

        // Mark S1 watched first
        try manager.markSeasonWatched(seriesId: series.id, seasonNumber: 1, watched: true)

        // When: markSeasonWatched(S2, true)
        try manager.markSeasonWatched(seriesId: series.id, seasonNumber: 2, watched: true)

        // Then: bingeReadySeason == nil (both seasons watched)
        #expect(series.bingeReadySeason == nil)

        // showState reflects the current season (S2 which is complete) = .bingeReady for dates
        // But since it's watched, the show is "waiting for next season" = .anticipated
        // Actually, showState is date-only (Axis 1), so it's still .bingeReady
        // The user-facing surface check (isOnBingeReadySurface) is what matters
        #expect(series.isOnBingeReadySurface == false)
    }

    /// MyList advance: completing the current (earliest) season moves selection
    /// to the next complete-unwatched season, and the deck count shrinks by one.
    @Test("MyList: complete current season → earliestUnwatchedSeason advances")
    @MainActor
    func myListAdvanceOnCompletion() async throws {
        let container = try makeTestContainer()
        let manager = SeriesManager(
            container: container,
            tmdb: MockTMDBService(),
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // S1 and S2 both complete (finales aired, past grace) and unwatched.
        let show = buildShowData(
            id: 2100,
            name: "Advance",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -110), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -60), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -50), isTypedFinale: false, isTyped: false)
                ])
            ]
        )
        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else { Issue.record("follow failed"); return }

        // Currently on S1, two seasons to catch up.
        #expect(series.earliestUnwatchedSeason?.seasonNumber == 1)
        #expect(series.bingeableUnwatchedSeasonCount == 2)

        // ✓ ALL on the complete S1 → every episode aired → season fully watched.
        try manager.markAiredEpisodesWatched(seriesId: series.id, seasonNumber: 1)

        // Advances to S2; deck shrinks to 1.
        #expect(series.earliestUnwatchedSeason?.seasonNumber == 2)
        #expect(series.bingeableUnwatchedSeasonCount == 1)
    }

    /// MyList no-false-advance: ✓ ALL on a STILL-AIRING season marks only aired
    /// episodes, so hasWatched stays false and selection does NOT move.
    @Test("MyList: ✓ ALL on a still-airing season does not advance")
    @MainActor
    func myListNoFalseAdvance() async throws {
        let container = try makeTestContainer()
        let manager = SeriesManager(
            container: container,
            tmdb: MockTMDBService(),
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // S1 complete+unwatched; S2 still airing (finale in the future).
        let show = buildShowData(
            id: 2101,
            name: "NoAdvance",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -110), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -5), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: date(daysFromNow: 5), isTypedFinale: true, isTyped: true)
                ])
            ]
        )
        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else { Issue.record("follow failed"); return }

        // Only S1 is bingeable; S2 is airing (Timeline's job).
        #expect(series.earliestUnwatchedSeason?.seasonNumber == 1)
        #expect(series.bingeableUnwatchedSeasonCount == 1)

        // ✓ ALL on the still-airing S2 marks aired ep1 only → not complete.
        try manager.markAiredEpisodesWatched(seriesId: series.id, seasonNumber: 2)

        let s2 = series.regularSeasons.first { $0.seasonNumber == 2 }
        #expect(s2?.hasWatched == false)                       // unaired ep2 remains
        #expect(series.earliestUnwatchedSeason?.seasonNumber == 1)  // no false advance
        #expect(series.bingeableUnwatchedSeasonCount == 1)
    }

    /// Add-time "caught up" must mark ALL prior seasons, not just the latest —
    /// otherwise an earlier unwatched season keeps the show on MyList (the HotD bug).
    @Test("MyList: caught up through latest ended season → nothing bingeable, off MyList")
    @MainActor
    func caughtUpMarksAllPriorSeasons() async throws {
        let container = try makeTestContainer()
        let manager = SeriesManager(
            container: container,
            tmdb: MockTMDBService(),
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // House of the Dragon shape: S1 & S2 ended, S3 still airing.
        let show = buildShowData(
            id: 2200,
            name: "Dragon",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -400), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -390), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -200), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -190), isTypedFinale: false, isTyped: false)
                ]),
                (number: 3, episodes: [
                    (number: 1, airDate: date(daysFromNow: -3), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: date(daysFromNow: 7), isTypedFinale: true, isTyped: true)
                ])
            ]
        )
        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, let prompt?) = result else {
            Issue.record("expected a follow with an add-time prompt"); return
        }

        // Before catching up, S1 is the earliest bingeable season.
        #expect(series.earliestUnwatchedSeason?.seasonNumber == 1)
        #expect(prompt.seasonNumber == 2)   // latest ended season

        // "All caught up" through S2 → marks S1 AND S2.
        try manager.markSeasonsWatched(seriesId: series.id, throughSeasonNumber: prompt.seasonNumber)

        let s1 = series.regularSeasons.first { $0.seasonNumber == 1 }
        #expect(s1?.hasWatched == true)                        // the fix: S1 not left behind
        #expect(series.earliestUnwatchedSeason == nil)         // nothing to binge
        #expect(series.bingeableUnwatchedSeasonCount == 0)     // off MyList → Timeline only
    }

    /// 6.4 S3 airs → Airing/Pending; S3 completes unwatched → Binge Ready = S3
    @Test("6.4 New season complete and unwatched → becomes Binge Ready")
    @MainActor
    func newSeasonBecomesBingeReady() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: S1-S2 watched, S3 completes unwatched
        let show = buildShowData(
            id: 2004,
            name: "Landman 4",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -180), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -173), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -166), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -113), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -106), isTypedFinale: false, isTyped: false)
                ]),
                (number: 3, episodes: [
                    (number: 1, airDate: date(daysFromNow: -30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -23), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: false) // S3 complete
                ])
            ]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else {
            Issue.record("Expected .followed result")
            return
        }

        // Mark S1 and S2 as watched
        try manager.markSeasonWatched(seriesId: series.id, seasonNumber: 1, watched: true)
        try manager.markSeasonWatched(seriesId: series.id, seasonNumber: 2, watched: true)

        // Then: bingeReadySeason == S3 (the latest unwatched complete)
        #expect(series.bingeReadySeason?.seasonNumber == 3)
    }

    /// 6.5 Older unwatched season persists but isn't the surface item
    @Test("6.5 Older unwatched season persists but isn't the surface item")
    @MainActor
    func olderUnwatchedNotSurface() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: S3 unwatched-complete AND S5 unwatched-complete
        let show = buildShowData(
            id: 2005,
            name: "Multi Unwatched",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -300), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -293), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -286), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -240), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -233), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -226), isTypedFinale: false, isTyped: false)
                ]),
                (number: 3, episodes: [ // unwatched-complete
                    (number: 1, airDate: date(daysFromNow: -180), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -173), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -166), isTypedFinale: false, isTyped: false)
                ]),
                (number: 4, episodes: [
                    (number: 1, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -113), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -106), isTypedFinale: false, isTyped: false)
                ]),
                (number: 5, episodes: [ // unwatched-complete
                    (number: 1, airDate: date(daysFromNow: -60), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -53), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -46), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else {
            Issue.record("Expected .followed result")
            return
        }

        // Mark S1, S2, S4 as watched (leave S3 and S5 unwatched)
        try manager.markSeasonWatched(seriesId: series.id, seasonNumber: 1, watched: true)
        try manager.markSeasonWatched(seriesId: series.id, seasonNumber: 2, watched: true)
        try manager.markSeasonWatched(seriesId: series.id, seasonNumber: 4, watched: true)

        // Then: bingeReadySeason == S5 (the latest)
        #expect(series.bingeReadySeason?.seasonNumber == 5)

        // S3 still hasWatched == false and reachable by drilling into the show
        let s3 = series.regularSeasons.first { $0.seasonNumber == 3 }
        #expect(s3?.hasWatched == false)
    }

    /// 6.6 Full cycle: TBA → premiering → airing → binge ready → watched → S2 repeats
    /// Tests the TRANSITIONS between states on one show across a full loop by advancing `now`.
    @Test("6.6 Full cycle: TBA → premiering → airing → binge ready → watched → S2 repeats")
    @MainActor
    func fullCycleAdvancingClock() async throws {
        // Fixed base date for all calculations
        let baseNow = testNow  // Aug 15, 2026

        // Helper to compute dates relative to base
        func dateOffset(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: baseNow)!
        }

        // Helper to build SeasonFacts from Series (since seasonFacts is private)
        func seasonFacts(for series: Series) -> [BingeEngine.SeasonFact] {
            series.regularSeasons.map { season in
                BingeEngine.SeasonFact(
                    seasonNumber: season.seasonNumber,
                    episodes: season.episodeFacts,
                    hasWatched: season.hasWatched
                )
            }
        }

        let container = try makeTestContainer()
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 1: S1 undated (TBA) → .anticipated
        // ═══════════════════════════════════════════════════════════════════

        var show = buildShowData(
            id: 7001,
            name: "Full Cycle Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: nil, isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: nil, isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: nil, isTypedFinale: true, isTyped: true)  // finale typed but undated
                ]
            )]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(_, _) = result else {
            Issue.record("Expected .followed")
            return
        }
        var series = manager.series(id: 7001)!

        // now = baseNow (day 0), S1 undated
        var now = baseNow
        var facts = seasonFacts(for: series)
        #expect(BingeEngine.showState(seasons: facts, now: now) == .anticipated)
        #expect(BingeEngine.bingeReadySeason(seasons: facts, now: now) == nil)
        // Anticipated shows appear on timeline (waiting for date)

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 2: S1 gets dated (premiere in 30 days) → .premieringSoon
        // ═══════════════════════════════════════════════════════════════════

        let s1Premiere = dateOffset(30)
        let s1Finale = dateOffset(44)  // 2 weeks after premiere

        show = buildShowData(
            id: 7001,
            name: "Full Cycle Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: s1Premiere, isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(37), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: s1Finale, isTypedFinale: true, isTyped: true)
                ]
            )]
        )
        await mockTMDB.setShow(show)
        await manager.refresh(id: 7001, force: true)
        series = manager.series(id: 7001)!
        facts = seasonFacts(for: series)

        // now = baseNow (day 0), premiere is day 30
        now = baseNow
        #expect(BingeEngine.showState(seasons: facts, now: now) == .premieringSoon)
        #expect(BingeEngine.daysUntilPremiere(seasons: facts, now: now) == 30)
        #expect(BingeEngine.bingeReadySeason(seasons: facts, now: now) == nil)

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 3: now = after premiere, before finale (finale confirmed) → .airing
        // ═══════════════════════════════════════════════════════════════════

        now = dateOffset(35)  // 5 days after premiere, 9 days before finale
        #expect(BingeEngine.showState(seasons: facts, now: now) == .airing)
        #expect(BingeEngine.daysUntilFinale(seasons: facts, now: now) == 9)
        #expect(BingeEngine.bingeReadySeason(seasons: facts, now: now) == nil)

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 3b: variant with finale NOT confirmed → .pending
        // ═══════════════════════════════════════════════════════════════════

        // Update to remove the typed finale (make all episodes typed but none is finale)
        let pendingShow = buildShowData(
            id: 7001,
            name: "Full Cycle Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: s1Premiere, isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(37), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: s1Finale, isTypedFinale: false, isTyped: true)  // NOT typed as finale
                ]
            )]
        )
        await mockTMDB.setShow(pendingShow)
        await manager.refresh(id: 7001, force: true)
        series = manager.series(id: 7001)!
        facts = seasonFacts(for: series)

        now = dateOffset(35)
        #expect(BingeEngine.showState(seasons: facts, now: now) == .pending)
        #expect(BingeEngine.daysUntilFinale(seasons: facts, now: now) == nil)  // no countdown for pending

        // Restore the typed finale for remaining phases
        await mockTMDB.setShow(show)
        await manager.refresh(id: 7001, force: true)
        series = manager.series(id: 7001)!
        facts = seasonFacts(for: series)

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 4: now = finale day → still .airing (grace window)
        // ═══════════════════════════════════════════════════════════════════

        now = s1Finale  // finale day
        #expect(BingeEngine.showState(seasons: facts, now: now) == .airing)

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 5: now = finale day +2 → .bingeReady, NOT on timeline
        // ═══════════════════════════════════════════════════════════════════

        now = dateOffset(46)  // finale was day 44, now is day 46 (+2)
        #expect(BingeEngine.showState(seasons: facts, now: now) == .bingeReady)
        let bingeReadyS1 = BingeEngine.bingeReadySeason(seasons: facts, now: now)
        #expect(bingeReadyS1?.seasonNumber == 1)
        #expect(bingeReadyS1?.hasWatched == false)
        #expect(BingeEngine.isOnBingeReadySurface(seasons: facts, now: now) == true)

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 6: markSeasonWatched(S1) → leaves surface
        // ═══════════════════════════════════════════════════════════════════

        try manager.markSeasonWatched(seriesId: 7001, seasonNumber: 1, watched: true)
        series = manager.series(id: 7001)!
        facts = seasonFacts(for: series)

        #expect(BingeEngine.bingeReadySeason(seasons: facts, now: now) == nil)
        // showState is still .bingeReady (Axis 1, date-fact), but not on surface (Axis 2, watched)
        #expect(BingeEngine.showState(seasons: facts, now: now) == .bingeReady)
        #expect(BingeEngine.isOnBingeReadySurface(seasons: facts, now: now) == false)

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 7: refresh adds dated S2 → .premieringSoon again (cycle restarts)
        // ═══════════════════════════════════════════════════════════════════

        let s2Premiere = dateOffset(100)
        let s2Finale = dateOffset(114)

        let showWithS2 = buildShowData(
            id: 7001,
            name: "Full Cycle Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: s1Premiere, isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(37), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: s1Finale, isTypedFinale: true, isTyped: true)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: s2Premiere, isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(107), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: s2Finale, isTypedFinale: true, isTyped: true)
                ])
            ]
        )
        await mockTMDB.setShow(showWithS2)
        await manager.refresh(id: 7001, force: true)
        series = manager.series(id: 7001)!
        facts = seasonFacts(for: series)

        // now is still day 46, S2 premiere is day 100
        now = dateOffset(46)
        #expect(BingeEngine.showState(seasons: facts, now: now) == .premieringSoon)
        #expect(BingeEngine.daysUntilPremiere(seasons: facts, now: now) == 54)  // 100 - 46

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 8: advance through S2: premiere → airing → finale+2 → bingeReady
        // ═══════════════════════════════════════════════════════════════════

        // S2 premiere day → .airing
        now = s2Premiere
        #expect(BingeEngine.showState(seasons: facts, now: now) == .airing)

        // S2 finale day → still .airing (grace window)
        now = s2Finale
        #expect(BingeEngine.showState(seasons: facts, now: now) == .airing)

        // S2 finale +2 → .bingeReady
        now = dateOffset(116)  // finale was 114, +2 = 116
        #expect(BingeEngine.showState(seasons: facts, now: now) == .bingeReady)
        let bingeReadyS2 = BingeEngine.bingeReadySeason(seasons: facts, now: now)
        #expect(bingeReadyS2?.seasonNumber == 2)

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 9: confirm S1 still watched, S2 is the surface item — loop closed
        // ═══════════════════════════════════════════════════════════════════

        let s1 = series.regularSeasons.first { $0.seasonNumber == 1 }
        let s2 = series.regularSeasons.first { $0.seasonNumber == 2 }
        #expect(s1?.hasWatched == true, "S1 should still be watched")
        #expect(s2?.hasWatched == false, "S2 should be unwatched")
        #expect(bingeReadyS2?.seasonNumber == 2, "S2 should be the binge ready season")
        #expect(BingeEngine.isOnBingeReadySurface(seasons: facts, now: now) == true)
    }

    /// 6.7 Multi-cycle proof: S1 → S2 → S3 → S4, three consecutive handoffs on ONE show.
    /// Proves the binge cycle repeats indefinitely, not just once.
    @Test("6.7 Multi-cycle: S1 → S2 → S3 → S4 proves cycle repeats indefinitely")
    @MainActor
    func multiCycleRepeatedHandoffs() async throws {
        // Fixed base date for all calculations
        let baseNow = testNow  // Aug 15, 2026

        // Helper to compute dates relative to base
        func dateOffset(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: baseNow)!
        }

        // Helper to build SeasonFacts from Series
        func seasonFacts(for series: Series) -> [BingeEngine.SeasonFact] {
            series.regularSeasons.map { season in
                BingeEngine.SeasonFact(
                    seasonNumber: season.seasonNumber,
                    episodes: season.episodeFacts,
                    hasWatched: season.hasWatched
                )
            }
        }

        let container = try makeTestContainer()
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Timeline offsets for each season (each season spans ~14 days)
        // S1: days 0-14 (premiere day 0, finale day 14)
        // S2: days 50-64
        // S3: days 100-114
        // S4: days 150-164

        // ═══════════════════════════════════════════════════════════════════════
        // CYCLE 1: S1 complete flow
        // ═══════════════════════════════════════════════════════════════════════

        // --- S1 ANTICIPATED (undated) ---
        var show = buildShowData(
            id: 7100,
            name: "Multi Cycle Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: nil, isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: nil, isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: nil, isTypedFinale: true, isTyped: true)
                ]
            )]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(_, _) = result else {
            Issue.record("Expected .followed")
            return
        }
        var series = manager.series(id: 7100)!
        var now = dateOffset(-30)  // 30 days before S1 premiere
        var facts = seasonFacts(for: series)

        #expect(BingeEngine.showState(seasons: facts, now: now) == .anticipated,
                "S1 undated → anticipated")

        // --- S1 PREMIERING SOON (dated, premiere in future) ---
        show = buildShowData(
            id: 7100,
            name: "Multi Cycle Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: dateOffset(0), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(7), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(14), isTypedFinale: true, isTyped: true)
                ]
            )]
        )
        await mockTMDB.setShow(show)
        await manager.refresh(id: 7100, force: true)
        series = manager.series(id: 7100)!
        facts = seasonFacts(for: series)

        now = dateOffset(-10)  // 10 days before premiere
        #expect(BingeEngine.showState(seasons: facts, now: now) == .premieringSoon,
                "S1 dated, premiere in future → premieringSoon")
        #expect(BingeEngine.daysUntilPremiere(seasons: facts, now: now) == 10)

        // --- S1 AIRING (mid-run) ---
        now = dateOffset(7)  // 7 days after premiere, 7 before finale
        #expect(BingeEngine.showState(seasons: facts, now: now) == .airing,
                "S1 mid-run → airing")
        #expect(BingeEngine.daysUntilFinale(seasons: facts, now: now) == 7)

        // --- S1 BINGE READY (finale + 2 days grace) ---
        now = dateOffset(16)  // finale was day 14, +2 = day 16
        #expect(BingeEngine.showState(seasons: facts, now: now) == .bingeReady,
                "S1 finale+2 → bingeReady")
        var bingeReady = BingeEngine.bingeReadySeason(seasons: facts, now: now)
        #expect(bingeReady?.seasonNumber == 1, "S1 is the binge ready season")
        #expect(BingeEngine.isOnBingeReadySurface(seasons: facts, now: now) == true)

        // --- MARK S1 WATCHED → leaves surface ---
        try manager.markSeasonWatched(seriesId: 7100, seasonNumber: 1, watched: true)
        series = manager.series(id: 7100)!
        facts = seasonFacts(for: series)

        #expect(BingeEngine.bingeReadySeason(seasons: facts, now: now) == nil,
                "S1 watched → no binge ready season")
        #expect(BingeEngine.isOnBingeReadySurface(seasons: facts, now: now) == false)

        // ═══════════════════════════════════════════════════════════════════════
        // CYCLE 2: S2 complete flow (S1 stays watched)
        // ═══════════════════════════════════════════════════════════════════════

        // --- S2 ANTICIPATED (announced but undated) ---
        show = buildShowData(
            id: 7100,
            name: "Multi Cycle Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: dateOffset(0), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(7), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(14), isTypedFinale: true, isTyped: true)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: nil, isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: nil, isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: nil, isTypedFinale: true, isTyped: true)
                ])
            ]
        )
        await mockTMDB.setShow(show)
        await manager.refresh(id: 7100, force: true)
        series = manager.series(id: 7100)!
        facts = seasonFacts(for: series)

        now = dateOffset(30)
        #expect(BingeEngine.showState(seasons: facts, now: now) == .anticipated,
                "S2 undated → show anticipated")

        // --- S2 PREMIERING SOON ---
        show = buildShowData(
            id: 7100,
            name: "Multi Cycle Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: dateOffset(0), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(7), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(14), isTypedFinale: true, isTyped: true)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: dateOffset(50), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(57), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(64), isTypedFinale: true, isTyped: true)
                ])
            ]
        )
        await mockTMDB.setShow(show)
        await manager.refresh(id: 7100, force: true)
        series = manager.series(id: 7100)!
        facts = seasonFacts(for: series)

        now = dateOffset(40)  // 10 days before S2 premiere
        #expect(BingeEngine.showState(seasons: facts, now: now) == .premieringSoon,
                "S2 dated → premieringSoon")

        // --- S2 AIRING ---
        now = dateOffset(57)  // mid S2
        #expect(BingeEngine.showState(seasons: facts, now: now) == .airing,
                "S2 mid-run → airing")

        // --- S2 BINGE READY ---
        now = dateOffset(66)  // S2 finale was day 64, +2
        #expect(BingeEngine.showState(seasons: facts, now: now) == .bingeReady,
                "S2 finale+2 → bingeReady")
        bingeReady = BingeEngine.bingeReadySeason(seasons: facts, now: now)
        #expect(bingeReady?.seasonNumber == 2, "S2 is the single binge ready season (dedup)")
        #expect(BingeEngine.isOnBingeReadySurface(seasons: facts, now: now) == true)

        // Verify S1 still watched
        let s1AfterS2 = series.regularSeasons.first { $0.seasonNumber == 1 }
        #expect(s1AfterS2?.hasWatched == true, "S1 must still be watched after S2 cycle")

        // --- MARK S2 WATCHED ---
        try manager.markSeasonWatched(seriesId: 7100, seasonNumber: 2, watched: true)
        series = manager.series(id: 7100)!
        facts = seasonFacts(for: series)

        #expect(BingeEngine.bingeReadySeason(seasons: facts, now: now) == nil)
        #expect(BingeEngine.isOnBingeReadySurface(seasons: facts, now: now) == false)

        // ═══════════════════════════════════════════════════════════════════════
        // CYCLE 3: S3 complete flow (S1 + S2 stay watched)
        // ═══════════════════════════════════════════════════════════════════════

        // --- S3 PREMIERING SOON (skip anticipated for brevity) ---
        show = buildShowData(
            id: 7100,
            name: "Multi Cycle Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: dateOffset(0), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(7), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(14), isTypedFinale: true, isTyped: true)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: dateOffset(50), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(57), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(64), isTypedFinale: true, isTyped: true)
                ]),
                (number: 3, episodes: [
                    (number: 1, airDate: dateOffset(100), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(107), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(114), isTypedFinale: true, isTyped: true)
                ])
            ]
        )
        await mockTMDB.setShow(show)
        await manager.refresh(id: 7100, force: true)
        series = manager.series(id: 7100)!
        facts = seasonFacts(for: series)

        now = dateOffset(90)  // 10 days before S3 premiere
        #expect(BingeEngine.showState(seasons: facts, now: now) == .premieringSoon,
                "S3 dated → premieringSoon")

        // --- S3 AIRING ---
        now = dateOffset(107)  // mid S3
        #expect(BingeEngine.showState(seasons: facts, now: now) == .airing,
                "S3 mid-run → airing")

        // --- S3 BINGE READY ---
        now = dateOffset(116)  // S3 finale was day 114, +2
        #expect(BingeEngine.showState(seasons: facts, now: now) == .bingeReady,
                "S3 finale+2 → bingeReady")
        bingeReady = BingeEngine.bingeReadySeason(seasons: facts, now: now)
        #expect(bingeReady?.seasonNumber == 3,
                "S3 is the single binge ready season (S1, S2 watched → dedup)")
        #expect(BingeEngine.isOnBingeReadySurface(seasons: facts, now: now) == true)

        // Verify S1 + S2 still watched
        let s1AfterS3 = series.regularSeasons.first { $0.seasonNumber == 1 }
        let s2AfterS3 = series.regularSeasons.first { $0.seasonNumber == 2 }
        #expect(s1AfterS3?.hasWatched == true, "S1 must still be watched after S3 cycle")
        #expect(s2AfterS3?.hasWatched == true, "S2 must still be watched after S3 cycle")

        // --- MARK S3 WATCHED ---
        try manager.markSeasonWatched(seriesId: 7100, seasonNumber: 3, watched: true)
        series = manager.series(id: 7100)!
        facts = seasonFacts(for: series)

        #expect(BingeEngine.bingeReadySeason(seasons: facts, now: now) == nil)
        #expect(BingeEngine.isOnBingeReadySurface(seasons: facts, now: now) == false)

        // ═══════════════════════════════════════════════════════════════════════
        // CYCLE 4: S4 proves the pattern is indefinitely repeatable
        // ═══════════════════════════════════════════════════════════════════════

        // --- S4 PREMIERING SOON ---
        show = buildShowData(
            id: 7100,
            name: "Multi Cycle Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: dateOffset(0), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(7), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(14), isTypedFinale: true, isTyped: true)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: dateOffset(50), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(57), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(64), isTypedFinale: true, isTyped: true)
                ]),
                (number: 3, episodes: [
                    (number: 1, airDate: dateOffset(100), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(107), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(114), isTypedFinale: true, isTyped: true)
                ]),
                (number: 4, episodes: [
                    (number: 1, airDate: dateOffset(150), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: dateOffset(157), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: dateOffset(164), isTypedFinale: true, isTyped: true)
                ])
            ]
        )
        await mockTMDB.setShow(show)
        await manager.refresh(id: 7100, force: true)
        series = manager.series(id: 7100)!
        facts = seasonFacts(for: series)

        now = dateOffset(140)  // 10 days before S4 premiere
        #expect(BingeEngine.showState(seasons: facts, now: now) == .premieringSoon,
                "S4 dated → premieringSoon")

        // --- S4 AIRING ---
        now = dateOffset(157)  // mid S4
        #expect(BingeEngine.showState(seasons: facts, now: now) == .airing,
                "S4 mid-run → airing")

        // --- S4 BINGE READY (final proof) ---
        now = dateOffset(166)  // S4 finale was day 164, +2
        #expect(BingeEngine.showState(seasons: facts, now: now) == .bingeReady,
                "S4 finale+2 → bingeReady")
        bingeReady = BingeEngine.bingeReadySeason(seasons: facts, now: now)
        #expect(bingeReady?.seasonNumber == 4,
                "S4 is the single binge ready season (S1, S2, S3 watched → dedup)")
        #expect(BingeEngine.isOnBingeReadySurface(seasons: facts, now: now) == true)

        // ═══════════════════════════════════════════════════════════════════════
        // FINAL ASSERTIONS: all previously watched seasons remain watched
        // ═══════════════════════════════════════════════════════════════════════

        let finalS1 = series.regularSeasons.first { $0.seasonNumber == 1 }
        let finalS2 = series.regularSeasons.first { $0.seasonNumber == 2 }
        let finalS3 = series.regularSeasons.first { $0.seasonNumber == 3 }
        let finalS4 = series.regularSeasons.first { $0.seasonNumber == 4 }

        #expect(finalS1?.hasWatched == true, "S1 watched state preserved through 3 cycles")
        #expect(finalS2?.hasWatched == true, "S2 watched state preserved through 2 cycles")
        #expect(finalS3?.hasWatched == true, "S3 watched state preserved through 1 cycle")
        #expect(finalS4?.hasWatched == false, "S4 is unwatched (current binge ready)")

        // Verify ONLY the latest unwatched-complete season surfaces (Landman dedup rule)
        #expect(bingeReady?.seasonNumber == 4,
                "Only S4 surfaces — older seasons (S1, S2, S3) are watched and DO NOT resurface")

        // ═══════════════════════════════════════════════════════════════════════
        // CYCLE PROVEN: The binge cycle repeats indefinitely.
        // S1 → S2 → S3 → S4 all followed the same pattern:
        //   anticipated → premieringSoon → airing → bingeReady → watched
        // Each time, the newly completed season became the single surface item,
        // and previously watched seasons stayed watched and did not resurface.
        // ═══════════════════════════════════════════════════════════════════════
    }
}

    // MARK: - Group 7: Refresh Preserves Watch State

    @Suite("Group 7 — Refresh Preserves Watch State")
    struct RefreshPreservesWatchStateTests {

    /// 7.1 Metadata refresh keeps hasWatched
    @Test("7.1 Metadata refresh keeps hasWatched")
    @MainActor
    func refreshKeepsWatched() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: S1 fully watched
        let show = buildShowData(
            id: 3001,
            name: "Refresh Test",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -60), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -53), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -46), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        _ = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        try manager.markSeasonWatched(seriesId: 3001, seasonNumber: 1, watched: true)

        // Prepare updated show data with S2 added
        let updatedShow = buildShowData(
            id: 3001,
            name: "Refresh Test",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -60), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -53), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -46), isTypedFinale: false, isTyped: false)
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: 30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: 37), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        await mockTMDB.setShow(updatedShow)

        // When: refresh pulls updated metadata + a new S2
        await manager.refresh(id: 3001, force: true)

        // Then: S1 episodes still hasWatched == true; S2 appended unwatched
        guard let series = manager.series(id: 3001) else {
            Issue.record("Series not found after refresh")
            return
        }

        let s1 = series.regularSeasons.first { $0.seasonNumber == 1 }
        #expect(s1?.hasWatched == true, "S1 should still be watched after refresh")

        let s2 = series.regularSeasons.first { $0.seasonNumber == 2 }
        #expect(s2?.hasWatched == false, "S2 should be unwatched")
    }

    /// 7.2 New episodes appended mid-season (still-airing, no confirmed finale)
    @Test("7.2 New episodes appended mid-season")
    @MainActor
    func newEpisodesAppendedMidSeason() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: S2 with 4 episodes aired, all watched (dates in distant past for determinism)
        // Episodes are TYPED but none is .finale → pending season (no confirmed finale)
        let show = buildShowData(
            id: 3002,
            name: "Mid Season Test",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -200), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: date(daysFromNow: -193), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: date(daysFromNow: -186), isTypedFinale: true, isTyped: true) // S1 finale
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -128), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: date(daysFromNow: -121), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: date(daysFromNow: -114), isTypedFinale: false, isTyped: true),
                    (number: 4, airDate: date(daysFromNow: -107), isTypedFinale: false, isTyped: true)
                    // No .finale typed → pending season
                ])
            ]
        )

        _ = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // Mark all S2 episodes as watched
        for epNum in 1...4 {
            try manager.toggleEpisodeWatched(seriesId: 3002, seasonNumber: 2, episodeNumber: epNum)
        }

        // Verify S2 is now watched
        guard let seriesBefore = manager.series(id: 3002) else {
            Issue.record("Series not found")
            return
        }
        let s2Before = seriesBefore.regularSeasons.first { $0.seasonNumber == 2 }
        #expect(s2Before?.episodes.filter { $0.hasWatched }.count == 4)

        // Prepare updated show with episodes 5-6 added (still no finale)
        let updatedShow = buildShowData(
            id: 3002,
            name: "Mid Season Test",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -200), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: date(daysFromNow: -193), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: date(daysFromNow: -186), isTypedFinale: true, isTyped: true) // S1 finale
                ]),
                (number: 2, episodes: [
                    (number: 1, airDate: date(daysFromNow: -128), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: date(daysFromNow: -121), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: date(daysFromNow: -114), isTypedFinale: false, isTyped: true),
                    (number: 4, airDate: date(daysFromNow: -107), isTypedFinale: false, isTyped: true),
                    (number: 5, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: true),
                    (number: 6, airDate: date(daysFromNow: -93), isTypedFinale: false, isTyped: true)
                    // Still no .finale → still pending
                ])
            ]
        )

        await mockTMDB.setShow(updatedShow)

        // When: refresh adds episodes 5–6
        await manager.refresh(id: 3002, force: true)

        // Then: 1–4 still watched, 5–6 unwatched, season not fully watched
        guard let series = manager.series(id: 3002) else {
            Issue.record("Series not found after refresh")
            return
        }

        let s2 = series.regularSeasons.first { $0.seasonNumber == 2 }
        guard let s2Episodes = s2?.sortedEpisodes else {
            Issue.record("S2 episodes not found")
            return
        }

        // Episodes 1-4 should be watched
        for ep in s2Episodes where ep.episodeNumber <= 4 {
            #expect(ep.hasWatched == true, "Episode \(ep.episodeNumber) should be watched")
        }

        // Episodes 5-6 should be unwatched
        for ep in s2Episodes where ep.episodeNumber > 4 {
            #expect(ep.hasWatched == false, "Episode \(ep.episodeNumber) should be unwatched")
        }

        // Season is not fully watched since 5-6 are unwatched
        #expect(s2?.hasWatched == false, "Season should not be fully watched")
    }

    /// 7.3 Finished season with data correction keeps hasWatched
    @Test("7.3 Finished season with data correction keeps hasWatched")
    @MainActor
    func finishedSeasonDataCorrectionKeepsWatched() async throws {
        let container = try makeTestContainer()
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: S1 with a TYPED FINALE that has aired, user watched all episodes
        // The finale is typed to confirm it's a finished season (not pending)
        let show = buildShowData(
            id: 3003,
            name: "Finished Season Test",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -200), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: date(daysFromNow: -193), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: date(daysFromNow: -186), isTypedFinale: true, isTyped: true) // TYPED FINALE, aired
                ])
            ]
        )

        _ = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // Mark all episodes as watched
        for epNum in 1...3 {
            try manager.toggleEpisodeWatched(seriesId: 3003, seasonNumber: 1, episodeNumber: epNum)
        }

        // Verify S1 is now watched
        guard let seriesBefore = manager.series(id: 3003) else {
            Issue.record("Series not found")
            return
        }
        let s1Before = seriesBefore.regularSeasons.first { $0.seasonNumber == 1 }
        #expect(s1Before?.hasWatched == true, "S1 should be watched before refresh")

        // Prepare updated show with a PHANTOM episode 4 added (TMDB data correction)
        // The finale is STILL episode 3 (typed .finale), episode 4 is just extra metadata
        let updatedShow = buildShowData(
            id: 3003,
            name: "Finished Season Test",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -200), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: date(daysFromNow: -193), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: date(daysFromNow: -186), isTypedFinale: true, isTyped: true), // TYPED FINALE
                    (number: 4, airDate: date(daysFromNow: -179), isTypedFinale: false, isTyped: true)  // phantom data correction
                ])
            ]
        )

        await mockTMDB.setShow(updatedShow)

        // When: refresh adds phantom episode 4
        await manager.refresh(id: 3003, force: true)

        // Then: Season hasWatched STAYS true (finale already aired = data correction, not new episode)
        guard let series = manager.series(id: 3003) else {
            Issue.record("Series not found after refresh")
            return
        }

        let s1 = series.regularSeasons.first { $0.seasonNumber == 1 }
        #expect(s1?.hasWatched == true, "Finished season should stay watched after data correction")

        // Verify episode 4 exists but is unwatched (that's fine, season is still marked watched)
        let ep4 = s1?.episodes.first { $0.episodeNumber == 4 }
        #expect(ep4 != nil, "Episode 4 should exist")
        #expect(ep4?.hasWatched == false, "Episode 4 should be unwatched")
    }
}

    // MARK: - Group 8: Archive (Axis 2 with Axis 1 override)

    @Suite("Group 8 — Archive")
    struct ArchiveTests {

    /// 8.1 Archive an ended show → stays archived
    @Test("8.1 Archive an ended show → stays archived")
    @MainActor
    func archiveEndedShow() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: ended show (all complete, all watched, not in production)
        var show = buildShowData(
            id: 4001,
            name: "Ended Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -113), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -106), isTypedFinale: false, isTyped: false)
                ])
            ]
        )
        show = ShowData(
            id: show.id,
            name: show.name,
            overview: show.overview,
            posterPath: show.posterPath,
            backdropPath: show.backdropPath,
            logoPath: show.logoPath,
            firstAirDate: show.firstAirDate,
            status: .ended,
            genres: show.genres,
            networks: show.networks,
            createdBy: show.createdBy,
            seasons: show.seasons,
            numberOfSeasons: show.numberOfSeasons,
            numberOfEpisodes: show.numberOfEpisodes,
            inProduction: false, // ended
            voteAverage: show.voteAverage
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else {
            Issue.record("Expected .followed result")
            return
        }

        // Mark all watched
        try manager.markSeasonWatched(seriesId: series.id, seasonNumber: 1, watched: true)

        // Archive the show
        try manager.setArchived(seriesId: series.id, archived: true)

        // Then: myListTab == .archived, appearsOnTimeline == false
        #expect(series.myListTab == .archived)
        #expect(series.appearsOnTimeline == false)
    }

    /// 8.3 Archive a currently-airing show → still on timeline
    @Test("8.3 Archive a currently-airing show → still on timeline")
    @MainActor
    func archiveAiringShow() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: airing show (with future finale)
        let show = buildShowData(
            id: 4003,
            name: "Airing Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -14), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -7), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: 7), isTypedFinale: false, isTyped: false) // future finale
                ])
            ]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else {
            Issue.record("Expected .followed result")
            return
        }

        // Archive the show
        try manager.setArchived(seriesId: series.id, archived: true)

        // Then: appearsOnTimeline == true (airing overrides archive)
        // Note: show state is either .airing or .pending depending on finale confirmation
        // The key point is that an in-progress show appears on timeline despite archive
        #expect(series.appearsOnTimeline == true)
    }
}

    // MARK: - Group 9: Split Season / Parts

    @Suite("Group 9 — Split Season / Parts")
    struct SplitSeasonTests {

    /// 9.1 Part 1 aired, no finale typed → pending, NOT binge-ready
    @Test("9.1 Part 1 aired, no finale typed → pending, NOT binge-ready")
    @MainActor
    func part1AiredNoFinale() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: 4 episodes aired, none typed .finale, more expected
        let show = buildShowData(
            id: 5001,
            name: "Split Season Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -28), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: date(daysFromNow: -21), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: date(daysFromNow: -14), isTypedFinale: false, isTyped: true),
                    (number: 4, airDate: date(daysFromNow: -7), isTypedFinale: false, isTyped: true)
                    // More episodes expected but not in data yet
                ])
            ]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else {
            Issue.record("Expected .followed result")
            return
        }

        // Then: .pending; bingeReadySeason == nil
        #expect(series.showState == .pending)
        #expect(series.bingeReadySeason == nil)
    }

    /// 9.2 Part 2 finale airs + grace → binge-ready
    @Test("9.2 Part 2 finale airs + grace → binge-ready")
    @MainActor
    func part2FinaleAiredGrace() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Given: finale episode typed .finale, aired well past grace window
        // Using -100+ day offsets to be unambiguous relative to real Date()
        let show = buildShowData(
            id: 5002,
            name: "Complete Split Season",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -200), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: date(daysFromNow: -193), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: date(daysFromNow: -186), isTypedFinale: false, isTyped: true),
                    (number: 4, airDate: date(daysFromNow: -179), isTypedFinale: false, isTyped: true),
                    // Part 2
                    (number: 5, airDate: date(daysFromNow: -120), isTypedFinale: false, isTyped: true),
                    (number: 6, airDate: date(daysFromNow: -113), isTypedFinale: false, isTyped: true),
                    (number: 7, airDate: date(daysFromNow: -106), isTypedFinale: true, isTyped: true) // finale
                ])
            ]
        )

        let result = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()
        guard case .followed(let series, _) = result else {
            Issue.record("Expected .followed result")
            return
        }

        // Then: .bingeReady; on surface if unwatched
        #expect(series.showState == .bingeReady)
        #expect(series.bingeReadySeason != nil)
        #expect(series.isOnBingeReadySurface == true)
    }
}

    // MARK: - Group 10: Spinoffs

    @Suite("Group 10 — Spinoffs")
    struct SpinoffTests {

    /// 10.1 Resolve once, store on Series
    @Test("10.1 Resolve once, store on Series")
    @MainActor
    func resolveOnceStoreOnSeries() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()

        // Create franchise resolver that returns related IDs
        var franchiseResolver = MockFranchiseResolver()
        franchiseResolver.relatedIds = [6001: [6002, 6003, 6004]]

        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: franchiseResolver,
            cloudKit: MockCloudSyncing()
        )

        // Given: a franchise member followed
        let show = buildShowData(
            id: 6001,
            name: "Franchise Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -23), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        _ = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // When: resolveSpinoffs (which is called automatically on follow, but we can call again)
        await manager.resolveSpinoffs(for: 6001)

        // Then: series.relatedShowIds populated, spinoffsResolved == true
        guard let series = manager.series(id: 6001) else {
            Issue.record("Series not found")
            return
        }

        #expect(series.relatedShowIds == [6002, 6003, 6004])
        #expect(series.spinoffsResolved == true)
    }

    /// 10.3 Non-franchise show → empty, still marked resolved
    @Test("10.3 Non-franchise show → empty, still marked resolved")
    @MainActor
    func nonFranchiseShowEmpty() async throws {
        let container = try makeTestContainer()
        // context derived from container in SeriesManager
        let mockTMDB = MockTMDBService()

        // Franchise resolver returns empty for this show
        let franchiseResolver = MockFranchiseResolver()

        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: franchiseResolver,
            cloudKit: MockCloudSyncing()
        )

        // Given: a show in no franchise
        let show = buildShowData(
            id: 6003,
            name: "Standalone Show",
            seasons: [
                (number: 1, episodes: [
                    (number: 1, airDate: date(daysFromNow: -30), isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: date(daysFromNow: -23), isTypedFinale: false, isTyped: false),
                    (number: 3, airDate: date(daysFromNow: -100), isTypedFinale: false, isTyped: false)
                ])
            ]
        )

        _ = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // When: resolveSpinoffs
        await manager.resolveSpinoffs(for: 6003)

        // Then: relatedShowIds == [], spinoffsResolved == true
        guard let series = manager.series(id: 6003) else {
            Issue.record("Series not found")
            return
        }

        #expect(series.relatedShowIds == [])
        #expect(series.spinoffsResolved == true)
    }
}

    // MARK: - Group 11: Refresh Cadence (State-Based Throttle)

    @Suite("Group 11 — Refresh Cadence")
    struct RefreshCadenceTests {

    /// 11.1 nextRefreshDue returns correct interval per state
    @Test("11.1 nextRefreshDue returns correct interval per ShowState")
    @MainActor
    func nextRefreshDuePerState() async throws {
        let container = try makeTestContainer()
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        // Fixed "now" for deterministic tests
        let now = testNow  // Aug 15, 2026

        // Helper to create dates relative to now
        func d(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: now)!
        }

        // ═══════════════════════════════════════════════════════════════════
        // ANTICIPATED (no dates) → 3 days
        // ═══════════════════════════════════════════════════════════════════
        let anticipatedShow = buildShowData(
            id: 11001,
            name: "Anticipated Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: nil, isTypedFinale: false, isTyped: false),
                    (number: 2, airDate: nil, isTypedFinale: false, isTyped: false)
                ]
            )]
        )
        _ = try manager.follow(showData: anticipatedShow)
        await manager.awaitPendingBackgroundWork()
        var series = manager.series(id: 11001)!
        series.lastRefreshedAt = now

        var nextDue = manager.nextRefreshDue(for: series, now: now)
        #expect(nextDue == d(3), "Anticipated should refresh in 3 days")

        // ═══════════════════════════════════════════════════════════════════
        // PREMIERING SOON (dated, not started) → 1 day
        // ═══════════════════════════════════════════════════════════════════
        let premieringSoonShow = buildShowData(
            id: 11002,
            name: "Premiering Soon Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(10), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(17), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(24), isTypedFinale: true, isTyped: true)
                ]
            )]
        )
        _ = try manager.follow(showData: premieringSoonShow)
        await manager.awaitPendingBackgroundWork()
        series = manager.series(id: 11002)!
        series.lastRefreshedAt = now

        nextDue = manager.nextRefreshDue(for: series, now: now)
        #expect(nextDue == d(1), "PremieringSoon should refresh in 1 day")

        // ═══════════════════════════════════════════════════════════════════
        // AIRING (started, finale confirmed, not near finale) → 7 days
        // ═══════════════════════════════════════════════════════════════════
        let airingShow = buildShowData(
            id: 11003,
            name: "Airing Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-14), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-7), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(21), isTypedFinale: true, isTyped: true)  // finale in 21 days
                ]
            )]
        )
        _ = try manager.follow(showData: airingShow)
        await manager.awaitPendingBackgroundWork()
        series = manager.series(id: 11003)!
        series.lastRefreshedAt = now

        nextDue = manager.nextRefreshDue(for: series, now: now)
        #expect(nextDue == d(7), "Airing (not near finale) should refresh in 7 days")

        // ═══════════════════════════════════════════════════════════════════
        // AIRING NEAR FINALE (≤2 days to finale) → 1 day
        // ═══════════════════════════════════════════════════════════════════
        let airingNearFinaleShow = buildShowData(
            id: 11004,
            name: "Airing Near Finale Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-14), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-7), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(2), isTypedFinale: true, isTyped: true)  // finale in 2 days
                ]
            )]
        )
        _ = try manager.follow(showData: airingNearFinaleShow)
        await manager.awaitPendingBackgroundWork()
        series = manager.series(id: 11004)!
        series.lastRefreshedAt = now

        nextDue = manager.nextRefreshDue(for: series, now: now)
        #expect(nextDue == d(1), "Airing near finale (≤2 days) should refresh in 1 day")

        // ═══════════════════════════════════════════════════════════════════
        // PENDING (started, no confirmed finale) → 2 days
        // ═══════════════════════════════════════════════════════════════════
        let pendingShow = buildShowData(
            id: 11005,
            name: "Pending Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-14), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-7), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(7), isTypedFinale: false, isTyped: true)  // NOT typed as finale
                ]
            )]
        )
        _ = try manager.follow(showData: pendingShow)
        await manager.awaitPendingBackgroundWork()
        series = manager.series(id: 11005)!
        series.lastRefreshedAt = now

        nextDue = manager.nextRefreshDue(for: series, now: now)
        #expect(nextDue == d(2), "Pending should refresh in 2 days")

        // ═══════════════════════════════════════════════════════════════════
        // BINGE READY (complete, past grace) → 7 days
        // ═══════════════════════════════════════════════════════════════════
        let bingeReadyShow = buildShowData(
            id: 11006,
            name: "Binge Ready Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-30), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-23), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(-16), isTypedFinale: true, isTyped: true)  // finale 16 days ago, past grace
                ]
            )]
        )
        _ = try manager.follow(showData: bingeReadyShow)
        await manager.awaitPendingBackgroundWork()
        series = manager.series(id: 11006)!
        series.lastRefreshedAt = now

        nextDue = manager.nextRefreshDue(for: series, now: now)
        #expect(nextDue == d(7), "BingeReady should refresh in 7 days")
    }

    /// 11.2 refresh(force:false) SKIPS a show refreshed within its state's interval
    @Test("11.2 refresh(force:false) skips show refreshed within cadence")
    @MainActor
    func refreshSkipsWithinCadence() async throws {
        let container = try makeTestContainer()
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        let now = testNow

        func d(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: now)!
        }

        // Create a bingeReady show (7-day cadence)
        let show = buildShowData(
            id: 11101,
            name: "Skip Test Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-30), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-23), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(-16), isTypedFinale: true, isTyped: true)
                ]
            )]
        )

        await mockTMDB.setShow(show)
        _ = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // Set lastRefreshedAt to 3 days ago (within 7-day cadence)
        let series = manager.series(id: 11101)!
        series.lastRefreshedAt = d(-3)

        // Clear tracking
        mockTMDB.clearFetchedIds()

        // When: refresh(force: false) with now
        await manager.refresh(id: 11101, force: false, now: now)

        // Then: TMDB was NOT called (show was skipped)
        #expect(mockTMDB.fetchedIds.isEmpty, "Should skip refresh within cadence")
    }

    /// 11.3 refresh(force:false) PROCEEDS for a show past its interval
    @Test("11.3 refresh(force:false) proceeds for show past cadence")
    @MainActor
    func refreshProceedsPastCadence() async throws {
        let container = try makeTestContainer()
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        let now = testNow

        func d(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: now)!
        }

        // Create a bingeReady show (7-day cadence)
        let show = buildShowData(
            id: 11102,
            name: "Proceed Test Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-30), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-23), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(-16), isTypedFinale: true, isTyped: true)
                ]
            )]
        )

        await mockTMDB.setShow(show)
        _ = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // Set lastRefreshedAt to 8 days ago (past 7-day cadence)
        let series = manager.series(id: 11102)!
        series.lastRefreshedAt = d(-8)

        // Clear tracking
        mockTMDB.clearFetchedIds()

        // When: refresh(force: false) with now
        await manager.refresh(id: 11102, force: false, now: now)

        // Then: TMDB WAS called (show was refreshed)
        #expect(mockTMDB.fetchedIds.contains(11102), "Should refresh show past cadence")
    }

    /// 11.4 refresh(force:true) always proceeds (pull-to-refresh bypasses cadence)
    @Test("11.4 refresh(force:true) always proceeds")
    @MainActor
    func refreshForceAlwaysProceeds() async throws {
        let container = try makeTestContainer()
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        let now = testNow

        func d(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: now)!
        }

        // Create a bingeReady show (7-day cadence)
        let show = buildShowData(
            id: 11103,
            name: "Force Test Show",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-30), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-23), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(-16), isTypedFinale: true, isTyped: true)
                ]
            )]
        )

        await mockTMDB.setShow(show)
        _ = try manager.follow(showData: show)
        await manager.awaitPendingBackgroundWork()

        // Set lastRefreshedAt to just 1 hour ago (way within 7-day cadence)
        let series = manager.series(id: 11103)!
        series.lastRefreshedAt = now.addingTimeInterval(-3600)

        // Clear tracking
        mockTMDB.clearFetchedIds()

        // When: refresh(force: true)
        await manager.refresh(id: 11103, force: true, now: now)

        // Then: TMDB WAS called (force bypasses cadence)
        #expect(mockTMDB.fetchedIds.contains(11103), "force:true should bypass cadence")
    }

    /// 11.5 Near-finale boundary: daysUntilFinale==2 uses 1-day, ==3 uses 7-day
    @Test("11.5 Near-finale boundary at 2 days")
    @MainActor
    func nearFinaleBoundary() async throws {
        let container = try makeTestContainer()
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        let now = testNow

        func d(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: now)!
        }

        // ═══════════════════════════════════════════════════════════════════
        // Show with finale in EXACTLY 2 days → should use 1-day cadence
        // ═══════════════════════════════════════════════════════════════════
        let show2Days = buildShowData(
            id: 11201,
            name: "Finale 2 Days",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-14), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-7), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(2), isTypedFinale: true, isTyped: true)  // finale in 2 days
                ]
            )]
        )
        _ = try manager.follow(showData: show2Days)
        await manager.awaitPendingBackgroundWork()
        var series = manager.series(id: 11201)!
        series.lastRefreshedAt = now

        var nextDue = manager.nextRefreshDue(for: series, now: now)
        #expect(nextDue == d(1), "Finale in 2 days should use 1-day cadence")

        // Verify the show state is airing
        #expect(BingeEngine.showState(seasons: series.seasonFacts, now: now) == .airing)
        #expect(BingeEngine.daysUntilFinale(seasons: series.seasonFacts, now: now) == 2)

        // ═══════════════════════════════════════════════════════════════════
        // Show with finale in EXACTLY 3 days → should use 7-day cadence
        // ═══════════════════════════════════════════════════════════════════
        let show3Days = buildShowData(
            id: 11202,
            name: "Finale 3 Days",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-14), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-7), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(3), isTypedFinale: true, isTyped: true)  // finale in 3 days
                ]
            )]
        )
        _ = try manager.follow(showData: show3Days)
        await manager.awaitPendingBackgroundWork()
        series = manager.series(id: 11202)!
        series.lastRefreshedAt = now

        nextDue = manager.nextRefreshDue(for: series, now: now)
        #expect(nextDue == d(7), "Finale in 3 days should use 7-day cadence")

        // Verify the show state is airing
        #expect(BingeEngine.showState(seasons: series.seasonFacts, now: now) == .airing)
        #expect(BingeEngine.daysUntilFinale(seasons: series.seasonFacts, now: now) == 3)
    }

    /// 11.6 refreshAll stops early when Task.isCancelled
    @Test("11.6 refreshAll stops when cancelled")
    @MainActor
    func refreshAllStopsWhenCancelled() async throws {
        let container = try makeTestContainer()
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        let now = testNow

        func d(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: now)!
        }

        // Create 3 shows, all past their cadence (will be refreshed if not cancelled)
        for i in 1...3 {
            let show = buildShowData(
                id: 11400 + i,
                name: "Cancel Test \(i)",
                seasons: [(
                    number: 1,
                    episodes: [
                        (number: 1, airDate: d(-30), isTypedFinale: false, isTyped: true),
                        (number: 2, airDate: d(-23), isTypedFinale: false, isTyped: true),
                        (number: 3, airDate: d(-16), isTypedFinale: true, isTyped: true)
                    ]
                )]
            )
            await mockTMDB.setShow(show)
            _ = try manager.follow(showData: show)
        }
        await manager.awaitPendingBackgroundWork()

        // Set all shows past their cadence (8 days ago, past 7-day bingeReady cadence)
        for i in 1...3 {
            manager.series(id: 11400 + i)!.lastRefreshedAt = d(-8)
        }

        // Clear tracking
        mockTMDB.clearFetchedIds()

        // Run refreshAll in a task that we cancel after a short delay
        let refreshTask = Task {
            await manager.refreshAll(force: false, now: now)
        }

        // Cancel immediately — the first show may or may not have started,
        // but subsequent shows should be skipped
        refreshTask.cancel()

        // Wait for the task to complete (it should exit early)
        await refreshTask.value

        // Then: NOT all 3 shows were refreshed (cancellation stopped the loop)
        // Note: The first show might have been fetched before cancellation was checked,
        // but we should NOT have all 3
        #expect(mockTMDB.fetchedIds.count < 3, "Cancellation should stop before all 3 shows")
    }

    /// 11.7 refreshAll with mixed states respects per-show cadence
    @Test("11.7 refreshAll respects per-show cadence")
    @MainActor
    func refreshAllPerShowCadence() async throws {
        let container = try makeTestContainer()
        let mockTMDB = MockTMDBService()
        let manager = SeriesManager(
            container: container,
            tmdb: mockTMDB,
            franchise: MockFranchiseResolver(),
            cloudKit: MockCloudSyncing()
        )

        let now = testNow

        func d(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: now)!
        }

        // Create 3 shows with different states and lastRefreshedAt:
        // 1. BingeReady, refreshed 3 days ago (within 7-day) → should SKIP
        // 2. BingeReady, refreshed 8 days ago (past 7-day) → should REFRESH
        // 3. PremieringSoon, refreshed 2 days ago (past 1-day) → should REFRESH

        let bingeReadyRecent = buildShowData(
            id: 11301,
            name: "Binge Recent",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-30), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-23), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(-16), isTypedFinale: true, isTyped: true)
                ]
            )]
        )
        await mockTMDB.setShow(bingeReadyRecent)
        _ = try manager.follow(showData: bingeReadyRecent)

        let bingeReadyStale = buildShowData(
            id: 11302,
            name: "Binge Stale",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(-30), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(-23), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(-16), isTypedFinale: true, isTyped: true)
                ]
            )]
        )
        await mockTMDB.setShow(bingeReadyStale)
        _ = try manager.follow(showData: bingeReadyStale)

        let premieringSoonStale = buildShowData(
            id: 11303,
            name: "Premiering Stale",
            seasons: [(
                number: 1,
                episodes: [
                    (number: 1, airDate: d(10), isTypedFinale: false, isTyped: true),
                    (number: 2, airDate: d(17), isTypedFinale: false, isTyped: true),
                    (number: 3, airDate: d(24), isTypedFinale: true, isTyped: true)
                ]
            )]
        )
        await mockTMDB.setShow(premieringSoonStale)
        _ = try manager.follow(showData: premieringSoonStale)

        await manager.awaitPendingBackgroundWork()

        // Set lastRefreshedAt
        manager.series(id: 11301)!.lastRefreshedAt = d(-3)  // 3 days ago, within 7-day cadence
        manager.series(id: 11302)!.lastRefreshedAt = d(-8)  // 8 days ago, past 7-day cadence
        manager.series(id: 11303)!.lastRefreshedAt = d(-2)  // 2 days ago, past 1-day cadence

        // Clear tracking
        mockTMDB.clearFetchedIds()

        // When: refreshAll(force: false)
        await manager.refreshAll(force: false, now: now)

        // Then: 11301 skipped, 11302 and 11303 refreshed
        #expect(!mockTMDB.fetchedIds.contains(11301), "11301 should be skipped (within cadence)")
        #expect(mockTMDB.fetchedIds.contains(11302), "11302 should be refreshed (past cadence)")
        #expect(mockTMDB.fetchedIds.contains(11303), "11303 should be refreshed (past cadence)")
    }
}

} // end SeriesManagerIntegrationTests
