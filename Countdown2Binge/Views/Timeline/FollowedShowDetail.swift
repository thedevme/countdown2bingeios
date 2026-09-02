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

    @State private var selectedSeason: Int
    @State private var showShareSheet = false
    @State private var showUnfollowConfirmation = false
    @State private var selectedTab: FollowedDetailTab = .seasonInfo
    @State private var isArchived: Bool = false
    @State private var showAlerts = false

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

    /// Franchise data, resolved LIVE from FranchiseService rather than from the
    /// Series snapshot. `series.relatedShowIds` is written once in a background
    /// task at follow-time and guarded by `spinoffsResolved`, which is set even
    /// when the lookup came back empty — so any show followed before the
    /// franchise list covered it is stuck at spinoffCount 0 forever, with no
    /// backfill path. Reading the service directly also keeps the tab and the
    /// tab's contents (which already read it live) from disagreeing.
    ///
    /// Latched into @State because FranchiseService is not @Observable: the
    /// launch fetch is async, and a plain computed property would not re-render
    /// this view when it lands.
    @State private var franchise: Franchise?

    private var spinoffCount: Int {
        guard let franchise else { return 0 }
        return franchise.allTmdbIds.filter { $0 != series.id }.count
    }

    /// Spin-offs are a premium feature, same as on the unfollowed detail view.
    /// The tab is hidden outright rather than shown locked — a followed show is
    /// somewhere the user already lives, and a dead tab there reads as broken.
    private var canShowSpinoffs: Bool {
        PremiumManager.shared.canViewSpinoffs && spinoffCount > 0
    }

    init(series: Series, initialSeason: Int? = nil, onDismiss: @escaping () -> Void, onUnfollow: @escaping () -> Void = {}, onSpinoffTap: @escaping (Int) -> Void = { _ in }) {
        self.series = series
        self.onDismiss = onDismiss
        self.onUnfollow = onUnfollow
        self.onSpinoffTap = onSpinoffTap
        // Prefer an explicit season (e.g. the season a My List card is on), else
        // default to the current season (not anticipated), falling back to count.
        let fallback = series.currentSeason?.seasonNumber ?? series.numberOfSeasons
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
                        FollowedDetailTabBar(
                            selectedTab: $selectedTab,
                            showSpinoffs: canShowSpinoffs
                        )
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
                            // Reachable only while the tab is visible; the guard
                            // covers a downgrade landing mid-view.
                            if canShowSpinoffs {
                                ShowDetailSpinoffsSection(
                                    show: show,
                                    franchise: franchise,
                                    onSpinoffTap: onSpinoffTap
                                )
                            }
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
        .task {
            // No-ops once loaded; covers a detail view opened before the
            // launch-time fetch finished.
            await FranchiseService.shared.fetchFranchises()
            franchise = FranchiseService.shared.franchise(forShowId: series.id)
            await loadShowInfo()
        }
        .onAppear {
            loadArchiveState()
            // Premium can lapse while this view is on screen; don't strand the
            // user on a tab that no longer has a bar entry or any content.
            if selectedTab == .spinoffs, !canShowSpinoffs {
                selectedTab = .seasonInfo
            }
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

