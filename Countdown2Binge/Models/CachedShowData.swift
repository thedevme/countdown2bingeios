//
//  CachedShowData.swift
//  Countdown2Binge
//

import Foundation
import SwiftData

/// Cached TMDB show data for offline access.
/// Stored as a relationship on FollowedShow.
@Model
final class CachedShowData {
    var tmdbId: Int
    var name: String
    var overview: String?
    var posterPath: String?
    var backdropPath: String?
    var logoPath: String?
    var firstAirDate: Date?
    var statusRaw: String
    var numberOfSeasons: Int
    var numberOfEpisodes: Int
    var inProduction: Bool

    /// Encoded season data as JSON string (avoiding SwiftData Data property issues)
    var seasonsJSON: String?

    /// Encoded genres as JSON string
    var genresJSON: String?

    /// Encoded networks as JSON string
    var networksJSON: String?

    /// Computed lifecycle state (updated on refresh)
    var lifecycleStateRaw: String

    init(from show: Show) {
        self.tmdbId = show.id
        self.name = show.name
        self.overview = show.overview
        self.posterPath = show.posterPath
        self.backdropPath = show.backdropPath
        self.logoPath = show.logoPath
        self.firstAirDate = show.firstAirDate
        self.statusRaw = show.status.rawValue
        self.numberOfSeasons = show.numberOfSeasons
        self.numberOfEpisodes = show.numberOfEpisodes
        self.inProduction = show.inProduction
        self.lifecycleStateRaw = show.lifecycleState.rawValue

        // Encode complex types as JSON strings
        if let data = try? JSONEncoder().encode(show.seasons) {
            self.seasonsJSON = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(show.genres) {
            self.genresJSON = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(show.networks) {
            self.networksJSON = String(data: data, encoding: .utf8)
        }
    }

    func update(from show: Show) {
        self.name = show.name
        self.overview = show.overview
        self.posterPath = show.posterPath
        self.backdropPath = show.backdropPath
        self.logoPath = show.logoPath
        self.firstAirDate = show.firstAirDate
        self.statusRaw = show.status.rawValue
        self.numberOfSeasons = show.numberOfSeasons
        self.numberOfEpisodes = show.numberOfEpisodes
        self.inProduction = show.inProduction
        self.lifecycleStateRaw = show.lifecycleState.rawValue
        if let data = try? JSONEncoder().encode(show.seasons) {
            self.seasonsJSON = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(show.genres) {
            self.genresJSON = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(show.networks) {
            self.networksJSON = String(data: data, encoding: .utf8)
        }
    }
}

// MARK: - Domain Model Conversion

extension CachedShowData {
    /// Convert cached data back to domain Show model
    func toShow() -> Show? {
        guard let status = ShowStatus(rawValue: statusRaw) else { return nil }

        let seasons: [Season] = {
            guard let json = seasonsJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([Season].self, from: data)) ?? []
        }()

        let genres: [Genre] = {
            guard let json = genresJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([Genre].self, from: data)) ?? []
        }()

        let networks: [Network] = {
            guard let json = networksJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([Network].self, from: data)) ?? []
        }()

        return Show(
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
            seasons: seasons,
            numberOfSeasons: numberOfSeasons,
            numberOfEpisodes: numberOfEpisodes,
            inProduction: inProduction
        )
    }

    /// Cached lifecycle state
    var lifecycleState: ShowLifecycleState {
        ShowLifecycleState(rawValue: lifecycleStateRaw) ?? .anticipated
    }
}
