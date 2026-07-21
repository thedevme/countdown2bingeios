//
//  DetailStatusInfo.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailStatusInfo: View {
    let show: ShowData
    let isReady: Bool
    let phaseTone: Color
    let phaseLabel: String

    /// Get the finale date (last episode's air date) for airing shows,
    /// or premiere date for premiering soon shows
    private var finaleDate: Date? {
        if show.timelineCategory == .airingNow {
            // For airing shows, show the finale date (last episode)
            return show.currentSeason?.episodes
                .filter { $0.airDate != nil }
                .max(by: { $0.episodeNumber < $1.episodeNumber })?
                .airDate
        } else {
            // For premiering soon, show the premiere date
            return show.currentSeason?.airDate ?? show.daysUntilPremiere.flatMap { _ in
                show.currentSeason?.episodes.first?.airDate
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text((isReady ? "Ready to binge" : "Until binge ready").uppercased())
                .font(.custom(.jetbrains.bold, size: 9.5))
                .foregroundColor(phaseTone)
                .tracking(1.6)

            if let date = finaleDate {
                let formatter = DateFormatter()
                let _ = formatter.dateFormat = "MMM d, yyyy"
                Text(formatter.string(from: date))
                    .font(.system(size: 13))
                    .foregroundColor(.c2bDim)
                    .padding(.top, 6)
            }

            DetailPhasePill(label: phaseLabel, tone: phaseTone, isReady: isReady)
                .padding(.top, 10)
        }
    }
}
