//
//  ShowDetailPlayButton.swift
//  Countdown2Binge
//
//  Circular play button for trailers/previews.
//

import SwiftUI

struct ShowDetailPlayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 54, height: 54)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ShowDetailPlayButton(action: {})
    }
}
