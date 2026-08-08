//
//  PlanCard.swift
//  Countdown2Binge
//
//  Plan selection card for the paywall.
//

import SwiftUI

struct PlanCard: View {
    let id: String
    let name: String
    let price: String
    let period: String
    let subtitle: String
    let badge: String?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.c2bTeal : Color.white.opacity(0.25),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.c2bTeal)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.c2bBackground)
                    }
                }

                // Plan info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.custom(.oswald.bold, size: 16))
                            .foregroundColor(.white)

                        if let badge = badge {
                            Text(badge)
                                .font(.custom(.jetbrains.bold, size: 9))
                                .foregroundColor(.c2bBackground)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.c2bTeal)
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(.custom(.jetbrains.regular, size: 10))
                        .foregroundColor(.c2bMuted)
                        .tracking(0.3)
                }

                Spacer()

                // Price stacked vertically, right-aligned
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.custom(.oswald.bold, size: 24))
                        .foregroundColor(.white)

                    if !period.isEmpty && period != "once" {
                        Text(period.hasPrefix("/") ? String(period.dropFirst()) : period)
                            .font(.custom(.jetbrains.regular, size: 11))
                            .foregroundColor(.c2bMuted)
                            .tracking(0.5)
                    } else if period == "once" {
                        Text("one-time")
                            .font(.custom(.jetbrains.regular, size: 11))
                            .foregroundColor(.c2bMuted)
                            .tracking(0.5)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? Color.c2bTeal.opacity(0.08)
                    : Color.white.opacity(0.03)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.c2bTeal : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        PlanCard(
            id: "monthly",
            name: "MONTHLY",
            price: "$2.99",
            period: "/mo",
            subtitle: "CANCEL ANYTIME",
            badge: nil,
            isSelected: false,
            onSelect: {}
        )

        PlanCard(
            id: "yearly",
            name: "YEARLY",
            price: "$9.99",
            period: "/yr",
            subtitle: "7-DAY FREE TRIAL · $0.83/MO",
            badge: "SAVE 44%",
            isSelected: true,
            onSelect: {}
        )

        PlanCard(
            id: "lifetime",
            name: "LIFETIME",
            price: "$29.99",
            period: "once",
            subtitle: "PAY ONCE, KEEP FOREVER",
            badge: nil,
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
    .background(Color.c2bBackground)
}
