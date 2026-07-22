//
//  FranchiseModels.swift
//  Countdown2Binge
//
//  Models for franchise/spinoff data from Firebase.
//

import Foundation

/// A franchise containing a parent show and its spinoffs
struct Franchise: Identifiable, Codable {
    let id: String
    let franchiseName: [String: String]  // Localized names: ["en": "Breaking Bad Universe", "es": "..."]
    let origin: String
    let parentShow: FranchiseShow
    let spinoffs: [SpinoffShow]
    let watchOrder: WatchOrder?

    /// Get localized franchise name
    func localizedName(for locale: String = "en") -> String {
        franchiseName[locale] ?? franchiseName["en"] ?? id
    }

    /// All TMDB IDs in this franchise (parent + spinoffs)
    var allTmdbIds: [Int] {
        [parentShow.tmdbId] + spinoffs.map { $0.tmdbId }
    }
}

/// A show within a franchise (parent or spinoff)
struct FranchiseShow: Codable {
    let title: String
    let tmdbId: Int
    let years: String
}

/// A spinoff show with additional metadata
struct SpinoffShow: Codable {
    let title: String
    let tmdbId: Int
    let years: String
    let type: SpinoffType
    let status: SpinoffStatus

    enum SpinoffType: String, Codable {
        case prequel
        case sequel
        case companion
        case remake
        case spinoff
    }

    enum SpinoffStatus: String, Codable {
        case ended
        case returning
        case upcoming
        case inProduction = "in_production"
    }
}

/// Watch order options for a franchise
struct WatchOrder: Codable {
    let release: [String]
    let chronological: [String]
}
