//
//  DetailEpisodeSection.swift
//  Countdown2Binge
//
//  Episode section showing episode cards in a horizontal carousel.
//  Always shows the EpisodeCarousel regardless of airing state.
//

import SwiftUI

struct DetailEpisodeSection: View {
    let show: ShowData
    var selectedSeason: Int? = nil
    @StateObject private var watchProgress = WatchProgressManager.shared

    private var seasonNumber: Int {
        selectedSeason ?? show.numberOfSeasons
    }

    private var season: SeasonData? {
        if let selectedSeason = selectedSeason {
            return show.seasons.first { $0.seasonNumber == selectedSeason }
        }
        return show.currentSeason
    }

    private var seasonDisplayModel: SeasonDisplayModel? {
        show.seasonDisplayModel(seasonNumber: seasonNumber, watchProgress: watchProgress)
    }

    private var synopsis: String {
        season?.overview ?? show.overview ?? ""
    }

    var body: some View {
        if let displaySeason = seasonDisplayModel {
            // Always show episode cards carousel
            EpisodeCarousel(
                season: displaySeason,
                showImageURL: show.backdropURL ?? show.posterURL,
                synopsis: synopsis,
                onToggleWatched: { episode in
                    watchProgress.toggleWatched(
                        showId: show.id,
                        season: seasonNumber,
                        episode: episode.number
                    )
                },
                onMarkAllAired: {
                    guard let season = season else { return }
                    let airedEpisodes = season.episodes
                        .filter { $0.hasAired }
                        .map { $0.episodeNumber }
                    watchProgress.markAiredWatched(
                        showId: show.id,
                        season: seasonNumber,
                        airedEpisodes: airedEpisodes
                    )
                },
                onClearAll: {
                    guard let season = season else { return }
                    watchProgress.setSeasonWatched(
                        showId: show.id,
                        season: season.seasonNumber,
                        episodeCount: season.episodeCount,
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
        let episodeCount = season?.episodeCount ?? 0
        let watchedCount = watchProgress.seasonWatchedCount(
            showId: show.id,
            season: seasonNumber,
            episodeCount: episodeCount
        )
        let isAllWatched = episodeCount > 0 && watchedCount == episodeCount

        return VStack(alignment: .leading, spacing: 16) {
            // Season header with progress bar
            VStack(alignment: .leading, spacing: 8) {
                // Progress bar (dashed segments)
                HStack(spacing: 3) {
                    ForEach(1...max(episodeCount, 1), id: \.self) { ep in
                        let isWatched = watchProgress.isWatched(
                            showId: show.id,
                            season: seasonNumber,
                            episode: ep
                        )
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isWatched ? Color.c2bTeal : Color.white.opacity(0.15))
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
            if episodeCount > 0 {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                    ForEach(1...episodeCount, id: \.self) { episodeNum in
                        LegacyEpisodeSquare(
                            episodeNumber: episodeNum,
                            isWatched: watchProgress.isWatched(
                                showId: show.id,
                                season: seasonNumber,
                                episode: episodeNum
                            ),
                            onToggle: {
                                watchProgress.toggleWatched(
                                    showId: show.id,
                                    season: seasonNumber,
                                    episode: episodeNum
                                )
                            }
                        )
                    }
                }

                // Clear season button
                if watchedCount > 0 {
                    Button {
                        guard let season = season else { return }
                        watchProgress.setSeasonWatched(
                            showId: show.id,
                            season: season.seasonNumber,
                            episodeCount: season.episodeCount,
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
