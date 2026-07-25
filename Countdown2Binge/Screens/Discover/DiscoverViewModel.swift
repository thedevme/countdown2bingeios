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

    /// Show pending follow confirmation - triggers confirmation sheet
    private(set) var pendingFollowShow: ShowData?

    /// Set to true when user hits free tier limit - triggers paywall
    var showPremiumUpgrade: Bool = false

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
    private var store: FollowedShowsStore?
    private var seriesStore: SeriesStore?
    private var cacheService: DiscoverCacheService?
    private var searchTask: Task<Void, Never>?
    private var followedShowIds: Set<Int> = []

    // MARK: - Init

    init(tmdbService: TMDBServiceProtocol = TMDBService()) {
        self.tmdbService = tmdbService
    }

    // MARK: - Configuration

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        self.store = FollowedShowsStore(modelContext: modelContext)
        self.seriesStore = SeriesStore(modelContext: modelContext)
        self.cacheService = DiscoverCacheService(modelContext: modelContext, tmdbService: tmdbService)
        Task {
            await loadFollowedShowIds()
        }
    }

    // MARK: - Public API

    func loadTrendingShows() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let response = try await tmdbService.getTrendingShows(page: 1)
            trendingShows = response.results.map { $0.toShowSummary() }
        } catch {
            self.error = String(localized: "error_load_trending")
            print("Error loading trending shows: \(error)")
        }

        isLoading = false
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
            print("Error searching shows: \(error)")
        }
    }

    func isFollowing(_ show: ShowSummary) -> Bool {
        followedShowIds.contains(show.id)
    }

    func toggleFollow(_ show: ShowSummary) async {
        guard let store, let seriesStore else { return }

        if isFollowing(show) {
            // Unfollow
            do {
                try store.unfollow(tmdbId: show.id)
                try seriesStore.delete(tmdbId: show.id)
                followedShowIds.remove(show.id)
            } catch {
                print("Error unfollowing show: \(error)")
            }
        } else {
            // Check premium limit before following
            if !PremiumManager.shared.canAddShow(currentCount: followedShowIds.count) {
                showPremiumUpgrade = true
                return
            }

            // Show confirmation sheet first - don't follow yet
            do {
                let fullShowData = try await tmdbService.getShowDetails(id: show.id)
                pendingFollowShow = fullShowData
            } catch {
                print("Error fetching show details: \(error)")
            }
        }
    }

    /// Actually follow the pending show (called when user taps SAVE)
    func confirmPendingFollow() async {
        guard let show = pendingFollowShow, let store, let seriesStore else { return }

        do {
            let summary = ShowSummary(
                id: show.id,
                name: show.name,
                overview: show.overview,
                posterPath: show.posterPath,
                backdropPath: show.backdropPath,
                firstAirDate: nil,
                voteAverage: show.voteAverage,
                genreIds: show.genres.map { $0.id }
            )
            try store.follow(summary: summary)
            followedShowIds.insert(show.id)
            try store.updateCache(for: show.id, with: show)
            try seriesStore.save(from: show)
            print("DEBUG: Saved \(show.name) - \(show.numberOfSeasons) seasons, inProduction: \(show.inProduction)")

            // Save franchise/spinoff data for this show
            await store.saveFranchiseData(for: show.id)
        } catch {
            print("Error following show: \(error)")
        }

        pendingFollowShow = nil
    }

    /// Clear the pending follow (call when dismissing without saving)
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
            print("Error loading show details: \(error)")
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
            // Check premium limit before following
            if !PremiumManager.shared.canAddShow(currentCount: followedShowIds.count) {
                showPremiumUpgrade = true
                loadingFollowId = nil
                return
            }

            // Show confirmation sheet - we already have full ShowData
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
        } catch {
            print("Error loading shows for genre \(genreId): \(error)")
            genreShows[genreId] = []
        }

        isLoadingGenre = false
    }

    func loadAllGenres() async {
        isLoadingGenre = true

        for genre in Self.genres {
            Task {
                do {
                    let response = try await tmdbService.getShowsByGenre(genreIds: [genre.id], page: 1)
                    genreShows[genre.id] = response.results.map { $0.toShowSummary() }
                } catch {
                    print("Error loading \(genre.name): \(error)")
                }
            }
        }

        isLoadingGenre = false
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
                    print("Error loading \(network.name): \(error)")
                }
            }
        }

        isLoadingNetwork = false
    }

    // MARK: - Private

    private func loadFollowedShowIds() async {
        guard let store else { return }

        do {
            let followedShows = try store.getAllFollowed()
            followedShowIds = Set(followedShows.map { $0.tmdbId })
        } catch {
            print("Error loading followed show IDs: \(error)")
        }
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
