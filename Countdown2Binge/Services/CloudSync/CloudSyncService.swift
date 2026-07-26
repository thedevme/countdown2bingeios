//
//  CloudSyncService.swift
//  Countdown2Binge
//
//  High-level cloud sync orchestration service.
//  Handles union merge sync between local SwiftData and CloudKit.
//

import Foundation
import SwiftData
import CloudKit

/// Result of a sync operation
struct SyncResult: Sendable {
    let showsRestored: Int      // Shows pulled from cloud → added locally
    let showsBackedUp: Int      // Shows pushed from local → added to cloud
    let showsRemoved: Int       // Shows removed during sync
    let errors: [String]        // Any errors encountered

    var isEmpty: Bool {
        showsRestored == 0 && showsBackedUp == 0 && showsRemoved == 0
    }

    var hasErrors: Bool {
        !errors.isEmpty
    }

    /// User-friendly message describing the sync result
    var message: String {
        if hasErrors && showsRestored == 0 && showsBackedUp == 0 {
            return String(localized: "sync_failed")
        }

        var parts: [String] = []

        if showsRestored > 0 {
            parts.append(String(localized: "sync_restored \(showsRestored)"))
        }

        if showsBackedUp > 0 {
            parts.append(String(localized: "sync_backed_up \(showsBackedUp)"))
        }

        if parts.isEmpty {
            return String(localized: "sync_up_to_date")
        }

        return parts.joined(separator: " ")
    }
}

/// Manages cloud sync operations between local storage and CloudKit
@MainActor
@Observable
final class CloudSyncService {
    static let shared = CloudSyncService()

    // MARK: - State

    /// Whether a sync operation is currently in progress
    private(set) var isSyncing = false

    /// Last sync result
    private(set) var lastSyncResult: SyncResult?

