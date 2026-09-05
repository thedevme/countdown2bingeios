//
//  MyListOnboardingCTA.swift
//  Countdown2Binge
//
//  The teal "Continue" / "See my list" button and the muted "Skip" text
//  button, shared by all three onboarding questions (design ref:
//  "My List Onboarding.html", `.cta` / `.skip`).
//

import SwiftUI

struct MyListOnboardingCTA: View {
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label.uppercased())
                .font(.custom(.oswald.bold, size: 15))
                .tracking(0.6)
                .foregroundColor(.c2bOnTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.c2bTeal)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct MyListOnboardingSkip: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("SKIP · USE DEFAULTS")
                .font(.custom(.jetbrains.bold, size: 9))
                .tracking(1.2)
                .foregroundColor(.c2bMuted)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 0) {
        MyListOnboardingCTA(label: "Continue", onTap: {})
        MyListOnboardingSkip(onTap: {})
    }
    .padding(20)
    .background(Color.c2bBackground)
}
