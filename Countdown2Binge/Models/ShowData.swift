//
//  ShowData.swift
//  Countdown2Binge
//
//  Domain model for a TV show.
//

import Foundation

// MARK: - Show Status

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

// MARK: - Show Data

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

    /// Cached finale date from SwiftData (overrides computed value when set)
    var cachedFinaleDate: Date?

    /// Cached premiere date from SwiftData (overrides computed value when set)
    var cachedPremiereDate: Date?

    /// Number of spinoffs/related shows (stored when following, not computed on view)
    var spinoffCount: Int?

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

    /// Current season - the season that is currently airing or most recently completed
    /// Does NOT include anticipated/future seasons that haven't started yet
    var currentSeason: SeasonData? {
        let today = Calendar.current.startOfDay(for: Date())
        let regularSeasons = seasons.filter { !$0.isSpecials }

        // Find seasons that have started but NOT completed (currently airing)
        let airingSeasons = regularSeasons.filter { season in
            guard let premiere = season.premiereDate else { return false }
            let hasStarted = Calendar.current.startOfDay(for: premiere) <= today

            // Check if finale is still in the future (not complete)
            if let finale = season.finaleDate {
                let isComplete = Calendar.current.startOfDay(for: finale) < today
                return hasStarted && !isComplete
            }
            // No finale date = assume not complete if started
            return hasStarted
        }

        // Return the LOWEST season number among airing seasons
        if let current = airingSeasons.min(by: { $0.seasonNumber < $1.seasonNumber }) {
            return current
        }

        // Fallback: most recently COMPLETED season (not anticipated/future)
        let completedSeasons = regularSeasons.filter { season in
            guard let premiere = season.premiereDate else { return false }
            let hasStarted = Calendar.current.startOfDay(for: premiere) <= today
            return hasStarted
        }

        // Return highest season number among completed seasons
        if let mostRecent = completedSeasons.max(by: { $0.seasonNumber < $1.seasonNumber }) {
            return mostRecent
        }

        // Last resort: if no seasons have started, return nil (show is fully anticipated)
        return nil
    }

    /// Anticipated season - announced but hasn't started airing yet
    var anticipatedSeason: SeasonData? {
        let today = Calendar.current.startOfDay(for: Date())
        return seasons
            .filter { !$0.isSpecials }
            .filter { season in
                // Season hasn't started yet
                guard let premiere = season.premiereDate else {
                    // No premiere date = anticipated if it's beyond current season
                    if let current = currentSeason {
                        return season.seasonNumber > current.seasonNumber
                    }
                    return true
                }
                return Calendar.current.startOfDay(for: premiere) > today
            }
            .min(by: { $0.seasonNumber < $1.seasonNumber })
    }

    /// Whether a specific season number is anticipated (not yet started)
    func isAnticipatedSeason(_ seasonNumber: Int) -> Bool {
        guard let season = seasons.first(where: { $0.seasonNumber == seasonNumber && !$0.isSpecials }) else {
            return false
        }
        let today = Calendar.current.startOfDay(for: Date())
        guard let premiere = season.premiereDate else {
            // No premiere date - anticipated if beyond current season
            if let current = currentSeason {
                return seasonNumber > current.seasonNumber
            }
            return true
        }
        return Calendar.current.startOfDay(for: premiere) > today
    }

    /// Upcoming season (next season with future air date that hasn't started)
    var upcomingSeason: SeasonData? {
        anticipatedSeason
    }

    /// Days until next premiere (from upcoming or current season)
    /// Uses cached date from SwiftData if available
    var daysUntilPremiere: Int? {
        // Use cached premiere date from SwiftData if available
        if let cachedDate = cachedPremiereDate {
            return daysUntil(cachedDate)
        }
        return upcomingSeason?.daysUntilPremiere ?? currentSeason?.daysUntilPremiere
    }

    /// Days until current season finale
    /// Uses cached date from SwiftData if available
    var daysUntilFinale: Int? {
        // Use cached finale date from SwiftData if available
        if let cachedDate = cachedFinaleDate {
            return daysUntil(cachedDate)
        }
        return currentSeason?.daysUntilFinale
    }

    /// Helper to calculate days until a date
    private func daysUntil(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDate = calendar.startOfDay(for: date)
        guard startOfDate >= startOfToday else { return nil }
        return calendar.dateComponents([.day], from: startOfToday, to: startOfDate).day
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
