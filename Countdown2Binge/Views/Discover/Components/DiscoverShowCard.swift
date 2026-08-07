//
//  DiscoverShowCard.swift
//  Countdown2Binge
//
//  Show card for Discover screen with poster, countdown badge, and follow button.
//

import SwiftUI

struct DiscoverShowCard: View {
    let show: ShowSummary
    let networkColor: String
    let daysUntil: Int?
    let isFollowing: Bool
    let onTap: () -> Void
    let onFollowTap: () -> Void

    private let cardWidth: CGFloat = 155

    private var posterURL: URL? {
        guard let path = show.posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(path)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster with countdown badge
            Button(action: onTap) {
                ZStack(alignment: .topLeading) {
                    // Poster image
                    PosterView(url: posterURL, width: cardWidth, cornerRadius: 14)

                    // Countdown badge
                    if let days = daysUntil, days > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("countdown_in")
                                .font(.custom(.jetbrains.regular, size: 10))
                                .foregroundColor(.white.opacity(0.9))

                            Text("\(days)d")
                                .font(.custom(.oswald.bold, size: 14))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.c2bTeal)
                        .cornerRadius(10)
                        .padding(10)
                    }
                }
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Show title
            Text(show.name.uppercased())
                .font(.custom(.oswald.bold, size: 15))
                .foregroundColor(.c2bText)
                .lineLimit(1)
                .padding(.top, 12)

            // Premiere date
            if let dateString = show.firstAirDate, let date = parseDate(dateString) {
                Text(String(localized: "premieres_date \(formatDate(date))"))
                    .font(.custom(.jetbrains.regular, size: 9))
                    .foregroundColor(.c2bMuted)
                    .tracking(0.8)
                    .padding(.top, 4)
            }

            // Follow button
            Button(action: onFollowTap) {
                HStack(spacing: 8) {
                    Image(systemName: isFollowing ? "checkmark" : "bookmark.fill")
                        .font(.system(size: 12, weight: .semibold))

                    Text(isFollowing ? "FOLLOWING" : "FOLLOW")
                        .font(.custom(.oswald.bold, size: 13))
                }
                .foregroundColor(isFollowing ? .c2bTealBright : Color(hex: "#04201c"))
                .frame(width: cardWidth)
                .padding(.vertical, 12)
                .background(isFollowing ? Color.c2bTeal.opacity(0.15) : Color.c2bTeal)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFollowing ? Color.c2bTeal.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            .padding(.top, 12)
        }
        .frame(width: cardWidth)
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }

    private func formatDate(_ date: Date) -> String {
        date.localizedShortDate.uppercased()
    }
}
