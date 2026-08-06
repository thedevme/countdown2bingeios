//
//  GracePeriodBanner.swift
//  Countdown2Binge
//
//  Banner displayed during the 3-day grace period after downgrading from premium.
//

import SwiftUI

struct GracePeriodBanner: View {
    let daysRemaining: Int
    let totalShows: Int
    let onChooseNow: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Warning icon
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 22))
                    .foregroundColor(warningColor)

                VStack(alignment: .leading, spacing: 3) {
                    // Title with countdown
                    Text(titleText)
                        .font(.custom(.oswald.bold, size: 15))
                        .foregroundColor(.c2bText)

                    // Subtitle
                    Text(subtitleText)
                        .font(.system(size: 12))
                        .foregroundColor(.c2bDim)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Action buttons
            HStack(spacing: 10) {
                // Choose Shows Now button
                Button(action: onChooseNow) {
                    Text("grace_choose_now")
                        .font(.custom(.jetbrains.bold, size: 10))
                        .tracking(0.8)
                        .foregroundColor(.c2bText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }

                // Upgrade button
                Button(action: onUpgrade) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("grace_upgrade")
                            .font(.custom(.jetbrains.bold, size: 10))
                            .tracking(0.8)
                    }
                    .foregroundColor(Color(hex: "#04201c"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.c2bTeal)
                    .cornerRadius(10)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(bannerBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(warningColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, C2BLayout.horizontalPadding)
    }

    private var warningColor: Color {
        daysRemaining <= 1 ? Color(hex: "#ff6b6b") : Color(hex: "#fbbf24")
    }

    private var bannerBackground: some View {
        LinearGradient(
            colors: [warningColor.opacity(0.12), Color(hex: "#0e0e0f")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var titleText: String {
        if daysRemaining > 1 {
            return String(localized: "grace_title_days \(daysRemaining)")
        } else if daysRemaining == 1 {
            return String(localized: "grace_title_day_one")
        } else {
            return String(localized: "grace_title_expired")
        }
    }

    private var subtitleText: String {
        String(localized: "grace_subtitle \(totalShows)")
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            GracePeriodBanner(
                daysRemaining: 3,
                totalShows: 7,
                onChooseNow: {},
                onUpgrade: {}
            )

            GracePeriodBanner(
                daysRemaining: 1,
                totalShows: 5,
                onChooseNow: {},
                onUpgrade: {}
            )

            GracePeriodBanner(
                daysRemaining: 0,
                totalShows: 4,
                onChooseNow: {},
                onUpgrade: {}
            )
        }
    }
}
