//
//  NotificationsScreen.swift
//  Countdown2Binge
//
//  Notification settings with premium features.
//

import SwiftUI
import RevenueCat

struct NotificationsScreen: View {
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var selectedPlan = "yearly"
    @State private var isPurchasing = false
    @State private var purchaseError: String?

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

                // Premium required for all notifications
                if !isPremium {
                    // Show upgrade prompt for free users
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.c2bMuted)

                        Text("NOTIFICATIONS REQUIRE PREMIUM")
                            .font(.custom(.oswald.bold, size: 18))
                            .foregroundColor(.white)

                        Text("Upgrade to get notified when seasons are binge-ready, premiere days, and more.")
                            .font(.system(size: 14))
                            .foregroundColor(.c2bMuted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)

                        Button(action: { showPaywall = true }) {
                            Text("UPGRADE TO PREMIUM")
                                .font(.custom(.oswald.bold, size: 16))
                                .foregroundColor(Color(hex: "#04201c"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.c2bTeal)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                } else {
                    // Premium users see all notification settings
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
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 10)

                    // Advanced Group
                    VStack(spacing: 0) {
                        SettingsRowToggle(
                            title: "Almost there",
                            subtitle: "Heads-up when a season is 1 episode from done",
                            isOn: $almostThere
                        )

                        SettingsRowCustom(
                            title: "Countdown lead time",
                            subtitle: "Remind me before binge-ready day"
                        ) {
                            NotificationLeadPicker(selectedDays: $leadDays, disabled: false)
                        }

                        SettingsRowToggle(
                            title: "Per-show timing",
                            subtitle: "Set alerts individually on each show",
                            isOn: $perShow
                        )

                        SettingsRowToggle(
                            title: "Weekly episode drops",
                            subtitle: "Notify on every new episode (opt-in)",
                            isOn: $weeklyDrop
                        )

                        SettingsRowCustom(
                            title: "Digest",
                            subtitle: "Roll upcoming shows into one summary"
                        ) {
                            NotificationDigestPicker(selectedOption: $digest, disabled: false)
                        }

                        SettingsRowToggle(
                            title: "Quiet hours",
                            subtitle: "Mute 11pm – 8am",
                            isLast: true,
                            isOn: $quietHours
                        )
                    }
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.bottom, 22)

                    // Footer text
                    Text("You're on Premium — all alerts available.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.c2bMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(1.5)
                        .frame(maxWidth: .infinity)
                } // end else (premium users)

                Spacer()
                    .frame(height: 150)
            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
        }
        .background(Color.c2bBackground)
        .navigationBarHidden(true)
        .sheet(isPresented: $showPaywall) {
            DiscoverPaywallSheet(
                selectedPlan: $selectedPlan,
                isPurchasing: $isPurchasing,
                purchaseError: $purchaseError,
                onDismiss: { showPaywall = false }
            )
        }
    }
}
