//
//  MyListRailCardDeck.swift
//  Countdown2Binge
//
//  MyListRailCard's deck-stack peek layers — one per season queued behind
//  the one currently shown on the card's face. Restyled as near-full-width
//  bands with only a hairline taper per layer, evenly spaced, up to 5
//  total cards visible (the face plus up to 4 of these). Depth is clamped
//  by the caller; fewer seasons queued removes layers from the BACK (the
//  farthest/topmost one) first.
//
//  Deliberately a separate file/component from the parked
//  MyListRailCardDeckLegacy.swift (the old wide wedge/fan taper) — neither
//  shares code with the other, so either can be swapped into
//  MyListRailCard.body independently with a one-line change.
//

import SwiftUI

struct MyListRailCardDeck: View {
    let depth: Int
    /// One shade per layer, nearest-to-face first (index 0 = layer
    /// closest to the face). Only the first 4 are ever used (max depth is
    /// 5 total cards = 4 backing layers).
    var tints: [Color] = [
        Color(hex: "#3a3a3f"), Color(hex: "#333338"),
        Color(hex: "#2b2b2f"), Color(hex: "#232326"),
    ]

    /// Fixed total vertical footprint, independent of depth — every card
    /// in a rail is the same height no matter how many seasons queue
    /// behind it.
    var reserve: CGFloat = 22

    /// Fixed sliver thickness per layer, same at every depth — this is
    /// what a depth-5 stack's own layers already use (`reserve / 4`).
    /// Layers stack upward from the face at this SAME spacing regardless
    /// of depth; fewer layers just leaves more of the reserve blank above
    /// them. Previously this was `reserve / (depth - 1)`, so a depth-2
    /// stack's one layer was stretched to reveal the ENTIRE reserve by
    /// itself instead of one thin sliver — way too far apart from the
    /// face, ballooned relative to how tight/thin depth-5's own layers
    /// look. Fixed spacing makes every depth look like a slice of the
    /// same stack, not a differently-scaled one.
    private var peekStep: CGFloat { reserve / 4 }

    var body: some View {
        ForEach(Array(stride(from: depth - 1, through: 1, by: -1)), id: \.self) { k in
            // Near-uniform width — only a hairline taper per layer
            // (2.5pt/step), so the stack reads as an even deck of
            // same-size cards peeking out, not a fan.
            let inset: CGFloat = 8 + CGFloat(k - 1) * 2.5
            RoundedRectangle(cornerRadius: 14)
                .fill(tints[min(k - 1, 3)])
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 6, y: -2)
                .padding(.horizontal, inset)
                // Anchored from the FACE side upward (reserve - k*step),
                // not from y=0 downward — the nearest layer (k=1) always
                // sits just above the face; farther layers stack higher.
                // Unused reserve above the topmost layer stays blank
                // instead of a layer stretching to fill it.
                .offset(y: reserve - CGFloat(k) * peekStep)
        }
    }
}

#Preview {
    HStack(alignment: .top, spacing: 20) {
        ForEach([1, 2, 3, 4, 5], id: \.self) { depth in
            ZStack(alignment: .top) {
                MyListRailCardDeck(depth: depth)
            }
            .frame(width: 60)
        }
    }
    .padding(40)
    .background(Color.c2bBackground)
}
