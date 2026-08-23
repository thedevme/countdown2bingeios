//
//  MyListLandscapeView.swift
//  Countdown2Binge
//
//  My List — three tabs over fully-released seasons (still-airing seasons live
//  on the Timeline):
//    • Ready    — one landscape card per show = the season you're on.
//    • Watched  — poster grid of shows you've finished seasons of.
//    • Archived — poster grid of shows you've set aside.
//  Archived shows are excluded from Ready/Watched. Bound to live SwiftData.
//

import SwiftUI
import SwiftData

struct MyListLandscapeView: View {
    @Query(sort: \Series.dateAdded, order: .reverse) private var allSeries: [Series]
    @Environment(SeriesManager.self) private var seriesManager
    @State private var tab: LandscapeListTab = .ready
    @State private var archive = MyListArchiveStore()
    @State private var navigationPath = NavigationPath()
    @State private var notificationSeries: Series?
    /// Show ids that currently have scheduled notifications — drives the bell
    /// glyph so it matches the modal's real "scheduled or not" status.
    @State private var scheduledShowIds: Set<Int> = []

    // MARK: - Ready tab (one card per show = the season you're on)

    private var readyItems: [(series: Series, display: MyListSeasonDisplay)] {
        allSeries
            .filter { $0.earliestUnwatchedSeason != nil && !archive.isArchived($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .compactMap { series in
                guard let season = series.earliestUnwatchedSeason else { return nil }
                let display = seasonDisplay(series, season,
                                            remainingSeasons: series.bingeableUnwatchedSeasonCount)
                return (series, display)
            }
    }

    private var readySeasonTotal: Int { readyItems.reduce(0) { $0 + max(1, $1.series.bingeableUnwatchedSeasonCount) } }
    private var readySecondsLeft: Int { readyItems.reduce(0) { $0 + $1.display.watchTimeSeconds } }

    // MARK: - Watched tab (shows with ≥1 fully-watched season)

    private var watchedShows: [WatchedShow] {
        allSeries
            .filter { !archive.isArchived($0.id) }
            .compactMap { series -> WatchedShow? in
                let done = series.visibleSeasons
                    .filter { $0.hasWatched }
                    .sorted { $0.seasonNumber > $1.seasonNumber }
                guard !done.isEmpty else { return nil }
                return makeGridShow(series, seasons: done)
            }
            .sorted { $0.seasonCount > $1.seasonCount }
    }

    // MARK: - Archived tab (shows set aside)

    private var archivedShows: [WatchedShow] {
        allSeries
            .filter { archive.isArchived($0.id) }
            .map { series in
                // Released seasons (complete or already watched), newest first.
                let released = series.visibleSeasons
                    .filter { $0.isBingeReadyByDate || $0.hasWatched }
                    .sorted { $0.seasonNumber > $1.seasonNumber }
                return makeGridShow(series, seasons: released)
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: - Builders

    private func makeGridShow(_ series: Series, seasons: [Season]) -> WatchedShow {
        WatchedShow(
            id: series.id,
            series: series,
            title: series.name,
            posterURL: series.posterURL,
            seasons: seasons.map { seasonDisplay(series, $0, remainingSeasons: 1) },
            episodeCount: seasons.reduce(0) { $0 + max($1.sortedEpisodes.count, $1.episodeCount) },
            watchTimeSeconds: seasons.reduce(0) { $0 + $1.watchTimeSeconds }
        )
    }

    /// Map any season → a card display, computing state from watch progress.
    private func seasonDisplay(_ series: Series, _ season: Season, remainingSeasons: Int) -> MyListSeasonDisplay {
        let epCount = season.sortedEpisodes.isEmpty ? season.episodeCount : season.sortedEpisodes.count
        let watched = season.watchedEpisodeCount
        let state: SeasonWatchState = season.hasWatched ? .done : (watched > 0 ? .watching : .ready)
        let note: String
        switch state {
        case .done: note = String(localized: "mylist_ls_note_all_watched")
        case .watching: note = String(format: NSLocalizedString("mylist_ls_note_watched %lld %lld", comment: ""), watched, max(epCount, 1))
        default: note = String(localized: "mylist_ls_note_ready")
        }
        let ticks = season.sortedEpisodes.map { ep in
            EpisodeTick(id: ep.id, number: ep.episodeNumber, watched: ep.hasWatched, aired: ep.hasAired)
        }
        return MyListSeasonDisplay(
            id: "\(series.id)-\(season.seasonNumber)",
            showTitle: series.name,
            backdropURL: series.backdropURL,
            seasonNumber: season.seasonNumber,
            episodeCount: epCount,
            watchedCount: season.hasWatched ? epCount : watched,
            releasedCount: max(season.episodes.filter { $0.hasAired }.count, watched),
            state: state,
            note: note,
            remainingSeasons: remainingSeasons,
            watchTimeSeconds: season.watchTimeSeconds,
            ticks: ticks
        )
    }

    private var shownCount: Int {
        switch tab {
        case .ready: return readyItems.count
        case .watched: return watchedShows.count
        case .archived: return archivedShows.count
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    content
                    Color.clear.frame(height: 150)
                }
            }
            .background(Color.c2bBackground)
            .navigationDestination(for: Series.self) { series in
                FollowedShowDetail(
                    series: series,
                    // Open on the season the My List card is on (the one you're
                    // catching up), falling back to the detail view's own default.
                    initialSeason: series.earliestUnwatchedSeason?.seasonNumber,
                    onDismiss: { navigationPath.removeLast() },
                    onUnfollow: { try? seriesManager.unfollow(id: series.id) }
                )
            }
        }
        .onAppear { archive.reload() }
        .task { await refreshScheduledStatus() }
        .overlay {
            if let series = notificationSeries {
                ShowNotificationSettingsOverlay(
                    series: series,
                    onDismiss: {
                        notificationSeries = nil
                        // Let the save's background reschedule land, then refresh
                        // the bells so their state matches what was just saved.
                        Task {
                            try? await Task.sleep(for: .milliseconds(500))
                            await refreshScheduledStatus()
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: notificationSeries)
    }

    private func refreshScheduledStatus() async {
        scheduledShowIds = await NotificationService.shared.scheduledShowIds()
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "mylist_ls_title").uppercased())
                .font(.custom(.oswald.bold, size: 27))
                .tracking(0.54)
                .foregroundColor(.white)

            Text(String(format: NSLocalizedString("mylist_ls_shown %lld", comment: ""), shownCount) + " · " + tab.label.uppercased())
                .font(.custom(.jetbrains.bold, size: 10.5))
                .tracking(0.95)
                .foregroundColor(.c2bMuted)
                .padding(.top, 8)

            Text(tab.desc)
                .font(.system(size: 14))
                .foregroundColor(.c2bDim)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            segmentedControl
                .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 52)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [Color.c2bBackground, Color.c2bBackground, Color.c2bBackground.opacity(0)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    private var segmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(LandscapeListTab.allCases) { item in
                let selected = item == tab
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { tab = item }
                } label: {
                    Text(item.label.uppercased())
                        .font(.custom(.jetbrains.bold, size: 11))
                        .tracking(0.6)
                        .foregroundColor(selected ? .c2bOnTeal : .c2bDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selected ? Color.c2bTeal : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .ready:
            if readyItems.isEmpty {
                emptyState.padding(.horizontal, 20).padding(.top, 40)
            } else {
                VStack(spacing: 18) {
                    MyListSeasonsStatsBar(
                        seasonCount: readySeasonTotal,
                        showCount: readyItems.count,
                        secondsLeft: readySecondsLeft
                    )
                    LazyVStack(spacing: 20) {
                        ForEach(readyItems, id: \.display.id) { entry in
                            MyListLandscapeCard(
                                season: entry.display,
                                onOpen: { navigationPath.append(entry.series) },
                                onMarkAll: {
                                    try? seriesManager.markAiredEpisodesWatched(
                                        seriesId: entry.series.id,
                                        seasonNumber: entry.display.seasonNumber
                                    )
                                },
                                onToggleEpisode: { tick in
                                    // Cumulative: tapping an unwatched episode marks
                                    // everything through it watched; tapping a watched
                                    // one rolls progress back to just before it.
                                    let through = tick.watched ? tick.number - 1 : tick.number
                                    try? seriesManager.setWatchedThrough(
                                        seriesId: entry.series.id,
                                        seasonNumber: entry.display.seasonNumber,
                                        episodeNumber: through
                                    )
                                },
                                notificationsOn: scheduledShowIds.contains(entry.series.id),
                                onBell: { notificationSeries = entry.series }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        case .watched:
            grid(watchedShows, variant: .watched)
        case .archived:
            grid(archivedShows, variant: .archived)
        }
    }

    @ViewBuilder
    private func grid(_ shows: [WatchedShow], variant: ShowGridVariant) -> some View {
        if shows.isEmpty {
            emptyState.padding(.horizontal, 20).padding(.top, 40)
        } else {
            MyListWatchedGrid(shows: shows, variant: variant) { series in
                navigationPath.append(series)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text(emptyTitle)
                .font(.custom(.oswald.medium, size: 18))
                .foregroundColor(.c2bDim)
            Text(emptySubtitle)
                .font(.system(size: 14))
                .foregroundColor(.c2bMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        )
    }

    private var emptyTitle: String {
        switch tab {
        case .ready: return String(localized: "mylist_ls_empty_ready_title")
        case .watched: return String(localized: "mylist_ls_empty_watched_title")
        case .archived: return String(localized: "mylist_ls_empty_archived_title")
        }
    }

    private var emptySubtitle: String {
        switch tab {
        case .ready: return String(localized: "mylist_ls_empty_ready_sub")
        case .watched: return String(localized: "mylist_ls_empty_watched_sub")
        case .archived: return String(localized: "mylist_ls_empty_archived_sub")
        }
    }
}
