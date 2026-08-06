//
//  DetailPhasePill.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailPhasePill: View {
    let label: String
    let tone: Color
    let isReady: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tone)
                .frame(width: 5, height: 5)
            Text(label)
                .font(.custom(.jetbrains.bold, size: 8.5))
                .foregroundColor(tone)
                .textCase(.uppercase)
                .tracking(1.4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(tone.opacity(0.1))
        .cornerRadius(999)
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(isReady ? Color.c2bTealLine : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
