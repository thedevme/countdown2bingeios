//
//  TastePreferences.swift
//  Countdown2Binge
//
//  Durable taste layer: the genres and streaming providers the user picked in
//  onboarding, persisted so they can drive every recommendation surface. Stores
//  TMDB IDs only — display names resolve at render time via TasteCatalog.
//

import Foundation

struct TastePreferences: Codable, Equatable {
    /// TMDB TV genre IDs.
    var genreIDs: [Int]
    /// TMDB watch-provider IDs (resolved; empty = no provider filter).
    var providerIDs: [Int]
    /// ISO 3166-1 region for watch_region. Never nil — defaults to "US".
    var watchRegion: String
    /// Whether the user actually went through the preference step (vs. a legacy
    /// user who onboarded before this feature — they get unfiltered recs).
    var completedPreferenceStep: Bool

    static let empty = TastePreferences(
        genreIDs: [], providerIDs: [], watchRegion: TastePreferences.defaultRegion,
        completedPreferenceStep: false
    )

    /// `Locale.current.region` is optional; nil never reaches a query.
    static var defaultRegion: String {
        Locale.current.region?.identifier ?? "US"
    }

    /// Build a `DiscoverQuery` for these preferences.
    func discoverQuery(page: Int = 1) -> DiscoverQuery {
        DiscoverQuery(genreIDs: genreIDs, providerIDs: providerIDs,
                      watchRegion: watchRegion, page: page)
    }
}
