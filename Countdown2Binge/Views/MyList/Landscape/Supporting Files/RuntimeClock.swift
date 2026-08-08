//
//  RuntimeClock.swift
//  Countdown2Binge
//
//  Ported from c2b-mylist.jsx `MLTime`: an h:m:s runtime readout in the display
//  face, with wide-tracked mono units. Always renders all three parts so every
//  card reads the same shape.
//

import SwiftUI

struct RuntimeClock: View {
    /// Total runtime in seconds.
    let seconds: Int
    var numberSize: CGFloat = 30
    var unitSize: CGFloat = 12
    var tone: Color = .c2bText

    private var parts: [(value: String, unit: String)] {
        let total = max(0, seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return [
            ("\(h)", "h"),
            (String(format: "%02d", m), "m"),
            (String(format: "%02d", s), "s"),
        ]
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 {
                    Text(":")
                        .font(.custom(.oswald.bold, size: numberSize))
                        .foregroundColor(.c2bMuted)
                        .padding(.horizontal, 1)
                }
                Text(part.value)
                    .font(.custom(.oswald.bold, size: numberSize))
                    .foregroundColor(tone)
                Text(part.unit)
                    .font(.custom(.jetbrains.regular, size: unitSize))
                    .foregroundColor(.c2bMuted)
            }
        }
        .lineLimit(1)
        .fixedSize()
    }
}

#Preview {
    VStack(alignment: .trailing, spacing: 20) {
        RuntimeClock(seconds: 2887 * 10)                       // ~8h
        RuntimeClock(seconds: 3502 * 10, numberSize: 20, unitSize: 9, tone: .c2bTealBright)
        RuntimeClock(seconds: 1928 * 4, numberSize: 24, unitSize: 10)
    }
    .padding()
    .background(Color.c2bBackground)
}
