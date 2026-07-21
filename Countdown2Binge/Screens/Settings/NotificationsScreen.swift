//
//  NotificationsScreen.swift
//  Countdown2Binge
//
//  Notification settings with premium features.
//

import SwiftUI

struct NotificationsScreen: View {
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss

    // Notification settings
    @AppStorage("notif_bingeReady") private var bingeReady = true
    @AppStorage("notif_premiere") private var premiere = true
    @AppStorage("notif_almostThere") private var almostThere = true
    @AppStorage("notif_leadDays") private var leadDays = 3
    @AppStorage("notif_perShow") private var perShow = true
    @AppStorage("notif_weeklyDrop") private var weeklyDrop = false
    @AppStorage("notif_digest") private var digest = "off"
    @AppStorage("notif_quietHours") private var quietHours = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with back button
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }

                    Text("NOTIFICATIONS")
                        .font(.custom(.oswald.bold, size: 22))
                        .tracking(0.44)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.bottom, 18)

                // Essentials Group (all users)
                SettingsGroup(label: "Essentials") {
                    SettingsRowToggle(
                        icon: "bell.fill",
                        iconColor: .c2bTealBright,
                        title: "Binge ready",
                        subtitle: "When a full season finishes releasing",
                        isOn: $bingeReady
                    )

                    SettingsRowToggle(
                        title: "Premiere day",
                        subtitle: "When a followed season premieres",
                        isLast: true,
                        isOn: $premiere
                    )
                }

                // Advanced Section Header
                HStack(spacing: 8) {
                    Text("ADVANCED")
                        .font(.custom(.jetbrains.regular, size: 9))
                        .tracking(1.44)
                        .foregroundColor(.c2bMuted)

                    SettingsPremiumBadge()
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

                // Advanced Group (premium-gated)
                ZStack {
                    VStack(spacing: 0) {
                        SettingsRowToggle(
                            title: "Almost there",
                            subtitle: "Heads-up when a season is 1 episode from done",
                            isOn: $almostThere,
                            disabled: !isPremium
                        )

                        SettingsRowCustom(
                            title: "Countdown lead time",
                            subtitle: "Remind me before binge-ready day"
                        ) {
                            NotificationLeadPicker(selectedDays: $leadDays, disabled: !isPremium)
                        }

                        SettingsRowToggle(
                            title: "Per-show timing",
                            subtitle: "Set alerts individually on each show",
                            isOn: $perShow,
                            disabled: !isPremium
                        )

                        SettingsRowToggle(
                            title: "Weekly episode drops",
                            subtitle: "Notify on every new episode (opt-in)",
                            isOn: $weeklyDrop,
                            disabled: !isPremium
                        )

                        SettingsRowCustom(
                            title: "Digest",
                            subtitle: "Roll upcoming shows into one summary"
                        ) {
                            NotificationDigestPicker(selectedOption: $digest, disabled: !isPremium)
                        }

                        SettingsRowToggle(
                            title: "Quiet hours",
                            subtitle: "Mute 11pm – 8am",
                            isLast: true,
                            isOn: $quietHours,
                            disabled: !isPremium
                        )
                    }
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .opacity(isPremium ? 1 : 0.5)
                    .saturation(isPremium ? 1 : 0.4)
                    .allowsHitTesting(isPremium)

                    // Premium overlay for free users
                    if !isPremium {
                        SettingsPremiumOverlay {
                            // TODO: Show premium paywall
                        }
                    }
                }
                .padding(.bottom, 22)

                // Footer text
                Text(isPremium
                    ? "You're on Premium — all advanced alerts available."
                    : "Free includes binge-ready & premiere alerts. Premium unlocks the rest."
                )
                .font(.system(size: 11.5))
                .foregroundColor(.c2bMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(1.5)
                .frame(maxWidth: .infinity)

                Spacer()
                    .frame(height: 150)
            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
        }
        .background(Color.c2bBackground)
        .navigationBarHidden(true)
    }
}
