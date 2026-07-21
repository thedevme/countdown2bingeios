//
//  Series.swift
//  Countdown2Binge
//
//  SwiftData models for tracking watch progress.
//  Series -> Season -> Episode hierarchy with watched state.
//

import Foundation
import SwiftData

// MARK: - Series

@Model
final class Series {
    /// TMDB ID of the show
    @Attribute(.unique) var tmdbId: Int

    /// Show name
    var name: String

    /// Poster path
    var posterPath: String?

    /// Total number of seasons
    var numberOfSeasons: Int

    /// Total number of episodes
    var numberOfEpisodes: Int

    /// Seasons in this series
    @Relationship(deleteRule: .cascade, inverse: \SeriesSeason.series)
    var seasons: [SeriesSeason] = []

    /// When this was last updated
    var updatedAt: Date

    init(tmdbId: Int, name: String, posterPath: String? = nil, numberOfSeasons: Int = 0, numberOfEpisodes: Int = 0) {
        self.tmdbId = tmdbId
        self.name = name
        self.posterPath = posterPath
        self.numberOfSeasons = numberOfSeasons
        self.numberOfEpisodes = numberOfEpisodes
        self.updatedAt = Date()
    }

    // MARK: - Computed

    var watchedEpisodeCount: Int {
        seasons.reduce(0) { $0 + $1.watchedEpisodeCount }
    }

    var totalEpisodeCount: Int {
        seasons.reduce(0) { $0 + $1.episodes.count }
    }

    var watchProgress: Double {
        guard totalEpisodeCount > 0 else { return 0 }
        return Double(watchedEpisodeCount) / Double(totalEpisodeCount)
    }

    var isFullyWatched: Bool {
        totalEpisodeCount > 0 && watchedEpisodeCount == totalEpisodeCount
    }
}

// MARK: - Season

@Model
final class SeriesSeason {
    /// TMDB ID of the season
    @Attribute(.unique) var tmdbId: Int

    /// Season number (0 = specials)
    var seasonNumber: Int

    /// Season name
    var name: String

    /// Air date
    var airDate: Date?

    /// Episode count
    var episodeCount: Int

    /// Parent series
    var series: Series?

    /// Episodes in this season
    @Relationship(deleteRule: .cascade, inverse: \SeriesEpisode.season)
    var episodes: [SeriesEpisode] = []

    init(tmdbId: Int, seasonNumber: Int, name: String, airDate: Date? = nil, episodeCount: Int = 0) {
        self.tmdbId = tmdbId
        self.seasonNumber = seasonNumber
        self.name = name
        self.airDate = airDate
        self.episodeCount = episodeCount
    }

    // MARK: - Computed

    var watchedEpisodeCount: Int {
        episodes.filter { $0.isWatched }.count
    }

    var isFullyWatched: Bool {
        !episodes.isEmpty && episodes.allSatisfy { $0.isWatched }
    }

    var watchProgress: Double {
        guard !episodes.isEmpty else { return 0 }
        return Double(watchedEpisodeCount) / Double(episodes.count)
    }
}

// MARK: - Episode

@Model
final class SeriesEpisode {
    /// TMDB ID of the episode
    @Attribute(.unique) var tmdbId: Int

    /// Episode number within season
    var episodeNumber: Int

    /// Season number
    var seasonNumber: Int

    /// Episode name
    var name: String

    /// Air date
    var airDate: Date?

    /// Runtime in minutes
    var runtime: Int?

    /// Whether user has watched this episode
    var isWatched: Bool

    /// When the user marked it as watched
    var watchedAt: Date?

    /// Parent season
    var season: SeriesSeason?

    init(
        tmdbId: Int,
        episodeNumber: Int,
        seasonNumber: Int,
        name: String,
        airDate: Date? = nil,
        runtime: Int? = nil,
        isWatched: Bool = false
    ) {
        self.tmdbId = tmdbId
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.name = name
        self.airDate = airDate
        self.runtime = runtime
        self.isWatched = isWatched
    }

    // MARK: - Convenience

    var episodeCode: String {
        String(format: "S%02dE%02d", seasonNumber, episodeNumber)
    }

    var hasAired: Bool {
        guard let airDate else { return false }
        return airDate <= Date()
    }
}
