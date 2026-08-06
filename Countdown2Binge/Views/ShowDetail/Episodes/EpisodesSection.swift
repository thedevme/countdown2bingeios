//
//  EpisodesSection.swift
//  Countdown2Binge
//
//  Main container for the episodes section of show detail.
//  Automatically shows the appropriate view based on season state:
//
//  - Schedule view: For airing shows (season not yet complete)
//  - Watched view: For complete seasons (all episodes released)
//

import SwiftUI

struct EpisodesSection: View {
    let season: SeasonDisplayModel
    let allSeasons: [SeasonDisplayModel]
    let showImageURL: URL?
    let synopsis: String
    let daysUntilReady: Int?
    let onToggleWatched: (EpisodeDisplayModel) -> Void
    let onMarkAllAired: () -> Void
    let onClearAll: () -> Void

    @State private var selectedEpisode: EpisodeDisplayModel?
    @State private var selectedPlanIndex: Int = 0
    @State private var selectedPace: Int = 1  // 1, 2, or 3 eps per day
    @State private var monthOffset: Int = 0
    @State private var showStartSelected: Bool = false

    /// True if season is still airing (show Schedule view)
    private var isAiring: Bool {
        season.needsScheduleMode
    }

    /// Prior seasons for the home stretch planner
    private var priorSeasons: [SeasonDisplayModel] {
        allSeasons.filter { !$0.isCurrent && $0.number < season.number }
    }

    /// Calculate weeks remaining until finale
    private var weeksRemaining: Int {
        guard let days = daysUntilReady, days > 0 else { return 1 }
        return max(1, Int(ceil(Double(days) / 7.0)))
    }

    /// Finale date (from the episode marked as finale)
    private var finaleDate: Date? {
        season.episodes.first { $0.isFinale }?.airDate ?? season.episodes.last?.airDate
    }

    /// All available binge plans for prior seasons
    private var availablePlans: [BingePlan] {
        guard !priorSeasons.isEmpty else { return [] }

        let sortedSeasons = priorSeasons.sorted { $0.number < $1.number }
        var plans: [BingePlan] = []

        for i in 0..<sortedSeasons.count {
            let seasonsToWatch = Array(sortedSeasons[i...])
            let totalEps = seasonsToWatch.reduce(0) { $0 + $1.totalEpisodes }
            let weeksLeft = max(1, weeksRemaining)
            let perWeek = Int(ceil(Double(totalEps) / Double(weeksLeft)))
            let perDay = Double(totalEps) / Double(weeksLeft * 7)

            plans.append(BingePlan(
                fromSeason: sortedSeasons[i].number,
                toSeason: sortedSeasons.last!.number,
                totalEpisodes: totalEps,
                episodesPerWeek: perWeek,
                episodesPerDay: (perDay * 10).rounded() / 10
            ))
        }

        return plans
    }

    /// Calculated start date based on selected plan and pace
    private var calculatedStartDate: Date? {
        guard selectedPlanIndex < availablePlans.count, let finale = finaleDate else { return nil }
        let totalEps = availablePlans[selectedPlanIndex].totalEpisodes
        let daysNeeded = Int(ceil(Double(totalEps) / Double(selectedPace)))
        return Calendar.current.date(byAdding: .day, value: -daysNeeded, to: finale)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Show appropriate view based on season state
            if isAiring {
                scheduleContent
            } else {
                watchedContent
            }
        }
    }

    // MARK: - Schedule Content

    private var scheduleContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Countdown header
            if let days = daysUntilReady, days > 0 {
                CountdownHeader(
                    daysRemaining: days,
                    finaleDate: finaleDate,
                    releasedCount: season.releasedCount,
                    totalEpisodes: season.totalEpisodes
                )
                .padding(.top, 22)
            }

            // Calendar
            EpisodeCalendar(
                season: season,
                startDate: calculatedStartDate,
                monthOffset: $monthOffset,
                selectedEpisode: $selectedEpisode,
                showStartSelected: $showStartSelected
            )
            .padding(.top, 22)

            // Episode detail panel (only when episode selected)
            if let episode = selectedEpisode {
                EpisodeDetailPanel(
                    episode: episode,
                    showImageURL: showImageURL,
                    isStartPlanSelected: false,
                    availablePlans: [],
                    finaleDate: finaleDate,
                    selectedPlanIndex: $selectedPlanIndex,
                    selectedPace: $selectedPace
                )
                .padding(.top, 14)
            }

            // Catch-up planner (always visible when prior seasons exist)
            if !availablePlans.isEmpty {
                CatchUpPanel(
                    availablePlans: availablePlans,
                    finaleDate: finaleDate,
                    selectedPlanIndex: $selectedPlanIndex,
                    selectedPace: $selectedPace
                )
                .padding(.top, 14)
            }

            // Legend
            CalendarLegend()
        }
    }

    // MARK: - Watched Content

    private var watchedContent: some View {
        EpisodeCarousel(
            season: season,
            showImageURL: showImageURL,
            synopsis: synopsis,
            onToggleWatched: onToggleWatched,
            onMarkAllAired: onMarkAllAired,
            onClearAll: onClearAll
        )
    }
}

