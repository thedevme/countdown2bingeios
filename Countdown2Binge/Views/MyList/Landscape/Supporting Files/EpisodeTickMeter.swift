//
//  EpisodeTickMeter.swift
//  Countdown2Binge
//
//  Ported from c2b-mylist.jsx `MLTicks`: episode ticks that flex to fill the
//  band so an 8-ep and a 24-ep season occupy identical width. Past the cap the
//  remainder collapses into a "+N" chip.
//

import SwiftUI

struct EpisodeTickMeter: View {
    let episodeCount: Int
    let watchedCount: Int
    /// Episodes released so far (unreleased ones read as hollow).
    var releasedCount: Int
    var tone: Color = .c2bTeal

    private let maxTicks = 10

    private var visibleTicks: Int { min(episodeCount, maxTicks) }
    private var overflow: Int { max(0, episodeCount - maxTicks) }

    var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 2) {
                ForEach(0..<visibleTicks, id: \.self) { i in
                    tick(at: i)
                }
            }

            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.custom(.jetbrains.bold, size: 8.5))
                    .tracking(0.17)
                    .foregroundColor(.c2bText)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .fixedSize()
            }
        }
    }

    @ViewBuilder
    private func tick(at index: Int) -> some View {
        let watched = index < watchedCount
        let released = index < releasedCount

        RoundedRectangle(cornerRadius: 2)
            .fill(watched ? tone : (released ? Color.white.opacity(0.22) : Color.white.opacity(0.07)))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity((watched || released) ? 0 : 0.12), lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 6)
    }
}

#Preview {
    VStack(spacing: 24) {
        EpisodeTickMeter(episodeCount: 10, watchedCount: 3, releasedCount: 10)
        EpisodeTickMeter(episodeCount: 7, watchedCount: 0, releasedCount: 6)
        EpisodeTickMeter(episodeCount: 24, watchedCount: 6, releasedCount: 17)
        EpisodeTickMeter(episodeCount: 8, watchedCount: 8, releasedCount: 8, tone: .c2bMuted)
    }
    .padding()
    .background(Color.c2bBackground)
}
