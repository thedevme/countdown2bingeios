//
//  SeasonCardStack.swift
//  Countdown2Binge
//

import SwiftUI

/// A stacked card view for navigating seasons with swipe gestures.
/// - Swipe right → next season
/// - Swipe left → previous season
/// - Swipe down → mark all episodes complete
/// - Swipe up → delete/remove the show
struct SeasonCardStack: View {
    let seasons: [Season]
    let showName: String
    @Binding var selectedSeasonNumber: Int
    let onMarkAllComplete: (Int) -> Void
    let onDeleteShow: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var swipeDirection: SwipeDirection? = nil

    private let swipeThreshold: CGFloat = 80

    private enum SwipeDirection {
        case left, right, up, down
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("SEASONS")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.4))

            // Card stack
            ZStack {
                ForEach(Array(seasons.enumerated().reversed()), id: \.element.id) { index, season in
                    let isTop = season.seasonNumber == selectedSeasonNumber
                    let offset = cardOffset(for: season, at: index)

                    SeasonCard(
                        season: season,
                        showName: showName,
                        isTop: isTop
                    )
                    .offset(x: isTop ? dragOffset.width : 0, y: isTop ? offset + dragOffset.height : offset)
                    .scaleEffect(cardScale(for: season))
                    .rotationEffect(.degrees(isTop ? Double(dragOffset.width) / 20 : 0))
                    .opacity(cardOpacity(for: season))
                    .zIndex(isTop ? 100 : Double(season.seasonNumber))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedSeasonNumber)
                }
            }
            .frame(height: 180)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Only capture gesture if it's clearly directional (not just starting to scroll)
                        let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                        let isVerticalSwipe = abs(value.translation.height) > abs(value.translation.width) && abs(value.translation.height) > 30

                        if isHorizontal || isVerticalSwipe {
                            isDragging = true
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        handleSwipeEnd(translation: value.translation)
                    }
            )

            // Swipe hints
            if let currentSeason = seasons.first(where: { $0.seasonNumber == selectedSeasonNumber }) {
                swipeHints(for: currentSeason)
            }
        }
    }

    // MARK: - Card Positioning

    private func cardOffset(for season: Season, at index: Int) -> CGFloat {
        let selectedIndex = seasons.firstIndex(where: { $0.seasonNumber == selectedSeasonNumber }) ?? 0
        let currentIndex = seasons.firstIndex(where: { $0.id == season.id }) ?? index
        let diff = currentIndex - selectedIndex

        if diff == 0 {
            return 0
        } else if diff > 0 {
            return CGFloat(diff) * 8
        } else {
            return CGFloat(diff) * 8
        }
    }

    private func cardScale(for season: Season) -> CGFloat {
        let selectedIndex = seasons.firstIndex(where: { $0.seasonNumber == selectedSeasonNumber }) ?? 0
        let currentIndex = seasons.firstIndex(where: { $0.id == season.id }) ?? 0
        let diff = abs(currentIndex - selectedIndex)

        return max(0.9, 1.0 - CGFloat(diff) * 0.03)
    }

    private func cardOpacity(for season: Season) -> Double {
        let selectedIndex = seasons.firstIndex(where: { $0.seasonNumber == selectedSeasonNumber }) ?? 0
        let currentIndex = seasons.firstIndex(where: { $0.id == season.id }) ?? 0
        let diff = abs(currentIndex - selectedIndex)

        if diff == 0 { return 1.0 }
        if diff == 1 { return 0.6 }
        return 0.3
    }

    // MARK: - Swipe Handling

    private func handleSwipeEnd(translation: CGSize) {
        let horizontalSwipe = abs(translation.width) > abs(translation.height)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            if horizontalSwipe {
                if translation.width > swipeThreshold {
                    // Swipe right → next season
                    goToNextSeason()
                } else if translation.width < -swipeThreshold {
                    // Swipe left → previous season
                    goToPreviousSeason()
                }
            } else {
                if translation.height < -swipeThreshold {
                    // Swipe up → delete/remove show
                    onDeleteShow()
                } else if translation.height > swipeThreshold {
                    // Swipe down → mark all episodes complete
                    onMarkAllComplete(selectedSeasonNumber)
                }
            }
            dragOffset = .zero
        }
    }

    private func goToPreviousSeason() {
        let currentIndex = seasons.firstIndex(where: { $0.seasonNumber == selectedSeasonNumber }) ?? 0
        if currentIndex > 0 {
            selectedSeasonNumber = seasons[currentIndex - 1].seasonNumber
        }
    }

    private func goToNextSeason() {
        let currentIndex = seasons.firstIndex(where: { $0.seasonNumber == selectedSeasonNumber }) ?? 0
        if currentIndex < seasons.count - 1 {
            selectedSeasonNumber = seasons[currentIndex + 1].seasonNumber
        }
    }

    // MARK: - Swipe Hints

    @ViewBuilder
    private func swipeHints(for season: Season) -> some View {
        VStack(spacing: 12) {
            // Horizontal hints row
            HStack {
                // Left hint - previous season
                if let prevIndex = seasons.firstIndex(where: { $0.seasonNumber == selectedSeasonNumber }),
                   prevIndex > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption2)
                        Text("S\(seasons[prevIndex - 1].seasonNumber)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white.opacity(0.3))
                } else {
                    Spacer().frame(width: 40)
                }

                Spacer()

                // Season indicator dots
                HStack(spacing: 6) {
                    ForEach(seasons, id: \.id) { s in
                        Circle()
                            .fill(s.seasonNumber == selectedSeasonNumber ? .white : .white.opacity(0.2))
                            .frame(width: 6, height: 6)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedSeasonNumber = s.seasonNumber
                                }
                            }
                    }
                }

                Spacer()

                // Right hint - next season
                if let nextIndex = seasons.firstIndex(where: { $0.seasonNumber == selectedSeasonNumber }),
                   nextIndex < seasons.count - 1 {
                    HStack(spacing: 4) {
                        Text("S\(seasons[nextIndex + 1].seasonNumber)")
                            .font(.caption2)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white.opacity(0.3))
                } else {
                    Spacer().frame(width: 40)
                }
            }

            // Vertical hints row
            HStack(spacing: 24) {
                // Down hint - mark complete
                if season.isBingeReady {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                        Text("Complete")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.6))
                }

                // Up hint - remove
                HStack(spacing: 4) {
                    Image(systemName: "chevron.up")
                        .font(.caption2)
                    Text("Remove")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.red.opacity(0.4))
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Season Card

