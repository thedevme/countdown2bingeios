//
//  ProfileTrackedStats.swift
//  Countdown2Binge
//
//  Stats grid showing episodes, seasons, watch time, and shows followed.
//

import SwiftUI

struct ProfileTrackedStats: View {
    let shows: [Series]

    private var episodeCount: Int {
        shows.reduce(0) { $0 + $1.numberOfEpisodes }
    }

    private var seasonCount: Int {
        shows.reduce(0) { $0 + $1.numberOfSeasons }
    }

    private var showCount: Int {
        shows.count
    }

    /// Total watch time formatted as "XD YH"
    private var watchTimeFormatted: String {
        // Calculate total minutes from episodes × average runtime (45 min default)
        let avgRuntimeMinutes = 45
        let totalMinutes = shows.reduce(0) { total, show in
            let episodes = show.numberOfEpisodes
            return total + (episodes * avgRuntimeMinutes)
        }

        let hours = totalMinutes / 60
        let days = hours / 24
        let remainingHours = hours % 24

        if days > 0 {
            return "\(days)D \(remainingHours)H"
        } else if hours > 0 {
            return "\(hours)H"
        } else {
            return "\(totalMinutes)M"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("profile_tracked_header")
                .font(.custom(.jetbrains.regular, size: 9))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)

            // 2x2 Stats Grid
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    ProfileStatCard(
                        value: "\(episodeCount)",
                        label: String(localized: "profile_stat_episodes")
                    )
                    ProfileStatCard(
                        value: "\(seasonCount)",
                        label: String(localized: "profile_stat_seasons")
                    )
                }

                HStack(spacing: 10) {
                    ProfileStatCard(
                        value: watchTimeFormatted,
                        label: String(localized: "profile_stat_show_time")
                    )
                    ProfileStatCard(
                        value: "\(showCount)",
                        label: String(localized: "profile_stat_shows_followed")
                    )
                }
            }
        }
    }
}

#Preview {
    ProfileTrackedStats(shows: [])
        .padding(20)
        .background(Color.c2bBackground)
        .preferredColorScheme(.dark)
}
