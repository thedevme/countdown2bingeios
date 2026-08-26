//
//  DiscoverViewModel.swift
//  Countdown2Binge
//
//  Manages state for the Discover/Search screen.
//  Fetches trending shows, handles search, and manages follow state.
//

import Foundation
import SwiftData

// MARK: - Genre Definition
struct GenreDefinition: Identifiable, Hashable {
    let id: Int
    let name: String
}

// MARK: - Network Definition
struct NetworkDefinition: Identifiable, Hashable {
    let id: Int
    let name: String
    let color: String
}

@MainActor
@Observable
final class DiscoverViewModel {
    // MARK: - Constants

    static let genres: [GenreDefinition] = [
        GenreDefinition(id: 10759, name: "Action"),
        GenreDefinition(id: 18, name: "Drama"),
        GenreDefinition(id: 10765, name: "Sci-Fi"),
        GenreDefinition(id: 35, name: "Comedy"),
        GenreDefinition(id: 80, name: "Crime"),
        GenreDefinition(id: 10764, name: "Reality"),
        GenreDefinition(id: 9648, name: "Mystery"),
        GenreDefinition(id: 10768, name: "War"),
        GenreDefinition(id: 10749, name: "Romance")
    ]

    static let networks: [NetworkDefinition] = [
        NetworkDefinition(id: 213, name: "Netflix", color: "#E50914"),
        NetworkDefinition(id: 3186, name: "Max", color: "#5A35E0"),
        NetworkDefinition(id: 453, name: "Hulu", color: "#1CE783"),
        NetworkDefinition(id: 1024, name: "Prime", color: "#1FB6FF"),
        NetworkDefinition(id: 2552, name: "Apple TV+", color: "#A1A1AA"),
        NetworkDefinition(id: 2739, name: "Disney+", color: "#1FA2FF"),
        NetworkDefinition(id: 4330, name: "Paramount+", color: "#0064FF"),
        NetworkDefinition(id: 3353, name: "Peacock", color: "#000000")
    ]

    // MARK: - State

    private(set) var trendingShows: [ShowSummary] = []
    private(set) var searchResults: [ShowSummary] = []
    private(set) var genreShows: [Int: [ShowSummary]] = [:]
    private(set) var networkShows: [Int: [ShowSummary]] = [:]

    /// Preference-driven "For You" rail — hard-filtered by taste. Additive and
    /// isolated: served by RecommendationService (the same path onboarding uses),
    /// never by the network/cache browse pipeline or search.
    private(set) var forYouShows: [ShowSummary] = []
    private(set) var forYouLabel: String?
    private(set) var isLoadingForYou = false

    // Genre pagination state
    private var genreCurrentPage: [Int: Int] = [:]
    private var genreTotalPages: [Int: Int] = [:]
    private(set) var isLoadingMoreGenre = false

    // Trending pagination state
    private var trendingCurrentPage = 0
    /// When the trending list was last loaded, and for which taste query.
    /// Both are needed: time alone would serve results for streaming services
    /// the user just turned off.
    private var trendingLoadedAt: Date?
    private var loadedTrendingQueryKey: String?
    private var trendingTotalPages = 0
    private(set) var isLoadingMoreTrending = false
    /// The relaxation level that produced the current trending page, so "load
    /// more" paginates the same taste-filtered query (never dropping providers).
    private var trendingRelaxation: DiscoverQuery.Relaxation = .full

    /// Cached discover shows (loaded from SwiftData)
    private(set) var cachedShows: [CachedDiscoverShow] = [] {
        didSet { rebuildCachedShowsByBucket() }
    }
    /// Pre-computed groupings by bucket for fast access
    private var cachedShowsByBucket: [DiscoverBucket: [CachedDiscoverShow]] = [:]
    private(set) var isLoading = false
    private(set) var isSearching = false
    private(set) var isLoadingGenre = false
    private(set) var isLoadingNetwork = false
    private(set) var error: String?

