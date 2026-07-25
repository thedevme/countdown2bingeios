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
    @State private var viewModel = DiscoverViewModel()
    @State private var selectedTab: DiscoverTab = .soonerLater
    @State private var selectedNetwork: String = "all"
    @State private var navigationPath = NavigationPath()
    @State private var showPaywall: Bool = false
    @State private var selectedPlan: String = "yearly"
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?

    /// Badge manager for tab notifications
    var badgeManager: TabBadgeManager?

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
            viewModel.configure(with: modelContext)
            // Fire off both loads - they update UI as data arrives
            async let cacheTask: () = viewModel.loadDiscoverFromCache()
            async let networkTask: () = viewModel.loadAllNetworks()
            _ = await (cacheTask, networkTask)
        }
        .sheet(item: Binding(
            get: { viewModel.pendingFollowShow },
            set: { _ in viewModel.clearPendingFollow() }
        )) { pendingShow in
            FollowConfirmationSheet(
                show: pendingShow,
                onSave: {
                    // Trigger badge based on show state
                    badgeManager?.showFollowed(pendingShow)

                    Task {
                        await viewModel.confirmPendingFollow()
                    }
                }
            )
        }
        .onChange(of: viewModel.showPremiumUpgrade) { _, show in
            if show {
                showPaywall = true
                viewModel.showPremiumUpgrade = false
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
    }
}

// MARK: - Discover Paywall Sheet
struct DiscoverPaywallSheet: View {
    @Binding var selectedPlan: String
    @Binding var isPurchasing: Bool
    @Binding var purchaseError: String?
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#000000").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#71717a"))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)

                // Reuse PaywallStep content
                PaywallStep(followedCount: 3, selectedPlan: $selectedPlan)

                // Purchase button
                Button(action: {
                    Task { await handlePurchase() }
                }) {
                    HStack(spacing: 10) {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#04201c")))
                                .scaleEffect(0.8)
                        }
                        Text(selectedPlan == "lifetime" ? String(localized: "button_purchase_lifetime") : String(localized: "button_start_trial"))
                            .font(.custom(.oswald.bold, size: 17))
                            .foregroundColor(Color(hex: "#04201c"))
                            .textCase(.uppercase)
                            .tracking(0.17)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#2dd4bf"))
                    .cornerRadius(15)
                }
                .disabled(isPurchasing)
                .padding(.horizontal, 22)
                .padding(.bottom, 16)

                // Legal text
                if selectedPlan != "lifetime" {
                    Text("premium_trial_legal")
                        .font(.custom(.jetbrains.bold, size: 9))
                        .foregroundColor(Color(hex: "#71717a"))
                        .textCase(.uppercase)
                        .tracking(1.6)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                }
            }

            // Error overlay
            if let error = purchaseError {
                Color.black.opacity(0.5).ignoresSafeArea()
                    .onTapGesture { purchaseError = nil }

                VStack(spacing: 16) {
                    Text("alert_purchase_failed")
                        .font(.custom(.oswald.bold, size: 18))
                        .foregroundColor(.white)

                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#a1a1aa"))
                        .multilineTextAlignment(.center)

                    Button("button_ok") { purchaseError = nil }
                        .font(.custom(.oswald.bold, size: 16))
                        .foregroundColor(Color(hex: "#04201c"))
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#2dd4bf"))
                        .cornerRadius(10)
                }
                .padding(24)
                .background(Color(hex: "#1a1a1c"))
                .cornerRadius(16)
                .padding(40)
            }
        }
    }

    private func handlePurchase() async {
        let packageId: String
        switch selectedPlan {
        case "yearly":
            packageId = "$rc_annual"
        case "monthly":
            packageId = "$rc_monthly"
        case "lifetime":
            packageId = "$rc_lifetime"
        default:
            onDismiss()
            return
        }

        isPurchasing = true
        purchaseError = nil

        do {
            let offerings = try await PremiumManager.shared.getOfferings()

            guard let currentOffering = offerings.current,
                  let package = currentOffering.package(identifier: packageId) else {
                isPurchasing = false
                onDismiss()
                return
            }

            let success = try await PremiumManager.shared.purchase(package: package)
            isPurchasing = false

            if success {
                onDismiss()
            }
        } catch {
            isPurchasing = false
            purchaseError = error.localizedDescription
        }
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
