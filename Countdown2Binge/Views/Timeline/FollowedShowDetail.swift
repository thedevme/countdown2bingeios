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

    // Spinoff count from stored data (set when show was followed)
    private var spinoffCount: Int {
        series.spinoffCount
    }

    // Franchise data for displaying spinoffs tab content
    private var franchise: Franchise? {
        FranchiseService.shared.franchise(forShowId: series.id)
    }

    init(series: Series, onDismiss: @escaping () -> Void, onUnfollow: @escaping () -> Void = {}, onSpinoffTap: @escaping (Int) -> Void = { _ in }) {
        self.series = series
        self.onDismiss = onDismiss
        self.onUnfollow = onUnfollow
        self.onSpinoffTap = onSpinoffTap
        // Default to current season (not anticipated), falling back to numberOfSeasons
        let initialSeason = series.currentSeason?.seasonNumber ?? series.numberOfSeasons
        self._selectedSeason = State(initialValue: initialSeason)
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
                            showSpinoffs: spinoffCount > 0
                        )
                        .padding(.top, 18)
                        .padding(.bottom, 16)

                        // Season picker and status block (only on Season Info tab)
                        if selectedTab == .seasonInfo {
                            DetailSeasonPicker(series: series, selectedSeason: $selectedSeason)
                                .padding(.bottom, 16)

                            // Status card with countdown + lifecycle + clock
                            DetailStatusBlock(show: show, selectedSeason: selectedSeason)
                                .padding(.bottom, 16)
                        }

                        // MARK: - Tab Content
                        switch selectedTab {
                        case .seasonInfo:
                            SeasonInfoTabContent(
                                series: series,
                                selectedSeason: selectedSeason
                            )

                        case .showInfo:
                            ShowInfoTabContent(
                                show: show,
                                cast: cast,
                                videos: videos,
                                isLoading: isLoadingShowInfo
                            )

                        case .spinoffs:
                            ShowDetailSpinoffsSection(
                                show: show,
                                franchise: franchise,
                                onSpinoffTap: onSpinoffTap
                            )
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
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
        .toolbar {
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

                    // Unfollow
                    Section {
                        Button(role: .destructive) {
                            showUnfollowConfirmation = true
                        } label: {
                            Label(String(localized: "button_unfollow"), systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
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
        .task {
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

    private func loadShowInfo() async {
        guard !isLoadingShowInfo else { return }
        isLoadingShowInfo = true

        do {
            let tmdbService = TMDBService()
            async let creditsResult = tmdbService.getShowCredits(id: series.id)
            async let videosResult = tmdbService.getShowVideos(id: series.id)

            let (credits, fetchedVideos) = try await (creditsResult, videosResult)
            cast = credits.cast
            videos = fetchedVideos
        } catch {
            print("Failed to load show info: \(error)")
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
    let selectedSeason: Int

    var body: some View {
        VStack(spacing: 0) {
            // Episode list
            DetailEpisodeSection(series: series, selectedSeason: selectedSeason)
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

