//
//  ProfileIdentityCard.swift
//  Countdown2Binge
//
//  Identity card showing avatar, name, and plan status.
//

import SwiftUI

struct ProfileIdentityCard: View {
    let profile: UserProfile
    let isPremium: Bool
    let onEditTap: () -> Void
    let onShareTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Avatar
            ProfileAvatar(profile: profile, size: 76, showRing: true)
                .padding(.bottom, 14)

            // Name
            Text(profile.name.uppercased())
                .font(.custom(.oswald.bold, size: 26))
                .foregroundColor(.white)
                .lineLimit(1)

            // Plan status
            HStack(spacing: 4) {
                if isPremium {
                    Text("★")
                        .font(.system(size: 10))
                }
                Text(isPremium ? "profile_premium_member" : "account_free_plan")
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(1.2)
                    .textCase(.uppercase)
            }
            .foregroundColor(isPremium ? .c2bTealBright : .c2bMuted)
            .padding(.top, 8)

            // Hint if no custom name
            if !profile.hasCustomName {
                Text("profile_edit_hint")
                    .font(.system(size: 11.5))
                    .foregroundColor(.c2bMuted)
                    .padding(.top, 10)
            }

            // Action buttons
            HStack(spacing: 10) {
                Button(action: onEditTap) {
                    Text("profile_edit_button")
                        .font(.custom(.jetbrains.bold, size: 10.5))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                }

                Button(action: onShareTap) {
                    Text("profile_share_lineup")
                        .font(.custom(.jetbrains.bold, size: 10.5))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: "#04201c"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.c2bTeal)
                        .cornerRadius(12)
                }
            }
            .padding(.top, 16)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.c2bTeal.opacity(0.12), Color.c2bTeal.opacity(0.01)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileIdentityCard(
            profile: .default,
            isPremium: true,
            onEditTap: {},
            onShareTap: {}
        )

        ProfileIdentityCard(
            profile: UserProfile(name: "Craig Clayton", avatarId: "plum", hasCustomName: true),
            isPremium: false,
            onEditTap: {},
            onShareTap: {}
        )
    }
    .padding(20)
    .background(Color.c2bBackground)
    .preferredColorScheme(.dark)
}
