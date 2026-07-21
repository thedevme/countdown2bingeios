//
//  ShowDetailStatusCard.swift
//  Countdown2Binge
//
//  Big countdown card with days, eyebrow text, date line, phase pill, and lifecycle rail.
//

import SwiftUI

struct ShowDetailStatusCard: View {
    let bigValue: String       // "62", "NOW", "TBD"
    let showDaysLabel: Bool    // Whether to show "DAYS" below the number
    let eyebrow: String        // "Until binge ready", "Ready to binge"
    let dateLine: String       // "Premieres Jun 3 · ~Aug 12 ready"
    let pillText: String       // "Premiering soon · in 42d"
    let isReady: Bool          // True if binge ready (green number)
    let isTBD: Bool            // True if no date (dim styling)
    let lifecycleIndex: Int    // 0 = Soon, 1 = Premiere, 2 = Airing, 3 = Ready

    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            HStack(alignment: .center, spacing: 18) {
                // Big countdown number
                VStack(spacing: 0) {
                    Text(bigValue)
                        .font(.custom(.oswald.bold, size: bigValueFontSize))
                        .foregroundColor(bigValueColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    if showDaysLabel {
                        Text("DAYS")
                            .font(.custom(.jetbrains.regular, size: 9))
                            .tracking(1.8)
                            .foregroundColor(.c2bDim)
                            .padding(.top, 4)
                    }
                }
                .frame(minWidth: 84)

                // Status info
                VStack(alignment: .leading, spacing: 6) {
                    // Eyebrow
                    Text(eyebrow.uppercased())
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .tracking(1.4)
                        .foregroundColor(.c2bTeal)

                    // Date line
                    Text(dateLine)
                        .font(.system(size: 13))
                        .foregroundColor(.c2bDim)
                        .lineSpacing(3)

                    // Phase pill
                    phasePill
                        .padding(.top, 4)
                }

                Spacer()
            }
            .padding(20)

            // Lifecycle rail section
            VStack {
                ShowDetailLifecycleRail(activeIndex: lifecycleIndex)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.2))
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 1),
                alignment: .top
            )
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Computed Properties

    private var bigValueFontSize: CGFloat {
        bigValue == "TBD" || bigValue == "NOW" ? 44 : 62
    }

    private var bigValueColor: Color {
        if isReady {
            return .c2bTealBright
        } else if isTBD {
            return .c2bMuted
        } else {
            return .white
        }
    }

    private var phasePill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isTBD ? Color.c2bMuted : .c2bTeal)
                .frame(width: 5, height: 5)

            Text(pillText.uppercased())
                .font(.custom(.jetbrains.bold, size: 8.5))
                .tracking(1.3)
                .foregroundColor(isTBD ? .c2bMuted : .c2bTeal)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(isTBD ? Color.white.opacity(0.05) : Color.c2bTeal.opacity(0.1))
        .cornerRadius(999)
        .overlay(
            Capsule()
                .stroke(isTBD ? Color.white.opacity(0.1) : Color.c2bTealLine, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            ShowDetailStatusCard(
                bigValue: "42",
                showDaysLabel: true,
                eyebrow: "Until binge ready",
                dateLine: "Premieres Jun 3 · ~Aug 12 ready",
                pillText: "Premiering soon · in 42d",
                isReady: false,
                isTBD: false,
                lifecycleIndex: 1
            )

            ShowDetailStatusCard(
                bigValue: "NOW",
                showDaysLabel: false,
                eyebrow: "Ready to binge",
                dateLine: "All 10 episodes out · just finished",
                pillText: "Binge ready · all 10 out",
                isReady: true,
                isTBD: false,
                lifecycleIndex: 3
            )

            ShowDetailStatusCard(
                bigValue: "TBD",
                showDaysLabel: false,
                eyebrow: "Until new season",
                dateLine: "No release date announced",
                pillText: "Anticipated",
                isReady: false,
                isTBD: true,
                lifecycleIndex: 0
            )
        }
        .padding()
    }
}
