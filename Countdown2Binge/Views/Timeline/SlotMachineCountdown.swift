//
//  SlotMachineCountdown.swift
//  Countdown2Binge
//

import SwiftUI

/// Slot machine style countdown showing days until event with horizontal scrolling animation
struct SlotMachineCountdown: View {
    let days: Int
    let targetDate: Date

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date()).uppercased()
    }

    var body: some View {
        VStack(spacing: 16) {
            // Today and date labels
            VStack(spacing: 0) {
                Text("TODAY")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color(white: 0.45))

                Text(dateLabel)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color(white: 0.45))
            }

            // Slot machine reel (horizontal)
            SlotMachineReel(value: days)
        }
        .padding(.vertical, 20)
    }
}

/// Horizontal reel that scrolls numbers left/right
private struct SlotMachineReel: View {
    let value: Int

    // How many numbers visible on each side of center
    private let visibleRange = 2
    // Width of each number cell
    private let cellWidth: CGFloat = 85
    // Height of the cell
    private let cellHeight: CGFloat = 100
    // Maximum number to display
    private let maxNumber = 99

    // Calculate the X offset to center the current value
    // HStack is centered by ZStack, so item at index maxNumber/2 is at center
    // To show item N at center, we need to shift by (centerIndex - N) * cellWidth
    private var xOffset: CGFloat {
        let centerIndex = CGFloat(maxNumber) / 2.0
        return (centerIndex - CGFloat(value)) * cellWidth
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

            // Scrolling number row
            HStack(spacing: 0) {
                ForEach(0...maxNumber, id: \.self) { number in
                    numberCell(for: number)
                }
            }
            .offset(x: xOffset)
            .animation(.timingCurve(0.0, 0.0, 0.15, 1, duration: 0.6), value: value)
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
            Text(String(format: "%02d", number))
                .font(.system(size: 65, weight: .heavy, design: .default).width(.condensed))
                .monospacedDigit()
                .foregroundStyle(.white)

            Text("DAYS")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Color(white: 0.5))
        }
        .frame(width: cellWidth, height: cellHeight)
    }
}

// MARK: - Previews

#Preview("Static") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            SlotMachineCountdown(
                days: 17,
                targetDate: Date().addingTimeInterval(86400 * 17)
            )
            Spacer()
        }
        .padding(.top, 100)
    }
}

#Preview("Animated") {
    struct AnimatedPreview: View {
        @State private var days = 5

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 40) {
                    SlotMachineCountdown(
                        days: days,
                        targetDate: Date().addingTimeInterval(86400 * Double(days))
                    )

                    HStack(spacing: 20) {
                        Button("5") { days = 5 }
                        Button("15") { days = 15 }
                        Button("25") { days = 25 }
                        Button("42") { days = 42 }
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
