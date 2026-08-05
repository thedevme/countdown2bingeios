//
//  SettingsScreen.swift
//  Countdown2Binge
//
//  Main settings screen.
//

import SwiftUI
import SwiftData
import RevenueCat

/// Sync eligibility state for iCloud sync
enum SyncEligibility {
    case eligible
    case notEligible(SyncIneligibilityReason)
}

/// Reasons why sync may be unavailable
enum SyncIneligibilityReason {
    case noICloudAccount
    case iCloudRestricted
    case temporarilyUnavailable
    case notPremium
    case unknown
}

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
    @State private var iCloudAvailable: Bool = true
    @State private var syncEligibility: SyncEligibility = .eligible
    private var profile: UserProfile { ProfileManager.shared.profile }

    private var isPremium: Bool { PremiumManager.shared.isPremium }

    // Cloud-synced onboarding flags
    private var cloudSettings: CloudSettingsStore { CloudSettingsStore.shared }

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
                                icon: iCloudAvailable ? "icloud.fill" : "icloud.slash.fill",
                                iconColor: iCloudAvailable ? .c2bTeal : .c2bMuted,
                                title: iCloudAvailable ? String(localized: "settings_sync_now") : String(localized: "settings_icloud_unavailable"),
                                subtitle: cloudSyncSubtitle,
                                isLast: true,
                                action: {
                                    if iCloudAvailable {
                                        Task { await performSync() }
                                    }
                                }
                            )
                        }
                        .task {
                            await checkiCloudStatus()
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

                        // Pending Section Toggle - Only works in Simulator
                        SettingsRowToggle(
                            icon: "clock.badge.questionmark",
                            iconColor: .c2bYellow,
                            title: "Show Mock Pending",
                            subtitle: DebugSettings.shared.isRunningInSimulator
                                ? (DebugSettings.shared.showMockPendingSection ? "Showing mock data" : "Hidden")
                                : "Simulator only",
                            isOn: Binding(
                                get: { DebugSettings.shared.showMockPendingSection },
                                set: { DebugSettings.shared.showMockPendingSection = $0 }
                            ),
                            disabled: !DebugSettings.shared.isRunningInSimulator
                        )
                        #endif

                        SettingsRowAction(
                            icon: "arrow.counterclockwise",
                            iconColor: .c2bMuted,
                            title: String(localized: "settings_reset_onboarding"),
                            subtitle: cloudSettings.hasCompletedOnboarding ? String(localized: "settings_completed") : String(localized: "settings_not_completed"),
                            action: {
                                cloudSettings.hasCompletedOnboarding = false
                            }
                        )

                        SettingsRowAction(
                            icon: "play.circle",
                            iconColor: .c2bMuted,
                            title: String(localized: "settings_reset_walkthrough"),
                            subtitle: cloudSettings.hasSeenWalkthrough ? String(localized: "settings_seen") : String(localized: "settings_not_seen"),
                            action: {
                                cloudSettings.hasSeenWalkthrough = false
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
            .overlay {
                if showNotifications {
                    NotificationSettingsOverlay(onDismiss: {
                        showNotifications = false
                    })
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showNotifications)
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
        // Show iCloud unavailable reason first
        if !iCloudAvailable {
            switch syncEligibility {
            case .eligible:
                return String(localized: "settings_icloud_checking")
            case .notEligible(let reason):
                switch reason {
                case .noICloudAccount:
                    return String(localized: "settings_sign_in_icloud")
                case .iCloudRestricted:
                    return String(localized: "settings_icloud_restricted")
                case .temporarilyUnavailable:
                    return String(localized: "settings_icloud_temp_unavailable")
                case .notPremium:
                    return String(localized: "settings_premium_required")
                case .unknown:
                    return String(localized: "settings_icloud_error")
                }
            }
        }

        if isSyncing {
            return String(localized: "sync_in_progress")
        }

        if !syncStatus.isEmpty {
            return syncStatus
        }

        // CloudKit sync is automatic via SwiftData
        return String(localized: "settings_cloud_sync_on")
    }

    @MainActor
    private func checkiCloudStatus() async {
        // CloudKit sync is automatic via SwiftData
        // Check if iCloud is available via FileManager
        iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        syncEligibility = iCloudAvailable ? .eligible : .notEligible(.noICloudAccount)
    }

    @MainActor
    private func performSync() async {
        guard !isSyncing else { return }

        isSyncing = true
        syncStatus = ""

        // CloudKit sync is automatic via SwiftData - nothing to do manually
        syncStatus = String(localized: "sync_success")

        isSyncing = false

        // Clear status after a few seconds
        try? await Task.sleep(for: .seconds(3))
        syncStatus = ""
    }
}
