//
//  CloudSyncShowGrid.swift
//  Countdown2Binge
//
//  3-column grid of show posters for CloudSync view.
//

import SwiftUI

struct CloudSyncShowGrid: View {
    let shows: [Series]
    let isPremium: Bool
    let isEditMode: Bool
    let onRemove: (Series) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        if shows.isEmpty && isPremium {
            emptyState
        } else {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(shows, id: \.id) { series in
                    PosterTileEditable(
                        posterURL: series.posterURL,
                        title: series.name,
                        badgeVariant: badgeVariant(for: series),
                        isEditMode: isEditMode && isPremium,
                        isLocked: !isPremium,
                        onRemove: { onRemove(series) }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "icloud")
                .font(.system(size: 30, weight: .light))
                .foregroundColor(.white.opacity(0.25))
            Text("Nothing backed up to iCloud yet")
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
