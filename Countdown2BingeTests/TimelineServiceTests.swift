//
//  TimelineServiceTests.swift
//  Countdown2BingeTests
//
//  Tests for timeline grouping and countdown calculations.
//

import Testing
import Foundation
@testable import Countdown2Binge

@Suite("Timeline Service Tests")
struct TimelineServiceTests {

    let service = TimelineService()

    // MARK: - Category Tests

    @Test("Completed show is categorized as Binge Ready")
    func completedShow_isBingeReady() {
        let show = makeShow(status: .ended, seasonComplete: true)
        #expect(service.categorize(show) == .bingeReady)
    }

    @Test("Cancelled show is categorized as Binge Ready")
    func cancelledShow_isBingeReady() {
        let show = makeShow(status: .cancelled, seasonComplete: false)
        #expect(service.categorize(show) == .bingeReady)
    }

    @Test("Airing show is categorized as Airing Now")
    func airingShow_isAiringNow() {
        let show = makeShow(status: .returning, seasonComplete: false, hasAiredEpisodes: true)
        #expect(service.categorize(show) == .airingNow)
    }

    @Test("Show with upcoming premiere is categorized as Premiering Soon")
    func showWithPremiere_isPremieringSoon() {
        let show = makeShow(status: .returning, seasonComplete: false, hasFuturePremiere: true)
        #expect(service.categorize(show) == .premieringSoon)
    }

    @Test("Show with no season is categorized as Anticipated")
    func showWithNoSeason_isAnticipated() {
        let show = makeShowWithNoSeasons()
        #expect(service.categorize(show) == .anticipated)
    }

    @Test("Show with no premiere date is categorized as Anticipated")
    func showWithNoPremiere_isAnticipated() {
        let show = makeShow(status: .inProduction, seasonComplete: false, hasNoDates: true)
        #expect(service.categorize(show) == .anticipated)
    }

    // MARK: - Countdown Tests

    @Test("Airing show has countdown to finale")
    func airingShow_hasFinaleCountdown() {
        let show = makeShow(status: .returning, seasonComplete: false, hasAiredEpisodes: true, daysToFinale: 14)
        let entry = service.createEntry(for: show)

        #expect(entry.countdown != nil)
        #expect(entry.countdown?.type == .toFinale)
        // Allow for day boundary variations in date calculation
        #expect((entry.countdown?.days ?? -1) >= 13 && (entry.countdown?.days ?? -1) <= 14)
    }

    @Test("Premiering Soon show has countdown to premiere")
    func premieringShow_hasPremiereCountdown() {
        let show = makeShow(status: .returning, seasonComplete: false, hasFuturePremiere: true, daysToPremiere: 7)
        let entry = service.createEntry(for: show)

        #expect(entry.countdown != nil)
        #expect(entry.countdown?.type == .toPremiere)
        // Allow for day boundary variations in date calculation
        #expect((entry.countdown?.days ?? -1) >= 6 && (entry.countdown?.days ?? -1) <= 7)
    }

    @Test("Binge Ready show has no countdown")
    func bingeReadyShow_hasNoCountdown() {
        let show = makeShow(status: .ended, seasonComplete: true)
        let entry = service.createEntry(for: show)

        #expect(entry.countdown == nil)
    }

    @Test("Anticipated show has no countdown")
    func anticipatedShow_hasNoCountdown() {
        let show = makeShowWithNoSeasons()
        let entry = service.createEntry(for: show)

        #expect(entry.countdown == nil)
    }

    // MARK: - Countdown Description Tests

    @Test("Countdown description is singular for 1 day")
    func countdownDescription_singular() {
        let countdown = CountdownInfo(type: .toFinale, days: 1, targetDate: Date())
        #expect(countdown.description == "Finale in 1 day")

        let premiereCountdown = CountdownInfo(type: .toPremiere, days: 1, targetDate: Date())
        #expect(premiereCountdown.description == "Premieres in 1 day")
    }

