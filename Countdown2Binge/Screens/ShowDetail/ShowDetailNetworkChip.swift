//
//  ShowDetailNetworkChip.swift
//  Countdown2Binge
//

import SwiftUI

struct ShowDetailNetworkChip: View {
    let networkName: String
    let accentColor: Color

    init(networkName: String, accentColor: Color = .c2bTeal) {
        self.networkName = networkName
        self.accentColor = accentColor
    }

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(accentColor)
                .frame(width: 9, height: 9)

            Text(networkName.uppercased())
                .font(.custom(.jetbrains.bold, size: 9))
                .tracking(0.9)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.leading, -4)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 12) {
            ShowDetailNetworkChip(networkName: "Netflix", accentColor: Color(hex: "#E50914"))
            ShowDetailNetworkChip(networkName: "HBO", accentColor: Color(hex: "#5A35E0"))
            ShowDetailNetworkChip(networkName: "Apple TV+", accentColor: .c2bMuted)
        }
    }
}
