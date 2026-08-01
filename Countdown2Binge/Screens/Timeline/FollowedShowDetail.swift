//
//  FollowedShowDetail.swift
//  Countdown2Binge
//
//  Detail view for followed shows from the timeline.
//

import SwiftUI

struct FollowedShowDetail: View {
    let show: ShowData
    let onDismiss: () -> Void
    let onUnfollow: () -> Void
    var onSpinoffTap: (Int) -> Void = { _ in }

    @State private var selectedSeason: Int
    @State private var showShareSheet = false
    @State private var selectedTab: FollowedDetailTab = .seasonInfo
    @State private var isArchived: Bool = false

    // Data for Show Info tab (fetched on appear)
    @State private var cast: [TMDBCastMember] = []
    @State private var videos: [TMDBVideo] = []
    @State private var isLoadingShowInfo = false

    // Archive storage key (shared with MyListViewModel)
    private let archivedShowsKey = "archivedShowIds"

    // Spinoff count from stored data (set when show was followed)
    private var spinoffCount: Int {
        show.spinoffCount ?? 0
    }

    // Franchise data for displaying spinoffs tab content
    private var franchise: Franchise? {
        FranchiseService.shared.franchise(forShowId: show.id)
    }

    init(show: ShowData, onDismiss: @escaping () -> Void, onUnfollow: @escaping () -> Void = {}, onSpinoffTap: @escaping (Int) -> Void = { _ in }) {
        self.show = show
        self.onDismiss = onDismiss
        self.onUnfollow = onUnfollow
        self.onSpinoffTap = onSpinoffTap
        // Default to current season (not anticipated), falling back to numberOfSeasons
        let initialSeason = show.currentSeason?.seasonNumber ?? show.numberOfSeasons
        self._selectedSeason = State(initialValue: initialSeason)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Hero Section
                    DetailHeroSection(
                        show: show,
                        onDismiss: onDismiss,
                        onShare: { showShareSheet = true },
                        onUnfollow: {
                            onUnfollow()
                            onDismiss()
                        },
                        isArchived: isArchived,
                        onArchive: {
                            toggleArchive()
                        }
                    )

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
                            DetailSeasonPicker(show: show, selectedSeason: $selectedSeason)
                                .padding(.bottom, 16)

                            // Status card with countdown + lifecycle + clock
                            DetailStatusBlock(show: show, selectedSeason: selectedSeason)
                                .padding(.bottom, 16)
                        }

                        // MARK: - Tab Content
                        switch selectedTab {
                        case .seasonInfo:
                            SeasonInfoTabContent(
                                show: show,
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
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.startLocation.x < 50 && value.translation.width > 80 {
                        onDismiss()
                    }
                }
        )
        .task {
            await loadShowInfo()
        }
        .onAppear {
            loadArchiveState()
        }
    }

    // MARK: - Data Loading

    private func loadShowInfo() async {
        guard !isLoadingShowInfo else { return }
        isLoadingShowInfo = true

        do {
            let tmdbService = TMDBService()
            async let creditsResult = tmdbService.getShowCredits(id: show.id)
            async let videosResult = tmdbService.getShowVideos(id: show.id)

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
            isArchived = ids.contains(show.id)
        }
    }

    private func toggleArchive() {
        var ids = Set(UserDefaults.standard.array(forKey: archivedShowsKey) as? [Int] ?? [])

        if isArchived {
            // Unarchive - stay on page
            ids.remove(show.id)
            UserDefaults.standard.set(Array(ids), forKey: archivedShowsKey)
            isArchived = false
        } else {
            // Archive - dismiss and go back
            ids.insert(show.id)
            UserDefaults.standard.set(Array(ids), forKey: archivedShowsKey)
            isArchived = true
            onDismiss()
        }
    }
}

// MARK: - Season Info Tab Content

private struct SeasonInfoTabContent: View {
    let show: ShowData
    let selectedSeason: Int

    var body: some View {
        VStack(spacing: 0) {
            // Episode list
            DetailEpisodeSection(show: show, selectedSeason: selectedSeason)
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

