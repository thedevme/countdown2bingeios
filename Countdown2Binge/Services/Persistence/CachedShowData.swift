//
//  CachedShowData.swift
//  Countdown2Binge
//
//  SwiftData model for caching show metadata from TMDB.
//  Stores show data as JSON for flexibility.
//

import Foundation
import SwiftData

@Model
final class CachedShowData {
    /// TMDB ID of the show
    var tmdbId: Int

    /// Show name (for quick access without parsing JSON)
    var name: String

    /// Poster path (for quick access)
    var posterPath: String?

    /// Backdrop path (for quick access)
    var backdropPath: String?

    /// Number of seasons
    var numberOfSeasons: Int

    /// Number of episodes
    var numberOfEpisodes: Int

    /// Whether show is in production
    var inProduction: Bool

    /// Raw status string from TMDB
    var statusRaw: String

    /// Cached lifecycle state (updated on refresh)
    var lifecycleStateRaw: String

    /// Full show data as JSON (for complete data access)
    var showDataJSON: Data?

    /// Seasons data as JSON
    var seasonsJSON: Data?

    /// When this cache was last updated
    var updatedAt: Date

    /// Cached finale date for current season (stored explicitly for reliability)
    var finaleDate: Date?

    /// Cached premiere date for upcoming season
    var premiereDate: Date?

    /// Inverse relationship to FollowedShow
    @Relationship(inverse: \FollowedShow.cachedData)
    var followedShow: FollowedShow?

    init(
        tmdbId: Int,
        name: String,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        numberOfSeasons: Int = 0,
        numberOfEpisodes: Int = 0,
        inProduction: Bool = false,
        statusRaw: String = "Planned",
        lifecycleStateRaw: String = "anticipated"
    ) {
        self.tmdbId = tmdbId
        self.name = name
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.numberOfSeasons = numberOfSeasons
        self.numberOfEpisodes = numberOfEpisodes
        self.inProduction = inProduction
        self.statusRaw = statusRaw
        self.lifecycleStateRaw = lifecycleStateRaw
        self.updatedAt = Date()
    }

    // MARK: - Conversion

    /// Convert cached data to ShowData domain model
    func toShow() -> ShowData? {
        guard let jsonData = showDataJSON else { return nil }
        return try? JSONDecoder().decode(ShowData.self, from: jsonData)
    }

    /// Update cache from ShowData
    func update(from show: ShowData) {
        self.name = show.name
        self.posterPath = show.posterPath
        self.backdropPath = show.backdropPath
        self.numberOfSeasons = show.numberOfSeasons
        self.numberOfEpisodes = show.numberOfEpisodes
        self.inProduction = show.inProduction
        self.statusRaw = show.status.rawValue
        self.lifecycleStateRaw = show.lifecycleState.rawValue
        self.updatedAt = Date()

        // Store finale/premiere dates explicitly
        self.finaleDate = show.currentSeason?.finaleDate
        self.premiereDate = show.upcomingSeason?.premiereDate ?? show.currentSeason?.premiereDate

        // Encode full show data
        let encoder = JSONEncoder()
        self.showDataJSON = try? encoder.encode(show)
        self.seasonsJSON = try? encoder.encode(show.seasons)
    }

    // MARK: - Convenience

    var posterURL: URL? {
        TMDBConfiguration.imageURL(path: posterPath, size: .poster)
    }

    var backdropURL: URL? {
        TMDBConfiguration.imageURL(path: backdropPath, size: .backdrop)
    }

    var lifecycleState: ShowLifecycleState {
        ShowLifecycleState(rawValue: lifecycleStateRaw) ?? .anticipated
    }

    var status: ShowStatus {
        ShowStatus(rawValue: statusRaw) ?? .planned
    }

    /// Days until finale (computed from stored finaleDate)
    var daysUntilFinale: Int? {
        guard let finaleDate else { return nil }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfFinaleDate = calendar.startOfDay(for: finaleDate)
        guard startOfFinaleDate >= startOfToday else { return nil }
        return calendar.dateComponents([.day], from: startOfToday, to: startOfFinaleDate).day
    }

    /// Days until premiere (computed from stored premiereDate)
    var daysUntilPremiere: Int? {
        guard let premiereDate else { return nil }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfPremiereDate = calendar.startOfDay(for: premiereDate)
        guard startOfPremiereDate >= startOfToday else { return nil }
        return calendar.dateComponents([.day], from: startOfToday, to: startOfPremiereDate).day
    }
}
