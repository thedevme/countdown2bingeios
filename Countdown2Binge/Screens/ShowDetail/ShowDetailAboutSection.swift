//
//  ShowDetailAboutSection.swift
//  Countdown2Binge
//
//  About section with show metadata.
//

import SwiftUI

struct ShowDetailAboutSection: View {
    let show: ShowData

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            Text("ABOUT")
                .font(.custom(.jetbrains.bold, size: 9.5))
                .foregroundColor(.c2bMuted)
                .tracking(1.4)

            // Metadata rows
            VStack(spacing: 0) {
                if !show.genreNames.isEmpty {
                    AboutRow(label: "Genre", value: show.genreNames.joined(separator: ", "))
                }

                if show.numberOfSeasons > 0 {
                    AboutRow(label: "Seasons", value: "\(show.numberOfSeasons)")
                }

                if show.numberOfEpisodes > 0 {
                    AboutRow(label: "Episodes", value: "\(show.numberOfEpisodes)")
                }

                AboutRow(label: "Status", value: show.status.displayName)

                if let network = show.primaryNetwork?.name {
                    AboutRow(label: "Network", value: network)
                }

                if let year = show.yearString {
                    AboutRow(label: "First Aired", value: year)
                }

                if let rating = show.voteAverage, rating > 0 {
                    AboutRow(label: "Rating", value: String(format: "%.1f / 10", rating))
                }
            }
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .padding(.top, 22)
    }
}

// MARK: - About Row
private struct AboutRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label.uppercased())
                .font(.custom(.jetbrains.bold, size: 9))
                .foregroundColor(.c2bMuted)
                .tracking(1.0)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.c2bText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
