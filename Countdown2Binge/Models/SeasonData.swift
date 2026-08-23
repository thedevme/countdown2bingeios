//
//  SeasonData.swift
//  Countdown2Binge
//
//  Domain model for a TV season.
//

import Foundation

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

    /// Finale episode - explicitly marked as finale type, or last episode by number
    var finaleEpisode: EpisodeData? {
        // First try to find explicitly marked finale
        if let finale = episodes.first(where: { $0.episodeType == .finale }) {
            return finale
        }
        // Fallback to last episode by episode number
        return episodes
            .filter { $0.episodeNumber > 0 }
            .max(by: { $0.episodeNumber < $1.episodeNumber })
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

    // MARK: - BingeEngine Bridge

    /// Episode facts for BingeEngine (DTO → engine bridge)
    var episodeFacts: [BingeEngine.EpisodeFact] {
        episodes.map { ep in
            BingeEngine.EpisodeFact(
                episodeNumber: ep.episodeNumber,
                airDate: ep.airDate,
                isTypedFinale: ep.episodeType == .finale,
                isTyped: ep.episodeType != .standard
            )
        }
    }

    /// Date-axis: season is complete + past grace window (delegates to BingeEngine)
    var isBingeReadyByDate: Bool {
        BingeEngine.isSeasonBingeReadyByDate(episodes: episodeFacts)
    }

    /// Has anything real behind it — episodes, or at least an air date.
    /// False for TMDB's placeholder for an ordered-but-unannounced season.
    /// (Pure delegation to BingeEngine — same rule the Series model uses.)
    var hasPublishedData: Bool {
        BingeEngine.hasPublishedData(episodes: episodeFacts, airDate: airDate)
    }

    /// For unfollowed shows, isBingeReady = date-axis only (no user watch state)
    var isBingeReady: Bool {
        isBingeReadyByDate
    }
}
