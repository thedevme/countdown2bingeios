//
//  DiscoverTimelineContent.swift
//  Countdown2Binge
//

import SwiftUI

struct DiscoverTimelineContent: View {
    let viewModel: DiscoverViewModel
    let selectedNetwork: String
    let onShowTap: (ShowSummary) -> Void
    let onFollowTap: (ShowSummary) -> Void

    private var networkId: Int? {
        if selectedNetwork == "all" { return nil }
        return Int(selectedNetwork)
    }

    var body: some View {
        VStack(spacing: 28) {
            ForEach(DiscoverBucket.allCases, id: \.self) { bucket in
                let shows = viewModel.getCachedShows(bucket: bucket, networkId: networkId)
                let count = viewModel.getCachedShowCount(bucket: bucket, networkId: networkId)

                if !shows.isEmpty {
                    CachedTimelineSection(
                        title: bucket.displayTitle,
                        count: count,
                        shows: shows,
                        isFollowing: { viewModel.isFollowing(ShowSummary(
                            id: $0.tmdbId,
                            name: $0.name,
                            overview: $0.overview,
                            posterPath: $0.posterPath,
                            backdropPath: $0.backdropPath,
                            firstAirDate: nil,
                            voteAverage: $0.voteAverage,
                            genreIds: nil
                        )) },
                        onShowTap: { cachedShow in
                            let summary = ShowSummary(
                                id: cachedShow.tmdbId,
                                name: cachedShow.name,
                                overview: cachedShow.overview,
                                posterPath: cachedShow.posterPath,
                                backdropPath: cachedShow.backdropPath,
                                firstAirDate: cachedShow.firstAirDate.map { formatDate($0) },
                                voteAverage: cachedShow.voteAverage,
                                genreIds: nil
                            )
                            onShowTap(summary)
                        },
                        onFollowTap: { cachedShow in
                            let summary = ShowSummary(
                                id: cachedShow.tmdbId,
                                name: cachedShow.name,
                                overview: cachedShow.overview,
                                posterPath: cachedShow.posterPath,
                                backdropPath: cachedShow.backdropPath,
                                firstAirDate: cachedShow.firstAirDate.map { formatDate($0) },
                                voteAverage: cachedShow.voteAverage,
                                genreIds: nil
                            )
                            onFollowTap(summary)
                        }
                    )
                }
            }

            if viewModel.cachedShows.isEmpty && viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.c2bMuted)
                    Spacer()
                }
                .padding(.vertical, 40)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Cached Timeline Section
struct CachedTimelineSection: View {
    let title: String
    let count: Int
    let shows: [CachedDiscoverShow]
    let isFollowing: (CachedDiscoverShow) -> Bool
    let onShowTap: (CachedDiscoverShow) -> Void
    let onFollowTap: (CachedDiscoverShow) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text(title)
                    .font(.custom(.oswald.bold, size: 18))
                    .foregroundColor(.c2bText)

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)

                Text("\(count)")
                    .font(.custom(.jetbrains.regular, size: 12))
                    .foregroundColor(.c2bMuted)
            }
            .padding(.horizontal, C2BLayout.horizontalPadding)

            // Show rows
            VStack(spacing: 0) {
                ForEach(shows, id: \.tmdbId) { show in
                    CachedDiscoverShowRow(
                        show: show,
                        isFollowing: isFollowing(show),
                        onTap: { onShowTap(show) },
                        onFollowTap: { onFollowTap(show) }
                    )
                }
            }
        }
    }
}
