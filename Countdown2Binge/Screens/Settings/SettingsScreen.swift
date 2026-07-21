//
//  SettingsScreen.swift
//  Countdown2Binge
//
//  Main settings screen.
//

import SwiftUI

struct SettingsScreen: View {
    @State private var showNotifications = false
    @State private var isPremium = false // TODO: Connect to actual premium state

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    Text("SETTINGS")
                        .font(.custom(.oswald.bold, size: 27))
                        .tracking(0.54)
                        .foregroundColor(.white)
                        .padding(.bottom, 18)

                    // Account Card
                    SettingsAccountCard(
                        userName: "Alex",
                        isPremium: isPremium
                    )

                    // Alerts Group
                    SettingsGroup(label: "Alerts") {
                        SettingsRowChevron(
                            icon: "bell.fill",
                            iconColor: .c2bTealBright,
                            title: "Notifications",
                            subtitle: isPremium ? "Advanced alerts enabled" : "Binge-ready alerts only",
                            isLast: true,
                            action: { showNotifications = true }
                        )
                    }

                    // Premium CTA (free users only)
                    if !isPremium {
                        SettingsPremiumCTA {
                            // TODO: Show premium paywall
                        }
                    }

                    // Preferences Group
                    SettingsGroup(label: "Preferences") {
                        SettingsRowChevron(
                            icon: "tv",
                            title: "Streaming services",
                            subtitle: "Netflix, Max, Prime, Hulu, Apple TV+",
                            action: { }
                        )

                        SettingsRowChevron(
                            icon: "moon.fill",
                            title: "Appearance",
                            subtitle: "Dark",
                            isLast: true,
                            action: { }
                        )
                    }

                    // Account Group
                    SettingsGroup(label: "Account") {
                        SettingsRowChevron(
                            icon: "person.fill",
                            title: "Manage account",
                            action: { }
                        )

                        SettingsRowChevron(
                            icon: "questionmark.circle",
                            title: "Help & feedback",
                            isLast: true,
                            action: { }
                        )
                    }

                    // Sign Out Group
                    SettingsGroup {
                        SettingsRowDanger(
                            title: "Sign out",
                            isLast: true,
                            action: { }
                        )
                    }

                    // Version
                    Text("COUNTDOWN2BINGE · V1.0")
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(1.19)
                        .foregroundColor(.c2bMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    Spacer()
                        .frame(height: 150)
                }
                .padding(.horizontal, 20)
                .padding(.top, 52)
            }
            .background(Color.c2bBackground)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsScreen(isPremium: isPremium)
            }
        }
    }
}
