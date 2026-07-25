//
//  EpisodeDetailPanel.swift
//  Countdown2Binge
//
//  Info panel for the selected episode or start plan.
//  Shows thumbnail, metadata, and contextual information.
//

import SwiftUI

struct EpisodeDetailPanel: View {
    let episode: EpisodeDisplayModel?
    let showImageURL: URL?
    let isStartPlanSelected: Bool
    let availablePlans: [BingePlan]
    let finaleDate: Date?
    @Binding var selectedPlanIndex: Int
    @Binding var selectedPace: Int  // 1, 2, or 3 eps per day

    /// Calculated start date based on selected plan and pace
    var calculatedStartDate: Date? {
        guard selectedPlanIndex < availablePlans.count, let finale = finaleDate else { return nil }
        let totalEps = availablePlans[selectedPlanIndex].totalEpisodes
        let daysNeeded = Int(ceil(Double(totalEps) / Double(selectedPace)))
        return Calendar.current.date(byAdding: .day, value: -daysNeeded, to: finale)
    }

    var body: some View {
        if isStartPlanSelected && !availablePlans.isEmpty {
            startPlanPanel
        } else if let ep = episode {
            episodePanel(episode: ep)
        } else {
            emptyPanel
        }
    }

    // MARK: - Start Plan Panel

