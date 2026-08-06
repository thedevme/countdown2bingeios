//
//  SeriesModels.swift
//  Countdown2Binge
//
//  The SINGLE persisted source of truth for a followed show.
//  Series → Season → Episode. Created ONLY when a user follows a show.
//
//  Design rules:
//   • Models COMPUTE (pure, date-based, no side effects). All lifecycle
//     computation delegates to BingeEngine so the rules live in one place.
//   • Models are MUTATED only through SeriesManager (the sole write funnel).
//   • CloudKit-compatible: no @Attribute(.unique), all relationships optional
//     with defaults, inverses declared.
//   • Spinoffs are stored on the Series at follow-time (relatedShowIds) and
//     never re-fetched at render — kills the flicker.
//
//  INTEGRATION: This file REPLACES the old Series.swift / SeasonModel.swift /
//  EpisodeModel.swift wholesale. See INTEGRATION.md.
//

import Foundation
import SwiftData

// MARK: - Series

@Model
final class Series {

    // Identity — TMDB show id. NOT .unique (avoids @Bindable crashes +
    // CloudKit incompatibility); uniqueness is enforced in SeriesManager.
    var id: Int = 0

    // Metadata (mirrors ShowData; refreshed from TMDB, never drives watch state)
    var name: String = ""
    var overview: String = ""
    var posterPath: String?
    var backdropPath: String?
    var logoPath: String?
    var firstAirDate: Date?
    var statusRaw: String = ShowStatus.planned.rawValue
    var inProduction: Bool = false
    var voteAverage: Double?
    var numberOfSeasons: Int = 0
    var numberOfEpisodes: Int = 0

    // JSON-encoded side metadata (small, display-only)
    var genresJSON: Data?
    var networksJSON: Data?
    var creatorsJSON: Data?

    // MARK: User-axis state (Axis 2)

    /// Manual archive flag. Suppresses user-axis surfaces; a dated new season
    /// still returns the show to the timeline (see BingeEngine.myListTab).
    var isArchived: Bool = false

    /// Whether this show is synced to iCloud. Premium-only feature.
    /// Set to true when synced, false when removed from cloud or user loses premium.
    var isSynced: Bool = false

    // MARK: Spinoffs (resolved once at follow-time, stored, never re-fetched)

    /// Related franchise/spinoff TMDB ids. Rendered from here — no live lookup.
    var relatedShowIdsJSON: Data?

    /// True once franchise resolution has run for this show (so we never redo
    /// the Firebase lookup on subsequent launches).
    var spinoffsResolved: Bool = false

    // MARK: Bookkeeping

    var dateAdded: Date = Date.now
    var lastUpdated: Date = Date.now
    /// When TMDB data was last pulled (drives refresh throttling).
    var lastRefreshedAt: Date?

    // MARK: Relationships

    @Relationship(deleteRule: .cascade, inverse: \Season.series)
    var seasons: [Season] = []

    // MARK: Init

    init(id: Int, name: String) {
        self.id = id
        self.name = name
        self.dateAdded = .now
        self.lastUpdated = .now
    }

    // MARK: - JSON accessors

    var genres: [GenreData] {
        get { decode(genresJSON) ?? [] }
        set { genresJSON = encode(newValue) }
    }

    var networks: [NetworkData] {
        get { decode(networksJSON) ?? [] }
        set { networksJSON = encode(newValue) }
    }

    var creators: [Creator]? {
        get { decode(creatorsJSON) }
        set { creatorsJSON = encode(newValue) }
    }

    var relatedShowIds: [Int] {
        get { decode(relatedShowIdsJSON) ?? [] }
        set { relatedShowIdsJSON = encode(newValue) }
    }

    // MARK: - Computed metadata

    var status: ShowStatus {
        ShowStatus(rawValue: statusRaw) ?? .planned
    }

    var posterURL: URL? { TMDBConfiguration.imageURL(path: posterPath, size: .poster) }
    var backdropURL: URL? { TMDBConfiguration.imageURL(path: backdropPath, size: .backdrop) }
    var logoURL: URL? { TMDBConfiguration.imageURL(path: logoPath, size: .logo) }

    var spinoffCount: Int { relatedShowIds.count }

    /// Regular seasons (excludes specials), sorted ascending.
    var regularSeasons: [Season] {
        seasons.filter { $0.seasonNumber > 0 }
            .sorted { $0.seasonNumber < $1.seasonNumber }
    }