private struct SeasonCard: View {
    let season: Season
    let showName: String
    let isTop: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Season poster
            posterView
                .frame(width: 100, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Season info
            VStack(alignment: .leading, spacing: 10) {
                // Season title
                VStack(alignment: .leading, spacing: 4) {
                    Text("SEASON \(season.seasonNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.5))

                    Text(showName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                // State badge
                seasonStateBadge

                // Episode info
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EPISODES")
                            .font(.system(size: 9))
                            .fontWeight(.medium)
                            .tracking(0.8)
                            .foregroundStyle(.white.opacity(0.4))

                        Text("\(season.airedEpisodeCount)/\(season.episodeCount)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }

                    if let countdown = countdownText {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(countdown.label)
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                                .tracking(0.8)
                                .foregroundStyle(.white.opacity(0.4))

                            Text(countdown.value)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(countdown.color)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, 12)

            Spacer()
        }
        .padding(12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: isTop ? 12 : 4, y: isTop ? 6 : 2)
    }

    // MARK: - Poster View

    @ViewBuilder
    private var posterView: some View {
        if let posterPath = season.posterPath,
           let url = TMDBConfiguration.imageURL(path: posterPath, size: .poster) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    posterPlaceholder
                }
            }
        } else {
            posterPlaceholder
        }
    }

    private var posterPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.2), Color(white: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 4) {
                Text("S\(season.seasonNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }

    // MARK: - State Badge

    @ViewBuilder
    private var seasonStateBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)

            Text(stateText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(stateColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(stateColor.opacity(0.15))
        )
    }

    private var stateText: String {
        if season.isWatched { return "Watched" }
        if season.isBingeReady { return "Binge Ready" }
        if season.isAiring { return "Airing" }
        if season.hasStarted { return "In Progress" }
        return "Upcoming"
    }

    private var stateColor: Color {
        if season.isWatched { return .gray }
        if season.isBingeReady { return Color(red: 0.45, green: 0.90, blue: 0.70) }
        if season.isAiring { return Color(red: 0.85, green: 0.55, blue: 0.25) }
        return .white.opacity(0.6)
    }

    // MARK: - Countdown

    private var countdownText: (label: String, value: String, color: Color)? {
        if let days = season.daysUntilPremiere, days >= 0 {
            return ("PREMIERE", "\(days) days", .white)
        }
        if let days = season.daysUntilFinale, days >= 0 {
            return ("FINALE", "\(days) days", Color(red: 0.85, green: 0.55, blue: 0.25))
        }
        if season.isBingeReady {
            return ("STATUS", "Ready!", Color(red: 0.45, green: 0.90, blue: 0.70))
        }
        return nil
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            // Base layer
            Color(white: 0.12)

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    .white.opacity(0.06),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Border
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Preview

#Preview("Season Card Stack") {
    ZStack {
        Color.black.ignoresSafeArea()

        SeasonCardStack(
            seasons: [
                Season(
                    id: 1,
                    seasonNumber: 1,
                    name: "Season 1",
                    overview: nil,
                    posterPath: nil,
                    airDate: Date().addingTimeInterval(-86400 * 365),
                    episodeCount: 10,
                    episodes: [],
                    watchedDate: Date()
                ),
                Season(
                    id: 2,
                    seasonNumber: 2,
                    name: "Season 2",
                    overview: nil,
                    posterPath: nil,
                    airDate: Date().addingTimeInterval(-86400 * 30),
                    episodeCount: 10,
                    episodes: [],
                    watchedDate: nil
                ),
                Season(
                    id: 3,
                    seasonNumber: 3,
                    name: "Season 3",
                    overview: nil,
                    posterPath: nil,
                    airDate: Date().addingTimeInterval(86400 * 60),
                    episodeCount: 10,
                    episodes: [],
                    watchedDate: nil
                )
            ],
            showName: "Severance",
            selectedSeasonNumber: .constant(2),
            onMarkAllComplete: { _ in },
            onDeleteShow: {}
        )
        .padding(.horizontal, 24)
    }
}
