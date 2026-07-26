//
//  ProfileStatCard.swift
//  Countdown2Binge
//
//  Reusable stat card for profile stats grid.
//

import SwiftUI

struct ProfileStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.custom(.oswald.bold, size: 36))
                .foregroundColor(.c2bTealBright)

            Text(label)
                .font(.custom(.jetbrains.regular, size: 9))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            ProfileStatCard(value: "110", label: "Episodes")
            ProfileStatCard(value: "44", label: "Seasons")
        }
        HStack(spacing: 12) {
            ProfileStatCard(value: "3D 12H", label: "Of Show Time")
            ProfileStatCard(value: "13", label: "Shows Followed")
        }
    }
    .padding(20)
    .background(Color.c2bBackground)
    .preferredColorScheme(.dark)
}
