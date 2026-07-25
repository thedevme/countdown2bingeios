//
//  ShowDetailTopBar.swift
//  Countdown2Binge
//
//  Top bar for show detail view with back button and network chip.
//

import SwiftUI

struct ShowDetailTopBar: View {
    let isFollowing: Bool
    let networkName: String?
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            HStack {
                // Back button
                Button(action: onDismiss) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            DirectionalIcon(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }

                Spacer()

                // Network chip (when available)
                if let network = networkName {
                    ShowDetailNetworkChip(
                        networkName: network,
                        accentColor: networkAccentColor(for: network)
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 52)

            Spacer()
        }
    }

    private func networkAccentColor(for network: String) -> Color {
        switch network.lowercased() {
        case "netflix": return Color(hex: "#E50914")
        case "hbo", "max": return Color(hex: "#5A35E0")
        case "prime video", "amazon": return Color(hex: "#1FB6FF")
        case "hulu": return Color(hex: "#1CE783")
        case "apple tv+", "apple": return .c2bMuted
        case "disney+", "disney": return Color(hex: "#1FA2FF")
        default: return .c2bTeal
        }
    }
}

// MARK: - Not Tracking Badge
struct ShowDetailNotTrackingBadge: View {
    var body: some View {
        Text("not_tracking_yet")
            .font(.custom(.jetbrains.regular, size: 9.5))
            .tracking(1.8)
            .foregroundColor(.c2bTealBright)
    }
}

#Preview {
    ZStack {
        Color.black
        ShowDetailTopBar(
            isFollowing: false,
            networkName: "Netflix",
            onDismiss: {}
        )
    }
}
