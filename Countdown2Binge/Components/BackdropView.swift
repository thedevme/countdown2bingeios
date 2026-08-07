//
//  BackdropView.swift
//  Countdown2Binge
//
//  Single reusable backdrop component for hero images.
//  Uses NukeUI's LazyImage for proper lazy container support.
//

import SwiftUI
import NukeUI

/// A standardized backdrop view for hero sections.
/// Use this for all backdrop/hero images - sizing is the only variable.
struct BackdropView: View {
    let url: URL?
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 0

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
        // Hero backdrop
        BackdropView(url: nil, height: 200)

        // Rounded backdrop
        BackdropView(url: nil, height: 150, cornerRadius: 16)
    }
    .padding()
    .background(Color.c2bBackground)
}
