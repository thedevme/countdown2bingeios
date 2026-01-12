//
//  StateBadge.swift
//  Countdown2Binge
//

import SwiftUI

/// Visual style variants for state badges
enum StateBadgeStyle {
    /// Airing - show is currently releasing episodes
    case airing

    /// Premiering - season is about to start
    case premiering

    /// Binge Ready - season is complete and ready to watch
    case bingeReady

    /// Anticipated - announced but no air date
    case anticipated

    /// Cancelled - show was cancelled
    case cancelled

    /// Watched - user has completed watching
    case watched

    var label: String {
        switch self {
        case .airing: "AIRING"
        case .premiering: "PREMIERING"
        case .bingeReady: "BINGE READY"
        case .anticipated: "ANTICIPATED"
        case .cancelled: "CANCELLED"
        case .watched: "WATCHED"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .airing: Color(red: 0.95, green: 0.95, blue: 0.97)
        case .premiering: Color(red: 0.95, green: 0.95, blue: 0.97)
        case .bingeReady: Color(red: 0.12, green: 0.12, blue: 0.14)
        case .anticipated: Color(red: 0.85, green: 0.85, blue: 0.88)
        case .cancelled: Color(red: 0.95, green: 0.95, blue: 0.97)
        case .watched: Color(red: 0.95, green: 0.95, blue: 0.97)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .airing:
            // Warm amber - active, ongoing
            Color(red: 0.85, green: 0.55, blue: 0.25)
        case .premiering:
            // Soft blue - upcoming, anticipated
            Color(red: 0.35, green: 0.55, blue: 0.85)
        case .bingeReady:
            // Bright mint - success, ready to go
            Color(red: 0.45, green: 0.90, blue: 0.70)
        case .anticipated:
            // Muted slate - waiting, future
            Color(red: 0.35, green: 0.38, blue: 0.45)
        case .cancelled:
            // Muted rose - ended, but not negative
            Color(red: 0.65, green: 0.40, blue: 0.45)
        case .watched:
            // Soft purple - completed, satisfied
            Color(red: 0.55, green: 0.45, blue: 0.70)
        }
    }
}

/// A capsule badge displaying the current state of a show or season.
/// Uses distinct colors to communicate status at a glance.
struct StateBadge: View {
    let style: StateBadgeStyle

    var body: some View {
        Text(style.label)
            .font(.caption2)
            .fontWeight(.bold)
            .tracking(0.8)
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(style.backgroundColor)
            )
    }
}

// MARK: - Convenience Initializers

extension StateBadge {
    /// Initialize from ShowLifecycleState
    init(lifecycleState: ShowLifecycleState) {
        switch lifecycleState {
        case .anticipated:
            self.style = .anticipated
        case .airing:
            self.style = .airing
        case .completed:
            self.style = .bingeReady
        case .cancelled:
            self.style = .cancelled
        }
    }
}

// MARK: - Preview

#Preview("All States") {
    VStack(spacing: 16) {
        StateBadge(style: .airing)
        StateBadge(style: .premiering)
        StateBadge(style: .bingeReady)
        StateBadge(style: .anticipated)
        StateBadge(style: .cancelled)
        StateBadge(style: .watched)
    }
    .padding(32)
    .background(Color(white: 0.08))
}

#Preview("On Card") {
    ZStack(alignment: .topTrailing) {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(white: 0.15))
            .frame(width: 200, height: 120)

        StateBadge(style: .airing)
            .padding(12)
    }
    .padding()
    .background(Color.black)
}