    // MARK: - Lifecycle (delegates to BingeEngine — Axis 1)

    /// Bridge: build BingeEngine season facts from the SwiftData graph.
    private var seasonFacts: [BingeEngine.SeasonFact] {
        regularSeasons.map { season in
            BingeEngine.SeasonFact(
                seasonNumber: season.seasonNumber,
                episodes: season.episodeFacts,
                hasWatched: season.hasWatched
            )
        }
    }

    /// The show-axis lifecycle state (anticipated / premieringSoon / airing /
    /// pending / bingeReady). Pure function of air dates.
    var showState: ShowState {
        BingeEngine.showState(seasons: seasonFacts)
    }

    /// The current season the timeline reflects.
    var currentSeason: Season? {
        guard let fact = BingeEngine.currentSeason(seasons: seasonFacts) else { return nil }
        return regularSeasons.first { $0.seasonNumber == fact.seasonNumber }
    }

    /// The single latest unwatched-complete season, or nil.
    /// This is what the Binge Ready surface shows for this series.
    var bingeReadySeason: Season? {
        guard let fact = BingeEngine.bingeReadySeason(seasons: seasonFacts) else { return nil }
        return regularSeasons.first { $0.seasonNumber == fact.seasonNumber }
    }

    /// First season user hasn't fully watched (user-axis, for Binge Ready UI).
    /// Different from currentSeason which is date-based.
    /// "First season with an aired-but-unwatched episode."
    var firstUnwatchedSeason: Season? {
        regularSeasons.first { season in
            let aired = season.episodes.filter { $0.hasAired }
            return aired.contains { !$0.hasWatched }
        } ?? regularSeasons.last
    }

    /// Whether this show belongs on the Binge Ready surface right now.
    var isOnBingeReadySurface: Bool {
        BingeEngine.isOnBingeReadySurface(seasons: seasonFacts)
    }

    /// Whether the show should appear on the main timeline.
    var appearsOnTimeline: Bool {
        // Archived shows only appear if a dated new season pulls them back.
        if isArchived {
            let s = showState
            return s == .premieringSoon || s == .airing || s == .pending
        }
        return showState.appearsOnTimeline
    }

    var daysUntilPremiere: Int? {
        BingeEngine.daysUntilPremiere(seasons: seasonFacts)
    }

    var daysUntilFinale: Int? {
        BingeEngine.daysUntilFinale(seasons: seasonFacts)
    }

    /// Which My List tab this show belongs in.
    var myListTab: MyListTab {
        BingeEngine.myListTab(
            seasons: seasonFacts,
            isArchived: isArchived,
            isInProduction: inProduction
        )
    }

    // MARK: - Conversion

    /// Convert Series to ShowData for compatibility with legacy views.
    func toShowData() -> ShowData {
        ShowData(
            id: id,
            name: name,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            logoPath: logoPath,
            firstAirDate: firstAirDate,
            status: status,
            genres: genres ?? [],
            networks: networks ?? [],
            createdBy: creators,
            seasons: regularSeasons.map { $0.toSeasonData() },
            numberOfSeasons: numberOfSeasons,
            numberOfEpisodes: numberOfEpisodes,
            inProduction: inProduction,
            voteAverage: voteAverage,
            cachedFinaleDate: currentSeason?.finaleDate,
            cachedPremiereDate: daysUntilPremiere.map { Date().addingTimeInterval(Double($0) * 86400) },
            spinoffCount: spinoffCount
        )
    }
}

// MARK: - Season

@Model
final class Season {

    var id: Int = 0                 // TMDB season id
    var seasonNumber: Int = 0
    var name: String = ""
    var overview: String = ""
    var posterPath: String?
    var airDate: Date?              // TMDB season.air_date (fallback only)
    var episodeCount: Int = 0       // TMDB's stated count (completeness check)
    var voteAverage: Double?

    // MARK: User-axis (Axis 2)

    /// Whether the user has marked this whole season watched.
    /// This is the flag the add-time "did you watch S_n?" question sets.
    var hasWatched: Bool = false

    /// When the season was marked watched (nil if unwatched).
    var watchedAt: Date?

    // MARK: Relationships

    var series: Series?

    @Relationship(deleteRule: .cascade, inverse: \Episode.season)
    var episodes: [Episode] = []

    init(id: Int, seasonNumber: Int, name: String) {
        self.id = id
        self.seasonNumber = seasonNumber
        self.name = name
    }

