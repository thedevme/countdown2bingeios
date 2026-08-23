//
//  EpisodeTickMeter.swift
//  Countdown2Binge
//
//  Ported from c2b-mylist.jsx `MLTicks`: episode ticks that flex to fill the
//  band so an 8-ep and a 24-ep season occupy identical width. Past the cap the
//  remainder collapses into a "+N" chip.
//
//  Each tick maps to a real episode. Tapping an aired tick toggles that
//  episode's watched state (via the onToggle callback → SeriesManager, R3).
//

import SwiftUI

/// One episode's worth of tick data. Watch flag is a user-axis mark (display
/// data), NOT computed lifecycle state.
struct EpisodeTick: Identifiable, Equatable {
    let id: Int          // TMDB episode id
    let number: Int      // episode number
    var watched: Bool
    let aired: Bool
}

struct EpisodeTickMeter: View {
    let ticks: [EpisodeTick]
    var tone: Color = .c2bTeal
    /// Tapping an aired tick toggles that episode. Nil → non-interactive.
    var onToggle: ((EpisodeTick) -> Void)? = nil

    private let maxTicks = 10

    private var visibleTicks: [EpisodeTick] { Array(ticks.prefix(maxTicks)) }
    private var overflow: Int { max(0, ticks.count - maxTicks) }

    var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 2) {
                ForEach(Array(visibleTicks.enumerated()), id: \.element.id) { index, tick in
                    tickView(tick, index: index)
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
    private func tickView(_ tick: EpisodeTick, index: Int) -> some View {
        let interactive = tick.aired && onToggle != nil

        Button {
            onToggle?(tick)
        } label: {
            RoundedRectangle(cornerRadius: 2)
                .fill(tick.watched ? tone : (tick.aired ? Color.white.opacity(0.22) : Color.white.opacity(0.07)))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity((tick.watched || tick.aired) ? 0 : 0.12), lineWidth: 1)
                )
                .frame(height: 6)
                .frame(maxWidth: .infinity)
                // Enlarged, invisible touch band so a 6pt tick is easy to tap.
                .padding(.vertical, 7)
                .contentShape(Rectangle())
                // Per-tick delay → a cumulative change sweeps left-to-right.
                .animation(.easeOut(duration: 0.18).delay(Double(index) * 0.04), value: tick.watched)
        }
        .buttonStyle(.plain)
        .disabled(!interactive)
    }
}

#Preview {
    func mk(_ n: Int, watched: Int, aired: Int) -> [EpisodeTick] {
        (1...n).map { EpisodeTick(id: $0, number: $0, watched: $0 <= watched, aired: $0 <= aired) }
    }
    return VStack(spacing: 24) {
        EpisodeTickMeter(ticks: mk(10, watched: 3, aired: 10), onToggle: { _ in })
        EpisodeTickMeter(ticks: mk(7, watched: 0, aired: 6), onToggle: { _ in })
        EpisodeTickMeter(ticks: mk(24, watched: 6, aired: 17), onToggle: { _ in })
        EpisodeTickMeter(ticks: mk(8, watched: 8, aired: 8), tone: .c2bMuted)
    }
    .padding()
    .background(Color.c2bBackground)
}