    /// Last successful sync timestamp
    private(set) var lastSyncedAt: Date? {
        get { UserDefaults.standard.object(forKey: "CloudSyncService.lastSyncedAt") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "CloudSyncService.lastSyncedAt") }
    }

    // MARK: - Dependencies

    private let cloudKit = CloudKitManager.shared

    // MARK: - Sync Eligibility

    /// Whether cloud sync is available (premium + iCloud)
    var canSync: Bool {
        get async {
            guard PremiumManager.shared.canUseCloudSync else {
                return false
            }
            return await cloudKit.isAvailable
        }
    }

    /// Check sync eligibility and return reason if not available
    func checkSyncEligibility() async -> SyncEligibility {
        if !PremiumManager.shared.canUseCloudSync {
            return .notEligible(reason: .notPremium)
        }

        do {
            let status = try await cloudKit.getAccountStatus()
            switch status {
            case .available:
                return .eligible
            case .noAccount:
                return .notEligible(reason: .noICloudAccount)
            case .restricted:
                return .notEligible(reason: .iCloudRestricted)
            case .couldNotDetermine:
                return .notEligible(reason: .unknown)
            case .temporarilyUnavailable:
                return .notEligible(reason: .temporarilyUnavailable)
            @unknown default:
                return .notEligible(reason: .unknown)
            }
        } catch {
            return .notEligible(reason: .unknown)
        }
    }

    // MARK: - Full Sync (Union Merge)

    /// Perform a full sync between local and cloud data
    /// Uses union merge: combines both sets, resolving conflicts by newest timestamp
    func fullSync(modelContext: ModelContext) async -> SyncResult {
        guard !isSyncing else {
            return SyncResult(showsRestored: 0, showsBackedUp: 0, showsRemoved: 0, errors: ["Sync already in progress"])
        }

        guard await canSync else {
            return SyncResult(showsRestored: 0, showsBackedUp: 0, showsRemoved: 0, errors: ["Sync not available"])
        }

        isSyncing = true
        defer { isSyncing = false }

        var errors: [String] = []
        var showsRestored = 0
        var showsBackedUp = 0

        let store = FollowedShowsStore(modelContext: modelContext)

        do {
            // 1. Fetch all cloud records
            let cloudRecords = try await cloudKit.fetchAllFollowedShows()
            let cloudShows = cloudRecords.compactMap { record -> (tmdbId: Int, followedAt: Date, recordName: String)? in
                guard let tmdbId = record.tmdbId,
                      let followedAt = record.followedAt else {
                    return nil
                }
                return (tmdbId, followedAt, record.recordID.recordName)
            }

            // 2. Get all local follows
            let localShows = try store.getAllFollowed()

            // Create lookup dictionaries
            let cloudByTmdbId = Dictionary(uniqueKeysWithValues: cloudShows.map { ($0.tmdbId, $0) })
            let localByTmdbId = Dictionary(uniqueKeysWithValues: localShows.map { ($0.tmdbId, $0) })

            // 3. Find shows only in cloud (need to restore locally)
            let cloudOnlyIds = Set(cloudByTmdbId.keys).subtracting(Set(localByTmdbId.keys))

            // 4. Find shows only in local (need to push to cloud)
            let localOnlyIds = Set(localByTmdbId.keys).subtracting(Set(cloudByTmdbId.keys))

            // 5. Find unsynced local shows (already in cloud but not marked synced)
            let unsyncedShows = try store.getUnsyncedFollows()
                .filter { cloudByTmdbId[$0.tmdbId] != nil }

            print("CloudSyncService: Cloud-only: \(cloudOnlyIds.count), Local-only: \(localOnlyIds.count), Unsynced: \(unsyncedShows.count)")

            // 6. Restore cloud-only shows locally
            for tmdbId in cloudOnlyIds {
                guard let cloudShow = cloudByTmdbId[tmdbId] else { continue }
                do {
                    // Create local follow with cloud timestamp
                    try store.follow(tmdbId: tmdbId, followedAt: cloudShow.followedAt, cloudKitRecordName: cloudShow.recordName)
                    showsRestored += 1
                    print("CloudSyncService: Restored show \(tmdbId) from cloud")
                } catch {
                    errors.append("Failed to restore show \(tmdbId): \(error.localizedDescription)")
                }
            }

            // 7. Push local-only shows to cloud
            if !localOnlyIds.isEmpty {
                let showsToPush = localOnlyIds.compactMap { tmdbId -> (tmdbId: Int, followedAt: Date)? in
                    guard let show = localByTmdbId[tmdbId] else { return nil }
                    return (show.tmdbId, show.followedAt)
                }

                do {
                    let savedNames = try await cloudKit.saveFollowedShows(showsToPush)
                    showsBackedUp = savedNames.count

                    // Mark as synced and store record names
                    for (index, tmdbId) in localOnlyIds.enumerated() {
                        if index < savedNames.count {
                            try store.markAsSynced(tmdbId: tmdbId, cloudKitRecordName: savedNames[index])
                        }
                    }
                    print("CloudSyncService: Backed up \(showsBackedUp) shows to cloud")
                } catch {
                    errors.append("Failed to backup shows: \(error.localizedDescription)")
                }
            }

            // 8. Mark unsynced shows as synced (they're already in cloud)
            for show in unsyncedShows {
                if let cloudShow = cloudByTmdbId[show.tmdbId] {
                    try? store.markAsSynced(tmdbId: show.tmdbId, cloudKitRecordName: cloudShow.recordName)
                }
            }

            // 9. Sync watch progress
            let localWatchedKeys = WatchProgressManager.shared.watchedEpisodes
            let mergedKeys = await syncWatchProgress(localWatchedKeys: localWatchedKeys)
            if mergedKeys != localWatchedKeys {
                await MainActor.run {
                    WatchProgressManager.shared.restoreFromCloud(mergedKeys)
                }
            }

            lastSyncedAt = Date()

        } catch {
            errors.append("Sync failed: \(error.localizedDescription)")
        }

        let result = SyncResult(
            showsRestored: showsRestored,
            showsBackedUp: showsBackedUp,
            showsRemoved: 0,
            errors: errors
        )

        lastSyncResult = result
        return result
    }

    // MARK: - Incremental Sync Operations

    /// Push a single show to cloud (call after following)
    func pushShow(tmdbId: Int, followedAt: Date, modelContext: ModelContext) async {
        guard await canSync else { return }

        do {
            let recordName = try await cloudKit.saveFollowedShow(tmdbId: tmdbId, followedAt: followedAt)
            let store = FollowedShowsStore(modelContext: modelContext)
            try store.markAsSynced(tmdbId: tmdbId, cloudKitRecordName: recordName)
            print("CloudSyncService: Pushed show \(tmdbId) to cloud")
        } catch {
            print("CloudSyncService: Failed to push show \(tmdbId) - \(error)")
            // Show will remain unsynced and be pushed on next full sync
        }
    }

    /// Remove a show from cloud (call after unfollowing)
    func removeShow(tmdbId: Int) async {
        guard await canSync else { return }

        do {
            try await cloudKit.deleteFollowedShow(tmdbId: tmdbId)
            print("CloudSyncService: Removed show \(tmdbId) from cloud")

            // Also remove watch progress for this show and push updated progress
            let localWatchedKeys = await MainActor.run { WatchProgressManager.shared.watchedEpisodes }
            let filteredKeys = localWatchedKeys.filter { !$0.hasPrefix("\(tmdbId)-") }
            if filteredKeys.count != localWatchedKeys.count {
                try await cloudKit.saveAllWatchProgress(watchedEpisodeKeys: filteredKeys)
            }
        } catch let error as CKError where error.code == .unknownItem {
            // Record didn't exist in cloud, that's fine
            print("CloudSyncService: Show \(tmdbId) not in cloud, skipping delete")
        } catch {
            print("CloudSyncService: Failed to remove show \(tmdbId) - \(error)")
        }
    }

    // MARK: - Watch Progress Sync

    /// Push all watch progress to cloud
    func pushWatchProgress(watchedEpisodeKeys: Set<String>) async {
        guard await canSync else { return }

        guard !watchedEpisodeKeys.isEmpty else {
            // If no watched episodes, delete cloud record
            try? await cloudKit.deleteAllWatchProgress()
            return
        }

        do {
            try await cloudKit.saveAllWatchProgress(watchedEpisodeKeys: watchedEpisodeKeys)
            print("CloudSyncService: Pushed watch progress (\(watchedEpisodeKeys.count) episodes)")
        } catch {
            print("CloudSyncService: Failed to push watch progress - \(error)")
        }
    }

    /// Sync watch progress between local and cloud (union merge)
    /// Returns the merged set of watched episode keys
    func syncWatchProgress(localWatchedKeys: Set<String>) async -> Set<String> {
        guard await canSync else { return localWatchedKeys }

        do {
            // Fetch cloud watch progress
            let cloudWatchedKeys = try await cloudKit.fetchAllWatchProgress() ?? []

            // Union merge: combine both sets
            let mergedKeys = localWatchedKeys.union(cloudWatchedKeys)

            // If there are differences, push the merged set to cloud
            if mergedKeys != cloudWatchedKeys {
                try await cloudKit.saveAllWatchProgress(watchedEpisodeKeys: mergedKeys)
                print("CloudSyncService: Synced watch progress - merged \(mergedKeys.count) episodes")
            }

            return mergedKeys
        } catch {
            print("CloudSyncService: Watch progress sync failed - \(error)")
            return localWatchedKeys
        }
    }

    // MARK: - Sync Unsynced Shows

    /// Push all unsynced shows to cloud
    func syncUnsyncedShows(modelContext: ModelContext) async {
        guard await canSync else { return }

        let store = FollowedShowsStore(modelContext: modelContext)

        do {
            let unsyncedShows = try store.getUnsyncedFollows()
            guard !unsyncedShows.isEmpty else {
                print("CloudSyncService: No unsynced shows")
                return
            }

            let showsToPush = unsyncedShows.map { ($0.tmdbId, $0.followedAt) }
            let savedNames = try await cloudKit.saveFollowedShows(showsToPush)

            // Mark as synced
            for (index, show) in unsyncedShows.enumerated() {
                if index < savedNames.count {
                    try store.markAsSynced(tmdbId: show.tmdbId, cloudKitRecordName: savedNames[index])
                }
            }

            print("CloudSyncService: Synced \(savedNames.count) previously unsynced shows")
        } catch {
            print("CloudSyncService: Failed to sync unsynced shows - \(error)")
        }
    }

    // MARK: - Account Deletion

    /// Delete all cloud data (for account deletion compliance)
    func deleteAllCloudData() async throws {
        try await cloudKit.deleteAllData()
        lastSyncedAt = nil
        lastSyncResult = nil
        print("CloudSyncService: Deleted all cloud data")
    }

    // MARK: - Subscriptions

    /// Set up CloudKit subscriptions for real-time sync
    func setupSubscriptions() async {
        guard await canSync else { return }

        do {
            try await cloudKit.subscribeToChanges()
        } catch {
            print("CloudSyncService: Failed to setup subscriptions - \(error)")
        }
    }
}

// MARK: - Sync Eligibility

enum SyncEligibility: Sendable {
    case eligible
    case notEligible(reason: SyncIneligibilityReason)
}

enum SyncIneligibilityReason: Sendable {
    case notPremium
    case noICloudAccount
    case iCloudRestricted
    case temporarilyUnavailable
    case unknown

    var localizedDescription: String {
        switch self {
        case .notPremium:
            return String(localized: "sync_requires_premium")
        case .noICloudAccount:
            return String(localized: "sync_no_icloud")
        case .iCloudRestricted:
            return String(localized: "sync_icloud_restricted")
        case .temporarilyUnavailable:
            return String(localized: "sync_temporarily_unavailable")
        case .unknown:
            return String(localized: "sync_unavailable")
        }
    }
}
