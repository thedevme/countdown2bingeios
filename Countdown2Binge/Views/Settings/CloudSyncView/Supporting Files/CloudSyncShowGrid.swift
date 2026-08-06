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

    private func badgeVariant(for series: Series) -> StatusBadgeVariant {
        if !isPremium {
            return .localOnly
        }
        return series.isSynced ? .synced : .syncing
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()

        Text("Preview requires Series data")
            .foregroundColor(.white.opacity(0.5))
    }
}
