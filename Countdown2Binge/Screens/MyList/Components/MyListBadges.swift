//
//  MyListBadges.swift
//  Countdown2Binge
//
//  Badge components for My List poster tiles.
//

import SwiftUI

// MARK: - Ready Badge

/// Teal "READY" badge with checkmark for just-completed shows
struct MyListReadyBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Color(hex: "#04201c"))

            Text("READY")
                .font(.custom(.jetbrains.bold, size: 7.5))
                .tracking(0.75)
                .foregroundColor(Color(hex: "#04201c"))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.c2bTeal)
        .cornerRadius(999)
        .shadow(color: .c2bTeal.opacity(0.45), radius: 10, y: 3)
    }
}

// MARK: - TBD Badge

/// Gray "TBD" badge for shows without a release date
struct MyListTBDBadge: View {
    var body: some View {
        Text("TBD")
            .font(.custom(.jetbrains.bold, size: 8))
            .tracking(0.8)
            .foregroundColor(.white.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.15))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
    }
}

// MARK: - Season Badge

/// Season number badge (e.g., "S2") for poster corners
struct MyListSeasonBadge: View {
    let seasonNumber: Int
    var isDimmed: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Text("S")
                .font(.custom(.oswald.bold, size: 13))
                .foregroundColor(isDimmed ? .white.opacity(0.7) : .white)
            Text("\(seasonNumber)")
                .font(.custom(.oswald.light, size: 13))
                .foregroundColor(isDimmed ? .white.opacity(0.7) : .white)
        }
    }
}

// MARK: - Complete Stamp

/// Angled "COMPLETE" stamp for ended shows
struct MyListCompleteStamp: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.c2bTealBright)

            Text("COMPLETE")
                .font(.custom(.oswald.bold, size: 12))
                .tracking(0.96)
                .foregroundColor(.c2bTealBright)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(hex: "#04201c").opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.c2bTealBright, lineWidth: 2.5)
        )
        .cornerRadius(8)
        .shadow(color: .c2bTeal.opacity(0.3), radius: 16, y: 4)
        .rotationEffect(.degrees(-13))
    }
}

// MARK: - Archive Icon

/// Small archive box icon for archived shows
struct MyListArchiveIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(hex: "#080808").opacity(0.72))
                .frame(width: 22, height: 22)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )

            Image(systemName: "archivebox")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Stripe Pattern

/// Diagonal stripe overlay for archived shows
struct MyListStripePattern: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let stripeWidth: CGFloat = 2
                let gap: CGFloat = 9
                let total = stripeWidth + gap
                var x: CGFloat = -geo.size.height

                while x < geo.size.width + geo.size.height {
                    path.move(to: CGPoint(x: x, y: geo.size.height))
                    path.addLine(to: CGPoint(x: x + geo.size.height, y: 0))
                    path.addLine(to: CGPoint(x: x + geo.size.height + stripeWidth, y: 0))
                    path.addLine(to: CGPoint(x: x + stripeWidth, y: geo.size.height))
                    path.closeSubpath()
                    x += total
                }
            }
            .fill(Color.white.opacity(0.03))
        }
    }
}
