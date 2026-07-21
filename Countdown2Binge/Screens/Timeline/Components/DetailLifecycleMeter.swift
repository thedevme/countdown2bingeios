//
//  DetailLifecycleMeter.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailLifecycleMeter: View {
    let category: TimelineCategory

    private let phases = ["Anticipated", "Premiering", "Airing", "Ready"]

    private var currentIndex: Int {
        switch category {
        case .anticipated: return 0
        case .premieringSoon: return 1
        case .airingNow: return 2
        case .bingeReady: return 3
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= currentIndex ? Color.c2bTeal : Color.white.opacity(0.12))
                        .frame(height: 4)

                    Text(phases[index].uppercased())
                        .font(.custom(.jetbrains.regular, size: 7))
                        .foregroundColor(index <= currentIndex ? .c2bTeal : .c2bMuted)
                        .tracking(0.8)
                }
            }
        }
    }
}