    // Selected show for detail view
    private(set) var selectedShowData: ShowData?
    private(set) var selectedShowCast: [TMDBCastMember] = []
    private(set) var selectedShowVideos: [TMDBVideo] = []
    private(set) var selectedShowRecommendations: [TMDBShowSummary] = []
    private(set) var isLoadingShowDetail = false
    private(set) var loadingFollowId: Int?

    /// Show pending follow confirmation - triggers AddShowModal
    private(set) var pendingFollowShow: ShowData?

    /// Set to true when user hits free tier limit - triggers paywall
    var showPremiumUpgrade: Bool = false

    /// Set to true when user tries to follow during grace period - shows alert
    var showGracePeriodBlock: Bool = false

    var searchText: String = "" {
        didSet {
            searchTask?.cancel()
            if searchText.isEmpty {
                searchResults = []
                isSearching = false
            } else {
                isSearching = true
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    await search(query: searchText)
                }
            }
        }
    }

    /// Shows to display - search results if searching, otherwise trending
    var displayedShows: [ShowSummary] {
        if !searchText.isEmpty {
            return searchResults
        }
        return trendingShows
    }

    // MARK: - Dependencies

    private let tmdbService: TMDBServiceProtocol
    private var modelContext: ModelContext?
    private var seriesManager: SeriesManager?
    private var cacheService: DiscoverCacheService?
    private var searchTask: Task<Void, Never>?
    private var followedShowIds: Set<Int> = []

    // MARK: - Init

    init(tmdbService: TMDBServiceProtocol = TMDBService()) {
        self.tmdbService = tmdbService
    }

    // MARK: - Configuration

    func configure(with modelContext: ModelContext, seriesManager: SeriesManager) {
        self.modelContext = modelContext
        self.seriesManager = seriesManager
        self.cacheService = DiscoverCacheService(modelContext: modelContext, tmdbService: tmdbService)
        Task {
            await loadFollowedShowIds()
        }
    }

    // MARK: - Public API

    /// How long a loaded trending list stays good. Re-running the relaxation
    /// ladder on every appearance meant a network round-trip each time the
    /// search screen was opened, even when returning to it seconds later.
    private static let trendingFreshness: TimeInterval = 15 * 60

    func loadTrendingShows(force: Bool = false) async {
        guard !isLoading else { return }

        // Already have results, still fresh, and the taste query hasn't changed.
        // The query is part of the key because changing streaming services or
        // genres must invalidate immediately — a stale list would silently show
        // shows the user can't stream.
        let queryKey = DiscoverQueryBuilder.cacheKey(
            for: TastePreferencesStore.shared.preferences.discoverQuery(page: 1),
            relaxation: .full
        )
        if !force,
           !trendingShows.isEmpty,
           queryKey == loadedTrendingQueryKey,
           let loadedAt = trendingLoadedAt,
           Date().timeIntervalSince(loadedAt) < Self.trendingFreshness {
            return
        }

        isLoading = true
        error = nil

        // Personalized + availability-filtered: only shows the user can actually
        // stream (their providers + region + flatrate) in their genres. Broadens by
        // dropping genre if needed, but NEVER drops the provider filter.
        let query = TastePreferencesStore.shared.preferences.discoverQuery(page: 1)
        let ladder = DiscoverQueryBuilder.relaxationLadder(for: query)

        for (index, level) in ladder.enumerated() {
            do {
                let response = try await tmdbService.discover(query: query, relaxation: level)
                let shows = response.results.map { $0.toShowSummary() }
                if shows.count >= 10 || index == ladder.count - 1 {
                    trendingShows = shows
                    trendingLoadedAt = Date()
                    loadedTrendingQueryKey = queryKey
                    trendingCurrentPage = 1
                    trendingTotalPages = response.totalPages
                    trendingRelaxation = level
                    break
                }
            } catch {
                self.error = String(localized: "error_load_trending")
                break
            }
        }

        isLoading = false
    }

    /// Check if more trending pages are available
    func canLoadMoreTrending() -> Bool {
        return trendingCurrentPage < trendingTotalPages && !isLoadingMoreTrending
    }

    /// Load the next page of trending shows
    func loadMoreTrendingShows() async {
        guard canLoadMoreTrending() else { return }

        let nextPage = trendingCurrentPage + 1
        isLoadingMoreTrending = true

        // Paginate the SAME taste-filtered query at the level that produced page 1.
        let query = TastePreferencesStore.shared.preferences.discoverQuery(page: nextPage)
        do {
            let response = try await tmdbService.discover(query: query, relaxation: trendingRelaxation)
            let newShows = response.results.map { $0.toShowSummary() }
            trendingShows.append(contentsOf: newShows)
            trendingCurrentPage = nextPage
        } catch {
        }

        isLoadingMoreTrending = false
    }

    func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        do {
            let response = try await tmdbService.searchShows(query: query, page: 1)
            // Only update if this is still the current search
            if searchText == query {
                searchResults = response.results.map { $0.toShowSummary() }
            }
        } catch {
            if searchText == query {
                searchResults = []
            }
        }
    }

    func isFollowing(_ show: ShowSummary) -> Bool {
        followedShowIds.contains(show.id)
    }

    func toggleFollow(_ show: ShowSummary) async {
        guard let seriesManager else { return }

        if isFollowing(show) {
            // Unfollow
            do {
                try seriesManager.unfollow(id: show.id)
                followedShowIds.remove(show.id)
            } catch {
            }
        } else {
            // Check grace period first - user must choose shows before following new ones
            if PremiumManager.shared.isInGracePeriod {
                showGracePeriodBlock = true
                return
            }

            // Check premium limit before following
            if !PremiumManager.shared.canAddShow(currentCount: followedShowIds.count) {
                showPremiumUpgrade = true
                return
            }

            // Fetch show details and show confirmation modal
            do {
                let fullShowData = try await tmdbService.getShowDetails(id: show.id)
                pendingFollowShow = fullShowData
            } catch {
            }
        }
    }

    /// Actually follow the show and apply the catch-up answer from AddShowModal.
    /// `lastWatchedSeason` is the last season the user finished; every season up
    /// through it is marked watched (0 = haven't started → leave in Binge Ready).
    func handleAddShowDone(lastWatchedSeason: Int) async {
        guard let show = pendingFollowShow, let seriesManager else {
            clearPendingFollow()
            return
        }

        do {
            // Actually follow the show now
            let result = try seriesManager.follow(showData: show)
            followedShowIds.insert(show.id)

            // Mark all seasons up through the one they finished (if there was a
            // catch-up prompt). This leaves nothing earlier unwatched, so a
            // caught-up show has no bingeable season and stays on the Timeline.
            if case let .followed(_, prompt?) = result, lastWatchedSeason > 0 {
                try seriesManager.markSeasonsWatched(
                    seriesId: prompt.seriesId,
                    throughSeasonNumber: lastWatchedSeason
                )
            }
        } catch {
        }

        clearPendingFollow()
    }

    /// Clear the pending follow state
    func clearPendingFollow() {
        pendingFollowShow = nil
    }

    func refresh() async {
        async let followedTask: () = loadFollowedShowIds()
        async let trendingTask: () = loadTrendingShows()
        _ = await (followedTask, trendingTask)
    }

    // MARK: - Show Detail Loading

    /// Load full show data for detail view
    func loadShowDetail(for summary: ShowSummary) async {
        isLoadingShowDetail = true

        do {
            // Fetch show details, cast, videos, and recommendations in parallel
            async let showDataTask = tmdbService.getShowDetails(id: summary.id)
            async let creditsTask = tmdbService.getShowCredits(id: summary.id)
            async let videosTask = tmdbService.getShowVideos(id: summary.id)
            async let recommendationsTask = tmdbService.getShowRecommendations(id: summary.id)

            let showData = try await showDataTask
            selectedShowData = showData

            // These can fail silently - not critical
            if let credits = try? await creditsTask {
                selectedShowCast = credits.cast
            }
            if let videos = try? await videosTask {
                selectedShowVideos = videos
            }
            if let recommendations = try? await recommendationsTask {
                selectedShowRecommendations = recommendations
            }
        } catch {
            // Create minimal ShowData from summary as fallback
            selectedShowData = ShowData(
                id: summary.id,
                name: summary.name,
                overview: summary.overview,
                posterPath: summary.posterPath,
                backdropPath: summary.backdropPath,
                logoPath: nil,
                firstAirDate: nil,
                status: .returning,
                genres: [],
                networks: [],
                createdBy: nil,
                seasons: [],
                numberOfSeasons: 0,
                numberOfEpisodes: 0,
                inProduction: true,
                voteAverage: summary.voteAverage
            )
        }

        isLoadingShowDetail = false
    }

    /// Clear selected show when dismissing detail view
    func clearSelectedShow() {
        selectedShowData = nil
        selectedShowCast = []
        selectedShowVideos = []
        selectedShowRecommendations = []
    }

    /// Toggle follow for the selected show with loading state
    func toggleFollowSelectedShow() async {
        guard let show = selectedShowData else { return }
        loadingFollowId = show.id

        // Check if we're about to follow (not unfollow)
        let willFollow = !isFollowing(ShowSummary(
            id: show.id,
            name: show.name,
            overview: show.overview,
            posterPath: show.posterPath,
            backdropPath: show.backdropPath,
            firstAirDate: nil,
            voteAverage: show.voteAverage,
            genreIds: show.genres.map { $0.id }
        ))

        // Create a ShowSummary to reuse existing logic
        let summary = ShowSummary(
            id: show.id,
            name: show.name,
            overview: show.overview,
            posterPath: show.posterPath,
            backdropPath: show.backdropPath,
            firstAirDate: show.firstAirDate.map {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: $0)
            },
            voteAverage: show.voteAverage,
            genreIds: show.genres.map { $0.id }
        )

        if willFollow {
            // Check grace period first - user must choose shows before following new ones
            if PremiumManager.shared.isInGracePeriod {
                showGracePeriodBlock = true
                loadingFollowId = nil
                return
            }

            // Check premium limit before following
            if !PremiumManager.shared.canAddShow(currentCount: followedShowIds.count) {
                showPremiumUpgrade = true
                loadingFollowId = nil
                return
            }

            // Show confirmation modal - we already have full ShowData
            pendingFollowShow = show
        } else {
            // Unfollow directly
            await toggleFollow(summary)
        }
        loadingFollowId = nil
    }

    /// Check if a show ID is currently loading for follow
    func isLoadingFollow(for showId: Int) -> Bool {
        loadingFollowId == showId
    }

    // MARK: - Cache-Based Discover

    /// Load discover shows from cache, refresh if stale
    func loadDiscoverFromCache() async {
        guard let cacheService else { return }

        isLoading = true

        // Refresh cache if stale (weekly)
        await cacheService.refreshIfNeeded()

        // Load all cached shows
        cachedShows = cacheService.getAllShows()

        isLoading = false
    }

    /// Force refresh the discover cache
    func refreshDiscoverCache() async {
        guard let cacheService else { return }

        isLoading = true
        await cacheService.refreshCache()
        cachedShows = cacheService.getAllShows()
        isLoading = false
    }

    /// Get cached shows for a bucket, optionally filtered by network
    func getCachedShows(bucket: DiscoverBucket, networkId: Int? = nil, limit: Int = 8) -> [CachedDiscoverShow] {
        let bucketShows = cachedShowsByBucket[bucket] ?? []
        if let networkId {
            return Array(bucketShows.filter { $0.networkId == networkId }.prefix(limit))
        }
        return Array(bucketShows.prefix(limit))
    }

    /// Get count of shows in a bucket
    func getCachedShowCount(bucket: DiscoverBucket, networkId: Int? = nil) -> Int {
        let bucketShows = cachedShowsByBucket[bucket] ?? []
        if let networkId {
            return bucketShows.filter { $0.networkId == networkId }.count
        }
        return bucketShows.count
    }

    // MARK: - Genre & Network Loading

    func loadShowsForGenre(_ genreId: Int) async {
        // Skip if already loaded
        if genreShows[genreId] != nil { return }

        isLoadingGenre = true

        do {
            let response = try await tmdbService.getShowsByGenre(genreIds: [genreId], page: 1)
            genreShows[genreId] = response.results.map { $0.toShowSummary() }
            genreCurrentPage[genreId] = 1
            genreTotalPages[genreId] = response.totalPages
        } catch {
            genreShows[genreId] = []
        }

        isLoadingGenre = false
    }

    /// Check if more pages are available for a genre
    func canLoadMoreForGenre(_ genreId: Int) -> Bool {
        guard let currentPage = genreCurrentPage[genreId],
              let totalPages = genreTotalPages[genreId] else {
            return false
        }
        return currentPage < totalPages && !isLoadingMoreGenre
    }

    /// Load the next page of shows for a genre
    func loadMoreShowsForGenre(_ genreId: Int) async {
        guard canLoadMoreForGenre(genreId) else { return }

        let nextPage = (genreCurrentPage[genreId] ?? 1) + 1
        isLoadingMoreGenre = true

        do {
            let response = try await tmdbService.getShowsByGenre(genreIds: [genreId], page: nextPage)
            let newShows = response.results.map { $0.toShowSummary() }

            // Append new shows to existing list
            if var existingShows = genreShows[genreId] {
                existingShows.append(contentsOf: newShows)
                genreShows[genreId] = existingShows
            } else {
                genreShows[genreId] = newShows
            }

            genreCurrentPage[genreId] = nextPage
        } catch {
        }

        isLoadingMoreGenre = false
    }

    func loadAllGenres() async {
        isLoadingGenre = true

        for genre in Self.genres {
            Task {
                do {
                    let response = try await tmdbService.getShowsByGenre(genreIds: [genre.id], page: 1)
                    genreShows[genre.id] = response.results.map { $0.toShowSummary() }
                } catch {
                }
            }
        }

        isLoadingGenre = false
    }

    /// Load the preference-filtered "For You" rail via the shared
    /// RecommendationService. Additive: leaves the network/cache browse paths and
    /// search entirely untouched.
    func loadForYou() async {
        let prefs = TastePreferencesStore.shared.preferences
        isLoadingForYou = true
        let feed = await RecommendationService.shared.feed(for: prefs, minResults: 10)
        forYouShows = feed.shows
        forYouLabel = feed.relaxationLabel
        isLoadingForYou = false
    }

    func loadAllNetworks() async {
        isLoadingNetwork = true

        // Load each network and update UI immediately as each completes
        for network in Self.networks {
            Task {
                do {
                    let response = try await tmdbService.getShowsByNetwork(networkId: network.id, page: 1)
                    // Take only first 10 shows per network
                    let shows = Array(response.results.prefix(10))
                    networkShows[network.id] = shows.map { $0.toShowSummary() }
                } catch {
                }
            }
        }

        isLoadingNetwork = false
    }

    // MARK: - Private

    private func loadFollowedShowIds() async {
        guard let seriesManager else { return }
        followedShowIds = Set(seriesManager.allSeries().map { $0.id })
    }

    /// Pre-compute bucket groupings once when data changes
    private func rebuildCachedShowsByBucket() {
        var grouped: [DiscoverBucket: [CachedDiscoverShow]] = [:]
        for bucket in DiscoverBucket.allCases {
            grouped[bucket] = cachedShows
                .filter { $0.currentBucket == bucket }
                .sorted { ($0.daysUntilPremiere ?? 0) < ($1.daysUntilPremiere ?? 0) }
        }
        cachedShowsByBucket = grouped
    }
}
