//
//  DiscoverScreen.swift
//  Countdown2Binge
//
//  Discover tab - browse new, recent & upcoming shows.
//

import SwiftUI
import SwiftData
import RevenueCat

struct DiscoverScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SeriesManager.self) private var seriesManager
    @State private var viewModel = DiscoverViewModel()
    @State private var selectedTab: DiscoverTab = .soonerLater
    @State private var selectedNetwork: String = "all"
    @State private var navigationPath = NavigationPath()
    @State private var showPaywall: Bool = false
    /// Explains WHY the follow was refused, before any sales page.
    @State private var showLimitSheet: Bool = false
    @State private var selectedPlan: String = "monthly"
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?
    @State private var showGracePeriodAlert: Bool = false
    @State private var showNotificationOnboarding: Bool = false

    /// Badge manager for tab notifications
    var badgeManager: TabBadgeManager?

    /// Notification settings store for onboarding check
    private var notificationSettingsStore: NotificationSettingsStore { NotificationSettingsStore.shared }

    enum DiscoverTab {
        case soonerLater
        case byNetwork
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("header_discover")
                            .font(.custom(.oswald.bold, size: 32))
                            .foregroundColor(.c2bText)

                        Text("discover_subtitle")
                            .font(.custom(.jetbrains.regular, size: 9))
                            .foregroundColor(.c2bMuted)
                            .tracking(1.0)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.bottom, 20)

                    // Preference-filtered recommendation surface (hard-filtered by
                    // taste). Isolated from the browse rails + search below.
                    DiscoverForYouRail(
                        shows: viewModel.forYouShows,
                        relaxationLabel: viewModel.forYouLabel,
                        isLoading: viewModel.isLoadingForYou,
                        onShowTap: { show in
                            Task {
                                await viewModel.loadShowDetail(for: show)
                                if let showData = viewModel.selectedShowData {
                                    navigationPath.append(showData)
                                }
                            }
                        }
                    )
                    .padding(.bottom, viewModel.forYouShows.isEmpty ? 0 : 24)

                    // Tab switcher
                    DiscoverTabSwitcher(selectedTab: $selectedTab)
                        .padding(.horizontal, C2BLayout.horizontalPadding)
                        .padding(.bottom, 16)

                    // Network filter chips
                    DiscoverNetworkChips(
                        selectedNetwork: $selectedNetwork,
                        networks: DiscoverViewModel.networks
                    )
                    .padding(.bottom, 24)

                    // Content based on selected tab
                    if selectedTab == .soonerLater {
                        DiscoverTimelineContent(
                            viewModel: viewModel,
                            selectedNetwork: selectedNetwork,
                            onShowTap: { show in
                                Task {
                                    await viewModel.loadShowDetail(for: show)
                                    if let showData = viewModel.selectedShowData {
                                        navigationPath.append(showData)
                                    }
                                }
                            },
                            onFollowTap: { show in
                                Task { await viewModel.toggleFollow(show) }
                            }
                        )
                    } else {
                        DiscoverNetworkContent(
                            viewModel: viewModel,
                            selectedNetwork: selectedNetwork,
                            onShowTap: { show in
                                Task {
                                    await viewModel.loadShowDetail(for: show)
                                    if let showData = viewModel.selectedShowData {
                                        navigationPath.append(showData)
                                    }
                                }
                            },
                            onFollowTap: { show in
                                Task { await viewModel.toggleFollow(show) }
                            }
                        )
                    }

                    Spacer()
                        .frame(height: 150)
                }
            }
            .background(Color.c2bBackground)
            .navigationDestination(for: ShowData.self) { showData in
                ShowDetailView(
                    show: showData,
                    cast: viewModel.selectedShowCast,
                    videos: viewModel.selectedShowVideos,
                    recommendations: viewModel.selectedShowRecommendations,
                    isFollowing: viewModel.isFollowing(ShowSummary(
                        id: showData.id,
                        name: showData.name,
                        overview: showData.overview,
                        posterPath: showData.posterPath,
                        backdropPath: showData.backdropPath,
                        firstAirDate: nil,
                        voteAverage: showData.voteAverage,
                        genreIds: showData.genres.map { $0.id }
                    )),
                    isLoadingFollow: viewModel.isLoadingFollow(for: showData.id),
                    onFollowTap: {
                        Task { await viewModel.toggleFollowSelectedShow() }
                    },
                    onRelatedTap: { recommendation in
                        Task {
                            let summary = ShowSummary(
                                id: recommendation.id,
                                name: recommendation.name,
                                overview: recommendation.overview,
                                posterPath: recommendation.posterPath,
                                backdropPath: recommendation.backdropPath,
                                firstAirDate: recommendation.firstAirDate,
                                voteAverage: recommendation.voteAverage,
                                genreIds: recommendation.genreIds
                            )
                            await viewModel.loadShowDetail(for: summary)
                            if let newShowData = viewModel.selectedShowData {
                                navigationPath.append(newShowData)
                            }
                        }
                    },
                    onDismiss: {
                        navigationPath.removeLast()
                        viewModel.clearSelectedShow()
                    }
                )
            }
        }
        .task {
            viewModel.configure(with: modelContext, seriesManager: seriesManager)
            // Fire off loads - they update UI as data arrives
            async let cacheTask: () = viewModel.loadDiscoverFromCache()
            async let networkTask: () = viewModel.loadAllNetworks()
            async let forYouTask: () = viewModel.loadForYou()
            _ = await (cacheTask, networkTask, forYouTask)
        }
        .sheet(item: Binding(
            get: { viewModel.pendingFollowShow },
            set: { _ in viewModel.clearPendingFollow() }
        )) { pendingShow in
            AddShowModal(
                show: pendingShow,
                addTimePrompt: pendingShow.addTimePrompt,
                onDone: { lastWatchedSeason in
                    // Trigger badge based on show state
                    badgeManager?.showFollowed(pendingShow)

                    // Follow + mark all seasons through the one they finished
                    Task {
                        await viewModel.handleAddShowDone(lastWatchedSeason: lastWatchedSeason)
                    }

                    // First follow — but only for someone who will actually
                    // receive notifications. Free users get every alert skipped
                    // at scheduling time, so asking them to pick which ones they
                    // want promises something the app won't deliver.
                    if PremiumManager.shared.canUseNotifications,
                       !notificationSettingsStore.hasCompletedOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showNotificationOnboarding = true
                        }
                    }
                }
            )
        }
        .overlay {
            // Re-checked at render: premium can lapse between the follow and
            // the half-second delay above.
            if showNotificationOnboarding, PremiumManager.shared.canUseNotifications {
                NotificationOnboardingOverlay(onSave: {
                    showNotificationOnboarding = false
                })
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showNotificationOnboarding)
        .onChange(of: viewModel.showPremiumUpgrade) { _, show in
            if show {
                // Explain the block first. The paywall is one tap further on —
                // throwing it up unprompted left users with no idea why their
                // Follow tap did nothing.
                showLimitSheet = true
                viewModel.showPremiumUpgrade = false
            }
        }
        .sheet(isPresented: $showLimitSheet) {
            ShowLimitSheet(
                limit: PremiumManager.shared.showLimit,
                posterURLs: seriesManager.allSeries()
                    .sorted { $0.dateAdded < $1.dateAdded }
                    .map(\.posterURL),
                onUpgrade: {
                    showLimitSheet = false
                    // Let the first sheet finish dismissing before presenting
                    // the next, or the paywall never appears.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showPaywall = true
                    }
                },
                onDismiss: { showLimitSheet = false }
            )
        }
        .onChange(of: viewModel.showGracePeriodBlock) { _, show in
            if show {
                showGracePeriodAlert = true
                viewModel.showGracePeriodBlock = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            DiscoverPaywallSheet(
                selectedPlan: $selectedPlan,
                isPurchasing: $isPurchasing,
                purchaseError: $purchaseError,
                onDismiss: { showPaywall = false }
            )
        }
        .alert(
            String(localized: "grace_cannot_follow_title"),
            isPresented: $showGracePeriodAlert
        ) {
            Button(String(localized: "button_ok"), role: .cancel) {}
        } message: {
            Text("grace_cannot_follow_message")
        }
    }
}

// MARK: - Discover Paywall Sheet
/// Wrapper for PaywallView used in Discover and other screens.
/// Kept for backward compatibility with existing sheet calls.
struct DiscoverPaywallSheet: View {
    @Binding var selectedPlan: String
    @Binding var isPurchasing: Bool
    @Binding var purchaseError: String?
    let onDismiss: () -> Void

    var body: some View {
        PaywallView(
            selectedPlan: $selectedPlan,
            onDismiss: onDismiss,
            onContinueFree: nil,
            showContinueFree: false
        )
    }
}

// MARK: - Show with Network Info (for non-cached use)
struct ShowWithNetwork: Identifiable {
    let show: ShowSummary
    let network: NetworkDefinition

    var id: Int { show.id }
}

#Preview {
    DiscoverScreen()
        .preferredColorScheme(.dark)
}
