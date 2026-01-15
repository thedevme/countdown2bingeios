//
//  Episode.swift
//  Countdown2Binge
//

import Foundation

/// Episode types from TMDB
enum EpisodeType: String, Codable {
    case standard
    case finale
    case midSeason = "mid_season"

    var isFinale: Bool { self == .finale }
}

/// Represents a single episode of a TV show.
struct Episode: Identifiable, Equatable, Hashable {
    let id: Int
    let episodeNumber: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let airDate: Date?
    let stillPath: String?
    let runtime: Int?
    var episodeType: EpisodeType = .standard
    var watchedDate: Date?

    /// Whether this episode has been marked as watched
    var isWatched: Bool {
        watchedDate != nil
    }

    /// Whether this episode has already aired
    var hasAired: Bool {
        guard let airDate else { return false }
        return airDate <= Date()
    }

    /// Days until this episode airs (nil if already aired or no date)
    var daysUntilAir: Int? {
        guard let airDate, !hasAired else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: airDate).day
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Codable

extension Episode: Codable {
    enum CodingKeys: String, CodingKey {
        case id, episodeNumber, seasonNumber, name, overview, airDate, stillPath, runtime
        case episodeType, watchedDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        episodeNumber = try container.decode(Int.self, forKey: .episodeNumber)
        seasonNumber = try container.decode(Int.self, forKey: .seasonNumber)
        name = try container.decode(String.self, forKey: .name)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        airDate = try container.decodeIfPresent(Date.self, forKey: .airDate)
        stillPath = try container.decodeIfPresent(String.self, forKey: .stillPath)
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        // Handle missing episodeType from old cached data
        episodeType = try container.decodeIfPresent(EpisodeType.self, forKey: .episodeType) ?? .standard
        watchedDate = try container.decodeIfPresent(Date.self, forKey: .watchedDate)
    }
}
