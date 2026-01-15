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

    // MARK: - Show Mapping

    static func map(_ details: TMDBShowDetails, seasons: [Season], logoPath: String? = nil) -> Show {
        Show(
            id: details.id,
            name: details.name,
            overview: details.overview,
            posterPath: details.posterPath,
            backdropPath: details.backdropPath,
            logoPath: logoPath,
            firstAirDate: parseDate(details.firstAirDate),
            status: ShowStatus(rawValue: details.status) ?? .planned,
            genres: details.genres.map { Genre(id: $0.id, name: $0.name) },
            networks: details.networks.map { map($0) },
            seasons: seasons,
            numberOfSeasons: details.numberOfSeasons,
            numberOfEpisodes: details.numberOfEpisodes,
            inProduction: details.inProduction
        )
    }

    static func map(_ network: TMDBNetwork) -> Network {
        Network(
            id: network.id,
            name: network.name,
            logoPath: network.logoPath
        )
    }

    // MARK: - Season Mapping

    static func map(_ summary: TMDBSeasonSummary) -> Season {
        Season(
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

    static func map(_ details: TMDBSeasonDetails) -> Season {
        Season(
            id: details.id,
            seasonNumber: details.seasonNumber,
            name: details.name,
            overview: details.overview,
            posterPath: details.posterPath,
            airDate: parseDate(details.airDate),
            episodeCount: details.episodes.count,
            episodes: details.episodes.map { map($0) }
        )
    }

    // MARK: - Episode Mapping

    static func map(_ episode: TMDBEpisode) -> Episode {
        Episode(
            id: episode.id,
            episodeNumber: episode.episodeNumber,
            seasonNumber: episode.seasonNumber,
            name: episode.name,
            overview: episode.overview,
            airDate: parseDate(episode.airDate),
            stillPath: episode.stillPath,
            runtime: episode.runtime,
            episodeType: EpisodeType(rawValue: episode.episodeType ?? "standard") ?? .standard
        )
    }
}
