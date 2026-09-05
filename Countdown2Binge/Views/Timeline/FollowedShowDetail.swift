//
//  FollowedShowDetail.swift
//  Countdown2Binge
//
//  Detail view for followed shows from the timeline.
//

import SwiftUI
import SwiftData

struct FollowedShowDetail: View {
    @Bindable var series: Series
    let onDismiss: () -> Void
    let onUnfollow: () -> Void
    var onSpinoffTap: (Int) -> Void = { _ in }

    @Environment(SeriesManager.self) private var seriesManager

    @State private var selectedSeason: Int
    @State private var showShareSheet = false
    @State private var showUnfollowConfirmation = false
    @State private var selectedTab: FollowedDetailTab = .seasonInfo
    @State private var isArchived: Bool = false
    @State private var showAlerts = false
    @State private var showSpinoffsPaywall = false
    @State private var spinoffsPaywallPlan = "monthly"

    // Data for Show Info tab (fetched on appear)
    @State private var cast: [TMDBCastMember] = []
    @State private var videos: [TMDBVideo] = []
    @State private var isLoadingShowInfo = false

    // Archive storage key. NOTE: My List no longer has an Archived tab (Ready /
    // Watched only), so this set is written here but not currently surfaced.
    private let archivedShowsKey = "archivedShowIds"

    /// Convert Series to ShowData for child components
    private var show: ShowData {
        series.toShowData()
    }

    /// Read once, here, and passed down explicitly — kept in this file (rather
    /// than read inside ShowDetailSpinoffsSection) so the premium-gate-audit
    /// build script, which greps this exact file for `canViewSpinoffs`, keeps
    /// proving the check hasn't quietly disappeared from the feature that owns it.
    private var canViewSpinoffs: Bool {
        PremiumManager.shared.canViewSpinoffs
    }

    /// Franchise data from the bundled FranchiseCatalog engine (BundledFranchiseProvider),
    /// resolved live rather than from any Series snapshot — same reasoning as
    /// the old FranchiseService-backed version this replaced: always asking
    /// fresh keeps the tab from disagreeing with itself, and there is no
    /// stored, potentially-stale cache to fall behind.
    @State private var franchiseGroup: FranchiseGroup?
    /// Backdrop URL per spin-off entry. Not part of FranchiseEntry itself (the
    /// engine is image-agnostic) — resolved here from the local Series when
    /// already followed (no network), or a TMDB fetch otherwise.
    @State private var spinoffPosterURLs: [MediaKey: URL] = [:]
    /// Tap targets for the spin-offs list: an already-followed entry pushes
    /// this same view again (recursively) on its own Series; a not-yet-followed
    /// one pushes SpinoffUnfollowedDetailHost, which fetches its own ShowData
    /// by tmdbId — navigation never depends on a background pre-fetch having
    /// already succeeded (it used to, silently via `try?`, so a slow or failed
    /// fetch meant tapping the entry did nothing at all).
    @State private var selectedFollowedSpinoff: Series?
    @State private var selectedUnfollowedSpinoffTarget: SpinoffTapTarget?

