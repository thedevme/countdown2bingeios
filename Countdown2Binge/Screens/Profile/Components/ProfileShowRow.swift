//
//  ProfileShowRow.swift
//  Countdown2Binge
//
//  Show row in profile with sync status.
//

import SwiftUI

struct ProfileShowRow: View {
    let show: Series
    let isSynced: Bool
    let onTap: () -> Void

    private var showName: String {
        show.name.isEmpty ? "Show \(show.id)" : show.name
    }

    private var posterURL: URL? {
        show.posterURL
    }

    private var seasonCount: Int {
        max(show.numberOfSeasons, 1)
    }

    private var episodeCount: Int {
        show.numberOfEpisodes
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
    let series1 = Series(id: 1234, name: "Breaking Bad")
    series1.numberOfSeasons = 5
    series1.numberOfEpisodes = 62

    let series2 = Series(id: 5678, name: "Better Call Saul")
    series2.numberOfSeasons = 6
    series2.numberOfEpisodes = 63

    return VStack(spacing: 0) {
        ProfileShowRow(
            show: series1,
            isSynced: true,
            onTap: {}
        )

        Divider()
            .background(Color.white.opacity(0.06))

        ProfileShowRow(
            show: series2,
            isSynced: false,
            onTap: {}
        )
    }
    .padding(.horizontal, 20)
    .background(Color.c2bBackground)
    .preferredColorScheme(.dark)
}
