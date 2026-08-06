//
//  DetailPhaseLabel.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailPhaseLabel: View {
    let label: String
    let tone: Color

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(tone)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.custom(.jetbrains.bold, size: 10))
                .foregroundColor(tone)
                .textCase(.uppercase)
                .tracking(2.0)
        }
    }
}
