//
//  EpisodeCard.swift
//  Countdown2Binge
//
//  Horizontal episode card for the watched carousel.
//  Shows thumbnail, watch state, and episode metadata.
//

import SwiftUI

struct EpisodeCard: View {
    let episode: EpisodeDisplayModel
    let showImageURL: URL?
    let onToggleWatched: () -> Void

    private let cardWidth: CGFloat = 268
    private let thumbnailHeight: CGFloat = 151

    var body: some View {
        Button(action: onToggleWatched) {
            VStack(alignment: .leading, spacing: 0) {
                thumbnailArea
                metadataArea
            }
            .frame(width: cardWidth)
        }
        .buttonStyle(.plain)
        .disabled(!episode.hasAired)
    }

    // MARK: - Thumbnail

    private var thumbnailArea: some View {
        ZStack {
            // Background image
            thumbnailImage

            // Bottom gradient
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: thumbnailHeight * 0.45)
            }

            // Checkbox (top-right)
            VStack {
                HStack {
                    Spacer()
                    checkboxView
                        .padding(9)
                }
                Spacer()
            }

            // Status labels
            statusLabels
        }
        .frame(width: cardWidth, height: thumbnailHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var thumbnailImage: some View {
        Group {
            if let url = showImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderImage
                    case .empty:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: cardWidth, height: thumbnailHeight)
        .brightness(imageBrightness)
        .saturation(imageSaturation)
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.c2bSurface2)
    }

    private var imageBrightness: Double {
        if !episode.hasAired { return -0.35 }
        if episode.isWatched { return -0.3 }
        return -0.05
    }

    private var imageSaturation: Double {
        if !episode.hasAired { return 0.4 }
        if episode.isWatched { return 0.75 }
        return 1.0
    }

    // MARK: - Checkbox

    private var checkboxView: some View {
        ZStack {
            Circle()
                .fill(episode.isWatched ? Color.c2bTeal : Color.black.opacity(0.55))
                .frame(width: 28, height: 28)
                .blur(radius: episode.isWatched ? 0 : 4)
                .overlay(
                    Circle()
                        .stroke(
                            episode.isWatched ? Color.c2bTeal : Color.white.opacity(0.5),
                            lineWidth: 1.5
                        )
                )

            if !episode.hasAired {
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            } else if episode.isWatched {
                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#04201c"))
            }
        }
    }

    // MARK: - Status Labels

    private var statusLabels: some View {
        ZStack {
            // "WATCHED" label (top-left when watched)
            if episode.isWatched {
                VStack {
                    HStack {
                        Text("episode_watched")
                            .font(.custom(CustomFont.jetbrains.bold, size: 8))
                            .tracking(1.6)
                            .foregroundColor(.c2bTealBright)
                            .padding(.leading, 12)
                            .padding(.top, 13)
                        Spacer()
                    }
                    Spacer()
                }
            }

            // "NOT YET AIRED" label (bottom-left when locked)
            if !episode.hasAired {
                VStack {
                    Spacer()
                    HStack {
                        Text("episode_not_aired")
                            .font(.custom(CustomFont.jetbrains.bold, size: 8))
                            .tracking(1.4)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.leading, 12)
                            .padding(.bottom, 11)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Metadata

    private var metadataArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Episode number
            Text(String(localized: "episode_number \(episode.number)"))
                .font(.custom(CustomFont.jetbrains.bold, size: 9))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)
                .padding(.top, 11)

            // Title
            Text(episode.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.c2bText)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, 4)

            // Description
            Text(episode.description)
                .font(.system(size: 12.5))
                .foregroundColor(.c2bDim)
                .lineSpacing(2)
                .lineLimit(3)
                .truncationMode(.tail)
                .padding(.top, 6)

            // Runtime
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(.c2bDim)

                Text(episode.formattedRuntime)
                    .font(.custom(CustomFont.jetbrains.regular, size: 10))
                    .tracking(0.4)
                    .foregroundColor(.c2bDim)
            }
            .padding(.top, 9)
        }
        .padding(.horizontal, 2)
        .opacity(!episode.hasAired ? 0.55 : 1)
    }
}

// MARK: - Preview

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 14) {
            EpisodeCard(
                episode: EpisodeDisplayModel(
                    id: "1",
                    number: 1,
                    seasonNumber: 2,
                    title: "The Crash",
                    description: "Mark returns to Lumon after the events of the finale, but things are different now.",
                    runtime: 45,
                    airDate: Date().addingTimeInterval(-86400 * 7),
                    isWatched: true,
                    hasAired: true,
                    isFinale: false
                ),
                showImageURL: nil,
                onToggleWatched: {}
            )

            EpisodeCard(
                episode: EpisodeDisplayModel(
                    id: "2",
                    number: 2,
                    seasonNumber: 2,
                    title: "Goodbye, Mrs. Selvig",
                    description: "Helly confronts her outie's past while Mark investigates a lead.",
                    runtime: 52,
                    airDate: Date(),
                    isWatched: false,
                    hasAired: true,
                    isFinale: false
                ),
                showImageURL: nil,
                onToggleWatched: {}
            )

            EpisodeCard(
                episode: EpisodeDisplayModel(
                    id: "3",
                    number: 3,
                    seasonNumber: 2,
                    title: "Episode 3",
                    description: "Details not yet available.",
                    runtime: 45,
                    airDate: Date().addingTimeInterval(86400 * 7),
                    isWatched: false,
                    hasAired: false,
                    isFinale: false
                ),
                showImageURL: nil,
                onToggleWatched: {}
            )
        }
        .padding(.horizontal, 22)
    }
    .background(Color.c2bBackground)
}
