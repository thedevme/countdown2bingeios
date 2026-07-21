//
//  OnboardingViewModel.swift
//  Countdown2Binge
//
//  Manages state for the onboarding flow.
//  Handles loading trending shows, searching, and managing selections.
//

import Foundation
import Combine

@MainActor
@Observable
final class OnboardingViewModel {
    // MARK: - Published State

    private(set) var trendingShows: [ShowSummary] = []
    private(set) var searchResults: [ShowSummary] = []
    private(set) var isLoading = false
    private(set) var isSearching = false
    private(set) var error: String?

    var searchText = "" {
        didSet {
            searchTextSubject.send(searchText)
        }
    }

    // Selected show IDs (in-memory during onboarding)
    private(set) var selectedShowIds: Set<Int> = []

    // Cache of selected show data for passing to completion
    private var selectedShowsCache: [Int: ShowSummary] = [:]

    // MARK: - Dependencies

    private let tmdbService: TMDBServiceProtocol

    // MARK: - Search Debouncing

    private let searchTextSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(tmdbService: TMDBServiceProtocol = TMDBService()) {
        self.tmdbService = tmdbService
        setupSearchDebounce()
    }

    // MARK: - Public API

    /// Load initial trending shows
    func loadTrendingShows() async {
        guard trendingShows.isEmpty else { return }

        isLoading = true
        error = nil

        do {
            let response = try await tmdbService.getTrendingShows(page: 1)
            trendingShows = response.results.map { $0.toShowSummary() }
        } catch {
            self.error = "Failed to load shows. Please try again."
            print("Error loading trending shows: \(error)")
        }

        isLoading = false
    }

    /// Search for shows
    func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            let response = try await tmdbService.searchShows(query: trimmed, page: 1)
            searchResults = response.results.map { $0.toShowSummary() }
        } catch {
            print("Error searching shows: \(error)")
            searchResults = []
        }

        isSearching = false
    }

    /// Toggle follow state for a show
    func toggleSelection(_ show: ShowSummary) {
        if selectedShowIds.contains(show.id) {
            selectedShowIds.remove(show.id)
            selectedShowsCache.removeValue(forKey: show.id)
        } else {
            selectedShowIds.insert(show.id)
            selectedShowsCache[show.id] = show
        }
    }

    /// Check if a show is selected
    func isSelected(_ show: ShowSummary) -> Bool {
        selectedShowIds.contains(show.id)
    }

    /// Check if a show ID is selected
    func isSelected(id: Int) -> Bool {
        selectedShowIds.contains(id)
    }

    /// Get all selected shows
    func getSelectedShows() -> [ShowSummary] {
        selectedShowIds.compactMap { selectedShowsCache[$0] }
    }

    /// Get shows to display (search results if searching, otherwise trending)
    var displayedShows: [ShowSummary] {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return searchResults
        }
        return trendingShows
    }

    /// Number of selected shows
    var selectedCount: Int {
        selectedShowIds.count
    }

    /// Whether any shows are selected
    var hasSelections: Bool {
        !selectedShowIds.isEmpty
    }

    // MARK: - Private

    private func setupSearchDebounce() {
        searchTextSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task { [weak self] in
                    await self?.search(query: query)
                }
            }
            .store(in: &cancellables)
    }
}
