//
//  DiscoverNetworkChips.swift
//  Countdown2Binge
//
//  Horizontal scrolling network filter chips.
//

import SwiftUI

struct DiscoverNetworkChips: View {
    @Binding var selectedNetwork: String
    let networks: [NetworkDefinition]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "All networks" chip
                NetworkChip(
                    name: String(localized: "discover_all_networks"),
                    color: nil,
                    isSelected: selectedNetwork == "all",
                    onTap: { selectedNetwork = "all" }
                )

                // Network chips
                ForEach(networks) { network in
                    NetworkChip(
                        name: network.name,
                        color: network.color,
                        isSelected: selectedNetwork == String(network.id),
                        onTap: { selectedNetwork = String(network.id) }
                    )
                }
            }
            .padding(.horizontal, C2BLayout.horizontalPadding)
        }
    }
}

// MARK: - Network Chip
private struct NetworkChip: View {
    let name: String
    let color: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let color = color {
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 8, height: 8)
                }

                Text(name)
                    .uiStyle(
                        size: 13,
                        weight: .medium,
                        color: isSelected ? Color(hex: "#04201c") : .c2bText
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.c2bTeal : Color.white.opacity(0.08))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
        }
    }
}
