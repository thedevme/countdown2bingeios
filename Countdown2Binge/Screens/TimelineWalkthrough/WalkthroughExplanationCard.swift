//
//  WalkthroughExplanationCard.swift
//  Countdown2Binge
//
//  Floating explanation overlay for each walkthrough step.
//

import SwiftUI

struct WalkthroughExplanationCard: View {
    let label: String
    let tone: Color
    let hint: String
    let note: String
    let currentStep: Int
    let totalSteps: Int

    private var isMuted: Bool {
        tone == Color(hex: "#71717a")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: dot + label + step counter
            HStack(alignment: .center, spacing: 9) {
                // Glowing dot
                Circle()
                    .fill(tone)
                    .frame(width: 9, height: 9)
                    .shadow(color: isMuted ? Color.white.opacity(0.08) : Color(hex: "#2dd4bf").opacity(0.18), radius: 4)

                Text(label)
                    .font(.custom(.oswald.bold, size: 24))
                    .foregroundColor(isMuted ? .white : tone)
                    .tracking(0.02 * 24)

                Spacer()

                Text("\(currentStep) / \(totalSteps)")
                    .font(.custom(.jetbrains.bold, size: 10))
                    .foregroundColor(.c2bMuted)
                    .textCase(.uppercase)
                    .tracking(1.4)
            }
            .padding(.bottom, 7)

            // Hint text
            Text(hint)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.c2bDim)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.top, 10)
                .padding(.bottom, 10)

            // Note with up arrow
            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isMuted ? .c2bDim : tone)
                    .frame(width: 14)

                Text(note)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundColor(.c2bMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "#141416").opacity(0.94))
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isMuted ? Color.white.opacity(0.16) : Color.c2bTealLine, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 23, x: 0, y: 18)
    }
}
