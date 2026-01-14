//
//  EmptySlotCard.swift
//  Countdown2Binge
//

import SwiftUI

/// Empty placeholder card for Timeline when no shows exist
struct EmptySlotCard: View {
    let style: TimelineCardStyle
    let isFirst: Bool
    let isLast: Bool

    private var accentColor: Color {
        switch style {
        case .endingSoon, .premiering:
            return Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.4)
        case .anticipated:
            return Color(white: 0.3)
        }
    }

    private var placeholderText: String {
        switch style {
        case .endingSoon, .premiering:
            return "--"
        case .anticipated:
            return "TBD"
        }
    }

    private var placeholderLabel: String {
        switch style {
        case .endingSoon, .premiering:
            return "DAYS"
        case .anticipated:
            return "DATE"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left side: Placeholder countdown text with background to create line break
            VStack(alignment: .center, spacing: 0) {
                Text(placeholderText)
                    .font(.system(size: placeholderText == "TBD" ? 24 : 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(style == .premiering ? .white : accentColor)

                Text(placeholderLabel)
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(style == .premiering ? .white.opacity(0.7) : accentColor.opacity(0.7))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.black)
            .frame(width: 80)

            // Right side: Empty slot placeholder (matches show card dimensions)
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 175)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            accentColor.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                        )
                )
                .overlay(
                    Text("EMPTY SLOTS")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(Color(white: 0.35))
                )
        }
        .padding(.trailing, 24)
    }
}

#Preview("Empty Slots") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 0) {
            EmptySlotCard(style: .premiering, isFirst: true, isLast: false)
                .frame(height: 190)
            EmptySlotCard(style: .premiering, isFirst: false, isLast: false)
                .frame(height: 190)
            EmptySlotCard(style: .premiering, isFirst: false, isLast: true)
                .frame(height: 190)
            Spacer()
        }
        .padding(.top, 40)
    }
}
