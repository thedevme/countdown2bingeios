//
//  MyListRailCardDeckLegacy.swift
//  Countdown2Binge
//
//  PARKED, NOT WIRED IN. This is `MyListRailCard`'s deck-stack peek layers
//  exactly as they stood before the "My vouchers"-reference restyle (wide
//  wedge/fan taper — up to 40pt horizontal inset on the farthest layer —
//  vs. the near-full-width bands the current `stackLayers(depth:)` uses
//  now). Kept here, self-contained, so the old look can be swapped back in
//  with a one-line change instead of reconstructing it from git history.
//
//  To restore: in `MyListRailCard.body`, replace
//    stackLayers(depth: depth)
//  with
//    MyListRailCardDeckLegacy(depth: depth, tints: deckTints)
//  (`deckTints`/`deckReserve` are private to MyListRailCard — either widen
//  their access or pass them in, as done here via `tints`.)
//

import SwiftUI

struct MyListRailCardDeckLegacy: View {
    let depth: Int
    let tints: [Color]

    /// Same fixed total vertical footprint as the live version — every
    /// card in a rail is the same height no matter how many seasons queue
    /// behind it.
    private let deckReserve: CGFloat = 22

    var body: some View {
        // Compress the whole stack into `deckReserve`, however many layers
        // there are — depth 5 fans four thin slivers across the same 22pt
        // that depth 2 spends on one.
        let peek: CGFloat = depth > 1 ? deckReserve / CGFloat(depth - 1) : 0
        ForEach(Array(stride(from: depth - 1, through: 1, by: -1)), id: \.self) { k in
            // The layer at k == depth-1 sits at offset y=0 — fully exposed,
            // showing the whole reserve above the face (not just one
            // `peek`-tall sliver, since nothing renders in front of it to
            // cover the rest). At depth 3+ that's already the layer with
            // the widest inset (k itself is ≥ 2, i.e. ≥20pt), so a full
            // reveal always pairs with a strong taper. At depth 2 the ONE
            // layer is simultaneously nearest AND farthest — it still gets
            // the full 22pt reveal, but `k` is 1, the inset meant for a
            // barely-visible near layer (10pt) — a tall reveal at almost
            // full card width, reading as a flat slab instead of a taper.
            // Floor only the fully-exposed layer's inset so depth 3+ (each
            // layer already ≥20pt there) renders byte-for-byte the same.
            let isFullyExposed = k == depth - 1
            let inset: CGFloat = isFullyExposed ? max(CGFloat(k) * 10, 20) : CGFloat(k) * 10
            RoundedRectangle(cornerRadius: 14)
                .fill(tints[min(k - 1, 3)])
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 4, y: -2)
                .padding(.horizontal, inset)
                // Furthest layer (k = depth-1) sits at y=0, the ZStack's
                // own shared top edge; each nearer layer steps DOWN toward
                // the face (which starts at y=deckReserve, via its own
                // padding).
                .offset(y: CGFloat(depth - 1 - k) * peek)
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        MyListRailCardDeckLegacy(
            depth: 5,
            tints: [
                Color(hex: "#1b1b1e"), Color(hex: "#232326"),
                Color(hex: "#2b2b2f"), Color(hex: "#333338"),
            ]
        )
    }
    .padding(40)
    .background(Color.c2bBackground)
}
