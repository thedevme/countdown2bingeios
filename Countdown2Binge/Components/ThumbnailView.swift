//
//  ThumbnailView.swift
//  Countdown2Binge
//
//  Single reusable thumbnail component for episode stills and video thumbnails.
//  Uses NukeUI's LazyImage for proper lazy container support.
//

import SwiftUI
import NukeUI

/// A standardized thumbnail view for episode stills and video thumbnails.
/// Use this for all thumbnail images - sizing is the only variable.
struct ThumbnailView: View {
    let url: URL?
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 8

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
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 20) {
        // Episode thumbnail
        ThumbnailView(url: nil, width: 160, height: 90, cornerRadius: 8)

        // Video thumbnail
        ThumbnailView(url: nil, width: 200, height: 112, cornerRadius: 10)
    }
    .padding()
    .background(Color.c2bBackground)
}
