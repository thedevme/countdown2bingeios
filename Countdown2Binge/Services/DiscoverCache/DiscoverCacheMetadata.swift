//
//  DiscoverCacheMetadata.swift
//  Countdown2Binge
//
//  Tracks when the Discover cache was last refreshed.
//

import Foundation
import SwiftData

@Model
final class DiscoverCacheMetadata {
    @Attribute(.unique) var id: String
    var lastFetchDate: Date?

    init(id: String = "discover_cache") {
        self.id = id
        self.lastFetchDate = nil
    }

    /// Check if cache is stale (older than 7 days)
    var isStale: Bool {
        guard let lastFetch = lastFetchDate else { return true }
        let daysSinceLastFetch = Calendar.current.dateComponents([.day], from: lastFetch, to: Date()).day ?? 0
        return daysSinceLastFetch >= 7
    }

    /// Mark cache as refreshed
    func markRefreshed() {
        lastFetchDate = Date()
    }
}
