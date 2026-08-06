//
//  TBACountdownLabelView.swift
//  Countdown2Binge
//
//  Reusable TBA label component showing:
//  - Big rotated "TBA" text
//  - Bottom label (e.g., "FINALE DATE")
//  - NO "DAYS" label
//

import SwiftUI

struct TBACountdownLabelView: View {
    let bottomLabel: LocalizedStringKey

    init(bottomLabel: LocalizedStringKey = "pending_finale_date_label") {
        self.bottomLabel = bottomLabel
    }

    var body: some View {
        HStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    Text("pending_tba")
                        .font(.custom(.oswald.bold, size: CustomFont.size.xl6))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(-2)
                        .rotationEffect(.degrees(-90))
                        .padding(2)

                    Text(bottomLabel)
                        .font(.custom(.jetbrains.bold, size: CustomFont.size.xs))
                        .foregroundColor(Color(hex: "#52525b"))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
            }
            .padding(-7)
            .frame(width: 110, height: 140)
        }
        .padding(-20)
    }
}

#Preview {
    TBACountdownLabelView(bottomLabel: "pending_finale_date_label")
        .padding(40)
        .background(Color.c2bBackground)
}
