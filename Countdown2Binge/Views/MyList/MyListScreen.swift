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
    @Query(sort: \Series.dateAdded, order: .reverse) private var allSeries: [Series]
    @Environment(\.modelContext) private var modelContext
    @Environment(SeriesManager.self) private var seriesManager
    @State private var viewModel = MyListViewModel()

    @State private var selectedTab: ListTabScreen = .active
    @State private var navigationPath = NavigationPath()

    // MARK: - Computed Series Arrays (filtered by BingeEngine state)

    /// Active tab: shows that are NOT ended and NOT archived
    private var activeSeries: [Series] {
        allSeries.filter { series in
            series.myListTab == .active && !viewModel.archivedShowIds.contains(series.id)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Ended tab: shows that have ended/canceled and NOT archived
    private var endedSeries: [Series] {
        allSeries.filter { series in
            series.myListTab == .ended && !viewModel.archivedShowIds.contains(series.id)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Archived tab: manually archived shows
    private var archivedSeries: [Series] {
        allSeries.filter { series in
            viewModel.archivedShowIds.contains(series.id)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Shows for the selected tab
    private var currentTabSeries: [Series] {
        switch selectedTab {
        case .active: return activeSeries
        case .ended: return endedSeries
        case .archived: return archivedSeries
        }
    }

    private var count: Int { currentTabSeries.count }
    private var activeCount: Int { activeSeries.count }
    private var endedCount: Int { endedSeries.count }
    private var archivedCount: Int { archivedSeries.count }

    // MARK: - Active Tab Sub-sections

    /// Binge Ready: shows with an unwatched complete season
    private var bingeReadySeries: [Series] {
        activeSeries.filter { $0.bingeReadySeason != nil }
    }

    /// Still Counting Down: airing or premiering, no unwatched complete season
    private var countingDownSeries: [Series] {
        let bingeReadyIds = Set(bingeReadySeries.map { $0.id })
        return activeSeries.filter { series in
            let isCountingDown = series.showState == .airing || series.showState == .premieringSoon || series.showState == .pending
            return isCountingDown && !bingeReadyIds.contains(series.id)
        }
    }

    /// No Date Yet: anticipated shows without binge-ready seasons
    private var noDateSeries: [Series] {
        let bingeReadyIds = Set(bingeReadySeries.map { $0.id })
        return activeSeries.filter { series in
            series.showState == .anticipated && !bingeReadyIds.contains(series.id)
        }
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
                    if currentTabSeries.isEmpty {
                        MyListEmptyState(tab: selectedTab)
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 0) {
                            switch selectedTab {
                            case .active:
                                activeTabContent
                            case .ended:
                                SeriesPosterGrid(
                                    seriesList: endedSeries,
                                    variant: .ended,
                                    onTap: { series in
                                        navigationPath.append(series)
                                    }
                                )
                            case .archived:
                                SeriesPosterGrid(
                                    seriesList: archivedSeries,
                                    variant: .archived,
                                    onTap: { series in
                                        navigationPath.append(series)
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
                await seriesManager.refreshAll(force: true)
            }
            .onAppear {
                viewModel.reloadArchivedShowIds()
            }
            .navigationDestination(for: Series.self) { series in
                FollowedShowDetail(
                    series: series,
                    onDismiss: { navigationPath.removeLast() },
                    onUnfollow: {
                        try? seriesManager.unfollow(id: series.id)
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
            if !bingeReadySeries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    MyListSectionHeader(
                        iconAsset: "ml-ready",
                        title: "BINGE READY",
                        subtitle: "\(bingeReadySeries.count) SEASONS READY TO WATCH",
                        tint: .c2bTeal
                    )

                    SeriesPosterGrid(
                        seriesList: bingeReadySeries,
                        variant: .justDone,
                        onTap: { series in
                            navigationPath.append(series)
                        }
                    )
                }
            }

            // Still Counting Down Section
            if !countingDownSeries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    MyListSectionHeader(
                        iconAsset: "ml-counting",
                        title: "STILL COUNTING DOWN",
                        subtitle: "\(countingDownSeries.count) SEASONS IN PROGRESS",
                        tint: .c2bMuted
                    )

                    SeriesPosterGrid(
                        seriesList: countingDownSeries,
                        variant: .active,
                        onTap: { series in
                            navigationPath.append(series)
                        }
                    )
                }
            }

            // No Date Yet Section
            if !noDateSeries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    MyListSectionHeader(
                        iconAsset: "ml-nodate",
                        title: "NO DATE YET",
                        subtitle: "\(noDateSeries.count) SEASONS AWAITING A RELEASE DATE",
                        tint: .c2bMuted
                    )

                    SeriesPosterGrid(
                        seriesList: noDateSeries,
                        variant: .noDate,
                        onTap: { series in
                            navigationPath.append(series)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - View Model (Archive Management Only)

@MainActor
@Observable
final class MyListViewModel {
    private(set) var archivedShowIds: Set<Int> = []
    private let archivedShowsKey = "archivedShowIds"

    init() {
        reloadArchivedShowIds()
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
