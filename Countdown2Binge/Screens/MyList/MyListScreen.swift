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

enum MyListTab: String, CaseIterable {
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
    @State private var viewModel = MyListViewModel()
    @StateObject private var watchProgress = WatchProgressManager.shared

    @State private var selectedTab: MyListTab = .active
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
                                    watchProgress: watchProgress,
                                    onTap: { show in navigationPath.append(show) }
                                )
                            case .archived:
                                MyListPosterGrid(
                                    shows: shows,
                                    variant: .archived,
                                    watchProgress: watchProgress,
                                    onTap: { show in navigationPath.append(show) }
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
                viewModel.configure(with: modelContext, container: modelContext.container)
                viewModel.reloadArchivedShowIds()
                Task { await viewModel.loadShows() }
            }
            .navigationDestination(for: ShowData.self) { show in
                FollowedShowDetail(
                    show: show,
                    onDismiss: { navigationPath.removeLast() },
                    onUnfollow: {
                        Task { await viewModel.unfollowShow(show) }
                    }
                )
                .navigationBarHidden(true)
            }
        }
    }

    // MARK: - Active Tab Content

    @ViewBuilder
    private var activeTabContent: some View {
        let bingeReady = viewModel.bingeReadyShows
        let countingDown = viewModel.countingDownShows
        let noDate = viewModel.noDateShows

        VStack(spacing: 30) {
            // Ready to Binge section
            if !bingeReady.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    MyListSectionHeader(
                        icon: "checkmark",
                        iconColor: Color(hex: "#04201c"),
                        tint: .c2bTeal,
                        title: String(localized: "mylist_section_ready"),
                        subtitle: String(localized: "mylist_section_ready_sub \(bingeReady.count)")
                    )

                    MyListPosterGrid(
                        shows: bingeReady,
                        variant: .justDone,
                        watchProgress: watchProgress,
                        onTap: { show in navigationPath.append(show) }
                    )
                }
            }

            // Still Counting Down section
            if !countingDown.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    MyListSectionHeader(
                        icon: "clock",
                        iconColor: Color(hex: "#e5e5e5"),
                        tint: Color(hex: "#3f3f46"),
                        title: String(localized: "mylist_section_counting"),
                        subtitle: String(localized: "mylist_section_counting_sub \(countingDown.count)")
                    )

                    MyListPosterGrid(
                        shows: countingDown,
                        variant: .active,
                        watchProgress: watchProgress,
                        onTap: { show in navigationPath.append(show) }
                    )
                }
            }

            // No Date Yet section
            if !noDate.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    MyListSectionHeader(
                        icon: "questionmark",
                        iconColor: Color(hex: "#a1a1aa"),
                        tint: Color(hex: "#27272a"),
                        title: String(localized: "mylist_section_nodate"),
                        subtitle: String(localized: "mylist_section_nodate_sub \(noDate.count)")
                    )

                    MyListPosterGrid(
                        shows: noDate,
                        variant: .noDate,
                        watchProgress: watchProgress,
                        onTap: { show in navigationPath.append(show) }
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

    private let archivedShowsKey = "archivedShowIds"

    init() {
        reloadArchivedShowIds()
    }

    func configure(with modelContext: ModelContext, container: ModelContainer? = nil) {
        self.modelContext = modelContext
        self.modelContainer = container
        self.store = FollowedShowsStore(modelContext: modelContext)
    }

    func loadShows() async {
        guard let store else { return }
        isLoading = true
        do {
            followedShows = try await store.getAllFollowedAsShowData()
        } catch {
            print("Error loading followed shows: \(error)")
            followedShows = []
        }
        isLoading = false
    }

    func refreshShows() async {
        guard let modelContainer, let store else { return }
        let refreshService = StateRefreshService(modelContainer: modelContainer)
        await refreshService.forceRefreshAllShows()
        do {
            followedShows = try await store.getAllFollowedAsShowData()
        } catch {
            print("Error reloading shows: \(error)")
        }
    }

    func unfollowShow(_ show: ShowData) async {
        guard let store else { return }
        do {
            try store.unfollow(tmdbId: show.id)
            followedShows = try await store.getAllFollowedAsShowData()
            Task { await CloudSyncService.shared.removeShow(tmdbId: show.id) }
        } catch {
            print("Error unfollowing show: \(error)")
            followedShows.removeAll { $0.id == show.id }
        }
    }

    // MARK: - Tab Filtering

    func shows(for tab: MyListTab) -> [ShowData] {
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

    /// Binge Ready - shows where the season has completed and is ready to watch
    /// Excludes shows that qualify for No Date Yet (user finished watching + no next date)
    var bingeReadyShows: [ShowData] {
        let noDateIds = Set(noDateShows.map { $0.id })
        return shows(for: .active).filter { show in
            show.timelineCategory == .bingeReady && !noDateIds.contains(show.id)
        }
    }

    /// Still Counting Down - shows that are airing or premiering soon
    var countingDownShows: [ShowData] {
        return shows(for: .active).filter { show in
            show.timelineCategory == .airingNow || show.timelineCategory == .premieringSoon
        }
    }

    /// No Date Yet - shows in anticipated state with no premiere date
    /// Either: (1) followed while already in TBD state, or (2) user watched all episodes of current season
    var noDateShows: [ShowData] {
        let watchProgress = WatchProgressManager.shared
        return shows(for: .active).filter { show in
            // Must have an anticipated season with no premiere date
            guard let anticipated = show.anticipatedSeason,
                  anticipated.premiereDate == nil else {
                return false
            }

            // If show is already in anticipated state (followed after season ended),
            // it goes directly to No Date Yet without requiring watch progress
            if show.timelineCategory == .anticipated {
                return true
            }

            // Otherwise, user must have watched all episodes of the current season
            // to "graduate" from Binge Ready to No Date Yet
            guard let currentSeason = show.currentSeason else {
                return false
            }

            let watchedCount = watchProgress.seasonWatchedCount(
                showId: show.id,
                season: currentSeason.seasonNumber,
                episodeCount: currentSeason.episodeCount
            )

            return watchedCount == currentSeason.episodeCount && currentSeason.episodeCount > 0
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
