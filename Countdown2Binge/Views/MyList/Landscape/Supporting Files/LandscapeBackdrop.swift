//
//  LandscapeBackdrop.swift
//  Countdown2Binge
//
//  The face-card artwork layer. Uses the shared BackdropView when a URL is
//  present, otherwise a deterministic cinematic gradient seeded by the title so
//  design previews read distinctly without any network images.
//

import SwiftUI

struct LandscapeBackdrop: View {
    let url: URL?
    /// Seed for the placeholder gradient (usually the show title).
    let seed: String

    var body: some View {
        if url != nil {
            BackdropView(url: url)
        } else {
            LinearGradient(
                colors: Self.palette(for: seed),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                // subtle vignette so the placeholder never looks flat
                RadialGradient(
                    colors: [.clear, .black.opacity(0.45)],
                    center: .center, startRadius: 40, endRadius: 260
                )
            )
        }
    }

    /// Two dark, cinematic tones chosen deterministically from the seed.
    static func palette(for seed: String) -> [Color] {
        let hues: [Double] = [0.58, 0.03, 0.10, 0.75, 0.42, 0.92, 0.30, 0.66]
        let hash = abs(seed.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) })
        let h = hues[hash % hues.count]
        return [
            Color(hue: h, saturation: 0.35, brightness: 0.30),
            Color(hue: (h + 0.06).truncatingRemainder(dividingBy: 1), saturation: 0.45, brightness: 0.12),
        ]
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(["Severance", "Shōgun", "The Bear", "Reacher"], id: \.self) { title in
            LandscapeBackdrop(url: nil, seed: title)
                .aspectRatio(16/9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    .padding()
    .background(Color.c2bBackground)
}
