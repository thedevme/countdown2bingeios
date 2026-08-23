//
//  AiringOverflowRailView.swift
//  Countdown2Binge
//
//  Every airing show the hero stack isn't already showing, on a drawn rail.
//  Ported from "Timeline Overflow.html" — example C · Rail.
//
//  Four parts, top to bottom: the Days | Episodes toggle paired with "View
//  entire timeline", the tappable overflow badge, and — once open — a 2pt
//  spine that draws itself downward while the rows drop in behind it, each
//  with a node centred on the line.
//
//  Reads Series directly (R4). Every number is show-axis (air dates only, R8);
//  nothing here writes, so there's no SeriesManager involvement.
//

import SwiftUI
import SwiftData

struct AiringOverflowRailView: View {
    /// Airing shows NOT already in the hero stack, soonest finale first.
    let series: [Series]
    let onSelect: (Series) -> Void
    let onViewAll: () -> Void
    /// Owned by the screen: the toggle drives the hero ticker too.
    @Binding var unit: CountdownDisplayMode

    @State private var isOpen = false

    private let rowSpacing: CGFloat = 16
    /// Rail axis: 2pt line at x = 5, so its centre lands on 6 — the node's.
    private let railInset: CGFloat = 5

    /// No airing shows beyond the hero — the rail has nothing to list, but the
    /// "View entire timeline" action still has to be reachable.
    private var hasOverflow: Bool { !series.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            controlsRow
                .padding(.bottom, hasOverflow ? 9 : 0)

            if hasOverflow {
                AiringOverflowBadge(
                    posterURLs: series.prefix(4).map(\.posterURL),
                    hiddenCount: series.count,
                    nextValue: count(for: series.first),
                    lastValue: count(for: series.last),
                    unit: unit,
                    isOpen: isOpen,
                    onTap: {
                        withAnimation(.easeOut(duration: 0.3)) { isOpen.toggle() }
                    }
                )

                if isOpen {
                    railList
                        .padding(.top, 14)
                }
            }
        }
    }

    // MARK: - Controls

    private var controlsRow: some View {
        HStack(spacing: 10) {
            AiringUnitToggle(unit: $unit)

            Spacer(minLength: 0)

            Button(action: onViewAll) {
                HStack(spacing: 6) {
                    Text(String(localized: "button_view_timeline"))
                        .font(.custom(.jetbrains.bold, size: 8))
                        .tracking(0.8)
                        .textCase(.uppercase)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 7, weight: .black))
                }
                .foregroundColor(.c2bDim)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Rail + rows

    private var railList: some View {
        VStack(spacing: rowSpacing) {
            ForEach(Array(series.enumerated()), id: \.element.id) { index, show in
                AiringRailRow(
                    title: show.name,
                    seasonNumber: show.currentSeason?.seasonNumber,
                    network: show.networks.first?.name ?? "",
                    posterURL: show.posterURL,
                    count: count(for: show),
                    unit: unit,
                    isNodeVisible: isOpen,
                    onTap: { onSelect(show) }
                )
                .opacity(isOpen ? 1 : 0)
                .offset(y: isOpen ? 0 : -26)
                .animation(
                    .spring(response: 0.44, dampingFraction: 0.72)
                        .delay(Double(index) * 0.10),
                    value: isOpen
                )
            }
        }
        // The spine draws first, top-down, behind the rows.
        .background(alignment: .top) {
            RoundedRectangle(cornerRadius: 1)
                .fill(
                    LinearGradient(
                        colors: [.c2bTealBright, Color.c2bTeal.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .scaleEffect(y: isOpen ? 1 : 0, anchor: .top)
                .animation(.easeOut(duration: 0.6), value: isOpen)
                .padding(.leading, railInset)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Numbers

    /// Days to the finale, or episodes still to air — whichever unit is active.
    /// Both come from the engine, so the rail and the hero ticker above always
    /// agree on what a number means.
    private func count(for show: Series?) -> Int {
        guard let show else { return 0 }
        switch unit {
        case .days:     return show.daysUntilFinale ?? 0
        case .episodes: return show.episodesUntilFinale ?? 0
        }
    }
}
