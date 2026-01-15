//
//  BingeReadyPosterCard.swift
//  Countdown2Binge
//

import SwiftUI

/// A full-bleed poster card for binge-ready seasons.
/// Displays season number, episode count badge, and progress bar overlaid on the poster.
struct BingeReadyPosterCard: View {
    let season: Season
    let show: Show
    let isTopCard: Bool
    let cardSize: CGSize

    // Default card dimensions (used when no size provided)
    static let defaultWidth: CGFloat = 280
    static let defaultHeight: CGFloat = 420
    static let aspectRatio: CGFloat = 280 / 420 // ~0.667

    // Computed dimensions
    private var cardWidth: CGFloat { cardSize.width }
    private var cardHeight: CGFloat { cardSize.height }
    private var cornerRadius: CGFloat { cardSize.width * 0.086 } // ~24pt at 280 width
    private var scaleFactor: CGFloat { cardSize.width / Self.defaultWidth }

    // App's teal accent
    private let accentColor = Color(red: 0.45, green: 0.90, blue: 0.70)

    // Poster URL with fallback to show poster
    private var posterURL: URL? {
        let path = season.posterPath ?? show.posterPath
        return TMDBConfiguration.imageURL(path: path, size: .poster)
    }

    init(season: Season, show: Show, isTopCard: Bool, cardSize: CGSize? = nil) {
        self.season = season
        self.show = show
        self.isTopCard = isTopCard
        self.cardSize = cardSize ?? CGSize(width: Self.defaultWidth, height: Self.defaultHeight)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-bleed poster background
            posterImage

            // Content overlay
            contentOverlay
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(borderGlow)
        .shadow(color: .black.opacity(isTopCard ? 0.4 : 0.2), radius: isTopCard ? 20 : 8, y: isTopCard ? 10 : 4)
    }

    // MARK: - Poster Image

    private var posterImage: some View {
        CachedAsyncImage(url: posterURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cardWidth, height: cardHeight)
        } placeholder: {
            posterPlaceholder
        }
        .drawingGroup() // Rasterizes for better animation performance
    }

    private var posterPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.18), Color(white: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12 * scaleFactor) {
                Image(systemName: "tv")
                    .font(.system(size: 48 * scaleFactor))
                    .foregroundStyle(.white.opacity(0.2))

                Text(show.name)
                    .font(.system(size: 14 * scaleFactor, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20 * scaleFactor)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    // MARK: - Content Overlay

    private var contentOverlay: some View {
        ZStack {
            // Episode badge at top right
            VStack {
                HStack {
                    Spacer()
                    episodeBadge
                }
                .padding(.top, 16 * scaleFactor)
                .padding(.trailing, 16 * scaleFactor)
                Spacer()
            }

            // Season number at bottom left with gradient scrim
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.4),
                        .black.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140 * scaleFactor)
                .overlay(alignment: .bottomLeading) {
                    seasonNumber
                        .padding(.leading, 20 * scaleFactor)
                        .padding(.bottom, 16 * scaleFactor)
                }
            }
        }
    }

    // MARK: - Season Number

    private var seasonNumber: some View {
        Text("S\(season.seasonNumber)")
            .font(.system(size: 64 * scaleFactor, weight: .heavy, design: .default).width(.condensed))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
    }

    // MARK: - Episode Badge

    private var episodeBadge: some View {
        Text("\(season.episodeCount) EPISODES")
            .font(.system(size: 13 * scaleFactor, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(.black)
            .padding(.horizontal, 14 * scaleFactor)
            .padding(.vertical, 8 * scaleFactor)
            .background(
                Capsule()
                    .fill(accentColor)
            )
            .shadow(color: accentColor.opacity(0.4), radius: 6 * scaleFactor, y: 2)
    }

    // MARK: - Border Glow (Top Card Only)

    @ViewBuilder
    private var borderGlow: some View {
        if isTopCard {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.95).opacity(0.6),
                            Color(white: 0.85).opacity(0.3),
                            Color(white: 0.75).opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .shadow(color: Color(white: 0.9).opacity(0.15), radius: 8, x: 0, y: 0)
        }
    }
}

// MARK: - Preview

#Preview("Top Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        BingeReadyPosterCard(
            season: Season(
                id: 1,
                seasonNumber: 2,
                name: "Season 2",
                overview: nil,
                posterPath: nil,
                airDate: Date().addingTimeInterval(-86400 * 90),
                episodeCount: 24,
                episodes: [],
                watchedDate: nil
            ),
            show: Show(
                id: 1,
                name: "The Last of Us",
                overview: nil,
                posterPath: nil,
                backdropPath: nil,
                logoPath: nil,
                firstAirDate: nil,
                status: .returning,
                genres: [],
                networks: [],
                seasons: [],
                numberOfSeasons: 2,
                numberOfEpisodes: 24,
                inProduction: true
            ),
            isTopCard: true
        )
    }
}

#Preview("Background Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        BingeReadyPosterCard(
            season: Season(
                id: 2,
                seasonNumber: 1,
                name: "Season 1",
                overview: nil,
                posterPath: nil,
                airDate: Date().addingTimeInterval(-86400 * 365),
                episodeCount: 9,
                episodes: [],
                watchedDate: nil
            ),
            show: Show(
                id: 2,
                name: "Stranger Things",
                overview: nil,
                posterPath: nil,
                backdropPath: nil,
                logoPath: nil,
                firstAirDate: nil,
                status: .returning,
                genres: [],
                networks: [],
                seasons: [],
                numberOfSeasons: 4,
                numberOfEpisodes: 36,
                inProduction: false
            ),
            isTopCard: false
        )
    }
}
