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

    private var initials: String {
        let parts = userName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(userName.prefix(2)).uppercased()
    }

    var body: some View {
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
                    .font(.custom(.oswald.regular, size: 22))
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

                    Text(isPremium ? "Premium · Free trial" : "Free plan")
                        .font(.custom(.jetbrains.regular, size: 9))
                        .tracking(0.9)
                        .foregroundColor(.c2bTealBright)
                        .textCase(.uppercase)
                }
            }

            Spacer()
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
        .padding(.bottom, 22)
    }
}
