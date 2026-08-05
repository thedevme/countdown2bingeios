//
//  PendingCard.swift
//  Countdown2Binge
//
//  Individual card for shows that have started airing but have no confirmed finale date.
//  Displays either countdown to premiere (if not yet aired) or "TBA" for finale date.
//

import SwiftUI

struct PendingCard: View {
    let showData: ShowData

    /// Whether the show has already premiered (premiere date in the past)
    private var hasPremiered: Bool {
        // Check currentSeason first (for airing shows)
        if let premiereDate = showData.currentSeason?.premiereDate {
            return premiereDate <= Date()
        }
        // Check anticipatedSeason (for shows that haven't started)
        if let premiereDate = showData.anticipatedSeason?.premiereDate {
            return premiereDate <= Date()
        }
        // Fallback: check first regular season
        if let firstSeason = showData.seasons.first(where: { !$0.isSpecials }),
           let premiereDate = firstSeason.premiereDate {
            return premiereDate <= Date()
        }
        // No premiere date found - assume premiered
        return true
    }

    private var daysUntilPremiere: Int {
        showData.daysUntilPremiere ?? 0
    }

    private var seasonNumber: String {
        String(showData.numberOfSeasons)
    }

    private var platformString: String {
        showData.networks.first?.name ?? ""
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: Countdown or TBA section
            countdownSection

            // Right: Poster with overlays
            posterSection
        }
        .contentShape(Rectangle())
    }

    // MARK: - Left Section (Countdown or TBA)

    @ViewBuilder
    private var countdownSection: some View {
        if hasPremiered {
            // Post-premiere: TBA finale date
            TBACountdownLabelView(bottomLabel: "pending_finale_date_label")
        } else {
            // Pre-premiere: Countdown to premiere
            CountdownLabelView(
                number: daysUntilPremiere,
                accentColor: .c2bYellowBright,
                bottomLabel: "timeline_to_premiere"
            )
        }
    }

    /// Mock asset name mapping for debug shows
    private var mockAssetName: String? {
        switch showData.id {
        case 999001: return "north watch"    // Cold Harvest
        case 999002: return "iron veil"      // The Lantern Route
        default: return nil
        }
    }

    // MARK: - Right Section (Poster)

    @ViewBuilder
    private var posterSection: some View {
        ZStack(alignment: .topTrailing) {
            // Poster image - check mock asset FIRST (for debug shows)
            if let assetName = mockAssetName {
                // Use local asset for mock shows
                Image(assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .clipped()
                    .overlay(Color.black.opacity(0.3))
                    .overlay(
                        Rectangle()
                            .fill(Color.c2bYellowLine)
                            .frame(width: 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
            } else if let url = showData.posterURL {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(hex: "#1a1a1c"))
                }
                .frame(height: 140)
                .clipped()
                .overlay(Color.black.opacity(0.3))
                .overlay(
                    Rectangle()
                        .fill(Color.c2bYellowLine)
                        .frame(width: 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )
            } else {
                Rectangle()
                    .fill(Color(hex: "#1a1a1c"))
                    .frame(height: 140)
            }

            // Overlay content
            VStack(alignment: .leading, spacing: 0) {
                // Top badges
                HStack(spacing: 6) {
                    // Finale Date TBA badge
                    HStack(spacing: 4) {
                        Image(systemName: "diamond")
                            .font(.system(size: 7, weight: .bold))
                        Text("pending_finale_tba_badge")
                            .font(.custom(.jetbrains.bold, size: 8))
                            .tracking(0.5)
                    }
                    .foregroundColor(.c2bYellowBright)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.c2bYellow.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.c2bYellowLine, lineWidth: 1)
                    )
                    .cornerRadius(6)

                    Spacer()

                    // Network badge
                    if !platformString.isEmpty {
                        Text(platformString.uppercased())
                            .font(.custom(.jetbrains.bold, size: 9))
                            .foregroundColor(Color(hex: "#e7e7e7"))
                            .tracking(0.54)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#080808").opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .cornerRadius(6)
                    }
                }

                Spacer()

                // Bottom: Season + Show name
                HStack(alignment: .bottom, spacing: 8) {
                    // Season badge
                    HStack(spacing: 0) {
                        Text("season_abbrev")
                            .font(.custom(.oswald.bold, size: 28))
                            .foregroundColor(.white)
                        Text(seasonNumber)
                            .font(.custom(.oswald.light, size: 28))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)

                    Text(showData.name.uppercased())
                        .font(.custom(.oswald.bold, size: 19))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                }
            }
            .padding(10)
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Mini Pending Card (Compact Mode)

struct MiniPendingCard: View {
    let showData: ShowData

    /// Whether the show has already premiered
    private var hasPremiered: Bool {
        guard let premiereDate = showData.currentSeason?.premiereDate else {
            return true
        }
        return premiereDate <= Date()
    }

    private var daysUntilPremiere: Int {
        showData.daysUntilPremiere ?? 0
    }

    private var seasonNumber: String {
        String(showData.numberOfSeasons)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Left: Countdown or TBA
            VStack(alignment: .leading, spacing: 0) {
                if hasPremiered {
                    // Post-premiere: TBA finale date
                    Text("pending_tba")
                        .font(.custom(.oswald.bold, size: 28))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("pending_finale_date_label")
                        .font(.custom(.jetbrains.bold, size: 6.5))
                        .tracking(0.6)
                        .foregroundColor(Color(hex: "#52525b"))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                } else {
                    // Pre-premiere: Countdown days
                    Text("\(daysUntilPremiere)")
                        .font(.custom(.oswald.bold, size: 38))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("time_days")
                        .font(.custom(.oswald.bold, size: 14))
                        .foregroundColor(.c2bYellowBright)
                        .textCase(.uppercase)
                        .tracking(1.0)

                    Text("timeline_to_premiere")
                        .font(.custom(.jetbrains.bold, size: 6.5))
                        .tracking(0.6)
                        .foregroundColor(Color(hex: "#52525b"))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .frame(width: 68, alignment: .leading)

            // Middle: Season + Name
            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 0) {
                    Text("season_abbrev")
                        .font(.custom(.oswald.bold, size: 20))
                        .foregroundColor(.white)

                    Text(seasonNumber)
                        .font(.custom(.oswald.light, size: 20))
                        .foregroundColor(.white)
                }

                Text(showData.name)
                    .font(.custom(.oswald.bold, size: 17))
                    .foregroundColor(.c2bText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: Network badge
            if let network = showData.networks.first {
                Text(network.name.uppercased())
                    .font(.custom(.jetbrains.bold, size: 8))
                    .tracking(0.3)
                    .foregroundColor(Color(hex: "#e7e7e7"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 60)
        .background(Color.white.opacity(0.03))
        .overlay(
            Rectangle()
                .fill(Color.c2bYellowLine)
                .frame(width: 2),
            alignment: .leading
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

#Preview("Pending Card - TBA Finale") {
    VStack(spacing: 20) {
        PendingCard(showData: ShowData(
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
        ))

        MiniPendingCard(showData: ShowData(
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
        ))
    }
    .padding(20)
    .background(Color.c2bBackground)
}
