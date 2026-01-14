//
//  HeroShowCard.swift
//  Countdown2Binge
//

import SwiftUI

/// Large hero card for the currently airing show with soonest finale
struct HeroShowCard: View {
    let show: Show?
    let daysUntilFinale: Int?

    var body: some View {
        VStack(spacing: 0) {
            if let show = show {
                // Hero card with show poster and logo overlay
                ZStack(alignment: .bottom) {
                    // Poster image
                    Group {
                        let url = TMDBConfiguration.imageURL(path: show.posterPath ?? show.backdropPath, size: .poster)
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 280, height: 365)
                        } placeholder: {
                            ZStack {
                                artworkPlaceholder
                                if url != nil {
                                    ProgressView()
                                        .tint(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                    .frame(width: 280, height: 365)

                    // Logo overlay with gradient
                    if show.logoPath != nil {
                        VStack(spacing: 0) {
                            Spacer()

                            // Gradient for logo legibility
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 140)

                            // Logo image
                            logoImage(for: show)
                                .frame(height: 60)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)
                                .background(
                                    LinearGradient(
                                        colors: [.black.opacity(0.8), .black.opacity(0.9)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                }
                .frame(width: 280, height: 365)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            } else {
                // Empty hero placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.15), Color(white: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(spacing: 8) {
                        Image(systemName: "tv")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(white: 0.4))

                        Text("No Shows Airing")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(white: 0.4))
                    }
                }
                .frame(width: 280, height: 365)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            }
        }
        .padding(.vertical, 20)
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.2), Color(white: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 280, height: 365)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(white: 0.4))
            )
    }

    @ViewBuilder
    private func logoImage(for show: Show) -> some View {
        if let logoUrl = TMDBConfiguration.imageURL(path: show.logoPath, size: .logo) {
            CachedAsyncImage(url: logoUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.clear
            }
        }
    }
}

#Preview("With Show") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            HeroShowCard(
                show: Show(
                    id: 1,
                    name: "Severance",
                    overview: "",
                    posterPath: nil,
                    backdropPath: nil,
                    logoPath: nil,
                    firstAirDate: nil,
                    status: .returning,
                    genres: [],
                    networks: [],
                    seasons: [],
                    numberOfSeasons: 2,
                    numberOfEpisodes: 20,
                    inProduction: true
                ),
                daysUntilFinale: 17
            )
            Spacer()
        }
        .padding(.top, 100)
    }
}

#Preview("No Show") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            HeroShowCard(
                show: nil,
                daysUntilFinale: nil
            )
            Spacer()
        }
        .padding(.top, 100)
    }
}
