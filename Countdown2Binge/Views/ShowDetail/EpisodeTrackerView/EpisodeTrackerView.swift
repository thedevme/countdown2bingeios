//
//  EpisodeTrackerView.swift
//  Countdown2Binge
//
//  The season tracker for show detail: every season stacked as an accordion,
//  the open one revealing its episode tracker. Ported from c2b-timeline.jsx
//  (`SeasonAccordion` + `EpisodeTracker`) — the design bundle's season module.
//
//  Replaces the season dropdown + episode carousel that used to sit on the
//  Season Info tab. The status/countdown card above it is unaffected — this
//  view drives `selectedSeason`, so that card follows whichever season is open.
//
//  Reads `Series` directly (R4). Seasons are turned into SeasonDisplayModel for
//  rendering only — no lifecycle math on the DTO (R1) — and every watch write
//  goes through SeriesManager (R3).
//

import SwiftUI
import SwiftData

struct EpisodeTrackerView: View {
    let series: Series
    /// The season in focus. Bound so the status card above stays in step — it
    /// survives collapsing the accordion, so the card doesn't jump when you
    /// close a season.
    @Binding var selectedSeason: Int

    /// The season currently expanded, or nil when all are closed.
    @State private var expandedSeason: Int?

    init(series: Series, selectedSeason: Binding<Int>) {
        self.series = series
        self._selectedSeason = selectedSeason
        self._expandedSeason = State(initialValue: selectedSeason.wrappedValue)
    }

    private var stillURL: URL? {
        series.backdropURL ?? series.posterURL
    }

    private var currentSeasonNumber: Int? {
        series.currentSeason?.seasonNumber
    }

    /// Still airing: newest season first (what's new matters most, and
    /// pairs with opening on the newest season below). Ended: oldest first
    /// — the normal, chronological reading order — paired with opening on
    /// wherever the user's watch progress actually is, not the newest.
    /// `visibleSeasons` has already dropped TMDB's empty placeholder for an
    /// ordered-but-unannounced season (Silo S4, say).
    private var seasons: [Season] {
        let sorted = series.visibleSeasons.sorted { $0.seasonNumber < $1.seasonNumber }
        return series.status.isActive ? Array(sorted.reversed()) : sorted
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(seasons, id: \.seasonNumber) { season in
                let isExpanded = season.seasonNumber == expandedSeason

                SeasonAccordionRow(
                    seasonNumber: season.seasonNumber,
                    // sortedEpisodes, not episodes: the tracker body renders
                    // that list (specials excluded), so the counts must match.
                    watchedCount: season.sortedEpisodes.filter(\.hasWatched).count,
                    totalEpisodes: season.sortedEpisodes.count,
                    isCurrent: season.seasonNumber == currentSeasonNumber,
                    isExpanded: isExpanded,
                    onTap: {
                        // At most one season open. Tapping the open one closes
                        // it; `selectedSeason` stays put so the status card
                        // above keeps showing that season.
                        withAnimation(.easeOut(duration: 0.28)) {
                            if isExpanded {
                                expandedSeason = nil
                            } else {
                                expandedSeason = season.seasonNumber
                                selectedSeason = season.seasonNumber
                            }
                        }
                    }
                ) {
                    SeasonEpisodeTracker(
                        seriesId: series.id,
                        season: SeasonDisplayModel(
                            from: season,
                            isCurrent: season.seasonNumber == currentSeasonNumber
                        ),
                        stillURL: stillURL
                    )
                }
            }
        }
        .padding(.top, 4)
        .onAppear(perform: clampToVisibleSeason)
    }

    /// The season we arrived on can be one we've just filtered out — the show's
    /// "current" season may be the empty placeholder. Fall back to the newest
    /// season that actually has something in it, so neither this list nor the
    /// status card above points at a season that isn't on screen.
    private func clampToVisibleSeason() {
        let visible = seasons.map(\.seasonNumber)
        guard !visible.isEmpty, !visible.contains(selectedSeason) else { return }
        guard let newest = visible.first else { return }
        selectedSeason = newest
        expandedSeason = newest
    }
}
