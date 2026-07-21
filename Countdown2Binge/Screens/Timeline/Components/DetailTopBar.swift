//
//  DetailTopBar.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailTopBar: View {
    let onDismiss: () -> Void
    var onShare: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Button {
                    dismiss()
                } label: {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }

                Spacer()

                DetailFollowingBadge()

                if let onShare = onShare {
                    Button(action: onShare) {
                        Circle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 52)

            Spacer()
        }
    }
}
