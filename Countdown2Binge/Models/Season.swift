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

    /// The finale episode (last episode of the season)
    var finale: Episode? {
        episodes.max(by: { $0.episodeNumber < $1.episodeNumber })
    }

    /// Date when the season finale airs
    var finaleDate: Date? {
        finale?.airDate
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

    /// Days until the finale airs (nil if complete or no date)
    var daysUntilFinale: Int? {
        guard let finaleDate, !isComplete else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let finale = calendar.startOfDay(for: finaleDate)
        return calendar.dateComponents([.day], from: today, to: finale).day
    }

    /// Days until the season premiere (nil if already started or no date)
    var daysUntilPremiere: Int? {
        guard let airDate, !hasStarted else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let premiere = calendar.startOfDay(for: airDate)
        return calendar.dateComponents([.day], from: today, to: premiere).day
    }

    /// Number of episodes that have aired
    var airedEpisodeCount: Int {
        episodes.filter { $0.hasAired }.count
    }

    /// Number of episodes that have been watched
    var watchedEpisodeCount: Int {
        episodes.filter { $0.isWatched }.count
    }

    /// Whether all aired episodes have been watched
    var allAiredEpisodesWatched: Bool {
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
