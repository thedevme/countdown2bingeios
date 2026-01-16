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
    case hasBingeReadySeasons = "HasBingeReadySeasons"
    case noBingeReadySeasons = "NoBingeReadySeasons"
    case airingNoFinaleDate = "AiringNoFinaleDate"
    case finaleTypeButNoAirDate = "FinaleTypeButNoAirDate"
    case emptyEpisodesArray = "EmptyEpisodesArray"
    case finaleIsToday = "FinaleIsToday"
    case finaleInPast = "FinaleInPast"
    case finaleOver99Days = "FinaleOver99Days"
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
        airDate: Date,
        episodeType: EpisodeType = .standard
    ) -> Episode {
        var episode = Episode(
            id: seasonNumber * 1000 + episodeNumber,
            episodeNumber: episodeNumber,
            seasonNumber: seasonNumber,
            name: "Episode \(episodeNumber)",
            overview: nil,
            airDate: airDate,
            stillPath: nil,
            runtime: 45
        )
        episode.episodeType = episodeType
        return episode
    }

    /// Creates an episode with nil air date
    static func makeMockEpisodeNoAirDate(
        episodeNumber: Int,
        seasonNumber: Int,
        episodeType: EpisodeType = .standard
    ) -> Episode {
        var episode = Episode(
            id: seasonNumber * 1000 + episodeNumber,
            episodeNumber: episodeNumber,
            seasonNumber: seasonNumber,
            name: "Episode \(episodeNumber)",
            overview: nil,
            airDate: nil,  // No air date!
            stillPath: nil,
            runtime: 45
        )
        episode.episodeType = episodeType
        return episode
    }

    /// Creates a season where finale is marked but has no air date
    static func makeMockSeasonFinaleNoAirDate(seasonNumber: Int) -> Season {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!

        // Episodes 1-9 have aired, episode 10 is finale but no air date
        var episodes: [Episode] = []
        for i in 1...9 {
            episodes.append(makeMockEpisode(
                episodeNumber: i,
                seasonNumber: seasonNumber,
                airDate: pastDate,
                episodeType: .standard
            ))
        }
        // Finale episode with NO air date
        episodes.append(makeMockEpisodeNoAirDate(
            episodeNumber: 10,
            seasonNumber: seasonNumber,
            episodeType: .finale
        ))

        return Season(
            id: seasonNumber * 100,
            seasonNumber: seasonNumber,
            name: "Season \(seasonNumber)",
            overview: nil,
            posterPath: nil,
            airDate: pastDate,
            episodeCount: episodes.count,
            episodes: episodes
        )
    }

    /// Creates a season with no episodes (not yet loaded)
    static func makeMockSeasonNoEpisodes(seasonNumber: Int) -> Season {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!

        return Season(
            id: seasonNumber * 100,
            seasonNumber: seasonNumber,
            name: "Season \(seasonNumber)",
            overview: nil,
            posterPath: nil,
            airDate: pastDate,
            episodeCount: 10,  // Says 10 episodes but array is empty
            episodes: []
        )
    }

    /// Creates a season where finale is TODAY
    static func makeMockSeasonFinaleToday(seasonNumber: Int) -> Season {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let today = Calendar.current.startOfDay(for: now)

        var episodes: [Episode] = []
        for i in 1...9 {
            episodes.append(makeMockEpisode(
                episodeNumber: i,
                seasonNumber: seasonNumber,
                airDate: pastDate,
                episodeType: .standard
            ))
        }
        // Finale is TODAY
        episodes.append(makeMockEpisode(
            episodeNumber: 10,
            seasonNumber: seasonNumber,
            airDate: today,
            episodeType: .finale
        ))

        return Season(
            id: seasonNumber * 100,
            seasonNumber: seasonNumber,
            name: "Season \(seasonNumber)",
            overview: nil,
            posterPath: nil,
            airDate: pastDate,
            episodeCount: episodes.count,
            episodes: episodes
        )
    }

    /// Creates a season where finale was in the past (negative days)
    static func makeMockSeasonFinalePast(seasonNumber: Int) -> Season {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        var episodes: [Episode] = []
        for i in 1...10 {
            episodes.append(makeMockEpisode(
                episodeNumber: i,
                seasonNumber: seasonNumber,
                airDate: i < 10 ? pastDate : yesterday,
                episodeType: i == 10 ? .finale : .standard
            ))
        }

        return Season(
            id: seasonNumber * 100,
            seasonNumber: seasonNumber,
            name: "Season \(seasonNumber)",
            overview: nil,
            posterPath: nil,
            airDate: pastDate,
            episodeCount: episodes.count,
            episodes: episodes
        )
    }

    /// Creates a season where finale is > 99 days away
    static func makeMockSeasonFinaleFarFuture(seasonNumber: Int) -> Season {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let farFuture = Calendar.current.date(byAdding: .day, value: 150, to: now)!

        var episodes: [Episode] = []
        for i in 1...10 {
            let airDate = i <= 2 ? pastDate : farFuture
            episodes.append(makeMockEpisode(
                episodeNumber: i,
                seasonNumber: seasonNumber,
                airDate: airDate,
                episodeType: i == 10 ? .finale : .standard
            ))
        }

        return Season(
            id: seasonNumber * 100,
            seasonNumber: seasonNumber,
            name: "Season \(seasonNumber)",
            overview: nil,
            posterPath: nil,
            airDate: pastDate,
            episodeCount: episodes.count,
            episodes: episodes
        )
    }

    /// Creates an airing season with no confirmed finale (TBD countdown)
    static func makeMockSeasonNoFinale(seasonNumber: Int) -> Season {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: now)!

        // Create episodes where some have aired, some haven't
        // Use midSeason type on one episode so hasEpisodeTypes=true
        // But don't mark any as finale, so finale will be nil
        var episodes: [Episode] = []
        for i in 1...10 {
            let airDate = i <= 5 ? pastDate : futureDate
            let type: EpisodeType = i == 5 ? .midSeason : .standard
            episodes.append(makeMockEpisode(
                episodeNumber: i,
                seasonNumber: seasonNumber,
                airDate: airDate,
                episodeType: type
            ))
        }

        return Season(
            id: seasonNumber * 100,
            seasonNumber: seasonNumber,
            name: "Season \(seasonNumber)",
            overview: nil,
            posterPath: nil,
            airDate: pastDate,
            episodeCount: episodes.count,
            episodes: episodes
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

        case .hasBingeReadySeasons:
            // Shows with complete seasons ready to binge
            return [
                makeMockShow(
                    id: 1,
                    name: "Binge Ready Show",
                    status: .returning,
                    seasons: [
                        makeMockSeason(seasonNumber: 1, isComplete: true, hasStarted: true),
                        makeMockSeason(seasonNumber: 2, isComplete: true, hasStarted: true)
                    ]
                ),
                makeMockShow(
                    id: 2,
                    name: "Another Binge Show",
                    status: .returning,
                    seasons: [makeMockSeason(seasonNumber: 1, isComplete: true, hasStarted: true)]
                )
            ]

        case .noBingeReadySeasons:
            // No binge-ready seasons (all airing or incomplete)
            return [
                makeMockShow(
                    id: 1,
                    name: "Still Airing",
                    status: .returning,
                    seasons: [makeMockSeason(seasonNumber: 1, isComplete: false, hasStarted: true)]
                )
            ]

        case .airingNoFinaleDate:
            // Airing show where finale date is unknown (TBD countdown)
            // This tests the scenario where Season.finale returns nil
            // Example: SVU - has midSeason type but last ep not marked finale
            return [
                makeMockShow(
                    id: 1,
                    name: "The Rookie Test",
                    status: .returning,
                    seasons: [makeMockSeasonNoFinale(seasonNumber: 1)]
                )
            ]

        case .finaleTypeButNoAirDate:
            // Finale episode is marked but has nil air date
            // Example: Show announced finale but no date yet
            return [
                makeMockShow(
                    id: 1,
                    name: "Finale No Date Test",
                    status: .returning,
                    seasons: [makeMockSeasonFinaleNoAirDate(seasonNumber: 1)]
                )
            ]

        case .emptyEpisodesArray:
            // Season exists but episodes not loaded yet
            // Example: Freshly added show before TMDB data loads
            return [
                makeMockShow(
                    id: 1,
                    name: "Empty Episodes Test",
                    status: .returning,
                    seasons: [makeMockSeasonNoEpisodes(seasonNumber: 1)]
                )
            ]

        case .finaleIsToday:
            // Finale air date is TODAY (0 days countdown)
            return [
                makeMockShow(
                    id: 1,
                    name: "Finale Today Test",
                    status: .returning,
                    seasons: [makeMockSeasonFinaleToday(seasonNumber: 1)]
                )
            ]

        case .finaleInPast:
            // Finale air date was yesterday (negative days)
            // This can happen if data isn't refreshed after finale airs
            return [
                makeMockShow(
                    id: 1,
                    name: "Finale Past Test",
                    status: .returning,
                    seasons: [makeMockSeasonFinalePast(seasonNumber: 1)]
                )
            ]

        case .finaleOver99Days:
            // Finale is 150+ days away (exceeds 2-digit display)
            return [
                makeMockShow(
                    id: 1,
                    name: "Finale Far Future Test",
                    status: .returning,
                    seasons: [makeMockSeasonFinaleFarFuture(seasonNumber: 1)]
                )
            ]
        }
    }

    /// Returns binge-ready show groups for the current test scenario
    static func bingeReadyGroupsForCurrentScenario() -> [BingeReadyShowGroup] {
        let shows = showsForCurrentScenario()
        var groups: [BingeReadyShowGroup] = []

        for show in shows {
            let readySeasons = show.seasons.filter { season in
                season.seasonNumber > 0 && season.isComplete
            }
            if !readySeasons.isEmpty {
                groups.append(BingeReadyShowGroup(show: show, seasons: readySeasons))
            }
        }

        return groups
    }
}
