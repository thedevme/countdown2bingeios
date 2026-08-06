//
//  TimelineSectionListView.swift
//  Countdown2Binge
//
//  A unified list view component for all timeline sections:
//  - Premiering Soon (teal)
//  - Pending (yellow)
//  - Anticipated (teal)
//
//  Automatically derives styling (colors, stroke, background) from the
//  series' showState. Pass in the series list and it handles the rest.
//
//  Usage:
//    TimelineSectionListView(seriesList: premieringSoonShows)
//    TimelineSectionListView(seriesList: pendingShows)
//    TimelineSectionListView(seriesList: anticipatedShows, maxCount: nil) // Full timeline
//

import SwiftUI

struct TimelineSectionListView: View {
    let seriesList: [Series]
    let maxCount: Int?

    /// Initialize with series list and optional max count
    /// - Parameters:
    ///   - seriesList: Array of Series to display
    ///   - maxCount: Maximum number of series to show (nil = unlimited, default = 3)
    init(seriesList: [Series], maxCount: Int? = 3) {
        self.seriesList = seriesList
        self.maxCount = maxCount
    }

    // MARK: - Derived State

    /// Get section state from the first series (all series in a section share the same state)
    private var sectionState: ShowState {
        seriesList.first?.showState ?? .anticipated
    }

    /// Series to display (respects maxCount)
    private var displayedSeries: [Series] {
        if let max = maxCount {
            return Array(seriesList.prefix(max))
        }
        return seriesList
    }

    // MARK: - Styling

    /// Teal color used for premiering/pending cards: #2DD4BF
    private let tealColor = Color(red: 45/255, green: 212/255, blue: 191/255)

    /// Amber color for pending accent: #E9A944
    private let amberColor = Color(red: 233/255, green: 169/255, blue: 68/255)

    /// Muted color for anticipated: #71717A
    private let mutedColor = Color(red: 113/255, green: 113/255, blue: 122/255)

    private var accentColor: Color {
        switch sectionState {
        case .premieringSoon, .airing, .bingeReady:
            return tealColor
        case .pending:
            return amberColor
        case .anticipated:
            return mutedColor
        }
    }

    /// Stroke color - teal at 40% for premiering/pending, white at 9% for anticipated
    private var strokeColor: Color {
        switch sectionState {
        case .anticipated:
            return Color.white.opacity(0.09)
        default:
            // Teal stroke: rgba(45, 212, 191, 0.40)
            return tealColor.opacity(0.40)
        }
    }

    /// Left edge accent line color
    private var leftEdgeColor: Color? {
        switch sectionState {
        case .premieringSoon, .airing, .bingeReady:
            return tealColor.opacity(0.40)
        case .pending:
            return amberColor.opacity(0.40)
        case .anticipated:
            return nil
        }
    }

    /// Background - teal gradient for premiering/pending, flat white 3% for anticipated
    private var backgroundGradient: LinearGradient {
        switch sectionState {
        case .anticipated:
            // Flat background: rgba(255, 255, 255, 0.03)
            return LinearGradient(
                colors: [Color.white.opacity(0.03), Color.white.opacity(0.03)],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            // Teal gradient: 100° from 10% to 2% alpha
            // 100° is near-horizontal tilting slightly downward left→right
            return LinearGradient(
                colors: [tealColor.opacity(0.10), tealColor.opacity(0.02)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var isGrayscale: Bool {
        sectionState == .anticipated
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Left: Stacked posters
            TimelineStackedPosterView(
                seriesList: displayedSeries,
                isGrayscale: isGrayscale
            )
            .padding(.top, 4)

            // Right: Content
            VStack(alignment: .leading, spacing: 10) {
                // Header with count
                SeriesCountHeader(
                    count: seriesList.count,
                    accentColor: accentColor
                )

                // Series rows - 9px spacing between shows
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(displayedSeries) { series in
                        SeriesListRow(series: series, accentColor: accentColor)
                    }
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            ZStack(alignment: .leading) {
                backgroundGradient

                // Left edge accent line
                if let edgeColor = leftEdgeColor {
                    Rectangle()
                        .fill(edgeColor)
                        .frame(width: 2)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(strokeColor, lineWidth: 1)
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("TimelineSectionListView")
                .foregroundColor(.white)
                .font(.headline)

            Text("Premiering Soon / Pending / Anticipated")
                .foregroundColor(.c2bMuted)
                .font(.caption)

            Text("Requires Series model instances")
                .foregroundColor(.c2bMuted)
                .font(.caption)
        }
        .padding()
    }
    .background(Color.c2bBackground)
}
