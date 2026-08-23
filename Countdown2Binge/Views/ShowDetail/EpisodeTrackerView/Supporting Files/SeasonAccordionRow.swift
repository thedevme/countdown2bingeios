//
//  SeasonAccordionRow.swift
//  Countdown2Binge
//
//  Molecule — one season in the tracker's accordion. The season plate IS the
//  header: tap it to open or close the season. Closed, the card carries a
//  progress bar along its bottom edge; open, it reveals the episode tracker.
//
//  The plate renders bare here — this card owns the surface, corner radius and
//  border so the two don't nest into a double-outline.
//

import SwiftUI

struct SeasonAccordionRow<Content: View>: View {
    let seasonNumber: Int
    let watchedCount: Int
    let totalEpisodes: Int
    var isCurrent: Bool = false
    let isExpanded: Bool
    let onTap: () -> Void
    @ViewBuilder var content: () -> Content

    /// Every episode watched — user axis only (R8).
    private var isFullyWatched: Bool {
        totalEpisodes > 0 && watchedCount == totalEpisodes
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                SeasonPlate(
                    seasonNumber: seasonNumber,
                    watchedCount: watchedCount,
                    totalEpisodes: totalEpisodes,
                    isComplete: isFullyWatched,
                    isCurrent: isCurrent
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .padding(.horizontal, 13)
                    .padding(.bottom, 14)
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )
            } else {
                // Collapsed only — the open card shows the tick meter instead.
                progressBar
            }
        }
        .background(isExpanded ? Color.c2bTeal.opacity(0.05) : Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isExpanded ? Color.c2bTealLine : Color.white.opacity(0.09), lineWidth: 1)
        )
    }

    // MARK: - Season progress

    /// Share of the season watched, 0...1.
    private var watchedFraction: Double {
        guard totalEpisodes > 0 else { return 0 }
        return min(1, Double(watchedCount) / Double(totalEpisodes))
    }

    /// Hairline fill across the bottom edge of the collapsed card.
    @ViewBuilder
    private var progressBar: some View {
        if totalEpisodes > 0 {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.07))

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.c2bTeal, .c2bTealBright],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * watchedFraction)
                }
            }
            .frame(height: 3)
            .animation(.easeOut(duration: 0.25), value: watchedFraction)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        SeasonAccordionRow(
            seasonNumber: 12, watchedCount: 10, totalEpisodes: 10,
            isExpanded: false, onTap: {}
        ) { EmptyView() }

        SeasonAccordionRow(
            seasonNumber: 13, watchedCount: 3, totalEpisodes: 10,
            isExpanded: true, onTap: {}
        ) {
            Text("tracker body")
                .foregroundColor(.c2bDim)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        SeasonAccordionRow(
            seasonNumber: 14, watchedCount: 0, totalEpisodes: 10,
            isExpanded: false, onTap: {}
        ) { EmptyView() }
    }
    .padding()
    .background(Color.c2bBackground)
}
