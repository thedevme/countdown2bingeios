//
//  SearchViewModel.swift
//  Countdown2Binge
//

import Foundation
import SwiftUI

/// Genre categories for filtering
enum ShowCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case actionAdventure = "Action & Adventure"
    case animation = "Animation"
    case comedy = "Comedy"
    case crime = "Crime"
    case documentary = "Documentary"
    case drama = "Drama"
    case family = "Family"
    case mystery = "Mystery"
    case sciFiFantasy = "Sci-Fi & Fantasy"
    case western = "Western"

    var id: String { rawValue }

    /// TMDB genre IDs for this category
    var genreIds: [Int] {
        switch self {
        case .all: return []
        case .actionAdventure: return [10759]
        case .animation: return [16]
        case .comedy: return [35]
        case .crime: return [80]
        case .documentary: return [99]
        case .drama: return [18]
        case .family: return [10751]
        case .mystery: return [9648]
        case .sciFiFantasy: return [10765]
        case .western: return [37]
        }
    }
}

/// ViewModel for the search screen.
/// Handles searching TMDB and adding shows to the user's followed list.
@MainActor
@Observable
final class SearchViewModel {
    // MARK: - Published Properties

    var searchQuery: String = ""
    var searchResults: [TMDBShowSummary] = []
    var isSearching: Bool = false
    var error: Error?

    /// Selected category filter
    var selectedCategory: ShowCategory = .all

    /// Trending shows for landing page with logo paths
    var trendingShows: [(show: TMDBShowSummary, logoPath: String?)] = []
    var isLoadingTrending: Bool = false

    /// Shows that are ending soon (from followed shows)
    var endingSoonShows: [(show: Show, daysLeft: Int)] = []

    /// Currently airing shows from TMDB with days until finale
    var airingShows: [(show: TMDBShowSummary, daysLeft: Int?)] = []
    var isLoadingAiring: Bool = false
    private var airingShowsPage: Int = 1
    private var airingShowsTotalPages: Int = 1

    /// Whether more airing shows can be loaded
    var canLoadMoreAiringShows: Bool {
        airingShowsPage < airingShowsTotalPages && !isLoadingAiring
    }

    /// Shows by genre from TMDB
    var genreShows: [TMDBShowSummary] = []
    var isLoadingGenre: Bool = false
    private var genreShowsPage: Int = 1
    private var genreShowsTotalPages: Int = 1
    private var currentGenreIds: [Int] = []

    /// Whether more genre shows can be loaded
    var canLoadMoreGenreShows: Bool {
        genreShowsPage < genreShowsTotalPages && !isLoadingGenre
    }

    /// Set of TMDB IDs currently being added (for loading state)
    var addingShowIds: Set<Int> = []

    /// ID of the most recently added show (for success feedback)
    var recentlyAddedShowId: Int?

    /// Show selected for detail navigation
    var selectedShow: Show?

    /// ID of show currently being loaded for detail view
    var loadingDetailId: Int?

    // MARK: - Dependencies

    private let tmdbService: TMDBServiceProtocol
    private let addShowUseCase: AddShowUseCaseProtocol
    private let repository: ShowRepositoryProtocol