    init(series: Series, initialSeason: Int? = nil, onDismiss: @escaping () -> Void, onUnfollow: @escaping () -> Void = {}, onSpinoffTap: @escaping (Int) -> Void = { _ in }) {
        self.series = series
        self.onDismiss = onDismiss
        self.onUnfollow = onUnfollow
        self.onSpinoffTap = onSpinoffTap
        // Prefer an explicit season (e.g. the season a My List card is on).
        // Otherwise the default pairs with EpisodeTrackerView's own list
        // order: still airing → newest season (matches the newest-first
        // list); ended → wherever the user's watch progress actually is
        // (matches the oldest-first list), falling back to newest when
        // there's nothing left unwatched.
        let fallback: Int
        if series.status.isActive {
            fallback = series.numberOfSeasons
        } else {
            fallback = series.earliestUnwatchedSeason?.seasonNumber ?? series.numberOfSeasons
        }
        self._selectedSeason = State(initialValue: initialSeason ?? fallback)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Hero Section
                    DetailHeroSection(show: show)

                    // MARK: - Content Section
                    VStack(spacing: 0) {
                        // MARK: - Segmented Tab Bar
                        FollowedDetailTabBar(selectedTab: $selectedTab)
                        .padding(.top, 18)
                        .padding(.bottom, 16)

                        // Status block (only on Season Info tab). The season
                        // dropdown lives in the tracker below now.
                        if selectedTab == .seasonInfo {
                            // Status card with countdown + lifecycle + clock
                            DetailStatusBlock(show: show, selectedSeason: selectedSeason)
                                .padding(.bottom, 16)
                        }

                        // MARK: - Tab Content
                        switch selectedTab {
                        case .seasonInfo:
                            SeasonInfoTabContent(
                                series: series,
                                selectedSeason: $selectedSeason
                            )

                        case .showInfo:
                            ShowInfoTabContent(
                                show: show,
                                cast: cast,
                                videos: videos,
                                isLoading: isLoadingShowInfo
                            )

                        case .spinoffs:
                            // Always rendered — SpinoffsEraSection itself decides
                            // no-franchise (empty state, shown to everyone) vs.
                            // premium (full era card) vs. free (locked era card),
                            // off the isPremium value computed above.
                            SpinoffsEraSection(
                                franchiseGroup: franchiseGroup,
                                showTitle: series.name,
                                isPremium: canViewSpinoffs,
                                posterURLs: spinoffPosterURLs,
                                onEntryTap: { entry in
                                    guard entry.isFollowable else { return }
                                    if let followedSeries = seriesManager.series(id: entry.tmdbId) {
                                        selectedFollowedSpinoff = followedSeries
                                    } else {
                                        selectedUnfollowedSpinoffTarget = SpinoffTapTarget(id: entry.tmdbId)
                                    }
                                    onSpinoffTap(entry.tmdbId)
                                },
                                onUnlockTap: { showSpinoffsPaywall = true }
                            )
                        }

                        // Unfollow — full-width destructive action at the page bottom
                        Button {
                            showUnfollowConfirmation = true
                        } label: {
                            Text(String(localized: "button_unfollow"))
                                .font(.custom(.oswald.bold, size: 16))
                                .tracking(0.5)
                                .textCase(.uppercase)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#E5484D"))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 36)
                        // Attached to the button, not the page. iOS 26 anchors a
                        // confirmation dialog to the view it is attached to, so
                        // hanging it off the outer ZStack floated it up by the
                        // toolbar with a tail pointing at nothing.
                        .confirmationDialog(
                            String(localized: "alert_unfollow \(series.name)"),
                            isPresented: $showUnfollowConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button(String(localized: "button_unfollow"), role: .destructive) {
                                onUnfollow()
                                onDismiss()
                            }
                            Button(String(localized: "button_cancel"), role: .cancel) {}
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 150)
                }
            }
            .background(Color.c2bBackground)
            .ignoresSafeArea(edges: .top)

            // Custom share sheet overlay
            if showShareSheet {
                ShareSheet(show: show, onClose: { showShareSheet = false })
                    .zIndex(100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
        .toolbar {
            // Alerts bell — premium only, like every other notification
            // surface. Free users get no notifications, so there is nothing
            // for this sheet to show them.
            if PremiumManager.shared.isPremium {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAlerts = true
                    } label: {
                        Image(systemName: series.notificationsActive ? "bell.fill" : "bell.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(series.notificationsActive ? .c2bTealBright : .c2bMuted)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Watch Now
                    if let network = show.networks.first,
                       let service = StreamingService.from(networkId: network.id, networkName: network.name) {
                        Button {
                            openStreamingApp(service: service)
                        } label: {
                            Label(String(localized: "watch_on \(service.displayName)"), systemImage: "play.tv")
                        }
                    }

                    // Share
                    Button {
                        showShareSheet = true
                    } label: {
                        Label(String(localized: "button_share"), systemImage: "square.and.arrow.up")
                    }

                    // Archive/Unarchive
                    Button {
                        toggleArchive()
                    } label: {
                        Label(
                            isArchived ? String(localized: "button_unarchive") : String(localized: "button_archive"),
                            systemImage: isArchived ? "arrow.uturn.backward" : "archivebox"
                        )
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .sheet(isPresented: $showAlerts) {
            ShowAlertsSheet(series: series, onDismiss: { showAlerts = false })
        }
        .sheet(isPresented: $showSpinoffsPaywall) {
            PaywallView(
                selectedPlan: $spinoffsPaywallPlan,
                onDismiss: { showSpinoffsPaywall = false },
                onContinueFree: nil
            )
        }
        // Spin-off tap targets — pushed locally rather than through the
        // caller's own NavigationStack path, so this view stays self-contained
        // regardless of which of the three screens presented it.
        .navigationDestination(item: $selectedFollowedSpinoff) { spinoffSeries in
            FollowedShowDetail(
                series: spinoffSeries,
                onDismiss: { selectedFollowedSpinoff = nil },
                onUnfollow: {
                    let id = spinoffSeries.id
                    Task { try? await seriesManager.unfollowAwaitingCloud(id: id) }
                }
            )
        }
        .navigationDestination(item: $selectedUnfollowedSpinoffTarget) { target in
            SpinoffUnfollowedDetailHost(
                tmdbId: target.id,
                onDismiss: { selectedUnfollowedSpinoffTarget = nil }
            )
        }
        .task {
            await loadSpinoffs()
            await loadShowInfo()
        }
        .onAppear {
            loadArchiveState()
        }
    }

    // MARK: - Streaming App

    @Environment(\.openURL) private var openURL

    private func openStreamingApp(service: StreamingService) {
        if let deepLink = service.deepLinkURL(for: series.name),
           UIApplication.shared.canOpenURL(deepLink) {
            openURL(deepLink)
        } else if let webURL = service.webURL(for: series.name) {
            openURL(webURL)
        }
    }

    // MARK: - Data Loading

    /// Looks this show up in the bundled franchise catalog, then — regardless
    /// of premium status, since the locked card still needs to know the
    /// current era to seal the rest — resolves a backdrop per entry: the
    /// local Series when already followed (no network), a TMDB fetch
    /// otherwise. Movie entries are skipped: TMDBServiceProtocol has no
    /// movie-details endpoint, only TV, so there's nothing real to show for
    /// them today.
    private func loadSpinoffs() async {
        let group = await BundledFranchiseProvider.shared.franchise(forShowId: series.id, locale: Locale.current)
        franchiseGroup = group
        guard let group else {
            spinoffPosterURLs = [:]
            return
        }

        // Backdrops only — this is a nice-to-have for the row art, so a
        // failed fetch here just leaves that one row without a thumbnail.
        // Tap-to-navigate does NOT depend on this succeeding (see
        // SpinoffUnfollowedDetailHost, which fetches its own ShowData by
        // tmdbId on demand instead of relying on this cache).
        let entries = group.sections.flatMap(\.entries).filter { !$0.isCurrentShow && $0.isFollowable }
        var resolvedURLs: [MediaKey: URL] = [:]
        let tmdbService = TMDBService()

        for entry in entries {
            if let followedSeries = seriesManager.series(id: entry.tmdbId) {
                resolvedURLs[entry.id] = followedSeries.toShowData().backdropURL
            } else if let fetched = try? await tmdbService.getShowDetails(id: entry.tmdbId) {
                resolvedURLs[entry.id] = fetched.backdropURL
            }
        }
        spinoffPosterURLs = resolvedURLs
    }

    private func loadShowInfo() async {
        guard !isLoadingShowInfo else { return }
        isLoadingShowInfo = true

        do {
            let tmdbService = TMDBService()
            // Read the Sendable id on the main actor so the non-Sendable Series
            // is never captured into the concurrent async-let child tasks.
            let showId = series.id
            async let creditsResult = tmdbService.getShowCredits(id: showId)
            async let videosResult = tmdbService.getShowVideos(id: showId)

            let (credits, fetchedVideos) = try await (creditsResult, videosResult)
            cast = credits.cast
            videos = fetchedVideos
        } catch {
        }

        isLoadingShowInfo = false
    }

    // MARK: - Archive Management

    private func loadArchiveState() {
        if let ids = UserDefaults.standard.array(forKey: archivedShowsKey) as? [Int] {
            isArchived = ids.contains(series.id)
        }
    }

    private func toggleArchive() {
        var ids = Set(UserDefaults.standard.array(forKey: archivedShowsKey) as? [Int] ?? [])

        if isArchived {
            // Unarchive - stay on page
            ids.remove(series.id)
            UserDefaults.standard.set(Array(ids), forKey: archivedShowsKey)
            isArchived = false
        } else {
            // Archive - dismiss and go back
            ids.insert(series.id)
            UserDefaults.standard.set(Array(ids), forKey: archivedShowsKey)
            isArchived = true
            onDismiss()
        }
    }
}

// MARK: - Season Info Tab Content

private struct SeasonInfoTabContent: View {
    let series: Series
    @Binding var selectedSeason: Int

    var body: some View {
        VStack(spacing: 0) {
            // Season accordion — the open season reveals its episode tracker.
            EpisodeTrackerView(series: series, selectedSeason: $selectedSeason)
        }
    }
}

// MARK: - Show Info Tab Content

private struct ShowInfoTabContent: View {
    let show: ShowData
    let cast: [TMDBCastMember]
    let videos: [TMDBVideo]
    let isLoading: Bool

    private var yearString: String {
        guard let date = show.firstAirDate else { return "" }
        return String(Calendar.current.component(.year, from: date))
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .tint(.c2bTeal)
                    .padding(.vertical, 40)
            } else {
                // Metadata row (year, runtime, badges)
                ShowDetailMetadataRow(
                    year: yearString,
                    runtime: "~55 min",
                    rating: "14+",
                    contentBadges: ["TV-MA", "4K"],
                    hasDolbyVision: true,
                    hasDolbyAtmos: true,
                    accessibilityBadges: ["CC", "SDH", "AD"]
                )
                .padding(.bottom, 16)

                // Synopsis
                DetailSynopsisSection(overview: show.overview)
                    .padding(.bottom, 24)

                // Trailers & Previews
                ShowDetailTrailersSection(videos: videos)

                // Cast & Crew
                ShowDetailCastSection(cast: cast)

                // About
                ShowDetailAboutSection(show: show)
            }
        }
    }
}

// MARK: - Spin-off Tap Target (not yet followed)

/// Identifies a not-yet-followed spin-off tap by tmdb id only — `ShowData`
/// itself isn't required to navigate; `SpinoffUnfollowedDetailHost` fetches
/// it on demand, so a tap always goes somewhere even if nothing was
/// pre-cached for this id.
struct SpinoffTapTarget: Identifiable, Hashable {
    let id: Int
}

/// Hosts the discover-style `ShowDetailView` for a spin-off entry that isn't
/// followed yet. Fetches its own `ShowData` (plus cast/videos) by tmdb id —
/// this is what makes tap-to-navigate reliable: it doesn't depend on
/// `FollowedShowDetail.loadSpinoffs()` having already succeeded for this
/// show, which was the actual bug when a tap on an entry did nothing (that
/// background fetch swallowed its own failures via `try?`, and navigation
/// was gated on its result). Also wires a minimal, limit-respecting follow
/// action — a lighter path than the full AddShowModal catch-up flow Discover
/// uses, since reaching a show through its own franchise doesn't need to ask
/// which season you've already watched before it can be followed.
private struct SpinoffUnfollowedDetailHost: View {
    let tmdbId: Int
    let onDismiss: () -> Void

    @Environment(SeriesManager.self) private var seriesManager

    @State private var show: ShowData?
    @State private var cast: [TMDBCastMember] = []
    @State private var videos: [TMDBVideo] = []
    @State private var loadFailed = false
    @State private var isFollowing = false
    @State private var isLoadingFollow = false
    @State private var showPaywall = false
    @State private var paywallPlan = "monthly"

    var body: some View {
        Group {
            if let show {
                ShowDetailView(
                    show: show,
                    cast: cast,
                    videos: videos,
                    isFollowing: isFollowing,
                    isLoadingFollow: isLoadingFollow,
                    onFollowTap: { Task { await toggleFollow() } },
                    onDismiss: onDismiss
                )
            } else if loadFailed {
                VStack(spacing: 14) {
                    Text(String(localized: "error_load_shows"))
                        .font(.system(size: 14))
                        .foregroundColor(.c2bDim)
                    Button(String(localized: "button_try_again")) {
                        Task { await load() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.c2bTeal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.c2bBackground)
            } else {
                ProgressView()
                    .tint(.c2bTeal)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.c2bBackground)
            }
        }
        .task {
            isFollowing = seriesManager.series(id: tmdbId) != nil
            await load()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                selectedPlan: $paywallPlan,
                onDismiss: { showPaywall = false },
                onContinueFree: nil
            )
        }
    }

    private func load() async {
        loadFailed = false
        let tmdbService = TMDBService()

        guard let fetchedShow = try? await tmdbService.getShowDetails(id: tmdbId) else {
            loadFailed = true
            return
        }
        show = fetchedShow

        async let creditsResult = tmdbService.getShowCredits(id: tmdbId)
        async let videosResult = tmdbService.getShowVideos(id: tmdbId)
        if let (credits, fetchedVideos) = try? await (creditsResult, videosResult) {
            cast = credits.cast
            videos = fetchedVideos
        }
    }

    private func toggleFollow() async {
        guard !isFollowing, let show else { return }

        // Same gates Discover applies before a follow: grace period first,
        // then the premium show-count limit.
        guard !PremiumManager.shared.isInGracePeriod else {
            showPaywall = true
            return
        }
        guard PremiumManager.shared.canAddShow(currentCount: seriesManager.followedCount()) else {
            showPaywall = true
            return
        }

        isLoadingFollow = true
        defer { isLoadingFollow = false }

        if (try? seriesManager.follow(showData: show, source: .user)) != nil {
            isFollowing = true
        }
    }
}

