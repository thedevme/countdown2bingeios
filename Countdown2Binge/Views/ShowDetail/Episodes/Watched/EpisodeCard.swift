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
            // Background image — no flat darkener; watched goes black & white.
            thumbnailImage

            // Legibility gradient for the overlaid title: clear across the top,
            // ramping to dark over the bottom half where the title sits.
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .clear, location: 0.45),
                    .init(color: .black.opacity(0.8), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                // Top row: episode number (left) · watched checkmark (right).
                HStack(alignment: .top) {
                    Text("E\(episode.number)")
                        .font(.custom(.oswald.bold, size: 20))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
                        .padding(.leading, 12)
                        .padding(.top, 10)

                    Spacer()

                    checkboxView
                        .padding(.trailing, 9)
                        .padding(.top, 9)
                }

                Spacer(minLength: 0)

                // Bottom: episode title over the image.
                HStack {
                    Text(episode.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                    Spacer(minLength: 0)
                }
                .padding(.leading, 12)
                .padding(.trailing, 12)
                .padding(.bottom, 11)
            }
        }
        .frame(width: cardWidth, height: thumbnailHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var thumbnailImage: some View {
        ThumbnailView(
            url: showImageURL,
            width: cardWidth,
            height: thumbnailHeight,
            cornerRadius: 0
        )
        .saturation(imageSaturation)
        .brightness(imageBrightness)
    }

    // No flat darkener anymore. Watched → black & white; not-yet-aired stays
    // dimmed/muted to read as locked; aired-unwatched is full colour.
    private var imageSaturation: Double {
        if episode.isWatched { return 0.0 }
        if !episode.hasAired { return 0.4 }
        return 1.0
    }

    private var imageBrightness: Double {
        if !episode.hasAired { return -0.25 }
        return 0.0
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

    // MARK: - Metadata

    /// Text status shown above the description: watched, or locked/not-aired.
    /// Aired-but-unwatched shows no label.
    private var statusLabel: (text: LocalizedStringKey, color: Color)? {
        if episode.isWatched { return ("episode_watched", .c2bTealBright) }
        if !episode.hasAired { return ("episode_not_aired", .c2bMuted) }
        return nil
    }

    private var metadataArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status label (WATCHED / NOT YET AIRED) above the description.
            // The lock icon on the image still marks not-yet-aired; this makes
            // the state explicit in words.
            if let status = statusLabel {
                Text(status.text)
                    .font(.custom(CustomFont.jetbrains.bold, size: 8))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundColor(status.color)
                    .padding(.top, 11)
            }

            // Description (episode number + title now live on the image)
            Text(episode.description)
                .font(.system(size: 12.5))
                .foregroundColor(.c2bDim)
                .lineSpacing(2)
                .lineLimit(3)
                .truncationMode(.tail)
                .padding(.top, statusLabel == nil ? 11 : 6)

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
