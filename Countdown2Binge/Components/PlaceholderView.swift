//
//  PlaceholderView.swift
//  Countdown2Binge
//
//  Standard placeholder view for image loading states.
//  Adapts to any size and corner radius.
//

import SwiftUI

/// A consistent placeholder view for image loading states.
/// Uses the app's standard styling: dark background with teal accent stroke.
struct PlaceholderView: View {
    var cornerRadius: CGFloat = 12

    var body: some View {
        Rectangle()
            .fill(Color.c2bImagePlaceholder)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.c2bTeal, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 20) {
        // Small poster
        PlaceholderView(cornerRadius: 8)
            .frame(width: 60, height: 90)

        // Standard poster
        PlaceholderView(cornerRadius: 12)
            .frame(width: 120, height: 180)

        // Large poster with different radius
        PlaceholderView(cornerRadius: 16)
            .frame(width: 200, height: 300)
    }
    .padding()
    .background(Color.c2bBackground)
}
