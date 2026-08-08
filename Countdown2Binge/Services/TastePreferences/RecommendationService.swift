//
//  RecommendationService.swift
//  Countdown2Binge
//
//  The ONE code path every recommendation surface calls — onboarding suggestion
//  rail and in-app discover rails alike — so they can't drift. Routes all fetches
//  through DiscoverQueryBuilder (single source of params), runs the relaxation
//  ladder, and keeps the request-volume behind a cache: composed-query results are
//  memoized, and "Because you added X" provider-availability is batched + cached
//  (never an N+1 of getWatchProviders across a rail).
//
//  Never touches the search path.
//

import Foundation

@MainActor
final class RecommendationService {
    static let shared = RecommendationService()

    private let service: TMDBServiceProtocol
    private var resultCache: [String: [ShowSummary]] = [:]        // query cacheKey → shows
    private var availabilityCache: [String: Bool] = [:]           // "showId:region" → streamable

    init(service: TMDBServiceProtocol = TMDBService()) {
        self.service = service
    }

    struct Feed {
        let shows: [ShowSummary]
        /// True if results came from a relaxed level (fewer than the target at full).
        let relaxed: Bool
        /// Honest label for a relaxed section, e.g. "Broadened — more on your services".
        let relaxationLabel: String?
        /// The relaxation level the feed settled on — pass to `morePage` so
        /// pagination keeps fetching the same broadened set.
        let level: DiscoverQuery.Relaxation
    }

    /// Discovery feed for the given preferences, walking the relaxation ladder
    /// (drop genre before provider) until at least `minResults` come back.
    func feed(for prefs: TastePreferences,
              page: Int = 1,
              minResults: Int = 10) async -> Feed {
        let query = prefs.discoverQuery(page: page)
        let ladder = DiscoverQueryBuilder.relaxationLadder(for: query)
        var last: [ShowSummary] = []

        for (index, level) in ladder.enumerated() {
            let shows = await fetch(query: query, level: level)
            last = shows
            if shows.count >= minResults {
                return Feed(shows: shows,
                            relaxed: index > 0,
                            relaxationLabel: index > 0 ? Self.label(for: level) : nil,
                            level: level)
            }
        }

        let exhausted = ladder.count > 1
        let settled = ladder.last ?? .dropProvider
        return Feed(shows: last,
                    relaxed: exhausted,
                    relaxationLabel: exhausted ? Self.label(for: settled) : nil,
                    level: settled)
    }

    /// Fetch one more page at an already-settled relaxation level, for infinite
    /// scroll. Returns `[]` when the page is past the end (the caller stops).
    /// Stays on the settled level so pagination never silently re-broadens or
    /// re-narrows the set the user is already browsing.
    func morePage(for prefs: TastePreferences,
                  page: Int,
                  level: DiscoverQuery.Relaxation) async -> [ShowSummary] {
        let query = prefs.discoverQuery(page: page)
        return await fetch(query: query, level: level)
    }

    /// "Because you added X" — seed from a library show's TMDB recommendations,
    /// then keep only titles streamable on the user's providers in their region.
    /// Availability is checked concurrently and cached, not N+1 per render.
    func becauseYouAdded(seedShowId: Int,
                         prefs: TastePreferences,
                         limit: Int = 20) async -> [ShowSummary] {
        guard let recs = try? await service.getShowRecommendations(id: seedShowId) else { return [] }
        let candidates = Array(recs.prefix(limit))

        // No provider filter → return as-is (still capped).
        guard !prefs.providerIDs.isEmpty else {
            return candidates.map { $0.toShowSummary() }
        }

        let region = prefs.watchRegion
        let providerIDs = Set(prefs.providerIDs)

        // Batch the availability checks concurrently; each result is cached.
        await withTaskGroup(of: Void.self) { group in
            for show in candidates where availabilityCache["\(show.id):\(region)"] == nil {
                group.addTask { [weak self] in
                    _ = await self?.isStreamable(showId: show.id, region: region, providerIDs: providerIDs)
                }
            }
        }

        return candidates
            .filter { availabilityCache["\($0.id):\(region)"] == true }
            .map { $0.toShowSummary() }
    }

    /// Drop everything cached — call when preferences change.
    func invalidate() {
        resultCache.removeAll()
        availabilityCache.removeAll()
    }

    // MARK: - Private

    private func fetch(query: DiscoverQuery, level: DiscoverQuery.Relaxation) async -> [ShowSummary] {
        let key = DiscoverQueryBuilder.cacheKey(for: query, relaxation: level)
        if let cached = resultCache[key] { return cached }
        do {
            let response = try await service.discover(query: query, relaxation: level)
            let shows = response.results.map { $0.toShowSummary() }
            resultCache[key] = shows
            return shows
        } catch {
            return []
        }
    }

    @discardableResult
    private func isStreamable(showId: Int, region: String, providerIDs: Set<Int>) async -> Bool {
        let key = "\(showId):\(region)"
        if let cached = availabilityCache[key] { return cached }
        do {
            let response = try await service.getWatchProviders(id: showId)
            let flatrate = response.results[region]?.flatrate ?? []
            let available = flatrate.contains { providerIDs.contains($0.providerId) }
            availabilityCache[key] = available
            return available
        } catch {
            availabilityCache[key] = false
            return false
        }
    }

    private static func label(for level: DiscoverQuery.Relaxation) -> String {
        switch level {
        case .full:         return ""
        case .dropGenre:    return "Broadened — more on your services"
        case .dropProvider: return "Popular right now"
        }
    }
}
