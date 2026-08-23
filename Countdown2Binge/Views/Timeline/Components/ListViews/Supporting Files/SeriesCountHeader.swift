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

    private let labelSize: CGFloat = 9.5

    /// SHOW for one, SHOWS for any other count.
    private var label: String {
        count == 1
            ? String(localized: "label_show")
            : String(localized: "label_shows")
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            // Count number (zero-padded)
            Text(String(format: "%02d", count))
                .font(.custom(.oswald.bold, size: 45))
                .foregroundColor(accentColor)

            // "SHOW" / "SHOWS" label
            Text(label)
                .font(.custom(.jetbrains.bold, size: labelSize))
                .foregroundColor(mutedColor)
                .tracking(labelSize * 0.16)

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
