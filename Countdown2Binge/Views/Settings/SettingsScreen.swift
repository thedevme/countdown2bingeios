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
    @State private var selectedPlan = "monthly"
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var isRefreshingDiscover = false
    @State private var isSyncing = false
    @State private var syncStatus: String = ""
    @State private var showTastePrefs = false
    @State private var showImport = false
    private var profile: UserProfile { ProfileManager.shared.profile }

    private var tastePrefsSubtitle: String {
        let p = TastePreferencesStore.shared.preferences
        guard p.completedPreferenceStep else { return String(localized: "settings_taste_not_set") }
        let g = p.genreIDs.count, s = p.providerIDs.count
        return String(format: NSLocalizedString("settings_taste_summary %lld %lld", comment: ""), g, s)
    }

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

                    // Premium CTA (free users only)
                    if !isPremium {
                        SettingsPremiumCTA {
                            showPaywall = true
                        }
                    }

                    // Free users see nothing they can't use: no profile,
                    // no alerts, no library, no preferences, no sync. Just the
                    // upgrade CTA and About. Bouncing every row to a paywall was
                    // noisier than simply not showing them.
                    if isPremium {
                        // Account Card
                        SettingsAccountCard(
                            userName: profile.name,
                            isPremium: isPremium,
                            isInTrial: PremiumManager.shared.isInTrial,
                            onTap: {
                                showProfile = true
                            }
                        )

                        // Alerts Group
                        SettingsGroup(label: String(localized: "settings_group_alerts")) {
                            SettingsRowChevron(
                                icon: "bell.fill",
                                iconColor: .c2bTealBright,
                                title: String(localized: "settings_notifications"),
                                subtitle: String(localized: "settings_alerts_advanced"),
                                isLast: true,
                                // Premium-gated: free users get no notifications at
                                // all (see scheduleNotificationsForShow), so letting
                                // them configure alerts promises something we never
                                // deliver.
                                action: {
                                    showNotifications = true
                                }
                            )
                        }


                        // Library Group — bulk import is a premium feature; the
                        // free tier caps at 3 shows, so there's nothing to import.
                        SettingsGroup(label: String(localized: "settings_group_library")) {
                            SettingsRowChevron(
                                icon: "square.and.arrow.down",
                                title: String(localized: "settings_import_title"),
                                subtitle: String(localized: "settings_import_subtitle"),
                                isLast: true,
                                action: {
                                    showImport = true
                                }
                            )
                        }

                        // Preferences Group
                        SettingsGroup(label: String(localized: "settings_group_preferences")) {
                            // Premium-gated: what a free user gets recommended isn't
                            // theirs to tune. Free taps land on the paywall.
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
                                action: { }
                            )

                            SettingsRowChevron(
                                icon: "slider.horizontal.3",
                                title: String(localized: "settings_taste_title"),
                                subtitle: tastePrefsSubtitle,
                                isLast: true,
                                action: {
                                    showTastePrefs = true
                                }
                            )
                        }
                    }

                    // Reset Group — visible to free and premium alike, so
                    // anyone can go back through either onboarding flow.
                    // Neither flag is behind isPremium above.
                    SettingsGroup(label: String(localized: "settings_group_reset")) {
                        SettingsRowAction(
                            icon: "arrow.counterclockwise",
                            title: String(localized: "settings_reset_app_onboarding"),
                            subtitle: String(localized: "settings_reset_app_onboarding_subtitle"),
                            action: {
                                // Reactive: ContentView watches this flag and
                                // re-presents OnboardingFlow immediately.
                                cloudSettings.resetOnboarding()
                            }
                        )

                        SettingsRowAction(
                            icon: "arrow.counterclockwise",
                            title: String(localized: "settings_reset_mylist_onboarding"),
                            subtitle: String(localized: "settings_reset_mylist_onboarding_subtitle"),
                            isLast: true,
                            action: {
                                // MyListLandscapeView reads this flag directly
                                // in its overlay, so it reappears next time
                                // that tab is shown.
                                cloudSettings.hasSeenMyListOnboarding = false
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

                    // Developer tools — Debug builds only, compiled out of Release.
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
            .navigationDestination(isPresented: $showImport) {
                ImportShowsView(onDismiss: { showImport = false })
            }
            .navigationDestination(isPresented: $showTastePrefs) {
                TastePreferencesEditorView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    selectedPlan: $selectedPlan,
                    onDismiss: { showPaywall = false },
                    onContinueFree: nil
                )
            }
            // Paywall preview — commented out; uncomment with its @State above.
            // #if DEBUG
            // .sheet(isPresented: $showPaywallPreview) {
            //     PaywallView(
            //         selectedPlan: $selectedPlan,
            //         onDismiss: { showPaywallPreview = false },
            //         onContinueFree: nil
            //     )
            // }
            // #endif
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
