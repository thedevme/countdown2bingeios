//
//  TMDBModels.swift
//  Countdown2Binge
//

import Foundation

// MARK: - API Response Models
// These map directly to TMDB JSON responses

struct TMDBSearchResponse: Codable {
    let page: Int
    let results: [TMDBShowSummary]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBShowSummary: Codable, Identifiable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let genreIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case genreIds = "genre_ids"
    }
}

struct TMDBShowDetails: Codable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let status: String
    let genres: [TMDBGenre]
    let networks: [TMDBNetwork]
    let seasons: [TMDBSeasonSummary]
    let numberOfSeasons: Int
    let numberOfEpisodes: Int
    let inProduction: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, overview, status, genres, networks, seasons
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
        case inProduction = "in_production"
    }
}

struct TMDBGenre: Codable {
    let id: Int
    let name: String
}

struct TMDBNetwork: Codable {
    let id: Int
    let name: String
    let logoPath: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath = "logo_path"
    }
}

struct TMDBSeasonSummary: Codable {
    let id: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let airDate: String?
    let episodeCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case seasonNumber = "season_number"
        case posterPath = "poster_path"
        case airDate = "air_date"
        case episodeCount = "episode_count"
    }
}

struct TMDBSeasonDetails: Codable {
    let id: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let airDate: String?
    let episodes: [TMDBEpisode]

    enum CodingKeys: String, CodingKey {
        case id, name, overview, episodes
        case seasonNumber = "season_number"
        case posterPath = "poster_path"
        case airDate = "air_date"
    }
}

struct TMDBEpisode: Codable {
    let id: Int
    let episodeNumber: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let airDate: String?
    let stillPath: String?
    let runtime: Int?
    let episodeType: String?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, runtime
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case airDate = "air_date"
        case stillPath = "still_path"
        case episodeType = "episode_type"
    }
}

// MARK: - Images Response

struct TMDBImagesResponse: Codable {
    let logos: [TMDBImage]
}

struct TMDBImage: Codable {
    let filePath: String
    let aspectRatio: Double
    let width: Int
    let height: Int
    let iso6391: String?

    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
        case aspectRatio = "aspect_ratio"
        case width, height
        case iso6391 = "iso_639_1"
    }
}
