//
//  SeasonDetailView.swift
//  Countdown2Binge
//

import SwiftUI

/// Detailed view for a single season showing poster, dates, episode count, and countdown.
struct SeasonDetailView: View {
    let season: Season
    let showName: String
    let onMarkWatched: (() -> Void)?

    init(season: Season, showName: String, onMarkWatched: (() -> Void)? = nil) {
        self.season = season
        self.showName = showName
        self.onMarkWatched = onMarkWatched
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with poster
            headerSection

            // Info section
            VStack(spacing: 24) {
                // Dates row
                datesSection

                // Stats row
                statsSection

                // Countdown (if applicable)
                if countdownInfo != nil {
                    countdownSection
                }

                // Mark watched button (if binge ready)
                if season.isBingeReady, let onMarkWatched {
                    markWatchedButton(action: onMarkWatched)
                }
            }
            .padding(24)
        }
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Poster background (blurred)
            posterBackground
                .frame(height: 200)
                .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, Color(white: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content
            HStack(alignment: .bottom, spacing: 16) {
                // Poster thumbnail
                posterThumbnail
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

                // Title and badge
                VStack(alignment: .leading, spacing: 8) {
                    Text("SEASON \(season.seasonNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.6))

                    Text(showName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    stateBadge
                }

                Spacer()
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private var posterBackground: some View {
        if let posterPath = season.posterPath,
           let url = TMDBConfiguration.imageURL(path: posterPath, size: .backdrop) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 20)
                        .overlay(Color.black.opacity(0.5))
                default:
                    Color(white: 0.15)
                }
            }
        } else {
            LinearGradient(
                colors: [Color(white: 0.2), Color(white: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private var posterThumbnail: some View {
        if let posterPath = season.posterPath,
           let url = TMDBConfiguration.imageURL(path: posterPath, size: .poster) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    posterPlaceholder
                }
            }
        } else {
            posterPlaceholder
        }
    }

    private var posterPlaceholder: some View {
        ZStack {
            Color(white: 0.2)
            Text("S\(season.seasonNumber)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    // MARK: - State Badge

    private var stateBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)

            Text(stateText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(stateColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(stateColor.opacity(0.15))
        )
    }

    private var stateText: String {
        if season.isWatched { return "Watched" }
        if season.isBingeReady { return "Binge Ready" }
        if season.isAiring { return "Airing" }
        if season.hasStarted { return "In Progress" }
        return "Upcoming"
    }

    private var stateColor: Color {
        if season.isWatched { return .gray }
        if season.isBingeReady { return Color(red: 0.45, green: 0.90, blue: 0.70) }
        if season.isAiring { return Color(red: 0.85, green: 0.55, blue: 0.25) }
        return .white.opacity(0.6)
    }

    // MARK: - Dates Section

    private var datesSection: some View {
        HStack(spacing: 0) {
            // Premiere date
            dateColumn(
                label: "PREMIERE",
                date: season.airDate,
                icon: "play.fill"
            )

            Spacer()

            // Divider
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 1, height: 40)

            Spacer()

            // Finale date
            dateColumn(
                label: "FINALE",
                date: season.finaleDate,
                icon: "flag.fill"
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.04))
        )
    }

    private func dateColumn(label: String, date: Date?, icon: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))

                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.4))
            }

            if let date {
                Text(formatDate(date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            } else {
                Text("TBD")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 16) {
            statItem(
                value: "\(season.episodeCount)",
                label: "Episodes"
            )

            statItem(
                value: "\(season.airedEpisodeCount)",
                label: "Aired"
            )

            if season.watchedEpisodeCount > 0 {
                statItem(
                    value: "\(season.watchedEpisodeCount)",
                    label: "Watched"
                )
            }

            if let runtime = averageRuntime {
                statItem(
                    value: "\(runtime)m",
                    label: "Avg Runtime"
                )
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var averageRuntime: Int? {
        let runtimes = season.episodes.compactMap { $0.runtime }.filter { $0 > 0 }
        guard !runtimes.isEmpty else { return nil }
        return runtimes.reduce(0, +) / runtimes.count
    }

    // MARK: - Countdown Section

    private var countdownInfo: (type: String, days: Int, label: String)? {
        if let days = season.daysUntilPremiere, days >= 0 {
            return ("premiere", days, days == 1 ? "day until premiere" : "days until premiere")
        }
        if let days = season.daysUntilFinale, days >= 0 {
            return ("finale", days, days == 1 ? "day until finale" : "days until finale")
        }
        return nil
    }

    @ViewBuilder
    private var countdownSection: some View {
        if let countdown = countdownInfo {
            VStack(spacing: 8) {
                Text("\(countdown.days)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(countdown.type == "finale" ? Color(red: 0.85, green: 0.55, blue: 0.25) : .white)

                Text(countdown.label.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Mark Watched Button

    private func markWatchedButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")

                Text("Mark Season Watched")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.45, green: 0.90, blue: 0.70))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Season Detail") {
    ZStack {
        Color.black.ignoresSafeArea()

        SeasonDetailView(
            season: Season(
                id: 2,
                seasonNumber: 2,
                name: "Season 2",
                overview: "The second season continues the story...",
                posterPath: nil,
                airDate: Date().addingTimeInterval(-86400 * 30),
                episodeCount: 10,
                episodes: [
                    Episode(id: 1, episodeNumber: 1, seasonNumber: 2, name: "Episode 1", overview: nil, airDate: Date().addingTimeInterval(-86400 * 30), stillPath: nil, runtime: 55, watchedDate: nil),
                    Episode(id: 2, episodeNumber: 2, seasonNumber: 2, name: "Episode 2", overview: nil, airDate: Date().addingTimeInterval(-86400 * 23), stillPath: nil, runtime: 52, watchedDate: nil),
                    Episode(id: 3, episodeNumber: 3, seasonNumber: 2, name: "Episode 3", overview: nil, airDate: Date().addingTimeInterval(-86400 * 16), stillPath: nil, runtime: 58, watchedDate: nil)
                ],
                watchedDate: nil
            ),
            showName: "Severance",
            onMarkWatched: {}
        )
        .padding(.horizontal, 24)
    }
}
