//
//  DiscoverForYouRail.swift
//  Countdown2Binge
//
//  The preference-filtered recommendation surface on the Discover tab. Served by
//  RecommendationService (hard-filtered by the user's genres + providers, the same
//  path onboarding uses). Additive — the network/date-bucket browse rails and
//  search are untouched.
//

import SwiftUI

struct DiscoverForYouRail: View {
    let shows: [ShowSummary]
    let relaxationLabel: String?
    let isLoading: Bool
    let onShowTap: (ShowSummary) -> Void

    var body: some View {
        if isLoading && shows.isEmpty {
            ProgressView()
                .tint(.c2bTeal)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
        } else if !shows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("FOR YOU")
                        .font(.custom(.jetbrains.bold, size: 11))
                        .tracking(1.2)
                        .foregroundColor(.c2bTeal)
                    Spacer()
                    if let relaxationLabel, !relaxationLabel.isEmpty {
                        Text(relaxationLabel.uppercased())
                            .font(.custom(.jetbrains.regular, size: 9))
                            .tracking(0.8)
                            .foregroundColor(.c2bMuted)
                    }
                }
                .padding(.horizontal, C2BLayout.horizontalPadding)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(shows) { show in
                            Button { onShowTap(show) } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    PosterView(url: show.posterURL, cornerRadius: 11)
                                        .frame(width: 120)
                                    Text(show.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.c2bText)
                                        .lineLimit(1)
                                        .frame(width: 120, alignment: .leading)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                }
            }
        }
    }
}
