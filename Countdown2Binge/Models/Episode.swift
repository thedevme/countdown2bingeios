//
//  Episode.swift
//  Countdown2Binge
//

import Foundation

/// Represents a single episode of a TV show.
struct Episode: Identifiable, Codable, Equatable {
    let id: Int
    let episodeNumber: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let airDate: Date?
    let stillPath: String?
    let runtime: Int?

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
}
