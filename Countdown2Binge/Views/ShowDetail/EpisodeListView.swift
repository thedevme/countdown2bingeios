//
//  EpisodeListView.swift
//  Countdown2Binge
//

import SwiftUI

/// A collapsible list of episodes for a season with watched toggles.
struct EpisodeListView: View {
    let episodes: [Episode]
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onToggleWatched: (Episode) -> Void

    private var watchedCount: Int {
        episodes.filter { $0.isWatched }.count
    }

    private var airedCount: Int {
        episodes.filter { $0.hasAired }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (tappable to expand/collapse)
            Button(action: onToggleExpand) {
                HStack {
                    Text("EPISODES")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.4))

                    Spacer()

                    // Progress indicator
                    Text("\(watchedCount)/\(airedCount) watched")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Episode list (when expanded)
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber })) { episode in
                        EpisodeRow(
                            episode: episode,
                            onToggleWatched: { onToggleWatched(episode) }
                        )

                        if episode.id != episodes.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.06))
                                .padding(.leading, 40)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Episode Row

private struct EpisodeRow: View {
    let episode: Episode
    let onToggleWatched: () -> Void

    private var canToggle: Bool {
        episode.hasAired
    }

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                onToggleWatched()
            } label: {
                checkboxView
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 28)
            .disabled(!canToggle)

            // Episode info
            VStack(alignment: .leading, spacing: 4) {
                // Episode number and title
                HStack(spacing: 8) {
                    Text("E\(episode.episodeNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.5))

                    Text(episode.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                }

                // Air date
                if let airDate = episode.airDate {
                    Text(formatDate(airDate))
                        .font(.caption2)
                        .foregroundStyle(dateColor)
                }
            }

            Spacer()

            // Future episode indicator
            if !episode.hasAired {
                Text("UPCOMING")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
            }
        }
        .padding(.vertical, 10)
        .opacity(rowOpacity)
    }

    @ViewBuilder
    private var checkboxView: some View {
        ZStack {
            Circle()
                .strokeBorder(checkboxColor, lineWidth: 1.5)
                .frame(width: 24, height: 24)

            if episode.isWatched {
                Circle()
                    .fill(Color(red: 0.45, green: 0.90, blue: 0.70))
                    .frame(width: 24, height: 24)

                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.black)
            }
        }
    }

    private var checkboxColor: Color {
        if episode.isWatched {
            return Color(red: 0.45, green: 0.90, blue: 0.70)
        } else if episode.hasAired {
            return .white.opacity(0.3)
        } else {
            return .white.opacity(0.15)
        }
    }

    private var textColor: Color {
        if episode.isWatched {
            return .white.opacity(0.5)
        } else if episode.hasAired {
            return .white
        } else {
            return .white.opacity(0.4)
        }
    }

    private var dateColor: Color {
        if !episode.hasAired {
            return Color(red: 0.85, green: 0.55, blue: 0.25).opacity(0.8)
        }
        return .white.opacity(0.4)
    }

    private var rowOpacity: Double {
        if episode.isWatched {
            return 0.7
        }
        return 1.0
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Episode List") {
    ZStack {
        Color.black.ignoresSafeArea()

        EpisodeListView(
            episodes: [
                Episode(id: 1, episodeNumber: 1, seasonNumber: 1, name: "Pilot", overview: nil, airDate: Date().addingTimeInterval(-86400 * 30), stillPath: nil, runtime: 60, watchedDate: Date()),
                Episode(id: 2, episodeNumber: 2, seasonNumber: 1, name: "The Beginning", overview: nil, airDate: Date().addingTimeInterval(-86400 * 23), stillPath: nil, runtime: 58, watchedDate: Date()),
                Episode(id: 3, episodeNumber: 3, seasonNumber: 1, name: "Rising Action", overview: nil, airDate: Date().addingTimeInterval(-86400 * 16), stillPath: nil, runtime: 55, watchedDate: nil),
                Episode(id: 4, episodeNumber: 4, seasonNumber: 1, name: "The Turning Point", overview: nil, airDate: Date().addingTimeInterval(-86400 * 9), stillPath: nil, runtime: 62, watchedDate: nil),
                Episode(id: 5, episodeNumber: 5, seasonNumber: 1, name: "Finale", overview: nil, airDate: Date().addingTimeInterval(86400 * 5), stillPath: nil, runtime: 75, watchedDate: nil)
            ],
            isExpanded: true,
            onToggleExpand: {},
            onToggleWatched: { _ in }
        )
        .padding(.horizontal, 24)
    }
}
