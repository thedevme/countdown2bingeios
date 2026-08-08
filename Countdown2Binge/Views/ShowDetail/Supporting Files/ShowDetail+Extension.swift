//
//  ShowDetail+Extension.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 8/8/26.
//


extension ShowDetailView {
    /// Initializer for use with ShowSummary (creates placeholder ShowData)
    init(
        summary: ShowSummary,
        isFollowing: Bool,
        onFollowTap: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        let placeholderShow = ShowData(
            id: summary.id,
            name: summary.name,
            overview: summary.overview,
            posterPath: summary.posterPath,
            backdropPath: summary.backdropPath,
            logoPath: nil,
            firstAirDate: nil,
            status: .returning,
            genres: [],
            networks: [],
            createdBy: nil,
            seasons: [],
            numberOfSeasons: 0,
            numberOfEpisodes: 0,
            inProduction: true,
            voteAverage: summary.voteAverage
        )
        self.init(
            show: placeholderShow,
            cast: [],
            videos: [],
            recommendations: [],
            isFollowing: isFollowing,
            isLoadingFollow: false,
            onFollowTap: onFollowTap,
            onPlayTap: {},
            onTimelineTap: {},
            onRelatedTap: { _ in },
            onDismiss: onDismiss
        )
    }
}