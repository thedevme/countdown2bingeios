//
//  TasteCatalog.swift
//  Countdown2Binge
//
//  The bridge between onboarding's string option IDs ("scifi", "netflix") and
//  the TMDB IDs that discovery queries actually use. Persist IDs, resolve display
//  names here at render time.
//
//  Genres map to fixed TMDB TV genre IDs (the TV genre list is small and closed —
//  there is no Thriller or Horror; use with_keywords for those post-launch).
//  Provider IDs here are an OFFLINE FALLBACK only — the live source of truth is
//  WatchProviderCatalog, which fetches /watch/providers/tv per region. Provider
//  IDs shift (HBO Max → Max) and vary by region, so never trust the constant.
//

import Foundation

/// One onboarding genre chip ↔ its TMDB TV genre ID.
struct TasteGenre: Equatable {
    let onboardingId: String
    let tmdbId: Int
    let displayName: String
}

/// One onboarding streaming service ↔ how to resolve it to a TMDB watch-provider ID.
struct TasteProvider: Equatable {
    let onboardingId: String
    /// Names to match against the live /watch/providers/tv list (first wins).
    let nameAliases: [String]
    /// Last-resort ID if the live catalog is unavailable. nil = "no provider filter".
    let fallbackTmdbId: Int?
}

enum TasteCatalog {
    /// The revised twelve — every entry is a distinct, real TMDB TV genre.
    static let genres: [TasteGenre] = [
        TasteGenre(onboardingId: "scifi",       tmdbId: 10765, displayName: "Sci-Fi & Fantasy"),
        TasteGenre(onboardingId: "drama",       tmdbId: 18,    displayName: "Drama"),
        TasteGenre(onboardingId: "comedy",      tmdbId: 35,    displayName: "Comedy"),
        TasteGenre(onboardingId: "crime",       tmdbId: 80,    displayName: "Crime"),
        TasteGenre(onboardingId: "documentary", tmdbId: 99,    displayName: "Documentary"),
        TasteGenre(onboardingId: "animation",   tmdbId: 16,    displayName: "Animation"),
        TasteGenre(onboardingId: "reality",     tmdbId: 10764, displayName: "Reality"),
        TasteGenre(onboardingId: "action",      tmdbId: 10759, displayName: "Action & Adventure"),
        TasteGenre(onboardingId: "mystery",     tmdbId: 9648,  displayName: "Mystery"),
        TasteGenre(onboardingId: "family",      tmdbId: 10751, displayName: "Family"),
        TasteGenre(onboardingId: "warpolitics", tmdbId: 10768, displayName: "War & Politics"),
        TasteGenre(onboardingId: "western",     tmdbId: 37,    displayName: "Western"),
    ]

    /// Onboarding services. "other" carries no ID → treated as "no provider filter".
    static let providers: [TasteProvider] = [
        TasteProvider(onboardingId: "netflix",   nameAliases: ["Netflix"],                              fallbackTmdbId: 8),
        TasteProvider(onboardingId: "max",       nameAliases: ["Max", "HBO Max"],                       fallbackTmdbId: 1899),
        TasteProvider(onboardingId: "hulu",      nameAliases: ["Hulu"],                                 fallbackTmdbId: 15),
        TasteProvider(onboardingId: "disney",    nameAliases: ["Disney Plus", "Disney+"],               fallbackTmdbId: 337),
        TasteProvider(onboardingId: "appletv",   nameAliases: ["Apple TV Plus", "Apple TV+"],           fallbackTmdbId: 350),
        TasteProvider(onboardingId: "prime",     nameAliases: ["Amazon Prime Video", "Prime Video"],    fallbackTmdbId: 9),
        TasteProvider(onboardingId: "paramount", nameAliases: ["Paramount Plus", "Paramount+"],         fallbackTmdbId: 531),
        TasteProvider(onboardingId: "peacock",   nameAliases: ["Peacock Premium", "Peacock"],           fallbackTmdbId: 386),
        TasteProvider(onboardingId: "other",     nameAliases: [],                                       fallbackTmdbId: nil),
    ]

    // MARK: - Genre resolution

    /// Onboarding genre IDs → sorted, de-duplicated TMDB genre IDs.
    static func tmdbGenreIDs(for onboardingIDs: Set<String>) -> [Int] {
        let ids = genres.filter { onboardingIDs.contains($0.onboardingId) }.map(\.tmdbId)
        return Array(Set(ids)).sorted()
    }

    static func genreDisplayName(tmdbId: Int) -> String? {
        genres.first { $0.tmdbId == tmdbId }?.displayName
    }

    // MARK: - Provider fallback resolution (offline only)

    /// Onboarding service IDs → sorted TMDB provider IDs, using the constant
    /// fallback. "other" (and any unknown id) contributes nothing.
    static func fallbackProviderIDs(for onboardingIDs: Set<String>) -> [Int] {
        let ids = providers
            .filter { onboardingIDs.contains($0.onboardingId) }
            .compactMap { $0.fallbackTmdbId }
        return Array(Set(ids)).sorted()
    }
}
