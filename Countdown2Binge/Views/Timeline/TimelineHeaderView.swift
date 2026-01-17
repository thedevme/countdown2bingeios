//
//  TimelineHeaderView.swift
//  Countdown2Binge
//

import SwiftUI
import UIKit

/// Header for the Timeline screen with refresh button and title
struct TimelineHeaderView: View {
    let lastUpdated: Date?
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onViewEntireTimeline: () -> Void

    // Responsive sizing for smaller screens
    private var isSmallScreen: Bool {
        UIScreen.main.bounds.width < 380
    }

    private var buttonSize: CGFloat { isSmallScreen ? 36 : 44 }

    // Colors
    private let buttonBackgroundColor = Color(red: 0x1A/255, green: 0x1A/255, blue: 0x1A/255)
    private let lastUpdatedColor = Color(red: 0x55/255, green: 0x55/255, blue: 0x55/255)

    private var lastUpdatedText: String {
        guard let date = lastUpdated else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Last updated: \(formatter.string(from: date).lowercased())"
    }

    var body: some View {
        VStack(spacing: 8) {
            // Top row: Refresh button aligned right
            HStack {
                Spacer()
                Button {
                    onRefresh()
                } label: {
                    Circle()
                        .fill(buttonBackgroundColor)
                        .frame(width: buttonSize, height: buttonSize)
                        .overlay(
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: isSmallScreen ? 14 : 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                .animation(
                                    isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                    value: isRefreshing
                                )
                        )
                }
                .disabled(isRefreshing)
                .accessibilityLabel(isRefreshing ? "Refreshing shows" : "Refresh shows")
                .accessibilityHint(isRefreshing ? "" : "Double tap to refresh show data")
            }

            // Last updated text (hidden on small screens to save space)
            if !lastUpdatedText.isEmpty && !isSmallScreen {
                Text(lastUpdatedText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(lastUpdatedColor)
            }

            // Section title
            Text("CURRENTLY AIRING")
                .font(.system(size: 36, weight: .heavy, design: .default).width(.condensed))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, isSmallScreen ? 12 : 16)
        .padding(.top, 16)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            TimelineHeaderView(
                lastUpdated: Date(),
                isRefreshing: false,
                onRefresh: {},
                onViewEntireTimeline: {}
            )
            Spacer()
        }
    }
}
