//
//  AiringUnitToggle.swift
//  Countdown2Binge
//
//  Atom — the Days | Episodes segmented control above the overflow rail.
//  Ported from "Timeline Overflow.html" (example C · Rail), `.seg`.
//
//  Switching the unit swaps every number between days-to-finale and
//  episodes-still-to-air — on the rail AND on the hero ticker above it, which
//  is why the binding is owned by the screen. Both are show-axis facts (R8).
//

import SwiftUI

struct AiringUnitToggle: View {
    @Binding var unit: CountdownDisplayMode

    var body: some View {
        HStack(spacing: 3) {
            ForEach(CountdownDisplayMode.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { unit = option }
                } label: {
                    Text(option.label)
                        .font(.custom(.jetbrains.bold, size: 8))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundColor(unit == option ? .c2bOnTeal : .c2bMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(unit == option ? Color.c2bTeal : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }
}

#Preview {
    @Previewable @State var unit: CountdownDisplayMode = .days
    return AiringUnitToggle(unit: $unit)
        .padding()
        .background(Color.c2bBackground)
}
