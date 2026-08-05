//
//  MyListScreen.swift
//  Countdown2Binge
//
//  My List tab with Active, Ended, and Archived segments.
//  Shows a 3-column poster grid with different visual treatments per state.
//

import SwiftUI
import SwiftData

// MARK: - My List Tab

enum ListTabScreen: String, CaseIterable {
    case active
    case ended
    case archived

    var label: String {
        switch self {
        case .active: return String(localized: "mylist_tab_active")
        case .ended: return String(localized: "mylist_tab_ended")
        case .archived: return String(localized: "mylist_tab_archived")
        }
    }

    var description: String {
        switch self {
        case .active: return String(localized: "mylist_desc_active")
        case .ended: return String(localized: "mylist_desc_ended")
        case .archived: return String(localized: "mylist_desc_archived")
        }
    }
}

// MARK: - My List Screen

struct MyListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SeriesManager.self) private var seriesManager
    @State private var viewModel = MyListViewModel()

    @State private var selectedTab: ListTabScreen = .active
    @State private var navigationPath = NavigationPath()

    private var shows: [ShowData] {
        viewModel.shows(for: selectedTab)
    }

    private var count: Int {
        shows.count
    }

    private var activeCount: Int {
        viewModel.shows(for: .active).count
    }

    private var endedCount: Int {
        viewModel.shows(for: .ended).count
    }

    private var archivedCount: Int {
        viewModel.shows(for: .archived).count
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    // Sticky Header
                    VStack(alignment: .leading, spacing: 0) {
                        // Title
                        Text("mylist_title")
                            .font(.custom(.oswald.bold, size: 27))
                            .tracking(0.54)
                            .foregroundColor(.white)

                        // Count + Tab
                        Text(String(localized: "mylist_count \(count) \(selectedTab.label.lowercased())"))
                            .font(.custom(.jetbrains.bold, size: 9.5))
                            .tracking(1.14)
                            .foregroundColor(.c2bMuted)
                            .textCase(.uppercase)
                            .padding(.top, 8)

                        // Description
                        Text(selectedTab.description)
                            .font(.system(size: 12.5))
                            .foregroundColor(.c2bDim)
                            .lineSpacing(3)
                            .padding(.top, 12)

                        // Segmented Control
                        MyListSegmentedControl(
                            selectedTab: $selectedTab,
                            activeCount: activeCount,
                            endedCount: endedCount,
                            archivedCount: archivedCount
                        )
                        .padding(.top, 14)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 52)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.c2bBackground, Color.c2bBackground, Color.c2bBackground.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Content
                    if shows.isEmpty {
                        MyListEmptyState(tab: selectedTab)
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 0) {
                            switch selectedTab {
                            case .active:
                                activeTabContent
                            case .ended:
                                MyListPosterGrid(
                                    shows: shows,
                                    variant: .ended,
                                    onTap: { show in
                                        if let series = viewModel.getSeries(for: show.id) {
                                            navigationPath.append(series)
                                        }
                                    }
                                )
                            case .archived:
                                MyListPosterGrid(
                                    shows: shows,
                                    variant: .archived,
                                    onTap: { show in
                                        if let series = viewModel.getSeries(for: show.id) {
                                            navigationPath.append(series)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }

                    Spacer()
                        .frame(height: 150)
                }
            }
            .background(Color.c2bBackground)
            .refreshable {
                await viewModel.refreshShows()
            }
            .onAppear {
                viewModel.configure(with: modelContext, container: modelContext.container, seriesManager: seriesManager)
                viewModel.reloadArchivedShowIds()
                Task { await viewModel.loadShows() }
            }
            .navigationDestination(for: Series.self) { series in
                FollowedShowDetail(
                    series: series,
                    onDismiss: { navigationPath.removeLast() },
                    onUnfollow: {
                        Task { await viewModel.unfollowShow(series) }
                    }
                )
            }
        }
    }

    // MARK: - Active Tab Content

    @ViewBuilder
    private var activeTabContent: some View {
        VStack(spacing: 24) {
            // Ready to Binge Section
            if !viewModel.bingeReadyShows.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    MyListSectionHeader(
                        iconAsset: "ml-ready",
                        title: "BINGE READY",
                        subtitle: "\(viewModel.bingeReadyShows.count) SEASONS READY TO WATCH",
                        tint: .c2bTeal
                    )

                    MyListPosterGrid(
                        shows: viewModel.bingeReadyShows,
                        variant: .justDone,
                        onTap: { show in
                            if let series = viewModel.getSeries(for: show.id) {
                                navigationPath.append(series)
                            }
                        },
                        bingeReadyInfoLookup: { showId in
                            viewModel.getBingeReadyInfo(for: showId)
                        }
                    )
                }
            }

            // Still Counting Down Section
            if !viewModel.countingDownShows.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    MyListSectionHeader(
                        iconAsset: "ml-counting",
                        title: "STILL COUNTING DOWN",
                        subtitle: "\(viewModel.countingDownShows.count) SEASONS IN PROGRESS",
                        tint: .c2bMuted
                    )

                    MyListPosterGrid(
                        shows: viewModel.countingDownShows,
                        variant: .active,
                        onTap: { show in
                            if let series = viewModel.getSeries(for: show.id) {
                                navigationPath.append(series)
                            }
                        }
                    )
                }
            }

            // No Date Yet Section
            if !viewModel.noDateShows.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    MyListSectionHeader(
                        iconAsset: "ml-nodate",
                        title: "NO DATE YET",
                        subtitle: "\(viewModel.noDateShows.count) SEASONS AWAITING A RELEASE DATE",
                        tint: .c2bMuted
                    )

                    MyListPosterGrid(
                        shows: viewModel.noDateShows,
                        variant: .active,
                        onTap: { show in
                            if let series = viewModel.getSeries(for: show.id) {
                                navigationPath.append(series)
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
@Observable
final class MyListViewModel {
    private(set) var followedShows: [ShowData] = []
    private(set) var isLoading = false
    private(set) var archivedShowIds: Set<Int> = []

    private var modelContext: ModelContext?
    private var modelContainer: ModelContainer?
    private var store: FollowedShowsStore?
    private var seriesManager: SeriesManager?

    private let archivedShowsKey = "archivedShowIds"

    init() {
        reloadArchivedShowIds()
    }

    func configure(with modelContext: ModelContext, container: ModelContainer? = nil, seriesManager: SeriesManager? = nil) {
        self.modelContext = modelContext
        self.modelContainer = container
        self.store = FollowedShowsStore(modelContext: modelContext)
        self.seriesManager = seriesManager
    }

    func loadShows() async {
        guard let seriesManager else { return }
        isLoading = true
        // Clean up any duplicate Series entries first
        try? seriesManager.cleanupDuplicates()
        // Load from SeriesManager (the new engine) and convert to ShowData
        followedShows = seriesManager.allSeries().map { $0.toShowData() }
        isLoading = false
    }

    func refreshShows() async {
        guard let seriesManager else { return }
        await seriesManager.refreshAll(force: true)
        // Reload from SeriesManager after refresh
        followedShows = seriesManager.allSeries().map { $0.toShowData() }
    }

    func unfollowShow(_ series: Series) async {
        guard let seriesManager else { return }
        do {
            try seriesManager.unfollow(id: series.id)
            followedShows.removeAll { $0.id == series.id }
        } catch {
            print("Error unfollowing show: \(error)")
        }
    }

    func getSeries(for showId: Int) -> Series? {
        seriesManager?.series(id: showId)
    }

    /// Get binge-ready season info for a show (the unwatched complete season)
    func getBingeReadyInfo(for showId: Int) -> BingeReadyInfo? {
        guard let series = seriesManager?.series(id: showId),
              let season = series.bingeReadySeason else { return nil }
        return BingeReadyInfo(seasonNumber: season.seasonNumber, finaleDate: season.finaleDate)
    }

    // MARK: - Tab Filtering

    func shows(for tab: ListTabScreen) -> [ShowData] {
        switch tab {
        case .active:
            return followedShows.filter { show in
                show.lifecycleState != .ended && !archivedShowIds.contains(show.id)
            }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .ended:
            return followedShows.filter { show in
                show.lifecycleState == .ended && !archivedShowIds.contains(show.id)
            }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .archived:
            return followedShows.filter { show in
                archivedShowIds.contains(show.id)
            }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    /// Binge Ready - shows that have ANY unwatched complete season
    /// A show can be airing Season 3 but still appear here if Season 2 is unwatched
    var bingeReadyShows: [ShowData] {
        return shows(for: .active).filter { show in
            // Check via Series model if there's an unwatched binge-ready season
            guard let series = seriesManager?.series(id: show.id) else {
                // Fallback to ShowData's timelineCategory for shows not in SwiftData
                return show.timelineCategory == .bingeReady
            }
            // Has any unwatched complete season?
            return series.bingeReadySeason != nil
        }
    }

    /// Still Counting Down - shows that are airing or premiering soon
    /// AND don't have an unwatched complete season (those go to Binge Ready)
    var countingDownShows: [ShowData] {
        let bingeReadyIds = Set(bingeReadyShows.map { $0.id })
        return shows(for: .active).filter { show in
            // Must be airing or premiering
            let isCountingDown = show.timelineCategory == .airingNow || show.timelineCategory == .premieringSoon
            // But NOT if they have unwatched seasons (those are in Binge Ready)
            return isCountingDown && !bingeReadyIds.contains(show.id)
        }
    }

    /// No Date Yet - shows in anticipated state with no premiere date
    /// AND don't have an unwatched complete season (those go to Binge Ready)
    var noDateShows: [ShowData] {
        let bingeReadyIds = Set(bingeReadyShows.map { $0.id })
        return shows(for: .active).filter { show in
            // Must be anticipated
            guard show.timelineCategory == .anticipated else {
                return false
            }
            // But NOT if they have unwatched seasons (those are in Binge Ready)
            return !bingeReadyIds.contains(show.id)
        }
    }

    // MARK: - Archive Management

    func isArchived(_ showId: Int) -> Bool {
        archivedShowIds.contains(showId)
    }

    func archiveShow(_ showId: Int) {
        archivedShowIds.insert(showId)
        saveArchivedShowIds()
    }

    func unarchiveShow(_ showId: Int) {
        archivedShowIds.remove(showId)
        saveArchivedShowIds()
    }

    func reloadArchivedShowIds() {
        if let ids = UserDefaults.standard.array(forKey: archivedShowsKey) as? [Int] {
            archivedShowIds = Set(ids)
        }
    }

    private func saveArchivedShowIds() {
        UserDefaults.standard.set(Array(archivedShowIds), forKey: archivedShowsKey)
    }
}
