//
//  MyListOnboardingIntroContent.swift
//  Countdown2Binge
//
//  The first page of the onboarding card — badge, headline, copy, 3 dots,
//  Get Started / Maybe Later. No backdrop or card chrome of its own: those
//  are owned once by MyListOnboardingContainer, shared across every page.
//  Design ref: "My List Cards.html", introOverlay().
//

import SwiftUI

struct MyListOnboardingIntroContent: View {
    let onGetStarted: () -> Void
    let onMaybeLater: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            Text("BUILT FOR YOU")
                .font(.custom(.jetbrains.bold, size: 7.5))
                .tracking(1.8)
                .foregroundColor(.c2bTealBright)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.c2bTealSoft)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.c2bTealLine, lineWidth: 1)
                )

            (Text("Your list, ")
                + Text("your pace").foregroundColor(.c2bTealBright))
                .font(.custom(.oswald.bold, size: 30))
                .foregroundColor(.c2bText)
                .multilineTextAlignment(.center)
                .padding(.top, 15)

            Text("My List is arranged around how you actually watch — grouped by how much time each season needs, so what fits tonight is always at the top.")
                .font(.system(size: 13.5))
                .foregroundColor(.c2bDim)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 12)

            Text("Three quick questions and we'll personalise it. You can change your answers any time.")
                .font(.system(size: 12.5))
                .foregroundColor(.c2bMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 10)

            HStack(spacing: 7) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(index == 0 ? Color.c2bTealBright : Color.c2bTeal.opacity(0.34))
                        .frame(width: 22, height: 3)
                }
            }
            .padding(.top, 18)

            Spacer(minLength: 20)

            MyListOnboardingCTA(label: "Get started", onTap: onGetStarted)

            Button(action: onMaybeLater) {
                Text("MAYBE LATER")
                    .font(.custom(.jetbrains.bold, size: 8.5))
                    .tracking(1.4)
                    .foregroundColor(.c2bMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 9)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ZStack {
        Color.c2bCard
        MyListOnboardingIntroContent(onGetStarted: {}, onMaybeLater: {})
            .padding(24)
    }
}
