//
//  ShowDetailFollowConfirmationSection.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 8/8/26.
//

import SwiftUI

struct ShowDetailFollowConfirmationSection: View {
    let show: ShowData
    let isFollowing: Bool
    let onTimelineTap: () -> Void

    private var daysUntilBingeReady: Int? {
        show.daysUntilFinale ?? show.daysUntilPremiere
    }

    private var hasDate: Bool {
        daysUntilBingeReady != nil
    }

    var body: some View {
        VStack(spacing: 8) {
            // Status text
            Text(statusText.uppercased())
                .font(.custom(.jetbrains.regular, size: 9))
                .tracking(1.3)
                .foregroundColor(isFollowing ? .c2bTealBright : .c2bMuted)
                .multilineTextAlignment(.center)

            // View on timeline link
            if isFollowing {
                ShowDetailTimelineLink(action: onTimelineTap)
                    .padding(.top, 2)
            }
        }
    }

    private var statusText: String {
        if isFollowing {
            if hasDate, let days = daysUntilBingeReady {
                return String(localized: "following_binge_ready_in \(days)")
            } else {
                return String(localized: "following_waiting_anticipated")
            }
        } else {
            if hasDate, let days = daysUntilBingeReady {
                return String(localized: "follow_prompt_with_days \(days)")
            } else {
                return String(localized: "follow_prompt_no_date")
            }
        }
    }
}

// MARK: - Synopsis Section
struct ShowDetailSynopsisSection: View {
    let show: ShowData
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let overview = show.overview, !overview.isEmpty {
                Text(overview)
                    .font(.system(size: 13.5))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(4)
                    .lineLimit(isExpanded ? nil : 3)

                if overview.count > 150 {
                    Button(action: { isExpanded.toggle() }) {
                        Text(isExpanded ? String(localized: "button_show_less") : String(localized: "button_more"))
                            .font(.custom(.jetbrains.bold, size: 10))
                            .foregroundColor(.c2bTeal)
                            .tracking(0.8)
                    }
                }
            }
        }
        .padding(.top, 16)
    }
}
