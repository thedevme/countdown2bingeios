//
//  CloudSyncing.swift
//  Countdown2Binge
//
//  Protocol for iCloud sync operations.
//  Production: CloudKitManager conforms to this.
//  Testing: A mock conforms to this to avoid CloudKit access.
//

import Foundation
import CloudKit

/// Protocol for iCloud sync operations, enabling dependency injection.
/// This allows SeriesManager to be tested without touching CloudKit.
@MainActor
protocol CloudSyncing {
    /// Check if iCloud account is available for CloudKit
    var isAvailable: Bool { get async }

    /// Save all watch progress to CloudKit
    @discardableResult
    func saveAllWatchProgress(watchedEpisodeKeys: Set<String>) async throws -> String

    /// Fetch all watch progress from CloudKit
    func fetchAllWatchProgress() async throws -> Set<String>?

    /// Save a followed show to CloudKit
    @discardableResult
    func saveFollowedShow(tmdbId: Int, followedAt: Date, recordName: String?) async throws -> String

    /// Delete a followed show from CloudKit by TMDB ID
    func deleteFollowedShow(tmdbId: Int) async throws

    /// Delete multiple followed shows from CloudKit
    func deleteFollowedShows(_ tmdbIds: [Int]) async throws

    /// Delete all watch progress from CloudKit
    func deleteAllWatchProgress() async throws

    /// Fetch all followed shows from CloudKit
    func fetchAllFollowedShows() async throws -> [CKRecord]
}

// MARK: - Default Parameters

extension CloudSyncing {
    /// Convenience overload with default recordName = nil
    @discardableResult
    func saveFollowedShow(tmdbId: Int, followedAt: Date) async throws -> String {
        try await saveFollowedShow(tmdbId: tmdbId, followedAt: followedAt, recordName: nil)
    }
}
