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

    private var seasonNumber: Int {
        if let currentSeason = series.currentSeason {
            return currentSeason.seasonNumber
        }
        // For anticipated, show next expected season
        return series.numberOfSeasons + 1
    }

    private var statusText: String {
        switch series.showState {
        case .premieringSoon:
            if let days = series.daysUntilPremiere {
                if days == 0 {
                    return "PREMIERES TODAY"
                } else if days == 1 {
                    return "PREMIERES TOMORROW"
                } else {
                    return "PREMIERES IN \(days) DAYS"
                }
            }
            return "PREMIERING SOON"

        case .airing:
            if let days = series.daysUntilFinale {
                return "FINALE IN \(days) DAYS"
            }
            return "NOW AIRING"

        case .pending:
            if let days = series.daysUntilPremiere, days > 0 {
                return "PREMIERES IN \(days) DAYS"
            }
            return "PREMIERE SET · FINALE DATE TBA"

        case .anticipated:
            return "RELEASE DATES TBA"

        case .bingeReady:
            return "BINGE READY"
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

                Text("S\(seasonNumber)")
                    .font(.custom(.oswald.light, size: 15))
                    .foregroundColor(.c2bMuted)
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
