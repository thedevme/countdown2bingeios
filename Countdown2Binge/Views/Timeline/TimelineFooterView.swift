//
//  TimelineFooterView.swift
//  Countdown2Binge
//

import SwiftUI

/// Footer for the Timeline with "View Full Timeline" button and info text
struct TimelineFooterView: View {
    let onViewFullTimeline: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // View Full Timeline button
            Button(action: onViewFullTimeline) {
                HStack(spacing: 8) {
                    Text("VIEW FULL TIMELINE")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.5)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "0D0D0D"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(hex: "252525"), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)

            // Info text
            VStack(spacing: 6) {
                // Cycle icon
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(white: 0.35))

                Text("SHOWS CYCLE BACK")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color(white: 0.35))

                Text("WHEN SEASONS END")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color(white: 0.35))
            }
        }
        .padding(.vertical, 32)
        .padding(.bottom, 20)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            TimelineFooterView(onViewFullTimeline: {})
        }
    }
}
