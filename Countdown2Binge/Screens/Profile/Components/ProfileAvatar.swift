//
//  ProfileAvatar.swift
//  Countdown2Binge
//
//  Avatar component with gradient background and initials.
//

import SwiftUI

struct ProfileAvatar: View {
    let profile: UserProfile
    var size: CGFloat = 56
    var showRing: Bool = false
    var customImage: UIImage? = nil

    var body: some View {
        ZStack {
            if let image = customImage ?? (profile.hasCustomImage ? ProfileManager.shared.avatarImage : nil) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: profile.avatar.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)

                Text(profile.initials)
                    .font(.custom(.oswald.bold, size: size * 0.36))
                    .foregroundColor(profile.avatar.foregroundColor)
            }
        }
        .overlay(
            Circle()
                .stroke(
                    showRing ? Color.c2bTealBright : Color.white.opacity(0.14),
                    lineWidth: showRing ? 2 : 1
                )
        )
        .shadow(
            color: showRing ? Color.c2bTeal.opacity(0.18) : .clear,
            radius: showRing ? 8 : 0
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileAvatar(profile: .default, size: 76, showRing: true)

        HStack(spacing: 12) {
            ForEach(AvatarStyle.all) { style in
                ProfileAvatar(
                    profile: UserProfile(name: "Test User", avatarId: style.id, hasCustomName: true),
                    size: 48
                )
            }
        }
    }
    .padding()
    .background(Color.c2bBackground)
    .preferredColorScheme(.dark)
}
