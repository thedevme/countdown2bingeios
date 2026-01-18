//
//  StateRefreshService.swift
//  Countdown2Binge
//

import Foundation
import SwiftData

/// Service for refreshing show states based on current date.
/// Updates lifecycle states and optionally fetches fresh data from TMDB.
@MainActor
final class StateRefreshService {
    private let modelContainer: ModelContainer
    private let tmdbService: TMDBServiceProtocol

    init(modelContainer: ModelContainer, tmdbService: TMDBServiceProtocol? = nil) {
        self.modelContainer = modelContainer
        self.tmdbService = tmdbService ?? TMDBService()
    }

    // MARK: - Refresh All Shows

    /// Refresh all followed shows.
    /// Updates lifecycle states based on current date and optionally fetches fresh data.
    /// - Parameters:
    ///   - fetchFromAPI: If true, also fetches fresh data from TMDB
    ///   - forceRefresh: If true, refreshes all shows regardless of staleness
    func refreshAllShows(fetchFromAPI: Bool = false, forceRefresh: Bool = false) async {
        let context = modelContainer.mainContext
        let store = FollowedShowsStore(modelContext: context)

        do {
            let followedShows = try store.getAllFollowed()

            for followedShow in followedShows {
                // Update lifecycle state based on current date
                updateLifecycleState(for: followedShow)

                // Optionally fetch fresh data from TMDB
                // Force refresh bypasses the staleness check
                if fetchFromAPI && (forceRefresh || followedShow.needsRefresh) {
                    await refreshFromAPI(followedShow: followedShow, store: store)
                }
            }

            // Save all changes
            try context.save()
        } catch {
            // Silently fail - refresh errors are non-critical
        }
    }

    /// Refresh states only (no API calls) - fast operation for app foreground
    func refreshStatesOnly() async {
        await refreshAllShows(fetchFromAPI: false)
    }

    /// Full refresh including API calls for stale shows
    func refreshWithAPIData() async {
        await refreshAllShows(fetchFromAPI: true)
    }

    /// Force refresh all shows from API regardless of staleness
    func forceRefreshAllShows() async {
        await refreshAllShows(fetchFromAPI: true, forceRefresh: true)
    }

    // MARK: - Single Show Refresh

    /// Refresh a single show from TMDB
    func refreshShow(tmdbId: Int) async throws {
        let context = modelContainer.mainContext
        let store = FollowedShowsStore(modelContext: context)

        let show = try await tmdbService.getShowDetails(id: tmdbId)
        try store.updateCache(for: tmdbId, with: show)
    }

    // MARK: - Private Helpers

    /// Update the lifecycle state for a followed show based on current date
    private func updateLifecycleState(for followedShow: FollowedShow) {
        guard let cachedData = followedShow.cachedData,
              let show = cachedData.toShow() else {
            return
        }

        // Recompute lifecycle state based on current date
        let currentState = show.lifecycleState

        // Update if changed
        if cachedData.lifecycleStateRaw != currentState.rawValue {
            cachedData.lifecycleStateRaw = currentState.rawValue
        }
    }

    /// Fetch fresh data from TMDB and update cache
    private func refreshFromAPI(followedShow: FollowedShow, store: FollowedShowsStore) async {
        do {
            let show = try await tmdbService.getShowDetails(id: followedShow.tmdbId)
            try store.updateCache(for: followedShow.tmdbId, with: show)
        } catch {
            // Silently fail - individual show refresh errors are non-critical
        }
    }
}

// MARK: - App Lifecycle Integration

extension StateRefreshService {
    /// Called when app launches - force refresh all shows from API
    func onAppLaunch() async {
        await forceRefreshAllShows()
    }

    /// Called when app comes to foreground - just update states (fast)
    func onAppForeground() async {
        await refreshStatesOnly()
    }
}
