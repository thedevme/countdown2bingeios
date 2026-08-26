//
//  CloudSyncUpsellCard.swift
//  Countdown2Binge
//
//  Premium upsell card shown when user is on free tier.
//

import SwiftUI

struct CloudSyncUpsellCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Crown icon
                ZStack {
                    Circle()
                        .fill(Color.c2bTeal.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.c2bTeal)
                }

                // Text content
                VStack(alignment: .leading, spacing: 3) {
                    Text("Back up your lineup")
                        .font(.custom(.oswald.bold, size: 15))
                        .foregroundColor(.white)
                        .tracking(0.3)

                    Text("Premium syncs every show, season, and watched episode across your devices.")
                        .font(.custom(.jetbrains.regular, size: 9))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.3)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.c2bTeal.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.c2bTeal.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()

        CloudSyncUpsellCard {
        }
        .padding()
    }
}
