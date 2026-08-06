//
//  StatusBadge.swift
//  Countdown2Binge
//
//  Reusable status badge for showing sync state, completion state, etc.
//

import SwiftUI

enum StatusBadgeVariant {
    case synced
    case syncing
    case localOnly

    var icon: String {
        switch self {
        case .synced: return "checkmark"
        case .syncing: return "arrow.trianglehead.2.clockwise"
        case .localOnly: return "lock.fill"
        }
    }

    var text: String {
        switch self {
        case .synced: return "SYNCED"
        case .syncing: return "SYNCING..."
        case .localOnly: return "LOCAL ONLY"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .synced, .syncing: return .c2bTeal
        case .localOnly: return .white.opacity(0.5)
        }
    }
}

struct StatusBadge: View {
    let variant: StatusBadgeVariant

    @State private var isRotating = false

    var body: some View {
        HStack(spacing: 4) {
            Group {
                if variant == .syncing {
                    Image(systemName: variant.icon)
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .animation(
                            .linear(duration: 1.0).repeatForever(autoreverses: false),
                            value: isRotating
                        )
                        .onAppear { isRotating = true }
                } else {
                    Image(systemName: variant.icon)
                }
            }
            .font(.system(size: 7, weight: .bold))
            .foregroundColor(variant.foregroundColor)

            Text(variant.text)
                .font(.custom(.jetbrains.bold, size: 7))
                .tracking(0.5)
                .foregroundColor(variant.foregroundColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.6))
        .cornerRadius(4)
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            StatusBadge(variant: .synced)
            StatusBadge(variant: .syncing)
            StatusBadge(variant: .localOnly)
        }
    }
}
