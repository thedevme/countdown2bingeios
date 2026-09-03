//
//  FollowedDetailTabBar.swift
//  Countdown2Binge
//
//  Segmented tab bar for FollowedShowDetail view.
//  Matches BingeSegmentBar styling.
//

import SwiftUI

enum FollowedDetailTab: CaseIterable {
    case seasonInfo
    case showInfo
    case spinoffs

    var localizedTitle: String {
        switch self {
        case .seasonInfo: return String(localized: "tab_season_info")
        case .showInfo: return String(localized: "tab_show_info")
        case .spinoffs: return String(localized: "tab_spinoffs")
        }
    }
}

struct FollowedDetailTabBar: View {
    @Binding var selectedTab: FollowedDetailTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FollowedDetailTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab

                Button(action: { selectedTab = tab }) {
                    Text(tab.localizedTitle)
                        .font(.custom(.jetbrains.bold, size: 10))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundColor(isSelected ? .c2bTealBright : .c2bMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Color.c2bTeal.opacity(0.08) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        FollowedDetailTabBar(selectedTab: .constant(.seasonInfo))
        FollowedDetailTabBar(selectedTab: .constant(.spinoffs))
    }
    .padding(.horizontal, 22)
    .background(Color.c2bBackground)
    .preferredColorScheme(.dark)
}
