//
//  EpisodeData.swift
//  Countdown2Binge
//
//  Domain model for a TV episode.
//

import Foundation

// MARK: - Episode Type

/// Episode type from TMDB
enum EpisodeType: String, Codable, Sendable {
    case standard
    case finale
    case midSeason = "mid_season"
}

// MARK: - Episode Data

struct EpisodeData: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let episodeNumber: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let airDate: Date?
    let stillPath: String?
    let runtime: Int?
    let episodeType: EpisodeType
    let voteAverage: Double?

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: EpisodeData, rhs: EpisodeData) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: Convenience

    var stillURL: URL? {
        TMDBConfiguration.imageURL(path: stillPath, size: .still)
    }

    var episodeCode: String {
        String(format: "S%02dE%02d", seasonNumber, episodeNumber)
    }

    var hasAired: Bool {
        guard let airDate else { return false }
        return airDate <= Date()
    }

    var runtimeFormatted: String? {
        guard let runtime, runtime > 0 else { return nil }
        return runtime.localizedRuntime
    }
}
