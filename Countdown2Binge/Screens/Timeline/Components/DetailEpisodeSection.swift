//
//  DetailEpisodeSection.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailEpisodeSection: View {
    let show: ShowData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("0/\(show.currentSeason?.episodeCount ?? 0) WATCHED")
                    .font(.custom(.jetbrains.bold, size: 9.5))
                    .foregroundColor(.c2bMuted)
                    .tracking(1.4)

                Spacer()

                Button {
                    // Mark all watched
                } label: {
                    Text("Mark all watched")
                        .font(.custom(.jetbrains.bold, size: 8.5))
                        .foregroundColor(.c2bDim)
                        .textCase(.uppercase)
                        .tracking(1.0)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
            }

            if let overview = show.overview, !overview.isEmpty {
                Text(overview)
                    .font(.system(size: 12.5))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(4)
                    .lineLimit(3)
            }

            Text("Episodes coming soon...")
                .font(.custom(.jetbrains.regular, size: 10))
                .foregroundColor(.c2bMuted)
                .padding(.top, 8)
        }
        .padding(.top, 22)
    }
}
