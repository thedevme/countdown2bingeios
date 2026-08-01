//
//  MyListSectionHeader.swift
//  Countdown2Binge
//
//  Section header with icon badge for My List groups.
//

import SwiftUI

struct MyListSectionHeader: View {
    let icon: String
    let iconColor: Color
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 11) {
            // Icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(tint)
                    .frame(width: 30, height: 30)
                    .shadow(color: tint.opacity(0.35), radius: 12, y: 3)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom(.oswald.bold, size: 18))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.custom(.jetbrains.bold, size: 8.5))
                    .tracking(1.02)
                    .foregroundColor(.c2bMuted)
                    .textCase(.uppercase)
            }

            Spacer()
        }
    }
}
