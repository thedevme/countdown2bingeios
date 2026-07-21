//
//  CachedDiscoverShow.swift
//  Countdown2Binge
//
//  SwiftData model for caching Discover shows.
//  Refreshed weekly to minimize API calls.
//

import Foundation
import SwiftData

@Model
final class CachedDiscoverShow {
    // MARK: - Show Data
    @Attribute(.unique) var tmdbId: Int
    var name: String
    var overview: String?
    var posterPath: String?
    var backdropPath: String?
    var firstAirDate: Date?
    var voteAverage: Double

    // MARK: - Details (fetched once)
    var episodeCount: Int
    var seasonCount: Int

    // MARK: - Network Info
    var networkId: Int
    var networkName: String
    var networkColor: String

    // MARK: - Cache Metadata
    var dateBucket: String  // "availableNow", "thisWeek", "thisMonth", "nextFewMonths", "laterThisYear"
    var cachedAt: Date

    init(
        tmdbId: Int,
        name: String,
        overview: String?,
        posterPath: String?,
        backdropPath: String?,
        firstAirDate: Date?,
        voteAverage: Double,
        episodeCount: Int,
        seasonCount: Int,
        networkId: Int,
        networkName: String,
        networkColor: String,
        dateBucket: String,
        cachedAt: Date = Date()
    ) {
        self.tmdbId = tmdbId
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.firstAirDate = firstAirDate
        self.voteAverage = voteAverage
        self.episodeCount = episodeCount
        self.seasonCount = seasonCount
        self.networkId = networkId
        self.networkName = networkName
        self.networkColor = networkColor
        self.dateBucket = dateBucket
        self.cachedAt = cachedAt
    }

    // MARK: - Computed Properties

    /// Days until premiere (negative if already aired)
    var daysUntilPremiere: Int? {
        guard let date = firstAirDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }

    /// Current bucket based on days until premiere
    var currentBucket: DiscoverBucket {
        guard let days = daysUntilPremiere else { return .availableNow }

        switch days {
        case ...0: return .availableNow
        case 1...7: return .thisWeek
        case 8...31: return .thisMonth
        case 32...90: return .nextFewMonths
        default: return .laterThisYear
        }
    }
}

// MARK: - Date Buckets

enum DiscoverBucket: String, CaseIterable {
    case availableNow = "availableNow"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case nextFewMonths = "nextFewMonths"
    case laterThisYear = "laterThisYear"

    var displayTitle: String {
        switch self {
        case .availableNow: return "AVAILABLE NOW"
        case .thisWeek: return "THIS WEEK"
        case .thisMonth: return "THIS MONTH"
        case .nextFewMonths: return "NEXT FEW MONTHS"
        case .laterThisYear: return "LATER THIS YEAR"
        }
    }

    /// Date range for this bucket relative to today
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch self {
        case .availableNow:
            let distantPast = calendar.date(byAdding: .year, value: -10, to: today)!
            return (distantPast, today)
        case .thisWeek:
            let start = calendar.date(byAdding: .day, value: 1, to: today)!
            let end = calendar.date(byAdding: .day, value: 7, to: today)!
            return (start, end)
        case .thisMonth:
            let start = calendar.date(byAdding: .day, value: 8, to: today)!
            let end = calendar.date(byAdding: .day, value: 31, to: today)!
            return (start, end)
        case .nextFewMonths:
            let start = calendar.date(byAdding: .day, value: 32, to: today)!
            let end = calendar.date(byAdding: .day, value: 90, to: today)!
            return (start, end)
        case .laterThisYear:
            let start = calendar.date(byAdding: .day, value: 91, to: today)!
            let end = calendar.date(byAdding: .year, value: 1, to: today)!
            return (start, end)
        }
    }
}
