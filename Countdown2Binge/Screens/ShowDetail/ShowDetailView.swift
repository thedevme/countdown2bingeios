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
                        onFollowTap: onFollowTap,
                        onPlayTap: onPlayTap
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
                        isReady: show.timelineCategory == .bingeReady,
                        isTBD: show.timelineCategory == .anticipated,
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
                    if PremiumManager.shared.canViewSpinoffs {
                        ShowDetailTabSwitcher(
                            selectedTab: $selectedTab,
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
        .navigationBarHidden(true)
    }

    // MARK: - Computed Properties

    private var seasonStatus: ShowDetailSeasonStatus? {
        switch show.timelineCategory {
        case .airingNow: return .airing
        case .premieringSoon: return .new
        case .bingeReady: return .ready
        case .anticipated: return nil
        }
    }

    private var seasonEpisodeInfo: String {
        guard let season = show.currentSeason else { return "TBA" }
        switch show.timelineCategory {
        case .bingeReady:
            return String(localized: "season_all_out \(season.episodeCount)")
        case .airingNow:
            let aired = season.episodes.filter { $0.hasAired }.count
            return String(localized: "season_partial_out \(aired) \(season.episodeCount)")
        default:
            return String(localized: "season_episode_count \(season.episodeCount)")
        }
    }

    private var statusCardBigValue: String {
        switch show.timelineCategory {
        case .bingeReady: return "NOW"
        case .anticipated: return "TBD"
        default:
            if let days = show.daysUntilFinale ?? show.daysUntilPremiere {
                return "\(days)"
            }
            return "TBD"
        }
    }

    private var showDaysLabel: Bool {
        statusCardBigValue != "NOW" && statusCardBigValue != "TBD"
    }

    private var statusCardEyebrow: String {
        switch show.timelineCategory {
        case .bingeReady: return String(localized: "status_ready_to_binge")
        case .anticipated: return String(localized: "status_until_new_season")
        default: return String(localized: "status_until_binge_ready")
        }
    }

    private var statusCardDateLine: String {
        switch show.timelineCategory {
        case .bingeReady:
            let eps = show.currentSeason?.episodeCount ?? 0
            return String(localized: "status_all_episodes_finished \(eps)")
        case .airingNow:
            if let finaleDate = show.currentSeason?.finaleDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return String(localized: "status_finale_date \(formatter.string(from: finaleDate))")
            }
            return String(localized: "status_airing_weekly")
        case .premieringSoon:
            if let premiereDate = show.currentSeason?.airDate,
               let days = show.daysUntilPremiere {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                let readyDays = days + (show.currentSeason?.episodeCount ?? 8) * 7
                return String(localized: "status_premieres_ready \(formatter.string(from: premiereDate)) \(readyDays)")
            }
            return String(localized: "status_coming_soon")
        case .anticipated:
            return String(localized: "status_no_release_date")
        }
    }

    private var statusCardPillText: String {
        switch show.timelineCategory {
        case .bingeReady:
            let eps = show.currentSeason?.episodeCount ?? 0
            return String(localized: "pill_binge_ready \(eps)")
        case .airingNow:
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
        switch show.timelineCategory {
        case .anticipated: return 0
        case .premieringSoon: return 1
        case .airingNow: return 2
        case .bingeReady: return 3
        }
    }
}

// MARK: - Follow Action Row
struct ShowDetailFollowActionRow: View {
    let isFollowing: Bool
    let isLoading: Bool
    let onFollowTap: () -> Void
    let onPlayTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Follow button
            Button(action: onFollowTap) {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(isFollowing ? .c2bTealBright : Color(hex: "#04201c"))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 18))
                    }

                    Text(isFollowing ? String(localized: "button_following") : String(localized: "button_follow_show"))
                        .font(.custom(.oswald.bold, size: 19))
                        .tracking(0.4)
                }
                .foregroundColor(isFollowing ? .c2bTealBright : Color(hex: "#04201c"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(isFollowing ? Color.white.opacity(0.07) : .white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isFollowing ? Color.white.opacity(0.16) : .clear, lineWidth: 1)
                )
            }
            .disabled(isLoading)

            // Play button
            ShowDetailPlayButton(action: onPlayTap)
        }
    }
}

// MARK: - Follow Confirmation Section
struct ShowDetailFollowConfirmationSection: View {
    let show: ShowData
    let isFollowing: Bool
    let onTimelineTap: () -> Void

    private var daysUntilBingeReady: Int? {
        show.daysUntilFinale ?? show.daysUntilPremiere
    }

    private var hasDate: Bool {
        daysUntilBingeReady != nil
    }

    var body: some View {
        VStack(spacing: 8) {
            // Status text
            Text(statusText.uppercased())
                .font(.custom(.jetbrains.regular, size: 9))
                .tracking(1.3)
                .foregroundColor(isFollowing ? .c2bTealBright : .c2bMuted)
                .multilineTextAlignment(.center)

            // View on timeline link
            if isFollowing {
                ShowDetailTimelineLink(action: onTimelineTap)
                    .padding(.top, 2)
            }
        }
    }

    private var statusText: String {
        if isFollowing {
            if hasDate, let days = daysUntilBingeReady {
                return String(localized: "following_binge_ready_in \(days)")
            } else {
                return String(localized: "following_waiting_anticipated")
            }
        } else {
            if hasDate, let days = daysUntilBingeReady {
                return String(localized: "follow_prompt_with_days \(days)")
            } else {
                return String(localized: "follow_prompt_no_date")
            }
        }
    }
}

// MARK: - Synopsis Section
struct ShowDetailSynopsisSection: View {
    let show: ShowData
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let overview = show.overview, !overview.isEmpty {
                Text(overview)
                    .font(.system(size: 13.5))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(4)
                    .lineLimit(isExpanded ? nil : 3)

                if overview.count > 150 {
                    Button(action: { isExpanded.toggle() }) {
                        Text(isExpanded ? String(localized: "button_show_less") : String(localized: "button_more"))
                            .font(.custom(.jetbrains.bold, size: 10))
                            .foregroundColor(.c2bTeal)
                            .tracking(0.8)
                    }
                }
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - ShowSummary Support (for Onboarding)
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
