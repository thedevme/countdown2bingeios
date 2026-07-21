//
//  ShowDetailMetadataRow.swift
//  Countdown2Binge
//
//  Apple TV-style metadata badges row with year, runtime, rating, quality badges, and accessibility icons.
//

import SwiftUI

struct ShowDetailMetadataRow: View {
    let year: String
    let runtime: String
    let rating: String
    let contentBadges: [String] // e.g., ["TV-MA", "4K", "HD"]
    let hasDolbyVision: Bool
    let hasDolbyAtmos: Bool
    let accessibilityBadges: [String] // e.g., ["CC", "SDH", "AD"]

    init(
        year: String = "2026",
        runtime: String = "~55 min",
        rating: String = "14+",
        contentBadges: [String] = ["TV-MA", "4K"],
        hasDolbyVision: Bool = true,
        hasDolbyAtmos: Bool = true,
        accessibilityBadges: [String] = ["CC", "SDH", "AD"]
    ) {
        self.year = year
        self.runtime = runtime
        self.rating = rating
        self.contentBadges = contentBadges
        self.hasDolbyVision = hasDolbyVision
        self.hasDolbyAtmos = hasDolbyAtmos
        self.accessibilityBadges = accessibilityBadges
    }

    var body: some View {
        FlowLayout(spacing: 8, lineSpacing: 10) {
            // Year
            metadataText(year)

            dotSeparator

            // Runtime
            metadataText(runtime)

            // Rating with checkmark
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: "#4ade80"))

                metadataText(rating)
            }

            // Content badges (TV-MA, 4K, etc.)
            ForEach(contentBadges, id: \.self) { badge in
                borderedBadge(badge)
            }

            // Dolby Vision
            if hasDolbyVision {
                dolbyBadge("Dolby Vision")
            }

            // Dolby Atmos
            if hasDolbyAtmos {
                dolbyBadge("Dolby Atmos")
            }

            // Accessibility badges (CC, SDH, AD)
            ForEach(accessibilityBadges, id: \.self) { badge in
                borderedBadge(badge, lighter: true)
            }
        }
    }

    private func metadataText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13.5, weight: .semibold))
            .foregroundColor(.white)
    }

    private var dotSeparator: some View {
        Circle()
            .fill(Color.c2bMuted)
            .frame(width: 3, height: 3)
    }

    private func borderedBadge(_ text: String, lighter: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.c2bDim)
            .padding(.horizontal, lighter ? 6 : 7)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(lighter ? 0.22 : 0.28), lineWidth: 1)
            )
    }

    private func dolbyBadge(_ label: String) -> some View {
        HStack(spacing: 3) {
            Text("◗◖")
                .font(.system(size: 13, weight: .heavy))
                .tracking(-0.5)
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.c2bDim)
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + lineSpacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    ZStack {
        Color.black
        ShowDetailMetadataRow()
            .padding()
    }
}
