//
//  SettingsScreen.swift
//  Countdown2Binge
//
//  Main settings screen.
//

import SwiftUI
import SwiftData
import RevenueCat

struct SettingsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showNotifications = false
    @State private var showPaywall = false
    @State private var selectedPlan = "yearly"
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var isRefreshingDiscover = false

    private var isPremium: Bool { PremiumManager.shared.isPremium }

    // Reset flags
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasSeenWalkthrough") private var hasSeenWalkthrough: Bool = false

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
                            showPaywall = true
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

                    // Developer / Reset Group
                    SettingsGroup(label: "Developer") {
                        #if DEBUG
                        SettingsRowToggle(
                            icon: "star.fill",
                            iconColor: .yellow,
                            title: "Debug Premium",
                            subtitle: PremiumManager.shared.debugPremiumOverride ? "Enabled" : "Disabled",
                            isOn: Binding(
                                get: { PremiumManager.shared.debugPremiumOverride },
                                set: { PremiumManager.shared.debugPremiumOverride = $0 }
                            )
                        )
                        #endif

                        SettingsRowAction(
                            icon: "arrow.counterclockwise",
                            iconColor: .c2bMuted,
                            title: "Reset onboarding",
                            subtitle: hasCompletedOnboarding ? "Completed" : "Not completed",
                            action: {
                                hasCompletedOnboarding = false
                            }
                        )

                        SettingsRowAction(
                            icon: "play.circle",
                            iconColor: .c2bMuted,
                            title: "Reset walkthrough",
                            subtitle: hasSeenWalkthrough ? "Seen" : "Not seen",
                            action: {
                                hasSeenWalkthrough = false
                            }
                        )

                        SettingsRowAction(
                            icon: "arrow.trianglehead.2.clockwise.rotate.90",
                            iconColor: .c2bTeal,
                            title: "Refresh Discover",
                            subtitle: isRefreshingDiscover ? "Refreshing..." : "Reload show data",
                            isLast: true,
                            action: {
                                Task { await refreshDiscoverCache() }
                            }
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

    @MainActor
    private func refreshDiscoverCache() async {
        isRefreshingDiscover = true
        let cacheService = DiscoverCacheService(modelContext: modelContext)
        await cacheService.refreshCache()
        isRefreshingDiscover = false
    }
}
