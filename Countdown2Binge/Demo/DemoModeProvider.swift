//
//  DemoModeProvider.swift
//  Countdown2Binge
//
//  Provides mock TV show data for App Store demo videos.
//  Shake device to toggle demo mode on/off.
//

import Foundation
import SwiftUI

/// Manages demo mode state and provides mock show data
/// Note: Demo mode is only available in DEBUG builds
final class DemoModeProvider {
    static let shared = DemoModeProvider()

    /// Whether demo mode is active (always false in release builds)
    #if DEBUG
    private(set) var isEnabled: Bool = false
    #else
    let isEnabled: Bool = false
    #endif

    private init() {
        // Initialize demo shows
        _demoShows = DemoModeProvider.createDemoShows()
    }

    /// Toggle demo mode on/off (no-op in release builds)
    func toggle() {
        #if DEBUG
        isEnabled.toggle()
        if isEnabled {
            // Haptic feedback when enabling
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        #endif
    }

    // MARK: - Demo Show Image Names (from asset catalog)

    enum DemoShowImage: String, CaseIterable {
        case theLastEmber = "the-last-ember"
        case midnightProtocol = "midnight-protocol"
        case harborHeights = "harbor-heights"
        case deadSignal = "dead-signal"
        case bakersDdozen = "bakers-dozen"
        case sovereign = "sovereign"
    }

    // MARK: - Demo Shows

    private let _demoShows: [Show]

    /// All demo shows for search results
    var demoShows: [Show] { _demoShows }

    private static func createDemoShows() -> [Show] {
        [
        // ENDING SOON (Airing)
        makeShow(
            id: 900001,
            name: "The Last Ember",
            overview: "A kingdom on the brink of collapse fights to preserve the last source of magic in a world turning to ash.",
            posterImage: .theLastEmber,
            status: .returning,
            genres: [Genre(id: 1, name: "Fantasy"), Genre(id: 2, name: "Drama")],
            seasons: [
                makeSeason(number: 1, episodeCount: 10, isComplete: true),
                makeSeason(number: 2, episodeCount: 10, isComplete: true),
                makeSeason(number: 3, episodeCount: 10, isComplete: true),
                makeAiringSeason(number: 4, episodeCount: 10, airedEpisodes: 7, nextAirDate: makeDate(month: 1, day: 19))
            ]
        ),
        makeShow(
            id: 900002,
            name: "Midnight Protocol",
            overview: "A team of hackers discovers a conspiracy that threatens to unravel the fabric of the digital world.",
            posterImage: .midnightProtocol,
            status: .returning,
            genres: [Genre(id: 3, name: "Sci-Fi"), Genre(id: 4, name: "Thriller")],
            seasons: [
                makeSeason(number: 1, episodeCount: 8, isComplete: true),
                makeAiringSeason(number: 2, episodeCount: 8, airedEpisodes: 6, nextAirDate: makeDate(month: 1, day: 16))
            ]
        ),

        // PREMIERING SOON
        makeShow(
            id: 900003,
            name: "Harbor Heights",
            overview: "Secrets and scandals collide in an affluent coastal town where everyone has something to hide.",
            posterImage: .harborHeights,
            status: .returning,
            genres: [Genre(id: 2, name: "Drama")],
            seasons: [
                makeUpcomingSeason(number: 1, episodeCount: 10, premiereDate: makeDate(month: 2, day: 2))
            ]
        ),
        makeShow(
            id: 900004,
            name: "Dead Signal",
            overview: "A small town radio station begins receiving mysterious broadcasts from beyond the grave.",
            posterImage: .deadSignal,
            status: .returning,
            genres: [Genre(id: 5, name: "Horror")],
            seasons: [
                makeUpcomingSeason(number: 1, episodeCount: 6, premiereDate: makeDate(month: 1, day: 31))
            ]
        ),

        // ANTICIPATED (TBD)
        makeShow(
            id: 900005,
            name: "The Baker's Dozen",
            overview: "A chaotic family of thirteen navigates life, love, and an inherited bakery in Brooklyn.",
            posterImage: .bakersDdozen,
            status: .returning,
            genres: [Genre(id: 6, name: "Comedy")],
            seasons: [
                makeSeason(number: 1, episodeCount: 12, isComplete: true),
                makeSeason(number: 2, episodeCount: 12, isComplete: true),
                makeAnnouncedSeason(number: 3)
            ]
        ),
        makeShow(
            id: 900006,
            name: "Sovereign",
            overview: "A newly elected president uncovers a shadow government that has controlled the nation for decades.",
            posterImage: .sovereign,
            status: .returning,
            genres: [Genre(id: 4, name: "Thriller"), Genre(id: 7, name: "Political")],
            seasons: [
                makeSeason(number: 1, episodeCount: 8, isComplete: true),
                makeSeason(number: 2, episodeCount: 8, isComplete: true),
                makeSeason(number: 3, episodeCount: 8, isComplete: true),
                makeAnnouncedSeason(number: 4)
            ]
        )
        ]
    }

    /// Demo shows as TMDBShowSummary for search results
    var demoSearchResults: [TMDBShowSummary] {
        demoShows.map { show in
            TMDBShowSummary(
                id: show.id,
                name: show.name,
                overview: show.overview,
                posterPath: show.posterPath, // Use demo:// path for local images
                backdropPath: nil,
                firstAirDate: nil,
                voteAverage: 8.5,
                genreIds: show.genres.map { $0.id }
            )
        }
    }

    // MARK: - Helper Methods

    private static func makeShow(
        id: Int,
        name: String,
        overview: String,
        posterImage: DemoShowImage,
        status: ShowStatus,
        genres: [Genre],
        seasons: [Season]
    ) -> Show {
        Show(
            id: id,
            name: name,
            overview: overview,
            posterPath: "demo://\(posterImage.rawValue)", // Special URL scheme for demo images
            backdropPath: "demo://\(posterImage.rawValue)",
            logoPath: nil,
            firstAirDate: nil,
            status: status,
            genres: genres,
            networks: [Network(id: 1, name: "StreamTV", logoPath: nil)],
            seasons: seasons,
            numberOfSeasons: seasons.count,
            numberOfEpisodes: seasons.reduce(0) { $0 + $1.episodeCount },
            inProduction: true
        )
    }

    private static func makeSeason(number: Int, episodeCount: Int, isComplete: Bool) -> Season {
        let pastDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!

        let episodes = (1...episodeCount).map { epNum in
            Episode(
                id: number * 1000 + epNum,
                episodeNumber: epNum,
                seasonNumber: number,
                name: "Episode \(epNum)",
                overview: nil,
                airDate: pastDate,
                stillPath: nil,
                runtime: 45
            )
        }

        return Season(
            id: number * 100,
            seasonNumber: number,
            name: "Season \(number)",
            overview: nil,
            posterPath: nil,
            airDate: pastDate,
            episodeCount: episodeCount,
            episodes: episodes
        )
    }

    private static func makeAiringSeason(number: Int, episodeCount: Int, airedEpisodes: Int, nextAirDate: Date) -> Season {
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        let episodes = (1...episodeCount).map { epNum in
            let airDate = epNum <= airedEpisodes ? pastDate : Calendar.current.date(byAdding: .day, value: (epNum - airedEpisodes) * 7, to: nextAirDate)!
            return Episode(
                id: number * 1000 + epNum,
                episodeNumber: epNum,
                seasonNumber: number,
                name: "Episode \(epNum)",
                overview: nil,
                airDate: airDate,
                stillPath: nil,
                runtime: 45
            )
        }

        return Season(
            id: number * 100,
            seasonNumber: number,
            name: "Season \(number)",
            overview: nil,
            posterPath: nil,
            airDate: pastDate,
            episodeCount: episodeCount,
            episodes: episodes
        )
    }

    private static func makeUpcomingSeason(number: Int, episodeCount: Int, premiereDate: Date) -> Season {
        let episodes = (1...episodeCount).map { epNum in
            let airDate = Calendar.current.date(byAdding: .day, value: (epNum - 1) * 7, to: premiereDate)!
            return Episode(
                id: number * 1000 + epNum,
                episodeNumber: epNum,
                seasonNumber: number,
                name: "Episode \(epNum)",
                overview: nil,
                airDate: airDate,
                stillPath: nil,
                runtime: 45
            )
        }

        return Season(
            id: number * 100,
            seasonNumber: number,
            name: "Season \(number)",
            overview: nil,
            posterPath: nil,
            airDate: premiereDate,
            episodeCount: episodeCount,
            episodes: episodes
        )
    }

    private static func makeAnnouncedSeason(number: Int) -> Season {
        Season(
            id: number * 100,
            seasonNumber: number,
            name: "Season \(number)",
            overview: nil,
            posterPath: nil,
            airDate: nil,
            episodeCount: 0,
            episodes: []
        )
    }

    private static func makeDate(month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Get Demo Show by ID

    func demoShow(for id: Int) -> Show? {
        demoShows.first { $0.id == id }
    }

    /// Get demo image name from poster path
    static func demoImageName(from posterPath: String?) -> String? {
        guard let path = posterPath, path.hasPrefix("demo://") else { return nil }
        return String(path.dropFirst("demo://".count))
    }
}
