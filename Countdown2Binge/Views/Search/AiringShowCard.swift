//
//  AiringShowCard.swift
//  Countdown2Binge
//

import SwiftUI

/// A large landscape card for currently airing shows from TMDB.
struct AiringShowCard: View {
    let show: TMDBShowSummary
    let daysLeft: Int?
    let isFollowed: Bool
    let isLoading: Bool
    let onTap: () -> Void
    let onAdd: () -> Void

    // App's teal accent color
    private let accentColor = Color(red: 0.22, green: 0.85, blue: 0.66)

    // Colors matching TrendingShowCard
    private let bottomBackgroundColor = Color(red: 0x22/255, green: 0x22/255, blue: 0x24/255)
    private let genreBackgroundColor = Color(red: 0x2D/255, green: 0x2D/255, blue: 0x2F/255)
    private let genreStrokeColor = Color(red: 0x38/255, green: 0x38/255, blue: 0x39/255)
    private let addButtonColor = Color(red: 0x20/255, green: 0xA3/255, blue: 0xA4/255)

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Main content area
                ZStack(alignment: .topTrailing) {
                    // Background image
                    backdropImage
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 10, style: .continuous))

                    // Network badge
                    if let network = extractNetwork(from: show) {
                        Text(network.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .padding(12)
                    }

                    // Gradient overlay
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 220)

                    // Show title
                    VStack(alignment: .leading) {
                        Spacer()
                        Text(show.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Genre tags
                HStack(spacing: 6) {
                    ForEach(extractGenres(from: show).prefix(2), id: \.self) { genre in
                        Text(genre)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(height: 20)
                            .padding(.horizontal, 10)
                            .background(genreBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(genreStrokeColor, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)

                // Bottom row: Add button + Airing indicator
                HStack(alignment: .center, spacing: 0) {
                    addButton

                    // Vertical divider
                    Rectangle()
                        .fill(Color(red: 0x4E/255, green: 0x4E/255, blue: 0x4F/255))
                        .frame(width: 1, height: 70)
                        .padding(.horizontal, 12)

                    // Days left indicator
                    VStack(alignment: .center, spacing: 0) {
                        if let days = daysLeft {
                            Text(String(format: "%02d", days))
                                .font(.system(size: 46, weight: .heavy))
                                .foregroundStyle(.white)
                        } else {
                            Text("--")
                                .font(.system(size: 46, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        Text("DAYS LEFT")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.trailing, 4)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(bottomBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        if let days = daysLeft {
            let daysText = days == 1 ? "1 day left" : "\(days) days left"
            parts.append(daysText)
        }
        if isFollowed {
            parts.append("Already added")
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Backdrop Image

    @ViewBuilder
    private var backdropImage: some View {
        if let url = TMDBConfiguration.imageURL(path: show.backdropPath ?? show.posterPath, size: .backdrop) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                backdropPlaceholder
            }
            .drawingGroup() // Rasterizes for smoother scrolling
        } else {
            backdropPlaceholder
        }
    }

    private var backdropPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.18), Color(white: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "tv")
                .font(.system(size: 40))
                .foregroundStyle(Color(white: 0.3))
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button(action: onAdd) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.7)
                } else {
                    Text(isFollowed ? "Added" : "+ Add to Binge List")
                        .font(.system(size: 12, weight: .medium))
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
        .disabled(isLoading || isFollowed)
        .accessibilityLabel(isFollowed ? "\(show.name) already added to binge list" : "Add \(show.name) to binge list")
        .accessibilityHint(isFollowed ? "" : "Double tap to add")
    }

    // MARK: - Helpers

    private func extractNetwork(from show: TMDBShowSummary) -> String? {
        // Use placeholder based on show ID (same as TrendingShowCard)
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

#Preview("Airing Show Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            AiringShowCard(
                show: TMDBShowSummary(
                    id: 1,
                    name: "Dark Matter",
                    overview: "A physicist travels through parallel worlds",
                    posterPath: nil,
                    backdropPath: nil,
                    firstAirDate: "2024-05-08",
                    voteAverage: 8.5,
                    genreIds: [10765, 18]
                ),
                daysLeft: 14,
                isFollowed: false,
                isLoading: false,
                onTap: {},
                onAdd: {}
            )

            AiringShowCard(
                show: TMDBShowSummary(
                    id: 2,
                    name: "The Bear",
                    overview: nil,
                    posterPath: nil,
                    backdropPath: nil,
                    firstAirDate: "2024-06-01",
                    voteAverage: 9.0,
                    genreIds: [35, 18]
                ),
                daysLeft: nil,
                isFollowed: false,
                isLoading: false,
                onTap: {},
                onAdd: {}
            )
        }
        .padding(.horizontal, 20)
    }
}
