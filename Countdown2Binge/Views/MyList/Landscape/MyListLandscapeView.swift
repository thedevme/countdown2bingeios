//
//  MyListLandscapeView.swift
//  Countdown2Binge
//
//  My List — fully-released seasons, one landscape card per show = the
//  season you're on (still-airing seasons live on the Timeline). Grouped
//  into MyListVerdictEngine shelf tiers, or a "Next"/"Upcoming" split in
//  Straight Through — exactly "My List Cards.html": title, stat line, the
//  Jump around/Straight through `.bar`, then sections. No separate
//  Watched/Archived tabs — that switcher isn't part of this design.
//  Archived shows are still excluded from the list. Bound to live SwiftData.
//

import SwiftUI
import SwiftData

struct MyListLandscapeView: View {
    @Query(sort: \Series.dateAdded, order: .reverse) private var allSeries: [Series]
    @Environment(SeriesManager.self) private var seriesManager
    @Environment(\.modelContext) private var modelContext
    @State private var archive = MyListArchiveStore()
    @State private var navigationPath = NavigationPath()
    @State private var notificationSeries: Series?
    @State private var cloudSettings = CloudSettingsStore.shared
    @State private var preferences = MyListPreferencesStore.shared
    @State private var watchOrder = WatchOrderStore.shared
    @State private var showWatchOrderSheet = false
    /// Show ids that currently have scheduled notifications — drives the bell
    /// glyph so it matches the modal's real "scheduled or not" status.
    @State private var scheduledShowIds: Set<Int> = []

    // MARK: - Ready items (one card per show = the season you're on)

    private var readyItems: [(series: Series, season: Season, display: MyListSeasonDisplay)] {
        allSeries
            // Stays until the WHOLE series is watched — not just the
            // current/next season. `firstUnwatchedSeason` is what the
            // card opens to; combined with `!isFullyWatched` it can never
            // be nil for an item that actually belongs in this list.
            .filter { !$0.isFullyWatched && !archive.isArchived($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .compactMap { series in
                guard let season = series.firstUnwatchedSeason else { return nil }
                let display = seasonDisplay(series, season,
                                            remainingSeasons: series.totalUnwatchedSeasonCount)
                return (series, season, display)
            }
    }

    private var readySecondsLeft: Int { readyVerdicts.reduce(0) { $0 + $1.display.watchTimeSeconds } }

    /// Every item paired with its MyListVerdictEngine output — the SAME
    /// engine the onboarding preview uses, so this screen can never disagree
    /// with what onboarding promised. `display.watchTimeSeconds` is
    /// overridden to the WHOLE SERIES' remaining time — every unwatched
    /// episode in every season, not just the one season this card is
    /// currently pointed at. This is unconditional: Jump Around vs
    /// Straight Through does not change it.
    private var readyVerdicts: [(series: Series, display: MyListSeasonDisplay, verdict: MyListVerdict)] {
        let answers = preferences.answers
        return readyItems.map { entry in
            let epCount = max(1, entry.display.episodeCount)
            let avgEpisodeSeconds = max(1, entry.display.watchTimeSeconds / epCount)
            let remaining = entry.series.totalRemainingWatchTimeSeconds
            let liveVerdict = MyListVerdictEngine.evaluate(
                remainingSeconds: remaining, answers: answers, avgEpisodeSeconds: avgEpisodeSeconds
            )
            var display = entry.display
            display.watchTimeSeconds = remaining

            // Shelf tier is pinned the first time this season is seen —
            // otherwise it's pure live math off remaining time, so
            // watching an episode shrinks that number and can silently
            // move the card to a different section mid-binge. Once
            // pinned, it keeps that tier no matter how remaining time
            // moves afterward; a season that finishes and hands off to
            // the next one starts that next season's tier fresh. A pin
            // only counts if it was computed under the CURRENT shelf-tier
            // formula — one from an older version (e.g. the old
            // session-based formula) is stale and gets recomputed here,
            // instead of staying stuck on a category that formula no
            // longer produces.
            let pinIsCurrent = entry.season.pinnedShelfTierVersion == MyListVerdictEngine.currentShelfTierVersion
            let verdict: MyListVerdict
            if pinIsCurrent, let pinnedRaw = entry.season.pinnedShelfTierRaw, let pinned = MyListShelfTier(rawValue: pinnedRaw) {
                verdict = MyListVerdict(
                    verdictText: liveVerdict.verdictText,
                    paceText: liveVerdict.paceText,
                    shelfTier: pinned,
                    rawHoursText: liveVerdict.rawHoursText,
                    shelfDateSuffix: liveVerdict.shelfDateSuffix
                )
            } else {
                verdict = liveVerdict
                // Deferred to the next runloop tick — writing to the
                // SwiftData model directly inside a computed property
                // that's evaluated as part of rendering `body` risks a
                // "modifying state during view update" cycle.
                let seasonRef = entry.season
                let tierRaw = liveVerdict.shelfTier.rawValue
                let version = MyListVerdictEngine.currentShelfTierVersion
                DispatchQueue.main.async {
                    guard seasonRef.pinnedShelfTierVersion != version else { return }
                    seasonRef.pinnedShelfTierRaw = tierRaw
                    seasonRef.pinnedShelfTierVersion = version
                    try? modelContext.save()
                }
            }

            return (series: entry.series, display: display, verdict: verdict)
        }
    }

    /// "Most recently watched" for Straight Through's hero — latest episode
    /// watch anywhere in the show, falling back to when it was followed for
    /// a show that hasn't been started yet.
    private func mostRecentActivity(_ series: Series) -> Date {
        series.seasons.flatMap(\.episodes).compactMap(\.watchedAt).max() ?? series.dateAdded
    }

    // MARK: - Builders

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
            watchTimeSeconds: season.remainingWatchTimeSeconds,
            ticks: ticks,
            network: series.networks.first?.name.uppercased(),
            nextEpisodeTitle: season.sortedEpisodes.first { !$0.hasWatched }?.name
        )
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
                    initialSeason: series.firstUnwatchedSeason?.seasonNumber,
                    onDismiss: { navigationPath.removeLast() },
                    onUnfollow: {
                        // Same detail screen as the timeline's — wait for the
                        // iCloud delete rather than firing and hoping.
                        let id = series.id
                        Task { try? await seriesManager.unfollowAwaitingCloud(id: id) }
                    }
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
        // Center overlay, not a sheet or full-screen cover — shown once, the
        // first time this screen is seen. Intro and all three questions page
        // inside this one card; it doesn't come back on its own once done.
        .overlay {
            if !cloudSettings.hasSeenMyListOnboarding {
                MyListOnboardingContainer {
                    cloudSettings.hasSeenMyListOnboarding = true
                }
                .transition(.opacity)
                .zIndex(200)
            }
        }
    }

