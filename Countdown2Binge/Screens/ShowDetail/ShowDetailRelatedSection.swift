//
//  ShowDetailRelatedSection.swift
//  Countdown2Binge
//
//  Horizontal scrollable related shows section.
//

import SwiftUI

struct ShowDetailRelatedSection: View {
    let recommendations: [TMDBShowSummary]
    let onTap: (TMDBShowSummary) -> Void

    private let posterWidth: CGFloat = 100
    private let posterHeight: CGFloat = 150

    var body: some View {
        if !recommendations.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                // Section header
                HStack {
                    Text("RELATED")
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
                        ForEach(recommendations.prefix(10)) { show in
                            RelatedShowCard(
                                show: show,
                                posterWidth: posterWidth,
                                posterHeight: posterHeight,
                                onTap: { onTap(show) }
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

// MARK: - Related Show Card
private struct RelatedShowCard: View {
    let show: TMDBShowSummary
    let posterWidth: CGFloat
    let posterHeight: CGFloat
    let onTap: () -> Void

    private var posterURL: URL? {
        guard let path = show.posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(path)")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Poster
                if let url = posterURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: posterWidth, height: posterHeight)
                                .clipped()
                        default:
                            Rectangle()
                                .fill(Color.c2bSurface)
                                .frame(width: posterWidth, height: posterHeight)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.c2bSurface)
                        .frame(width: posterWidth, height: posterHeight)
                }

                // Title
                Text(show.name)
                    .font(.custom(.jetbrains.bold, size: 10))
                    .foregroundColor(.c2bText)
                    .lineLimit(1)
            }
            .frame(width: posterWidth)
        }
        .buttonStyle(.plain)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
