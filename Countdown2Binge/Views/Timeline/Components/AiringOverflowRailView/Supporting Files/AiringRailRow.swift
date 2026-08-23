//
//  AiringRailRow.swift
//  Countdown2Binge
//
//  Molecule — one show on the overflow rail. No card box: the poster is the
//  object. Title + inline season on one line, network beneath, count on the
//  right. Ported from "Timeline Overflow.html" (example C · Rail), `.r`.
//
//  The leading 26pt gutter holds this row's rail node, centred on the spine
//  the parent draws — so the line never crosses the digits.
//

import SwiftUI

struct AiringRailRow: View {
    let title: String
    let seasonNumber: Int?
    let network: String
    let posterURL: URL?
    /// Already resolved to the active unit by the parent.
    let count: Int
    let unit: CountdownDisplayMode
    /// Node pops in after the rail has drawn past it.
    let isNodeVisible: Bool
    let onTap: () -> Void

    private var unitLabel: String {
        switch unit {
        case .days:
            return String(localized: "unit_days")
        case .episodes:
            return count == 1
                ? String(localized: "unit_episode")
                : String(localized: "unit_episodes")
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                nodeGutter

                HStack(spacing: 13) {
                    PosterView(url: posterURL, width: 44, cornerRadius: 7)
                        .frame(width: 44, height: 66)
                        .shadow(color: .black.opacity(0.55), radius: 10, x: 0, y: 8)

                    VStack(alignment: .leading, spacing: 7) {
                        titleLine
                        Text(network)
                            .font(.custom(.jetbrains.regular, size: 8))
                            .tracking(1.12)
                            .textCase(.uppercase)
                            .foregroundColor(.c2bMuted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: 5) {
                        Text("\(count)")
                            .font(.custom(.oswald.bold, size: 30))
                            .foregroundColor(.white)
                        Text(unitLabel)
                            .font(.custom(.jetbrains.regular, size: 6.5))
                            .tracking(0.91)
                            .textCase(.uppercase)
                            .foregroundColor(.c2bMuted)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 26pt gutter with a 10pt node centred on the rail axis (x = 6).
    private var nodeGutter: some View {
        Circle()
            .fill(Color.c2bTealBright)
            .frame(width: 10, height: 10)
            .scaleEffect(isNodeVisible ? 1 : 0)
            .padding(.leading, 1)
            .frame(width: 26, alignment: .leading)
    }

    private var titleLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.custom(.oswald.bold, size: 16))
                .textCase(.uppercase)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)

            if let seasonNumber {
                (
                    Text(String(localized: "season_abbrev"))
                        .font(.custom(.oswald.bold, size: 12))
                    + Text("\(seasonNumber)")
                        .font(.custom(.oswald.light, size: 12))
                )
                .foregroundColor(.white.opacity(0.6))
                .fixedSize()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AiringRailRow(
            title: "Forward Hold", seasonNumber: 3, network: "PRIME", posterURL: nil,
            count: 21, unit: .days, isNodeVisible: true, onTap: {}
        )
        AiringRailRow(
            title: "Blackwater Point", seasonNumber: 2, network: "NETFLIX", posterURL: nil,
            count: 1, unit: .episodes, isNodeVisible: true, onTap: {}
        )
    }
    .padding()
    .background(Color.c2bBackground)
}
