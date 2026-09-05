//
//  MyListOnboardingProgressHeader.swift
//  Countdown2Binge
//
//  Back button + progress track + step counter, shared by all three
//  onboarding questions (design ref: "My List Onboarding.html", `.prog`).
//

import SwiftUI

struct MyListOnboardingProgressHeader: View {
    /// 0-based index of the current question.
    let stepIndex: Int
    let totalSteps: Int
    let onBack: () -> Void

    private var isFirstStep: Bool { stepIndex == 0 }

    var body: some View {
        HStack(spacing: 11) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.8))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.13), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isFirstStep)
            .opacity(isFirstStep ? 0 : 1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.11))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.c2bTeal, .c2bTealBright],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(stepIndex + 1) / CGFloat(totalSteps + 1))
                        .animation(.easeOut(duration: 0.3), value: stepIndex)
                }
            }
            .frame(height: 5)

            Text(String(format: "%d / %d", stepIndex + 1, totalSteps))
                .font(.custom(.jetbrains.bold, size: 9))
                .tracking(1)
                .foregroundColor(.c2bMuted)
                .fixedSize()
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    VStack(spacing: 20) {
        MyListOnboardingProgressHeader(stepIndex: 0, totalSteps: 3, onBack: {})
        MyListOnboardingProgressHeader(stepIndex: 1, totalSteps: 3, onBack: {})
        MyListOnboardingProgressHeader(stepIndex: 2, totalSteps: 3, onBack: {})
    }
    .padding(20)
    .background(Color.c2bBackground)
}
