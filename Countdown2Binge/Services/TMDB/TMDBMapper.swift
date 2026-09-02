//
//  TMDBMapper.swift
//  Countdown2Binge
//

import Foundation

/// Maps TMDB API responses to domain models
enum TMDBMapper {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    static func parseDate(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return dateFormatter.date(from: string)
    }

    // MARK: - Air-date correction (Apple TV+)

    /// Apple TV+ air dates arrive in the TMDB feed one calendar day early (the
    /// whole catalog is stored on the day *before* the public release — verified
    /// against known premieres, e.g. Ted Lasso S3 fed as Mar 14 vs the real
    /// Mar 15). Every other network we checked (HBO, Prime, Disney+, Hulu) is
    /// correct. So we shift Apple TV+ dates forward one day at ingestion; the
    /// engine then computes finale/premiere countdowns on the corrected dates.
    ///
    /// Heuristic, not a root cause — revisit if a correctly-dated Apple title
    /// ever appears (it would then over-shift by a day).
    private static func airDateDayOffset(networks: [TMDBNetwork]) -> Int {
        networks.contains { $0.name.localizedCaseInsensitiveContains("apple") } ? 1 : 0
    }

    private static func shift(_ date: Date?, byDays days: Int) -> Date? {
        guard let date, days != 0 else { return date }
        return Calendar.current.date(byAdding: .day, value: days, to: date)
    }

    private static func shift(_ season: SeasonData, byDays days: Int) -> SeasonData {
        SeasonData(
            id: season.id,
            seasonNumber: season.seasonNumber,
            name: season.name,
            overview: season.overview,
            posterPath: season.posterPath,
            airDate: shift(season.airDate, byDays: days),
            episodeCount: season.episodeCount,
            episodes: season.episodes.map { shift($0, byDays: days) },
            voteAverage: season.voteAverage
        )
    }

    private static func shift(_ episode: EpisodeData, byDays days: Int) -> EpisodeData {
        EpisodeData(
            id: episode.id,
            episodeNumber: episode.episodeNumber,
            seasonNumber: episode.seasonNumber,
            name: episode.name,
            overview: episode.overview,
            airDate: shift(episode.airDate, byDays: days),
            stillPath: episode.stillPath,
            runtime: episode.runtime,
            episodeType: episode.episodeType,
            voteAverage: episode.voteAverage
        )
    }

    // MARK: - Show Mapping

    static func map(_ details: TMDBShowDetails, seasons: [SeasonData], logoPath: String? = nil) -> ShowData {
        let offset = airDateDayOffset(networks: details.networks)
        let correctedSeasons = offset == 0 ? seasons : seasons.map { shift($0, byDays: offset) }
        return ShowData(
            id: details.id,
            name: details.name,
            overview: details.overview,
            posterPath: details.posterPath,
            backdropPath: details.backdropPath,
            logoPath: logoPath,
            firstAirDate: shift(parseDate(details.firstAirDate), byDays: offset),
            status: ShowStatus(rawValue: details.status) ?? .planned,
            genres: details.genres.map { GenreData(id: $0.id, name: $0.name) },
            networks: details.networks.map { map($0) },
            createdBy: details.createdBy?.map { Creator(id: $0.id, name: $0.name, profilePath: $0.profilePath) },
            seasons: correctedSeasons,
            numberOfSeasons: details.numberOfSeasons,
            numberOfEpisodes: details.numberOfEpisodes,
            inProduction: details.inProduction,
            voteAverage: details.voteAverage
        )
    }

    static func map(_ network: TMDBNetwork) -> NetworkData {
        NetworkData(
            id: network.id,
            name: network.name,
            logoPath: network.logoPath
        )
    }

    // MARK: - Season Mapping

    static func map(_ summary: TMDBSeasonSummary) -> SeasonData {
        SeasonData(
            id: summary.id,
            seasonNumber: summary.seasonNumber,
            name: summary.name,
            overview: summary.overview,
            posterPath: summary.posterPath,
            airDate: parseDate(summary.airDate),
            episodeCount: summary.episodeCount,
            episodes: []
        )
    }

    static func map(_ details: TMDBSeasonDetails) -> SeasonData {
        SeasonData(
            id: details.id,
            seasonNumber: details.seasonNumber,
            name: details.name,
            overview: details.overview,
            posterPath: details.posterPath,
            airDate: parseDate(details.airDate),
            episodeCount: details.episodes.count,
            episodes: details.episodes.map { map($0) },
            voteAverage: details.voteAverage
        )
    }

    // MARK: - Episode Mapping

    static func map(_ episode: TMDBEpisode) -> EpisodeData {
        EpisodeData(
            id: episode.id,
            episodeNumber: episode.episodeNumber,
            seasonNumber: episode.seasonNumber,
            name: episode.name,
            overview: episode.overview,
            airDate: parseDate(episode.airDate),
            stillPath: episode.stillPath,
            runtime: episode.runtime,
            episodeType: EpisodeType(rawValue: episode.episodeType ?? "standard") ?? .standard,
            voteAverage: episode.voteAverage
        )
    }
}
