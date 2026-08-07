//
//  FreeIncludesSection.swift
//  Countdown2Binge
//
//  Shows what free users get - displayed on the paywall.
//

import SwiftUI

struct FreeIncludesSection: View {
    private let features = [
        "Follow up to 3 shows",
        "View show details, seasons, episodes",
        "See every timeline stage",
        "Search & discover shows",
        "Mark episodes watched (this device)",
        "Basic profile"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("FREE INCLUDES")
                .font(.custom(.jetbrains.bold, size: 10))
                .foregroundColor(.c2bMuted)
                .tracking(1.2)
                .padding(.bottom, 12)

            // Feature list - matching PremiumUnlocksSection row height
            VStack(spacing: 0) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FreeFeatureRow(text: feature)

                    if index < features.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.06))
                    }
                }
            }
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

// MARK: - Free Feature Row

private struct FreeFeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            // Checkmark circle to match premium icon style
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.c2bMuted)
            }

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.c2bText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    FreeIncludesSection()
        .padding()
        .background(Color.c2bBackground)
}
