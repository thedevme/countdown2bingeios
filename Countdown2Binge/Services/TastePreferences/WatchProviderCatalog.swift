//
//  WatchProviderCatalog.swift
//  Countdown2Binge
//
//  Live source of truth for TMDB watch-provider IDs. Fetches
//  /watch/providers/tv?watch_region={region}, caches per region, and resolves
//  onboarding service IDs → CURRENT provider IDs by name alias. The constant table
//  in TasteCatalog is only a fallback for when the fetch fails — provider IDs
//  shift (HBO Max → Max) and vary by region, so the constant must never be the
//  source of truth.
//

import Foundation

@MainActor
final class WatchProviderCatalog {
    static let shared = WatchProviderCatalog()

    private let service: TMDBServiceProtocol
    private var cache: [String: [TMDBWatchProvider]] = [:]  // region → live providers

    init(service: TMDBServiceProtocol = TMDBService()) {
        self.service = service
    }

    /// Resolve onboarding service IDs to TMDB provider IDs for a region.
    /// Prefers the live catalog (matched by name alias); falls back to the
    /// TasteCatalog constant when a service can't be matched live. "other" and
    /// unknown IDs contribute nothing (→ no provider filter for that pick).
    func resolveProviderIDs(serviceOptionIDs: Set<String>,
                            region: String) async -> [Int] {
        let live = await providers(for: region)
        var ids: [Int] = []

        for option in TasteCatalog.providers where serviceOptionIDs.contains(option.onboardingId) {
            guard !option.nameAliases.isEmpty else { continue } // "other" → no filter
            if let match = live.first(where: { provider in
                option.nameAliases.contains { $0.caseInsensitiveCompare(provider.providerName) == .orderedSame }
            }) {
                ids.append(match.providerId)
            } else if let fallback = option.fallbackTmdbId {
                ids.append(fallback)
            }
        }

        return Array(Set(ids)).sorted()
    }

    private func providers(for region: String) async -> [TMDBWatchProvider] {
        if let cached = cache[region] { return cached }
        do {
            let list = try await service.getWatchProvidersTV(region: region)
            cache[region] = list
            return list
        } catch {
            return [] // caller falls back to TasteCatalog constants
        }
    }
}
