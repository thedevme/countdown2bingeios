//
//  DiscoverNetworkSection.swift
//  Countdown2Binge
//
//  Network section with header and horizontal show scroll.
//

import SwiftUI

struct DiscoverNetworkSection: View {
    let network: NetworkDefinition
    let shows: [ShowSummary]
    let isFollowing: (ShowSummary) -> Bool
    let onShowTap: (ShowSummary) -> Void
    let onFollowTap: (ShowSummary) -> Void

    private var networkIcon: String {
        String(network.name.prefix(1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Network header
            HStack(spacing: 12) {
                // Network icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: network.color).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Text(networkIcon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: network.color))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(network.name.uppercased())
                        .font(.custom(.oswald.bold, size: 22))
                        .foregroundColor(.c2bText)

                    Text("\(shows.count) UPCOMING")
                        .font(.custom(.jetbrains.regular, size: 9))
                        .foregroundColor(.c2bMuted)
                        .tracking(1.0)
                }

                Spacer()

                // Sooner/Later toggle
                HStack(spacing: 4) {
                    Text("SOONER")
                        .font(.custom(.jetbrains.regular, size: 8))
                        .foregroundColor(.c2bMuted)
                        .tracking(0.8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.c2bMuted)

                    Text("LATER")
                        .font(.custom(.jetbrains.regular, size: 8))
                        .foregroundColor(.c2bDim)
                        .tracking(0.8)
                }
            }
            .padding(.horizontal, C2BLayout.horizontalPadding)

            // Shows horizontal scroll
            if shows.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.c2bMuted)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shows) { show in
                            DiscoverShowCard(
                                show: show,
                                networkColor: network.color,
                                daysUntil: daysUntilPremiere(show),
                                isFollowing: isFollowing(show),
                                onTap: { onShowTap(show) },
                                onFollowTap: { onFollowTap(show) }
                            )
                        }
                    }
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                }
            }
        }
    }

    private func daysUntilPremiere(_ show: ShowSummary) -> Int? {
        guard let dateString = show.firstAirDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return nil }

        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return days > 0 ? days : nil
    }
}
