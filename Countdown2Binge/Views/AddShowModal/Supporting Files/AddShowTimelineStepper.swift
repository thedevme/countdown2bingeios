//
//  AddShowTimelineStepper.swift
//  Countdown2Binge
//
//  Timeline stepper showing lifecycle phases with vertical connector on active phase.
//

import SwiftUI

struct AddShowTimelineStepper: View {
    let activePhase: String

    // Phases from left to right: complete -> airing -> premiering -> anticipated
    private var phases: [(String, String)] {
        [
            ("ready", String(localized: "stepper_series_complete")),
            ("airing", String(localized: "stepper_now_airing")),
            ("premiering", String(localized: "stepper_premiering")),
            ("anticipated", String(localized: "stepper_anticipated"))
        ]
    }

    private var activeIndex: Int {
        phases.firstIndex { $0.0 == activePhase } ?? 3
    }

    var body: some View {
        VStack(spacing: 0) {
            // Dots and horizontal line
            GeometryReader { geo in
                let spacing = geo.size.width / CGFloat(phases.count)

                ZStack {
                    // Background line
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 2)
                        .padding(.horizontal, spacing / 2)

                    // Progress line (from start to active)
                    HStack {
                        Rectangle()
                            .fill(Color.c2bTeal)
                            .frame(width: CGFloat(activeIndex) * spacing, height: 2)
                        Spacer()
                    }
                    .padding(.horizontal, spacing / 2)

                    // Dots
                    HStack(spacing: 0) {
                        ForEach(Array(phases.enumerated()), id: \.offset) { index, _ in
                            let isPast = index < activeIndex
                            let isActive = index == activeIndex

                            Circle()
                                .fill(isPast ? Color.c2bTeal : (isActive ? Color.c2bTeal : Color(hex: "#1a1a1c")))
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(isPast || isActive ? Color.clear : Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .frame(height: 20)

            // Vertical connector line for active phase
            GeometryReader { geo in
                let spacing = geo.size.width / CGFloat(phases.count)
                let activeX = (CGFloat(activeIndex) + 0.5) * spacing

                Path { path in
                    path.move(to: CGPoint(x: activeX, y: 0))
                    path.addLine(to: CGPoint(x: activeX, y: 20))
                }
                .stroke(Color.c2bTeal, lineWidth: 1.5)
            }
            .frame(height: 20)

            // Labels
            HStack(spacing: 0) {
                ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                    let isActive = index == activeIndex

                    Text(phase.1)
                        .font(.custom(.jetbrains.bold, size: 8))
                        .tracking(0.4)
                        .foregroundColor(isActive ? .c2bTeal : .c2bMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        AddShowTimelineStepper(activePhase: "anticipated")
        AddShowTimelineStepper(activePhase: "premiering")
        AddShowTimelineStepper(activePhase: "airing")
        AddShowTimelineStepper(activePhase: "ready")
    }
    .padding(20)
    .background(Color.c2bBackground)
}
