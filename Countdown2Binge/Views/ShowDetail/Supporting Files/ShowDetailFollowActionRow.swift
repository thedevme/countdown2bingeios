//
//  ShowDetailFollowActionRow.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 8/8/26.
//
import SwiftUI

struct ShowDetailFollowActionRow: View {
    let isFollowing: Bool
    let isLoading: Bool
    let onFollowTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Follow button
            Button(action: onFollowTap) {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(isFollowing ? .c2bTealBright : Color(hex: "#04201c"))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isFollowing ? "checkmark" : "plus")
                            .font(.system(size: 16, weight: .bold))
                    }

                    Text(isFollowing ? String(localized: "button_following") : String(localized: "button_follow_show"))
                        .font(.custom(.oswald.bold, size: 17))
                        .tracking(0.4)
                }
                .foregroundColor(isFollowing ? .c2bTealBright : Color(hex: "#04201c"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isFollowing ? Color.c2bTeal.opacity(0.15) : Color.c2bTeal)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFollowing ? Color.c2bTeal.opacity(0.5) : .clear, lineWidth: 1)
                )
            }
            .disabled(isLoading)
        }
    }
}
