//
//  SeasonStatePip.swift
//  Countdown2Binge
//
//  Ported from c2b-mylist.jsx `MLStatePip`: the small status chip on a season
//  card. READY fills teal; every other state is a dark chip with tone-colored text.
//

import SwiftUI

struct SeasonStatePip: View {
    let state: SeasonWatchState

    var body: some View {
        Text(state.label)
            .font(.custom(.jetbrains.bold, size: 6.5))
            .tracking(0.65)
            .foregroundColor(state.isReady ? .c2bOnTeal : state.tone)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(state.isReady ? Color.c2bTeal : Color(hex: "#080808").opacity(0.8))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    state.isReady ? Color.c2bTeal : Color.white.opacity(0.18),
                    lineWidth: 1
                )
            )
            .fixedSize()
    }
}

#Preview {
    HStack(spacing: 8) {
        ForEach(SeasonWatchState.allCases, id: \.rawValue) { state in
            SeasonStatePip(state: state)
        }
    }
    .padding()
    .background(Color.c2bBackground)
}
