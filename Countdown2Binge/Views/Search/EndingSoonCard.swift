//
//  EndingSoonCard.swift
//  Countdown2Binge
//

import SwiftUI

/// A large landscape card for shows ending soon with countdown display.
struct EndingSoonCard: View {
    let show: Show
    let daysLeft: Int
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
                    if let network = show.networks.first?.name {
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
                    ForEach(show.genres.prefix(2)) { genre in
                        Text(genre.name)
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


                // Bottom row: Add button + Days left
                HStack(alignment: .center, spacing: 0) {
                    addButton

                    // Vertical divider
                    Rectangle()
                        .fill(Color(red: 0x4E/255, green: 0x4E/255, blue: 0x4F/255))
                        .frame(width: 1, height: 24)
                        .padding(.horizontal, 12)

                    // Days countdown
                    VStack(alignment: .center, spacing: 0) {
                        Text(String(format: "%02d", daysLeft))
                            .font(.system(size: 46, weight: .heavy))
                            .foregroundStyle(.white)
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
    }
}

// MARK: - Preview

#Preview("Ending Soon Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        EndingSoonCard(
            show: Show(
                id: 1,
                name: "Dark Matter",
                overview: "A physicist travels through parallel worlds",
                posterPath: nil,
                backdropPath: nil,
                logoPath: nil,
                firstAirDate: nil,
                status: .returning,
                genres: [Genre(id: 10765, name: "Sci-Fi"), Genre(id: 53, name: "Thriller")],
                networks: [Network(id: 1, name: "Netflix", logoPath: nil)],
                seasons: [],
                numberOfSeasons: 1,
                numberOfEpisodes: 9,
                inProduction: true
            ),
            daysLeft: 3,
            isFollowed: false,
            isLoading: false,
            onTap: {},
            onAdd: {}
        )
        .padding(.horizontal, 20)
    }
}
