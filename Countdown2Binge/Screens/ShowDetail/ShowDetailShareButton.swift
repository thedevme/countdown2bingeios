//
//  ShowDetailShareButton.swift
//  Countdown2Binge
//

import SwiftUI

struct ShowDetailShareButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 38, height: 38)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ShowDetailShareButton(action: {})
    }
}
