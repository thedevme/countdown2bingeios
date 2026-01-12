//
//  SearchViewModel.swift
//  Countdown2Binge
//

import Foundation
import SwiftUI

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

    /// Set of TMDB IDs currently being added (for loading state)
    var addingShowIds: Set<Int> = []

    /// ID of the most recently added show (for success feedback)
    var recentlyAddedShowId: Int?

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

    // MARK: - Clear

    /// Clear search results and query
    func clear() {
        searchQuery = ""
        searchResults = []
        error = nil
        searchTask?.cancel()
    }
}
