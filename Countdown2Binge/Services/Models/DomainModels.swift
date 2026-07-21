//
//  DomainModels.swift
//  Countdown2Binge
//
//  Domain models (Data POSOs) used throughout the app.
//  These are plain structs that can be passed to views, services, and business logic.
//  They are separate from SwiftData models to keep persistence concerns isolated.
//

import Foundation

// MARK: - Enums

/// Show production/airing status from TMDB
enum ShowStatus: String, Codable, Sendable {
    case returning = "Returning Series"
    case ended = "Ended"
    case canceled = "Canceled"
    case inProduction = "In Production"
    case planned = "Planned"
    case pilot = "Pilot"

    var displayName: String {
        switch self {
        case .returning: return "Returning"
        case .ended: return "Ended"
        case .canceled: return "Canceled"
        case .inProduction: return "In Production"
        case .planned: return "Planned"
        case .pilot: return "Pilot"
        }
    }

    var isActive: Bool {
        switch self {
        case .returning, .inProduction, .pilot:
            return true
        case .ended, .canceled, .planned:
            return false
        }
    }
}

/// Episode type from TMDB
enum EpisodeType: String, Codable, Sendable {
    case standard
    case finale
    case midSeason = "mid_season"
}

// MARK: - Show

struct ShowData: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let logoPath: String?
    let firstAirDate: Date?
    let status: ShowStatus
    let genres: [GenreData]
    let networks: [NetworkData]
    let createdBy: [Creator]?
    let seasons: [SeasonData]
    let numberOfSeasons: Int
    let numberOfEpisodes: Int
    let inProduction: Bool
    let voteAverage: Double?

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ShowData, rhs: ShowData) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: Convenience

    var posterURL: URL? {
        TMDBConfiguration.imageURL(path: posterPath, size: .poster)
    }

    var posterSmallURL: URL? {
        TMDBConfiguration.imageURL(path: posterPath, size: .posterSmall)
    }

    var backdropURL: URL? {
        TMDBConfiguration.imageURL(path: backdropPath, size: .backdrop)
    }

    var logoURL: URL? {
        TMDBConfiguration.imageURL(path: logoPath, size: .logo)
    }

    var primaryNetwork: NetworkData? {
        networks.first
    }

    var genreNames: [String] {
        genres.map { $0.name }
    }

    var yearString: String? {
        guard let date = firstAirDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Lifecycle Helpers

    /// Current season (latest non-special season)
    var currentSeason: SeasonData? {
        seasons
            .filter { !$0.isSpecials }
            .max(by: { $0.seasonNumber < $1.seasonNumber })
    }

    /// Upcoming season (next season with future air date)
    var upcomingSeason: SeasonData? {
        seasons
            .filter { !$0.isSpecials && !$0.hasStarted && $0.airDate != nil }
            .min(by: { ($0.airDate ?? .distantFuture) < ($1.airDate ?? .distantFuture) })
    }

    /// Days until next premiere (from upcoming or current season)
    var daysUntilPremiere: Int? {
        upcomingSeason?.daysUntilPremiere ?? currentSeason?.daysUntilPremiere
    }

    /// Days until current season finale
    var daysUntilFinale: Int? {
        currentSeason?.daysUntilFinale
    }

    /// Derived lifecycle state
    var lifecycleState: ShowLifecycleState {
        // Cancelled is the only status we trust from TMDB
        if status == .canceled {
            return .cancelled
        }

        // No seasons yet = anticipated
        guard let currentSeason = currentSeason else {
            return .anticipated
        }

        // Season hasn't started airing
        if !currentSeason.hasStarted {
            return .anticipated
        }

        // Season is complete
        if currentSeason.isComplete {
            // Stay "airing" on finale day until midnight
            if currentSeason.isFinaleDay {
                return .airing
            }
            // If still in production, between seasons (anticipated)
            // If not in production, show has ended
            return inProduction ? .anticipated : .ended
        }

        // Season started but not complete
        return .airing
    }

    /// Timeline category for UI
    var timelineCategory: TimelineCategory {
        let state = lifecycleState

        switch state {
        case .cancelled, .ended:
            return .bingeReady

        case .completed:
            // User watch status - show in appropriate timeline category
            return .bingeReady

        case .airing:
            return .airingNow

        case .anticipated:
            // Check if we have a known premiere date
            if daysUntilPremiere != nil {
                return .premieringSoon
            }
            // No premiere date = TBD
            return .anticipated
        }
    }

    /// Check if show is ready to binge
    var isBingeReady: Bool {
        timelineCategory == .bingeReady
    }
}

// MARK: - Season

