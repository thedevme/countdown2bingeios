//
//  NextUpBadge.swift
//  Countdown2Binge
//
//  Atom — the small teal "NEXT" chip marking the first unwatched aired episode
//  in the tracker list. Ported from c2b-timeline.jsx `EpisodeTracker` (nextUp).
//
//  Not StatusBadge: that one is a fixed sync/lock variant set (SYNCED /
//  SYNCING / LOCAL ONLY) with its own icon vocabulary and doesn't fit here.
//

import SwiftUI

struct NextUpBadge: View {
    var body: some View {
        Text(String(localized: "badge_next"))
            .font(.custom(.jetbrains.bold, size: 7))
            .tracking(0.7)
            .textCase(.uppercase)
            .foregroundColor(.c2bOnTeal)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.c2bTealBright)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .fixedSize()
    }
}

#Preview {
    NextUpBadge()
        .padding()
        .background(Color.c2bBackground)
}
