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

// MARK: - Premium Upgrade Prompt

struct ShowDetailRelatedUpgradePrompt: View {
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 12) {
            // Section header (locked state)
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.c2bMuted)

                    Text("SPINOFFS & RELATED")
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .foregroundColor(.c2bMuted)
                        .tracking(1.4)
                }

                Spacer()

                Text("PREMIUM")
                    .font(.custom(.jetbrains.bold, size: 8))
                    .tracking(1.2)
                    .foregroundColor(.c2bTeal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.c2bTeal.opacity(0.15))
                    .cornerRadius(4)
            }

            // Blurred placeholder cards
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.c2bSurface)
                            .frame(width: 80, height: 120)
                            .cornerRadius(6)

                        Rectangle()
                            .fill(Color.c2bSurface.opacity(0.5))
                            .frame(width: 60, height: 8)
                            .cornerRadius(2)
                            .padding(.top, 8)
                    }
                }
                Spacer()
            }
            .blur(radius: 4)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(.c2bTeal)

                    Text("Discover spinoffs & prequels")
                        .font(.custom(.jetbrains.bold, size: 11))
                        .foregroundColor(.white)
                }
            )

            // Upgrade button
            Button(action: { showPaywall = true }) {
                Text("UNLOCK WITH PREMIUM")
                    .font(.custom(.oswald.bold, size: 14))
                    .tracking(0.4)
                    .foregroundColor(Color(hex: "#04201c"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.c2bTeal)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.top, 22)
    }
}
