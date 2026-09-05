//
//  MyListSectionRail.swift
//  Countdown2Binge
//
//  The design's actual `.rail` — a horizontal, center-snapped, one-page-at-
//  a-time scroller with neighbours peeking in from both edges, plus page
//  dots below. Every section owns its own rail (paging is per-section, not
//  shared). A single item still runs through this SAME scroller/sizing —
//  only the page dots are hidden ("solo" in the design) — so a section
//  with one card is never a different width than one with several; a
//  standalone full-width card measurably diverged from the rest (a card
//  ~4x the width of a paged one, confirmed by pixel-measuring two
//  sections side by side). Design ref: "My List Cards.html" —
//  `.rail`/`.bc`/`.dots`.
//
//  NOTE: card width is `containerRelativeFrame(.horizontal, count: 1,
//  spacing:)` — the built-in iOS 17 recipe for exactly this "one page,
//  peeking neighbours" pattern, paired with `.contentMargins()` for the
//  peek inset. NOT a hand-computed `{ width, _ in width - 30 }` closure
//  (measurably inconsistent between sections in this nested hierarchy —
//  confirmed by pixel-measuring two rails side by side, one ~4x narrower
//  than the other) and NOT a self-measured GeometryReader (that sizes
//  itself FROM this same view's content, which sizes ITS cards from that
//  measurement: a circular dependency that once collapsed the rail to a
//  sliver with a wall of blank space).
//

import SwiftUI

struct MyListSectionRail<Item: Identifiable, CardContent: View>: View {
    let items: [Item]
    /// The section's own tone (tier tone / straight-through override) —
    /// the active page dot matches it, not a fixed teal regardless of
    /// which section the rail belongs to.
    var tone: Color = .c2bTeal
    @ViewBuilder var card: (Item) -> CardContent

    @State private var position: Item.ID?

    var body: some View {
        VStack(spacing: 13) {
            ScrollView(.horizontal) {
                // `alignment: .top` — LazyHStack defaults to centering
                // its cross axis, so any residual height difference
                // between cards (deck/plate content) center-aligns them
                // instead of lining up their top edges, which reads as
                // "the other card is bigger." The design is explicit
                // that decks of any depth start at the same y.
                LazyHStack(alignment: .top, spacing: 10) {
                    ForEach(items) { item in
                        card(item)
                            // span is Apple's own mechanism for "this item
                            // occupies most, not all, of the container" —
                            // 19/20 (95%) of the width, proportionally on
                            // any screen size, not a fixed point value.
                            // Applied to EVERY section regardless of item
                            // count, so a single-item section is never a
                            // different width than a multi-item one.
                            .containerRelativeFrame(.horizontal, count: 20, span: 19, spacing: 10)
                            // `.bc.off{opacity:.42;transform:scale(.97)}` —
                            // without this, a peeking neighbour renders at
                            // full size/opacity and reads as bigger than
                            // the focused card instead of receding behind it.
                            .opacity(item.id == position ? 1 : 0.42)
                            .scaleEffect(item.id == position ? 1 : 0.97)
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $position)
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 15, for: .scrollContent)
            .onAppear { if position == nil { position = items.first?.id } }

            // Dots only when there's something to page between — a single
            // item ("solo" in the design) has nothing to indicate.
            if items.count > 1 {
                HStack(spacing: 5) {
                    ForEach(items) { item in
                        Capsule()
                            .fill(item.id == position ? tone : Color.white.opacity(0.2))
                            .frame(width: item.id == position ? 16 : 5, height: 5)
                            .animation(.easeOut(duration: 0.2), value: position)
                    }
                }
            }
        }
    }
}
