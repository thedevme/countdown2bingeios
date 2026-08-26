//
//  SettingsAccountCard.swift
//  Countdown2Binge
//
//  Account/plan card at top of settings.
//

import SwiftUI

struct SettingsAccountCard: View {
    let userName: String
    let isPremium: Bool
    /// Premium *because of an active trial*, not a completed purchase.
    /// Without this the card told every premium user they were on a free
    /// trial — misleading for someone who actually paid, and alarming for
    /// anyone who picked the free plan.
    var isInTrial: Bool = false
    var onTap: (() -> Void)? = nil

    private var initials: String {
        let parts = userName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(userName.prefix(2)).uppercased()
    }

    private var planLabel: LocalizedStringKey {
        guard isPremium else { return "account_free_plan" }
        return isInTrial ? "account_premium_trial" : "account_premium"
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#2a2a2e"), Color(hex: "#131315")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    Text(initials)
                        .font(.custom(.oswald.bold, size: 22))
                        .foregroundColor(.c2bTealBright)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(userName)
                        .font(.custom(.oswald.bold, size: 20))
                        .foregroundColor(.white)

                    HStack(spacing: 5) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.c2bTealBright)

                        Text(planLabel)
                            .font(.custom(.jetbrains.regular, size: 9))
                            .tracking(0.9)
                            .foregroundColor(.c2bTealBright)
                            .textCase(.uppercase)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.c2bMuted)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.c2bTeal.opacity(0.14), Color.c2bTeal.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.c2bTealLine, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 22)
    }
}
