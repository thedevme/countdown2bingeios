//
//  TimelineStackedPosterView.swift
//  Countdown2Binge
//
//  Displays 1-3 fanned poster thumbnails for the timeline list view.
//  Same visual style as the hero card stack, but static (not swipable).
//
//  - 1 series: Single poster
//  - 2 series: Two posters fanned
//  - 3+ series: Three posters fanned (max visible)
//

import SwiftUI

struct TimelineStackedPosterView: View {
    let seriesList: [Series]
    var isGrayscale: Bool = false

    // Poster dimensions: 80px tall, 2:3 aspect ratio = 53.33×80.
    // Overlap and container scale off the height so the fan keeps its shape
    // and still fits — they were tuned against the old 38×57 poster.
    private let posterHeight: CGFloat = 80
    private var posterWidth: CGFloat { posterHeight * 2 / 3 }
    private var overlap: CGFloat { posterWidth * (18 / 38) }
    private let rotationStep: Double = 4  // (i - 1.5) × 4°
    /// Fixed width so every section's text column starts at the same x.
    private var containerWidth: CGFloat { posterWidth * (84 / 38) }

    /// Posters to display (max 3)
    private var postersToShow: [Series] {
        Array(seriesList.prefix(3))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(postersToShow.enumerated().reversed()), id: \.element.id) { index, series in
                posterImage(for: series)
                    .frame(width: posterWidth, height: posterHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "#0C0C0E"), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
                    .rotationEffect(.degrees(rotationForIndex(index)))
                    .offset(x: offsetForIndex(index))
            }
        }
        .frame(width: containerWidth, height: posterHeight, alignment: .leading)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func posterImage(for series: Series) -> some View {
        PosterView(url: series.posterURL, width: posterWidth, cornerRadius: 6)
            .grayscale(isGrayscale ? 1.0 : 0.0)
            .brightness(isGrayscale ? -0.4 : 0.0)
    }

    /// Rotation: (i - 1.5) × 4° for fan from -6° to +6°
    private func rotationForIndex(_ index: Int) -> Double {
        let count = postersToShow.count
        guard count > 1 else { return 0 }

        // Center the rotation around the middle
        let center = Double(count - 1) / 2.0
        return (Double(index) - center) * rotationStep
    }

    /// Offset for overlapping posters (-18px each)
    private func offsetForIndex(_ index: Int) -> CGFloat {
        // Each poster overlaps by 18px
        // First poster at 0, each subsequent shifts right but overlaps
        let baseOffset = CGFloat(index) * (posterWidth - overlap)
        // Center the stack
        let totalWidth = CGFloat(postersToShow.count - 1) * (posterWidth - overlap) + posterWidth
        let centerOffset = (containerWidth - totalWidth) / 2
        return baseOffset + centerOffset
    }
}

#Preview {
    VStack(spacing: 30) {
        Text("TimelineStackedPosterView")
            .foregroundColor(.white)
        Text("Requires Series model instances")
            .foregroundColor(.c2bMuted)
    }
    .padding()
    .background(Color.c2bBackground)
}
