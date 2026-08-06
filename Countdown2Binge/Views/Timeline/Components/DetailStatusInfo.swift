//
//  DetailStatusInfo.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailStatusInfo: View {
    let show: ShowData
    let isReady: Bool
    var isAnticipated: Bool = false
    let phaseTone: Color
    let phaseLabel: String

    /// Get the relevant date based on show state
    private var displayDate: Date? {
        if isAnticipated {
            // For anticipated seasons, show the premiere date
            return show.anticipatedSeason?.airDate ?? show.anticipatedSeason?.premiereDate
        } else if show.showState == .airing || show.showState == .pending {
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

    private var statusText: String {
        if isReady {
            return String(localized: "phase_ready_to_binge")
        } else if isAnticipated {
            return String(localized: "status_until_premiere")
        } else {
            return String(localized: "status_until_binge_ready")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(statusText)
                .font(.custom(.jetbrains.bold, size: 9.5))
                .foregroundColor(phaseTone)
                .tracking(1.6)
                .textCase(.uppercase)

            if let date = displayDate {
                Text(date.localizedFullDate)
                    .font(.system(size: 13))
                    .foregroundColor(.c2bDim)
                    .padding(.top, 6)
            }

            DetailPhasePill(label: phaseLabel, tone: phaseTone, isReady: isReady)
                .padding(.top, 10)
        }
    }
}