    @Test("Countdown description is plural for multiple days")
    func countdownDescription_plural() {
        let countdown = CountdownInfo(type: .toFinale, days: 5, targetDate: Date())
        #expect(countdown.description == "Finale in 5 days")

        let premiereCountdown = CountdownInfo(type: .toPremiere, days: 10, targetDate: Date())
        #expect(premiereCountdown.description == "Premieres in 10 days")
    }

    // MARK: - Grouping Tests

    @Test("Shows are grouped by category")
    func showsAreGroupedByCategory() {
        let bingeReady = makeShow(id: 1, name: "Completed Show", status: .ended, seasonComplete: true)
        let airing = makeShow(id: 2, name: "Airing Show", status: .returning, seasonComplete: false, hasAiredEpisodes: true)
        let premiering = makeShow(id: 3, name: "Upcoming Show", status: .returning, seasonComplete: false, hasFuturePremiere: true)
        let anticipated = makeShowWithNoSeasons(id: 4, name: "TBD Show")

        let grouped = service.groupByCategory([bingeReady, airing, premiering, anticipated])

        #expect(grouped[.bingeReady]?.count == 1)
        #expect(grouped[.airingNow]?.count == 1)
        #expect(grouped[.premieringSoon]?.count == 1)
        #expect(grouped[.anticipated]?.count == 1)
    }

    @Test("Empty groups are not included in sorted output")
    func emptyGroupsNotInOutput() {
        let bingeReady = makeShow(status: .ended, seasonComplete: true)
        let grouped = service.groupByCategory([bingeReady])
        let sorted = service.sortedCategories(from: grouped)

        #expect(sorted.count == 1)
        #expect(sorted[0].category == .bingeReady)
    }

    @Test("Categories are sorted by display order")
    func categoriesSortedByDisplayOrder() {
        let anticipated = makeShowWithNoSeasons(id: 1, name: "TBD")
        let bingeReady = makeShow(id: 2, name: "Done", status: .ended, seasonComplete: true)
        let airing = makeShow(id: 3, name: "Current", status: .returning, seasonComplete: false, hasAiredEpisodes: true)

        let grouped = service.groupByCategory([anticipated, bingeReady, airing])
        let sorted = service.sortedCategories(from: grouped)

        #expect(sorted[0].category == .bingeReady)
        #expect(sorted[1].category == .airingNow)
        #expect(sorted[2].category == .anticipated)
    }

    // MARK: - Sorting Within Category Tests

    @Test("Airing shows sorted by finale date")
    func airingShowsSortedByFinale() {
        let show1 = makeShow(id: 1, name: "Later", status: .returning, seasonComplete: false, hasAiredEpisodes: true, daysToFinale: 30)
        let show2 = makeShow(id: 2, name: "Sooner", status: .returning, seasonComplete: false, hasAiredEpisodes: true, daysToFinale: 7)

        let grouped = service.groupByCategory([show1, show2])
        let entries = grouped[.airingNow]!

        #expect(entries[0].show.name == "Sooner")
        #expect(entries[1].show.name == "Later")
    }

    @Test("Premiering shows sorted by premiere date")
    func premieringShowsSortedByPremiere() {
        let show1 = makeShow(id: 1, name: "Later", status: .returning, seasonComplete: false, hasFuturePremiere: true, daysToPremiere: 60)
        let show2 = makeShow(id: 2, name: "Sooner", status: .returning, seasonComplete: false, hasFuturePremiere: true, daysToPremiere: 14)

        let grouped = service.groupByCategory([show1, show2])
        let entries = grouped[.premieringSoon]!

        #expect(entries[0].show.name == "Sooner")
        #expect(entries[1].show.name == "Later")
    }

    @Test("Binge Ready shows sorted alphabetically")
    func bingeReadyShowsSortedAlphabetically() {
        let show1 = makeShow(id: 1, name: "Zebra", status: .ended, seasonComplete: true)
        let show2 = makeShow(id: 2, name: "Apple", status: .ended, seasonComplete: true)

        let grouped = service.groupByCategory([show1, show2])
        let entries = grouped[.bingeReady]!

        #expect(entries[0].show.name == "Apple")
        #expect(entries[1].show.name == "Zebra")
    }
}

// MARK: - Test Helpers

extension TimelineServiceTests {

