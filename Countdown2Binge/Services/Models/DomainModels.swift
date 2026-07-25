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
        case .returning: return String(localized: "show_status_returning")
        case .ended: return String(localized: "show_status_ended")
        case .canceled: return String(localized: "show_status_canceled")
        case .inProduction: return String(localized: "show_status_in_production")
        case .planned: return String(localized: "show_status_planned")
        case .pilot: return String(localized: "show_status_pilot")
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
        return date.localizedYear
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

    // MARK: - Lifecycle Helpers (all use episode data as source of truth)

    /// First episode of the season (by episode number)
    private var firstEpisode: EpisodeData? {
        episodes
            .filter { $0.episodeNumber > 0 }
            .min(by: { $0.episodeNumber < $1.episodeNumber })
    }

    /// Finale episode - explicitly marked as finale type
    var finaleEpisode: EpisodeData? {
        episodes.first { $0.episodeType == .finale }
    }

    /// Premiere date from first episode's air date
    var premiereDate: Date? {
        firstEpisode?.airDate
    }

    /// Finale date from finale episode's air date
    var finaleDate: Date? {
        finaleEpisode?.airDate
    }

    /// Check if season has started airing (first episode's air date has passed)
    var hasStarted: Bool {
        guard let premiereDate = premiereDate else {
            return false
        }
        let calendar = Calendar.current
        return calendar.startOfDay(for: premiereDate) <= calendar.startOfDay(for: Date())
    }

    /// Check if season is complete (finale episode has aired)
    var isComplete: Bool {
        guard hasStarted else { return false }
        guard let finaleEp = finaleEpisode, let finaleAirDate = finaleEp.airDate else {
            return false // No finale episode = not complete
        }
        let calendar = Calendar.current
        // Complete if finale date is in the past (not today)
        return calendar.startOfDay(for: finaleAirDate) < calendar.startOfDay(for: Date())
    }

    /// Check if today is the finale day
    var isFinaleDay: Bool {
        guard let finaleDate = finaleDate else {
            return false
        }
        return Calendar.current.isDateInToday(finaleDate)
    }

    /// Days until season premiere (nil if already started or no date)
    var daysUntilPremiere: Int? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        guard let premiereDate = premiereDate else { return nil }
        let startOfPremiereDate = calendar.startOfDay(for: premiereDate)

        // Return nil if already started
        guard startOfPremiereDate >= startOfToday else { return nil }

        return calendar.dateComponents([.day], from: startOfToday, to: startOfPremiereDate).day
    }

    /// Days until season finale (nil if no finale episode or finale has passed)
    var daysUntilFinale: Int? {
        guard hasStarted else { return nil }

        // Must have a finale episode with an air date
        guard let finaleDate = finaleDate else { return nil }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfFinaleDate = calendar.startOfDay(for: finaleDate)

        // Finale must be today or in the future to show countdown
        guard startOfFinaleDate >= startOfToday else {
            return nil
        }

        return calendar.dateComponents([.day], from: startOfToday, to: startOfFinaleDate).day
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
        return runtime.localizedRuntime
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
