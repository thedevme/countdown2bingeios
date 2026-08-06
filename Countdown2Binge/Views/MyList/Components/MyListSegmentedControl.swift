//
//  MyListSegmentedControl.swift
//  Countdown2Binge
//
//  3-button segmented control for Active/Ended/Archived tabs with count badges.
//

import SwiftUI

struct MyListSegmentedControl: View {
    @Binding var selectedTab: ListTabScreen
    let activeCount: Int
    let endedCount: Int
    let archivedCount: Int

    private func count(for tab: ListTabScreen) -> Int {
        switch tab {
        case .active: return activeCount
        case .ended: return endedCount
        case .archived: return archivedCount
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ListTabScreen.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                let tabCount = count(for: tab)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(tab.label)
                            .font(.custom(.jetbrains.bold, size: 10))
                            .tracking(1.0)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        // Count badge
                        Text("\(tabCount)")
                            .font(.custom(.jetbrains.bold, size: 9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                isSelected
                                    ? Color(hex: "#04201c").opacity(0.3)
                                    : Color.white.opacity(0.08)
                            )
                            .cornerRadius(6)
                    }
                    .foregroundColor(isSelected ? Color(hex: "#04201c") : .c2bDim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(isSelected ? Color.c2bTeal : Color.clear)
                    .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
