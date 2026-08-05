//
//  EpisodeModels.swift
//  Countdown2Binge
//
//  Models and state for the Episodes section.
//

import SwiftUI

// MARK: - Episode State

enum EpisodeState {
    case aired       // Episode has aired and is available
    case next        // Next episode to air
    case locked      // Not yet aired
    case finale      // Last episode of the season

    var dotColor: Color {
        switch self {
        case .aired: return .c2bTeal
        case .next: return .c2bTealBright
        case .locked: return Color.white.opacity(0.1)
        case .finale: return .c2bTealLine
        }
    }

    var label: String {
        switch self {
        case .aired: return String(localized: "episode_status_aired")
        case .next: return String(localized: "episode_status_up_next")
        case .locked: return String(localized: "episode_status_not_aired")
        case .finale: return String(localized: "episode_status_finale")
        }
    }
}

// MARK: - Episode Display Model

struct EpisodeDisplayModel: Identifiable {
    let id: String
    let number: Int
    let seasonNumber: Int
    let title: String
    let description: String
    let runtime: Int
    let airDate: Date?
    var isWatched: Bool
    let hasAired: Bool
    let isFinale: Bool

    var state: EpisodeState {
        if isFinale && !hasAired { return .finale }
        if hasAired { return .aired }
        // Logic for "next" would be set externally
        return .locked
    }

    var formattedRuntime: String {
        runtime.localizedRuntime
    }

    var formattedAirDate: String {
        guard let date = airDate else { return String(localized: "date_tba") }
        return date.localizedWeekdayDate
    }

    var shortAirDate: String {
        guard let date = airDate else { return String(localized: "date_tba") }
        return date.localizedShortDate
    }

    var daysUntilAir: Int? {
        guard let date = airDate, date > Date() else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }
}

// MARK: - Season Display Model

struct SeasonDisplayModel: Identifiable {
    let id: String
    let number: Int
    let name: String
    let episodes: [EpisodeDisplayModel]
    let isCurrent: Bool
    let airDate: Date?

    var totalEpisodes: Int { episodes.count }
    var releasedCount: Int { episodes.filter { $0.hasAired }.count }
    var watchedCount: Int { episodes.filter { $0.isWatched }.count }
    var isComplete: Bool { releasedCount == totalEpisodes }
    var isFullyWatched: Bool { watchedCount == totalEpisodes && totalEpisodes > 0 }

    /// True if season is still airing (not all episodes released)
    var isAiring: Bool { releasedCount < totalEpisodes && releasedCount > 0 }

    /// True if show is in "schedule" mode (still counting down to binge-ready)
    var needsScheduleMode: Bool { releasedCount < totalEpisodes }

    /// Initialize from SwiftData Season model.
    /// Reads watch state directly from Episode.hasWatched (single source of truth).
    /// Uses conservative finale rule: only episodes explicitly typed as finale.
    init(from season: Season, isCurrent: Bool) {
        self.id = "\(season.id)"
        self.number = season.seasonNumber
        self.name = season.name
        self.isCurrent = isCurrent
        self.airDate = season.airDate

        let sortedEps = season.sortedEpisodes
        // Conservative finale: only use explicitly typed finale episodes
        let finaleEpisodeNumber = sortedEps.first { $0.episodeType == .finale }?.episodeNumber

        self.episodes = sortedEps.map { episode in
            EpisodeDisplayModel(
                id: "\(episode.id)",
                number: episode.episodeNumber,
                seasonNumber: episode.seasonNumber,
                title: episode.name,
                description: episode.overview,
                runtime: episode.runtime,
                airDate: episode.airDate,
                isWatched: episode.hasWatched,
                hasAired: episode.hasAired,
                isFinale: finaleEpisodeNumber != nil && episode.episodeNumber == finaleEpisodeNumber
            )
        }
    }

    /// Memberwise initializer for previews and tests.
    init(
        id: String,
        number: Int,
        name: String,
        episodes: [EpisodeDisplayModel],
        isCurrent: Bool,
        airDate: Date? = nil
    ) {
        self.id = id
        self.number = number
        self.name = name
        self.episodes = episodes
        self.isCurrent = isCurrent
        self.airDate = airDate
    }
}


// MARK: - Binge Plan Model

struct BingePlan: Identifiable {
    let id = UUID()
    let fromSeason: Int
    let toSeason: Int
    let totalEpisodes: Int
    let episodesPerWeek: Int
    let episodesPerDay: Double

    var seasonRange: String {
        if fromSeason == toSeason {
            return "S\(fromSeason)"
        }
        return "S\(fromSeason)–S\(toSeason)"
    }

    var title: String {
        if fromSeason == toSeason {
            return String(localized: "rewatch_single_season \(fromSeason)")
        }
        return String(localized: "rewatch_season_range \(fromSeason) \(toSeason)")
    }
}

// MARK: - Domain Model Conversions

extension EpisodeData {
    /// Convert to display model for the Episodes section
    func toDisplayModel(isWatched: Bool, isFinale: Bool) -> EpisodeDisplayModel {
        EpisodeDisplayModel(
            id: "\(id)",
            number: episodeNumber,
            seasonNumber: seasonNumber,
            title: name,
            description: overview ?? "",
            runtime: runtime ?? 45,
            airDate: airDate,
            isWatched: isWatched,
            hasAired: hasAired,
            isFinale: isFinale
        )
    }
}

extension SeasonData {
    /// Convert to display model for the Episodes section
    /// - Parameters:
    ///   - isCurrent: Whether this is the current/active season
    ///   - watchedEpisodes: Set of episode numbers that have been watched
    func toDisplayModel(
        isCurrent: Bool,
        watchedEpisodes: Set<Int>
    ) -> SeasonDisplayModel {
        let sortedEpisodes = episodes
            .filter { $0.episodeNumber > 0 }
            .sorted { $0.episodeNumber < $1.episodeNumber }

        let finaleEpisodeNumber = finaleEpisode?.episodeNumber ?? sortedEpisodes.last?.episodeNumber

        let displayEpisodes = sortedEpisodes.map { episode in
            episode.toDisplayModel(
                isWatched: watchedEpisodes.contains(episode.episodeNumber),
                isFinale: episode.episodeNumber == finaleEpisodeNumber
            )
        }

        return SeasonDisplayModel(
            id: "\(id)",
            number: seasonNumber,
            name: name,
            episodes: displayEpisodes,
            isCurrent: isCurrent,
            airDate: airDate
        )
    }
}

// MARK: - ShowData Extensions (deprecated - use SeasonDisplayModel(from: Season) instead)
// These extensions are kept for backwards compatibility but should not be used.
// Watch state is now read from Episode.hasWatched on the SwiftData model.
