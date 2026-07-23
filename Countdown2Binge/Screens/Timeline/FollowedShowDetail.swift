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
    @State private var notifyEnabled = true
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

                    // Episodes / Spin-offs Tab Switcher (Premium feature)
                    if PremiumManager.shared.canViewSpinoffs {
                        ShowDetailTabSwitcher(
                            selectedTab: $selectedTab,
                            spinoffCount: spinoffCount
                        )
                        .padding(.top, 26)
                        .padding(.bottom, 4)

                        // Tab Content
                        if selectedTab == .episodes {
                            DetailEpisodeSection(show: show)
                        } else {
                            ShowDetailSpinoffsSection(
                                show: show,
                                franchise: franchise,
                                onSpinoffTap: onSpinoffTap
                            )
                        }
                    } else {
                        // Non-premium: just show episodes
                        DetailEpisodeSection(show: show)
                    }

                    DetailNotifyToggle(isEnabled: $notifyEnabled)
                        .padding(.top, 26)

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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showShareSheet)
        .navigationBarHidden(true)
    }
}