// MARK: - Preview

private func makePreviewEpisodes() -> [EpisodeDisplayModel] {
    (1...8).map { num in
        let title = num <= 4 ? "Episode \(num) Title" : "Episode \(num)"
        let desc = num <= 4 ? "Description for episode \(num) with some details." : ""
        let airDate = Date().addingTimeInterval(Double((num - 5) * 7 * 86400))
        return EpisodeDisplayModel(
            id: "\(num)",
            number: num,
            seasonNumber: 2,
            title: title,
            description: desc,
            runtime: 45 + (num * 2),
            airDate: airDate,
            isWatched: num <= 2,
            hasAired: num <= 4,
            isFinale: num == 8
        )
    }
}

private func makeS1PreviewEpisodes() -> [EpisodeDisplayModel] {
    (1...9).map { num in
        EpisodeDisplayModel(
            id: "s1-\(num)",
            number: num,
            seasonNumber: 1,
            title: "Episode \(num)",
            description: "",
            runtime: 45,
            airDate: nil,
            isWatched: true,
            hasAired: true,
            isFinale: num == 9
        )
    }
}

#Preview("Airing Show - Schedule Mode") {
    let episodes = makePreviewEpisodes()
    let s1Episodes = makeS1PreviewEpisodes()

    let season = SeasonDisplayModel(
        id: "s2",
        number: 2,
        name: "Season 2",
        episodes: episodes,
        isCurrent: true,
        airDate: Date().addingTimeInterval(-28 * 86400)
    )

    let season1 = SeasonDisplayModel(
        id: "s1",
        number: 1,
        name: "Season 1",
        episodes: s1Episodes,
        isCurrent: false,
        airDate: nil
    )

    ScrollView {
        EpisodesSection(
            season: season,
            allSeasons: [season1, season],
            showImageURL: nil,
            synopsis: "Season 2 continues the story of Mark and his colleagues.",
            daysUntilReady: 28,
            onToggleWatched: { _ in },
            onMarkAllAired: {},
            onClearAll: {}
        )
        .padding(.horizontal, 22)
    }
    .background(Color.c2bBackground)
}

private func makeCompleteSeasonEpisodes() -> [EpisodeDisplayModel] {
    (1...10).map { num in
        let airDate = Date().addingTimeInterval(Double(-num * 7 * 86400))
        return EpisodeDisplayModel(
            id: "\(num)",
            number: num,
            seasonNumber: 1,
            title: "Episode \(num) - Full Title Here",
            description: "A detailed description of what happens in this episode.",
            runtime: 45 + (num % 3) * 5,
            airDate: airDate,
            isWatched: num <= 7,
            hasAired: true,
            isFinale: num == 10
        )
    }
}

#Preview("Complete Season - Watched Mode") {
    let episodes = makeCompleteSeasonEpisodes()

    let season = SeasonDisplayModel(
        id: "s1",
        number: 1,
        name: "Season 1",
        episodes: episodes,
        isCurrent: false,
        airDate: nil
    )

    ScrollView {
        EpisodesSection(
            season: season,
            allSeasons: [season],
            showImageURL: nil,
            synopsis: "The complete first season following the journey of our protagonists.",
            daysUntilReady: nil,
            onToggleWatched: { _ in },
            onMarkAllAired: {},
            onClearAll: {}
        )
        .padding(.horizontal, 22)
    }
    .background(Color.c2bBackground)
}
