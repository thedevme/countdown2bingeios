//
//  ShowDetailTrailersSection.swift
//  Countdown2Binge
//
//  Horizontal scrollable trailers and previews section.
//

import SwiftUI
import YouTubePlayerKit

struct ShowDetailTrailersSection: View {
    let videos: [TMDBVideo]

    private let thumbnailWidth: CGFloat = 200
    private let thumbnailHeight: CGFloat = 112

    var body: some View {
        if !videos.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                // Section header
                HStack {
                    Text("header_trailers")
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .foregroundColor(.c2bMuted)
                        .tracking(1.4)

                    Spacer()

                    DirectionalIcon(systemName: "chevron.right")
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

    @State private var showPlayer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail with play button
            Button {
                showPlayer = true
            } label: {
                ZStack {
                    ThumbnailView(
                        url: video.thumbnailURL,
                        width: width,
                        height: height,
                        cornerRadius: 0
                    )

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
            .fullScreenCover(isPresented: $showPlayer) {
                YouTubePlayerFullscreen(videoKey: video.key)
            }

            // Title
            Text(video.name)
                .font(.custom(.jetbrains.regular, size: 10))
                .foregroundColor(.c2bDim)
                .lineLimit(1)
        }
        .frame(width: width)
    }
}

// MARK: - YouTube Player Fullscreen

struct YouTubePlayerFullscreen: View {
    let videoKey: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player: YouTubePlayer

    init(videoKey: String) {
        self.videoKey = videoKey
        _player = StateObject(wrappedValue: YouTubePlayer(
            source: .video(id: videoKey),
            configuration: .init(
                fullscreenMode: .system,
                allowsInlineMediaPlayback: true
            )
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                YouTubePlayerView(player)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()

                // Close button
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.top, 60)
                        .padding(.leading, 20)

                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            Task {
                try? await player.play()
            }
        }
    }
}
