//
//  DetailActionButtons.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailActionButtons: View {
    let show: ShowData
    let onUnfollow: () -> Void

    @State private var showUnfollowConfirmation = false

    private var isReady: Bool {
        show.timelineCategory == .bingeReady
    }

    var body: some View {
        VStack(spacing: 12) {
            if isReady {
                DetailPrimaryButton(title: String(localized: "button_start_binge"), style: .primary) {
                    // Start binge
                }
            }

            DetailUnfollowButton {
                showUnfollowConfirmation = true
            }
        }
        .confirmationDialog(
            String(localized: "alert_unfollow \(show.name)"),
            isPresented: $showUnfollowConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "button_unfollow"), role: .destructive) {
                onUnfollow()
            }
            Button(String(localized: "button_cancel"), role: .cancel) {}
        } message: {
            Text("alert_remove_message")
        }
    }
}
