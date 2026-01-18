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

// MARK: - Videos Response

struct TMDBVideosResponse: Codable {
    let results: [TMDBVideo]
}

struct TMDBVideo: Codable, Identifiable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
    let official: Bool
    let publishedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, key, name, site, type, official
        case publishedAt = "published_at"
    }

    /// YouTube thumbnail URL
    var thumbnailURL: URL? {
        guard site == "YouTube" else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(key)/mqdefault.jpg")
    }

    /// YouTube video URL
    var videoURL: URL? {
        guard site == "YouTube" else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
}

// MARK: - Credits Response

struct TMDBCreditsResponse: Codable {
    let cast: [TMDBCastMember]
    let crew: [TMDBCrewMember]
}

struct TMDBCastMember: Codable, Identifiable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let order: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, character, order
        case profilePath = "profile_path"
    }
}

struct TMDBCrewMember: Codable, Identifiable {
    let id: Int
    let name: String
    let job: String
    let department: String
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, job, department
        case profilePath = "profile_path"
    }
}
