//
//  BingeReadyCardView.swift
//  Countdown2Binge
//

import SwiftUI

/// A card-based view for a binge-ready season with swipe-to-complete gesture.
struct BingeReadyCardView: View {
    let item: BingeReadyItem
    let onMarkWatched: () -> Void
    let onTap: () -> Void

    @State private var offset: CGSize = .zero
    @State private var isDragging: Bool = false

    private let swipeThreshold: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main card content
            cardContent

            // Swipe indicator overlay
            if offset.width > 40 {
                swipeIndicator
            }
        }
        .offset(x: offset.width)
        .rotationEffect(.degrees(Double(offset.width) / 25))
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // Only activate for horizontal swipes (right direction)
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                    if isHorizontal && value.translation.width > 0 {
                        isDragging = true
                        offset = CGSize(width: value.translation.width, height: 0)
                    }
                }
                .onEnded { value in
                    isDragging = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        if value.translation.width > swipeThreshold {
                            // Complete the swipe
                            offset = CGSize(width: 500, height: 0)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onMarkWatched()
                            }
                        } else {
                            offset = .zero
                        }
                    }
                }
        )
        .onTapGesture {
            onTap()
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(spacing: 0) {
            // Backdrop/Poster header
            headerSection
                .frame(height: 180)

            // Info section
            infoSection
                .padding(20)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop image
            backdropImage

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .clear, Color(white: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Season badge
            HStack {
                Text("SEASON \(item.season.seasonNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )

                Spacer()

                // Binge ready badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 0.45, green: 0.90, blue: 0.70))
                        .frame(width: 8, height: 8)

                    Text("READY")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(1)
                        .foregroundStyle(Color(red: 0.45, green: 0.90, blue: 0.70))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.15))
                )
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var backdropImage: some View {
        let imagePath = item.show.backdropPath ?? item.show.posterPath ?? item.season.posterPath

        if let url = TMDBConfiguration.imageURL(path: imagePath, size: .backdrop) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    backdropPlaceholder
                }
            }
        } else {
            backdropPlaceholder
        }
    }

    private var backdropPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.2), Color(white: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "tv")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.1))
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Show name
            Text(item.show.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)

            // Stats row
            HStack(spacing: 20) {
                // Episode count
                HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))

                    Text("\(item.season.episodeCount) episodes")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                // Runtime estimate
                if let totalRuntime = estimatedTotalRuntime {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))

                        Text(totalRuntime)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }

            // Swipe hint
            HStack {
                Spacer()

                HStack(spacing: 6) {
                    Text("Swipe to complete")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.top, 4)
        }
    }

    private var estimatedTotalRuntime: String? {
        let runtimes = item.season.episodes.compactMap { $0.runtime }.filter { $0 > 0 }
        guard !runtimes.isEmpty else { return nil }

        let avgRuntime = runtimes.reduce(0, +) / runtimes.count
        let totalMinutes = avgRuntime * item.season.episodeCount
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    // MARK: - Swipe Indicator

    private var swipeIndicator: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color(red: 0.45, green: 0.90, blue: 0.70))
                .padding(16)
                .background(
                    Circle()
                        .fill(Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.2))
                )
        }
        .padding(20)
        .opacity(min(1, Double(offset.width - 40) / 80))
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            Color(white: 0.1)

            // Subtle gradient
            LinearGradient(
                colors: [.white.opacity(0.05), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Preview

#Preview("Binge Ready Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        BingeReadyCardView(
            item: BingeReadyItem(
                show: Show(
                    id: 1,
                    name: "Severance",
                    overview: "Mark leads a team...",
                    posterPath: nil,
                    backdropPath: nil,
                    logoPath: nil,
                    firstAirDate: Date(),
                    status: .returning,
                    genres: [],
                    networks: [],
                    seasons: [],
                    numberOfSeasons: 2,
                    numberOfEpisodes: 19,
                    inProduction: true
                ),
                season: Season(
                    id: 2,
                    seasonNumber: 2,
                    name: "Season 2",
                    overview: nil,
                    posterPath: nil,
                    airDate: Date().addingTimeInterval(-86400 * 30),
                    episodeCount: 10,
                    episodes: [],
                    watchedDate: nil
                )
            ),
            onMarkWatched: {},
            onTap: {}
        )
        .padding(.horizontal, 24)
    }
}
