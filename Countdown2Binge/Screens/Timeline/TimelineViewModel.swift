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

    /// Shows currently releasing episodes (sorted by finale date, soonest first; no date = last, then alphabetical)
    var airingNowShows: [ShowData] {
        followedShows
            .filter { $0.timelineCategory == .airingNow }
            .sorted { lhs, rhs in
                switch (lhs.daysUntilFinale, rhs.daysUntilFinale) {
                case let (l?, r?):
                    return l < r                          // Both have dates: soonest first
                case (_?, nil):
                    return true                           // Has date beats no date
                case (nil, _?):
                    return false                          // No date goes after
                case (nil, nil):
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
            }
    }

    /// Shows with known premiere date (sorted by premiere date, soonest first; no date = last, then alphabetical)
    var premieringSoonShows: [ShowData] {
        followedShows
            .filter { $0.timelineCategory == .premieringSoon }
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

    // MARK: - Init

    init() {
        // Listen for cloud sync completions to refresh data
        NotificationCenter.default.addObserver(
            forName: CloudSyncService.didSyncNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.loadFollowedShows()
            }
        }
    }

    // MARK: - Public API

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        self.store = FollowedShowsStore(modelContext: modelContext)
    }

    func loadFollowedShows() async {
        guard let store else { return }

        isLoading = true

        do {
            followedShows = try await store.getAllFollowedAsShowData()
            lastRefreshedAt = Date()
        } catch {
            print("Error loading followed shows: \(error)")
            followedShows = []
        }

        isLoading = false
    }

    func refresh() async {
        await loadFollowedShows()
    }

    /// Unfollow a show
    func unfollowShow(_ series: Series) async {
        guard let store else { return }

        do {
            try store.unfollow(tmdbId: series.tmdbId)
            // Remove from local list
            followedShows.removeAll { $0.id == series.tmdbId }

            // Remove from cloud
            Task { await CloudSyncService.shared.removeShow(tmdbId: series.tmdbId) }
        } catch {
            print("Error unfollowing show: \(error)")
        }
    }

    /// Get Series by show ID for navigation
    func getSeries(for showId: Int) -> Series? {
        guard let modelContext else { return nil }
        let seriesStore = SeriesStore(modelContext: modelContext)
        return seriesStore.fetchSeries(tmdbId: showId)
    }

    /// Get anticipated season number for display (numberOfSeasons + 1)
    func anticipatedSeasonNumber(for show: ShowData) -> Int {
        show.numberOfSeasons + 1
    }
}
