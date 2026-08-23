//
//  AiringOverflowBadge.swift
//  Countdown2Binge
//
//  Molecule — the tappable bar that opens the overflow rail: a fan of mini
//  posters, "+N MORE AIRING", a timing sub-line, and a chevron that flips.
//  Ported from "Timeline Overflow.html" (example C · Rail), `.badge`.
//

import SwiftUI

struct AiringOverflowBadge: View {
    /// Posters for the fan — first four of the hidden shows.
    let posterURLs: [URL?]
    let hiddenCount: Int
    /// Countdown of the soonest hidden show, in the active unit.
    let nextValue: Int
    /// Countdown of the furthest-out hidden show, in the active unit.
    let lastValue: Int
    let unit: CountdownDisplayMode
    let isOpen: Bool
    let onTap: () -> Void

    private var title: String {
        isOpen
            ? String(localized: "airing_rail_hide \(hiddenCount)")
            : String(localized: "airing_rail_more \(hiddenCount)")
    }

    private var subtitle: String {
        switch unit {
        case .days:     return String(localized: "airing_rail_next_days \(nextValue) \(lastValue)")
        case .episodes: return String(localized: "airing_rail_next_eps \(nextValue) \(lastValue)")
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 11) {
                posterFan

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.custom(.oswald.bold, size: 14))
                        .textCase(.uppercase)
                        .foregroundColor(.c2bTealBright)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.custom(.jetbrains.regular, size: 7.5))
                        .tracking(0.75)
                        .textCase(.uppercase)
                        .foregroundColor(.c2bMuted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.c2bTealBright)
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(isOpen ? Color.c2bTeal.opacity(0.09) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(isOpen ? Color.c2bTealLine : Color.white.opacity(0.10), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Up to four 19×28 posters, each tucked 7pt under the one before it.
    private var posterFan: some View {
        HStack(spacing: -7) {
            ForEach(Array(posterURLs.prefix(4).enumerated()), id: \.offset) { _, url in
                PosterView(url: url, width: 19, cornerRadius: 3)
                    .frame(width: 19, height: 28)
                    .brightness(-0.18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(hex: "#0b0b0c"), lineWidth: 1)
                    )
            }
        }
        .fixedSize()
    }
}

#Preview {
    VStack(spacing: 12) {
        AiringOverflowBadge(
            posterURLs: [nil, nil, nil, nil], hiddenCount: 9,
            nextValue: 4, lastValue: 118, unit: .days, isOpen: false, onTap: {}
        )
        AiringOverflowBadge(
            posterURLs: [nil, nil], hiddenCount: 2,
            nextValue: 1, lastValue: 17, unit: .episodes, isOpen: true, onTap: {}
        )
    }
    .padding()
    .background(Color.c2bBackground)
}
