//
//  ProfileShowRow.swift
//  Countdown2Binge
//
//  Show row in profile with sync status.
//

import SwiftUI

struct ProfileShowRow: View {
    let show: FollowedShow
    let isSynced: Bool
    let onTap: () -> Void

    private var showName: String {
        show.cachedData?.name ?? "Show \(show.tmdbId)"
    }

    private var posterURL: URL? {
        guard let path = show.cachedData?.posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w154\(path)")
    }

    private var seasonCount: Int {
        show.cachedData?.numberOfSeasons ?? 1
    }

    private var episodeCount: Int {
        show.cachedData?.numberOfEpisodes ?? 0
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 13) {
                // Poster
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(Color.c2bSurface)
                    }
                }
                .frame(width: 42, height: 63)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .grayscale(isSynced ? 0 : 0.6)
                .brightness(isSynced ? 0 : -0.35)

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(showName)
                        .font(.custom(.oswald.bold, size: 17))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text("\(seasonCount) \(seasonCount == 1 ? String(localized: "profile_season") : String(localized: "profile_seasons")) · \(episodeCount) \(String(localized: "profile_episodes_label"))")
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundColor(.c2bMuted)
                }

                Spacer()

                // Sync status
                if isSynced {
                    HStack(spacing: 6) {
                        Text("profile_synced")
                            .font(.custom(.jetbrains.bold, size: 8))
                            .tracking(1.0)
                            .foregroundColor(.c2bTealBright)

                        ZStack {
                            Circle()
                                .fill(Color.c2bTeal)
                                .frame(width: 20, height: 20)

                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "#04201c"))
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Text("profile_local_only")
                            .font(.custom(.jetbrains.bold, size: 8))
                            .tracking(1.0)
                            .foregroundColor(.c2bMuted)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.c2bMuted)
                    }
                }
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 0) {
        ProfileShowRow(
            show: FollowedShow(tmdbId: 1234),
            isSynced: true,
            onTap: {}
        )

        Divider()
            .background(Color.white.opacity(0.06))

        ProfileShowRow(
            show: FollowedShow(tmdbId: 5678),
            isSynced: false,
            onTap: {}
        )
    }
    .padding(.horizontal, 20)
    .background(Color.c2bBackground)
    .preferredColorScheme(.dark)
}
