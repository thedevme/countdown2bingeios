//
//  CloudKitManager.swift
//  Countdown2Binge
//
//  Low-level CloudKit operations for syncing followed shows.
//

import Foundation
import CloudKit

/// Manages CloudKit container and database operations
@MainActor
final class CloudKitManager {
    static let shared = CloudKitManager()

    // MARK: - CloudKit Configuration

    /// CloudKit container identifier - must match entitlements
    private static let containerIdentifier = "iCloud.io.DesignToSwiftUI.Countdown2Binge"

    /// CloudKit container
    private lazy var container: CKContainer = {
        CKContainer(identifier: Self.containerIdentifier)
    }()

    private var privateDB: CKDatabase { container.privateCloudDatabase }

    // MARK: - Record Type Constants

    static let followedShowRecordType = "FollowedShow"
    static let watchProgressRecordType = "WatchProgress"
    static let userSettingsRecordType = "UserSettings"

    // MARK: - Field Keys

    enum FieldKey {
        static let tmdbId = "tmdbId"
        static let followedAt = "followedAt"
        static let lastModified = "lastModified"

        // Watch Progress fields
        static let seriesTmdbId = "seriesTmdbId"
        static let watchedEpisodes = "watchedEpisodes"  // JSON array of {episodeId, watchedAt}

        // User Settings / Grace Period fields
        static let gracePeriodExpiry = "gracePeriodExpiry"
        static let gracePeriodStartedAt = "gracePeriodStartedAt"
        static let premiumShowCount = "premiumShowCount"
    }

    // MARK: - Account Status

    /// Check if iCloud account is available for CloudKit
    var isAvailable: Bool {
        get async {
            do {
                let status = try await container.accountStatus()
                let available = status == .available
                print("CloudKitManager: Account status = \(status.rawValue), available = \(available)")
                return available
            } catch {
                print("CloudKitManager: Failed to check account status - \(error)")
                return false
            }
        }
    }

