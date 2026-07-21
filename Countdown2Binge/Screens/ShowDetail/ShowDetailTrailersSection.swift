//
//  ShowDetailTrailersSection.swift
//  Countdown2Binge
//
//  Horizontal scrollable trailers and previews section.
//

import SwiftUI

struct ShowDetailTrailersSection: View {
    let videos: [TMDBVideo]

    private let thumbnailWidth: CGFloat = 200
    private let thumbnailHeight: CGFloat = 112

    var body: some View {
        if !videos.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                // Section header
                HStack {
                    Text("TRAILERS & PREVIEWS")
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .foregroundColor(.c2bMuted)
                        .tracking(1.4)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.c2bMuted)
                }

                // Horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(videos.prefix(6)) { video in
                            TrailerCard(
                                video: video,
                                width: thumbnailWidth,
                                height: thumbnailHeight
                            )
                        }
                    }
                }
                .padding(.horizontal, -22)
                .padding(.leading, 22)
            }
            .padding(.top, 22)
        }
    }
}

// MARK: - Trailer Card
private struct TrailerCard: View {
    let video: TMDBVideo
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail with play button
            Button {
                if let url = video.videoURL {
                    UIApplication.shared.open(url)
                }
            } label: {
                ZStack {
                    if let thumbnailURL = video.thumbnailURL {
                        AsyncImage(url: thumbnailURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: width, height: height)
                                    .clipped()
                            default:
                                Rectangle()
                                    .fill(Color.c2bSurface)
                                    .frame(width: width, height: height)
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.c2bSurface)
                            .frame(width: width, height: height)
                    }

                    // Play button overlay
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .offset(x: 2)
                        )

                    // Type badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(video.type.uppercased())
                                .font(.custom(.jetbrains.bold, size: 7))
                                .foregroundColor(.white)
                                .tracking(0.8)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                                .padding(8)
                        }
                    }
                }
                .frame(width: width, height: height)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Title
            Text(video.name)
                .font(.custom(.jetbrains.regular, size: 10))
                .foregroundColor(.c2bDim)
                .lineLimit(1)
        }
        .frame(width: width)
    }
}
