//
//  DiscoverQueryBuilderTests.swift
//  Countdown2BingeTests
//
//  Pure tests for the discovery query-building layer — the single source of
//  discovery parameters. No network. Also guards that the search path is
//  untouched by the discovery feature.
//

import Testing
import Foundation
@testable import Countdown2Binge

@Suite("Discover query builder")
struct DiscoverQueryBuilderTests {

    private func value(_ items: [URLQueryItem], _ name: String) -> String? {
        items.first { $0.name == name }?.value
    }
    private func has(_ items: [URLQueryItem], _ name: String) -> Bool {
        items.contains { $0.name == name }
    }

    // MARK: - Composition

    @Test("Genres + providers → all params composed, with flatrate + region")
    func fullComposition() {
        let q = DiscoverQuery(genreIDs: [18, 10765], providerIDs: [8, 15], watchRegion: "US")
        let items = DiscoverQueryBuilder.queryItems(for: q, relaxation: .full)

        #expect(value(items, "with_genres") == "18|10765")
        #expect(value(items, "with_watch_providers") == "8|15")
        #expect(value(items, "watch_region") == "US")
        #expect(value(items, "with_watch_monetization_types") == "flatrate")
        #expect(value(items, "sort_by") == "popularity.desc")
        #expect(value(items, "vote_count.gte") == "50")
    }

    @Test("Empty genres → no with_genres key emitted at all")
    func emptyGenres() {
        let q = DiscoverQuery(genreIDs: [], providerIDs: [8], watchRegion: "US")
        let items = DiscoverQueryBuilder.queryItems(for: q, relaxation: .full)

        #expect(!has(items, "with_genres"))
        #expect(has(items, "with_watch_providers"))
        #expect(has(items, "with_watch_monetization_types")) // flatrate stays with providers
    }

    @Test("Empty providers → no with_watch_providers / watch_region / flatrate")
    func emptyProviders() {
        let q = DiscoverQuery(genreIDs: [18], providerIDs: [], watchRegion: "US")
        let items = DiscoverQueryBuilder.queryItems(for: q, relaxation: .full)

        #expect(has(items, "with_genres"))
        #expect(!has(items, "with_watch_providers"))
        #expect(!has(items, "watch_region"))
        #expect(!has(items, "with_watch_monetization_types"))
    }

    @Test("Both empty → plain popularity query")
    func bothEmpty() {
        let q = DiscoverQuery(genreIDs: [], providerIDs: [], watchRegion: "US")
        let items = DiscoverQueryBuilder.queryItems(for: q, relaxation: .full)

        #expect(!has(items, "with_genres"))
        #expect(!has(items, "with_watch_providers"))
        #expect(!has(items, "watch_region"))
        #expect(!has(items, "with_watch_monetization_types"))
        #expect(value(items, "sort_by") == "popularity.desc")
        #expect(value(items, "vote_count.gte") == "50")
    }

    @Test("flatrate is present whenever providers are present")
    func flatrateAlwaysWithProviders() {
        let q = DiscoverQuery(genreIDs: [], providerIDs: [9], watchRegion: "GB")
        let items = DiscoverQueryBuilder.queryItems(for: q, relaxation: .full)
        #expect(value(items, "with_watch_monetization_types") == "flatrate")
        #expect(value(items, "watch_region") == "GB")
    }

    // MARK: - Relaxation ladder

    @Test("Ladder broadens by dropping genre but never drops the provider filter")
    func ladderOrder() {
        let q = DiscoverQuery(genreIDs: [18], providerIDs: [8], watchRegion: "US")
        let ladder = DiscoverQueryBuilder.relaxationLadder(for: q)
        // Provider filter is availability — never dropped when the user has providers.
        #expect(ladder == [.full, .dropGenre])
        #expect(!ladder.contains(.dropProvider))
    }

