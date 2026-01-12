//
//  Episode.swift
//  Countdown2Binge
//

import Foundation

/// Represents a single episode of a TV show.
struct Episode: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let episodeNumber: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let airDate: Date?
    let stillPath: String?
    let runtime: Int?

    /// Date when user marked this episode as watched (nil = not watched)
    var watchedDate: Date?

    /// Whether this episode has been marked as watched
    var isWatched: Bool {
        watchedDate != nil
    }

    /// Whether this episode has already aired
    var hasAired: Bool {
        guard let airDate else { return false }
        return airDate <= Date()
    }

    /// Days until this episode airs (nil if already aired or no date)
    var daysUntilAir: Int? {
        guard let airDate, !hasAired else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: airDate).day
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
