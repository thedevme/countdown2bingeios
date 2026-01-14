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
            // Top row: Avatar, greeting, notification
            HStack {
                // Profile avatar
                Circle()
                    .fill(Color(hex: "2A2A2A"))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "4A4A4A"))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: "666666"))

                    Text("Alex")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                // Refresh button
                Button {
                    onRefresh()
                } label: {
                    Circle()
                        .fill(Color(hex: "1A1A1A"))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                .animation(
                                    isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                    value: isRefreshing
                                )
                        )
                }
                .disabled(isRefreshing)
            }

            // Last updated text
            if !lastUpdatedText.isEmpty {
                Text(lastUpdatedText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(hex: "555555"))
            }

            // Section title
            Text("CURRENTLY AIRING")
                .font(.system(size: 36, weight: .heavy, design: .default).width(.condensed))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 24)
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
