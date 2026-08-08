//
//  DiscoverQuery.swift
//  Countdown2Binge
//
//  THE single source of discovery parameters. Every recommendation surface —
//  onboarding suggestion rail, in-app discover rails, per-provider rails — builds
//  its /discover/tv query here so they can never drift. Pure value-in → query-out:
//  no network, no SwiftData, no singletons. This is the layer Phase 3 tests.
//
//  NOT reachable from the search path. Search stays /search/tv, untouched.
//

import Foundation

/// A resolved discovery request: TMDB IDs only, region already defaulted.
struct DiscoverQuery: Equatable {
    var genreIDs: [Int]
    var providerIDs: [Int]
    var watchRegion: String
    var page: Int = 1

    /// The relaxation ladder. Availability matters more than taste, so genre is
    /// dropped before provider.
    enum Relaxation: Int, CaseIterable, Comparable {
        case full = 0        // genres ∩ providers
        case dropGenre = 1   // providers only
        case dropProvider = 2 // plain popularity

        static func < (lhs: Relaxation, rhs: Relaxation) -> Bool { lhs.rawValue < rhs.rawValue }
    }
}

enum DiscoverQueryBuilder {
    /// Raw discover results are noisy without a floor.
    static let minVoteCount = 50

    /// Compose the `/discover/tv` query items for a request at a relaxation level.
    /// - `with_genres` emitted only at `.full` and only when non-empty.
    /// - `with_watch_providers` (with `watch_region` + `flatrate`) emitted at
    ///   `.full`/`.dropGenre` and only when non-empty. `flatrate` is mandatory
    ///   whenever providers are present — otherwise TMDB matches rent/buy titles
    ///   the user can't stream.
    /// - `.dropProvider` (or all-empty) yields a plain popularity query.
    static func queryItems(for query: DiscoverQuery,
                           relaxation: DiscoverQuery.Relaxation = .full) -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "vote_count.gte", value: String(minVoteCount)),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "page", value: String(max(1, query.page))),
        ]

        let useGenres = relaxation == .full && !query.genreIDs.isEmpty
        let useProviders = relaxation <= .dropGenre && !query.providerIDs.isEmpty

        if useGenres {
            items.append(URLQueryItem(name: "with_genres",
                                      value: orJoin(query.genreIDs)))
        }

        if useProviders {
            items.append(URLQueryItem(name: "with_watch_providers",
                                      value: orJoin(query.providerIDs)))
            items.append(URLQueryItem(name: "watch_region", value: query.watchRegion))
            // Subscription-streamable only — never rent/buy.
            items.append(URLQueryItem(name: "with_watch_monetization_types", value: "flatrate"))
        }

        return items
    }

    /// The relaxation levels to try, in order, for a given query.
    ///
    /// If the user has providers, the provider filter is NEVER dropped — we don't
    /// recommend shows they can't watch. We only ever broaden by dropping the genre
    /// filter. Only when the user selected no providers at all do we fall back to a
    /// plain popularity query (there's no availability to preserve).
    static func relaxationLadder(for query: DiscoverQuery) -> [DiscoverQuery.Relaxation] {
        let hasGenres = !query.genreIDs.isEmpty
        let hasProviders = !query.providerIDs.isEmpty
        if !hasGenres && !hasProviders { return [.dropProvider] }   // plain popularity
        if hasProviders {
            // Keep availability; broaden only by dropping genre.
            return hasGenres ? [.full, .dropGenre] : [.full]
        }
        // No providers to preserve → genre-only, then plain popularity.
        return [.full, .dropProvider]
    }

    /// A stable cache key for a query at a relaxation level.
    static func cacheKey(for query: DiscoverQuery,
                         relaxation: DiscoverQuery.Relaxation) -> String {
        "disc:g=\(orJoin(query.genreIDs)):p=\(orJoin(query.providerIDs)):r=\(query.watchRegion):lvl=\(relaxation.rawValue):pg=\(query.page)"
    }

    private static func orJoin(_ ids: [Int]) -> String {
        ids.map(String.init).joined(separator: "|")
    }
}
