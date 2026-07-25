//
//  DetailUnfollowButton.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailUnfollowButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                Text("unfollow_show")
                    .font(.custom(.jetbrains.bold, size: 10.5))
                    .textCase(.uppercase)
                    .tracking(1.4)
            }
            .foregroundColor(.c2bMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .cornerRadius(13)
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}