    var posterURL: URL? { TMDBConfiguration.imageURL(path: posterPath, size: .poster) }

    var sortedEpisodes: [Episode] {
        episodes.filter { $0.episodeNumber > 0 }
            .sorted { $0.episodeNumber < $1.episodeNumber }
    }

    // MARK: - Engine bridge

    /// Episode facts for the engine (the conservative finale rule reads these).
    var episodeFacts: [BingeEngine.EpisodeFact] {
        episodes.map { ep in
            BingeEngine.EpisodeFact(
                episodeNumber: ep.episodeNumber,
                airDate: ep.airDate,
                isTypedFinale: ep.episodeType == .finale,
                isTyped: ep.episodeType != .standard
            )
        }
    }

    // MARK: - Computed lifecycle (Axis 1, delegates to BingeEngine)

    var premiereDate: Date? { BingeEngine.premiereDate(from: episodeFacts) }
    var finaleDate: Date? { BingeEngine.finaleDate(from: episodeFacts) }
    var hasStarted: Bool { BingeEngine.hasStarted(episodes: episodeFacts) }
    var hasConfirmedFinale: Bool { BingeEngine.hasConfirmedFinale(episodes: episodeFacts) }

    /// This season's own show-state.
    var showState: ShowState {
        BingeEngine.seasonShowState(episodes: episodeFacts)
    }

    /// Date-fact: is this season complete + past the grace window?
    var isBingeReadyByDate: Bool {
        BingeEngine.isSeasonBingeReadyByDate(episodes: episodeFacts)
    }

    /// The user-facing Binge Ready predicate = date fact ∩ unwatched.
    var isBingeReady: Bool {
        isBingeReadyByDate && !hasWatched
    }

    /// Season completeness by episode availability (used for data-quality gates).
    var hasAllEpisodes: Bool {
        episodeCount <= 0 || sortedEpisodes.count >= episodeCount
    }

    /// Count of episodes marked watched in this season.
    var watchedEpisodeCount: Int {
        episodes.filter { $0.hasWatched }.count
    }

    /// Convert Season to SeasonData for compatibility with legacy views.
    func toSeasonData() -> SeasonData {
        SeasonData(
            id: id,
            seasonNumber: seasonNumber,
            name: name,
            overview: overview,
            posterPath: posterPath,
            airDate: airDate,
            episodeCount: episodeCount,
            episodes: sortedEpisodes.map { $0.toEpisodeData() },
            voteAverage: voteAverage
        )
    }
}

// MARK: - Episode

@Model
final class Episode {

    var id: Int = 0                 // TMDB episode id
    var episodeNumber: Int = 0
    var seasonNumber: Int = 0
    var name: String = ""
    var overview: String = ""
    var airDate: Date?
    var stillPath: String?
    var runtime: Int = 0
    var episodeTypeRaw: String = EpisodeType.standard.rawValue
    var voteAverage: Double?

    // MARK: User-axis (Axis 2)

    var hasWatched: Bool = false
    var watchedAt: Date?

    // MARK: Relationship

    var season: Season?

    init(id: Int, episodeNumber: Int, seasonNumber: Int, name: String) {
        self.id = id
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.name = name
    }

    var episodeType: EpisodeType {
        EpisodeType(rawValue: episodeTypeRaw) ?? .standard
    }

    var stillURL: URL? { TMDBConfiguration.imageURL(path: stillPath, size: .still) }

    var episodeCode: String {
        String(format: "S%02dE%02d", seasonNumber, episodeNumber)
    }

    var hasAired: Bool {
        guard let airDate else { return false }
        return airDate <= Date()
    }

    var isFinale: Bool { episodeType == .finale }

    /// Convert Episode to EpisodeData for compatibility with legacy views.
    func toEpisodeData() -> EpisodeData {
        EpisodeData(
            id: id,
            episodeNumber: episodeNumber,
            seasonNumber: seasonNumber,
            name: name,
            overview: overview,
            airDate: airDate,
            stillPath: stillPath,
            runtime: runtime,
            episodeType: episodeType,
            voteAverage: voteAverage
        )
    }
}

// MARK: - JSON helpers

private func encode<T: Encodable>(_ value: T?) -> Data? {
    guard let value else { return nil }
    return try? JSONEncoder().encode(value)
}

private func decode<T: Decodable>(_ data: Data?) -> T? {
    guard let data else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
}
