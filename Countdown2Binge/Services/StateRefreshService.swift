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
    // MARK: - Constants

    private static let lastRefreshKey = "lastFullRefreshTimestamp"
    private static let refreshIntervalSeconds: TimeInterval = 24 * 60 * 60 // 24 hours

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let tmdbService: TMDBServiceProtocol

    /// Badge manager for notifying tab badges of state changes
    var badgeManager: TabBadgeManager?

    // MARK: - State

    private var lastRefreshDate: Date? {
        get { UserDefaults.standard.object(forKey: Self.lastRefreshKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Self.lastRefreshKey) }
    }

    init(modelContainer: ModelContainer, tmdbService: TMDBServiceProtocol? = nil, badgeManager: TabBadgeManager? = nil) {
        self.modelContainer = modelContainer
        self.tmdbService = tmdbService ?? TMDBService()
        self.badgeManager = badgeManager
    }

    /// Check if 24 hours have passed since last full refresh
    private func shouldPerformFullRefresh() -> Bool {
        guard let lastRefresh = lastRefreshDate else { return true }
        return Date().timeIntervalSince(lastRefresh) >= Self.refreshIntervalSeconds
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

            // Update lifecycle states (fast, local operation)
            for followedShow in followedShows {
                updateLifecycleState(for: followedShow)
            }

            // Fetch from API in parallel if requested
            if fetchFromAPI {
                let showsToRefresh = followedShows.filter { forceRefresh || $0.needsRefresh }
                let tmdbIds = showsToRefresh.map { $0.tmdbId }

                if !tmdbIds.isEmpty {
                    // Fetch all shows in parallel
                    let refreshedShows = try await tmdbService.getMultipleShowDetails(ids: tmdbIds)

                    // Update caches
                    for show in refreshedShows {
                        try? store.updateCache(for: show.id, with: show)

                        // Also update SwiftData Series model
                        let seriesStore = SeriesStore(modelContext: context)
                        try? seriesStore.updateMetadata(for: show.id, from: show)
                    }
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

        // Get previous state
        let previousStateRaw = cachedData.lifecycleStateRaw
        let previousState = ShowLifecycleState(rawValue: previousStateRaw)

        // Recompute lifecycle state based on current date
        let currentState = show.lifecycleState

        // Update if changed
        if cachedData.lifecycleStateRaw != currentState.rawValue {
            cachedData.lifecycleStateRaw = currentState.rawValue

            // Check for transition to binge-ready state
            if let previous = previousState {
                let wasBingeable = previous == .ended || previous == .completed || previous == .cancelled
                let isBingeable = currentState == .ended || currentState == .completed || currentState == .cancelled

                // If show transitioned from non-bingeable to bingeable, trigger badge
                if !wasBingeable && isBingeable {
                    badgeManager?.bingeReadyBadge = true
                }
            }
        }
    }

}

// MARK: - App Lifecycle Integration

extension StateRefreshService {
    /// Called when app launches - force refresh if 24+ hours since last refresh
    func onAppLaunch() async {
        if shouldPerformFullRefresh() {
            await forceRefreshAllShows()
            lastRefreshDate = Date()
        } else {
            // Still recalculate states based on current date
            await refreshStatesOnly()
        }
    }

    /// Called when app comes to foreground - just update states (fast)
    func onAppForeground() async {
        await refreshStatesOnly()
    }
}
