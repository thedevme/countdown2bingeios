//
//  EpisodeWatchToggle.swift
//  Countdown2Binge
//
//  Atom — the 29pt circular watch control on an episode row.
//  Ported from c2b-timeline.jsx `EpisodeTracker`'s trailing circle:
//  filled teal + dark check when watched, hairline ring + faint check when not,
//  padlock when the episode hasn't aired yet.
//
//  Display only. The tap lives on the row so the whole row is the target;
//  the write goes through SeriesManager (R3).
//

import SwiftUI

struct EpisodeWatchToggle: View {
    let isWatched: Bool
    let isLocked: Bool

    private let diameter: CGFloat = 29

    var body: some View {
        ZStack {
            Circle()
                .fill(isWatched ? Color.c2bTeal : Color.clear)
                .overlay(
                    Circle()
                        .stroke(
                            isWatched ? Color.c2bTeal : Color.white.opacity(0.24),
                            lineWidth: 1.5
                        )
                )

            if isLocked {
                Image(systemName: "lock")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.55))
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(isWatched ? .c2bOnTeal : .c2bDim)
                    .opacity(isWatched ? 1 : 0.4)
            }
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeOut(duration: 0.16), value: isWatched)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 18) {
        EpisodeWatchToggle(isWatched: true, isLocked: false)
        EpisodeWatchToggle(isWatched: false, isLocked: false)
        EpisodeWatchToggle(isWatched: false, isLocked: true)
    }
    .padding()
    .background(Color.c2bBackground)
}
