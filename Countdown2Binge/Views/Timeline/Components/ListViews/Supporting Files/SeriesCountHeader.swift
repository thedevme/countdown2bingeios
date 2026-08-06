//
//  SeriesCountHeader.swift
//  Countdown2Binge
//
//  Displays the show count label like "03 SHOWS" with dropdown arrow.
//  Reusable across all timeline list views.
//

import SwiftUI

struct SeriesCountHeader: View {
    let count: Int
    var accentColor: Color = Color(hex: "#5EEAD4")  // Teal default

    /// Muted color: #71717A
    private let mutedColor = Color(hex: "#71717A")

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            // Count number (zero-padded)
            Text(String(format: "%02d", count))
                .font(.custom(.oswald.bold, size: 30))
                .foregroundColor(accentColor)

            // "SHOWS" label
            Text("SHOWS")
                .font(.custom(.jetbrains.bold, size: 9.5))
                .foregroundColor(mutedColor)
                .tracking(9.5 * 0.16)

            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SeriesCountHeader(count: 3, accentColor: .c2bTealBright)
        SeriesCountHeader(count: 12, accentColor: .c2bYellowBright)
        SeriesCountHeader(count: 1, accentColor: .c2bMuted)
    }
    .padding()
    .background(Color.c2bBackground)
}
