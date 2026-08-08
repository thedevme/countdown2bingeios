//
//  SeriesListRow.swift
//  Countdown2Binge
//
//  Individual row in the timeline list view showing:
//  - Series name + Season badge (e.g., "ECHO 7 S2")
//  - Status line in accent color (based on showState)
//  - Optional third line for Anticipated ("Last updated X hours ago")
//

import SwiftUI

struct SeriesListRow: View {
    let series: Series
    var accentColor: Color = .c2bTealBright

    // MARK: - Computed Properties

    /// The real season the engine is pointing at (announced next season for
    /// anticipated shows). Nil when there is no real season in the data — the row
    /// then shows no season badge rather than a fabricated `numberOfSeasons + 1`.
    private var seasonNumber: Int? {
        series.currentSeason?.seasonNumber
    }

    private var statusText: String {
        switch series.showState {
        case .premieringSoon:
            if let days = series.daysUntilPremiere {
                if days == 0 {
                    return String(localized: "timeline_row_premieres_today")
                } else if days == 1 {
                    return String(localized: "timeline_row_premieres_tomorrow")
                } else {
                    return String(format: NSLocalizedString("timeline_row_premieres_in %lld", comment: ""), days)
                }
            }
            return String(localized: "timeline_row_premiering_soon")

        case .airing:
            if let days = series.daysUntilFinale {
                return String(format: NSLocalizedString("timeline_row_finale_in %lld", comment: ""), days)
            }
            return String(localized: "timeline_row_now_airing")

        case .pending:
            if let days = series.daysUntilPremiere, days > 0 {
                return String(format: NSLocalizedString("timeline_row_premieres_in %lld", comment: ""), days)
            }
            return String(localized: "timeline_row_premiere_set")

        case .anticipated:
            return String(localized: "timeline_row_release_tba")

        case .bingeReady:
            return String(localized: "timeline_row_binge_ready")
        }
    }

    /// For Anticipated shows, show when data was last updated
    private var lastUpdatedText: String? {
        guard series.showState == .anticipated else { return nil }

        let lastUpdated = series.lastUpdated
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Last updated \(formatter.localizedString(for: lastUpdated, relativeTo: Date()))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Row 1: Series name + Season badge
            HStack(spacing: 6) {
                Text(series.name.uppercased())
                    .font(.custom(.oswald.bold, size: 15))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let seasonNumber {
                    Text("S\(seasonNumber)")
                        .font(.custom(.oswald.light, size: 15))
                        .foregroundColor(.c2bMuted)
                }
            }

            // Row 2: Status line
            Text(statusText)
                .font(.custom(.jetbrains.bold, size: 8))
                .foregroundColor(accentColor)
                .tracking(0.5)

            // Row 3: Last updated (Anticipated only)
            if let lastUpdated = lastUpdatedText {
                Text(lastUpdated)
                    .font(.custom(.jetbrains.regular, size: 7))
                    .foregroundColor(.c2bMuted)
                    .tracking(0.3)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        // Mock previews would go here
        Text("SeriesListRow Preview")
            .foregroundColor(.white)
        Text("Requires Series model instance")
            .foregroundColor(.c2bMuted)
    }
    .padding()
    .background(Color.c2bBackground)
}
