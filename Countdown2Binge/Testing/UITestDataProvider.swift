//
//  UITestDataProvider.swift
//  Countdown2Binge
//
//  Provides mock data for UI testing scenarios.
//

import Foundation

/// Launch argument keys for UI testing
enum UITestLaunchArgument: String {
    case uiTesting = "-UITesting"
    case scenario = "-UITestScenario"
}

/// UI Test scenarios that can be triggered via launch arguments
enum UITestScenario: String {
    case noFollowedShows = "NoFollowedShows"
    case hasShowsButNoneActive = "HasShowsButNoneActive"
    case hasActiveShows = "HasActiveShows"
    case thePittScenario = "ThePittScenario"
    case airingOnlyNoBottomSections = "AiringOnlyNoBottomSections"
}

/// Provides mock data for UI testing
struct UITestDataProvider {

    /// Check if app is running in UI test mode
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains(UITestLaunchArgument.uiTesting.rawValue)
    }

    /// Get the current test scenario from launch arguments
    static var currentScenario: UITestScenario? {
        guard isUITesting else { return nil }

        let args = ProcessInfo.processInfo.arguments
        guard let scenarioIndex = args.firstIndex(of: UITestLaunchArgument.scenario.rawValue),
              scenarioIndex + 1 < args.count else {
            return nil
        }

        return UITestScenario(rawValue: args[scenarioIndex + 1])
    }

    // MARK: - Mock Data Generators

    /// Creates a mock show for testing
    static func makeMockShow(
        id: Int,
        name: String,
        status: ShowStatus,
        seasons: [Season]
    ) -> Show {
        Show(
            id: id,
            name: name,
            overview: "Test show for UI testing",
            posterPath: nil,
            backdropPath: nil,
            logoPath: nil,
            firstAirDate: nil,
            status: status,
            genres: [],
            networks: [],
            seasons: seasons,
            numberOfSeasons: seasons.count,
            numberOfEpisodes: seasons.reduce(0) { $0 + $1.episodeCount },
            inProduction: status == .returning || status == .inProduction
        )
    }

    /// Creates a mock season
    static func makeMockSeason(
        seasonNumber: Int,
        isComplete: Bool,
        hasStarted: Bool
    ) -> Season {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: now)!

        let airDate = hasStarted ? pastDate : futureDate

        let episodes: [Episode]
        if isComplete {
            episodes = (1...10).map { makeMockEpisode(episodeNumber: $0, seasonNumber: seasonNumber, airDate: pastDate) }
        } else if hasStarted {
            episodes = (1...10).map { makeMockEpisode(episodeNumber: $0, seasonNumber: seasonNumber, airDate: $0 <= 5 ? pastDate : futureDate) }
        } else {
            episodes = (1...10).map { makeMockEpisode(episodeNumber: $0, seasonNumber: seasonNumber, airDate: futureDate) }
        }

        return Season(
            id: seasonNumber * 100,
            seasonNumber: seasonNumber,
            name: "Season \(seasonNumber)",
            overview: nil,
            posterPath: nil,
            airDate: airDate,
            episodeCount: episodes.count,
            episodes: episodes
        )
    }

    /// Creates an announced season with no episodes
    static func makeMockAnnouncedSeason(seasonNumber: Int) -> Season {
        Season(
            id: seasonNumber * 100,
            seasonNumber: seasonNumber,
            name: "Season \(seasonNumber)",
            overview: nil,
            posterPath: nil,
            airDate: nil,
            episodeCount: 0,
            episodes: []
        )
    }

    /// Creates a mock episode
    static func makeMockEpisode(
        episodeNumber: Int,
        seasonNumber: Int,
        airDate: Date
    ) -> Episode {
        Episode(
            id: seasonNumber * 1000 + episodeNumber,
            episodeNumber: episodeNumber,
            seasonNumber: seasonNumber,
            name: "Episode \(episodeNumber)",
            overview: nil,
            airDate: airDate,
            stillPath: nil,
            runtime: 45
        )
    }

    // MARK: - Scenario Data

    /// Returns mock shows for the current test scenario
    static func showsForCurrentScenario() -> [Show] {
        guard let scenario = currentScenario else { return [] }

        switch scenario {
        case .noFollowedShows:
            return []

        case .hasShowsButNoneActive:
            // Shows that don't appear in timeline: ended, cancelled with all seasons complete
            return [
                makeMockShow(
                    id: 1,
                    name: "Ended Show",
                    status: .ended,
                    seasons: [makeMockSeason(seasonNumber: 1, isComplete: true, hasStarted: true)]
                )
            ]

        case .hasActiveShows:
            return [
                // Airing show - appears in Ending Soon
                makeMockShow(
                    id: 1,
                    name: "Currently Airing",
                    status: .returning,
                    seasons: [makeMockSeason(seasonNumber: 1, isComplete: false, hasStarted: true)]
                ),
                // Premiering soon show
                makeMockShow(
                    id: 2,
                    name: "Coming Soon",
                    status: .returning,
                    seasons: [
                        makeMockSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
                        makeMockSeason(seasonNumber: 2, isComplete: false, hasStarted: false)
                    ]
                ),
                // Anticipated show
                makeMockShow(
                    id: 3,
                    name: "Anticipated Show",
                    status: .returning,
                    seasons: [
                        makeMockSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
                        makeMockAnnouncedSeason(seasonNumber: 2)
                    ]
                )
            ]

        case .thePittScenario:
            // The Pitt: S1 complete, S2 airing, S3 announced
            return [
                makeMockShow(
                    id: 250307,
                    name: "The Pitt",
                    status: .returning,
                    seasons: [
                        makeMockSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
                        makeMockSeason(seasonNumber: 2, isComplete: false, hasStarted: true),
                        makeMockAnnouncedSeason(seasonNumber: 3)
                    ]
                )
            ]

        case .airingOnlyNoBottomSections:
            // Only an airing show - no premiering soon or anticipated
            // Tests that connector below countdown is hidden when no bottom sections
            return [
                makeMockShow(
                    id: 1,
                    name: "Airing Only Show",
                    status: .returning,
                    seasons: [makeMockSeason(seasonNumber: 1, isComplete: false, hasStarted: true)]
                )
            ]
        }
    }
}
