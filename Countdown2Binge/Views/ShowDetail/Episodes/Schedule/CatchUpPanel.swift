//
//  CatchUpPanel.swift
//  Countdown2Binge
//
//  Always-visible panel for planning a rewatch of prior seasons.
//  Shows pace options (1, 2, 3 eps/day) with calculated start dates.
//

import SwiftUI

struct CatchUpPanel: View {
    let availablePlans: [BingePlan]
    let finaleDate: Date?
    @Binding var selectedPlanIndex: Int
    @Binding var selectedPace: Int

    var body: some View {
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

    // MARK: - Pace Options

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

                    Text("ep\(episodesPerDay > 1 ? "s" : "")/day")
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
    ScrollView {
        CatchUpPanel(
            availablePlans: [
                BingePlan(fromSeason: 1, toSeason: 1, totalEpisodes: 9, episodesPerWeek: 3, episodesPerDay: 0.4),
                BingePlan(fromSeason: 1, toSeason: 2, totalEpisodes: 19, episodesPerWeek: 5, episodesPerDay: 0.7)
            ],
            finaleDate: Date().addingTimeInterval(86400 * 28),
            selectedPlanIndex: .constant(0),
            selectedPace: .constant(1)
        )
        .padding(22)
    }
    .background(Color.c2bBackground)
}
