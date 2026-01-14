//
//  CompactPosterRow.swift
//  Countdown2Binge
//

import SwiftUI

/// Compact vertical stack of portrait posters shown when section is collapsed
struct CompactPosterRow: View {
    let shows: [Show]
    let style: TimelineCardStyle
    let onShowTap: (Show) -> Void

    private var accentColor: Color {
        switch style {
        case .endingSoon, .premiering:
            return Color(red: 0.45, green: 0.90, blue: 0.70) // Teal
        case .anticipated:
            return Color(white: 0.4) // Muted gray
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            let displayShows = Array(shows.prefix(3))
            ForEach(Array(displayShows.enumerated()), id: \.element.id) { index, show in
                CompactPosterCard(
                    show: show,
                    style: style,
                    isFirst: index == 0,
                    isLast: index == displayShows.count - 1
                )
                .frame(height: 320)
                .onTapGesture {
                    onShowTap(show)
                }
            }
        }
    }
}

/// Individual compact poster card with timeline connector
private struct CompactPosterCard: View {
    let show: Show
    let style: TimelineCardStyle
    let isFirst: Bool
    let isLast: Bool

    private var accentColor: Color {
        switch style {
        case .endingSoon, .premiering:
            return Color(red: 0.45, green: 0.90, blue: 0.70) // Teal
        case .anticipated:
            return Color(white: 0.4) // Muted gray
        }
    }

    private var countdownText: String {
        switch style {
        case .endingSoon:
            if let days = show.daysUntilFinale {
                return String(format: "%02d", days)
            }
            return "--"
        case .premiering:
            if let days = show.daysUntilPremiere {
                return String(format: "%02d", days)
            }
            return "--"
        case .anticipated:
            if let season = show.upcomingSeason, let airDate = season.airDate {
                let year = Calendar.current.component(.year, from: airDate)
                return "\(year)"
            }
            return "TBD"
        }
    }

    private var countdownLabel: String {
        switch style {
        case .endingSoon, .premiering:
            return "DAYS"
        case .anticipated:
            if let season = show.upcomingSeason, season.airDate != nil {
                return "EXP."
            }
            return "DATE"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left side: Countdown text with background to create line break
            VStack(alignment: .center, spacing: 0) {
                Text(countdownText)
                    .font(.system(size: countdownText == "TBD" ? 24 : 36, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(style == .anticipated ? accentColor : .white)

                Text(countdownLabel)
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(style == .anticipated ? accentColor.opacity(0.7) : .white.opacity(0.7))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.black)
            .frame(width: 80)

            Spacer()

            // Right side: Portrait poster (230x310, corner radius 15, floats right)
            ZStack(alignment: .bottomTrailing) {
                posterImage
                    .frame(width: 230, height: 310)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .strokeBorder(Color(white: 0.4).opacity(0.5), lineWidth: 1)
                    )

                // Season badge
                Text("S\(show.upcomingSeason?.seasonNumber ?? show.currentSeason?.seasonNumber ?? 1)")
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
            }
        }
        .padding(.trailing, 24)
    }

    @ViewBuilder
    private var posterImage: some View {
        let url = TMDBConfiguration.imageURL(path: show.posterPath, size: .poster)
        CachedAsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                posterPlaceholder
                if url != nil {
                    ProgressView()
                        .tint(.white.opacity(0.5))
                }
            }
        }
    }

    private var posterPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.15), Color(white: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(String(show.name.prefix(1)))
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(Color(white: 0.25))
        }
    }
}

#Preview("Premiering Collapsed") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 0) {
            CompactPosterRow(
                shows: [
                    Show(
                        id: 1,
                        name: "Bear Show",
                        overview: "",
                        posterPath: nil,
                        backdropPath: nil,
                        logoPath: nil,
                        firstAirDate: nil,
                        status: .returning,
                        genres: [],
                        networks: [],
                        seasons: [],
                        numberOfSeasons: 3,
                        numberOfEpisodes: 30,
                        inProduction: true
                    ),
                    Show(
                        id: 2,
                        name: "Temple Show",
                        overview: "",
                        posterPath: nil,
                        backdropPath: nil,
                        logoPath: nil,
                        firstAirDate: nil,
                        status: .returning,
                        genres: [],
                        networks: [],
                        seasons: [],
                        numberOfSeasons: 2,
                        numberOfEpisodes: 20,
                        inProduction: true
                    ),
                    Show(
                        id: 3,
                        name: "Forest Show",
                        overview: "",
                        posterPath: nil,
                        backdropPath: nil,
                        logoPath: nil,
                        firstAirDate: nil,
                        status: .returning,
                        genres: [],
                        networks: [],
                        seasons: [],
                        numberOfSeasons: 5,
                        numberOfEpisodes: 50,
                        inProduction: true
                    )
                ],
                style: .premiering,
                onShowTap: { _ in }
            )
            Spacer()
        }
        .padding(.top, 40)
    }
}

#Preview("Anticipated Collapsed") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 0) {
            CompactPosterRow(
                shows: [
                    Show(
                        id: 1,
                        name: "Witcher",
                        overview: "",
                        posterPath: nil,
                        backdropPath: nil,
                        logoPath: nil,
                        firstAirDate: nil,
                        status: .inProduction,
                        genres: [],
                        networks: [],
                        seasons: [],
                        numberOfSeasons: 4,
                        numberOfEpisodes: 32,
                        inProduction: true
                    ),
                    Show(
                        id: 2,
                        name: "Unknown",
                        overview: "",
                        posterPath: nil,
                        backdropPath: nil,
                        logoPath: nil,
                        firstAirDate: nil,
                        status: .inProduction,
                        genres: [],
                        networks: [],
                        seasons: [],
                        numberOfSeasons: 1,
                        numberOfEpisodes: 10,
                        inProduction: true
                    )
                ],
                style: .anticipated,
                onShowTap: { _ in }
            )
            Spacer()
        }
        .padding(.top, 40)
    }
}
