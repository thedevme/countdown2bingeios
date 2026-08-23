//
//  EpisodeTrackerRow.swift
//  Countdown2Binge
//
//  Molecule — one episode line in the tracker: still, S00 | E00 code, title,
//  optional NEXT chip, watch toggle. Ported from c2b-timeline.jsx
//  `EpisodeTracker`'s episode rows.
//
//  Reuses ThumbnailView (Components/) for the still. Purely presentational —
//  the tap is handed up so the write can go through SeriesManager (R3).
//

import SwiftUI

struct EpisodeTrackerRow: View {
    let episode: EpisodeDisplayModel
    let stillURL: URL?
    /// First unwatched aired episode in the season.
    let isNextUp: Bool
    let onTap: () -> Void

    /// Not yet aired — the row is dimmed and inert.
    private var isLocked: Bool { !episode.hasAired }

    var body: some View {
        Button(action: { if !isLocked { onTap() } }) {
            HStack(spacing: 12) {
                ThumbnailView(url: stillURL, width: 70, height: 42, cornerRadius: 7)
                    .saturation(episode.isWatched || isLocked ? 0.35 : 1)
                    .brightness(episode.isWatched ? -0.18 : (isLocked ? -0.24 : 0))

                VStack(alignment: .leading, spacing: 2) {
                    episodeCode
                    Text(episode.title)
                        .font(.system(size: 11.5))
                        .foregroundColor(episode.isWatched ? .c2bMuted : .c2bDim)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isNextUp {
                    NextUpBadge()
                }

                EpisodeWatchToggle(isWatched: episode.isWatched, isLocked: isLocked)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 9)
            .opacity(isLocked ? 0.55 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.c2bHairSoft)
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(episode.isWatched ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Episode code — S00 | E00, Oswald bold/light mix

    private var episodeCode: some View {
        let tint: Color = episode.isWatched ? .c2bMuted : .c2bText

        return (
            Text(String(localized: "season_abbrev"))
                .font(.custom(.oswald.bold, size: 14))
                .foregroundColor(tint)
            + Text(String(format: "%02d", episode.seasonNumber))
                .font(.custom(.oswald.light, size: 14))
                .foregroundColor(tint)
            + Text("  |  ")
                .font(.custom(.oswald.light, size: 13))
                .foregroundColor(.c2bMuted)
            + Text(verbatim: "E")
                .font(.custom(.oswald.bold, size: 14))
                .foregroundColor(tint)
            + Text(String(format: "%02d", episode.number))
                .font(.custom(.oswald.light, size: 14))
                .foregroundColor(tint)
        )
    }

    private var accessibilityLabel: String {
        let code = "S\(episode.seasonNumber) E\(episode.number)"
        let state = isLocked
            ? String(localized: "episode_status_not_aired")
            : (episode.isWatched
                ? String(localized: "season_watched")
                : String(localized: "episode_status_up_next"))
        return "\(code), \(episode.title), \(state)"
    }
}

#Preview {
    func ep(_ n: Int, watched: Bool, aired: Bool) -> EpisodeDisplayModel {
        EpisodeDisplayModel(
            id: "\(n)",
            number: n,
            seasonNumber: 13,
            title: n == 1 ? "Machines" : "Episode \(n) with a rather long title",
            description: "",
            runtime: 45,
            airDate: nil,
            isWatched: watched,
            hasAired: aired,
            isFinale: n == 10
        )
    }

    return VStack(spacing: 0) {
        EpisodeTrackerRow(episode: ep(1, watched: true, aired: true), stillURL: nil, isNextUp: false, onTap: {})
        EpisodeTrackerRow(episode: ep(2, watched: false, aired: true), stillURL: nil, isNextUp: true, onTap: {})
        EpisodeTrackerRow(episode: ep(3, watched: false, aired: true), stillURL: nil, isNextUp: false, onTap: {})
        EpisodeTrackerRow(episode: ep(4, watched: false, aired: false), stillURL: nil, isNextUp: false, onTap: {})
    }
    .padding()
    .background(Color.c2bBackground)
}
