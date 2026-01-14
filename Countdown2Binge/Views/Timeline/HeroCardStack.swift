//
//  HeroCardStack.swift
//  Countdown2Binge
//

import SwiftUI

/// Swipeable card stack showing currently airing shows with soonest finales
struct HeroCardStack: View {
    let shows: [(show: Show, daysUntilFinale: Int)]
    @Binding var currentIndex: Int
    let onShowTap: (Show) -> Void

    @State private var dragOffset: CGFloat = 0

    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 365
    private let cardCornerRadius: CGFloat = 32
    private let cardSpacing: CGFloat = 35
    private let scaleStep: CGFloat = 0.1
    private let rotationDegrees: Double = 2

    var body: some View {
        ZStack {
            if shows.isEmpty {
                // Empty state
                emptyPlaceholder
            } else {
                // Card stack
                ForEach(Array(shows.enumerated()), id: \.element.show.id) { index, item in
                    cardView(for: item.show, at: index)
                        .zIndex(zIndex(for: index))
                }
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .gesture(
            shows.count > 1 ?
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 100
                    var newIndex = currentIndex

                    if value.translation.width < -threshold {
                        // Swipe left - go to next card (or loop to first)
                        newIndex = (currentIndex + 1) % shows.count
                    } else if value.translation.width > threshold {
                        // Swipe right - go to previous card (or loop to last)
                        newIndex = (currentIndex - 1 + shows.count) % shows.count
                    }

                    // Play sound if card changed
                    if newIndex != currentIndex {
                        SoundManager.shared.playCardSwipeWithHaptic()
                    }

                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 40)) {
                        currentIndex = newIndex
                        dragOffset = 0
                    }
                }
            : nil
        )
        .padding(.vertical, 20)
    }

    // MARK: - Card View

    @ViewBuilder
    private func cardView(for show: Show, at index: Int) -> some View {
        // Calculate position with wrap-around for looping
        let rawPosition = index - currentIndex
        let stackPosition: CGFloat = {
            if shows.count <= 1 { return CGFloat(rawPosition) }
            // Wrap position to be in range [-count/2, count/2] for proper looping
            let halfCount = shows.count / 2
            if rawPosition > halfCount {
                return CGFloat(rawPosition - shows.count)
            } else if rawPosition < -halfCount {
                return CGFloat(rawPosition + shows.count)
            }
            return CGFloat(rawPosition)
        }()
        // Only the front card reacts to drag for scale/rotation
        let isFrontCard = index == currentIndex
        let dragProgress = isFrontCard ? (dragOffset / 300) : 0
        let effectPosition = stackPosition + dragProgress

        Group {
            let url = TMDBConfiguration.imageURL(path: show.posterPath ?? show.backdropPath, size: .poster)
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
            } placeholder: {
                cardPlaceholder(for: show)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .scaleEffect(scale(for: effectPosition))
        .offset(x: offset(for: stackPosition, dragOffset: dragOffset, isFrontCard: isFrontCard))
        .rotation3DEffect(.degrees(rotation(for: effectPosition)), axis: (x: 0, y: 1, z: 0))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .onTapGesture {
            if index == currentIndex {
                onShowTap(show)
            }
        }
    }

    // MARK: - Transformations

    private func zIndex(for index: Int) -> Double {
        // Calculate wrapped position for proper z-ordering
        let rawPosition = index - currentIndex
        let position: Int = {
            if shows.count <= 1 { return rawPosition }
            let halfCount = shows.count / 2
            if rawPosition > halfCount {
                return rawPosition - shows.count
            } else if rawPosition < -halfCount {
                return rawPosition + shows.count
            }
            return rawPosition
        }()

        // Current card on top, others below based on distance
        if position == 0 {
            return Double(shows.count)
        } else {
            return Double(shows.count - abs(position))
        }
    }

    private func scale(for position: CGFloat) -> CGFloat {
        let absPosition = abs(position)
        return max(0.7, 1.0 - (scaleStep * absPosition))
    }

    private func offset(for stackPosition: CGFloat, dragOffset: CGFloat, isFrontCard: Bool) -> CGFloat {
        // Base offset from position in stack
        let baseOffset = stackPosition * cardSpacing

        // Only the front card moves with the drag
        // All other cards stay completely still
        if isFrontCard {
            return baseOffset + dragOffset
        } else {
            return baseOffset
        }
    }

    private func rotation(for position: CGFloat) -> Double {
        return -Double(position) * rotationDegrees
    }

    // MARK: - Placeholders

    private func cardPlaceholder(for show: Show) -> some View {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.2), Color(white: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: cardWidth, height: cardHeight)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(white: 0.4))
                    Text(show.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(white: 0.5))
                }
            )
    }

    private var emptyPlaceholder: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.15), Color(white: 0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: cardWidth, height: cardHeight)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "tv")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(white: 0.4))

                    Text("No Shows Airing")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(white: 0.4))
                }
            )
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
}

// MARK: - Previews

#Preview("With Shows") {
    struct PreviewWrapper: View {
        @State private var currentIndex = 0

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    HeroCardStack(
                        shows: [
                            (Show(
                                id: 1,
                                name: "Severance",
                                overview: "",
                                posterPath: nil,
                                backdropPath: nil,
                                firstAirDate: nil,
                                status: .returning,
                                genres: [],
                                networks: [],
                                seasons: [],
                                numberOfSeasons: 2,
                                numberOfEpisodes: 20,
                                inProduction: true
                            ), 17),
                            (Show(
                                id: 2,
                                name: "The Bear",
                                overview: "",
                                posterPath: nil,
                                backdropPath: nil,
                                firstAirDate: nil,
                                status: .returning,
                                genres: [],
                                networks: [],
                                seasons: [],
                                numberOfSeasons: 3,
                                numberOfEpisodes: 30,
                                inProduction: true
                            ), 24),
                            (Show(
                                id: 3,
                                name: "Andor",
                                overview: "",
                                posterPath: nil,
                                backdropPath: nil,
                                firstAirDate: nil,
                                status: .returning,
                                genres: [],
                                networks: [],
                                seasons: [],
                                numberOfSeasons: 2,
                                numberOfEpisodes: 12,
                                inProduction: true
                            ), 31)
                        ],
                        currentIndex: $currentIndex,
                        onShowTap: { _ in }
                    )
                    Spacer()
                }
                .padding(.top, 100)
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Empty") {
    struct PreviewWrapper: View {
        @State private var currentIndex = 0

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    HeroCardStack(
                        shows: [],
                        currentIndex: $currentIndex,
                        onShowTap: { _ in }
                    )
                    Spacer()
                }
                .padding(.top, 100)
            }
        }
    }
    return PreviewWrapper()
}
