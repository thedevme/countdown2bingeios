//
//  DetailEpisodeSection.swift
//  Countdown2Binge
//
//  Episode section showing episode cards in a horizontal carousel.
//  Always shows the EpisodeCarousel regardless of airing state.
//

import SwiftUI
import SwiftData

struct DetailEpisodeSection: View {
    let series: Series
    var selectedSeason: Int? = nil
    @Environment(SeriesManager.self) private var seriesManager

    private var seasonNumber: Int {
        selectedSeason ?? series.currentSeason?.seasonNumber ?? series.numberOfSeasons
    }

    private var season: Season? {
        if let selectedSeason = selectedSeason {
            // If viewing the current season, use currentSeason which has full episode data
            if let current = series.currentSeason, current.seasonNumber == selectedSeason {
                return current
            }
            return series.seasons.first { $0.seasonNumber == selectedSeason }
        }
        return series.currentSeason
    }

    private var seasonDisplayModel: SeasonDisplayModel? {
        guard let season = season else { return nil }
        return SeasonDisplayModel(from: season, isCurrent: season.seasonNumber == series.currentSeason?.seasonNumber)
    }

    private var synopsis: String {
        season?.overview ?? series.overview ?? ""
    }

    private var isAnticipatedSeason: Bool {
        guard let selected = selectedSeason,
              let season = series.seasons.first(where: { $0.seasonNumber == selected }) else {
            return false
        }
        
        // Anticipated if season hasn't started (no premiere date or premiere in future) and has no episodes
        let today = Calendar.current.startOfDay(for: Date())
        if let premiere = season.premiereDate {
            let hasStarted = Calendar.current.startOfDay(for: premiere) <= today
            return !hasStarted && season.episodes.isEmpty
        }
        return season.episodes.isEmpty
    }

    var body: some View {
        // For anticipated seasons, show a placeholder message
        if isAnticipatedSeason {
            anticipatedSeasonPlaceholder
        } else if let displaySeason = seasonDisplayModel {
            // Show episode cards carousel
            
            EpisodeCarousel(
                season: displaySeason,
                showImageURL: series.backdropURL ?? series.posterURL,
                synopsis: synopsis,
                onToggleWatched: { episode in
                    try? seriesManager.toggleEpisodeWatched(
                        seriesId: series.id,
                        seasonNumber: seasonNumber,
                        episodeNumber: episode.number
                    )
                },
                onMarkAllAired: {
                    try? seriesManager.markAiredEpisodesWatched(
                        seriesId: series.id,
                        seasonNumber: seasonNumber
                    )
                },
                onClearAll: {
                    try? seriesManager.markSeasonWatched(
                        seriesId: series.id,
                        seasonNumber: seasonNumber,
                        watched: false
                    )
                }
            )
        } else {
            // Fallback for seasons without detailed episode data
            legacyEpisodeGrid
        }
    }

    // MARK: - Legacy Fallback

    /// Fallback grid view when episode details aren't available
    private var legacyEpisodeGrid: some View {
        let episodes = season?.sortedEpisodes ?? []
        let watchedCount = season?.watchedEpisodeCount ?? 0
        let episodeCount = episodes.count
        let isAllWatched = episodeCount > 0 && watchedCount == episodeCount

        return VStack(alignment: .leading, spacing: 16) {
            // Season header with progress bar
            VStack(alignment: .leading, spacing: 8) {
                // Progress bar (dashed segments)
                HStack(spacing: 3) {
                    ForEach(episodes, id: \.id) { episode in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(episode.hasWatched ? Color.c2bTeal : Color.white.opacity(0.15))
                            .frame(height: 4)
                    }
                }
                .frame(maxWidth: .infinity)

                // Season label and status
                HStack(alignment: .center) {
                    Text("S\(seasonNumber)")
                        .font(.custom(.oswald.bold, size: 22))
                        .foregroundColor(.white)

                    Text(isAllWatched ? "\(watchedCount)/\(episodeCount) WATCHED \u{00B7} DONE" : "\(watchedCount)/\(episodeCount) WATCHED")
                        .font(.custom(.jetbrains.bold, size: 9))
                        .foregroundColor(isAllWatched ? .c2bTealBright : .c2bMuted)
                        .tracking(0.8)

                    Spacer()

                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.c2bMuted)
                }
            }

            // Episode grid
            if !episodes.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                    ForEach(episodes, id: \.id) { episode in
                        LegacyEpisodeSquare(
                            episodeNumber: episode.episodeNumber,
                            isWatched: episode.hasWatched,
                            onToggle: {
                                try? seriesManager.toggleEpisodeWatched(
                                    seriesId: series.id,
                                    seasonNumber: seasonNumber,
                                    episodeNumber: episode.episodeNumber
                                )
                            }
                        )
                    }
                }

                // Clear season button
                if watchedCount > 0 {
                    Button {
                        try? seriesManager.markSeasonWatched(
                            seriesId: series.id,
                            seasonNumber: seasonNumber,
                            watched: false
                        )
                    } label: {
                        Text("button_clear_season")
                            .font(.custom(.jetbrains.bold, size: 10))
                            .foregroundColor(.c2bMuted)
                            .tracking(1.2)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("no_episodes_available")
                    .font(.custom(.jetbrains.regular, size: 10))
                    .foregroundColor(.c2bMuted)
                    .padding(.top, 8)
            }
        }
        .padding(.top, 22)
    }

    // MARK: - Anticipated Season Placeholder

    private var anticipatedSeasonPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(.c2bMuted)

            Text("episodes_not_announced")
                .font(.custom(.jetbrains.bold, size: 11))
                .foregroundColor(.c2bMuted)
                .tracking(1.2)
                .textCase(.uppercase)

            Text("episodes_coming_soon_description")
                .font(.system(size: 13))
                .foregroundColor(.c2bDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}

// MARK: - Legacy Episode Square

private struct LegacyEpisodeSquare: View {
    let episodeNumber: Int
    let isWatched: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isWatched ? Color.c2bTeal : Color.c2bSurface)

                RoundedRectangle(cornerRadius: 10)
                    .stroke(isWatched ? Color.c2bTeal : Color.white.opacity(0.12), lineWidth: 1)

                if isWatched {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#04201c"))
                } else {
                    Text("\(episodeNumber)")
                        .font(.custom(.oswald.medium, size: 18))
                        .foregroundColor(.c2bMuted)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }
}
