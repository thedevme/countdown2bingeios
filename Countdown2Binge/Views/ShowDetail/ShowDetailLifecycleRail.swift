//
//  ShowDetailLifecycleRail.swift
//  Countdown2Binge
//
//  4-node lifecycle progress rail: SOON → PREMIERE → AIRING → READY
//

import SwiftUI

struct ShowDetailLifecycleRail: View {
    /// 0 = Soon, 1 = Premiere, 2 = Airing, 3 = Ready
    let activeIndex: Int

    private let nodes = ["SOON", "PREMIERE", "AIRING", "READY"]
    private let dotSize: CGFloat = 12

    var body: some View {
        VStack(spacing: 8) {
            // Rail with dots
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let nodeSpacing = (totalWidth - dotSize) / CGFloat(nodes.count - 1)

                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 3)
                        .padding(.horizontal, dotSize / 2)

                    // Progress fill
                    let progressFraction = CGFloat(activeIndex) / CGFloat(nodes.count - 1)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.c2bTeal, .c2bTealBright],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, (totalWidth - dotSize) * progressFraction), height: 3)
                        .padding(.leading, dotSize / 2)
                        .shadow(color: .c2bTeal.opacity(0.5), radius: 10, x: 0, y: 0)

                    // Dots
                    ForEach(0..<nodes.count, id: \.self) { index in
                        let isActive = index <= activeIndex
                        let isCurrent = index == activeIndex

                        Circle()
                            .fill(isActive ? (isCurrent ? Color.c2bTealBright : .c2bTeal) : Color(hex: "#1a1a1c"))
                            .frame(width: dotSize, height: dotSize)
                            .overlay(
                                Circle()
                                    .stroke(isActive ? Color.clear : Color.white.opacity(0.18), lineWidth: 1.5)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.c2bTeal.opacity(isCurrent ? 0.18 : 0), lineWidth: 4)
                                    .scaleEffect(1.5)
                            )
                            .position(x: dotSize / 2 + nodeSpacing * CGFloat(index), y: geometry.size.height / 2)
                    }
                }
            }
            .frame(height: dotSize)

            // Labels
            HStack {
                ForEach(0..<nodes.count, id: \.self) { index in
                    Text(nodes[index])
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(0.9)
                        .foregroundColor(index == activeIndex ? .c2bTealBright : .c2bMuted)
                        .fontWeight(index == activeIndex ? .bold : .regular)

                    if index < nodes.count - 1 {
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 30) {
            ShowDetailLifecycleRail(activeIndex: 0)
            ShowDetailLifecycleRail(activeIndex: 1)
            ShowDetailLifecycleRail(activeIndex: 2)
            ShowDetailLifecycleRail(activeIndex: 3)
        }
        .padding(20)
    }
}
