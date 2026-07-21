//
//  DetailActionButtons.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailActionButtons: View {
    let show: ShowData

    private var isReady: Bool {
        show.timelineCategory == .bingeReady
    }

    var body: some View {
        VStack(spacing: 12) {
            if isReady {
                DetailPrimaryButton(title: "\u{25B8} START BINGE", style: .primary) {
                    // Start binge
                }
            }

            DetailPrimaryButton(
                title: "BINGE PLAN",
                icon: "calendar.badge.checkmark",
                style: isReady ? .secondary : .primary
            ) {
                // Binge plan
            }

            DetailUnfollowButton {
                // Unfollow
            }
        }
    }
}