    private var startPlanPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with dropdown
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 12))
                    .foregroundColor(.c2bTealBright)

                Text("header_catch_up")
                    .font(.custom(CustomFont.jetbrains.bold, size: 9))
                    .tracking(1.2)
                    .foregroundColor(.c2bTeal)

                Spacer()

                // Season dropdown (only if multiple options)
                if availablePlans.count > 1 {
                    seasonDropdown
                }
            }
            .padding(.bottom, 14)

            // Pace options for selected plan
            if selectedPlanIndex < availablePlans.count {
                let plan = availablePlans[selectedPlanIndex]
                paceOptions(for: plan)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.c2bTeal.opacity(0.18),
                    Color.c2bTeal.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.c2bTealBright, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.c2bTeal.opacity(0.18), radius: 10, y: 5)
    }

    private func paceOptions(for plan: BingePlan) -> some View {
        let totalEps = plan.totalEpisodes

        return VStack(spacing: 6) {
            ForEach([1, 2, 3], id: \.self) { epsPerDay in
                let daysNeeded = Int(ceil(Double(totalEps) / Double(epsPerDay)))
                let startDate = calculateStartDate(daysNeeded: daysNeeded)
                let isSelected = selectedPace == epsPerDay

                PaceOptionRow(
                    episodesPerDay: epsPerDay,
                    startDate: startDate,
                    daysNeeded: daysNeeded,
                    isSelected: isSelected,
                    onSelect: { selectedPace = epsPerDay }
                )
            }
        }
    }

    private func calculateStartDate(daysNeeded: Int) -> Date {
        guard let finale = finaleDate else { return Date() }
        return Calendar.current.date(byAdding: .day, value: -daysNeeded, to: finale) ?? Date()
    }

    // MARK: - Season Dropdown

    private var seasonDropdown: some View {
        Menu {
            ForEach(Array(availablePlans.enumerated()), id: \.element.id) { index, plan in
                Button {
                    selectedPlanIndex = index
                } label: {
                    HStack {
                        Text(String(localized: "plan_season_episodes \(plan.seasonRange) \(plan.totalEpisodes)"))
                        if selectedPlanIndex == index {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                if selectedPlanIndex < availablePlans.count {
                    Text(availablePlans[selectedPlanIndex].seasonRange)
                        .font(.custom(CustomFont.oswald.bold, size: 14))
                        .foregroundColor(.c2bText)

                    Text(String(localized: "episode_count_short \(availablePlans[selectedPlanIndex].totalEpisodes)"))
                        .font(.custom(CustomFont.jetbrains.regular, size: 9))
                        .foregroundColor(.c2bMuted)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.c2bMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Episode Panel

    private func episodePanel(episode: EpisodeDisplayModel) -> some View {
        HStack(spacing: 13) {
            // Thumbnail
            thumbnailView(episode: episode)

            // Info
            VStack(alignment: .leading, spacing: 0) {
                // Episode label
                Text(episodeLabel(episode: episode))
                    .font(.custom(CustomFont.jetbrains.bold, size: 8.5))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(labelColor(episode: episode))

                // Title
                Text(episode.hasAired ? episode.title : String(localized: "episode_placeholder \(episode.number)"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.c2bText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 3)

                // Date and runtime
                HStack(spacing: 0) {
                    Text(episode.formattedAirDate)
                    if !episode.hasAired, let days = episode.daysUntilAir {
                        Text(String(localized: "episode_in_days \(days)"))
                    }
                    Text(" · \(episode.formattedRuntime)")
                }
                .font(.custom(CustomFont.jetbrains.regular, size: 9))
                .tracking(0.4)
                .foregroundColor(.c2bDim)
                .padding(.top, 5)

                // Description or finale message
                if episode.hasAired && !episode.description.isEmpty {
                    Text(episode.description)
                        .font(.system(size: 12))
                        .foregroundColor(.c2bMuted)
                        .lineLimit(2)
                        .lineSpacing(2)
                        .padding(.top, 6)
                } else if episode.isFinale && !episode.hasAired {
                    Text("binge_ready_when_airs")
                        .font(.system(size: 12))
                        .foregroundColor(.c2bTeal)
                        .lineSpacing(2)
                        .padding(.top, 6)
                }
            }
        }
        .padding(15)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func thumbnailView(episode: EpisodeDisplayModel) -> some View {
        ZStack {
            if let url = showImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(Color.c2bSurface2)
                    }
                }
            } else {
                Rectangle().fill(Color.c2bSurface2)
            }

            // Lock overlay for unaired
            if !episode.hasAired {
                Color.black.opacity(0.4)
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .frame(width: 96, height: 56)
        .brightness(episode.hasAired ? -0.08 : -0.3)
        .saturation(episode.hasAired ? 1 : 0.6)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func episodeLabel(episode: EpisodeDisplayModel) -> String {
        let epLabel = String(localized: "episode_label_short \(episode.number)")
        if episode.isFinale {
            return epLabel + " · " + String(localized: "episode_label_finale")
        } else if episode.hasAired {
            return epLabel + " · " + String(localized: "episode_label_aired")
        }
        return epLabel
    }

    private func labelColor(episode: EpisodeDisplayModel) -> Color {
        if episode.hasAired {
            return .c2bTeal
        } else if episode.isFinale {
            return .c2bTealBright
        } else {
            return .c2bMuted
        }
    }

    // MARK: - Empty Panel

    private var emptyPanel: some View {
        Text("tap_episode_details")
            .font(.custom(CustomFont.jetbrains.regular, size: 9))
            .tracking(1)
            .textCase(.uppercase)
            .foregroundColor(.c2bMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
    }

    // MARK: - Helpers

    private var formattedToday: String {
        Date().localizedShortDate
    }

    private var formattedFinaleDate: String {
        guard let date = finaleDate else { return String(localized: "date_tba") }
        return date.localizedShortDate
    }
}

// MARK: - Pace Option Row

private struct PaceOptionRow: View {
    let episodesPerDay: Int
    let startDate: Date
    let daysNeeded: Int
    let isSelected: Bool
    let onSelect: () -> Void

    private var formattedDate: String {
        startDate.localizedWeekdayDate
    }

    private var isStartToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }

    private var isPastStart: Bool {
        startDate < Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 0) {
                // Pace
                HStack(spacing: 4) {
                    Text("\(episodesPerDay)")
                        .font(.custom(CustomFont.oswald.bold, size: 18))
                        .foregroundColor(isSelected ? .c2bTealBright : .c2bText)

                    Text(episodesPerDay > 1 ? "time_eps_per_day" : "time_ep_per_day")
                        .font(.custom(CustomFont.jetbrains.regular, size: 9))
                        .tracking(0.4)
                        .foregroundColor(.c2bMuted)
                }
                .frame(width: 80, alignment: .leading)

                // Arrow
                DirectionalIcon(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.c2bMuted)
                    .padding(.horizontal, 8)

                // Start date
                VStack(alignment: .leading, spacing: 2) {
                    if isPastStart {
                        Text("time_already_started")
                            .font(.custom(CustomFont.jetbrains.bold, size: 10))
                            .foregroundColor(.c2bMuted)
                    } else if isStartToday {
                        Text("time_start_today")
                            .font(.custom(CustomFont.jetbrains.bold, size: 10))
                            .foregroundColor(isSelected ? .c2bTealBright : .c2bText)
                    } else {
                        Text(String(localized: "time_start_date \(formattedDate)"))
                            .font(.custom(CustomFont.jetbrains.bold, size: 10))
                            .foregroundColor(isSelected ? .c2bTealBright : .c2bText)
                    }

                    Text(String(localized: "time_days_to_watch \(daysNeeded)"))
                        .font(.custom(CustomFont.jetbrains.regular, size: 8))
                        .tracking(0.4)
                        .foregroundColor(.c2bDim)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.c2bTeal)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.c2bTeal.opacity(0.12) : Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.c2bTealLine : Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .opacity(isPastStart ? 0.5 : 1)
        .disabled(isPastStart)
    }
}


// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Start plan panel with multiple seasons
        EpisodeDetailPanel(
            episode: nil,
            showImageURL: nil,
            isStartPlanSelected: true,
            availablePlans: [
                BingePlan(fromSeason: 1, toSeason: 1, totalEpisodes: 9, episodesPerWeek: 3, episodesPerDay: 0.4),
                BingePlan(fromSeason: 1, toSeason: 2, totalEpisodes: 19, episodesPerWeek: 5, episodesPerDay: 0.7),
                BingePlan(fromSeason: 1, toSeason: 3, totalEpisodes: 28, episodesPerWeek: 7, episodesPerDay: 1.0)
            ],
            finaleDate: Date().addingTimeInterval(86400 * 28),
            selectedPlanIndex: .constant(1),
            selectedPace: .constant(1)
        )

        // Episode panel
        EpisodeDetailPanel(
            episode: EpisodeDisplayModel(
                id: "1",
                number: 3,
                seasonNumber: 2,
                title: "The Confrontation",
                description: "Mark confronts his past while the MDR team uncovers a disturbing secret.",
                runtime: 52,
                airDate: Date().addingTimeInterval(-86400 * 3),
                isWatched: true,
                hasAired: true,
                isFinale: false
            ),
            showImageURL: nil,
            isStartPlanSelected: false,
            availablePlans: [],
            finaleDate: nil,
            selectedPlanIndex: .constant(0),
            selectedPace: .constant(1)
        )

        // Empty panel
        EpisodeDetailPanel(
            episode: nil,
            showImageURL: nil,
            isStartPlanSelected: false,
            availablePlans: [],
            finaleDate: nil,
            selectedPlanIndex: .constant(0),
            selectedPace: .constant(1)
        )
    }
    .padding(22)
    .background(Color.c2bBackground)
}
