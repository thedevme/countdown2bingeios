//
//  CircleXButton.swift
//  Countdown2Binge
//
//  Reusable X button for edit/delete modes (iOS home screen style).
//

import SwiftUI

struct CircleXButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#27272a"))
                    .frame(width: 22, height: 22)

                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: 22, height: 22)

                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()

        CircleXButton {
        }
    }
}
