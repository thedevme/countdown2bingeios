//
//  DiscoverCacheService.swift
//  Countdown2Binge
//
//  Manages the weekly Discover cache.
//  Fetches shows by date range for each network, caches with details.
//

import Foundation
import SwiftData

@MainActor
final class DiscoverCacheService {
    private let modelContext: ModelContext
    private let tmdbService: TMDBServiceProtocol

    /// Track cached show IDs in memory to avoid DB queries for duplicate checks
    private var cachedIds: Set<Int> = []

    private let networks: [NetworkDefinition] = [
        NetworkDefinition(id: 213, name: "Netflix", color: "#E50914"),
        NetworkDefinition(id: 3186, name: "Max", color: "#5A35E0"),
        NetworkDefinition(id: 453, name: "Hulu", color: "#1CE783"),
        NetworkDefinition(id: 1024, name: "Prime", color: "#1FB6FF"),
        NetworkDefinition(id: 2552, name: "Apple TV+", color: "#A1A1AA"),
        NetworkDefinition(id: 2739, name: "Disney+", color: "#1FA2FF"),
        NetworkDefinition(id: 4330, name: "Paramount+", color: "#0064FF"),
        NetworkDefinition(id: 3353, name: "Peacock", color: "#000000")
    ]

    init(modelContext: ModelContext, tmdbService: TMDBServiceProtocol = TMDBService()) {
        self.modelContext = modelContext
        self.tmdbService = tmdbService
    }

    // MARK: - Public API

    /// Check if cache needs refresh and refresh if stale
    func refreshIfNeeded() async {
        let metadata = getOrCreateMetadata()

        if metadata.isStale {
            print("DEBUG: Discover cache is stale, refreshing...")
            await refreshCache()
            metadata.markRefreshed()
            try? modelContext.save()
        } else {
            print("DEBUG: Discover cache is fresh, last fetched: \(metadata.lastFetchDate?.description ?? "never")")
        }
    }

    /// Force refresh the cache
    func refreshCache() async {
        print("DEBUG: Starting Discover cache refresh...")

        // Clear existing cache
        clearCache()

        // Track cached IDs in memory to avoid DB queries for duplicates
        cachedIds.removeAll()

        // Fetch all networks in parallel
        try? await withThrowingTaskGroup(of: Void.self) { group in
            for network in networks {
                group.addTask {
                    await self.fetchShowsForNetwork(network)
                }
            }
            try await group.waitForAll()
        }

        try? modelContext.save()
        print("DEBUG: Discover cache refresh complete")
    }

    /// Get cached shows for a bucket, optionally filtered by network
    func getShows(bucket: DiscoverBucket, networkId: Int? = nil) -> [CachedDiscoverShow] {
        var descriptor = FetchDescriptor<CachedDiscoverShow>()

        // We filter by current bucket (computed from days) not stored bucket
        let allShows = (try? modelContext.fetch(descriptor)) ?? []

        return allShows
            .filter { $0.currentBucket == bucket }
            .filter { networkId == nil || $0.networkId == networkId }
            .sorted { ($0.daysUntilPremiere ?? 0) < ($1.daysUntilPremiere ?? 0) }
    }

    /// Get all cached shows, optionally filtered by network
    func getAllShows(networkId: Int? = nil) -> [CachedDiscoverShow] {
        var descriptor = FetchDescriptor<CachedDiscoverShow>()
        let allShows = (try? modelContext.fetch(descriptor)) ?? []

        return allShows
            .filter { networkId == nil || $0.networkId == networkId }
            .sorted { ($0.daysUntilPremiere ?? 0) < ($1.daysUntilPremiere ?? 0) }
    }

    // MARK: - Private

    private func getOrCreateMetadata() -> DiscoverCacheMetadata {
        let descriptor = FetchDescriptor<DiscoverCacheMetadata>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let metadata = DiscoverCacheMetadata()
        modelContext.insert(metadata)
        return metadata
    }

    private func clearCache() {
        let descriptor = FetchDescriptor<CachedDiscoverShow>()
        if let shows = try? modelContext.fetch(descriptor) {
            for show in shows {
                modelContext.delete(show)
            }
        }
    }

    private func fetchShowsForNetwork(_ network: NetworkDefinition) async {
        print("DEBUG: Fetching shows for \(network.name)...")

        // Fetch all date buckets in parallel
        try? await withThrowingTaskGroup(of: Void.self) { group in
            for bucket in DiscoverBucket.allCases {
                group.addTask {
                    await self.fetchShowsForBucket(network: network, bucket: bucket)
                }
            }
            try await group.waitForAll()
        }
    }

    private func fetchShowsForBucket(network: NetworkDefinition, bucket: DiscoverBucket) async {
        let dateRange = bucket.dateRange

        do {
            // Fetch shows in date range
            let response = try await tmdbService.getShowsByDateRange(
                networkId: network.id,
                startDate: dateRange.start,
                endDate: dateRange.end,
                page: 1
            )

            // Take first 8 shows per bucket per network
            let shows = Array(response.results.prefix(8))

            // Cache shows directly - no extra API calls
            for show in shows {
                cacheShow(show, network: network, bucket: bucket)
            }

            print("DEBUG: Cached \(shows.count) shows for \(network.name) - \(bucket.displayTitle)")
        } catch {
            print("DEBUG: Error fetching \(network.name) \(bucket.displayTitle): \(error)")
        }
    }

    private func cacheShow(_ summary: TMDBShowSummary, network: NetworkDefinition, bucket: DiscoverBucket) {
        // Check if already cached using in-memory Set (avoid DB query)
        guard !cachedIds.contains(summary.id) else { return }
        cachedIds.insert(summary.id)

        // Parse first air date
        var firstAirDate: Date?
        if let dateString = summary.firstAirDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            firstAirDate = formatter.date(from: dateString)
        }

        // Create cached show - no extra API call for counts
        let cachedShow = CachedDiscoverShow(
            tmdbId: summary.id,
            name: summary.name,
            overview: summary.overview,
            posterPath: summary.posterPath,
            backdropPath: summary.backdropPath,
            firstAirDate: firstAirDate,
            voteAverage: summary.voteAverage ?? 0,
            episodeCount: 0,
            seasonCount: 0,
            networkId: network.id,
            networkName: network.name,
            networkColor: network.color,
            dateBucket: bucket.rawValue
        )

        modelContext.insert(cachedShow)
    }
}
