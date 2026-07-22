//
//  SchemaVersions.swift
//  Countdown2Binge
//
//  SwiftData schema versions and migration plan.
//

import Foundation
import SwiftData

// MARK: - Schema Versions

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [FollowedShowV1.self]
    }

    @Model
    final class FollowedShowV1 {
        @Attribute(.unique) var tmdbId: Int
        var followedAt: Date
        var lastRefreshedAt: Date?
        var isSynced: Bool
        @Relationship(deleteRule: .cascade) var cachedData: CachedShowData?

        init(tmdbId: Int, followedAt: Date = Date(), isSynced: Bool = false) {
            self.tmdbId = tmdbId
            self.followedAt = followedAt
            self.lastRefreshedAt = nil
            self.isSynced = isSynced
        }
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [FollowedShow.self, CachedShowData.self, Series.self, SeriesSeason.self, SeriesEpisode.self, CachedDiscoverShow.self, DiscoverCacheMetadata.self]
    }
}

// MARK: - Migration Plan

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // Lightweight migration - SwiftData handles adding new property with default value
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
