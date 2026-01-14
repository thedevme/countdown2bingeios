//
//  FollowedShowsStore.swift
//  Countdown2Binge
//

import Foundation
import SwiftData

/// Errors that can occur during store operations
enum StoreError: Error, LocalizedError {
    case showNotFound
    case saveFailed(Error)
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .showNotFound:
            return "Show not found"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch: \(error.localizedDescription)"
        }
    }
}

/// Protocol for followed shows storage (enables testing with mocks)
protocol FollowedShowsStoreProtocol {
    func follow(showId: Int) throws
    func followWithCache(showId: Int, show: Show) throws
    func unfollow(showId: Int) throws
    func isFollowing(showId: Int) throws -> Bool
    func getFollowedShow(id: Int) throws -> FollowedShow?
    func getAllFollowed() throws -> [FollowedShow]
    func updateCache(for showId: Int, with show: Show) throws
}

/// Store for managing followed shows in SwiftData
@MainActor
final class FollowedShowsStore: FollowedShowsStoreProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Follow/Unfollow

    /// Follow a show by its TMDB ID
    func follow(showId: Int) throws {
        // Check if already following
        if try isFollowing(showId: showId) {
            return
        }

        let followedShow = FollowedShow(tmdbId: showId)
        modelContext.insert(followedShow)

        do {
            try modelContext.save()
        } catch {
            throw StoreError.saveFailed(error)
        }
    }

    /// Follow a show and populate cache atomically (single save)
    func followWithCache(showId: Int, show: Show) throws {
        // Check if already following
        if try isFollowing(showId: showId) {
            // If already following, just update cache
            try updateCache(for: showId, with: show)
            return
        }

        // Create FollowedShow and CachedShowData
        let followedShow = FollowedShow(tmdbId: showId)
        let cachedData = CachedShowData(from: show)

        // Insert BOTH models into context explicitly
        modelContext.insert(followedShow)
        modelContext.insert(cachedData)

        // Set up the relationship AFTER both are in context
        followedShow.cachedData = cachedData
        followedShow.lastRefreshedAt = Date()

        do {
            try modelContext.save()
        } catch {
            throw StoreError.saveFailed(error)
        }
    }

    /// Unfollow a show by its TMDB ID
    func unfollow(showId: Int) throws {
        guard let followedShow = try getFollowedShow(id: showId) else {
            return // Already not following
        }

        modelContext.delete(followedShow)

        do {
            try modelContext.save()
        } catch {
            throw StoreError.saveFailed(error)
        }
    }

    /// Check if a show is being followed
    func isFollowing(showId: Int) throws -> Bool {
        try getFollowedShow(id: showId) != nil
    }

    // MARK: - Fetch

    /// Get a specific followed show by TMDB ID
    func getFollowedShow(id: Int) throws -> FollowedShow? {
        let descriptor = FetchDescriptor<FollowedShow>(
            predicate: #Predicate { $0.tmdbId == id }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            throw StoreError.fetchFailed(error)
        }
    }

    /// Get all followed shows
    func getAllFollowed() throws -> [FollowedShow] {
        let descriptor = FetchDescriptor<FollowedShow>(
            sortBy: [SortDescriptor(\.followedAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw StoreError.fetchFailed(error)
        }
    }

    /// Get followed shows that need refresh
    func getShowsNeedingRefresh() throws -> [FollowedShow] {
        let allFollowed = try getAllFollowed()
        return allFollowed.filter { $0.needsRefresh }
    }

    // MARK: - Cache Management

    /// Update cached data for a followed show
    func updateCache(for showId: Int, with show: Show) throws {
        guard let followedShow = try getFollowedShow(id: showId) else {
            throw StoreError.showNotFound
        }

        followedShow.updateCache(from: show)

        do {
            try modelContext.save()
        } catch {
            throw StoreError.saveFailed(error)
        }
    }

    // MARK: - Queries by Lifecycle State

    /// Get all followed shows grouped by lifecycle state
    func getShowsByLifecycleState() throws -> [ShowLifecycleState: [FollowedShow]] {
        let allFollowed = try getAllFollowed()

        var grouped: [ShowLifecycleState: [FollowedShow]] = [:]

        for state in ShowLifecycleState.allCases {
            grouped[state] = []
        }

        for show in allFollowed {
            let state = show.cachedData?.lifecycleState ?? .anticipated
            grouped[state, default: []].append(show)
        }

        return grouped
    }

    /// Get count of followed shows
    func getFollowedCount() throws -> Int {
        let descriptor = FetchDescriptor<FollowedShow>()
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            throw StoreError.fetchFailed(error)
        }
    }
}
