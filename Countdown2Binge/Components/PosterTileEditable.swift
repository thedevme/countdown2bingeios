//
//  PosterTileEditable.swift
//  Countdown2Binge
//
//  Reusable poster tile with status badge, X button, and jiggle animation.
//  Used in CloudSync and anywhere edit mode is needed.
//

import SwiftUI

struct PosterTileEditable: View {
    let posterURL: URL?
    let title: String
    let badgeVariant: StatusBadgeVariant
    let isEditMode: Bool
    let isLocked: Bool
    let onRemove: () -> Void
    /// Whole-series watched/total episode counts — shown BELOW the poster
    /// as a progress bar plus a "XX% ⋯ watched/total" line, not an overlay
    /// on the art itself. Nil hides the whole block — most callers (e.g.
    /// plain "add show" grids) have no watch progress to show.
    var watchedEpisodes: Int? = nil
    var totalEpisodes: Int? = nil

    @State private var jiggling = false

    private var completionPercent: Int? {
        guard let watchedEpisodes, let totalEpisodes, totalEpisodes > 0 else { return nil }
        return Int((Double(watchedEpisodes) / Double(totalEpisodes) * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster with overlay
            ZStack(alignment: .topTrailing) {
                // Poster image
                posterImage
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                // Badge at bottom-left
                VStack {
                    Spacer()
                    HStack {
                        StatusBadge(variant: badgeVariant)
                            .padding(6)
                        Spacer()
                    }
                }

                // X button (edit mode only)
                if isEditMode {
                    CircleXButton(action: onRemove)
                        .offset(x: 6, y: -6)
                }
            }
            // Jiggle only the rotation via an explicit, self-contained animation
            // so the conditionally-inserted X button and badge don't get swept
            // into a repeatForever transaction (which made them blink).
            .rotationEffect(.degrees(isEditMode ? (jiggling ? 1.5 : -1.5) : 0))
            .onChange(of: isEditMode) { _, editing in
                if editing {
                    jiggling = false
                    withAnimation(.easeInOut(duration: 0.13).repeatForever(autoreverses: true)) {
                        jiggling = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.1)) { jiggling = false }
                }
            }
            .onAppear {
                if isEditMode {
                    withAnimation(.easeInOut(duration: 0.13).repeatForever(autoreverses: true)) {
                        jiggling = true
                    }
                }
            }

            // Title
            Text(title)
                .font(.custom(.jetbrains.regular, size: 11))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)

            // Progress bar + "percent ⋯ watched/total", grouped in their
            // own VStack so the 6pt bar→row gap is independent of the
            // outer stack's 8pt spacing (which places this block 8pt
            // below the title, per spec) — below the poster, never on
            // top of the art.
            if let completionPercent, let watchedEpisodes, let totalEpisodes {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.13))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.c2bTeal)
                                .frame(width: geo.size.width * CGFloat(completionPercent) / 100)
                        }
                    }
                    .frame(height: 4)

                    HStack {
                        Text("\(completionPercent)%")
                            .font(.custom(.oswald.bold, size: 13))
                            .foregroundColor(.c2bTeal)
                        Spacer()
                        Text("\(watchedEpisodes)/\(totalEpisodes)")
                            .font(.custom(.jetbrains.regular, size: 6.5))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var posterImage: some View {
        PosterView(url: posterURL, cornerRadius: 10)
            .grayscale(isLocked ? 1.0 : 0.0)
            .opacity(isLocked ? 0.5 : 1.0)
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()

        HStack(spacing: 12) {
            PosterTileEditable(
                posterURL: nil,
                title: "The Bear",
                badgeVariant: .synced,
                isEditMode: false,
                isLocked: false,
                onRemove: {}
            )
            .frame(width: 110)

            PosterTileEditable(
                posterURL: nil,
                title: "Severance",
                badgeVariant: .syncing,
                isEditMode: true,
                isLocked: false,
                onRemove: {}
            )
            .frame(width: 110)

            PosterTileEditable(
                posterURL: nil,
                title: "Wednesday",
                badgeVariant: .localOnly,
                isEditMode: false,
                isLocked: true,
                onRemove: {}
            )
            .frame(width: 110)
        }
        .padding()
    }
}
