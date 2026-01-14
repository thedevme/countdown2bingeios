//
//  TimelineShowCard.swift
//  Countdown2Binge
//

import SwiftUI

/// Card style for timeline entries
enum TimelineCardStyle {
    case endingSoon  // Days countdown, teal accent (currently airing)
    case premiering  // Days countdown, teal accent
    case anticipated // Year or TBD, muted gray
}

/// A show card for the Timeline with countdown/date on left and backdrop on right
struct TimelineShowCard: View {
    let show: Show
    let seasonNumber: Int
    let style: TimelineCardStyle
    let daysUntil: Int?
    let expectedYear: Int?
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
        case .endingSoon, .premiering:
            if let days = daysUntil {
                return String(format: "%02d", days)
            }
            return "--"
        case .anticipated:
            if let year = expectedYear {
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
            return expectedYear != nil ? "EXP." : "DATE"
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

            // Right side: Backdrop with season badge (fills available width, height 175, corner radius 24)
            ZStack(alignment: .bottomTrailing) {
                // Backdrop image with solid stroke border
                backdropImage
                    .frame(maxWidth: .infinity)
                    .frame(height: 175)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color(white: 0.4).opacity(0.5), lineWidth: 1)
                    )

                // Season badge
                Text("S\(seasonNumber)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.trailing, 12)
                    .padding(.bottom, 10)
            }
            .contentShape(Rectangle()) // Hit area only on backdrop
        }
        .padding(.trailing, 24)
    }

    @ViewBuilder
    private var backdropImage: some View {
        if let url = TMDBConfiguration.imageURL(path: show.backdropPath, size: .backdrop) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    backdropPlaceholder
                @unknown default:
                    backdropPlaceholder
                }
            }
        } else {
            backdropPlaceholder
        }
    }

    private var backdropPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.15), Color(white: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(String(show.name.prefix(1)))
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color(white: 0.25))
        }
    }
}

#Preview("Premiering Soon") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 0) {
            TimelineShowCard(
                show: Show(
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
                seasonNumber: 3,
                style: .premiering,
                daysUntil: 16,
                expectedYear: nil,
                isFirst: true,
                isLast: false
            )
            .frame(height: 120)

            TimelineShowCard(
                show: Show(
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
                seasonNumber: 2,
                style: .premiering,
                daysUntil: 24,
                expectedYear: nil,
                isFirst: false,
                isLast: true
            )
            .frame(height: 120)

            Spacer()
        }
        .padding(.top, 40)
    }
}

#Preview("Anticipated") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 0) {
            TimelineShowCard(
                show: Show(
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
                seasonNumber: 4,
                style: .anticipated,
                daysUntil: nil,
                expectedYear: 2025,
                isFirst: true,
                isLast: false
            )
            .frame(height: 120)

            TimelineShowCard(
                show: Show(
                    id: 2,
                    name: "Unknown Show",
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
                ),
                seasonNumber: 1,
                style: .anticipated,
                daysUntil: nil,
                expectedYear: nil,
                isFirst: false,
                isLast: true
            )
            .frame(height: 120)

            Spacer()
        }
        .padding(.top, 40)
    }
}
