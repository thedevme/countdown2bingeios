//
//  MyLibraryShowGrid.swift
//  Countdown2Binge
//
//  3-column grid of show posters for My Library. Removing a show is local
//  device management, not an iCloud feature, so long-press-to-delete works
//  for both tiers — only the sync badge language (SYNCED vs LOCAL ONLY)
//  differs by tier.
//

import SwiftUI

struct MyLibraryShowGrid: View {
    let shows: [Series]
    let isPremium: Bool
    let isEditMode: Bool
    let onRemove: (Series) -> Void
    var onSelect: (Series) -> Void = { _ in }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        if shows.isEmpty {
            emptyState
        } else {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(shows, id: \.id) { series in
                    PosterTileEditable(
                        posterURL: series.posterURL,
                        title: series.name,
                        badgeVariant: badgeVariant(for: series),
                        isEditMode: isEditMode,
                        // Free sees its shows plainly — no dimmed/locked
                        // look. Only a synced-but-removed Premium show
                        // (mid-transition) would ever be dimmed here.
                        isLocked: false,
                        onRemove: { onRemove(series) },
                        watchedEpisodes: series.overallWatchedEpisodeCount,
                        totalEpisodes: series.overallEpisodeCount
                    )
                    // Not a Button — the X button (edit mode) is a nested
                    // tappable control; a tap gesture on the tile only
                    // fires for taps outside it, same reasoning as
                    // MyListRailCard. Edit mode itself absorbs the tap
                    // (jiggling tiles shouldn't also navigate away).
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isEditMode else { return }
                        onSelect(series)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: isPremium ? "icloud" : "tv")
                .font(.system(size: 30, weight: .light))
                .foregroundColor(.white.opacity(0.25))
            Text(isPremium ? "Nothing backed up to iCloud yet" : "Nothing tracked yet")
                .font(.custom(.jetbrains.regular, size: 11))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func badgeVariant(for series: Series) -> StatusBadgeVariant {
        if !isPremium {
            return .localOnly
        }
        // No per-show in-flight sync state is tracked here, so an unsynced show
        // is "local only" (e.g. removed from iCloud, or iCloud unavailable) —
        // not a perpetual "syncing" spinner.
        return series.isSynced ? .synced : .localOnly
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()

        Text("Preview requires Series data")
            .foregroundColor(.white.opacity(0.5))
    }
}
