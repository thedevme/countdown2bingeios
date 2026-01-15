//
//  TimelineHeaderView.swift
//  Countdown2Binge
//

import SwiftUI

/// Header for the Timeline screen with greeting, avatar, and actions
struct TimelineHeaderView: View {
    let lastUpdated: Date?
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onViewEntireTimeline: () -> Void

    // Responsive sizing for smaller screens
    private var isSmallScreen: Bool {
        UIScreen.main.bounds.width < 380
    }

    private var avatarSize: CGFloat { isSmallScreen ? 36 : 44 }
    private var buttonSize: CGFloat { isSmallScreen ? 36 : 44 }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "GOOD MORNING"
        case 12..<17: return "GOOD AFTERNOON"
        case 17..<21: return "GOOD EVENING"
        default: return "GOOD NIGHT"
        }
    }

    private var lastUpdatedText: String {
        guard let date = lastUpdated else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Last updated: \(formatter.string(from: date).lowercased())"
    }

    var body: some View {
        VStack(spacing: 8) {
            // Top row: Avatar, greeting, refresh button
            ZStack {
                // Left side: Avatar + greeting
                HStack(spacing: isSmallScreen ? 8 : 12) {
                    // Profile avatar
                    Circle()
                        .fill(Color(hex: "2A2A2A"))
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: isSmallScreen ? 14 : 18))
                                .foregroundStyle(Color(hex: "4A4A4A"))
                        )
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.system(size: isSmallScreen ? 9 : 10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(Color(hex: "666666"))

                        Text("Alex")
                            .font(.system(size: isSmallScreen ? 16 : 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(greeting.lowercased().capitalized), Alex")

                    Spacer()
                }

                // Right side: Refresh button (positioned absolutely)
                HStack {
                    Spacer()
                    Button {
                        onRefresh()
                    } label: {
                        Circle()
                            .fill(Color(hex: "1A1A1A"))
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
            }

            // Last updated text (hidden on small screens to save space)
            if !lastUpdatedText.isEmpty && !isSmallScreen {
                Text(lastUpdatedText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(hex: "555555"))
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
