//
//  ShowDetailView.swift
//  Countdown2Binge
//
//  Detail view for shows from search/discover (not yet followed).
//  Parent view that assembles all child components.
//

import SwiftUI

struct ShowDetailView: View {
    let show: ShowData
    let cast: [TMDBCastMember]
    let videos: [TMDBVideo]
    let recommendations: [TMDBShowSummary]
    let isFollowing: Bool
    let isLoadingFollow: Bool
    let onFollowTap: () -> Void
    let onPlayTap: () -> Void
    let onTimelineTap: () -> Void
    let onRelatedTap: (TMDBShowSummary) -> Void
    let onSpinoffTap: (Int) -> Void  // TMDB ID of spinoff
    let onDismiss: () -> Void

    @State private var selectedSeason: Int
    @State private var selectedTab: ShowDetailTab = .episodes

    // Franchise data for spinoffs
    private var franchise: Franchise? {
        let result = FranchiseService.shared.franchise(forShowId: show.id)
        print("DEBUG ShowDetail: Looking up franchise for show.id=\(show.id) (\(show.name)), found: \(result?.localizedName() ?? "nil")")
        return result
    }

    private var spinoffCount: Int {
        franchise?.spinoffs.count ?? 0
    }

    init(
        show: ShowData,
        cast: [TMDBCastMember] = [],
        videos: [TMDBVideo] = [],
        recommendations: [TMDBShowSummary] = [],
        isFollowing: Bool,
        isLoadingFollow: Bool = false,
        onFollowTap: @escaping () -> Void,
        onPlayTap: @escaping () -> Void = {},
        onTimelineTap: @escaping () -> Void = {},
        onRelatedTap: @escaping (TMDBShowSummary) -> Void = { _ in },
        onSpinoffTap: @escaping (Int) -> Void = { _ in },
        onDismiss: @escaping () -> Void
    ) {
        self.show = show
        self.cast = cast
        self.videos = videos
        self.recommendations = recommendations
        self.isFollowing = isFollowing
        self.isLoadingFollow = isLoadingFollow
        self.onFollowTap = onFollowTap
        self.onPlayTap = onPlayTap
        self.onTimelineTap = onTimelineTap
        self.onRelatedTap = onRelatedTap
        self.onSpinoffTap = onSpinoffTap
        self.onDismiss = onDismiss
        self._selectedSeason = State(initialValue: show.numberOfSeasons)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Hero Section
                    ShowDetailHeroSection(
                        show: show,
                        isFollowing: isFollowing,
                        onDismiss: onDismiss
                    )

                    // MARK: - Content Section
                    VStack(spacing: 0) {
                        // Follow Action Row (Follow + Play buttons)
                        ShowDetailFollowActionRow(
                            isFollowing: isFollowing,
                            isLoading: isLoadingFollow,
                            onFollowTap: onFollowTap
                        )

                        // Follow Confirmation + Timeline Link
                        ShowDetailFollowConfirmationSection(
                            show: show,
                            isFollowing: isFollowing,
                            onTimelineTap: onTimelineTap
                        )
                        .padding(.top, 12)

                        // Metadata Row (Apple TV style)
                        ShowDetailMetadataRow(
                            year: show.yearString ?? "2026",
                            runtime: "~55 min",
                            rating: "14+",
                            contentBadges: ["TV-MA", "4K"],
                            hasDolbyVision: true,
                            hasDolbyAtmos: true,
                            accessibilityBadges: ["CC", "SDH", "AD"]
                        )
                        .padding(.top, 18)

                        // Synopsis
                        ShowDetailSynopsisSection(show: show)

                        // Season Bar
                        ShowDetailSeasonBar(
                            seasonNumber: show.numberOfSeasons,
                            status: seasonStatus,
                            episodeInfo: seasonEpisodeInfo
                        )
                        .padding(.top, 22)

                        // Status Card with Lifecycle Rail
                        ShowDetailStatusCard(
                            bigValue: statusCardBigValue,
                            showDaysLabel: showDaysLabel,
                            eyebrow: statusCardEyebrow,
                            dateLine: statusCardDateLine,
                            pillText: statusCardPillText,
                            isReady: show.showState == .bingeReady,
                            isTBD: show.showState == .anticipated,
                            lifecycleIndex: lifecycleIndex
                        )
                        .padding(.top, 12)

                        // Follow Hint
                        ShowDetailFollowHint(
                            hasDate: show.daysUntilPremiere != nil,
                            episodeCount: show.currentSeason?.episodeCount ?? 8
                        )
                        .padding(.top, 12)

                        // Episodes / Spin-offs Tab Switcher (Premium feature)
                        if PremiumManager.shared.canViewSpinoffs && spinoffCount > 0 {
                            ShowDetailTabSwitcher(
                                selectedTab: $selectedTab,
                                showCatchUp: false,
                                showSpinoffs: true,
                                spinoffCount: spinoffCount
                            )
                            .padding(.top, 26)

                            // Tab Content
                            if selectedTab == .spinoffs {
                                ShowDetailSpinoffsSection(
                                    show: show,
                                    franchise: franchise,
                                    onSpinoffTap: onSpinoffTap
                                )
                            }
                            // Episodes tab content would go here (episode tracker)
                        }

                        // Trailers & Previews
                        ShowDetailTrailersSection(videos: videos)

                        // Cast & Crew
                        ShowDetailCastSection(cast: cast)

                        // Related Shows (Premium feature)
                        if PremiumManager.shared.canViewSpinoffs {
                            ShowDetailRelatedSection(
                                recommendations: recommendations,
                                onTap: onRelatedTap
                            )
                        } else if !recommendations.isEmpty {
                            // Show upgrade prompt for free users
                            ShowDetailRelatedUpgradePrompt()
                        }

                        // About
                        ShowDetailAboutSection(show: show)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 150)
                }
            }
            .background(Color.c2bBackground)
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if let network = show.primaryNetwork?.name {
                ToolbarItem(placement: .topBarTrailing) {
                    ShowDetailNetworkChip(
                        networkName: network,
                        accentColor: Self.networkAccentColor(for: network)
                    )
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }

    /// Accent color per network for the nav-bar chip (moved from the old top bar).
    private static func networkAccentColor(for network: String) -> Color {
        switch network.lowercased() {
        case "netflix": return Color(hex: "#E50914")
        case "hbo", "max": return Color(hex: "#5A35E0")
        case "prime video", "amazon": return Color(hex: "#1FB6FF")
        case "hulu": return Color(hex: "#1CE783")
        case "apple tv+", "apple": return .c2bMuted
        case "disney+", "disney": return Color(hex: "#1FA2FF")
        default: return .c2bTeal
        }
    }

    // MARK: - Computed Properties

    private var seasonStatus: ShowDetailSeasonStatus? {
        switch show.showState {
        case .airing, .pending: return .airing
        case .premieringSoon: return .new
        case .bingeReady: return .ready
        case .anticipated: return nil
        }
    }

    private var seasonEpisodeInfo: String {
        guard let season = show.currentSeason else { return "TBA" }
        switch show.showState {
        case .bingeReady:
            return String(localized: "season_all_out \(season.episodeCount)")
        case .airing, .pending:
            let aired = season.episodes.filter { $0.hasAired }.count
            return String(localized: "season_partial_out \(aired) \(season.episodeCount)")
        case .premieringSoon, .anticipated:
            return String(localized: "season_episode_count \(season.episodeCount)")
        }
    }

    private var statusCardBigValue: String {
        switch show.showState {
        case .bingeReady: return "NOW"
        case .anticipated: return "TBD"
        case .airing:
            if let days = show.daysUntilFinale {
                return "\(days)"
            }
            return "TBD"
        case .pending:
            // Pending has no finale date
            return "TBD"
        case .premieringSoon:
            if let days = show.daysUntilPremiere {
                return "\(days)"
            }
            return "TBD"
        }
    }

    private var showDaysLabel: Bool {
        statusCardBigValue != "NOW" && statusCardBigValue != "TBD"
    }

    private var statusCardEyebrow: String {
        switch show.showState {
        case .bingeReady: return String(localized: "status_ready_to_binge")
        case .anticipated: return String(localized: "status_until_new_season")
        case .airing, .pending, .premieringSoon: return String(localized: "status_until_binge_ready")
        }
    }

    private var statusCardDateLine: String {
        switch show.showState {
        case .bingeReady:
            let eps = show.currentSeason?.episodeCount ?? 0
            return String(localized: "status_all_episodes_finished \(eps)")
        case .airing:
            if let finaleDate = show.currentSeason?.finaleDate {
                return String(localized: "status_finale_date \(finaleDate.localizedShortDate)")
            }
            return String(localized: "status_airing_weekly")
        case .pending:
            // Pending = airing but no confirmed finale
            return String(localized: "status_airing_weekly")
        case .premieringSoon:
            if let premiereDate = show.currentSeason?.airDate,
               let days = show.daysUntilPremiere {
                let readyDays = days + (show.currentSeason?.episodeCount ?? 8) * 7
                return String(localized: "status_premieres_ready \(premiereDate.localizedShortDate) \(readyDays)")
            }
            return String(localized: "status_coming_soon")
        case .anticipated:
            return String(localized: "status_no_release_date")
        }
    }

    private var statusCardPillText: String {
        switch show.showState {
        case .bingeReady:
            let eps = show.currentSeason?.episodeCount ?? 0
            return String(localized: "pill_binge_ready \(eps)")
        case .airing:
            let aired = show.currentSeason?.episodes.filter { $0.hasAired }.count ?? 0
            let total = show.currentSeason?.episodeCount ?? 0
            return String(localized: "pill_now_airing \(aired) \(total)")
        case .pending:
            // Pending = airing but no finale countdown
            let aired = show.currentSeason?.episodes.filter { $0.hasAired }.count ?? 0
            let total = show.currentSeason?.episodeCount ?? 0
            return String(localized: "pill_now_airing \(aired) \(total)")
        case .premieringSoon:
            if let days = show.daysUntilPremiere {
                return String(localized: "pill_premiering_in \(days)")
            }
            return String(localized: "pill_premiering_soon")
        case .anticipated:
            return String(localized: "badge_anticipated")
        }
    }

    private var lifecycleIndex: Int {
        switch show.showState {
        case .anticipated: return 0
        case .premieringSoon: return 1
        case .airing, .pending: return 2
        case .bingeReady: return 3
        }
    }
}

// MARK: - Preview
#Preview {
    ShowDetailView(
        show: ShowData(
            id: 1,
            name: "The Last of Us",
            overview: "Twenty years after modern civilization has been destroyed, Joel, a hardened survivor, is hired to smuggle Ellie, a 14-year-old girl, out of an oppressive quarantine zone.",
            posterPath: "/uKvVjHNqB5VmOrdxqAt2F7J78ED.jpg",
            backdropPath: "/uDgy6hyPd82kOHh6I95FLtLnj6p.jpg",
            logoPath: nil,
            firstAirDate: Date(),
            status: .returning,
            genres: [GenreData(id: 18, name: "Drama"), GenreData(id: 10765, name: "Sci-Fi")],
            networks: [NetworkData(id: 49, name: "HBO", logoPath: nil)],
            createdBy: nil,
            seasons: [],
            numberOfSeasons: 2,
            numberOfEpisodes: 17,
            inProduction: true,
            voteAverage: 8.8
        ),
        isFollowing: false,
        onFollowTap: {},
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
