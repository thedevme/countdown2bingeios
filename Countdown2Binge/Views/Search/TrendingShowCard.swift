//
//  TrendingShowCard.swift
//  Countdown2Binge
//

import SwiftUI

/// A card displaying a trending show with poster, network badge, genres, and add button.
struct TrendingShowCard: View {
    let show: TMDBShowSummary
    let logoPath: String?
    let seasonNumber: Int?
    let isFollowed: Bool
    let isLoading: Bool
    let onTap: () -> Void
    let onAdd: () -> Void

    // App's teal accent color
    private let accentColor = Color(red: 0.22, green: 0.85, blue: 0.66)

    // Card dimensions
    private let posterHeight: CGFloat = 220
    private let bottomHeight: CGFloat = 100
    private let cornerRadius: CGFloat = 10
    private let bottomBackgroundColor = Color(red: 0x22/255, green: 0x22/255, blue: 0x24/255)

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Poster with network badge
                posterSection
                    .frame(maxWidth: .infinity)
                    .frame(height: posterHeight)

                // Info section
                infoSection
                    .frame(maxWidth: .infinity)
                    .background(bottomBackgroundColor)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(cardAccessibilityLabel)
        .accessibilityHint("Double tap to view details")
    }

    private var cardAccessibilityLabel: String {
        var parts = [show.name]
        if let network = extractNetwork(from: show) {
            parts.append("on \(network)")
        }
        let genres = extractGenres(from: show).prefix(2)
        if !genres.isEmpty {
            parts.append(genres.joined(separator: ", "))
        }
        if isFollowed {
            parts.append("Already added")
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Poster Section

    private var posterSection: some View {
        ZStack(alignment: .topTrailing) {
            // Poster image - fills the entire space
            posterImage
                .frame(maxWidth: .infinity)
                .frame(height: posterHeight)
                .clipped()

            // Network badge
            if let network = extractNetwork(from: show) {
                Text(network.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(red: 0x2D/255, green: 0x2D/255, blue: 0x2F/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color(red: 0x38/255, green: 0x38/255, blue: 0x39/255), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .padding(10)
            }

            // Gradient for logo legibility
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }

            // Logo overlay
            VStack {
                Spacer()
                if let logoPath = logoPath,
                   let logoURL = TMDBConfiguration.imageURL(path: logoPath, size: .logo) {
                    CachedAsyncImage(url: logoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        EmptyView()
                    }
                    .frame(maxHeight: 50, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var posterImage: some View {
        if let url = TMDBConfiguration.imageURL(path: show.posterPath, size: .poster) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                posterPlaceholder
            }
            .drawingGroup() // Rasterizes for smoother scrolling
        } else {
            posterPlaceholder
        }
    }

    private var posterPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.18), Color(white: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "tv")
                .font(.system(size: 32))
                .foregroundStyle(Color(white: 0.3))
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Genre tags
            genreTags
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Divider line
            Rectangle()
                .fill(Color(red: 0x38/255, green: 0x38/255, blue: 0x3A/255))
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .padding(.top, 6)

            // Bottom row: Add button + Season
            HStack(spacing: 0) {
                addButton

                // Vertical divider + Season indicator (only if season exists)
                if let season = seasonNumber {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(red: 0x4E/255, green: 0x4E/255, blue: 0x4F/255))
                            .frame(width: 1, height: 32)
                            .padding(.leading, 8)

                        Text("S\(season)")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.leading, 8)
                            .padding(.trailing, 4)
                    }
                    .fixedSize()
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 12)
    }

    private var genreTags: some View {
        HStack(spacing: 6) {
            ForEach(extractGenres(from: show).prefix(2), id: \.self) { genre in
                Text(genre)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(height: 20)
                    .padding(.horizontal, 10)
                    .background(Color(red: 0x2D/255, green: 0x2D/255, blue: 0x2F/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color(red: 0x38/255, green: 0x38/255, blue: 0x39/255), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }

    private let addButtonColor = Color(red: 0x20/255, green: 0xA3/255, blue: 0xA4/255)

    private var addButton: some View {
        Button(action: onAdd) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.7)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: isFollowed ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14, weight: .bold))
                        Text(isFollowed ? "FOLLOWING" : "FOLLOW")
                            .font(.system(size: 16, weight: .heavy).width(.condensed))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isFollowed ? Color.white.opacity(0.2) : addButtonColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(isFollowed ? "Following \(show.name)" : "Follow \(show.name)")
        .accessibilityHint(isFollowed ? "" : "Double tap to follow")
    }

    // MARK: - Helpers

    private func extractNetwork(from show: TMDBShowSummary) -> String? {
        // In a full implementation, you'd get this from show details
        // For now, return a placeholder based on show ID
        let networks = ["HBO", "NETFLIX", "APPLE TV+", "HULU", "PRIME", "MAX"]
        return networks[abs(show.id) % networks.count]
    }

    private func extractGenres(from show: TMDBShowSummary) -> [String] {
        guard let genreIds = show.genreIds else { return [] }

        let genreMap: [Int: String] = [
            10759: "Action",
            16: "Animation",
            35: "Comedy",
            80: "Crime",
            99: "Documentary",
            18: "Drama",
            10751: "Family",
            10762: "Kids",
            9648: "Mystery",
            10763: "News",
            10764: "Reality",
            10765: "Sci-Fi",
            10766: "Soap",
            10767: "Talk",
            10768: "Politics",
            37: "Western",
            27: "Horror"
        ]

        return genreIds.compactMap { genreMap[$0] }
    }
}

// MARK: - Preview

#Preview("Trending Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        HStack(spacing: 12) {
            TrendingShowCard(
                show: TMDBShowSummary(
                    id: 1,
                    name: "Dune: Prophecy",
                    overview: nil,
                    posterPath: nil,
                    backdropPath: nil,
                    firstAirDate: "2024-11-17",
                    voteAverage: 8.5,
                    genreIds: [10765, 18]
                ),
                logoPath: nil,
                seasonNumber: 1,
                isFollowed: false,
                isLoading: false,
                onTap: {},
                onAdd: {}
            )

            TrendingShowCard(
                show: TMDBShowSummary(
                    id: 2,
                    name: "The Night Agent",
                    overview: nil,
                    posterPath: nil,
                    backdropPath: nil,
                    firstAirDate: "2024-01-15",
                    voteAverage: 7.9,
                    genreIds: [10759, 53]
                ),
                logoPath: nil,
                seasonNumber: 2,
                isFollowed: true,
                isLoading: false,
                onTap: {},
                onAdd: {}
            )
        }
        .padding()
    }
}
