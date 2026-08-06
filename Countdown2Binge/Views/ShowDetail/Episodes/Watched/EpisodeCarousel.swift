//
//  EpisodeCarousel.swift
//  Countdown2Binge
//
//  Horizontal scrolling carousel of episode cards.
//  Used in "Watched" mode for tracking watch progress.
//

import SwiftUI

struct EpisodeCarousel: View {
    let season: SeasonDisplayModel
    let showImageURL: URL?
    let synopsis: String
    let onToggleWatched: (EpisodeDisplayModel) -> Void
    let onMarkAllAired: () -> Void
    let onClearAll: () -> Void

    private var watchedCount: Int { season.watchedCount }
    private var totalCount: Int { season.totalEpisodes }
    private var allAiredWatched: Bool {
        let aired = season.episodes.filter { $0.hasAired }
        guard !aired.isEmpty else { return false }
        return aired.allSatisfy { $0.isWatched }
    }
    private var hasAiredEpisodes: Bool {
        season.episodes.contains { $0.hasAired }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            headerRow
                .padding(.horizontal, 2)

            // Synopsis
            Text(synopsis)
                .font(.system(size: 12.5))
                .foregroundColor(.c2bDim)
                .lineSpacing(4)
                .padding(.horizontal, 2)
                .padding(.top, 0)
                .padding(.bottom, 14)

            // Episode cards carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(season.episodes) { episode in
                        EpisodeCard(
                            episode: episode,
                            showImageURL: showImageURL,
                            onToggleWatched: { onToggleWatched(episode) }
                        )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 2)
            }
            .padding(.horizontal, -22) // Bleed to edges

            // Status footer
            statusFooter
                .padding(.horizontal, 2)
                .padding(.top, 10)
        }
        .padding(.top, 22)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            // Watched counter
            Text(String(localized: "binge_watched_count \(watchedCount) \(totalCount)"))
                .font(.custom(CustomFont.jetbrains.bold, size: 9.5))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundColor(allAiredWatched && hasAiredEpisodes ? .c2bTealBright : .c2bMuted)

            Spacer()

            // Action button
            if hasAiredEpisodes {
                Button(action: {
                    if allAiredWatched {
                        onClearAll()
                    } else {
                        onMarkAllAired()
                    }
                }) {
                    Text(actionButtonLabel)
                        .font(.custom(CustomFont.jetbrains.bold, size: 8.5))
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundColor(.c2bDim)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 999))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 12)
    }

    private var actionButtonLabel: String {
        if allAiredWatched {
            return String(localized: "button_clear")
        } else if season.isComplete {
            return String(localized: "button_mark_all_watched")
        } else {
            return String(localized: "button_mark_aired_watched")
        }
    }

    // MARK: - Status Footer

    private var statusFooter: some View {
        Text(statusText)
            .font(.custom(CustomFont.jetbrains.regular, size: 8.5))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundColor(.c2bMuted)
    }

    private var statusText: String {
        if !season.isCurrent {
            return String(localized: "status_complete_rewatch")
        } else if season.isComplete {
            return String(localized: "status_full_season_available")
        } else if season.releasedCount > 0 {
            return String(localized: "status_partial_aired \(season.releasedCount) \(season.totalEpisodes)")
        } else {
            return String(localized: "status_no_episodes_yet")
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        EpisodeCarousel(
            season: SeasonDisplayModel(
                id: "s2",
                number: 2,
                name: "Season 2",
                episodes: [
                    EpisodeDisplayModel(
                        id: "1",
                        number: 1,
                        seasonNumber: 2,
                        title: "The Crash",
                        description: "Mark returns to Lumon after the events.",
                        runtime: 45,
                        airDate: Date().addingTimeInterval(-86400 * 14),
                        isWatched: true,
                        hasAired: true,
                        isFinale: false
                    ),
                    EpisodeDisplayModel(
                        id: "2",
                        number: 2,
                        seasonNumber: 2,
                        title: "Goodbye, Mrs. Selvig",
                        description: "Helly confronts her outie's past.",
                        runtime: 52,
                        airDate: Date().addingTimeInterval(-86400 * 7),
                        isWatched: true,
                        hasAired: true,
                        isFinale: false
                    ),
                    EpisodeDisplayModel(
                        id: "3",
                        number: 3,
                        seasonNumber: 2,
                        title: "Episode 3",
                        description: "Details not yet available.",
                        runtime: 45,
                        airDate: Date().addingTimeInterval(86400 * 2),
                        isWatched: false,
                        hasAired: false,
                        isFinale: false
                    ),
                    EpisodeDisplayModel(
                        id: "4",
                        number: 4,
                        seasonNumber: 2,
                        title: "Episode 4",
                        description: "Details not yet available.",
                        runtime: 45,
                        airDate: Date().addingTimeInterval(86400 * 9),
                        isWatched: false,
                        hasAired: false,
                        isFinale: true
                    )
                ],
                isCurrent: true,
                airDate: Date().addingTimeInterval(-86400 * 14)
            ),
            showImageURL: nil,
            synopsis: "Season 2 of Severance continues the story of Mark S. and his colleagues at Lumon Industries.",
            onToggleWatched: { _ in },
            onMarkAllAired: {},
            onClearAll: {}
        )
        .padding(.horizontal, 22)
    }
    .background(Color.c2bBackground)
}
