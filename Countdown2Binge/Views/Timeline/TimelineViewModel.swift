//
//  TimelineViewModel.swift
//  Countdown2Binge
//
//  Manages state for the Timeline screen.
//  Fetches followed shows and categorizes them by lifecycle state.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class TimelineViewModel {
    // MARK: - State

    private(set) var followedShows: [ShowData] = []
    private(set) var isLoading = false
    private(set) var lastRefreshedAt: Date? = nil

    // MARK: - Categorized Shows

    /// Shows currently releasing episodes WITH a known finale date
    /// (sorted by finale date, soonest first)
    var airingNowShows: [ShowData] {
        followedShows
            .filter { $0.timelineCategory == .airingNow && $0.daysUntilFinale != nil }
            .sorted { lhs, rhs in
                guard let l = lhs.daysUntilFinale, let r = rhs.daysUntilFinale else {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return l < r
            }
    }

    /// Shows that are airing or premiering soon but have NO confirmed finale date
    /// Sorted: pre-premiere shows by days until premiere, then already-airing shows alphabetically
    var pendingShows: [ShowData] {
        let airingNoFinale = followedShows.filter {
            $0.timelineCategory == .airingNow && $0.daysUntilFinale == nil
        }
        let premieringNoFinale = followedShows.filter {
            $0.timelineCategory == .premieringSoon && !hasConfirmedFinale($0)
        }

        return (airingNoFinale + premieringNoFinale).sorted { lhs, rhs in
            // Pre-premiere shows come after, sorted by days to premiere
            let lhsPremiered = hasPremiered(lhs)
            let rhsPremiered = hasPremiered(rhs)

            if lhsPremiered != rhsPremiered {
                // Shows that haven't premiered come first (sorted by premiere date)
                return !lhsPremiered
            }

            if !lhsPremiered && !rhsPremiered {
                // Both haven't premiered - sort by days until premiere
                let lDays = lhs.daysUntilPremiere ?? Int.max
                let rDays = rhs.daysUntilPremiere ?? Int.max
                return lDays < rDays
            }

            // Both have premiered - sort alphabetically
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    /// Helper: Check if show has a confirmed finale date
    private func hasConfirmedFinale(_ show: ShowData) -> Bool {
        // Check current season first, then anticipated season for pre-premiere shows
        if let currentSeason = show.currentSeason {
            return currentSeason.finaleDate != nil
        }
        // For shows that haven't premiered, check the anticipated season
        return show.anticipatedSeason?.finaleDate != nil
    }

    /// Helper: Check if show has already premiered
    private func hasPremiered(_ show: ShowData) -> Bool {
        guard let premiereDate = show.currentSeason?.premiereDate else {
            return true // No premiere date = assume premiered
        }
        return premiereDate <= Date()
    }

    /// Shows with known premiere date AND a confirmed finale date
    /// (sorted by premiere date, soonest first)
    var premieringSoonShows: [ShowData] {
        followedShows
            .filter { $0.timelineCategory == .premieringSoon && hasConfirmedFinale($0) }
            .sorted { lhs, rhs in
                switch (lhs.daysUntilPremiere, rhs.daysUntilPremiere) {
                case let (l?, r?):
                    return l < r                          // Both have dates: soonest first
                case (_?, nil):
                    return true                           // Has date beats no date
                case (nil, _?):
                    return false                          // No date goes after
                case (nil, nil):
                    return lhs.name < rhs.name            // Both nil: alphabetical
                }
            }
    }

    /// Shows with no date announced - TBD (sorted alphabetically)
    var anticipatedShows: [ShowData] {
        followedShows
            .filter { $0.timelineCategory == .anticipated }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Completed or cancelled shows - ready to binge (sorted alphabetically)
    var bingeReadyShows: [ShowData] {
        followedShows
            .filter { $0.timelineCategory == .bingeReady }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Series Arrays (for list views that need SwiftData models)

    /// Airing now shows as Series (for list views)
    var airingNowSeries: [Series] {
        guard let seriesManager else { return [] }
        return seriesManager.allSeries()
            .filter { $0.showState == .airing }
            .sorted { lhs, rhs in
                switch (lhs.daysUntilFinale, rhs.daysUntilFinale) {
                case let (l?, r?):
                    return l < r
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.name < rhs.name
                }
            }
    }

    /// Premiering soon shows as Series (for list views)
    var premieringSoonSeries: [Series] {
        guard let seriesManager else { return [] }
        return seriesManager.allSeries()
            .filter { $0.showState == .premieringSoon }
            .sorted { lhs, rhs in
                switch (lhs.daysUntilPremiere, rhs.daysUntilPremiere) {
                case let (l?, r?):
                    return l < r
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.name < rhs.name
                }
            }
    }

    /// Pending shows as Series (for list views)
    var pendingSeries: [Series] {
        guard let seriesManager else {
            #if DEBUG
            return DebugSettings.shared.shouldShowMockPendingData ? mockPendingSeries : []
            #else
            return []
            #endif
        }

        var series = seriesManager.allSeries()
            .filter { $0.showState == .pending }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }

        // Debug: Add mock pending Series if enabled (simulator only)
        #if DEBUG
        if DebugSettings.shared.shouldShowMockPendingData {
            series.append(contentsOf: mockPendingSeries)
        }
        #endif

        return series
    }

    /// Mock pending Series for debug (mirrors mockPendingShows)
    private var mockPendingSeries: [Series] {
        #if DEBUG
        return Self.mockPendingShows.map { showData in
            let series = Series(id: showData.id, name: showData.name)
            series.posterPath = showData.posterPath
            series.numberOfSeasons = showData.numberOfSeasons
            series.statusRaw = showData.status.rawValue
            series.inProduction = showData.inProduction
            series.networks = showData.networks

            // Create a season with pending-like dates (premiere set, no finale)
            let seasonNum = showData.numberOfSeasons
            let season = Season(id: showData.id * 100, seasonNumber: seasonNum, name: "Season \(seasonNum)")

            // Add episodes with premiere date but no finale info
            if let seasonData = showData.seasons.first {
                for epData in seasonData.episodes {
                    let episode = Episode(
                        id: epData.id,
                        episodeNumber: epData.episodeNumber,
                        seasonNumber: seasonData.seasonNumber,
                        name: epData.name
                    )
                    episode.airDate = epData.airDate
                    episode.episodeTypeRaw = epData.episodeType.rawValue
                    season.episodes.append(episode)
                }
                season.airDate = seasonData.airDate
            }

            series.seasons.append(season)
            return series
        }
        #else
        return []
        #endif
    }

    /// Anticipated shows as Series (for list views)
    var anticipatedSeries: [Series] {
        guard let seriesManager else { return [] }
        return seriesManager.allSeries()
            .filter { $0.showState == .anticipated }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    /// Hero shows for the card stack (airing now, sorted by finale)
    var heroShows: [ShowData] {
        Array(airingNowShows.prefix(5))
    }

    /// Hero shows as tuples for HeroCardStack
    var heroShowTuples: [HeroCardStack.ShowDataTuple] {
        heroShows.map { show in
            (
                show: show,
                daysUntilFinale: show.daysUntilFinale,
                episodesUntilFinale: nil, // Not tracked currently
                finaleDate: show.currentSeason?.episodes
                    .max(by: { $0.episodeNumber < $1.episodeNumber })?.airDate
            )
        }
    }

    var trackedCount: Int {
        followedShows.count
    }

    var upcomingCount: Int {
        airingNowShows.count
    }

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private var store: FollowedShowsStore?
    private var seriesManager: SeriesManager?

    // MARK: - Init

    init() {
        // Cloud sync handled via SwiftData's native CloudKit integration
    }

    // MARK: - Public API

    func configure(with modelContext: ModelContext, seriesManager: SeriesManager? = nil) {
        self.modelContext = modelContext
        self.store = FollowedShowsStore(modelContext: modelContext)
        self.seriesManager = seriesManager
    }

    func loadFollowedShows() async {
        guard let seriesManager else { return }

        isLoading = true

        // Clean up any duplicate Series entries first
        try? seriesManager.cleanupDuplicates()

        // Load from SeriesManager (the new engine) and convert to ShowData
        var shows = seriesManager.allSeries().map { $0.toShowData() }

        // Debug: Add mock pending shows for testing (simulator only)
        #if DEBUG
        if DebugSettings.shared.shouldShowMockPendingData {
            shows.append(contentsOf: Self.mockPendingShows)
        }
        #endif

        followedShows = shows
        lastRefreshedAt = Date()

        isLoading = false
    }

    func refresh() async {
        await loadFollowedShows()
    }

    /// Unfollow a show
    func unfollowShow(_ series: Series) async {
        guard let seriesManager else { return }

        do {
            try seriesManager.unfollow(id: series.id)
            // Remove from local list
            followedShows.removeAll { $0.id == series.id }
        } catch {
            print("Error unfollowing show: \(error)")
        }
    }

    /// Get Series by show ID for navigation
    func getSeries(for showId: Int) -> Series? {
        seriesManager?.series(id: showId)
    }

    /// Get anticipated season number for display (numberOfSeasons + 1)
    func anticipatedSeasonNumber(for show: ShowData) -> Int {
        show.numberOfSeasons + 1
    }

    // MARK: - Mock Data for Testing

    #if DEBUG
    /// Mock pending shows for testing the Pending section
    private static var mockPendingShows: [ShowData] {
        [
            // Show 1: Hasn't premiered yet, no finale date (shows countdown to premiere)
            ShowData(
                id: 999001,
                name: "Cold Harvest",
                overview: "A gripping drama about survival in the frozen north.",
                posterPath: "/mock_cold_harvest.jpg",
                backdropPath: nil,
                logoPath: nil,
                firstAirDate: Date().addingTimeInterval(86400 * 18), // Premieres in 18 days
                status: .returning,
                genres: [GenreData(id: 18, name: "Drama")],
                networks: [NetworkData(id: 2552, name: "Apple TV+", logoPath: nil)],
                createdBy: nil,
                seasons: [
                    SeasonData(
                        id: 999101,
                        seasonNumber: 2,
                        name: "Season 2",
                        overview: "The second season",
                        posterPath: nil,
                        airDate: Date().addingTimeInterval(86400 * 18), // Premieres in 18 days
                        episodeCount: 5,
                        episodes: [
                            // Episodes with premiere date but no finale date
                            EpisodeData(id: 9991001, episodeNumber: 1, seasonNumber: 2, name: "Ep 1", overview: "", airDate: Date().addingTimeInterval(86400 * 18), stillPath: nil, runtime: 55, episodeType: .standard, voteAverage: nil),
                            EpisodeData(id: 9991002, episodeNumber: 2, seasonNumber: 2, name: "Ep 2", overview: "", airDate: nil, stillPath: nil, runtime: 55, episodeType: .standard, voteAverage: nil),
                            EpisodeData(id: 9991003, episodeNumber: 3, seasonNumber: 2, name: "Ep 3", overview: "", airDate: nil, stillPath: nil, runtime: 55, episodeType: .standard, voteAverage: nil),
                            EpisodeData(id: 9991004, episodeNumber: 4, seasonNumber: 2, name: "Ep 4", overview: "", airDate: nil, stillPath: nil, runtime: 55, episodeType: .standard, voteAverage: nil),
                            EpisodeData(id: 9991005, episodeNumber: 5, seasonNumber: 2, name: "Ep 5", overview: "", airDate: nil, stillPath: nil, runtime: 55, episodeType: .standard, voteAverage: nil)
                        ],
                        voteAverage: nil
                    )
                ],
                numberOfSeasons: 2,
                numberOfEpisodes: 15,
                inProduction: true,
                voteAverage: 8.2
            ),

            // Show 2: Already premiered, no finale date (shows "TBA FINALE DATE")
            ShowData(
                id: 999002,
                name: "The Lantern Route",
                overview: "A mystery thriller set in the Pacific Northwest.",
                posterPath: "/mock_lantern_route.jpg",
                backdropPath: nil,
                logoPath: nil,
                firstAirDate: Date().addingTimeInterval(-86400 * 14), // Started 2 weeks ago
                status: .returning,
                genres: [GenreData(id: 9648, name: "Mystery")],
                networks: [NetworkData(id: 3186, name: "Max", logoPath: nil)],
                createdBy: nil,
                seasons: [
                    SeasonData(
                        id: 999201,
                        seasonNumber: 3,
                        name: "Season 3",
                        overview: "The third season",
                        posterPath: nil,
                        airDate: Date().addingTimeInterval(-86400 * 14), // Premiered 2 weeks ago
                        episodeCount: 3,
                        episodes: [
                            // Episodes with air dates but NO finale marked
                            EpisodeData(id: 9992001, episodeNumber: 1, seasonNumber: 3, name: "Ep 1", overview: "", airDate: Date().addingTimeInterval(-86400 * 14), stillPath: nil, runtime: 50, episodeType: .standard, voteAverage: nil),
                            EpisodeData(id: 9992002, episodeNumber: 2, seasonNumber: 3, name: "Ep 2", overview: "", airDate: Date().addingTimeInterval(-86400 * 7), stillPath: nil, runtime: 50, episodeType: .standard, voteAverage: nil),
                            EpisodeData(id: 9992003, episodeNumber: 3, seasonNumber: 3, name: "Ep 3", overview: "", airDate: nil, stillPath: nil, runtime: 50, episodeType: .standard, voteAverage: nil)
                        ],
                        voteAverage: nil
                    )
                ],
                numberOfSeasons: 3,
                numberOfEpisodes: 24,
                inProduction: true,
                voteAverage: 7.9
            )
        ]
    }
    #endif
}
