//
//  Season.swift
//  Countdown2Binge
//

import Foundation

/// Represents a season of a TV show.
struct Season: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let airDate: Date?
    let episodeCount: Int
    var episodes: [Episode]

    /// Date when user marked this season as watched (nil = not watched)
    var watchedDate: Date?

    /// Whether this season has been marked as watched
    var isWatched: Bool {
        watchedDate != nil
    }

    /// The last episode in the list (may not be the actual finale)
    var lastEpisode: Episode? {
        episodes.max(by: { $0.episodeNumber < $1.episodeNumber })
    }

    /// Whether TMDB has added episode types (any non-standard type found)
    private var hasEpisodeTypes: Bool {
        episodes.contains { $0.episodeType != .standard }
    }

    /// The finale episode
    var finale: Episode? {
        guard let last = lastEpisode else { return nil }
        // If explicitly marked as finale, use it
        if last.episodeType.isFinale { return last }
        // If TMDB has typed episodes but last isn't finale, no finale known yet
        if hasEpisodeTypes { return nil }
        // Legacy fallback: no episode types in data, use last episode
        return last
    }

    /// Date when the season finale airs (nil if finale not confirmed)
    var finaleDate: Date? {
        finale?.airDate
    }

    /// Whether the finale date is known (either marked or season complete)
    var hasConfirmedFinale: Bool {
        finale != nil
    }

    /// Whether all episodes have aired
    var isComplete: Bool {
        guard !episodes.isEmpty else { return false }
        return episodes.allSatisfy { $0.hasAired }
    }

    /// Whether the season has started airing
    var hasStarted: Bool {
        guard let airDate else { return false }
        return airDate <= Date()
    }

    /// Whether season is currently airing (started but not complete)
    var isAiring: Bool {
        hasStarted && !isComplete
    }

    /// Whether today is the finale day
    var isFinaleDay: Bool {
        guard let finaleDate else { return false }
        return Calendar.current.isDateInToday(finaleDate)
    }

    /// Days until the finale airs (nil if finale has passed or no date)
    /// Returns 0 on the day of the finale (show stays visible until end of day)
    var daysUntilFinale: Int? {
        guard let finaleDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let finale = calendar.startOfDay(for: finaleDate)
        let days = calendar.dateComponents([.day], from: today, to: finale).day ?? 0
        // Return days if finale is today or in the future
        return days >= 0 ? days : nil
    }

    /// Days until the season premiere (nil if already started or no date)
    var daysUntilPremiere: Int? {
        guard let airDate, !hasStarted else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let premiere = calendar.startOfDay(for: airDate)
        return calendar.dateComponents([.day], from: today, to: premiere).day
    }

    /// Episodes until the finale airs (nil if complete or no finale)
    var episodesUntilFinale: Int? {
        guard let finale, !isComplete else { return nil }
        let finaleNumber = finale.episodeNumber
        let lastAiredNumber = episodes.filter { $0.hasAired }.map { $0.episodeNumber }.max() ?? 0
        let remaining = finaleNumber - lastAiredNumber
        return remaining > 0 ? remaining : nil
    }

    /// Number of episodes that have aired
    var airedEpisodeCount: Int {
        episodes.filter { $0.hasAired }.count
    }

    /// Number of episodes that have been watched
    /// If season is marked watched, returns all aired episodes (or all episodes if complete)
    var watchedEpisodeCount: Int {
        // If season marked as watched, all aired episodes are considered watched
        if isWatched {
            return isComplete ? episodeCount : airedEpisodeCount
        }
        return episodes.filter { $0.isWatched }.count
    }

    /// Whether all aired episodes have been watched
    var allAiredEpisodesWatched: Bool {
        // If season is marked as watched, all aired episodes are considered watched
        if isWatched { return true }
        guard !episodes.isEmpty else { return false }
        let airedEpisodes = episodes.filter { $0.hasAired }
        guard !airedEpisodes.isEmpty else { return false }
        return airedEpisodes.allSatisfy { $0.isWatched }
    }

    /// Whether season is ready to binge (complete and not yet watched)
    var isBingeReady: Bool {
        isComplete && !isWatched
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
