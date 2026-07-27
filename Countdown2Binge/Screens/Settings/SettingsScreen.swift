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
    @State private var showProfile = false
    @State private var selectedPlan = "yearly"
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var isRefreshingDiscover = false
    @State private var isSyncing = false
    @State private var syncStatus: String = ""
    private var profile: UserProfile { ProfileManager.shared.profile }

    private var isPremium: Bool { PremiumManager.shared.isPremium }
    private var cloudSyncService: CloudSyncService { CloudSyncService.shared }

    // Reset flags
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasSeenWalkthrough") private var hasSeenWalkthrough: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    Text("header_settings")
                        .font(.custom(.oswald.bold, size: 27))
                        .tracking(0.54)
                        .foregroundColor(.white)
                        .padding(.bottom, 18)

                    // Account Card
                    SettingsAccountCard(
                        userName: profile.name,
                        isPremium: isPremium,
                        onTap: { showProfile = true }
                    )

                    // Alerts Group
                    SettingsGroup(label: String(localized: "settings_group_alerts")) {
                        SettingsRowChevron(
                            icon: "bell.fill",
                            iconColor: .c2bTealBright,
                            title: String(localized: "settings_notifications"),
                            subtitle: isPremium ? String(localized: "settings_alerts_advanced") : String(localized: "settings_alerts_basic"),
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
                    SettingsGroup(label: String(localized: "settings_group_preferences")) {
                        SettingsRowChevron(
                            icon: "tv",
                            title: String(localized: "settings_streaming_services"),
                            subtitle: "Netflix, Max, Prime, Hulu, Apple TV+",
                            action: { }
                        )

                        SettingsRowChevron(
                            icon: "moon.fill",
                            title: String(localized: "settings_appearance"),
                            subtitle: String(localized: "settings_dark"),
                            isLast: true,
                            action: { }
                        )
                    }

                    // Cloud Sync Group (Premium only)
                    if isPremium {
                        SettingsGroup(label: String(localized: "settings_cloud_sync")) {
                            SettingsRowAction(
                                icon: "icloud.fill",
                                iconColor: .c2bTeal,
                                title: String(localized: "settings_sync_now"),
                                subtitle: cloudSyncSubtitle,
                                isLast: true,
                                action: {
                                    Task { await performSync() }
                                }
                            )
                        }
                    }

                    // Account Group
                    SettingsGroup(label: String(localized: "settings_group_account")) {
                        SettingsRowChevron(
                            icon: "person.fill",
                            title: String(localized: "settings_manage_account"),
                            action: { }
                        )

                        SettingsRowChevron(
                            icon: "questionmark.circle",
                            title: String(localized: "settings_help_feedback"),
                            isLast: true,
                            action: { }
                        )
                    }

                    // Developer / Reset Group
                    SettingsGroup(label: String(localized: "settings_group_developer")) {
                        #if DEBUG
                        SettingsRowToggle(
                            icon: "star.fill",
                            iconColor: .yellow,
                            title: String(localized: "settings_debug_premium"),
                            subtitle: PremiumManager.shared.debugPremiumOverride ? String(localized: "settings_enabled") : String(localized: "settings_disabled"),
                            isOn: Binding(
                                get: { PremiumManager.shared.debugPremiumOverride },
                                set: { PremiumManager.shared.debugPremiumOverride = $0 }
                            )
                        )
                        #endif

                        SettingsRowAction(
                            icon: "arrow.counterclockwise",
                            iconColor: .c2bMuted,
                            title: String(localized: "settings_reset_onboarding"),
                            subtitle: hasCompletedOnboarding ? String(localized: "settings_completed") : String(localized: "settings_not_completed"),
                            action: {
                                hasCompletedOnboarding = false
                            }
                        )

                        SettingsRowAction(
                            icon: "play.circle",
                            iconColor: .c2bMuted,
                            title: String(localized: "settings_reset_walkthrough"),
                            subtitle: hasSeenWalkthrough ? String(localized: "settings_seen") : String(localized: "settings_not_seen"),
                            action: {
                                hasSeenWalkthrough = false
                            }
                        )

                        SettingsRowAction(
                            icon: "arrow.trianglehead.2.clockwise.rotate.90",
                            iconColor: .c2bTeal,
                            title: String(localized: "settings_refresh_discover"),
                            subtitle: isRefreshingDiscover ? String(localized: "settings_refreshing") : String(localized: "settings_reload_data"),
                            isLast: true,
                            action: {
                                Task { await refreshDiscoverCache() }
                            }
                        )
                    }

                    // About Group
                    SettingsGroup(label: String(localized: "settings_group_about")) {
                        Link(destination: URL(string: "https://www.themoviedb.org")!) {
                            SettingsLinkRowContent(
                                icon: "powerplug.fill",
                                title: String(localized: "settings_api_provided_by")
                            )
                        }

                        Link(destination: URL(string: "https://countdown2binge.app/privacy")!) {
                            SettingsLinkRowContent(
                                icon: "doc.plaintext.fill",
                                title: String(localized: "settings_privacy_policy")
                            )
                        }

                        Link(destination: URL(string: "https://countdown2binge.app/terms")!) {
                            SettingsLinkRowContent(
                                icon: "doc.text.magnifyingglass",
                                title: String(localized: "settings_terms_of_use"),
                                isLast: true
                            )
                        }
                    }

                    // Sign Out Group
                    SettingsGroup {
                        SettingsRowDanger(
                            title: String(localized: "button_sign_out"),
                            isLast: true,
                            action: { }
                        )
                    }

                    // Version
                    Text(String(localized: "app_version \("V1.0")"))
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
            .navigationDestination(isPresented: $showProfile) {
                ProfileScreen(isPremium: isPremium)
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

    // MARK: - Cloud Sync

    private var cloudSyncSubtitle: String {
        if isSyncing {
            return String(localized: "sync_in_progress")
        }

        if !syncStatus.isEmpty {
            return syncStatus
        }

        if let lastSynced = cloudSyncService.lastSyncedAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return String(localized: "sync_last_synced \(formatter.localizedString(for: lastSynced, relativeTo: Date()))")
        }

        return String(localized: "settings_cloud_sync_on")
    }

    @MainActor
    private func performSync() async {
        guard !isSyncing else { return }

        isSyncing = true
        syncStatus = ""

        let result = await cloudSyncService.fullSync(modelContext: modelContext)

        isSyncing = false
        syncStatus = result.message

        // Clear status after a few seconds
        try? await Task.sleep(for: .seconds(3))
        syncStatus = ""
    }
}
