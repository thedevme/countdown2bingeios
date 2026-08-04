//
//  FollowedShowsStore.swift
//  Countdown2Binge
//
//  Data access layer for FollowedShow model.
//  Handles following/unfollowing and cache updates.
//

import Foundation
import SwiftData

@MainActor
final class FollowedShowsStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Follow/Unfollow

    /// Follow a show by TMDB ID
    func follow(tmdbId: Int) throws {
        // Check if already following
        guard !isFollowing(tmdbId: tmdbId) else { return }

        let followedShow = FollowedShow(tmdbId: tmdbId)
        modelContext.insert(followedShow)
        try modelContext.save()
    }

    /// Follow a show with initial data
    func follow(show: ShowData) throws {
        // Check if already following
        if let existing = getFollowedShow(tmdbId: show.id) {
            // Update existing cache
            if existing.cachedData == nil {
                existing.cachedData = CachedShowData(tmdbId: show.id, name: show.name)
            }
            existing.cachedData?.update(from: show)
            existing.lastRefreshedAt = Date()
        } else {
            // Create new
            let followedShow = FollowedShow(tmdbId: show.id)
            let cachedData = CachedShowData(tmdbId: show.id, name: show.name)
            cachedData.update(from: show)
            followedShow.cachedData = cachedData
            followedShow.lastRefreshedAt = Date()
            modelContext.insert(followedShow)
        }

        try modelContext.save()
    }

    /// Follow a show from ShowSummary (minimal data)
    func follow(summary: ShowSummary) throws {
        guard !isFollowing(tmdbId: summary.id) else { return }

        let followedShow = FollowedShow(tmdbId: summary.id)
        let cachedData = CachedShowData(
            tmdbId: summary.id,
            name: summary.name,
            posterPath: summary.posterPath,
            backdropPath: summary.backdropPath
        )
        followedShow.cachedData = cachedData
        modelContext.insert(followedShow)
        try modelContext.save()
    }

    /// Unfollow a show
    func unfollow(tmdbId: Int) throws {
        guard let followedShow = getFollowedShow(tmdbId: tmdbId) else { return }
        modelContext.delete(followedShow)
        try modelContext.save()
    }

    // MARK: - Query

    /// Check if a show is being followed
    func isFollowing(tmdbId: Int) -> Bool {
        getFollowedShow(tmdbId: tmdbId) != nil
    }

    /// Get a specific followed show
    func getFollowedShow(tmdbId: Int) -> FollowedShow? {
        let descriptor = FetchDescriptor<FollowedShow>(
            predicate: #Predicate { $0.tmdbId == tmdbId }
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// Get all followed shows
    func getAllFollowed() throws -> [FollowedShow] {
        let descriptor = FetchDescriptor<FollowedShow>(
            sortBy: [SortDescriptor(\.followedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get all followed shows as ShowData (for timeline)
    /// Decodes JSON in parallel off the main thread to avoid UI blocking
    /// Uses cached finaleDate/premiereDate from SwiftData for accurate countdowns
    func getAllFollowedAsShowData() async throws -> [ShowData] {
        let followedShows = try getAllFollowed()

        // Extract JSON data, cached dates, and spinoff count on main thread (SwiftData access)
        var showDataWithInfo: [(Data, Date?, Date?, Int)] = []
        for followed in followedShows {
            if let jsonData = followed.cachedData?.showDataJSON {
                showDataWithInfo.append((
                    jsonData,
                    followed.cachedData?.finaleDate,
                    followed.cachedData?.premiereDate,
                    followed.relatedShowIds.count
                ))
            }
        }

        // Decode all shows in parallel using TaskGroup
        var shows: [ShowData] = []
        try await withThrowingTaskGroup(of: ShowData?.self) { group in
            for (jsonData, finaleDate, premiereDate, spinoffCount) in showDataWithInfo {
                group.addTask {
                    guard var show = try? JSONDecoder().decode(ShowData.self, from: jsonData) else {
                        return nil
                    }
                    // Override with cached dates and spinoff count from SwiftData
                    show.cachedFinaleDate = finaleDate
                    show.cachedPremiereDate = premiereDate
                    show.spinoffCount = spinoffCount
                    return show
                }
            }

            for try await show in group {
                if let show {
                    shows.append(show)
                }
            }
        }

        return shows
    }

    /// Get count of followed shows
    func getFollowedCount() -> Int {
        let descriptor = FetchDescriptor<FollowedShow>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Cache Management

    /// Update the cache for a followed show
    func updateCache(for tmdbId: Int, with show: ShowData) throws {
        guard let followedShow = getFollowedShow(tmdbId: tmdbId) else {
            throw FollowedShowsStoreError.notFollowing
        }

        if followedShow.cachedData == nil {
            followedShow.cachedData = CachedShowData(tmdbId: tmdbId, name: show.name)
        }

        followedShow.cachedData?.update(from: show)
        followedShow.lastRefreshedAt = Date()
        try modelContext.save()
    }

    // MARK: - Spinoffs/Related Shows

    /// Update related show IDs for a followed show
    func updateRelatedShowIds(for tmdbId: Int, relatedIds: [Int]) throws {
        guard let followedShow = getFollowedShow(tmdbId: tmdbId) else {
            throw FollowedShowsStoreError.notFollowing
        }
        followedShow.relatedShowIds = relatedIds
        try modelContext.save()
    }

    /// Get related show IDs for a followed show
    func getRelatedShowIds(for tmdbId: Int) -> [Int] {
        guard let followedShow = getFollowedShow(tmdbId: tmdbId) else {
            return []
        }
        return followedShow.relatedShowIds
    }

    /// Save franchise data for a followed show (called after following)
    func saveFranchiseData(for tmdbId: Int) async {
        // Ensure franchise data is loaded
        await FranchiseService.shared.fetchFranchises()

        // Get related show IDs
        let relatedIds = FranchiseService.shared.relatedShowIds(forShowId: tmdbId)

        guard !relatedIds.isEmpty else { return }

        // Save to database
        try? updateRelatedShowIds(for: tmdbId, relatedIds: relatedIds)
        print("FollowedShowsStore: Saved \(relatedIds.count) related shows for \(tmdbId)")
    }

    // MARK: - Sync

    /// Mark a show as synced to cloud
    func markAsSynced(tmdbId: Int, cloudKitRecordName: String? = nil) throws {
        guard let followedShow = getFollowedShow(tmdbId: tmdbId) else { return }
        followedShow.isSynced = true
        if let recordName = cloudKitRecordName {
            followedShow.cloudKitRecordName = recordName
        }
        try modelContext.save()
    }

    /// Get all unsynced follows (for cloud sync)
    func getUnsyncedFollows() throws -> [FollowedShow] {
        let descriptor = FetchDescriptor<FollowedShow>(
            predicate: #Predicate { $0.isSynced == false }
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Cloud Restore

    /// Follow a show restored from cloud (with specific timestamp and record name)
    func follow(tmdbId: Int, followedAt: Date, cloudKitRecordName: String) throws {
        // Check if already following
        guard !isFollowing(tmdbId: tmdbId) else {
            // Update existing record with cloud data
            if let existing = getFollowedShow(tmdbId: tmdbId) {
                existing.cloudKitRecordName = cloudKitRecordName
                existing.isSynced = true
                try modelContext.save()
            }
            return
        }

        let followedShow = FollowedShow(
            tmdbId: tmdbId,
            followedAt: followedAt,
            isSynced: true,
            cloudKitRecordName: cloudKitRecordName
        )
        modelContext.insert(followedShow)
        try modelContext.save()
    }

    /// Get all TMDB IDs of followed shows
    func getAllFollowedTmdbIds() throws -> Set<Int> {
        let descriptor = FetchDescriptor<FollowedShow>()
        let shows = try modelContext.fetch(descriptor)
        return Set(shows.map { $0.tmdbId })
    }
}

// MARK: - Errors

enum FollowedShowsStoreError: Error {
    case notFollowing
    case alreadyFollowing
}
