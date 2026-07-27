//
//  FollowedShowDetail.swift
//  Countdown2Binge
//
//  Detail view for followed shows from the timeline.
//

import SwiftUI

struct FollowedShowDetail: View {
    let show: ShowData
    let onDismiss: () -> Void
    let onUnfollow: () -> Void
    var onSpinoffTap: (Int) -> Void = { _ in }

    @State private var selectedSeason: Int
    @State private var showShareSheet = false
    @State private var selectedTab: ShowDetailTab = .episodes

    // Franchise data for spinoffs
    private var franchise: Franchise? {
        FranchiseService.shared.franchise(forShowId: show.id)
    }

    private var spinoffCount: Int {
        guard let franchise = franchise else { return 0 }
        // Count all related shows in the franchise (excluding current show)
        return franchise.allTmdbIds.filter { $0 != show.id }.count
    }

    private var hasSpinoffs: Bool {
        PremiumManager.shared.canViewSpinoffs && spinoffCount > 0
    }

    private var showCatchUp: Bool {
        // Show catch up tab if show is airing and has a finale date coming up
        show.lifecycleState == .airing && show.daysUntilFinale != nil
    }

    private var showTabs: Bool {
        // Show tabs if we have catch up OR spinoffs (always show episodes)
        showCatchUp || hasSpinoffs
    }

    init(show: ShowData, onDismiss: @escaping () -> Void, onUnfollow: @escaping () -> Void = {}, onSpinoffTap: @escaping (Int) -> Void = { _ in }) {
        self.show = show
        self.onDismiss = onDismiss
        self.onUnfollow = onUnfollow
        self.onSpinoffTap = onSpinoffTap
        self._selectedSeason = State(initialValue: show.numberOfSeasons)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    DetailHeroSection(
                        show: show,
                        onDismiss: onDismiss,
                        onShare: { showShareSheet = true }
                    )

                VStack(spacing: 0) {
                    // Streaming app deep link
                    StreamingLinkButton(
                        network: show.primaryNetwork,
                        showName: show.name
                    )
                    .padding(.bottom, 16)

                    DetailSeasonPicker(
                        show: show,
                        selectedSeason: $selectedSeason
                    )
                    .padding(.bottom, 16)

                    DetailStatusBlock(show: show)

                    // Countdown clock (only when days remaining)
                    if let days = show.daysUntilFinale ?? show.daysUntilPremiere, days > 0 {
                        BingeClock(days: days)
                    }

                    // Tab Switcher (show if catch up or spinoffs available)
                    if showTabs {
                        ShowDetailTabSwitcher(
                            selectedTab: $selectedTab,
                            showCatchUp: showCatchUp,
                            showSpinoffs: hasSpinoffs,
                            spinoffCount: spinoffCount
                        )
                        .padding(.top, 26)
                        .padding(.bottom, 4)

                        // Tab Content
                        switch selectedTab {
                        case .catchUp:
                            DetailCatchUpSection(show: show)
                        case .episodes:
                            DetailEpisodeSection(show: show, selectedSeason: selectedSeason)
                        case .spinoffs:
                            ShowDetailSpinoffsSection(
                                show: show,
                                franchise: franchise,
                                onSpinoffTap: onSpinoffTap
                            )
                        }
                    } else {
                        // No tabs needed: just show episodes
                        DetailEpisodeSection(show: show, selectedSeason: selectedSeason)
                    }

                    DetailActionButtons(show: show, onUnfollow: {
                        onUnfollow()
                        onDismiss()
                    })
                        .padding(.top, 22)
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 150)
                }
            }
            .background(Color.c2bBackground)
            .ignoresSafeArea(edges: .top)

            // Custom share sheet overlay
            if showShareSheet {
                ShareSheet(show: show, onClose: { showShareSheet = false })
                    .zIndex(100)
            }
        }
        .navigationBarHidden(true)
    }
}
