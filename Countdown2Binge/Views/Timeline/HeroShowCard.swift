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
                // Hero card with show poster
                Group {
                    if let url = TMDBConfiguration.imageURL(path: show.posterPath ?? show.backdropPath, size: .poster) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 280, height: 365)
                                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            case .failure, .empty:
                                artworkPlaceholder
                            @unknown default:
                                artworkPlaceholder
                            }
                        }
                    } else {
                        artworkPlaceholder
                    }
                }
                .frame(width: 280, height: 365)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            } else {
                // Empty hero placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color(white: 0.95))

                    VStack(spacing: 8) {
                        Image(systemName: "tv")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(white: 0.7))

                        Text("No Shows Airing")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(white: 0.5))
                    }
                }
                .frame(width: 280, height: 365)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
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
