//
//  ShowDetailTimelineLink.swift
//  Countdown2Binge
//
//  "View on my timeline →" link button shown after following a show.
//

import SwiftUI

struct ShowDetailTimelineLink: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("VIEW ON MY TIMELINE →")
                .font(.custom(.jetbrains.bold, size: 10.5))
                .tracking(1.3)
                .foregroundColor(.c2bTealBright)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ShowDetailTimelineLink(action: {})
    }
}
