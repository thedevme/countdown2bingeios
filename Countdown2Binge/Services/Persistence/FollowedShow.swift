//
//  FollowedShow.swift
//  Countdown2Binge
//
//  SwiftData model for tracking followed shows.
//  Separates following state from show data cache.
//

import Foundation
import SwiftData

@Model
final class FollowedShow {
    /// TMDB ID of the show
    @Attribute(.unique) var tmdbId: Int

    /// When the user followed this show
    var followedAt: Date

    /// Last time we fetched fresh data from TMDB
    var lastRefreshedAt: Date?

    /// Whether this follow has been synced to cloud
    var isSynced: Bool

    /// CloudKit record name for this follow (for bi-directional sync)
    var cloudKitRecordName: String?

    /// Cached show data (metadata from TMDB)
    @Relationship(deleteRule: .cascade)
    var cachedData: CachedShowData?

    /// Related show IDs from franchise data (spinoffs)
    var relatedShowIds: [Int]

    init(tmdbId: Int, followedAt: Date = Date(), isSynced: Bool = false, cloudKitRecordName: String? = nil) {
        self.tmdbId = tmdbId
        self.followedAt = followedAt
        self.lastRefreshedAt = nil
        self.isSynced = isSynced
        self.cloudKitRecordName = cloudKitRecordName
        self.relatedShowIds = []
    }

    /// Whether this show has spinoffs/related shows
    var hasSpinoffs: Bool {
        !relatedShowIds.isEmpty
    }

    /// Check if show data needs refresh
    /// - Airing shows: refresh every 6 hours (episode dates change frequently)
    /// - Other shows: refresh every 24 hours
    var needsRefresh: Bool {
        guard let lastRefreshed = lastRefreshedAt else {
            return true // Never refreshed
        }

        let hoursSinceRefresh = Date().timeIntervalSince(lastRefreshed) / 3600

        // Airing shows need more frequent updates
        if let cached = cachedData, cached.lifecycleStateRaw == "airing" {
            return hoursSinceRefresh >= 6
        }

        return hoursSinceRefresh >= 24
    }
}
