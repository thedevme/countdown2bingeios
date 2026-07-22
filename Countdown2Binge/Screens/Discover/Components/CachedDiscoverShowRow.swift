//
//  CachedDiscoverShowRow.swift
//  Countdown2Binge
//

import SwiftUI

struct CachedDiscoverShowRow: View {
    let show: CachedDiscoverShow
    let isFollowing: Bool
    let onTap: () -> Void
    let onFollowTap: () -> Void

    private var posterURL: URL? {
        guard let path = show.posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w154\(path)")
    }

    private var isAvailableNow: Bool {
        guard let days = show.daysUntilPremiere else { return true }
        return days <= 0
    }

    private var isImminentPremiere: Bool {
        guard let days = show.daysUntilPremiere else { return false }
        return days > 0 && days <= 14
    }

    private var countColor: Color {
        if isAvailableNow || isImminentPremiere {
            return .c2bTeal
        }
        return .c2bText
    }

    private var statusText: String {
        guard let days = show.daysUntilPremiere else {
            return "FULL SEASON AVAILABLE"
        }

        if days <= 0 {
            return "FULL SEASON AVAILABLE"
        } else if days <= 7 {
            return "PREMIERES IN \(days) DAY\(days == 1 ? "" : "S")"
        } else if let date = show.firstAirDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "PREMIERES \(formatter.string(from: date).uppercased())"
        } else {
            return "COMING SOON"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Episode count (for Now) or Countdown (for future)
                VStack(spacing: 2) {
                    if isAvailableNow {
                        Text("\(show.episodeCount)")
                            .font(.custom(.oswald.bold, size: numberFontSize(for: show.episodeCount)))
                            .foregroundColor(countColor)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Text("EPS")
                            .font(.custom(.jetbrains.regular, size: 9))
                            .foregroundColor(countColor)
                            .tracking(0.5)
                    } else if let days = show.daysUntilPremiere {
                        Text("\(days)")
                            .font(.custom(.oswald.bold, size: numberFontSize(for: days)))
                            .foregroundColor(countColor)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Text("DAYS")
                            .font(.custom(.jetbrains.regular, size: 9))
                            .foregroundColor(countColor)
                            .tracking(0.5)
                    }
                }
                .frame(width: 50)

                // Poster thumbnail
                if let url = posterURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 52, height: 78)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            posterPlaceholder
                        }
                    }
                } else {
                    posterPlaceholder
                }

                // Show info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(show.name.uppercased())
                            .font(.custom(.oswald.bold, size: 17))
                            .foregroundColor(.c2bText)
                            .lineLimit(1)

                        if show.seasonCount > 0 {
                            Text("S\(show.seasonCount)")
                                .font(.custom(.oswald.bold, size: 12))
                                .foregroundColor(.c2bMuted)
                                .layoutPriority(1)
                        }
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: show.networkColor))
                            .frame(width: 6, height: 6)

                        Text("\(show.networkName.uppercased()) \u{00B7} \(statusText)")
                            .font(.custom(.jetbrains.regular, size: 9))
                            .foregroundColor(.c2bMuted)
                            .tracking(0.5)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Follow button
                Button(action: onFollowTap) {
                    Image(systemName: isFollowing ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isFollowing ? .c2bTeal : .c2bMuted)
                }
            }
            .padding(.horizontal, C2BLayout.horizontalPadding)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.c2bSurface)
            .frame(width: 52, height: 78)
            .overlay(
                Image(systemName: "tv")
                    .font(.system(size: 16))
                    .foregroundColor(.c2bMuted)
            )
    }

    /// Scale font size based on number of digits
    private func numberFontSize(for number: Int) -> CGFloat {
        let digits = String(number).count
        switch digits {
        case 1:
            return 28
        case 2:
            return 28
        case 3:
            return 22
        default:
            return 18
        }
    }
}
