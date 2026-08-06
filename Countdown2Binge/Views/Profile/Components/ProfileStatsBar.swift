//
//  ProfileStatsBar.swift
//  Countdown2Binge
//
//  Stats bar showing following count, ready count, and episodes.
//

import SwiftUI

struct ProfileStatsBar: View {
    let followingCount: Int
    let readyCount: Int
    let episodeCount: Int

    var body: some View {
        HStack(spacing: 0) {
            StatItem(
                value: String(format: "%02d", followingCount),
                label: String(localized: "profile_stat_following")
            )

            Divider()
                .frame(width: 1)
                .background(Color.white.opacity(0.08))

            StatItem(
                value: String(format: "%02d", readyCount),
                label: String(localized: "profile_stat_ready_now")
            )

            Divider()
                .frame(width: 1)
                .background(Color.white.opacity(0.08))

            StatItem(
                value: "\(episodeCount)",
                label: String(localized: "profile_stat_episodes")
            )
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.custom(.oswald.bold, size: 24))
                .foregroundColor(.c2bTealBright)

            Text(label)
                .font(.custom(.jetbrains.regular, size: 8))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

#Preview {
    ProfileStatsBar(followingCount: 12, readyCount: 3, episodeCount: 847)
        .padding(20)
        .background(Color.c2bBackground)
        .preferredColorScheme(.dark)
}
