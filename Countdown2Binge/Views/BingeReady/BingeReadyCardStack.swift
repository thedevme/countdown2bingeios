//
//  BingeReadyCardStack.swift
//  Countdown2Binge
//

import SwiftUI

/// A vertically stacked card component for binge-ready seasons with 4-directional gestures.
/// - Swipe RIGHT: Next season (card goes to back)
/// - Swipe LEFT: Previous season
/// - Swipe DOWN: Mark watched (with confirmation)
/// - Swipe UP: Delete show (with confirmation)
struct BingeReadyCardStack: View {
    let seasons: [Season]
    let show: Show
    @Binding var currentIndex: Int
    let cardSize: CGSize
    let onMarkWatched: (Season) -> Void
    let onDeleteShow: () -> Void
    let onTapCard: () -> Void

    // Gesture state
    @State private var dragOffset: CGSize = .zero
    @State private var activeGesture: GestureDirection? = nil

    // Confirmation state
    @State private var showDeleteConfirmation: Bool = false

    // Scale factor for responsive sizing
    private var scaleFactor: CGFloat { cardSize.width / BingeReadyPosterCard.defaultWidth }

    // Layout constants - fanned card display (scaled)
    private var fanSpread: CGFloat { 28 * scaleFactor }      // Horizontal spread between cards
    private let fanRotation: Double = 5                       // Rotation angle per position (degrees)
    private var fanYOffset: CGFloat { 8 * scaleFactor }      // Vertical drop per position
    private let scaleStep: CGFloat = 0.06                     // Scale reduction per position
    private var swipeThreshold: CGFloat { 80 * scaleFactor } // Swipe threshold
    private let maxVisibleCards: Int = 5                      // Show up to 5 cards

    private enum GestureDirection {
        case horizontal
        case vertical
    }

    var body: some View {
        VStack(spacing: 20 * scaleFactor) {
            // Card stack - fanned display
            ZStack {
                ForEach(Array(seasons.enumerated()), id: \.element.id) { index, season in
                    let position = relativePosition(for: index)
                    let absPosition = abs(position)

                    // Only render visible cards (up to 2 on each side)
                    if absPosition <= 2 {
                        let isFrontCard = index == currentIndex
                        let dragProgress = isFrontCard ? (dragOffset.width / 200) : 0

                        BingeReadyPosterCard(
                            season: season,
                            show: show,
                            isTopCard: isFrontCard,
                            cardSize: cardSize
                        )
                        .drawingGroup() // Rasterizes entire card for smoother animation
                        .scaleEffect(scale(for: position))
                        .offset(x: fanXOffset(for: position, dragOffset: dragOffset.width, isFrontCard: isFrontCard))
                        .offset(y: fanYPosition(for: position) + (isFrontCard ? dragOffset.height : 0))
                        .rotationEffect(.degrees(fanAngle(for: CGFloat(position) + dragProgress)))
                        .zIndex(zIndex(for: index))
                        .opacity(opacity(for: position))
                        .animation(.interpolatingSpring(stiffness: 300, damping: 40), value: currentIndex)
                        .onTapGesture {
                            if isFrontCard {
                                onTapCard()
                            }
                        }
                    }
                }
            }
            .frame(
                width: cardSize.width + (120 * scaleFactor), // Extra space for fanned cards
                height: cardSize.height + (40 * scaleFactor)
            )
            .gesture(swipeGesture)

            // Confirmation UI (only shows when needed)
            if showDeleteConfirmation {
                deleteConfirmationView
            }
        }
    }

    // MARK: - Card Positioning

    private func relativePosition(for index: Int) -> Int {
        // Wrap-around calculation for looping
        let raw = index - currentIndex
        let count = seasons.count
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
            return Double(seasons.count * 2)
        }
        return Double(seasons.count - abs(position))
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
                // Lock direction on first significant movement
                if activeGesture == nil {
                    activeGesture = detectDirection(value.translation)
                }

