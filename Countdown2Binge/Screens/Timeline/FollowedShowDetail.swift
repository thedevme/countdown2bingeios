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

    @State private var selectedSeason: Int
    @State private var notifyEnabled = true
    @State private var showShareSheet = false

    init(show: ShowData, onDismiss: @escaping () -> Void) {
        self.show = show
        self.onDismiss = onDismiss
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

                    DetailEpisodeSection(show: show)

                    DetailNotifyToggle(isEnabled: $notifyEnabled)
                        .padding(.top, 26)

                    DetailActionButtons(show: show)
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
