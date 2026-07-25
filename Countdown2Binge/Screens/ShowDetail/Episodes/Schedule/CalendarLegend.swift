//
//  CalendarLegend.swift
//  Countdown2Binge
//
//  Legend explaining calendar cell states.
//

import SwiftUI

struct CalendarLegend: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(legendItems, id: \.label) { item in
                legendItem(icon: item.icon, label: item.label)
                if item.label != legendItems.last?.label {
                    Spacer(minLength: 8)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 2)
    }

    private var legendItems: [LegendItem] {
        [
            LegendItem(icon: .tealSquare, label: String(localized: "legend_aired")),
            LegendItem(icon: .ring, label: String(localized: "legend_up_next")),
            LegendItem(icon: .lock, label: String(localized: "legend_not_yet_aired")),
            LegendItem(icon: .star, label: String(localized: "legend_finale")),
            LegendItem(icon: .play, label: String(localized: "legend_start_today"))
        ]
    }

    @ViewBuilder
    private func legendItem(icon: LegendIcon, label: String) -> some View {
        HStack(spacing: 6) {
            iconView(for: icon)
            Text(label)
                .font(.custom(CustomFont.jetbrains.regular, size: 8))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)
        }
    }

    @ViewBuilder
    private func iconView(for icon: LegendIcon) -> some View {
        switch icon {
        case .tealSquare:
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.c2bTeal)
                .frame(width: 11, height: 11)

        case .ring:
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.c2bTealBright, lineWidth: 1.5)
                .frame(width: 11, height: 11)
                .shadow(color: Color.c2bTeal.opacity(0.18), radius: 2)

        case .lock:
            Image(systemName: "lock.fill")
                .font(.system(size: 9))
                .foregroundColor(.c2bMuted)
                .frame(width: 11, height: 11)

        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(.c2bTealBright)
                .frame(width: 12, height: 12)

        case .play:
            Image(systemName: "play.fill")
                .font(.system(size: 9))
                .foregroundColor(.c2bTealBright)
                .frame(width: 11, height: 11)
        }
    }
}

// MARK: - Models

private enum LegendIcon {
    case tealSquare
    case ring
    case lock
    case star
    case play
}

private struct LegendItem {
    let icon: LegendIcon
    let label: String
}

// MARK: - Preview

#Preview {
    VStack {
        CalendarLegend()
    }
    .padding(22)
    .background(Color.c2bBackground)
}
