//
//  DetailSeasonPicker.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailSeasonPicker: View {
    let show: ShowData
    @Binding var selectedSeason: Int
    @State private var isExpanded = false

    private func episodeCount(for seasonNumber: Int) -> Int {
        show.seasons.first { $0.seasonNumber == seasonNumber }?.episodeCount ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(String(localized: "season_number \(selectedSeason)"))
                        .font(.custom(.oswald.bold, size: 20))
                        .foregroundColor(.white)
                        .textCase(.uppercase)

                    if selectedSeason == show.numberOfSeasons {
                        DetailCurrentBadge()
                    }

                    Spacer()

                    Text(String(localized: "binge_watched_count \(0) \(episodeCount(for: selectedSeason))"))
                        .font(.custom(.jetbrains.regular, size: 9.5))
                        .foregroundColor(.c2bMuted)
                        .tracking(1.0)

                    if show.numberOfSeasons > 1 {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.c2bMuted)
                            .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(isExpanded ? 0 : 13)
                .cornerRadius(13, corners: [.topLeft, .topRight])
            }
            .buttonStyle(.plain)

            // Expandable season list
            if isExpanded && show.numberOfSeasons > 1 {
                VStack(spacing: 0) {
                    ForEach(1...show.numberOfSeasons, id: \.self) { season in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedSeason = season
                                isExpanded = false
                            }
                        } label: {
                            HStack {
                                Text(String(localized: "season_number \(season)"))
                                    .font(.custom(.oswald.regular, size: 18))
                                    .foregroundColor(season == selectedSeason ? .white : .c2bDim)

                                if season == show.numberOfSeasons {
                                    Text("·")
                                        .foregroundColor(.c2bMuted)
                                    Text("detail_current")
                                        .font(.custom(.jetbrains.bold, size: 9))
                                        .foregroundColor(.c2bTeal)
                                        .tracking(1.0)
                                }

                                Spacer()

                                Text("0/\(episodeCount(for: season))")
                                    .font(.custom(.jetbrains.regular, size: 11))
                                    .foregroundColor(.c2bMuted)
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 14)
                            .background(season == selectedSeason ? Color.white.opacity(0.06) : Color.clear)
                        }
                        .buttonStyle(.plain)

                        if season < show.numberOfSeasons {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                                .padding(.horizontal, 15)
                        }
                    }
                }
                .background(Color.white.opacity(0.04))
                .cornerRadius(13, corners: [.bottomLeft, .bottomRight])
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
