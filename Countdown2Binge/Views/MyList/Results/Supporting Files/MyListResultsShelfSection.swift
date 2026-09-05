//
//  MyListResultsShelfSection.swift
//  Countdown2Binge
//
//  One tier's section — its own bordered, tinted card surface (left border
//  = the tier's tone, background = its wash) containing the header and a
//  horizontal paginated rail of MyListRailCards. Design ref:
//  "My List Cards.html" — `.sec`.
//

import SwiftUI

struct MyListResultsShelfSection: View {
    let tier: MyListShelfTier
    let items: [MyListSeasonDisplay]
    var labelOverride: String? = nil
    var whyOverride: String? = nil
    var iconOverride: String? = nil
    var toneOverride: Color? = nil
    var isEditable: Bool = false
    var onEdit: () -> Void = {}
    var showsNextEpisodeCheckoff: Bool = true

    private var effectiveTone: Color { toneOverride ?? tier.tone }
    var onOpen: (MyListSeasonDisplay) -> Void = { _ in }
    var onMarkAll: (MyListSeasonDisplay) -> Void = { _ in }
    var onToggleEpisode: (MyListSeasonDisplay, EpisodeTick) -> Void = { _, _ in }
    var notificationsOn: (MyListSeasonDisplay) -> Bool = { _ in true }
    var onBell: (MyListSeasonDisplay) -> Void = { _ in }

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                MyListResultsShelfHeader(
                    tier: tier, count: items.count,
                    labelOverride: labelOverride, whyOverride: whyOverride,
                    iconOverride: iconOverride, toneOverride: toneOverride,
                    isEditable: isEditable, onEdit: onEdit
                )

                MyListSectionRail(items: items, tone: effectiveTone) { season in
                    MyListRailCard(
                        season: season,
                        tone: effectiveTone,
                        showsNextEpisodeCheckoff: showsNextEpisodeCheckoff,
                        onOpen: { onOpen(season) },
                        onMarkAll: { onMarkAll(season) },
                        onToggleEpisode: { onToggleEpisode(season, $0) },
                        notificationsOn: notificationsOn(season),
                        onBell: { onBell(season) }
                    )
                }
                // NOT `.padding(.horizontal, 15)` here — the rail's own
                // ScrollView already insets its SCROLLABLE CONTENT by 15pt
                // via `.contentMargins`. Wrapping the rail in a SECOND
                // 15pt padding shrinks the ScrollView's own FRAME (its
                // clipping bounds) by another 15pt on each side, on top of
                // that — 30pt total, vs. the header's single 15pt. That
                // mismatch is exactly why a peeking neighbour card got
                // clipped well before reaching the section's actual edge,
                // reading as an arbitrary cutoff instead of a peek.
                .padding(.bottom, 4)
            }
            .padding(.top, 14)
            // `.sec{padding:14px 0 16px}` — 16pt below the rail's own 4pt,
            // or the card's bottom edge sits flush against the section's
            // rounded corner instead of breathing inside it.
            .padding(.bottom, 16)
            .background(tier.wash)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
            // Shift the whole wash+content box 3pt right, then put a
            // narrow, FIXED-width amber box BEHIND it via .background() —
            // just wide enough (21pt) for its own 18pt corner radius to
            // fully form. No need to match the section's full width: the
            // wash+content box covers all of it except the leftmost 3pt,
            // where the amber box's own curve shows through at the top
            // and bottom corners instead of a straight-edged bar.
            .padding(.leading, 3)
            .background(alignment: .leading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(effectiveTone)
                    .frame(width: 21)
            }
            // Shifts the whole already-composed strip+wash unit 2pt
            // further right as one piece — the strip keeps its exact 3pt
            // reveal shape, just repositioned, rather than widening it.
            .padding(.leading, 2)
        }
    }
}

#Preview {
    ScrollView {
        MyListResultsShelfSection(tier: .weekend, items: MyListLandscapeSample.active)
            .padding(20)
    }
    .background(Color.c2bBackground)
}
