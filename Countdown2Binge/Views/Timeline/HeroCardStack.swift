//
//  HeroCardStack.swift
//  Countdown2Binge
//

import SwiftUI

/// A fanned card stack component for airing shows on the timeline.
/// Shows are displayed with horizontal swiping to navigate between cards.
/// Limited to 3 cards max with a "+X MORE" badge for additional shows.
struct HeroCardStack: View {
    typealias ShowDataTuple = (show: ShowData, daysUntilFinale: Int?, episodesUntilFinale: Int?, finaleDate: Date?)

    let shows: [ShowDataTuple]
    @Binding var currentIndex: Int
    let onShowTap: (ShowData) -> Void
    let cardSize: CGSize

    // Limit to 3 cards in the stack
    private let maxVisibleCards = 3

    /// Shows visible in the stack (max 3)
    private var visibleShows: [ShowDataTuple] {
        Array(shows.prefix(maxVisibleCards))
    }

    /// Number of additional shows beyond the 3 visible
    private var additionalShowsCount: Int {
        max(0, shows.count - maxVisibleCards)
    }

    /// The 4th show (for thumbnail in badge)
    private var nextShow: ShowDataTuple? {
        shows.count > maxVisibleCards ? shows[maxVisibleCards] : nil
    }

    // Default card dimensions (aspect ratio 1.5)
    static let defaultWidth: CGFloat = 280
    static let defaultHeight: CGFloat = 420

    // Gesture state
    @State private var dragOffset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Scale factor for responsive sizing
    private var scaleFactor: CGFloat { cardSize.width / Self.defaultWidth }

    // Layout constants - fanned card display (scaled)
    private var fanSpread: CGFloat { 28 * scaleFactor }      // Horizontal spread between cards
    private let fanRotation: Double = 5                       // Rotation angle per position (degrees)
    private var fanYOffset: CGFloat { 8 * scaleFactor }      // Vertical drop per position
    private let scaleStep: CGFloat = 0.06                     // Scale reduction per position
    private var swipeThreshold: CGFloat { 80 * scaleFactor } // Swipe threshold

    var body: some View {
        ZStack {
            // Card Stack (limited to 3)
            ForEach(0..<visibleShows.count, id: \.self) { index in
                let showTuple = visibleShows[index]
                let position = relativePosition(for: index)
                let absPosition = abs(position)

                // Only render visible cards (up to 2 on each side)
                if absPosition <= 2 {
                    let isFrontCard = index == currentIndex
                    let dragProgress = isFrontCard ? (dragOffset / 200) : 0

                    HeroShowCard(
                        show: showTuple.show,
                        daysUntilFinale: showTuple.daysUntilFinale
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .drawingGroup() // Rasterizes entire card for smoother animation
                    .scaleEffect(scale(for: position))
                    .offset(x: fanXOffset(for: position, dragOffset: dragOffset, isFrontCard: isFrontCard))
                    .offset(y: fanYPosition(for: position))
                    .rotationEffect(.degrees(fanAngle(for: CGFloat(position) + dragProgress)))
                    .zIndex(zIndex(for: index))
                    .opacity(opacity(for: position))
                    .animation(reduceMotion ? .none : .interpolatingSpring(stiffness: 300, damping: 40), value: currentIndex)
                    .onTapGesture {
                        if isFrontCard {
                            onShowTap(showTuple.show)
                        }
                    }
                }
            }

            // "+X MORE" Badge
            if additionalShowsCount > 0, let nextShow = nextShow {
                MoreShowsBadge(
                    count: additionalShowsCount,
                    nextShowPosterURL: nextShow.show.posterURL
                )
                .offset(x: cardSize.width / 2 - 20, y: cardSize.height / 2 - 40)
                .zIndex(Double(shows.count * 2 + 1))
            }
        }
        .frame(
            width: cardSize.width + (120 * scaleFactor), // Extra space for fanned cards
            height: cardSize.height + (40 * scaleFactor)
        )
        .gesture(swipeGesture)
    }

    // MARK: - Card Positioning

    private func relativePosition(for index: Int) -> Int {
        // Wrap-around calculation for looping (using visible shows only)
        let raw = index - currentIndex
        let count = visibleShows.count
        if count <= 1 { return raw }

        let halfCount = count / 2
        if raw > halfCount {
            return raw - count
        } else if raw < -halfCount {
            return raw + count
        }
        return raw
    }

    private func scale(for position: Int) -> CGFloat {
        let absPosition = abs(position)
        return max(0.75, 1.0 - (scaleStep * CGFloat(absPosition)))
    }

    private func fanXOffset(for position: Int, dragOffset: CGFloat, isFrontCard: Bool) -> CGFloat {
        let baseOffset = CGFloat(position) * fanSpread
        if isFrontCard {
            return baseOffset + dragOffset
        } else {
            return baseOffset
        }
    }

    private func fanYPosition(for position: Int) -> CGFloat {
        // Cards further from center drop down
        return CGFloat(abs(position)) * fanYOffset
    }

    private func fanAngle(for position: CGFloat) -> Double {
        // Cards rotate away from center like a hand of cards
        return Double(position) * fanRotation
    }

    private func zIndex(for index: Int) -> Double {
        let position = relativePosition(for: index)
        if position == 0 {
            return Double(visibleShows.count * 2)
        }
        return Double(visibleShows.count - abs(position))
    }

    private func opacity(for position: Int) -> Double {
        let absPos = abs(position)
        if absPos == 0 { return 1.0 }
        if absPos == 1 { return 0.7 }
        if absPos == 2 { return 0.4 }
        return 0.2
    }

    // MARK: - Gesture Handling

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                handleSwipeEnd(translation: value.translation.width)
            }
    }

    private func handleSwipeEnd(translation: CGFloat) {
        let actions = {
            if translation > self.swipeThreshold && self.visibleShows.count > 1 {
                // RIGHT: Next show
                self.goToNextShow()
                SoundManager.shared.playCardSwipeWithHaptic()
            } else if translation < -self.swipeThreshold && self.visibleShows.count > 1 {
                // LEFT: Previous show
                self.goToPreviousShow()
                SoundManager.shared.playCardSwipeWithHaptic()
            }

            self.dragOffset = 0
        }

        if reduceMotion {
            actions()
        } else {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 40)) {
                actions()
            }
        }
    }

    private func goToNextShow() {
        currentIndex = (currentIndex + 1) % visibleShows.count
    }

    private func goToPreviousShow() {
        currentIndex = (currentIndex - 1 + visibleShows.count) % visibleShows.count
    }
}

// MARK: - More Shows Badge
private struct MoreShowsBadge: View {
    let count: Int
    let nextShowPosterURL: URL?

    var body: some View {
        HStack(spacing: 8) {
            // Thumbnail of next show
            if let url = nextShowPosterURL {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 26, height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } placeholder: {
                    PlaceholderView(cornerRadius: 5)
                        .frame(width: 26, height: 26)
                }
            }

            Text(String(localized: "hero_more_count \(count)"))
                .font(.custom(.jetbrains.bold, size: 11))
                .tracking(1.1)
                .foregroundColor(.c2bTealBright)
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(hex: "#0e0e0f").opacity(0.9))
        )
        .overlay(
            Capsule()
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
    }
}
