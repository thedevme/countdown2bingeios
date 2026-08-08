//
//  DetailSeasonPicker.swift
//  Countdown2Binge
//

import SwiftUI
import SwiftData

struct DetailSeasonPicker: View {
    let series: Series
    @Binding var selectedSeason: Int
    @State private var isExpanded = false

    private var currentSeasonNumber: Int? {
        series.currentSeason?.seasonNumber
    }

    /// Whether the current season's finale aired more than 24 hours ago
    private var hasCurrentSeasonFinished: Bool {
        guard let current = series.currentSeason,
              let finaleDate = current.finaleDate else {
            // No current season or no finale date - assume finished
            return true
        }
        // Finale must have aired more than 24 hours ago
        let now = Date()
        let hoursSinceFinale = Calendar.current.dateComponents([.hour], from: finaleDate, to: now).hour ?? 0
        return hoursSinceFinale >= 24
    }

    /// Maximum season number to show in the picker
    /// Only show anticipated seasons after the current season's finale has aired
    private var maxSelectableSeason: Int {
        if hasCurrentSeasonFinished {
            // Finale has passed, can show anticipated seasons
            return series.numberOfSeasons
        } else {
            // Still airing, only show up to current season
            return currentSeasonNumber ?? series.numberOfSeasons
        }
    }

    private func episodeCount(for seasonNumber: Int) -> Int {
        // Prefer currentSeason if it matches (has full data)
        if let current = series.currentSeason, current.seasonNumber == seasonNumber {
            return current.episodeCount
        }
        return series.seasons.first { $0.seasonNumber == seasonNumber }?.episodeCount ?? 0
    }

    /// Episodes marked watched in a season — reads live from the stored model so
    /// the picker reflects marking a season watched (both immediately and on
    /// return). Previously hard-coded to 0.
    private func watchedCount(for seasonNumber: Int) -> Int {
        if let current = series.currentSeason, current.seasonNumber == seasonNumber {
            return current.watchedEpisodeCount
        }
        return series.seasons.first { $0.seasonNumber == seasonNumber }?.watchedEpisodeCount ?? 0
    }

    private func isAnticipated(_ seasonNumber: Int) -> Bool {
        guard let season = series.seasons.first(where: { $0.seasonNumber == seasonNumber }) else {
            return false
        }
        // Anticipated if season hasn't started (no premiere date or premiere in future)
        let today = Calendar.current.startOfDay(for: Date())
        if let premiere = season.premiereDate {
            return Calendar.current.startOfDay(for: premiere) > today
        }
        return season.episodes.isEmpty
    }

    private func isCurrent(_ seasonNumber: Int) -> Bool {
        currentSeasonNumber == seasonNumber
    }

    private func shouldShowSeason(_ seasonNumber: Int) -> Bool {
        seasonNumber <= maxSelectableSeason
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(String(localized: "season_number \(selectedSeason)"))
                        .font(.custom(.oswald.bold, size: 20))
                        .foregroundColor(.white)
                        .textCase(.uppercase)

                    if isCurrent(selectedSeason) {
                        DetailCurrentBadge()
                    } else if isAnticipated(selectedSeason) {
                        DetailAnticipatedBadge()
                    }

                    Spacer()

                    // Show episode count if episodes exist
                    let selectedCount = episodeCount(for: selectedSeason)
                    if selectedCount > 0 {
                        Text(String(localized: "binge_watched_count \(watchedCount(for: selectedSeason)) \(selectedCount)"))
                            .font(.custom(.jetbrains.regular, size: 9.5))
                            .foregroundColor(.c2bMuted)
                            .tracking(1.0)
                    }

                    if maxSelectableSeason > 1 {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.c2bMuted)
                            .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .background(Color.white.opacity(0.04))
                .cornerRadius(isExpanded ? 0 : 13)
                .cornerRadius(13, corners: [.topLeft, .topRight])
            }
            .buttonStyle(.plain)

            // Expandable season list
            if isExpanded && maxSelectableSeason > 1 {
                VStack(spacing: 0) {
                    ForEach(1...maxSelectableSeason, id: \.self) { season in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedSeason = season
                                isExpanded = false
                            }
                        } label: {
                            HStack {
                                Text(String(localized: "season_number \(season)"))
                                    .font(.custom(.oswald.regular, size: 18))
                                    .foregroundColor(season == selectedSeason ? .white : .c2bDim)

                                if isCurrent(season) {
                                    Text("·")
                                        .foregroundColor(.c2bMuted)
                                    Text("detail_current")
                                        .font(.custom(.jetbrains.bold, size: 9))
                                        .foregroundColor(.c2bTeal)
                                        .tracking(1.0)
                                } else if isAnticipated(season) {
                                    Text("·")
                                        .foregroundColor(.c2bMuted)
                                    Text("detail_anticipated")
                                        .font(.custom(.jetbrains.bold, size: 9))
                                        .foregroundColor(.c2bMuted)
                                        .tracking(1.0)
                                }

                                Spacer()

                                // Show episode count if episodes exist
                                let count = episodeCount(for: season)
                                if count > 0 {
                                    Text("\(watchedCount(for: season))/\(count)")
                                        .font(.custom(.jetbrains.regular, size: 11))
                                        .foregroundColor(.c2bMuted)
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                            .background(season == selectedSeason ? Color.white.opacity(0.06) : Color.clear)
                        }
                        .buttonStyle(.plain)

                        if season < maxSelectableSeason {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                                .padding(.horizontal, 15)
                        }
                    }
                }
                .background(Color.white.opacity(0.04))
                .cornerRadius(13, corners: [.bottomLeft, .bottomRight])
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Anticipated Badge

struct DetailAnticipatedBadge: View {
    var body: some View {
        Text("detail_anticipated")
            .font(.custom(.jetbrains.bold, size: 8))
            .foregroundColor(.c2bMuted)
            .tracking(1.0)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.08))
            .cornerRadius(4)
    }
}
