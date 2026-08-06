//
//  DetailCatchUpSection.swift
//  Countdown2Binge
//
//  Full calendar and catch-up planning section for followed show detail.
//  Shows: CountdownHeader, EpisodeCalendar, CatchUpPanel, CalendarLegend
//

import SwiftUI

struct DetailCatchUpSection: View {
    let series: Series
    @State private var selectedPlanIndex: Int = 0
    @State private var selectedPace: Int = 1
    @State private var monthOffset: Int = 0
    @State private var selectedEpisode: EpisodeDisplayModel?
    @State private var showStartSelected: Bool = false

    /// Current season data
    private var currentSeason: Season? {
        series.currentSeason
    }

    /// Current season as display model
    private var seasonDisplayModel: SeasonDisplayModel? {
        guard let season = currentSeason else { return nil }
        return SeasonDisplayModel(from: season, isCurrent: true)
    }

    /// Prior seasons for catch-up planning
    private var priorSeasons: [SeasonDisplayModel] {
        series.regularSeasons
            .filter { $0.seasonNumber < (currentSeason?.seasonNumber ?? 1) }
            .map { SeasonDisplayModel(from: $0, isCurrent: false) }
    }

    /// Days remaining until finale
    private var daysUntilReady: Int? {
        series.daysUntilFinale
    }

    /// Weeks remaining until finale
    private var weeksRemaining: Int {
        guard let days = daysUntilReady, days > 0 else { return 1 }
        return max(1, Int(ceil(Double(days) / 7.0)))
    }

    /// Finale date from current season
    private var finaleDate: Date? {
        currentSeason?.finaleDate
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
            // Countdown header (shows days until binge-ready)
            if let days = daysUntilReady, days > 0, let displaySeason = seasonDisplayModel {
                CountdownHeader(
                    daysRemaining: days,
                    finaleDate: finaleDate,
                    releasedCount: displaySeason.releasedCount,
                    totalEpisodes: displaySeason.totalEpisodes
                )
                .padding(.top, 22)
            }

            // Episode Calendar
            if let displaySeason = seasonDisplayModel {
                EpisodeCalendar(
                    season: displaySeason,
                    startDate: calculatedStartDate,
                    monthOffset: $monthOffset,
                    selectedEpisode: $selectedEpisode,
                    showStartSelected: $showStartSelected
                )
                .padding(.top, 22)

                // Episode detail panel (when episode selected)
                if let episode = selectedEpisode {
                    EpisodeDetailPanel(
                        episode: episode,
                        showImageURL: series.backdropURL ?? series.posterURL,
                        isStartPlanSelected: false,
                        availablePlans: [],
                        finaleDate: finaleDate,
                        selectedPlanIndex: $selectedPlanIndex,
                        selectedPace: $selectedPace
                    )
                    .padding(.top, 14)
                }
            }

            // Catch-up planner (when prior seasons exist)
            if !availablePlans.isEmpty {
                CatchUpPanel(
                    availablePlans: availablePlans,
                    finaleDate: finaleDate,
                    selectedPlanIndex: $selectedPlanIndex,
                    selectedPace: $selectedPace
                )
                .padding(.top, 14)
            } else if seasonDisplayModel == nil {
                // No calendar data - show fallback
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.c2bTeal)

                    Text("catch_up_all_caught_up")
                        .font(.custom(.jetbrains.regular, size: 12))
                        .foregroundColor(.c2bMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.top, 20)
            }

            // Calendar Legend
            if seasonDisplayModel != nil {
                CalendarLegend()
            }
        }
    }
}
