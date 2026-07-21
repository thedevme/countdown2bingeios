//
//  ShowDetailSeasonBar.swift
//  Countdown2Binge
//
//  Season selector bar with status badge (NEW/AIRING/READY).
//

import SwiftUI

enum ShowDetailSeasonStatus: String {
    case new = "NEW"
    case airing = "AIRING"
    case ready = "READY"
}

struct ShowDetailSeasonBar: View {
    let seasonNumber: Int
    let status: ShowDetailSeasonStatus?
    let episodeInfo: String

    var body: some View {
        HStack(spacing: 10) {
            // Season label
            Text("Season \(seasonNumber)")
                .font(.custom(.oswald.bold, size: 20))
                .foregroundColor(.white)

            // Status badge
            if let status = status {
                Text(status.rawValue)
                    .font(.custom(.jetbrains.bold, size: 8))
                    .tracking(1.1)
                    .foregroundColor(.c2bTealBright)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.c2bTeal.opacity(0.12))
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.c2bTealLine, lineWidth: 1)
                    )
            }

            Spacer()

            // Episode count
            Text(episodeInfo.uppercased())
                .font(.custom(.jetbrains.regular, size: 9.5))
                .tracking(0.9)
                .foregroundColor(.c2bMuted)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 12) {
            ShowDetailSeasonBar(seasonNumber: 2, status: .new, episodeInfo: "8 episodes")
            ShowDetailSeasonBar(seasonNumber: 1, status: .airing, episodeInfo: "5/10 out")
            ShowDetailSeasonBar(seasonNumber: 3, status: .ready, episodeInfo: "all 10 out")
            ShowDetailSeasonBar(seasonNumber: 4, status: nil, episodeInfo: "TBA")
        }
        .padding()
    }
}