                // Only update offset in locked direction
                switch activeGesture {
                case .horizontal:
                    dragOffset = CGSize(width: value.translation.width, height: 0)
                case .vertical:
                    dragOffset = CGSize(width: 0, height: value.translation.height)
                case .none:
                    break
                }
            }
            .onEnded { value in
                handleSwipeEnd(translation: value.translation)
                activeGesture = nil
            }
    }

    private func detectDirection(_ translation: CGSize) -> GestureDirection? {
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        let threshold: CGFloat = 15

        if absX < threshold && absY < threshold { return nil }
        return absX > absY ? .horizontal : .vertical
    }

    private func handleSwipeEnd(translation: CGSize) {
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 40)) {
            switch activeGesture {
            case .horizontal:
                if translation.width > swipeThreshold && seasons.count > 1 {
                    // RIGHT: Next season
                    goToNextSeason()
                    SoundManager.shared.playCardSwipeWithHaptic()
                } else if translation.width < -swipeThreshold && seasons.count > 1 {
                    // LEFT: Previous season
                    goToPreviousSeason()
                    SoundManager.shared.playCardSwipeWithHaptic()
                }

            case .vertical:
                if translation.height > swipeThreshold {
                    // DOWN: Mark watched immediately
                    onMarkWatched(seasons[currentIndex])
                    SoundManager.shared.playCardSwipeWithHaptic()
                } else if translation.height < -swipeThreshold {
                    // UP: Delete show
                    showDeleteConfirmation = true
                    SoundManager.shared.playCardSwipeWithHaptic()
                }

            case .none:
                break
            }

            dragOffset = .zero
        }
    }

    private func goToNextSeason() {
        currentIndex = (currentIndex + 1) % seasons.count
    }

    private func goToPreviousSeason() {
        currentIndex = (currentIndex - 1 + seasons.count) % seasons.count
    }

    // MARK: - Delete Confirmation

    private var deleteConfirmationView: some View {
        HStack(spacing: 12) {
            Text("Remove \(show.name)?")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    showDeleteConfirmation = false
                    onDeleteShow()
                }
            } label: {
                Text("Yes")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.red)
                    )
            }

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    showDeleteConfirmation = false
                }
            } label: {
                Text("No")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.1))
                    )
            }
        }
        .frame(height: 32)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Preview

#Preview("Multiple Seasons") {
    struct PreviewWrapper: View {
        @State private var currentIndex = 0

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                BingeReadyCardStack(
                    seasons: [
                        Season(id: 1, seasonNumber: 2, name: "Season 2", overview: nil, posterPath: nil, airDate: Date().addingTimeInterval(-86400 * 30), episodeCount: 24, episodes: [], watchedDate: nil),
                        Season(id: 2, seasonNumber: 1, name: "Season 1", overview: nil, posterPath: nil, airDate: Date().addingTimeInterval(-86400 * 365), episodeCount: 9, episodes: [], watchedDate: nil)
                    ],
                    show: Show(id: 1, name: "The Last of Us", overview: nil, posterPath: nil, backdropPath: nil, logoPath: nil, firstAirDate: nil, status: .returning, genres: [], networks: [], seasons: [], numberOfSeasons: 2, numberOfEpisodes: 33, inProduction: true),
                    currentIndex: $currentIndex,
                    cardSize: CGSize(width: BingeReadyPosterCard.defaultWidth, height: BingeReadyPosterCard.defaultHeight),
                    onMarkWatched: { _ in },
                    onDeleteShow: {},
                    onTapCard: {}
                )
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Single Season") {
    struct PreviewWrapper: View {
        @State private var currentIndex = 0

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                BingeReadyCardStack(
                    seasons: [
                        Season(id: 1, seasonNumber: 4, name: "Season 4", overview: nil, posterPath: nil, airDate: Date().addingTimeInterval(-86400 * 60), episodeCount: 8, episodes: [], watchedDate: nil)
                    ],
                    show: Show(id: 2, name: "Yellowstone", overview: nil, posterPath: nil, backdropPath: nil, logoPath: nil, firstAirDate: nil, status: .returning, genres: [], networks: [], seasons: [], numberOfSeasons: 4, numberOfEpisodes: 40, inProduction: true),
                    currentIndex: $currentIndex,
                    cardSize: CGSize(width: BingeReadyPosterCard.defaultWidth, height: BingeReadyPosterCard.defaultHeight),
                    onMarkWatched: { _ in },
                    onDeleteShow: {},
                    onTapCard: {}
                )
            }
        }
    }
    return PreviewWrapper()
}
