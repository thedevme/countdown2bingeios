//
//  ShowDetailFollowHint.swift
//  Countdown2Binge
//
//  Hint text below status card explaining what happens when you follow.
//

import SwiftUI

struct ShowDetailFollowHint: View {
    let hasDate: Bool
    let episodeCount: Int

    var body: some View {
        Text(hintText)
            .font(.system(size: 11.5))
            .foregroundColor(.c2bMuted)
            .lineSpacing(3)
    }

    private var hintText: String {
        if hasDate {
            return String(localized: "follow_hint_airing \(episodeCount)")
        } else {
            return String(localized: "follow_hint_anticipated")
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            ShowDetailFollowHint(hasDate: true, episodeCount: 10)
            ShowDetailFollowHint(hasDate: false, episodeCount: 8)
        }
        .padding()
    }
}
