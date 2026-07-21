//
//  ShowDetailFollowSection.swift
//  Countdown2Binge
//
//  Follow button and confirmation text for show detail view.
//

import SwiftUI

struct ShowDetailFollowSection: View {
    let show: ShowData
    let isFollowing: Bool
    let isLoading: Bool
    let onFollowTap: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Follow/Following button
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

                    Text(isFollowing ? "FOLLOWING" : "FOLLOW")
                        .font(.custom(.oswald.bold, size: 16))
                        .tracking(0.5)
                }
                .foregroundColor(isFollowing ? .c2bTealBright : Color(hex: "#04201c"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isFollowing ? Color.c2bTeal.opacity(0.15) : Color.c2bTeal)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isFollowing ? Color.c2bTeal.opacity(0.5) : Color.clear,
                            lineWidth: 1.5
                        )
                )
            }
            .disabled(isLoading)

            // Confirmation text (only when following)
            if isFollowing {
                ShowDetailFollowConfirmation(show: show)
            }
        }
    }
}

// MARK: - Follow Confirmation
struct ShowDetailFollowConfirmation: View {
    let show: ShowData

    private var daysUntilBingeReady: Int? {
        show.daysUntilFinale ?? show.daysUntilPremiere
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.c2bTeal)

            if let days = daysUntilBingeReady {
                Text("On your timeline \u{00B7} binge ready in ~\(days) days")
                    .font(.custom(.jetbrains.bold, size: 9.5))
                    .foregroundColor(.c2bTeal)
                    .tracking(0.8)
            } else {
                Text("Following \u{00B7} waiting in Anticipated")
                    .font(.custom(.jetbrains.bold, size: 9.5))
                    .foregroundColor(.c2bTeal)
                    .tracking(0.8)
            }
        }
        .textCase(.uppercase)
    }
}
