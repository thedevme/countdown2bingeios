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

    /// Show overview/synopsis
    var overview: String?

    /// Poster path
    var posterPath: String?

    /// Backdrop path
    var backdropPath: String?

    /// Logo path
    var logoPath: String?

    /// First air date
    var firstAirDate: Date?

    /// Status raw value
    var statusRaw: String?

    /// Whether in production
    var inProduction: Bool?

    /// Vote average
    var voteAverage: Double?

    /// Total number of seasons
    var numberOfSeasons: Int

    /// Total number of episodes
    var numberOfEpisodes: Int

    /// Genres as JSON
    var genresJSON: Data?

    /// Networks as JSON
    var networksJSON: Data?

    /// Creators as JSON
    var creatorsJSON: Data?

    /// Spinoff count
    var spinoffCount: Int?

    /// Seasons in this series
    @Relationship(deleteRule: .cascade, inverse: \SeriesSeason.series)
    var seasons: [SeriesSeason]

    /// When this was last updated
    var updatedAt: Date?

    /// When this was added
    var dateAdded: Date?

    init(
        tmdbId: Int,
        name: String,
        overview: String? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        logoPath: String? = nil,
        firstAirDate: Date? = nil,
        statusRaw: String = "Planned",
        inProduction: Bool = false,
        voteAverage: Double? = nil,
        numberOfSeasons: Int = 0,
        numberOfEpisodes: Int = 0
    ) {
        self.tmdbId = tmdbId
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.logoPath = logoPath
        self.firstAirDate = firstAirDate
        self.statusRaw = statusRaw
        self.inProduction = inProduction
        self.voteAverage = voteAverage
        self.numberOfSeasons = numberOfSeasons
        self.numberOfEpisodes = numberOfEpisodes
        self.updatedAt = Date()
        self.dateAdded = Date()
        self.seasons = []
    }

    // MARK: - Computed

    var status: ShowStatus {
        guard let statusRaw else { return .planned }
        return ShowStatus(rawValue: statusRaw) ?? .planned
    }

    var posterURL: URL? {
        TMDBConfiguration.imageURL(path: posterPath, size: .poster)
    }

    var backdropURL: URL? {
        TMDBConfiguration.imageURL(path: backdropPath, size: .backdrop)
    }

    var logoURL: URL? {
        TMDBConfiguration.imageURL(path: logoPath, size: .logo)
    }

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

    var sortedSeasons: [SeriesSeason] {
        seasons.filter { $0.seasonNumber > 0 }
            .sorted { $0.seasonNumber < $1.seasonNumber }
    }

    /// Current season - prioritizes upcoming, then airing, then most recent completed
    var currentSeason: SeriesSeason? {
        let today = Calendar.current.startOfDay(for: Date())
        let regularSeasons = seasons.filter { $0.seasonNumber > 0 }

        // 1. FIRST check for upcoming season (hasn't started yet) - highest numbered
        let upcomingSeasons = regularSeasons.filter { season in
            guard let premiere = season.premiereDate else { return false }
            return Calendar.current.startOfDay(for: premiere) > today
        }
        if let upcoming = upcomingSeasons.max(by: { $0.seasonNumber < $1.seasonNumber }) {
            return upcoming
        }

        // 2. Then check for currently airing (started but not complete)
        let airingSeasons = regularSeasons.filter { season in
            guard let premiere = season.premiereDate else { return false }
            let hasStarted = Calendar.current.startOfDay(for: premiere) <= today

            if let finale = season.finaleDate {
                let isComplete = Calendar.current.startOfDay(for: finale) < today
                return hasStarted && !isComplete
            }
            return hasStarted
        }
        if let airing = airingSeasons.max(by: { $0.seasonNumber < $1.seasonNumber }) {
            return airing
        }

        // 3. Fallback: most recently completed season
        return regularSeasons.max(by: { $0.seasonNumber < $1.seasonNumber })
    }

    // MARK: - JSON Accessors

    var genres: [GenreData] {
        get {
            guard let data = genresJSON else { return [] }
            return (try? JSONDecoder().decode([GenreData].self, from: data)) ?? []
        }
        set {
            genresJSON = try? JSONEncoder().encode(newValue)
        }
    }

    var networks: [NetworkData] {
        get {
            guard let data = networksJSON else { return [] }
            return (try? JSONDecoder().decode([NetworkData].self, from: data)) ?? []
        }
        set {
            networksJSON = try? JSONEncoder().encode(newValue)
        }
    }

    var creators: [Creator]? {
        get {
            guard let data = creatorsJSON else { return nil }
            return try? JSONDecoder().decode([Creator].self, from: data)
        }
        set {
            creatorsJSON = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - Conversion to ShowData

extension Series {
    /// Convert Series to ShowData for compatibility with existing views
    func toShow() -> ShowData {
        let showSeasons = sortedSeasons.map { seriesSeason -> SeasonData in
            let episodes = seriesSeason.sortedEpisodes.map { seriesEpisode -> EpisodeData in
                EpisodeData(
                    id: seriesEpisode.tmdbId,
                    episodeNumber: seriesEpisode.episodeNumber,
                    seasonNumber: seriesEpisode.seasonNumber,
                    name: seriesEpisode.name,
                    overview: nil,
                    airDate: seriesEpisode.airDate,
                    stillPath: seriesEpisode.stillPath,
                    runtime: seriesEpisode.runtime,
                    episodeType: seriesEpisode.episodeType,
                    voteAverage: nil
                )
            }
            return SeasonData(
                id: seriesSeason.tmdbId,
                seasonNumber: seriesSeason.seasonNumber,
                name: seriesSeason.name,
                overview: seriesSeason.overview,
                posterPath: seriesSeason.posterPath,
                airDate: seriesSeason.airDate,
                episodeCount: seriesSeason.episodeCount,
                episodes: episodes,
                voteAverage: seriesSeason.voteAverage
            )
        }

        return ShowData(
            id: tmdbId,
            name: name,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            logoPath: logoPath,
            firstAirDate: firstAirDate,
            status: status,
            genres: genres,
            networks: networks,
            createdBy: creators,
            seasons: showSeasons,
            numberOfSeasons: numberOfSeasons,
            numberOfEpisodes: numberOfEpisodes,
            inProduction: inProduction ?? false,
            voteAverage: voteAverage,
            spinoffCount: spinoffCount
        )
    }

    /// Update from ShowData
    func update(from show: ShowData) {
        self.name = show.name
        self.overview = show.overview
        self.posterPath = show.posterPath
        self.backdropPath = show.backdropPath
        self.logoPath = show.logoPath
        self.firstAirDate = show.firstAirDate
        self.statusRaw = show.status.rawValue
        self.inProduction = show.inProduction
        self.voteAverage = show.voteAverage
        self.numberOfSeasons = show.numberOfSeasons
        self.numberOfEpisodes = show.numberOfEpisodes
        self.genres = show.genres
        self.networks = show.networks
        self.creators = show.createdBy
        self.spinoffCount = show.spinoffCount
        self.updatedAt = Date()
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

    /// Season overview
    var overview: String?

    /// Poster path
    var posterPath: String?

    /// Air date
    var airDate: Date?

    /// Episode count
    var episodeCount: Int

    /// Vote average
    var voteAverage: Double?

    /// Parent series
    var series: Series?

    /// Episodes in this season
    @Relationship(deleteRule: .cascade, inverse: \SeriesEpisode.season)
    var episodes: [SeriesEpisode]

    init(
        tmdbId: Int,
        seasonNumber: Int,
        name: String,
        overview: String? = nil,
        posterPath: String? = nil,
        airDate: Date? = nil,
        episodeCount: Int = 0,
        voteAverage: Double? = nil
    ) {
        self.tmdbId = tmdbId
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.voteAverage = voteAverage
        self.episodes = []
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

    var sortedEpisodes: [SeriesEpisode] {
        episodes.sorted { $0.episodeNumber < $1.episodeNumber }
    }

    /// First episode of the season
    var firstEpisode: SeriesEpisode? {
        episodes.filter { $0.episodeNumber > 0 }
            .min(by: { $0.episodeNumber < $1.episodeNumber })
    }

    /// Finale episode
    var finaleEpisode: SeriesEpisode? {
        if let finale = episodes.first(where: { $0.episodeType == .finale }) {
            return finale
        }
        return episodes.filter { $0.episodeNumber > 0 }
            .max(by: { $0.episodeNumber < $1.episodeNumber })
    }

    /// Premiere date from first episode
    var premiereDate: Date? {
        firstEpisode?.airDate
    }

    /// Finale date from finale episode
    var finaleDate: Date? {
        finaleEpisode?.airDate
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

    /// Episode overview
    var overview: String?

    /// Air date
    var airDate: Date?

    /// Still image path
    var stillPath: String?

    /// Runtime in minutes
    var runtime: Int?

    /// Episode type raw value
    var episodeTypeRaw: String?

    /// Vote average
    var voteAverage: Double?

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
        overview: String? = nil,
        airDate: Date? = nil,
        stillPath: String? = nil,
        runtime: Int? = nil,
        episodeTypeRaw: String = "standard",
        voteAverage: Double? = nil,
        isWatched: Bool = false
    ) {
        self.tmdbId = tmdbId
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.airDate = airDate
        self.stillPath = stillPath
        self.runtime = runtime
        self.episodeTypeRaw = episodeTypeRaw
        self.voteAverage = voteAverage
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

    var episodeType: EpisodeType {
        guard let episodeTypeRaw else { return .standard }
        return EpisodeType(rawValue: episodeTypeRaw) ?? .standard
    }

    var stillURL: URL? {
        TMDBConfiguration.imageURL(path: stillPath, size: .still)
    }
}