    /// Get the current iCloud account status
    func getAccountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }

    // MARK: - CRUD Operations

    /// Save a followed show to CloudKit (upsert - creates or updates)
    /// - Parameters:
    ///   - tmdbId: The TMDB ID of the show
    ///   - followedAt: When the show was followed
    ///   - recordName: Optional existing record name for updates
    /// - Returns: The record name of the saved record
    @discardableResult
    func saveFollowedShow(tmdbId: Int, followedAt: Date, recordName: String? = nil) async throws -> String {
        let recordID: CKRecord.ID
        if let existingName = recordName {
            recordID = CKRecord.ID(recordName: existingName)
        } else {
            // Create deterministic record name from tmdbId for easy lookup
            recordID = CKRecord.ID(recordName: "show_\(tmdbId)")
        }

        let record = CKRecord(recordType: Self.followedShowRecordType, recordID: recordID)
        record[FieldKey.tmdbId] = tmdbId as CKRecordValue
        record[FieldKey.followedAt] = followedAt as CKRecordValue
        record[FieldKey.lastModified] = Date() as CKRecordValue

        // Use CKModifyRecordsOperation with .allKeys to upsert (handles existing records)
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .allKeys

        return try await withCheckedThrowingContinuation { continuation in
            var savedRecordName: String?

            operation.perRecordSaveBlock = { recordID, result in
                if case .success = result {
                    savedRecordName = recordID.recordName
                }
            }

            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    let name = savedRecordName ?? recordID.recordName
                    print("CloudKitManager: Saved show \(tmdbId) with recordName: \(name)")
                    continuation.resume(returning: name)
                case .failure(let error):
                    print("CloudKitManager: Failed to save show \(tmdbId) - \(error)")
                    continuation.resume(throwing: error)
                }
            }

            privateDB.add(operation)
        }
    }

    /// Delete a followed show from CloudKit
    /// - Parameter tmdbId: The TMDB ID of the show to delete
    func deleteFollowedShow(tmdbId: Int) async throws {
        let recordID = CKRecord.ID(recordName: "show_\(tmdbId)")
        try await privateDB.deleteRecord(withID: recordID)
        print("CloudKitManager: Deleted show \(tmdbId)")
    }

    /// Delete a followed show by record name
    /// - Parameter recordName: The CloudKit record name
    func deleteFollowedShow(recordName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        try await privateDB.deleteRecord(withID: recordID)
        print("CloudKitManager: Deleted record \(recordName)")
    }

    /// Fetch all followed shows from CloudKit
    /// - Returns: Array of CloudKit records sorted by followedAt (newest first)
    func fetchAllFollowedShows() async throws -> [CKRecord] {
        // Query using tmdbId field - all valid records have tmdbId > 0
        // This avoids CloudKit internal recordName index requirements
        let query = CKQuery(
            recordType: Self.followedShowRecordType,
            predicate: NSPredicate(format: "%K > 0", FieldKey.tmdbId)
        )
        // Note: Sort in-memory to avoid CloudKit index requirements

        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?

        // Initial fetch
        let (records, nextCursor) = try await privateDB.records(matching: query)
        allRecords.append(contentsOf: records.compactMap { try? $0.1.get() })
        cursor = nextCursor

        // Continue fetching if there are more records
        while let currentCursor = cursor {
            let (moreRecords, nextCursor) = try await privateDB.records(continuingMatchFrom: currentCursor)
            allRecords.append(contentsOf: moreRecords.compactMap { try? $0.1.get() })
            cursor = nextCursor
        }

        // Sort by followedAt in-memory (newest first)
        allRecords.sort { record1, record2 in
            let date1 = record1.followedAt ?? .distantPast
            let date2 = record2.followedAt ?? .distantPast
            return date1 > date2
        }

        print("CloudKitManager: Fetched \(allRecords.count) shows from CloudKit")
        return allRecords
    }

    /// Fetch a specific followed show by TMDB ID
    /// - Parameter tmdbId: The TMDB ID of the show
    /// - Returns: The CloudKit record if found
    func fetchFollowedShow(tmdbId: Int) async throws -> CKRecord? {
        let recordID = CKRecord.ID(recordName: "show_\(tmdbId)")
        do {
            return try await privateDB.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    // MARK: - Batch Operations

    /// Save multiple followed shows to CloudKit
    /// - Parameter shows: Array of (tmdbId, followedAt) tuples
    /// - Returns: Array of saved record names
    func saveFollowedShows(_ shows: [(tmdbId: Int, followedAt: Date)]) async throws -> [String] {
        guard !shows.isEmpty else { return [] }

        let records = shows.map { show -> CKRecord in
            let recordID = CKRecord.ID(recordName: "show_\(show.tmdbId)")
            let record = CKRecord(recordType: Self.followedShowRecordType, recordID: recordID)
            record[FieldKey.tmdbId] = show.tmdbId as CKRecordValue
            record[FieldKey.followedAt] = show.followedAt as CKRecordValue
            record[FieldKey.lastModified] = Date() as CKRecordValue
            return record
        }

        let modifyOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        modifyOperation.savePolicy = .allKeys

        return try await withCheckedThrowingContinuation { continuation in
            var savedNames: [String] = []

            modifyOperation.perRecordSaveBlock = { recordID, result in
                if case .success = result {
                    savedNames.append(recordID.recordName)
                }
            }

            modifyOperation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("CloudKitManager: Batch saved \(savedNames.count) shows")
                    continuation.resume(returning: savedNames)
                case .failure(let error):
                    print("CloudKitManager: Batch save failed - \(error)")
                    continuation.resume(throwing: error)
                }
            }

            privateDB.add(modifyOperation)
        }
    }

    /// Delete multiple followed shows from CloudKit
    /// - Parameter tmdbIds: Array of TMDB IDs to delete
    func deleteFollowedShows(_ tmdbIds: [Int]) async throws {
        guard !tmdbIds.isEmpty else { return }

        let recordIDs = tmdbIds.map { CKRecord.ID(recordName: "show_\($0)") }

        let modifyOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            modifyOperation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("CloudKitManager: Batch deleted \(tmdbIds.count) shows")
                    continuation.resume()
                case .failure(let error):
                    print("CloudKitManager: Batch delete failed - \(error)")
                    continuation.resume(throwing: error)
                }
            }

            privateDB.add(modifyOperation)
        }
    }

    // MARK: - Watch Progress Operations

    /// Save all watch progress to CloudKit (upsert - creates or updates)
    /// - Parameter watchedEpisodeKeys: Set of episode keys in format "showId-season-episode"
    @discardableResult
    func saveAllWatchProgress(watchedEpisodeKeys: Set<String>) async throws -> String {
        let recordID = CKRecord.ID(recordName: "watch_progress_all")
        let record = CKRecord(recordType: Self.watchProgressRecordType, recordID: recordID)

        record[FieldKey.lastModified] = Date() as CKRecordValue

        // Encode watched episodes as JSON array
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(Array(watchedEpisodeKeys)),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            record[FieldKey.watchedEpisodes] = jsonString as CKRecordValue
        }

        // Use CKModifyRecordsOperation with .allKeys to upsert (handles existing records)
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .allKeys

        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("CloudKitManager: Saved watch progress with \(watchedEpisodeKeys.count) episodes")
                    continuation.resume(returning: recordID.recordName)
                case .failure(let error):
                    print("CloudKitManager: Failed to save watch progress - \(error)")
                    continuation.resume(throwing: error)
                }
            }

            privateDB.add(operation)
        }
    }

    /// Fetch all watch progress from CloudKit
    func fetchAllWatchProgress() async throws -> Set<String>? {
        let recordID = CKRecord.ID(recordName: "watch_progress_all")
        do {
            let record = try await privateDB.record(for: recordID)
            guard let jsonString = record[FieldKey.watchedEpisodes] as? String,
                  let jsonData = jsonString.data(using: .utf8),
                  let keys = try? JSONDecoder().decode([String].self, from: jsonData) else {
                return nil
            }
            return Set(keys)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    /// Delete all watch progress from CloudKit
    func deleteAllWatchProgress() async throws {
        let recordID = CKRecord.ID(recordName: "watch_progress_all")
        do {
            try await privateDB.deleteRecord(withID: recordID)
            print("CloudKitManager: Deleted all watch progress")
        } catch let error as CKError where error.code == .unknownItem {
            // Record didn't exist, that's fine
        }
    }

    // MARK: - Delete All Data

    /// Delete all user data from CloudKit (for account deletion)
    func deleteAllData() async throws {
        // Delete followed shows
        let showRecords = try await fetchAllFollowedShows()

        var recordIDs = showRecords.map { $0.recordID }

        // Add watch progress record ID
        recordIDs.append(CKRecord.ID(recordName: "watch_progress_all"))

        guard !recordIDs.isEmpty else {
            print("CloudKitManager: No data to delete")
            return
        }

        let modifyOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            modifyOperation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("CloudKitManager: Deleted all \(recordIDs.count) records")
                    continuation.resume()
                case .failure(let error):
                    print("CloudKitManager: Delete all failed - \(error)")
                    continuation.resume(throwing: error)
                }
            }

            privateDB.add(modifyOperation)
        }
    }

    // MARK: - User Settings / Grace Period Operations

    /// Save user settings including grace period data (upsert - creates or updates)
    /// - Parameters:
    ///   - gracePeriodExpiry: When the grace period expires (nil to clear)
    ///   - gracePeriodStartedAt: When the grace period started
    ///   - premiumShowCount: Number of shows when grace period started
    func saveUserSettings(
        gracePeriodExpiry: Date?,
        gracePeriodStartedAt: Date?,
        premiumShowCount: Int?
    ) async throws {
        let recordID = CKRecord.ID(recordName: "user_settings")
        let record = CKRecord(recordType: Self.userSettingsRecordType, recordID: recordID)

        if let expiry = gracePeriodExpiry {
            record[FieldKey.gracePeriodExpiry] = expiry as CKRecordValue
        }
        if let startedAt = gracePeriodStartedAt {
            record[FieldKey.gracePeriodStartedAt] = startedAt as CKRecordValue
        }
        if let showCount = premiumShowCount {
            record[FieldKey.premiumShowCount] = showCount as CKRecordValue
        }
        record[FieldKey.lastModified] = Date() as CKRecordValue

        // Use CKModifyRecordsOperation with .allKeys to upsert (handles existing records)
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .allKeys

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("CloudKitManager: Saved user settings (grace period expiry: \(String(describing: gracePeriodExpiry)))")
                    continuation.resume()
                case .failure(let error):
                    print("CloudKitManager: Failed to save user settings - \(error)")
                    continuation.resume(throwing: error)
                }
            }

            privateDB.add(operation)
        }
    }

    /// Fetch user settings from CloudKit
    /// - Returns: Tuple with grace period data, or nils if not found
    func fetchUserSettings() async throws -> (
        gracePeriodExpiry: Date?,
        gracePeriodStartedAt: Date?,
        premiumShowCount: Int?
    ) {
        let recordID = CKRecord.ID(recordName: "user_settings")
        do {
            let record = try await privateDB.record(for: recordID)
            let expiry = record[FieldKey.gracePeriodExpiry] as? Date
            let startedAt = record[FieldKey.gracePeriodStartedAt] as? Date
            let showCount = record[FieldKey.premiumShowCount] as? Int
            print("CloudKitManager: Fetched user settings (grace period expiry: \(String(describing: expiry)))")
            return (expiry, startedAt, showCount)
        } catch let error as CKError where error.code == .unknownItem {
            print("CloudKitManager: No user settings found")
            return (nil, nil, nil)
        }
    }

    /// Clear grace period from CloudKit (user re-subscribed or completed selection)
    func clearGracePeriod() async throws {
        let recordID = CKRecord.ID(recordName: "user_settings")
        do {
            try await privateDB.deleteRecord(withID: recordID)
            print("CloudKitManager: Cleared grace period (deleted user_settings record)")
        } catch let error as CKError where error.code == .unknownItem {
            // Record didn't exist, that's fine
            print("CloudKitManager: No grace period to clear")
        }
    }

    // MARK: - Subscriptions

    /// Subscribe to changes in followed shows (for push notifications)
    func subscribeToChanges() async throws {
        let subscriptionID = "followed-shows-changes"

        // Check if subscription already exists
        do {
            _ = try await privateDB.subscription(for: subscriptionID)
            print("CloudKitManager: Subscription already exists")
            return
        } catch let error as CKError where error.code == .unknownItem {
            // Subscription doesn't exist, create it
        }

        let subscription = CKQuerySubscription(
            recordType: Self.followedShowRecordType,
            predicate: NSPredicate(format: "%K > 0", FieldKey.tmdbId),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true // Silent push for background sync
        subscription.notificationInfo = notificationInfo

        try await privateDB.save(subscription)
        print("CloudKitManager: Created subscription for followed shows changes")
    }
}

// MARK: - CloudKit Record Helpers

extension CKRecord {
    /// Extract TMDB ID from a FollowedShow record
    var tmdbId: Int? {
        self[CloudKitManager.FieldKey.tmdbId] as? Int
    }

    /// Extract followedAt date from a FollowedShow record
    var followedAt: Date? {
        self[CloudKitManager.FieldKey.followedAt] as? Date
    }

    /// Extract lastModified date from a FollowedShow record
    var lastModified: Date? {
        self[CloudKitManager.FieldKey.lastModified] as? Date
    }
}
