//
//  CountdownText.swift
//  Countdown2Binge
//

import SwiftUI

/// The type of countdown being displayed
enum CountdownType {
    case days
    case episodes

    var singularLabel: String {
        switch self {
        case .days: "DAY"
        case .episodes: "EPISODE"
        }
    }

    var pluralLabel: String {
        switch self {
        case .days: "DAYS"
        case .episodes: "EPISODES"
        }
    }

    func label(for count: Int) -> String {
        count == 1 ? singularLabel : pluralLabel
    }
}

/// Display size variants for countdown text
enum CountdownSize {
    case compact
    case regular
    case large

    var numberFont: Font {
        switch self {
        case .compact: .title3.monospacedDigit()
        case .regular: .title.monospacedDigit()
        case .large: .system(size: 48, weight: .bold, design: .rounded).monospacedDigit()
        }
    }

    var labelFont: Font {
        switch self {
        case .compact: .caption2
        case .regular: .caption
        case .large: .subheadline
        }
    }

    var spacing: CGFloat {
        switch self {
        case .compact: 2
        case .regular: 4
        case .large: 6
        }
    }
}

/// A typography-focused view displaying countdown numbers with labels.
/// Shows "X DAYS" or "X EPISODES" in a clean, prominent style.
struct CountdownText: View {
    let count: Int
    let type: CountdownType
    let size: CountdownSize

    init(count: Int, type: CountdownType, size: CountdownSize = .regular) {
        self.count = count
        self.type = type
        self.size = size
    }

    var body: some View {
        VStack(spacing: size.spacing) {
            Text("\(count)")
                .font(size.numberFont)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(type.label(for: count))
                .font(size.labelFont)
                .fontWeight(.semibold)
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - Horizontal Variant

/// Horizontal layout variant showing "X DAYS" inline
struct CountdownTextInline: View {
    let count: Int
    let type: CountdownType

    var body: some View {
        HStack(spacing: 6) {
            Text("\(count)")
                .font(.body.monospacedDigit())
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(type.label(for: count))
                .font(.caption)
                .fontWeight(.medium)
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - Preview

#Preview("Countdown Sizes") {
    HStack(spacing: 40) {
        CountdownText(count: 5, type: .days, size: .compact)
        CountdownText(count: 12, type: .days, size: .regular)
        CountdownText(count: 3, type: .days, size: .large)
    }
    .padding(32)
    .background(Color(white: 0.08))
}

#Preview("Countdown Types") {
    HStack(spacing: 40) {
        CountdownText(count: 7, type: .days)
        CountdownText(count: 10, type: .episodes)
    }
    .padding(32)
    .background(Color(white: 0.08))
}

#Preview("Singular/Plural") {
    HStack(spacing: 40) {
        CountdownText(count: 1, type: .days)
        CountdownText(count: 1, type: .episodes)
    }
    .padding(32)
    .background(Color(white: 0.08))
}

#Preview("Inline Variant") {
    VStack(spacing: 16) {
        CountdownTextInline(count: 5, type: .days)
        CountdownTextInline(count: 8, type: .episodes)
    }
    .padding(32)
    .background(Color(white: 0.08))
}
