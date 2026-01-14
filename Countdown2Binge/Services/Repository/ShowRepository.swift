//
//  ShowRepository.swift
//  Countdown2Binge
//

import Foundation
import SwiftData

/// Protocol for show repository operations (enables testing with mocks)
protocol ShowRepositoryProtocol {
    func save(_ show: Show) async throws
    func fetchAllShows() -> [Show]
    func fetchShow(byTmdbId id: Int) -> Show?
    func fetchTimelineShows() -> [Show]
    func fetchBingeReadySeasons() -> [Season]
    func delete(_ show: Show) async throws
    func isShowFollowed(tmdbId: Int) -> Bool
    func markSeasonWatched(showId: Int, seasonNumber: Int) async throws
    func markEpisodeWatched(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool) async throws
}

/// Repository for managing shows with higher-level domain operations.
/// Wraps FollowedShowsStore and provides domain model access.
@MainActor
final class ShowRepository: ShowRepositoryProtocol {
    private let store: FollowedShowsStore

    init(store: FollowedShowsStore) {
        self.store = store
    }

    convenience init(modelContext: ModelContext) {
        self.init(store: FollowedShowsStore(modelContext: modelContext))
    }

    // MARK: - Save

    /// Save a show to the repository (follow and cache atomically)
    func save(_ show: Show) async throws {
        // Follow and cache in a single save to avoid race condition
        // where @Query fires before cachedData is populated
        try store.followWithCache(showId: show.id, show: show)
    }

    // MARK: - Fetch All

    /// Fetch all followed shows as domain models
    func fetchAllShows() -> [Show] {
        guard let followedShows = try? store.getAllFollowed() else {
            return []
        }
        return followedShows.compactMap { $0.cachedData?.toShow() }
    }

    // MARK: - Fetch Single

    /// Fetch a single show by its TMDB ID
    func fetchShow(byTmdbId id: Int) -> Show? {
        guard let followedShow = try? store.getFollowedShow(id: id) else {
            return nil
        }
        return followedShow.cachedData?.toShow()
    }

    // MARK: - Timeline Shows

    /// Fetch shows for the timeline (returning or in production only)
    func fetchTimelineShows() -> [Show] {
        let allShows = fetchAllShows()
        return allShows.filter { show in
            switch show.status {
            case .returning, .inProduction:
                return true
            case .ended, .cancelled, .planned, .pilot:
                return false
            }
        }
    }

    // MARK: - Binge Ready Seasons

    /// Fetch all seasons that are ready to binge across all followed shows
    func fetchBingeReadySeasons() -> [Season] {
        let allShows = fetchAllShows()
        var bingeReadySeasons: [Season] = []

        for show in allShows {
            // Get seasons that are binge ready (complete and not watched)
            let readySeasons = show.seasons.filter { season in
                season.seasonNumber > 0 && season.isBingeReady
            }
            bingeReadySeasons.append(contentsOf: readySeasons)
        }

        // Sort by finale date (most recent first)
        return bingeReadySeasons.sorted { season1, season2 in
            guard let date1 = season1.finaleDate else { return false }
            guard let date2 = season2.finaleDate else { return true }
            return date1 > date2
        }
    }

    // MARK: - Delete

    /// Delete (unfollow) a show from the repository
    func delete(_ show: Show) async throws {
        try store.unfollow(showId: show.id)
    }

    // MARK: - Check Following Status

    /// Check if a show is currently followed
    func isShowFollowed(tmdbId: Int) -> Bool {
        (try? store.isFollowing(showId: tmdbId)) ?? false
    }

    // MARK: - Mark Season Watched

    /// Mark a specific season as watched
    func markSeasonWatched(showId: Int, seasonNumber: Int) async throws {
        guard var show = fetchShow(byTmdbId: showId) else {
            throw StoreError.showNotFound
        }

        // Find and update the season
        guard let seasonIndex = show.seasons.firstIndex(where: { $0.seasonNumber == seasonNumber }) else {
            throw StoreError.showNotFound
        }

        show.seasons[seasonIndex].watchedDate = Date()

        // Save the updated show
        try store.updateCache(for: showId, with: show)
    }

    // MARK: - Mark Episode Watched

    /// Mark a specific episode as watched or unwatched
    func markEpisodeWatched(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool) async throws {
        guard var show = fetchShow(byTmdbId: showId) else {
            throw StoreError.showNotFound
        }

        // Find the season
        guard let seasonIndex = show.seasons.firstIndex(where: { $0.seasonNumber == seasonNumber }) else {
            throw StoreError.showNotFound
        }

        // Find the episode
        guard let episodeIndex = show.seasons[seasonIndex].episodes.firstIndex(where: { $0.episodeNumber == episodeNumber }) else {
            throw StoreError.showNotFound
        }

        // Update the episode
        show.seasons[seasonIndex].episodes[episodeIndex].watchedDate = watched ? Date() : nil

        // Save the updated show
        try store.updateCache(for: showId, with: show)
    }
}
