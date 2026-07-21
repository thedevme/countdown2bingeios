//
//  DiscoverTabSwitcher.swift
//  Countdown2Binge
//

import SwiftUI

struct DiscoverTabSwitcher: View {
    @Binding var selectedTab: DiscoverScreen.DiscoverTab

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { selectedTab = .soonerLater }) {
                HStack(spacing: 8) {
                    Text("SOONER")
                        .font(.custom(.oswald.bold, size: 13))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("LATER")
                        .font(.custom(.oswald.bold, size: 13))
                }
                .foregroundColor(selectedTab == .soonerLater ? Color(hex: "#04201c") : .c2bMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selectedTab == .soonerLater ? Color.c2bTeal : Color.clear)
                .cornerRadius(12)
            }

            Button(action: { selectedTab = .byNetwork }) {
                Text("BY NETWORK")
                    .font(.custom(.oswald.bold, size: 13))
                    .foregroundColor(selectedTab == .byNetwork ? Color(hex: "#04201c") : .c2bMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selectedTab == .byNetwork ? Color.c2bTeal : Color.clear)
                    .cornerRadius(12)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
