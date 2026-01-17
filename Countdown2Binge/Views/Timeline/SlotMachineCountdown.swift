//
//  SlotMachineCountdown.swift
//  Countdown2Binge
//

import SwiftUI

/// Slot machine style countdown showing days or episodes until event with horizontal scrolling animation
struct SlotMachineCountdown: View {
    let value: Int?
    let displayMode: CountdownDisplayMode

    private var subtitle: String {
        switch displayMode {
        case .days: return "EPISODE IN"
        case .episodes: return "IN"
        }
    }

    private var accessibilityLabel: String {
        guard let value = value, value >= 0, value <= 99 else {
            return "Finale date to be determined"
        }
        let unit = displayMode == .days ? (value == 1 ? "day" : "days") : (value == 1 ? "episode" : "episodes")
        return "Finale in \(value) \(unit)"
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: -4) {
                Text("FINALE")
                    .font(.system(size: 28, weight: .heavy).width(.condensed))
                    .foregroundStyle(Color(white: 0.45))
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular).width(.condensed))
                    .foregroundStyle(Color(white: 0.45))
            }

            // Always use animated reel - handles nil and out-of-range by animating to TBD
            SlotMachineReel(value: value, displayMode: displayMode)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Horizontal reel that scrolls numbers left/right
private struct SlotMachineReel: View {
    let value: Int?
    let displayMode: CountdownDisplayMode

    // How many numbers visible on each side of center
    private let visibleRange = 2
    // Width of each number cell
    private let cellWidth: CGFloat = 90
    // Height of the cell
    private let cellHeight: CGFloat = 80
    // Maximum number to display (0-99 + TBD at 100)
    private let maxNumber = 99
    private let tbdIndex = 100
    // Pre-computed indices (0 on left, TBD on right)
    private let indices = Array(0...100)

    // The display value - nil or out-of-range means TBD (position 100)
    private var displayValue: Int {
        guard let value = value, value >= 0, value <= maxNumber else {
            return tbdIndex
        }
        return value
    }

    // Calculate the X offset to center the current value
    // Numbers go left to right: 0, 1, 2... 98, 99, TBD
    // Position of displayValue = displayValue directly
    private var xOffset: CGFloat {
        let centerIndex = CGFloat(tbdIndex) / 2.0
        let position = CGFloat(displayValue)
        return (centerIndex - position) * cellWidth
    }

    var body: some View {
        ZStack {
            // The today box (static, always centered)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "0D0D0D"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(hex: "252525"), lineWidth: 1)
                )
                .frame(width: cellWidth, height: cellHeight)

            // Scrolling number row (smallest on left, TBD on right)
            HStack(spacing: 0) {
                ForEach(indices, id: \.self) { number in
                    numberCell(for: number)
                }
            }
            .drawingGroup()
            .offset(x: xOffset)
            .animation(.easeOut(duration: 0.4), value: displayValue)
            .mask(
                // Fade out numbers at edges
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.15), location: 0.15),
                        .init(color: .white.opacity(0.35), location: 0.3),
                        .init(color: .white, location: 0.4),
                        .init(color: .white, location: 0.6),
                        .init(color: .white.opacity(0.35), location: 0.7),
                        .init(color: .white.opacity(0.15), location: 0.85),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: cellWidth * CGFloat(visibleRange * 2 + 1))
            )
        }
        .frame(width: cellWidth * CGFloat(visibleRange * 2 + 1), height: cellHeight)
        .clipped()
    }

    private func numberCell(for number: Int) -> some View {
        VStack(spacing: 0) {
            if number == tbdIndex {
                Text("TBD")
                    .font(.system(size: 51, weight: .heavy, design: .default).width(.condensed))
                    .foregroundStyle(.white)
            } else {
                Text(String(format: "%02d", number))
                    .font(.system(size: 61, weight: .heavy, design: .default).width(.condensed))
                    .foregroundStyle(.white)
            }

            Text(displayMode.unit)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Color(white: 0.5))
        }
        .frame(width: cellWidth, height: cellHeight)
    }
}

// MARK: - Previews

#Preview("Days") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            SlotMachineCountdown(value: 17, displayMode: .days)
            Spacer()
        }
        .padding(.top, 100)
    }
}

#Preview("Episodes") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            SlotMachineCountdown(value: 5, displayMode: .episodes)
            Spacer()
        }
        .padding(.top, 100)
    }
}

#Preview("TBD") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            SlotMachineCountdown(value: nil, displayMode: .days)
            Spacer()
        }
        .padding(.top, 100)
    }
}

#Preview("Animated") {
    struct AnimatedPreview: View {
        @State private var value = 5

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 40) {
                    SlotMachineCountdown(value: value, displayMode: .days)

                    HStack(spacing: 20) {
                        Button("5") { value = 5 }
                        Button("15") { value = 15 }
                        Button("25") { value = 25 }
                        Button("42") { value = 42 }
                    }
                    .font(.title)
                    .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.top, 100)
            }
        }
    }
    return AnimatedPreview()
}
