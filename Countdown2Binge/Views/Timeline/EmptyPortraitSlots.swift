//
//  EmptyPortraitSlots.swift
//  Countdown2Binge
//

import SwiftUI

/// Empty portrait placeholder slots shown when section is collapsed with no shows
struct EmptyPortraitSlots: View {
    let style: TimelineCardStyle

    private var accentColor: Color {
        switch style {
        case .endingSoon, .premiering:
            return Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.4)
        case .anticipated:
            return Color(white: 0.3)
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            ForEach(0..<3, id: \.self) { index in
                EmptyPortraitCard(
                    style: style,
                    isFirst: index == 0,
                    isLast: index == 2
                )
                .frame(height: 320)
            }
        }
    }
}

/// Individual empty portrait card with timeline connector
private struct EmptyPortraitCard: View {
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
                    .foregroundStyle(style == .anticipated ? accentColor : .white)

                Text(placeholderLabel)
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(style == .anticipated ? accentColor.opacity(0.7) : .white.opacity(0.7))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.black)
            .frame(width: 80)

            Spacer()

            // Right side: Empty portrait placeholder (230x310, corner radius 15, floats right)
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(
                        accentColor.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                    )

                Text("EMPTY")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color(white: 0.35))
            }
            .frame(width: 230, height: 310)
        }
        .padding(.trailing, 24)
    }
}

#Preview("Empty Portrait Slots") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 0) {
            EmptyPortraitSlots(style: .premiering)
            Spacer()
        }
        .padding(.top, 40)
    }
}