struct SeasonData: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let airDate: Date?
    let episodeCount: Int
    let episodes: [EpisodeData]
    let voteAverage: Double?

    init(
        id: Int,
        seasonNumber: Int,
        name: String,
        overview: String? = nil,
        posterPath: String? = nil,
        airDate: Date? = nil,
        episodeCount: Int,
        episodes: [EpisodeData] = [],
        voteAverage: Double? = nil
    ) {
        self.id = id
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.episodes = episodes
        self.voteAverage = voteAverage
    }

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SeasonData, rhs: SeasonData) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: Convenience

    var posterURL: URL? {
        TMDBConfiguration.imageURL(path: posterPath, size: .poster)
    }

    var isSpecials: Bool {
        seasonNumber == 0
    }

    // MARK: - Lifecycle Helpers

    /// Check if season has started airing
    var hasStarted: Bool {
        // Use season airDate, or fall back to first episode's air date
        let firstEpisodeDate = episodes
            .filter { $0.episodeNumber > 0 }
            .min(by: { $0.episodeNumber < $1.episodeNumber })?.airDate

        guard let startDate = airDate ?? firstEpisodeDate else {
            return false // No date means NOT started
        }
        return startDate <= Date()
    }

    /// Check if season is complete (all episodes have aired)
    var isComplete: Bool {
        guard hasStarted else { return false }
        guard !episodes.isEmpty else {
            // No episode data - check if we have episodeCount and airDate is in past
            if episodeCount > 0, let airDate = airDate {
                // Estimate: assume ~7 days per episode from air date
                let estimatedEndDate = Calendar.current.date(byAdding: .day, value: episodeCount * 7, to: airDate) ?? airDate
                return estimatedEndDate <= Date()
            }
            return false
        }

        // Check if all episodes have aired
        let airedEpisodes = episodes.filter { $0.hasAired }
        return airedEpisodes.count >= episodeCount && episodeCount > 0
    }

    /// Check if today is the finale day
    var isFinaleDay: Bool {
        guard let finaleDate = finaleDate else {
            return false
        }
        return Calendar.current.isDateInToday(finaleDate)
    }

    /// The finale date (last episode's air date)
    var finaleDate: Date? {
        episodes
            .filter { $0.airDate != nil }
            .max(by: { $0.episodeNumber < $1.episodeNumber })?
            .airDate
    }

    /// Days until season premiere (nil if already started or no date)
    var daysUntilPremiere: Int? {
        let firstEpisodeDate = episodes
            .filter { $0.episodeNumber > 0 }
            .min(by: { $0.episodeNumber < $1.episodeNumber })?.airDate

        guard let startDate = airDate ?? firstEpisodeDate else { return nil }
        guard startDate > Date() else { return nil }

        let days = Calendar.current.dateComponents([.day], from: Date(), to: startDate).day
        return days
    }

    /// Days until season finale (nil if complete or no data)
    var daysUntilFinale: Int? {
        guard hasStarted, !isComplete else { return nil }
        guard let finaleDate = finaleDate, finaleDate > Date() else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: finaleDate).day
    }
}

// MARK: - Episode

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
        if runtime >= 60 {
            let hours = runtime / 60
            let mins = runtime % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(runtime)m"
    }
}

// MARK: - Supporting Types

struct GenreData: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let name: String
}

struct NetworkData: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let name: String
    let logoPath: String?

    var logoURL: URL? {
        TMDBConfiguration.imageURL(path: logoPath, size: .logo)
    }
}

struct Creator: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let name: String
    let profilePath: String?

    var profileURL: URL? {
        guard let profilePath else { return nil }
        return URL(string: "\(TMDBConfiguration.imageBaseURL)/w185\(profilePath)")
    }
}

// MARK: - Lightweight Show (for lists/search)

/// Lightweight show data for search results and lists.
/// Use this instead of full ShowData when you only need basic info.
struct ShowSummary: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let genreIds: [Int]?

    var posterURL: URL? {
        TMDBConfiguration.imageURL(path: posterPath, size: .poster)
    }

    var posterSmallURL: URL? {
        TMDBConfiguration.imageURL(path: posterPath, size: .posterSmall)
    }

    var yearString: String? {
        guard let firstAirDate, firstAirDate.count >= 4 else { return nil }
        return String(firstAirDate.prefix(4))
    }
}

// MARK: - TMDBShowSummary Extension

extension TMDBShowSummary {
    /// Convert API response to domain model
    func toShowSummary() -> ShowSummary {
        ShowSummary(
            id: id,
            name: name,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            firstAirDate: firstAirDate,
            voteAverage: voteAverage,
            genreIds: genreIds
        )
    }
}
