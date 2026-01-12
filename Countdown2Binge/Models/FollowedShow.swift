//
//  FollowedShow.swift
//  Countdown2Binge
//

import Foundation
import SwiftData

/// A TV show the user is following.
/// This is the primary persisted model—tracks user intent to follow a show.
@Model
final class FollowedShow {
    /// TMDB show ID (unique identifier)
    @Attribute(.unique) var tmdbId: Int

    /// When the user followed this show
    var followedAt: Date

    /// Cached show data for offline access
    @Relationship(deleteRule: .cascade)
    var cachedData: CachedShowData?

    /// Last time we refreshed data from TMDB
    var lastRefreshedAt: Date?

    init(tmdbId: Int, followedAt: Date = Date()) {
        self.tmdbId = tmdbId
        self.followedAt = followedAt
    }
}

// MARK: - Convenience

extension FollowedShow {
    /// Whether cached data needs refresh (stale after 24 hours)
    var needsRefresh: Bool {
        guard let lastRefreshedAt else { return true }
        let staleInterval: TimeInterval = 24 * 60 * 60 // 24 hours
        return Date().timeIntervalSince(lastRefreshedAt) > staleInterval
    }

    /// Update cached data from a Show domain model
    func updateCache(from show: Show) {
        if cachedData == nil {
            cachedData = CachedShowData(from: show)
        } else {
            cachedData?.update(from: show)
        }
        lastRefreshedAt = Date()
    }
}