    // MARK: - Private State

    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        tmdbService: TMDBServiceProtocol,
        addShowUseCase: AddShowUseCaseProtocol,
        repository: ShowRepositoryProtocol
    ) {
        self.tmdbService = tmdbService
        self.addShowUseCase = addShowUseCase
        self.repository = repository
    }

    // MARK: - Search

    /// Search for shows matching the current query.
    /// Debounces requests and cancels previous searches.
    func search() async {
        // Cancel any in-flight search
        searchTask?.cancel()

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        // Clear results if query is empty
        guard !query.isEmpty else {
            searchResults = []
            error = nil
            return
        }

        // Debounce: wait briefly before searching
        searchTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return // Cancelled
            }

            await performSearch(query: query)
        }
    }

    private func performSearch(query: String) async {
        isSearching = true
        error = nil

        do {
            let response = try await tmdbService.searchShows(query: query, page: 1)
            searchResults = response.results
        } catch {
            if !Task.isCancelled {
                self.error = error
                searchResults = []
            }
        }

        isSearching = false
    }

    // MARK: - Add Show

    /// Add a show to the user's followed list.
    /// - Parameter tmdbId: The TMDB ID of the show to add
    /// - Returns: `true` if successful, `false` if failed
    func addShow(tmdbId: Int) async -> Bool {
        guard !addingShowIds.contains(tmdbId) else { return false }

        addingShowIds.insert(tmdbId)
        recentlyAddedShowId = nil

        do {
            _ = try await addShowUseCase.execute(tmdbId: tmdbId)
            recentlyAddedShowId = tmdbId

            // Clear success indicator after delay
            Task {
                try? await Task.sleep(for: .seconds(2))
                if recentlyAddedShowId == tmdbId {
                    recentlyAddedShowId = nil
                }
            }

            addingShowIds.remove(tmdbId)
            return true
        } catch {
            self.error = error
            addingShowIds.remove(tmdbId)
            return false
        }
    }

    // MARK: - Check Following Status

    /// Check if a show is already being followed.
    /// - Parameter tmdbId: The TMDB ID to check
    /// - Returns: `true` if the show is followed
    func isFollowed(tmdbId: Int) -> Bool {
        repository.isShowFollowed(tmdbId: tmdbId)
    }

    /// Check if a show is currently being added.
    /// - Parameter tmdbId: The TMDB ID to check
    /// - Returns: `true` if the show is being added
    func isAdding(tmdbId: Int) -> Bool {
        addingShowIds.contains(tmdbId)
    }

    // MARK: - Show Detail

    /// Fetch full show details and set for navigation
    /// - Parameter tmdbId: The TMDB ID to fetch
    func selectShow(tmdbId: Int) async {
        guard loadingDetailId == nil else { return }

        loadingDetailId = tmdbId

        do {
            let show = try await tmdbService.getShowDetails(id: tmdbId)
            selectedShow = show
        } catch {
            self.error = error
        }

        loadingDetailId = nil
    }

    /// Check if a show is currently loading for detail view
    func isLoadingDetail(tmdbId: Int) -> Bool {
        loadingDetailId == tmdbId
    }

    // MARK: - Clear

    /// Clear search results and query
    func clear() {
        searchQuery = ""
        searchResults = []
        error = nil
        searchTask?.cancel()
    }

    // MARK: - Trending Shows

    /// Load trending TV shows from TMDB with logos
    func loadTrendingShows() async {
        guard trendingShows.isEmpty else { return }

        isLoadingTrending = true

        do {
            let shows = try await tmdbService.getTrendingShows()

            // Fetch logos for top shows
            var results: [(show: TMDBShowSummary, logoPath: String?)] = []

            for summary in shows.prefix(10) {
                let logoPath = await tmdbService.getShowLogo(id: summary.id)
                results.append((show: summary, logoPath: logoPath))
            }

            trendingShows = results
        } catch {
            // Silently fail - trending is not critical
        }

        isLoadingTrending = false
    }

    // MARK: - Airing Shows

    /// Load currently airing shows from TMDB with finale dates
    func loadAiringShows() async {
        guard airingShows.isEmpty else { return }

        isLoadingAiring = true
        airingShowsPage = 1

        do {
            let response = try await tmdbService.getAiringShows(page: 1)
            airingShowsTotalPages = response.totalPages

            // Only fetch details for the first 3 shows (displayed on landing page)
            let showsWithDetails = await fetchDaysLeftForShows(Array(response.results.prefix(3)))
            // Rest of shows without details fetch (faster loading)
            let remainingShows = response.results.dropFirst(3).map { (show: $0, daysLeft: nil as Int?) }

            airingShows = showsWithDetails + remainingShows
        } catch {
            // Silently fail - airing shows is not critical
        }

        isLoadingAiring = false
    }

    /// Load more airing shows (pagination)
    func loadMoreAiringShows() async {
        guard canLoadMoreAiringShows else { return }

        isLoadingAiring = true
        let nextPage = airingShowsPage + 1

        do {
            let response = try await tmdbService.getAiringShows(page: nextPage)
            airingShowsPage = nextPage
            airingShowsTotalPages = response.totalPages

            // Don't fetch details for paginated results (faster loading)
            let newResults = response.results.map { (show: $0, daysLeft: nil as Int?) }
            airingShows.append(contentsOf: newResults)
        } catch {
            // Silently fail
        }

        isLoadingAiring = false
    }

    // MARK: - Genre Shows

    /// Load shows by genre from TMDB
    func loadGenreShows(genreIds: [Int]) async {
        // Reset if different genre
        if currentGenreIds != genreIds {
            genreShows = []
            genreShowsPage = 1
            genreShowsTotalPages = 1
            currentGenreIds = genreIds
        }

        guard genreShows.isEmpty else { return }

        isLoadingGenre = true

        do {
            let response = try await tmdbService.getShowsByGenre(genreIds: genreIds, page: 1)
            genreShowsTotalPages = response.totalPages
            genreShows = response.results
        } catch {
            // Silently fail
        }

        isLoadingGenre = false
    }

    /// Load more genre shows (pagination)
    func loadMoreGenreShows() async {
        guard canLoadMoreGenreShows else { return }

        isLoadingGenre = true
        let nextPage = genreShowsPage + 1

        do {
            let response = try await tmdbService.getShowsByGenre(genreIds: currentGenreIds, page: nextPage)
            genreShowsPage = nextPage
            genreShowsTotalPages = response.totalPages
            genreShows.append(contentsOf: response.results)
        } catch {
            // Silently fail
        }

        isLoadingGenre = false
    }

    /// Clear genre shows when navigating away
    func clearGenreShows() {
        genreShows = []
        genreShowsPage = 1
        genreShowsTotalPages = 1
        currentGenreIds = []
    }

    /// Helper to fetch days left for a list of shows
    private func fetchDaysLeftForShows(_ shows: [TMDBShowSummary]) async -> [(show: TMDBShowSummary, daysLeft: Int?)] {
        let today = Date()
        var results: [(show: TMDBShowSummary, daysLeft: Int?)] = []

        for summary in shows {
            do {
                let details = try await tmdbService.getShowDetails(id: summary.id)
                // Find current airing season's finale date
                if let currentSeason = details.seasons.first(where: { $0.isAiring }),
                   let finaleDate = currentSeason.finaleDate {
                    let days = Calendar.current.dateComponents([.day], from: today, to: finaleDate).day ?? 0
                    results.append((show: summary, daysLeft: max(0, days)))
                } else {
                    results.append((show: summary, daysLeft: nil))
                }
            } catch {
                results.append((show: summary, daysLeft: nil))
            }
        }

        return results
    }

    // MARK: - Ending Soon Shows

    /// Load shows that are ending soon from followed shows
    func loadEndingSoonShows() {
        let allShows = repository.fetchTimelineShows()
        let today = Date()

        var endingSoon: [(show: Show, daysLeft: Int)] = []

        for show in allShows {
            // Find the current airing season
            if let currentSeason = show.seasons.first(where: { $0.isAiring }) {
                if let finaleDate = currentSeason.finaleDate {
                    let days = Calendar.current.dateComponents([.day], from: today, to: finaleDate).day ?? 0
                    if days >= 0 && days <= 30 {
                        endingSoon.append((show: show, daysLeft: days))
                    }
                }
            }
        }

        // Sort by days left
        endingSoonShows = endingSoon.sorted { $0.daysLeft < $1.daysLeft }
    }

    // MARK: - Category Filtering

    /// Filter results by selected category
    var filteredTrendingShows: [(show: TMDBShowSummary, logoPath: String?)] {
        guard selectedCategory != .all else { return trendingShows }

        return trendingShows.filter { item in
            guard let genreIds = item.show.genreIds else { return false }
            return !Set(genreIds).isDisjoint(with: Set(selectedCategory.genreIds))
        }
    }
}
