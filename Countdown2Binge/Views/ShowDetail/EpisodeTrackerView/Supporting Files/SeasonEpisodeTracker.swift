//
//  SeasonEpisodeTracker.swift
//  Countdown2Binge
//
//  The body of an expanded season: tick meter, one row per episode, status
//  footer. Ported from c2b-timeline.jsx `EpisodeTracker`.
//
//  The season plate sits above this as the card's header (SeasonAccordionRow),
//  so the watched rollup, bulk-mark button and season synopsis the prototype
//  carried here are deliberately gone — they repeated what the plate says.
//
//  Reads a SeasonDisplayModel (display DTO, no lifecycle math — R1) and routes
//  every write through SeriesManager (R3).
//
//  Axis discipline (R8): `hasAired` is show-state (dates), `isWatched` is
//  user-state (marks). Read separately, never blended into one "complete" flag.
//

import SwiftUI

struct SeasonEpisodeTracker: View {
    let seriesId: Int
    let season: SeasonDisplayModel
    let stillURL: URL?

    @Environment(SeriesManager.self) private var seriesManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EpisodeTickMeter(ticks: ticks) { tick in
                // Tapping the tick that is currently the last watched one
                // steps back by one; otherwise fill through it.
                let through = watchedCount == tick.number ? tick.number - 1 : tick.number
                setWatchedThrough(through)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 14)

            ForEach(season.episodes) { episode in
                EpisodeTrackerRow(
                    episode: episode,
                    stillURL: stillURL,
                    isNextUp: episode.number == nextUpNumber,
                    onTap: { toggle(episode) }
                )
            }

            Text(footerLabel)
                .font(.custom(.jetbrains.regular, size: 8.5))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)
                .padding(.top, 10)
        }
        .padding(.top, 12)
        .animation(.easeOut(duration: 0.2), value: watchedCount)
    }

    // MARK: - Derived

    private var watchedCount: Int { season.watchedCount }

    /// Episodes that have aired — the only ones a user can mark.
    private var releasedCount: Int { season.releasedCount }

    /// First aired-but-unwatched episode — gets the NEXT chip.
    private var nextUpNumber: Int? {
        season.episodes.first { $0.hasAired && !$0.isWatched }?.number
    }

    /// Feeds the shared EpisodeTickMeter (Components/).
    private var ticks: [EpisodeTick] {
        season.episodes.map { episode in
            EpisodeTick(
                id: Int(episode.id) ?? episode.number,
                number: episode.number,
                watched: episode.isWatched,
                aired: episode.hasAired
            )
        }
    }

    private var footerLabel: String {
        if !season.isCurrent {
            return String(localized: "status_complete_rewatch")
        } else if season.isComplete {
            return String(localized: "status_full_season_available")
        } else if releasedCount > 0 {
            return String(localized: "status_partial_aired \(releasedCount) \(season.totalEpisodes)")
        } else {
            return String(localized: "status_no_episodes_yet")
        }
    }

    // MARK: - Mutations — all through SeriesManager (R3)

    /// Tapping an episode is cumulative, not a single toggle: marking E5 fills
    /// E1–E5, and un-marking a watched E5 clears it and everything after it.
    private func toggle(_ episode: EpisodeDisplayModel) {
        guard episode.hasAired else { return }
        setWatchedThrough(episode.isWatched ? episode.number - 1 : episode.number)
    }

    private func setWatchedThrough(_ episodeNumber: Int) {
        try? seriesManager.setWatchedThrough(
            seriesId: seriesId,
            seasonNumber: season.number,
            episodeNumber: episodeNumber
        )
    }
}
