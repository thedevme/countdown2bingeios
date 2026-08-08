//
//  PremiumUnlocksSection.swift
//  Countdown2Binge
//
//  Shows premium features with icons - displayed on the paywall.
//

import SwiftUI

struct PremiumUnlocksSection: View {
    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("infinity", "Unlimited shows", "No 3-show cap — track the whole watchlist"),
        ("icloud", "iCloud sync", "Progress & follows on every device"),
        ("bell.badge", "Push notifications", "Premiere, finale, binge ready, new season"),
        ("rectangle.on.rectangle", "Spinoff collections", "Franchise & related shows in watch order"),
        ("person.crop.circle", "Custom profile photo", "Pick any image from your library")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with lock icon
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.c2bTeal)

                Text("PREMIUM UNLOCKS")
                    .font(.custom(.jetbrains.bold, size: 10))
                    .foregroundColor(.c2bTeal)
                    .tracking(1.2)
            }
            .padding(.bottom, 12)

            // Feature list
            VStack(spacing: 0) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    PremiumFeatureRow(
                        icon: feature.icon,
                        title: feature.title,
                        subtitle: feature.subtitle
                    )

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

// MARK: - Premium Feature Row

private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(Color.c2bTeal.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.c2bTeal)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.c2bMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    PremiumUnlocksSection()
        .padding()
        .background(Color.c2bBackground)
}