    func makeShow(
        id: Int = 1,
        name: String = "Test Show",
        status: ShowStatus = .returning,
        seasonComplete: Bool = false,
        hasAiredEpisodes: Bool = false,
        hasFuturePremiere: Bool = false,
        hasNoDates: Bool = false,
        daysToFinale: Int? = nil,
        daysToPremiere: Int? = nil
    ) -> Show {
        let now = Date()
        let calendar = Calendar.current

        // Determine episode air dates based on test scenario
        let episodes: [Episode]
        let seasonAirDate: Date?

        if hasNoDates {
            // No dates scenario
            episodes = []
            seasonAirDate = nil
        } else if hasFuturePremiere {
            // Future premiere - all episodes in future
            let premiereDate = calendar.date(byAdding: .day, value: daysToPremiere ?? 30, to: now)!
            seasonAirDate = premiereDate
            episodes = (1...10).map { num in
                Episode(
                    id: num,
                    episodeNumber: num,
                    seasonNumber: 1,
                    name: "Episode \(num)",
                    overview: nil,
                    airDate: calendar.date(byAdding: .day, value: (daysToPremiere ?? 30) + (num * 7), to: now),
                    stillPath: nil,
                    runtime: 45
                )
            }
        } else if seasonComplete {
            // All episodes aired
            let pastDate = calendar.date(byAdding: .day, value: -90, to: now)!
            seasonAirDate = pastDate
            episodes = (1...10).map { num in
                Episode(
                    id: num,
                    episodeNumber: num,
                    seasonNumber: 1,
                    name: "Episode \(num)",
                    overview: nil,
                    airDate: calendar.date(byAdding: .day, value: -90 + (num * 7), to: now),
                    stillPath: nil,
                    runtime: 45
                )
            }
        } else if hasAiredEpisodes {
            // Some episodes aired, finale in future
            let pastDate = calendar.date(byAdding: .day, value: -30, to: now)!
            seasonAirDate = pastDate
            let finaleOffset = daysToFinale ?? 14
            episodes = (1...10).map { num in
                let airDate: Date?
                if num <= 5 {
                    // First 5 episodes have aired
                    airDate = calendar.date(byAdding: .day, value: -30 + (num * 7), to: now)
                } else {
                    // Remaining episodes in future, finale at specified offset
                    let daysFromNow = (num - 5) * 7 - 7 + finaleOffset - 28
                    airDate = calendar.date(byAdding: .day, value: num == 10 ? finaleOffset : daysFromNow, to: now)
                }
                return Episode(
                    id: num,
                    episodeNumber: num,
                    seasonNumber: 1,
                    name: "Episode \(num)",
                    overview: nil,
                    airDate: airDate,
                    stillPath: nil,
                    runtime: 45
                )
            }
        } else {
            // Default: all future
            let futureDate = calendar.date(byAdding: .day, value: 30, to: now)!
            seasonAirDate = futureDate
            episodes = (1...10).map { num in
                Episode(
                    id: num,
                    episodeNumber: num,
                    seasonNumber: 1,
                    name: "Episode \(num)",
                    overview: nil,
                    airDate: calendar.date(byAdding: .day, value: 30 + (num * 7), to: now),
                    stillPath: nil,
                    runtime: 45
                )
            }
        }

        let season = Season(
            id: 100,
            seasonNumber: 1,
            name: "Season 1",
            overview: nil,
            posterPath: nil,
            airDate: seasonAirDate,
            episodeCount: episodes.count,
            episodes: episodes
        )

        return Show(
            id: id,
            name: name,
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            firstAirDate: seasonAirDate,
            status: status,
            genres: [],
            networks: [],
            seasons: [season],
            numberOfSeasons: 1,
            numberOfEpisodes: episodes.count,
            inProduction: status == .returning || status == .inProduction
        )
    }

    func makeShowWithNoSeasons(id: Int = 1, name: String = "TBD Show") -> Show {
        Show(
            id: id,
            name: name,
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            firstAirDate: nil,
            status: .planned,
            genres: [],
            networks: [],
            seasons: [],
            numberOfSeasons: 0,
            numberOfEpisodes: 0,
            inProduction: false
        )
    }
}
