//
//  DetailStatusBlock.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailStatusBlock: View {
    let show: ShowData
    var selectedSeason: Int? = nil

    @State private var hours: Int = 7
    @State private var minutes: Int = 32
    @State private var seconds: Int = 36
    @State private var timer: Timer?

    // Whether we're viewing a past season (completed, not current or anticipated)
    private var isViewingPastSeason: Bool {
        guard let selected = selectedSeason else { return false }
        guard let currentSeasonNumber = show.currentSeason?.seasonNumber else {
            // No current season means all seasons are either past or anticipated
            return !show.isAnticipatedSeason(selected)
        }
        return selected < currentSeasonNumber
    }

    // Whether we're viewing an anticipated season (not yet started)
    private var isViewingAnticipatedSeason: Bool {
        guard let selected = selectedSeason else { return false }
        return show.isAnticipatedSeason(selected)
    }

    // Whether we're viewing the current season (actually airing)
    private var isViewingCurrentSeason: Bool {
        guard let selected = selectedSeason else { return true }
        return show.currentSeason?.seasonNumber == selected
    }

    // Whether the selected season has finished airing (all episodes out)
    private var isSelectedSeasonBingeReady: Bool {
        // Get the season we're viewing
        let seasonNumber = selectedSeason ?? show.currentSeason?.seasonNumber ?? show.numberOfSeasons

        guard let season = show.currentSeason?.seasonNumber == seasonNumber
            ? show.currentSeason
            : show.seasons.first(where: { $0.seasonNumber == seasonNumber }) else {
            return false
        }

        // Check if the season's finale has already aired
        if let finaleDate = season.finaleDate {
            let today = Calendar.current.startOfDay(for: Date())
            let finale = Calendar.current.startOfDay(for: finaleDate)
            return finale <= today
        }

        // No finale date - check if all episodes have aired
        // If the season has started and has no future episodes, consider it binge ready
        if let premiereDate = season.premiereDate {
            let today = Calendar.current.startOfDay(for: Date())
            let premiere = Calendar.current.startOfDay(for: premiereDate)
            if premiere <= today {
                // Season has started - check if there are any future episode air dates
                let hasUnreleasedEpisodes = season.episodes.contains { episode in
                    guard let airDate = episode.airDate else { return false }
                    return Calendar.current.startOfDay(for: airDate) > today
                }
                return !hasUnreleasedEpisodes && season.episodeCount > 0
            }
        }

        return false
    }

    // Whether we should show the "NOW / READY TO BINGE" box
    // This applies to: past seasons OR current season that has finished airing
    private var shouldShowReadyState: Bool {
        // Don't show ready state for anticipated seasons
        if isViewingAnticipatedSeason { return false }
        // Show ready state for past seasons or if selected season is binge ready
        return isViewingPastSeason || isSelectedSeasonBingeReady
    }

    // Episode count for the selected season
    private var selectedSeasonEpisodeCount: Int {
        guard let selected = selectedSeason else {
            // For current season, use currentSeason's episodeCount
            return show.currentSeason?.episodeCount ?? 0
        }
        if let current = show.currentSeason, current.seasonNumber == selected {
            return current.episodeCount
        }
        return show.seasons.first { $0.seasonNumber == selected }?.episodeCount ?? 0
    }

    private var isReady: Bool {
        shouldShowReadyState
    }

    private var daysRemaining: Int? {
        if isViewingAnticipatedSeason {
            // Calculate days until premiere for the selected anticipated season
            guard let selected = selectedSeason,
                  let season = show.seasons.first(where: { $0.seasonNumber == selected }),
                  let premiereDate = season.airDate else {
                return show.daysUntilPremiere
            }
            let today = Calendar.current.startOfDay(for: Date())
            let premiere = Calendar.current.startOfDay(for: premiereDate)
            let days = Calendar.current.dateComponents([.day], from: today, to: premiere).day ?? 0
            return max(0, days)
        }
        return show.daysUntilFinale ?? show.daysUntilPremiere
    }

    // Only show countdown clock for currently AIRING shows (not binge ready)
    private var showClock: Bool {
        if shouldShowReadyState { return false }
        if isViewingAnticipatedSeason { return false }
        if let days = daysRemaining, days > 0 {
            return true
        }
        return false
    }

    private var effectiveCategory: TimelineCategory {
        if shouldShowReadyState { return .bingeReady }
        if isViewingAnticipatedSeason { return .anticipated }
        // Map ShowState to TimelineCategory
        switch show.showState {
        case .airing, .pending: return .airingNow
        case .premieringSoon: return .premieringSoon
        case .anticipated: return .anticipated
        case .bingeReady: return .bingeReady
        }
    }

    private var phaseTone: Color {
        switch effectiveCategory {
        case .airingNow: return .c2bTeal
        case .premieringSoon: return .c2bTeal.opacity(0.7)
        case .anticipated: return .c2bMuted
        case .bingeReady: return .c2bTealBright
        }
    }

    private var phaseLabel: String {
        if shouldShowReadyState {
            return String(localized: "status_complete_all_out \(selectedSeasonEpisodeCount)")
        }
        if isViewingAnticipatedSeason {
            return String(localized: "phase_anticipated")
        }
        switch show.showState {
        case .airing, .pending: return String(localized: "phase_now_airing")
        case .premieringSoon: return String(localized: "phase_premiering_soon")
        case .anticipated: return String(localized: "phase_anticipated")
        case .bingeReady: return String(localized: "phase_binge_ready")
        }
    }

    private var countdownTitle: String {
        if isViewingAnticipatedSeason {
            return String(localized: "timeline_countdown_premiere")
        }
        return String(localized: "timeline_countdown_finale")
    }

    // Premiere date for anticipated season
    private var anticipatedPremiereDate: Date? {
        guard let selected = selectedSeason else { return nil }
        return show.seasons
            .first { $0.seasonNumber == selected }?
            .airDate
    }

    var body: some View {
        VStack(spacing: 0) {
            // Ready state: Past season OR current season that finished airing
            if shouldShowReadyState {
                HStack(alignment: .top, spacing: 16) {
                    // NOW label
                    Text("NOW")
                        .font(.custom(.oswald.bold, size: 44))
                        .foregroundColor(.c2bTeal)

                    // Status info
                    VStack(alignment: .leading, spacing: 6) {
                        Text("phase_ready_to_binge")
                            .font(.custom(.jetbrains.bold, size: 9.5))
                            .foregroundColor(.c2bTealBright)
                            .tracking(1.6)
                            .textCase(.uppercase)

                        Text(String(localized: "status_all_episodes_out \(selectedSeasonEpisodeCount)"))
                            .font(.system(size: 13))
                            .foregroundColor(.c2bDim)

                        DetailPhasePill(
                            label: phaseLabel,
                            tone: phaseTone,
                            isReady: true
                        )
                        .padding(.top, 4)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            // Anticipated season: Show "SOON" state with premiere info
            else if isViewingAnticipatedSeason {
                HStack(alignment: .top, spacing: 16) {
                    // SOON label or days count
                    if let days = daysRemaining, days > 0 {
                        VStack(spacing: 2) {
                            Text("\(days)")
                                .font(.custom(.oswald.bold, size: 44))
                                .foregroundColor(.c2bMuted)
                            Text("time_days")
                                .font(.custom(.jetbrains.bold, size: 8))
                                .foregroundColor(.c2bMuted)
                                .tracking(1.0)
                                .textCase(.uppercase)
                        }
                    } else {
                        Text("SOON")
                            .font(.custom(.oswald.bold, size: 44))
                            .foregroundColor(.c2bMuted)
                    }

                    // Status info
                    VStack(alignment: .leading, spacing: 6) {
                        Text("status_until_premiere")
                            .font(.custom(.jetbrains.bold, size: 9.5))
                            .foregroundColor(.c2bMuted)
                            .tracking(1.6)
                            .textCase(.uppercase)

                        if let date = anticipatedPremiereDate {
                            Text(date.localizedFullDate)
                                .font(.system(size: 13))
                                .foregroundColor(.c2bDim)
                        } else {
                            Text("status_no_release_date")
                                .font(.system(size: 13))
                                .foregroundColor(.c2bDim)
                        }

                        DetailPhasePill(
                            label: phaseLabel,
                            tone: phaseTone,
                            isReady: false
                        )
                        .padding(.top, 4)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            // Current season: Clock countdown (only when days remaining)
            else if showClock {
                VStack(spacing: 12) {
                    Text(countdownTitle)
                        .font(.custom(.oswald.bold, size: 15))
                        .tracking(0.6)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        StatusClockCell(value: "\(daysRemaining ?? 0)", label: String(localized: "time_days"))
                        StatusClockSeparator()
                        StatusClockCell(value: String(format: "%02d", hours), label: String(localized: "time_hours"))
                        StatusClockSeparator()
                        StatusClockCell(value: String(format: "%02d", minutes), label: String(localized: "time_minutes"))
                        StatusClockSeparator()
                        StatusClockCell(value: String(format: "%02d", seconds), label: String(localized: "time_seconds"))
                    }

                    // Status info
                    DetailStatusInfo(
                        show: show,
                        isReady: isReady,
                        isAnticipated: isViewingAnticipatedSeason,
                        phaseTone: phaseTone,
                        phaseLabel: phaseLabel
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }

            DetailLifecycleMeter(category: effectiveCategory)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.2))
        }
        .background(
            isReady
                ? LinearGradient(colors: [Color.c2bTeal.opacity(0.16), Color.c2bTeal.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color.white.opacity(0.03), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isReady ? Color.c2bTealLine : Color.white.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            if showClock {
                startTimer()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            tick()
        }
    }

    private func tick() {
        seconds -= 1
        if seconds < 0 {
            seconds = 59
            minutes -= 1
        }
        if minutes < 0 {
            minutes = 59
            hours -= 1
        }
        if hours < 0 {
            hours = 23
        }
    }
}

// MARK: - Status Clock Cell

private struct StatusClockCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.custom(.oswald.bold, size: 28))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                )
                .cornerRadius(10)

            Text(label.uppercased())
                .font(.custom(.jetbrains.bold, size: 7))
                .tracking(1.0)
                .foregroundColor(.c2bMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Status Clock Separator

private struct StatusClockSeparator: View {
    var body: some View {
        Text(":")
            .font(.custom(.oswald.bold, size: 22))
            .foregroundColor(.c2bTeal)
            .padding(.horizontal, 1)
            .offset(y: -8)
    }
}
