//
//  ShowSummary.swift
//  Countdown2Binge
//
//  Lightweight show data for search results and lists.
//

import Foundation

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
    nonisolated func toShowSummary() -> ShowSummary {
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
