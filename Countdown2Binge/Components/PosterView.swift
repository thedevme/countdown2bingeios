//
//  PosterView.swift
//  Countdown2Binge
//
//  Single reusable poster component with consistent styling.
//  Uses NukeUI's LazyImage for proper lazy container support.
//

import SwiftUI
import NukeUI

/// A standardized poster view with consistent aspect ratio and placeholder.
/// Use this everywhere posters are displayed - sizing is the only variable.
struct PosterView: View {
    let url: URL?
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 12

    /// Standard poster aspect ratio (2:3)
    private let aspectRatio: CGFloat = 2.0 / 3.0

    var body: some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                PlaceholderView(cornerRadius: cornerRadius)
            }
        }
        .frame(width: width, height: height)
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Small poster
            PosterView(url: nil, width: 60, cornerRadius: 8)

            // Medium poster
            PosterView(url: nil, width: 100, cornerRadius: 10)

            // Large poster
            PosterView(url: nil, width: 150, cornerRadius: 14)

            // Extra large
            PosterView(url: nil, width: 200, cornerRadius: 16)
        }
        .padding()
    }
    .background(Color.c2bBackground)
}
