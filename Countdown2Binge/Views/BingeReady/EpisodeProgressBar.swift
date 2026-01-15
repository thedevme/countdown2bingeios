//
//  EpisodeProgressBar.swift
//  Countdown2Binge
//

import SwiftUI

/// A progress bar visualizing episode count from premiere to finale.
/// Shows max 10 segments with a "+X" overflow label for additional episodes.
struct EpisodeProgressBar: View {
    let watchedCount: Int
    let totalCount: Int
    let maxSegments: Int = 10

    // App's teal accent
    private let accentColor = Color(red: 0.45, green: 0.90, blue: 0.70)
    private let segmentHeight: CGFloat = 16
    private let cornerRadius: CGFloat = 4

    private var displayedTotal: Int {
        min(totalCount, maxSegments)
    }

    private var displayedWatched: Int {
        min(watchedCount, maxSegments)
    }

    /// Overflow shows additional episodes beyond 10
    private var overflowCount: Int {
        max(0, totalCount - maxSegments)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar with segments
            HStack(spacing: 1) { // 1px separator (background shows through)
                ForEach(0..<displayedTotal, id: \.self) { index in
                    AnimatedSegment(
                        index: index,
                        totalSegments: displayedTotal,
                        isFilled: index < displayedWatched,
                        isFirst: index == 0,
                        accentColor: accentColor,
                        cornerRadius: cornerRadius
                    )
                }

                // Overflow indicator
                if overflowCount > 0 {
                    overflowLabel
                }
            }
            .frame(height: segmentHeight)
            .padding(.horizontal, 10)

            // PREMIERE / FINALE labels
            HStack {
                Text("PREMIERE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                Text("FINALE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 10)
        }
    }

    private var overflowLabel: some View {
        Text("+\(overflowCount)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.7))
            .padding(.leading, 8)
            .fixedSize()
    }
}

// MARK: - Animated Segment

private struct AnimatedSegment: View {
    let index: Int
    let totalSegments: Int
    let isFilled: Bool
    let isFirst: Bool
    let accentColor: Color
    let cornerRadius: CGFloat

    @State private var displayedFilled: Bool = false
    @State private var offset: CGFloat = 0

    private let emptyColor = Color.white.opacity(0.15)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background (empty state)
                if isFirst {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: cornerRadius
                    )
                    .fill(emptyColor)
                } else {
                    Rectangle()
                        .fill(emptyColor)
                }

                // Filled state (animates in/out)
                if isFirst {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: cornerRadius
                    )
                    .fill(accentColor)
                    .offset(y: offset)
                } else {
                    Rectangle()
                        .fill(accentColor)
                        .offset(y: offset)
                }
            }
            .clipShape(Rectangle())
        }
        .onAppear {
            displayedFilled = isFilled
            offset = isFilled ? 0 : 20
        }
        .onChange(of: isFilled) { oldValue, newValue in
            if newValue {
                // Filling: animate left to right (premiere to finale)
                let delay = Double(index) * 0.08
                offset = 20
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75).delay(delay)) {
                    offset = 0
                }
            } else {
                // Emptying: animate right to left (finale to premiere)
                let reverseIndex = totalSegments - 1 - index
                let delay = Double(reverseIndex) * 0.08
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75).delay(delay)) {
                    offset = -20
                }
                // Reset for next animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + delay) {
                    offset = 20
                }
            }
            displayedFilled = newValue
        }
    }
}

// MARK: - Preview

#Preview("5 of 10 Watched") {
    ZStack {
        Color.black.ignoresSafeArea()

        EpisodeProgressBar(watchedCount: 5, totalCount: 10)
            .padding(.horizontal, 24)
    }
}

#Preview("All 10 Watched") {
    ZStack {
        Color.black.ignoresSafeArea()

        EpisodeProgressBar(watchedCount: 10, totalCount: 10)
            .padding(.horizontal, 24)
    }
}

#Preview("14 of 24 Watched (+4)") {
    ZStack {
        Color.black.ignoresSafeArea()

        EpisodeProgressBar(watchedCount: 14, totalCount: 24)
            .padding(.horizontal, 24)
    }
}

#Preview("None Watched") {
    ZStack {
        Color.black.ignoresSafeArea()

        EpisodeProgressBar(watchedCount: 0, totalCount: 8)
            .padding(.horizontal, 24)
    }
}
