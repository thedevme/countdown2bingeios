//
//  SettingsPremiumCTA.swift
//  Countdown2Binge
//
//  Premium unlock call-to-action card.
//

import SwiftUI

struct SettingsPremiumCTA: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 13) {
                // Crown icon
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.c2bTeal)
                        .frame(width: 38, height: 38)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#04201c"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("premium_unlock_premium")
                        .font(.custom(.oswald.bold, size: 16))
                        .foregroundColor(.c2bTealBright)

                    Text("premium_advanced_features")
                        .font(.system(size: 11.5))
                        .foregroundColor(.c2bDim)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.c2bMuted)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.c2bTeal.opacity(0.16), Color.c2bTeal.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.c2bTealLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.bottom, 22)
    }
}

// MARK: - Premium Feature Overlay
struct SettingsPremiumOverlay: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Crown icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.c2bTeal)
                        .frame(width: 42, height: 42)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#04201c"))
                }

                Text("premium_feature")
                    .font(.custom(.oswald.bold, size: 17))
                    .tracking(0.34)
                    .foregroundColor(.c2bTealBright)

                Text("premium_feature_description")
                    .font(.system(size: 12))
                    .foregroundColor(.c2bDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(1.45)
                    .frame(maxWidth: 220)

                Text("button_start_free_trial")
                    .font(.custom(.jetbrains.bold, size: 10.5))
                    .tracking(1.26)
                    .foregroundColor(Color(hex: "#04201c"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.c2bTeal)
                    .clipShape(Capsule())
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "#0e0e0f").opacity(0.86))
                    .shadow(color: .black.opacity(0.6), radius: 40, y: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.c2bTealLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
