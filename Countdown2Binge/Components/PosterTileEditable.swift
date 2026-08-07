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

    @State private var jiggleAmount: Double = 0

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
            .rotationEffect(.degrees(isEditMode ? jiggleAmount : 0))
            .animation(
                isEditMode
                    ? Animation.easeInOut(duration: 0.12).repeatForever(autoreverses: true)
                    : .default,
                value: isEditMode
            )
            .onChange(of: isEditMode) { _, editing in
                jiggleAmount = editing ? Double.random(in: -1.5...1.5) : 0
            }
            .onAppear {
                if isEditMode {
                    jiggleAmount = Double.random(in: -1.5...1.5)
                }
            }

            // Title
            Text(title)
                .font(.custom(.jetbrains.regular, size: 11))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
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
