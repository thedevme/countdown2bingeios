//
//  ShowCard.swift
//  Countdown2Binge
//

import SwiftUI

/// A card displaying a show's backdrop image with title overlay.
/// Designed for timeline and list displays with a premium, editorial feel.
struct ShowCard: View {
    let title: String
    let backdropPath: String?
    let subtitle: String?

    init(title: String, backdropPath: String?, subtitle: String? = nil) {
        self.title = title
        self.backdropPath = backdropPath
        self.subtitle = subtitle
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Backdrop image
                backdropImage
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Gradient overlay for text legibility
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.3),
                        .black.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Title overlay
                VStack(alignment: .leading, spacing: 4) {
                    if let subtitle {
                        Text(subtitle.uppercased())
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .padding(.top, 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }

    @ViewBuilder
    private var backdropImage: some View {
        if let url = TMDBConfiguration.imageURL(path: backdropPath, size: .backdrop) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderView
                        .overlay {
                            ProgressView()
                                .tint(.white.opacity(0.5))
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color(white: 0.12)

            // Subtle texture pattern
            Image(systemName: "tv")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.08))
        }
    }
}

// MARK: - Convenience Initializers

extension ShowCard {
    /// Initialize with a Show model
    init(show: Show) {
        self.title = show.name
        self.backdropPath = show.backdropPath
        self.subtitle = nil
    }

    /// Initialize with a Show model and custom subtitle
    init(show: Show, subtitle: String?) {
        self.title = show.name
        self.backdropPath = show.backdropPath
        self.subtitle = subtitle
    }
}

// MARK: - Preview

#Preview("With Backdrop") {
    ShowCard(
        title: "Severance",
        backdropPath: "/sample.jpg",
        subtitle: "Season 2"
    )
    .frame(width: 340, height: 200)
    .padding()
    .background(Color.black)
}

#Preview("Without Backdrop") {
    ShowCard(
        title: "The Last of Us",
        backdropPath: nil,
        subtitle: "Premiering Soon"
    )
    .frame(width: 340, height: 200)
    .padding()
    .background(Color.black)
}
