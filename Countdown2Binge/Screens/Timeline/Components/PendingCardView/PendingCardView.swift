//
//  PendingCardView.swift
//  Countdown2Binge
//
//  Section view for "Pending" shows - shows that have started airing
//  but don't have a confirmed finale date.
//
//  NOTE: This section is only shown when there are pending shows.
//  It is completely hidden when empty (unlike Premiering Soon and Anticipated).
//

import SwiftUI

struct PendingCardView: View {
    let shows: [ShowData]
    let onShowTap: (ShowData) -> Void

    @AppStorage("timeline_pending_expanded") private var isExpanded: Bool = true

    var body: some View {
        // Only render if there are pending shows
        if !shows.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                // Section Header
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack(spacing: 9) {
                        Circle()
                            .fill(Color.c2bYellow)
                            .frame(width: 8, height: 8)

                        Text("header_pending")
                            .displayStyle(size: 16, color: .c2bText)

                        Text("\(shows.count)")
                            .monoStyle(size: 9, color: .c2bYellowBright)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.c2bYellow.opacity(0.12))
                            .cornerRadius(C2BLayout.chipRadius)

                        Spacer()

                        Text(isExpanded ? String(localized: "button_hide") : String(localized: "button_show"))
                            .monoStyle(size: 8.5, color: .c2bMuted)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.c2bMuted)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.bottom, 14)
                }

                // Content
                VStack(spacing: isExpanded ? 16 : 10) {
                    ForEach(shows, id: \.id) { show in
                        Button(action: { onShowTap(show) }) {
                            if isExpanded {
                                PendingCard(showData: show)
                            } else {
                                MiniPendingCard(showData: show)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, C2BLayout.horizontalPadding)
            }
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    ScrollView {
        PendingCardView(
            shows: [
                ShowData(
                    id: 1,
                    name: "Cold Harvest",
                    overview: "A show",
                    posterPath: nil,
                    backdropPath: nil,
                    logoPath: nil,
                    firstAirDate: Date().addingTimeInterval(-86400 * 30),
                    status: .returning,
                    genres: [],
                    networks: [NetworkData(id: 1, name: "Apple TV+", logoPath: nil)],
                    createdBy: nil,
                    seasons: [],
                    numberOfSeasons: 2,
                    numberOfEpisodes: 10,
                    inProduction: true,
                    voteAverage: nil
                ),
                ShowData(
                    id: 2,
                    name: "The Lantern Route",
                    overview: "Another show",
                    posterPath: nil,
                    backdropPath: nil,
                    logoPath: nil,
                    firstAirDate: Date().addingTimeInterval(86400 * 26),
                    status: .returning,
                    genres: [],
                    networks: [NetworkData(id: 2, name: "MAX", logoPath: nil)],
                    createdBy: nil,
                    seasons: [],
                    numberOfSeasons: 3,
                    numberOfEpisodes: 8,
                    inProduction: true,
                    voteAverage: nil
                )
            ],
            onShowTap: { _ in }
        )
    }
    .background(Color.c2bBackground)
}
