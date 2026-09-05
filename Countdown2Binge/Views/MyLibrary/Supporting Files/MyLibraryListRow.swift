//
//  MyLibraryListRow.swift
//  Countdown2Binge
//
//  One row of My Library's list view — poster, title, progress bar +
//  episode/sync caption, and a large percent (or the remove button in
//  edit mode) trailing.
//

import SwiftUI

struct MyLibraryListRow: View {
    let posterURL: URL?
    let title: String
    let watchedEpisodes: Int
    let totalEpisodes: Int
    let badgeVariant: StatusBadgeVariant
    let isEditMode: Bool
    let onRemove: () -> Void

    private var completionPercent: Int {
        guard totalEpisodes > 0 else { return 0 }
        return Int((Double(watchedEpisodes) / Double(totalEpisodes) * 100).rounded())
    }

    var body: some View {
        HStack(spacing: 14) {
            // Explicit width AND height — a width-only frame here lets
            // `.aspectRatio(.fit)` resolve against this HStack's own
            // (much shorter) proposed height from the text block beside
            // it, squashing the poster into a slim rectangle instead of a
            // real 2:3 shape. Fixing both dimensions makes it a proper
            // poster regardless of the row's height.
            PosterView(url: posterURL, width: 44, height: 66, cornerRadius: 7)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom(.jetbrains.regular, size: 12))
                    .foregroundColor(.c2bText)
                    .lineLimit(1)

                // Bar + meta row grouped in their own VStack so the 6pt
                // gap between them is independent of the 8pt title→bar
                // gap above (the outer VStack's own spacing).
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.13))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.c2bTeal)
                                .frame(width: geo.size.width * CGFloat(completionPercent) / 100)
                        }
                    }
                    .frame(height: 4)

                    HStack(spacing: 6) {
                        Text("\(watchedEpisodes)/\(totalEpisodes) EPISODES")
                            .font(.custom(.jetbrains.regular, size: 7.5))
                            .foregroundColor(.white.opacity(0.4))

                        Text("·")
                            .foregroundColor(.white.opacity(0.25))

                        HStack(spacing: 3) {
                            Image(systemName: badgeVariant.icon)
                                .font(.system(size: 6.5, weight: .bold))
                            Text(badgeVariant.text)
                                .font(.custom(.jetbrains.bold, size: 6.5))
                        }
                        .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            // Percentage (or the remove button in edit mode), right-
            // aligned in its own 44px column.
            Group {
                if isEditMode {
                    CircleXButton(action: onRemove)
                } else {
                    Text("\(completionPercent)%")
                        .font(.custom(.oswald.bold, size: 19))
                        .foregroundColor(.c2bTeal)
                }
            }
            .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    VStack(spacing: 0) {
        MyLibraryListRow(
            posterURL: nil, title: "Echo 7", watchedEpisodes: 14, totalEpisodes: 18,
            badgeVariant: .localOnly, isEditMode: false, onRemove: {}
        )
        Divider().background(Color.white.opacity(0.07))
        MyLibraryListRow(
            posterURL: nil, title: "Forward Hold", watchedEpisodes: 21, totalEpisodes: 24,
            badgeVariant: .synced, isEditMode: true, onRemove: {}
        )
    }
    .padding(.horizontal, 20)
    .background(Color.c2bBackground)
}
