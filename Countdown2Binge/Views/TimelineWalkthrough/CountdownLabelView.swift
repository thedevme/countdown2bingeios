//
//  CountdownLabelView.swift
//  Countdown2Binge
//
//  Reusable countdown label component showing:
//  - Big rotated number or text (days, year, etc.)
//  - Middle label (e.g., "DAYS", "EXP")
//  - Bottom label (e.g., "TO PREMIERE", "RELEASE")
//

import SwiftUI

struct CountdownLabelView: View {
    let displayText: String
    let middleLabel: LocalizedStringKey
    let accentColor: Color
    let bottomLabel: LocalizedStringKey

    /// Initialize with a number (for day countdowns)
    init(
        number: Int,
        accentColor: Color = .c2bTealBright,
        bottomLabel: LocalizedStringKey = "timeline_to_premiere"
    ) {
        self.displayText = "\(number)"
        self.middleLabel = "time_days"
        self.accentColor = accentColor
        self.bottomLabel = bottomLabel
    }

    /// Initialize with custom text (for year display, etc.)
    init(
        text: String,
        middleLabel: LocalizedStringKey,
        accentColor: Color = .c2bTealBright,
        bottomLabel: LocalizedStringKey
    ) {
        self.displayText = text
        self.middleLabel = middleLabel
        self.accentColor = accentColor
        self.bottomLabel = bottomLabel
    }

    var body: some View {
        HStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    Text(displayText)
                        .font(.custom(.oswald.bold, size: CustomFont.size.xl7))
                        .foregroundColor(.white)
                        .tracking(-5)
                        .rotationEffect(.degrees(-90))
                        .padding(-30)

                    Text(middleLabel)
                        .font(.custom(.oswald.bold, size: CustomFont.size.xl2))
                        .foregroundColor(accentColor)
                        .textCase(.uppercase)
                        .tracking(1.6)
                        .padding(-5)

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
    HStack(spacing: 40) {
        // Day countdown
        CountdownLabelView(number: 18, accentColor: .c2bTealBright, bottomLabel: "timeline_to_premiere")
        // Year display
        CountdownLabelView(text: "'27", middleLabel: "timeline_exp", accentColor: .c2bTealBright, bottomLabel: "timeline_release")
    }
    .padding(40)
    .background(Color.c2bBackground)
}
