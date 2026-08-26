//
//  ContentView.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 7/9/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SeriesManager.self) private var seriesManager

    // Cloud-synced onboarding flags (persists across devices via iCloud).
    // Held as @State so its @Observable changes drive the UI — e.g. resetting
    // onboarding in Settings (or completing it on another device) reflects live.
    @State private var cloudSettings = CloudSettingsStore.shared

    @State private var activeTab: String = "timeline"
    @State private var showOnboarding: Bool = false
    @State private var showWalkthrough: Bool = false
    @State private var showFreeLimitModal: Bool = false
    @State private var showDowngradeModal: Bool = false
    @State private var selectedPlan: String = "monthly"
    @State private var followedShows: [ShowSummary] = []
    @State private var timelineRefreshTrigger: UUID = UUID()
    @State private var showPremiumPaywall: Bool = false
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?

    // Badge manager for tab notifications (shared instance)
    private var badgeManager: TabBadgeManager { TabBadgeManager.shared }

    // For FreeLimitModal compatibility (uses String names)
    @State private var followedShowNames: [String] = []

    var body: some View {
        ZStack {
            TabView(selection: $activeTab) {
                Tab("tab_timeline", image: "tab-timeline", value: "timeline") {
                    TimelineScreen(
                        layout: "expanded",
                        numberStyle: "rotated",
                        refreshTrigger: timelineRefreshTrigger,
                        onInfoTap: {
                            showWalkthrough = true
                        }
                    )
                }
                .badge(badgeManager.timelineBadge ? 1 : 0)

                Tab("tab_my_list", image: "tab-mylist", value: "mylist") {
                    MyListLandscapeView()
                }
                .badge(badgeManager.bingeReadyBadge ? 1 : 0)

                Tab("tab_settings", image: "tab-settings", value: "settings") {
                    SettingsScreen()
                }

                Tab(value: "search", role: .search) {
                    SearchScreen(badgeManager: badgeManager)
                }
            }
            .tint(.white)
            .onChange(of: activeTab) { _, newTab in
                // Clear badge when user visits the tab
                badgeManager.clearBadge(for: newTab)
            }
            .onAppear {
                configureTabBarAppearance()
                // Show onboarding if not completed
                if !cloudSettings.hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            // Show titles are TMDB content — re-localize stored titles if the app
            // language changed since they were saved (like search fetches live).
            .task {
                await seriesManager.relocalizeNamesIfLanguageChanged()
            }
            // React to the iCloud flag changing — reset from Settings re-presents
            // onboarding immediately; completion on another device dismisses it.
            .onChange(of: cloudSettings.hasCompletedOnboarding) { _, completed in
                withAnimation { showOnboarding = !completed }
            }

            // Onboarding overlay
            if showOnboarding {
                OnboardingFlow(
                    isPresented: $showOnboarding,
                    onComplete: { plan, shows in
                        print("ContentView: Received \(shows.count) shows to save")
                        selectedPlan = plan
                        followedShows = shows
                        followedShowNames = shows.map { $0.name }

                        // Mark onboarding as completed
                        cloudSettings.hasCompletedOnboarding = true

                        // Save to SwiftData, then show walkthrough
                        Task {
                            await saveFollowedShows(shows)

                            // Wait for UI to update
                            try? await Task.sleep(for: .seconds(1))

                            await MainActor.run {
                                // Show Free Limit Modal if free plan and >3 shows
                                if plan == "free" && shows.count > 3 {
                                    showFreeLimitModal = true
                                } else if !cloudSettings.hasSeenWalkthrough {
                                    showWalkthrough = true
                                    cloudSettings.hasSeenWalkthrough = true
                                }
                            }
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(100)
            }

            // Free Limit Modal overlay
            if showFreeLimitModal {
                FreeLimitModal(
                    isPresented: $showFreeLimitModal,
                    followedShows: $followedShowNames,
                    onUpgrade: {
                        selectedPlan = "premium"
                    }
                )
                .zIndex(95)
                .onChange(of: showFreeLimitModal) { oldValue, newValue in
                    if !newValue && !cloudSettings.hasSeenWalkthrough {
                        // Show walkthrough after modal dismisses (only if not seen)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showWalkthrough = true
                            cloudSettings.hasSeenWalkthrough = true
                        }
                    }
                }
            }

            // Walkthrough overlay
            if showWalkthrough {
                TimelineWalkthrough(isPresented: $showWalkthrough)
                    .zIndex(90)
            }

            // Grace period banner (when in grace period but not expired)
            if PremiumManager.shared.isInGracePeriod && !PremiumManager.shared.isGracePeriodExpired {
                VStack {
                    GracePeriodBanner(
                        daysRemaining: PremiumManager.shared.gracePeriodDaysRemaining ?? 0,
                        totalShows: PremiumManager.shared.gracePeriodShowCount,
                        onChooseNow: {
                            showDowngradeModal = true
                        },
                        onUpgrade: {
                            showPremiumPaywall = true
                        }
                    )
                    .padding(.top, 60)

                    Spacer()
                }
                .zIndex(80)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: PremiumManager.shared.isInGracePeriod)
            }

            // Downgrade removal modal (when premium -> free with >3 shows)
            if showDowngradeModal {
                DowngradeRemovalModal(isPresented: $showDowngradeModal)
                    .zIndex(100)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPremiumPaywall) {
            DiscoverPaywallSheet(
                selectedPlan: $selectedPlan,
                isPurchasing: $isPurchasing,
                purchaseError: $purchaseError,
                onDismiss: { showPremiumPaywall = false }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkForDowngrade()
            checkGracePeriodExpiry()
        }
        .onChange(of: PremiumManager.shared.didDowngradeFromPremium) { _, didDowngrade in
            if didDowngrade {
                checkForDowngrade()
            }
        }
        // RevenueCat resolves entitlements after launch, so re-check when the
        // answer lands as well as on first appearance.
        .onChange(of: PremiumManager.shared.isPremium) { _, _ in
            checkForDowngrade()
        }
        .task {
            checkForDowngrade()
        }
    }

    // MARK: - Downgrade & Grace Period Check

    private func checkForDowngrade() {
        // Two separate questions, two separate owners.
        //
        // 1. Premium or free — RevenueCat's answer, and only RevenueCat's.
        guard !PremiumManager.shared.isPremium else { return }

        // 2. Over the limit — ours. RevenueCat knows nothing about how many
        //    shows are followed. `showLimit` is used rather than a bare 3 only
        //    so the free cap lives in one place.
        showDowngradeModal = seriesManager.allSeries().count > PremiumManager.shared.showLimit
    }

    private func checkGracePeriodExpiry() {
        if PremiumManager.shared.isInGracePeriod && PremiumManager.shared.isGracePeriodExpired {
            showDowngradeModal = true
        }
    }

    // MARK: - Persistence

    @MainActor
    private func saveFollowedShows(_ shows: [ShowSummary]) async {
        // Follow each show through SeriesManager (the single write funnel)
        for show in shows {
            do {
                // .onboarding: these must not advance the review-prompt
                // counter — asking for a rating during onboarding is a 5.6.3
                // rejection (and was one).
                _ = try await seriesManager.follow(id: show.id, source: .onboarding)
                print("DEBUG: Followed show \(show.name)")
            } catch {
                print("Error following show \(show.name): \(error)")
            }
        }

        // Trigger timeline refresh
        timelineRefreshTrigger = UUID()
        print("DEBUG: Triggered timeline refresh after saving \(shows.count) shows")
    }

    // MARK: - Tab Bar Appearance

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.c2bBackground)

        // Custom font for tab bar items (JetBrains Mono Bold - same as custom tab bar)
        let tabBarFont = UIFont(name: "JetBrainsMono-Bold", size: 8.5) ?? .systemFont(ofSize: 8.5, weight: .bold)

        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.4, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.4, alpha: 1.0),
            .font: tabBarFont
        ]

        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: tabBarFont
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Settings Placeholder
struct SettingsPlaceholder: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("settings_heading")
                    .font(.custom(.oswald.bold, size: CustomFont.size.heading))
                    .foregroundColor(.c2bText)
                    .textCase(.uppercase)
                    .tracking(0.26)
                    .padding(.top, 52)

                Text("settings_coming_soon")
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundColor(.c2bDim)
                    .padding(.top, 20)

                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Preview for Individual Screens
#Preview("Timeline") {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()
        NavigationStack {
            TimelineScreen(
                layout: "expanded",
                numberStyle: "rotated"
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Timeline - Compact") {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()
        NavigationStack {
            TimelineScreen(
                layout: "compact",
                numberStyle: "stacked"
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Search") {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()
        SearchScreen()
    }
    .preferredColorScheme(.dark)
}

#Preview("Onboarding") {
    struct OnboardingPreviewWrapper: View {
        @State private var showOnboarding = true

        var body: some View {
            ZStack {
                Color.c2bBackground.ignoresSafeArea()
                OnboardingFlow(
                    isPresented: $showOnboarding,
                    onComplete: { plan, shows in
                        print("Completed with plan: \(plan), shows: \(shows.map { $0.name })")
                    }
                )
            }
            .preferredColorScheme(.dark)
        }
    }

    return OnboardingPreviewWrapper()
}

#Preview("Tab Bar") {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()

        VStack {
            Spacer()
            C2BTabBar(
                activeTab: .constant("timeline"),
                onSearchTap: {}
            )
        }
    }
    .preferredColorScheme(.dark)
}
