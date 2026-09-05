//
//  MyLibraryShowList.swift
//  Countdown2Binge
//
//  List-view alternative to MyLibraryShowGrid — same data, same
//  edit/remove/select wiring, one row per show with a hairline divider
//  between rows instead of a 3-column grid.
//

import SwiftUI

struct MyLibraryShowList: View {
    let shows: [Series]
    let isPremium: Bool
    let isEditMode: Bool
    let onRemove: (Series) -> Void
    var onSelect: (Series) -> Void = { _ in }

    var body: some View {
        if shows.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                ForEach(Array(shows.enumerated()), id: \.element.id) { index, series in
                    MyLibraryListRow(
                        posterURL: series.posterURL,
                        title: series.name,
                        watchedEpisodes: series.overallWatchedEpisodeCount,
                        totalEpisodes: series.overallEpisodeCount,
                        badgeVariant: badgeVariant(for: series),
                        isEditMode: isEditMode,
                        onRemove: { onRemove(series) }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isEditMode else { return }
                        onSelect(series)
                    }

                    if index < shows.count - 1 {
                        Divider().background(Color.white.opacity(0.07))
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
