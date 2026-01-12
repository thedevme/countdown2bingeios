//
//  Show.swift
//  Countdown2Binge
//

import Foundation

/// TMDB show status values
enum ShowStatus: String, Codable {
    case returning = "Returning Series"
    case ended = "Ended"
    case cancelled = "Canceled"
    case inProduction = "In Production"
    case planned = "Planned"
    case pilot = "Pilot"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ShowStatus(rawValue: rawValue) ?? .planned
    }
}

/// Represents a TV show with all its metadata.
struct Show: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: Date?
    let status: ShowStatus
    let genres: [Genre]
    let networks: [Network]
    var seasons: [Season]
    let numberOfSeasons: Int
    let numberOfEpisodes: Int
    let inProduction: Bool

    /// The current or most recent season
    var currentSeason: Season? {
        seasons
            .filter { $0.seasonNumber > 0 } // Exclude specials (season 0)
            .max(by: { $0.seasonNumber < $1.seasonNumber })
    }

    /// The next season to air (if any)
    var upcomingSeason: Season? {
        seasons
            .filter { $0.seasonNumber > 0 && !$0.hasStarted }
            .min(by: { $0.seasonNumber < $1.seasonNumber })
    }

    static func == (lhs: Show, rhs: Show) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Supporting Types

struct Genre: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
}

struct Network: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let logoPath: String?
}
