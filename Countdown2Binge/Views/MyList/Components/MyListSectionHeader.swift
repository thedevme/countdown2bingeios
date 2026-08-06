//
//  MyListSectionHeader.swift
//  Countdown2Binge
//
//  Section header with icon badge for My List groups.
//

import SwiftUI

struct MyListSectionHeader: View {
    let iconAsset: String
    let title: String
    let subtitle: String
    var tint: Color = .c2bTeal

    var body: some View {
        HStack(spacing: 11) {
            // Icon badge with rounded rect background
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(tint)
                    .frame(width: 30, height: 30)

                Image(iconAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
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