    private func refreshScheduledStatus() async {
        scheduledShowIds = await NotificationService.shared.scheduledShowIds()
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(String(localized: "mylist_ls_title").uppercased())
                    .font(.custom(.oswald.bold, size: 27))
                    .tracking(0.54)
                    .foregroundColor(.white)

                Spacer()

                // Jump around/Straight through is now set once during My
                // List's own onboarding, not switched live from a bar
                // here — this re-opens that onboarding to change it.
                Button(action: { cloudSettings.hasSeenMyListOnboarding = false }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Redo Onboarding"))
            }

            // "N shows · 7h:05m:00s left · current season" — one line,
            // exactly "My List Cards.html"'s `.sub`, not a separate
            // stats-bar component.
            readyStatLine
                .padding(.top, 8)
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

    /// "N shows · 7h:05m:00s left · current season" — matches
    /// "My List Cards.html"'s `.sub` line exactly, including the h:m:s clock
    /// format (not the rounded "7h 05m" used elsewhere on cards).
    private var readyStatLine: Text {
        let secs = readySecondsLeft
        let h = secs / 3600, m = (secs % 3600) / 60, s = secs % 60
        let clock = String(format: "%dh:%02dm:%02ds", h, m, s)
        let scopeText = preferences.answers.scope == .straightThrough
            ? "all remaining seasons" : "current season"

        return Text(plural(readyItems.count, "show", "shows") + " · ")
            .font(.custom(.jetbrains.regular, size: 10.5))
            .foregroundColor(.c2bMuted)
        + Text(clock)
            .font(.custom(.jetbrains.bold, size: 10.5))
            .foregroundColor(.c2bTealBright)
        + Text(" left · " + scopeText)
            .font(.custom(.jetbrains.regular, size: 10.5))
            .foregroundColor(.c2bMuted)
    }

    private func plural(_ n: Int, _ one: String, _ many: String) -> String {
        "\(n) \(n == 1 ? one : many)"
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if readyItems.isEmpty {
            emptyState.padding(.horizontal, 20).padding(.top, 40)
        } else {
            VStack(spacing: 16) {
                switch preferences.answers.scope {
                case .straightThrough:
                    straightThroughReady
                case .jumpAround:
                    jumpAroundReady
                }
            }
            .padding(.top, 4)
        }
    }

    /// Jump around — every show grouped into a MyListVerdictEngine shelf,
    /// each its own tinted/bordered `.sec` card (icon + title + why + count)
    /// with its own horizontal paginated rail — exactly `sectionsFor()` /
    /// `listView()` in "My List Cards.html", which never drops the section
    /// chrome even when only one tier ends up populated.
    @ViewBuilder
    private var jumpAroundReady: some View {
        let byTier = Dictionary(grouping: readyVerdicts, by: { $0.verdict.shelfTier })
        let populatedTiers = MyListShelfTier.allCases.filter { !(byTier[$0]?.isEmpty ?? true) }

        VStack(spacing: 16) {
            ForEach(populatedTiers) { tier in
                let entries = byTier[tier] ?? []
                MyListResultsShelfSection(
                    tier: tier,
                    items: entries.map(\.display),
                    onOpen: { openReady(display: $0) },
                    onMarkAll: { markAllReady(display: $0) },
                    onToggleEpisode: { toggleEpisodeReady(display: $0, tick: $1) },
                    notificationsOn: { notificationsOn(display: $0) },
                    onBell: { onBellReady(display: $0) }
                )
            }
        }
        .padding(.horizontal, 12)
    }

    /// Straight through — a "Next" section holding exactly the most
    /// recently watched show (full-width, no dots — the design's "solo"
    /// rail), and an "Upcoming" section for the rest, shortest first.
    /// Next-only when it's the only show — no Upcoming section at all.
    @ViewBuilder
    private var straightThroughReady: some View {
        let sorted = readyVerdicts.sorted { mostRecentActivity($0.series) > mostRecentActivity($1.series) }
        VStack(spacing: 16) {
            if let hero = sorted.first {
                MyListResultsShelfSection(
                    tier: .oneSitting, items: [hero.display],
                    labelOverride: "Next", whyOverride: "The one you're closest to finishing",
                    iconOverride: "next_v1", toneOverride: Color(hex: "#86E7D5"),
                    onOpen: { openReady(display: $0) },
                    onMarkAll: { markAllReady(display: $0) },
                    onToggleEpisode: { toggleEpisodeReady(display: $0, tick: $1) },
                    notificationsOn: { notificationsOn(display: $0) },
                    onBell: { onBellReady(display: $0) }
                )
            }

            let upcomingEntries = watchOrder.apply(to: Array(sorted.dropFirst()), id: { $0.series.id })
            let upcoming = upcomingEntries.map(\.display)
            if !upcoming.isEmpty {
                MyListResultsShelfSection(
                    tier: .month, items: upcoming,
                    labelOverride: "Upcoming",
                    whyOverride: watchOrder.customOrder != nil ? "Your order" : "Queued behind it, shortest first",
                    iconOverride: "upcoming_v1", toneOverride: Color(hex: "#A38CF3"),
                    isEditable: true,
                    onEdit: { showWatchOrderSheet = true },
                    // Checking off an episode updates the show's most-
                    // recent-activity timestamp — exactly what promotes it
                    // to "Next," so the card being tapped would jump to a
                    // different section mid-interaction. Confirmed: this is
                    // what read as "the tick doesn't show / episodes cycle
                    // wrong" — it was really the whole section reshuffling
                    // under the tap, not a data bug.
                    showsNextEpisodeCheckoff: false,
                    onOpen: { openReady(display: $0) },
                    onMarkAll: { markAllReady(display: $0) },
                    onToggleEpisode: { toggleEpisodeReady(display: $0, tick: $1) },
                    notificationsOn: { notificationsOn(display: $0) },
                    onBell: { onBellReady(display: $0) }
                )
                .sheet(isPresented: $showWatchOrderSheet) {
                    WatchOrderSheet(
                        items: upcomingEntries.map {
                            (id: $0.series.id, posterURL: $0.series.posterURL,
                             title: $0.series.name, secondsLeft: $0.display.watchTimeSeconds)
                        },
                        tone: Color(hex: "#A38CF3")
                    )
                    .presentationDetents([.large])
                    .presentationCornerRadius(24)
                    .presentationDragIndicator(.hidden)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func readySeries(for display: MyListSeasonDisplay) -> Series? {
        readyVerdicts.first { $0.display.id == display.id }?.series
    }

    private func openReady(display: MyListSeasonDisplay) {
        guard let series = readySeries(for: display) else { return }
        navigationPath.append(series)
    }

    private func markAllReady(display: MyListSeasonDisplay) {
        guard let series = readySeries(for: display) else { return }
        try? seriesManager.markAiredEpisodesWatched(seriesId: series.id, seasonNumber: display.seasonNumber)
    }

    private func toggleEpisodeReady(display: MyListSeasonDisplay, tick: EpisodeTick) {
        guard let series = readySeries(for: display) else { return }
        // Cumulative: tapping an unwatched episode marks everything through
        // it watched; tapping a watched one rolls progress back to just
        // before it.
        let through = tick.watched ? tick.number - 1 : tick.number
        try? seriesManager.setWatchedThrough(seriesId: series.id, seasonNumber: display.seasonNumber, episodeNumber: through)
    }

    private func notificationsOn(display: MyListSeasonDisplay) -> Bool {
        guard let series = readySeries(for: display) else { return true }
        return scheduledShowIds.contains(series.id)
    }

    private func onBellReady(display: MyListSeasonDisplay) {
        notificationSeries = readySeries(for: display)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text(String(localized: "mylist_ls_empty_ready_title"))
                .font(.custom(.oswald.medium, size: 18))
                .foregroundColor(.c2bDim)
            Text(String(localized: "mylist_ls_empty_ready_sub"))
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
}