    @Test("dropGenre keeps providers, drops genres")
    func dropGenreLevel() {
        let q = DiscoverQuery(genreIDs: [18], providerIDs: [8], watchRegion: "US")
        let items = DiscoverQueryBuilder.queryItems(for: q, relaxation: .dropGenre)
        #expect(!has(items, "with_genres"))
        #expect(has(items, "with_watch_providers"))
    }

    @Test("dropProvider drops both → plain popularity")
    func dropProviderLevel() {
        let q = DiscoverQuery(genreIDs: [18], providerIDs: [8], watchRegion: "US")
        let items = DiscoverQueryBuilder.queryItems(for: q, relaxation: .dropProvider)
        #expect(!has(items, "with_genres"))
        #expect(!has(items, "with_watch_providers"))
    }

    @Test("No-filter query only needs the plain popularity level")
    func ladderNoFilters() {
        let q = DiscoverQuery(genreIDs: [], providerIDs: [], watchRegion: "US")
        #expect(DiscoverQueryBuilder.relaxationLadder(for: q) == [.dropProvider])
    }

    @Test("Provider-only query never relaxes past the provider filter")
    func ladderProviderOnly() {
        let q = DiscoverQuery(genreIDs: [], providerIDs: [8], watchRegion: "US")
        #expect(DiscoverQueryBuilder.relaxationLadder(for: q) == [.full])
    }

    @Test("With no providers, ladder falls back to plain popularity")
    func ladderGenreOnly() {
        let q = DiscoverQuery(genreIDs: [18], providerIDs: [], watchRegion: "US")
        #expect(DiscoverQueryBuilder.relaxationLadder(for: q) == [.full, .dropProvider])
    }

    // MARK: - A provider the user does not have never appears

    @Test("Only the user's providers appear in with_watch_providers")
    func onlyUserProviders() {
        let q = DiscoverQuery(genreIDs: [], providerIDs: [8, 337], watchRegion: "US")
        let items = DiscoverQueryBuilder.queryItems(for: q, relaxation: .full)
        // Paramount+ (531) was never in the set → must not appear.
        let providers = value(items, "with_watch_providers") ?? ""
        #expect(providers == "8|337")
        #expect(!providers.contains("531"))
    }
}

@Suite("Taste catalog mapping")
struct TasteCatalogTests {

    @Test("Twelve genres, all distinct TMDB IDs")
    func twelveDistinct() {
        #expect(TasteCatalog.genres.count == 12)
        let ids = TasteCatalog.genres.map(\.tmdbId)
        #expect(Set(ids).count == 12)
    }

    @Test("Thriller and Horror are gone; War & Politics and Western are in")
    func revisedChips() {
        let ids = Set(TasteCatalog.genres.map(\.onboardingId))
        #expect(!ids.contains("thriller"))
        #expect(!ids.contains("horror"))
        #expect(ids.contains("warpolitics"))
        #expect(ids.contains("western"))
    }

    @Test("Onboarding genre IDs resolve to sorted, deduped TMDB IDs")
    func genreResolution() {
        #expect(TasteCatalog.tmdbGenreIDs(for: ["drama", "scifi"]) == [18, 10765])
    }

    @Test("\"other\" contributes no provider filter")
    func otherProvider() {
        #expect(TasteCatalog.fallbackProviderIDs(for: ["other"]) == [])
    }
}

@Suite("Search path unchanged")
struct SearchIsolationTests {

    @Test("searchTV emits exactly its historical params — no discovery leakage")
    func searchUntouched() {
        let items = TMDBEndpoint.searchTV(query: "severance", page: 1).queryItems
        let names = Set(items.map(\.name))
        // Historical search params only.
        #expect(names == ["api_key", "language", "query", "page", "include_adult"])
        // Discovery params must never appear on search.
        #expect(!names.contains("with_genres"))
        #expect(!names.contains("with_watch_providers"))
        #expect(!names.contains("watch_region"))
        #expect(!names.contains("with_watch_monetization_types"))
        #expect(!names.contains("sort_by"))
    }
}
