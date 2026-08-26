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

    /// Track count per bucket to ensure minimum of 8 per section
    private var bucketCounts: [DiscoverBucket: Int] = [:]
    private let targetPerBucket = 8

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
            await refreshCache()
            metadata.markRefreshed()
            try? modelContext.save()
        } else {
        }
    }

    /// Force refresh the cache
    func refreshCache() async {

        // Clear existing cache
        clearCache()

        // Reset tracking
        cachedIds.removeAll()
        bucketCounts = Dictionary(uniqueKeysWithValues: DiscoverBucket.allCases.map { ($0, 0) })

        // Fetch each bucket across all networks until we have enough shows
        for bucket in DiscoverBucket.allCases {
            await fetchShowsForBucket(bucket)
        }

        try? modelContext.save()

    }

    /// Get cached shows for a bucket, optionally filtered by network
    func getShows(bucket: DiscoverBucket, networkId: Int? = nil) -> [CachedDiscoverShow] {
        let descriptor = FetchDescriptor<CachedDiscoverShow>()

        // We filter by current bucket (computed from days) not stored bucket
        let allShows = (try? modelContext.fetch(descriptor)) ?? []

        return allShows
            .filter { $0.currentBucket == bucket }
            .filter { networkId == nil || $0.networkId == networkId }
            .sorted { ($0.daysUntilPremiere ?? 0) < ($1.daysUntilPremiere ?? 0) }
    }

    /// Get all cached shows, optionally filtered by network
    func getAllShows(networkId: Int? = nil) -> [CachedDiscoverShow] {
        let descriptor = FetchDescriptor<CachedDiscoverShow>()
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

    /// Fetch shows for a bucket across all networks until we have enough
    private func fetchShowsForBucket(_ bucket: DiscoverBucket) async {
        let dateRange = bucket.dateRange
        let maxPagesPerNetwork = 10


        // Try each network until we have enough shows
        for network in networks {
            // Check if we already have enough for this bucket
            if (bucketCounts[bucket] ?? 0) >= targetPerBucket {
                break
            }

            var page = 1

            while (bucketCounts[bucket] ?? 0) < targetPerBucket && page <= maxPagesPerNetwork {
                do {
                    // Fetch shows in date range
                    let response = try await tmdbService.getShowsByDateRange(
                        networkId: network.id,
                        startDate: dateRange.start,
                        endDate: dateRange.end,
                        page: page
                    )

                    // No more results from this network
                    if response.results.isEmpty {
                        break
                    }

                    // Get IDs that aren't already cached
                    let newShows = response.results.filter { !cachedIds.contains($0.id) }
                    let newShowIds = newShows.map { $0.id }

                    if !newShowIds.isEmpty {
                        // Fetch full details to get episode/season counts
                        let fullShows = try await tmdbService.getMultipleShowDetails(ids: newShowIds)

                        // Create lookup for full show data
                        let showDataMap = Dictionary(uniqueKeysWithValues: fullShows.map { ($0.id, $0) })

                        // Cache shows with full details
                        for summary in newShows {
                            if (bucketCounts[bucket] ?? 0) >= targetPerBucket { break }
                            if let fullData = showDataMap[summary.id] {
                                cacheShow(summary, fullData: fullData, network: network, bucket: bucket)
                                bucketCounts[bucket, default: 0] += 1
                            }
                        }

                        // Save after each batch so UI updates progressively
                        try? modelContext.save()
                    }

                    // Check if we've reached the last page for this network
                    if page >= response.totalPages {
                        break
                    }

                    page += 1
                } catch {
                    break
                }
            }
        }

    }

    private func cacheShow(_ summary: TMDBShowSummary, fullData: ShowData, network: NetworkDefinition, bucket: DiscoverBucket) {
        // Check if already cached using in-memory Set (avoid DB query)
        guard !cachedIds.contains(summary.id) else { return }
        cachedIds.insert(summary.id)

        // Use firstAirDate from full data, fallback to summary
        var firstAirDate: Date? = fullData.firstAirDate
        if firstAirDate == nil, let dateString = summary.firstAirDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            firstAirDate = formatter.date(from: dateString)
        }

        // Create cached show with full episode/season counts
        let cachedShow = CachedDiscoverShow(
            tmdbId: summary.id,
            name: summary.name,
            overview: summary.overview,
            posterPath: summary.posterPath,
            backdropPath: summary.backdropPath,
            firstAirDate: firstAirDate,
            voteAverage: summary.voteAverage ?? 0,
            episodeCount: fullData.numberOfEpisodes,
            seasonCount: fullData.numberOfSeasons,
            networkId: network.id,
            networkName: network.name,
            networkColor: network.color,
            dateBucket: bucket.rawValue
        )

        modelContext.insert(cachedShow)
    }
}
