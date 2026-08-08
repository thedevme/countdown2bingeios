//
//  SeriesManager.swift
//  Countdown2Binge
//
//  THE SINGLE WRITE FUNNEL for followed shows.
//
//  Every operation that creates, deletes, mutates, refreshes, or resolves a
//  followed show goes through this class. Views, view models, and use cases
//  CALL SeriesManager — they never touch the ModelContext for shows directly.
//  This is what makes "added once, not managed in six places" structurally
//  true and kills the drift bugs.
//
//  Responsibilities:
//   • follow(showData:)      — the ONLY place a Series is created
//   • unfollow(id:)          — the ONLY deletion path
//   • refresh(id:) / refreshAll() — the ONLY place TMDB sync writes a Series
//   • markSeasonWatched / markEpisodeWatched — watch-state mutations
//   • setAddTimeWatched(...) — the add-time "did you watch S_n?" answer
//   • archive/unarchive      — the user-axis flag
//   • resolveSpinoffs(...)   — Firebase franchise lookup, ONCE, stored
//
//  Reads (lifecycle state, binge-ready surface, timeline) come off the Series
//  computed properties, which delegate to BingeEngine. This class does writes.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class SeriesManager {

    /// The container, kept alive for background Tasks that need their own context.
    private let container: ModelContainer

    /// Main context for synchronous operations. Background Tasks should create
    /// their own context via `ModelContext(container)` to avoid lifecycle issues.
    private var context: ModelContext { container.mainContext }

    private let tmdb: TMDBServiceProtocol
    private let franchise: FranchiseResolving
    private let cloudKit: CloudSyncing

    /// Notification scheduler (actor for thread safety)
    private let notificationScheduler = NotificationScheduler()

    #if DEBUG
    /// Pending background tasks — tracked only in DEBUG for test awaiting.
    /// Each task removes itself on completion to avoid unbounded growth.
    private var pendingTasks: [UUID: Task<Void, Never>] = [:]
    #endif

    init(
        container: ModelContainer,
        tmdb: TMDBServiceProtocol = TMDBService(),
        franchise: FranchiseResolving? = nil,
        cloudKit: CloudSyncing? = nil
    ) {
        self.container = container
        self.tmdb = tmdb
        // Resolve the shared singletons in the (main-actor) init body rather than
        // in nonisolated default-argument position.
        self.franchise = franchise ?? FranchiseService.shared
        self.cloudKit = cloudKit ?? CloudKitManager.shared
    }

    #if DEBUG
    /// Await all pending background work. For tests only.
    func awaitPendingBackgroundWork() async {
        let tasks = pendingTasks.values
        for task in tasks {
            await task.value
        }
    }
    #endif

    // MARK: - Refresh Cadence (State-Based Throttle)

    /// Cadence intervals per ShowState. Replaces the old flat 24h throttle.
    /// State-based: airing shows refresh weekly, anticipated shows every 3 days,
    /// premieringSoon daily, etc. One source of truth for "is this show due."
    enum RefreshCadence {
        static let anticipated: TimeInterval = 3 * 24 * 60 * 60      // 3 days
        static let premieringSoon: TimeInterval = 1 * 24 * 60 * 60   // 1 day
        static let airing: TimeInterval = 7 * 24 * 60 * 60           // 7 days
        static let airingNearFinale: TimeInterval = 1 * 24 * 60 * 60 // 1 day (≤2 days to finale)
        static let pending: TimeInterval = 2 * 24 * 60 * 60          // 2 days
        static let bingeReady: TimeInterval = 7 * 24 * 60 * 60       // 7 days (renewal discovery)
    }

    /// When this show should next be refreshed based on its lifecycle state.
    /// Uses injected `now` for deterministic tests.
    func nextRefreshDue(for series: Series, now: Date) -> Date {
        let seasonFacts = series.seasonFacts
        let state = BingeEngine.showState(seasons: seasonFacts, now: now)
        let lastRefresh = series.lastRefreshedAt ?? .distantPast

        let interval: TimeInterval
        switch state {
        case .anticipated:
            interval = RefreshCadence.anticipated
        case .premieringSoon:
            interval = RefreshCadence.premieringSoon
        case .airing:
            // Near-finale shows get faster refresh (≤2 days to finale → daily)
            let daysUntilFinale = BingeEngine.daysUntilFinale(seasons: seasonFacts, now: now)
            if let days = daysUntilFinale, days <= 2 {
                interval = RefreshCadence.airingNearFinale
            } else {
                interval = RefreshCadence.airing
            }
        case .pending:
            interval = RefreshCadence.pending
        case .bingeReady:
            interval = RefreshCadence.bingeReady
        }

        return lastRefresh.addingTimeInterval(interval)
    }

    /// Launch a background task that self-cleans from pendingTasks on completion.
    /// In DEBUG: tracked for test awaiting. In RELEASE: fire-and-forget.
    private func launchBackgroundTask(_ operation: @escaping @Sendable () async -> Void) {
        #if DEBUG
        let taskId = UUID()
        let task = Task {
            await operation()
            // Self-remove on completion to avoid unbounded growth
            await MainActor.run { _ = self.pendingTasks.removeValue(forKey: taskId) }
        }
        pendingTasks[taskId] = task
        #else
        Task { await operation() }
        #endif
    }

    // MARK: - Queries

    func series(id: Int) -> Series? {
        let descriptor = FetchDescriptor<Series>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    func isFollowing(id: Int) -> Bool {
        series(id: id) != nil
    }

    /// Fetch all followed series. For one-shot queries in non-view contexts.
    /// Views should use @Query<Series> for automatic updates.
    func allSeries() -> [Series] {
        let descriptor = FetchDescriptor<Series>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func followedCount() -> Int {
        allSeries().count
    }

    // MARK: - Follow (the ONLY creation path)

    /// Follow a show we already have full ShowData for.
    /// Returns the result so the UI can prompt the add-time question when the
    /// show enters already-complete (back-catalog like Landman).
    @discardableResult
    func follow(showData show: ShowData) throws -> FollowResult {
        // Idempotent: if already followed, just refresh metadata.
        if let existing = series(id: show.id) {
            SeriesMapper.update(existing, from: show, in: context)
            try context.save()
            return .alreadyFollowing(existing)
        }

        let newSeries = SeriesMapper.makeSeries(from: show, in: context)
        newSeries.lastRefreshedAt = .now
        try context.save()

        // Capture ID for background tasks (avoid capturing model object)
        let seriesId = newSeries.id

        // Resolve spinoffs once, in the background (non-blocking).
        // Uses its own context to avoid lifecycle issues if caller's context deallocates.
        launchBackgroundTask { [container, franchise] in
            let bgContext = ModelContext(container)
            let descriptor = FetchDescriptor<Series>(predicate: #Predicate { $0.id == seriesId })
            guard let s = try? bgContext.fetch(descriptor).first, !s.spinoffsResolved else { return }

            let relatedIds = await franchise.relatedShowIds(forShowId: seriesId)
            s.relatedShowIds = relatedIds
            s.spinoffsResolved = true
            try? bgContext.save()
        }

        // Sync to iCloud if premium (non-blocking)
        launchBackgroundTask {
            await self.syncShowToCloudIfPremium(seriesId: seriesId)
        }

        // Schedule notifications for this show (non-blocking)
        launchBackgroundTask { [container] in
            // Fetch fresh from context (the newSeries reference may be stale)
            let bgContext = ModelContext(container)
            let descriptor = FetchDescriptor<Series>(predicate: #Predicate { $0.id == seriesId })
            guard let series = try? bgContext.fetch(descriptor).first else { return }
            await self.scheduleNotificationsForShow(series, now: Date())
        }

        // Decide whether to prompt the add-time watched question.
        let prompt = addTimeWatchedPrompt(for: newSeries)
        return .followed(newSeries, addTimePrompt: prompt)
    }

    /// Follow by TMDB id — fetches full details first, then follows.
    @discardableResult
    func follow(id: Int) async throws -> FollowResult {
        if let existing = series(id: id) { return .alreadyFollowing(existing) }
        let show = try await tmdb.getShowDetails(id: id)
        return try follow(showData: show)
    }

    // MARK: - Unfollow (the ONLY deletion path)

    func unfollow(id: Int) throws {
        guard let s = series(id: id) else { return }

        // Cancel notifications for this show (non-blocking)
        let showId = s.id
        launchBackgroundTask {
            await self.cancelNotificationsForShow(showId)
        }

        context.delete(s)               // cascades to seasons/episodes
        try context.save()
    }

    // MARK: - Cleanup

    /// Remove duplicate Series entries (keeps the most recently added one per ID)
    func cleanupDuplicates() throws {
        let all = allSeries()

        // Group by ID
        var byId: [Int: [Series]] = [:]
        for series in all {
            byId[series.id, default: []].append(series)
        }

        // Delete duplicates (keep first, which is most recent due to sort order)
        var deletedCount = 0
        for (id, duplicates) in byId where duplicates.count > 1 {
            print("🧹 Cleaning up \(duplicates.count - 1) duplicate(s) for show ID \(id): \(duplicates.first?.name ?? "?")")
            for dup in duplicates.dropFirst() {
                context.delete(dup)
                deletedCount += 1
            }
        }

        if deletedCount > 0 {
            try context.save()
            print("🧹 Deleted \(deletedCount) duplicate Series entries")
        }
    }

    // MARK: - Add-time watched question

    /// Whether to prompt "Have you watched Season N?" at follow-time.
    /// Only when the show's latest season is ALREADY binge-ready-by-date
    /// (i.e. the show was added from the back catalog after airing).
    private func addTimeWatchedPrompt(for series: Series) -> AddTimeWatchedPrompt? {
        // The latest season that is complete by date, regardless of watched.
        let latestComplete = series.regularSeasons
            .filter { $0.isBingeReadyByDate }
            .max(by: { $0.seasonNumber < $1.seasonNumber })

        guard let season = latestComplete else { return nil }
        return AddTimeWatchedPrompt(seriesId: series.id,
                                    seasonNumber: season.seasonNumber,
                                    seasonName: season.name)
    }

    /// Apply the user's answer to the add-time question.
    /// `watched == true`  → mark ONLY that latest season watched → toward Anticipated.
    /// `watched == false` → leave unwatched → the show sits in Binge Ready.
    func answerAddTimeWatched(seriesId: Int, seasonNumber: Int, watched: Bool) throws {
        guard watched else { return }   // "no" = leave as-is (Binge Ready)
        guard let series = series(id: seriesId),
              let season = series.regularSeasons.first(where: { $0.seasonNumber == seasonNumber })
        else { return }
        // Mark ONLY the answered (latest) season watched — same as the timeline
        // path marking a single season complete. Earlier seasons are untouched.
        setSeasonWatched(season, watched: true)
        try context.save()
        syncWatchProgressToCloud()
    }

    // MARK: - Watch state

    func markSeasonWatched(seriesId: Int, seasonNumber: Int, watched: Bool = true) throws {
        guard let s = series(id: seriesId),
              let season = s.regularSeasons.first(where: { $0.seasonNumber == seasonNumber })
        else { return }
        setSeasonWatched(season, watched: watched)
        try context.save()
        syncWatchProgressToCloud()
    }

    /// Mark every regular season up to and including `throughSeasonNumber` as
    /// watched — the "caught up through Season N" catch-up answer. Marks ALL
    /// prior seasons, not just the latest, so nothing earlier is left unwatched.
    /// `throughSeasonNumber <= 0` marks nothing (haven't started).
    func markSeasonsWatched(seriesId: Int, throughSeasonNumber n: Int) throws {
        guard n > 0, let s = series(id: seriesId) else { return }
        for season in s.regularSeasons where season.seasonNumber <= n {
            setSeasonWatched(season, watched: true)
        }
        try context.save()
        syncWatchProgressToCloud()
    }

    /// Toggle episode watched by TMDB episode ID.
    func toggleEpisodeWatched(seriesId: Int, episodeId: Int) throws {
        guard let s = series(id: seriesId) else { return }
        for season in s.seasons {
            if let ep = season.episodes.first(where: { $0.id == episodeId }) {
                ep.hasWatched.toggle()
                ep.watchedAt = ep.hasWatched ? .now : nil
                syncSeasonWatchedState(season)
                try context.save()
                    syncWatchProgressToCloud()
                return
            }
        }
    }

    /// Toggle episode watched by season/episode number (for views without episode ID).
    func toggleEpisodeWatched(seriesId: Int, seasonNumber: Int, episodeNumber: Int) throws {
        guard let s = series(id: seriesId),
              let season = s.regularSeasons.first(where: { $0.seasonNumber == seasonNumber }),
              let episode = season.episodes.first(where: { $0.episodeNumber == episodeNumber })
        else { return }

        episode.hasWatched.toggle()
        episode.watchedAt = episode.hasWatched ? .now : nil
        syncSeasonWatchedState(season)
        try context.save()
        syncWatchProgressToCloud()
    }

    /// Mark all aired episodes in a season as watched.
    /// Note: season.hasWatched only becomes true if ALL episodes (including unaired)
    /// are watched. For a still-airing season, this correctly leaves hasWatched=false
    /// since unaired episodes aren't marked — the season isn't complete yet.
    func markAiredEpisodesWatched(seriesId: Int, seasonNumber: Int) throws {
        guard let s = series(id: seriesId),
              let season = s.regularSeasons.first(where: { $0.seasonNumber == seasonNumber })
        else { return }

        for episode in season.episodes where episode.hasAired {
            episode.hasWatched = true
            episode.watchedAt = .now
        }
        syncSeasonWatchedState(season)
        try context.save()
        syncWatchProgressToCloud()
    }

    /// Recompute season.hasWatched from its episodes. Single source of truth for
    /// season-level watched rollup — call after any episode watch-state mutation.
    private func syncSeasonWatchedState(_ season: Season) {
        let allWatched = season.episodes.allSatisfy { $0.hasWatched }
        season.hasWatched = allWatched
        season.watchedAt = allWatched ? .now : nil
    }

    private func setSeasonWatched(_ season: Season, watched: Bool) {
        season.hasWatched = watched
        season.watchedAt = watched ? .now : nil
        for ep in season.episodes {
            ep.hasWatched = watched
            ep.watchedAt = watched ? .now : nil
        }
    }

    // MARK: - Archive (user-axis flag)

    func setArchived(seriesId: Int, archived: Bool) throws {
        guard let s = series(id: seriesId) else { return }
        s.isArchived = archived
        try context.save()
    }

    // MARK: - Refresh (the ONLY TMDB→Series write path)

    /// Refresh a single show from TMDB (metadata + new seasons/episodes),
    /// preserving watch state. `force` bypasses the state-based cadence.
    /// `now` parameter for testability (defaults to current date).
    ///
    /// Cadence is state-based: anticipated (3d), premieringSoon (1d), airing (7d),
    /// airing near finale (1d), pending (2d), bingeReady (7d). See RefreshCadence.
    /// Show titles are TMDB content (like search), so they should follow the app
    /// language. Stored titles are captured in the language active when a show was
    /// followed; when the language changes, re-fetch each title in the new language
    /// (one light request per show). No-op when the language hasn't changed. R3:
    /// the single write funnel for the name correction.
    func relocalizeNamesIfLanguageChanged() async {
        let current = TMDBConfiguration.currentLanguage
        let key = "seriesNameLanguage"
        guard UserDefaults.standard.string(forKey: key) != current else { return }

        let ids = allSeries().map { $0.id }
        guard !ids.isEmpty else {
            UserDefaults.standard.set(current, forKey: key)
            return
        }

        let tmdb = self.tmdb
        var names: [Int: String] = [:]
        await withTaskGroup(of: (Int, String)?.self) { group in
            for id in ids {
                group.addTask {
                    guard let name = try? await tmdb.getShowName(id: id), !name.isEmpty else { return nil }
                    return (id, name)
                }
            }
            for await item in group {
                if let (id, name) = item { names[id] = name }
            }
        }

        for (id, name) in names {
            series(id: id)?.name = name
        }
        try? context.save()
        UserDefaults.standard.set(current, forKey: key)
    }

    func refresh(id: Int, force: Bool = false, now: Date = Date()) async {
        guard let s = series(id: id) else { return }

        // State-based throttle: skip if not due (unless forced)
        if !force, now < nextRefreshDue(for: s, now: now) {
            return
        }

        // Snapshot old season numbers for new-season detection
        let oldSeasonNumbers = Set(s.regularSeasons.map { $0.seasonNumber })
        let seriesName = s.name

        do {
            let show = try await tmdb.getShowDetails(id: id)
            SeriesMapper.update(s, from: show, in: context)
            s.lastRefreshedAt = now

            // Fix hasWatched if new episodes were added to a "watched" season.
            // This is the single write funnel for this correction (R3).
            // Only un-mark if the season is STILL AIRING (finale hasn't aired).
            // Finished seasons with data corrections stay marked watched.
            for season in s.seasons where season.hasWatched {
                let allWatched = season.episodes.allSatisfy { $0.hasWatched }
                if !allWatched {
                    // Check if finale has aired (conservative rule via episodeFacts)
                    let finaleEp = BingeEngine.finaleEpisode(from: season.episodeFacts)
                    let finaleAired = finaleEp?.airDate.map { $0 <= now } ?? false

                    // Only un-mark if finale HASN'T aired (still-airing = real new episode)
                    // If finale already aired, treat unwatched episodes as data correction
                    if !finaleAired {
                        season.hasWatched = false
                    }
                }
            }

            try context.save()

            // Snapshot new season numbers after update
            let newSeasonNumbers = Set(s.regularSeasons.map { $0.seasonNumber })

            // Schedule notifications for this show (based on updated dates)
            await scheduleNotificationsForShow(s, now: now)

            // Detect and fire new-season event notifications
            await handleNewSeasonEvent(
                seriesId: id,
                seriesName: seriesName,
                oldSeasonNumbers: oldSeasonNumbers,
                newSeasonNumbers: newSeasonNumbers,
                now: now
            )
        } catch {
            // Silent: keep existing data on failure.
        }
    }

    /// Refresh every followed show. Call on launch / background refresh.
    /// Checks Task.isCancelled between shows for graceful background-task expiration.
    /// `now` parameter for testability (defaults to current date).
    func refreshAll(force: Bool = false, now: Date = Date()) async {
        for s in allSeries() {
            // Check cancellation before each show (supports background task expiration)
            guard !Task.isCancelled else {
                print("🛑 Refresh cancelled by system")
                return
            }
            await refresh(id: s.id, force: force, now: now)
        }
    }

    // MARK: - Notifications (Premium-gated)

    /// Schedule notifications for a single show based on current dates and global settings.
    /// Premium-gated: free users get no notifications.
    private func scheduleNotificationsForShow(_ series: Series, now: Date) async {
        // Premium gate: free users get no notifications
        guard PremiumManager.shared.isPremium else { return }

        // Check notification authorization
        guard NotificationService.shared.isAuthorized else { return }

        // Get global settings (MainActor access)
        let settings = NotificationSettingsStore.shared.settings

        // Extract dates from Series (R2 compliant: reads Series, not ShowData)
        let dateInfo = extractDateInfo(from: series, now: now)

        // Plan notifications (pure function)
        let plans = planNotifications(dates: dateInfo, settings: settings, now: now)

        // Apply plans (schedule-once / update-only-on-change pattern)
        await notificationScheduler.applyPlans(plans, for: series.id)
    }

    /// Detect and fire new season notifications (event-driven, fires once).
    /// Called after refresh when new seasons are detected.
    private func handleNewSeasonEvent(
        seriesId: Int,
        seriesName: String,
        oldSeasonNumbers: Set<Int>,
        newSeasonNumbers: Set<Int>,
        now: Date
    ) async {
        // Premium gate
        guard PremiumManager.shared.isPremium else { return }

        // Check notification authorization
        guard NotificationService.shared.isAuthorized else { return }

        // Get global settings (MainActor access)
        let settings = NotificationSettingsStore.shared.settings
        guard settings.newSeason else { return }

        // Find added seasons
        let addedSeasons = newSeasonNumbers.subtracting(oldSeasonNumbers)

        for seasonNumber in addedSeasons {
            // Check if already fired (avoid duplicate notifications)
            let alreadyFired = await notificationScheduler.hasNewSeasonFired(
                showId: seriesId,
                seasonNumber: seasonNumber
            )
            guard !alreadyFired else { continue }

            // Fire immediate notification
            let plan = NotificationPlan(
                identifier: "show-\(seriesId)-newseason-s\(seasonNumber)",
                type: .newSeason,
                showId: seriesId,
                showName: seriesName,
                fireDate: now,
                seasonNumber: seasonNumber
            )
            await notificationScheduler.fireImmediate(plan)
        }
    }

    /// Cancel all notifications for a show (called on unfollow).
    private func cancelNotificationsForShow(_ showId: Int) async {
        await notificationScheduler.cancelAll(for: showId)
    }

    // MARK: - Spinoffs (Firebase, ONCE, stored — kills the flicker)

    /// Resolve franchise/spinoff ids for a show and store them on the Series.
    /// Runs at most once per show (guarded by spinoffsResolved).
    func resolveSpinoffs(for seriesId: Int) async {
        guard let s = series(id: seriesId), !s.spinoffsResolved else { return }
        let relatedIds = await franchise.relatedShowIds(forShowId: seriesId)
        s.relatedShowIds = relatedIds
        s.spinoffsResolved = true
        try? context.save()
    }

    // MARK: - iCloud Watch Progress Sync

    /// Collect all watched episode keys in format "seriesId-seasonNumber-episodeNumber"
    private func allWatchedEpisodeKeys() -> Set<String> {
        var keys = Set<String>()
        for series in allSeries() {
            for season in series.seasons {
                for episode in season.episodes where episode.hasWatched {
                    let key = "\(series.id)-\(season.seasonNumber)-\(episode.episodeNumber)"
                    keys.insert(key)
                }
            }
        }
        return keys
    }

    /// Sync watch progress to iCloud (called after any watch state change)
    /// Uses its own context to avoid lifecycle issues.
    private func syncWatchProgressToCloud() {
        launchBackgroundTask { [container, cloudKit] in
            guard await cloudKit.isAvailable else {
                print("☁️ iCloud: Not available, skipping sync")
                return
            }

            // Create background context and fetch all series
            let bgContext = ModelContext(container)
            let descriptor = FetchDescriptor<Series>()
            let allSeriesList = (try? bgContext.fetch(descriptor)) ?? []

            // Collect watch keys from bgContext objects
            var keys = Set<String>()
            var showSummary: [String: (watched: Int, total: Int)] = [:]

            for series in allSeriesList {
                var watchedCount = 0
                var totalCount = 0
                for season in series.seasons {
                    for episode in season.episodes {
                        totalCount += 1
                        if episode.hasWatched {
                            watchedCount += 1
                            let key = "\(series.id)-\(season.seasonNumber)-\(episode.episodeNumber)"
                            keys.insert(key)
                        }
                    }
                }
                if watchedCount > 0 {
                    showSummary[series.name] = (watchedCount, totalCount)
                }
            }

            // Debug logging
            print("☁️ ═══════════════════════════════════════════")
            print("☁️ iCloud SYNC - Saving Watch Progress")
            print("☁️ ═══════════════════════════════════════════")

            if showSummary.isEmpty {
                print("☁️ No watched episodes to sync")
            } else {
                for (name, counts) in showSummary.sorted(by: { $0.key < $1.key }) {
                    let progress = counts.total > 0 ? Int((Double(counts.watched) / Double(counts.total)) * 100) : 0
                    print("☁️ ✓ \(name): \(counts.watched)/\(counts.total) episodes (\(progress)%)")
                }
                print("☁️ ───────────────────────────────────────────")
                print("☁️ Total: \(keys.count) watched episodes")
            }

            do {
                try await cloudKit.saveAllWatchProgress(watchedEpisodeKeys: keys)
                print("☁️ ✅ Successfully synced to iCloud")
            } catch {
                print("☁️ ❌ Failed to sync: \(error)")
            }
            print("☁️ ═══════════════════════════════════════════")
        }
    }

    /// Restore watch progress from iCloud (call on app launch)
    func restoreWatchProgressFromCloud() async {
        guard await cloudKit.isAvailable else {
            print("☁️ iCloud: Not available, skipping restore")
            return
        }

        print("☁️ ═══════════════════════════════════════════")
        print("☁️ iCloud RESTORE - Fetching Watch Progress")
        print("☁️ ═══════════════════════════════════════════")

        do {
            guard let cloudKeys = try await cloudKit.fetchAllWatchProgress() else {
                print("☁️ No watch progress found in iCloud")
                print("☁️ ═══════════════════════════════════════════")
                return
            }

            print("☁️ Found \(cloudKeys.count) watched episodes in iCloud")

            // Parse keys and apply to local data
            var restoredCount = 0
            var restoredByShow: [String: Int] = [:]

            for key in cloudKeys {
                let parts = key.split(separator: "-")
                guard parts.count == 3,
                      let seriesId = Int(parts[0]),
                      let seasonNumber = Int(parts[1]),
                      let episodeNumber = Int(parts[2])
                else { continue }

                // Find and mark episode as watched
                guard let series = series(id: seriesId),
                      let season = series.seasons.first(where: { $0.seasonNumber == seasonNumber }),
                      let episode = season.episodes.first(where: { $0.episodeNumber == episodeNumber })
                else { continue }

                if !episode.hasWatched {
                    episode.hasWatched = true
                    episode.watchedAt = .now
                    restoredCount += 1
                    restoredByShow[series.name, default: 0] += 1
                }
            }

            // Update season watched states
            for series in allSeries() {
                for season in series.seasons {
                    syncSeasonWatchedState(season)
                }
            }

            if restoredCount > 0 {
                try context.save()
                    print("☁️ ───────────────────────────────────────────")
                print("☁️ Restored episodes from iCloud:")
                for (name, count) in restoredByShow.sorted(by: { $0.key < $1.key }) {
                    print("☁️ ↓ \(name): +\(count) episodes")
                }
                print("☁️ ───────────────────────────────────────────")
                print("☁️ ✅ Total restored: \(restoredCount) episodes")
            } else {
                print("☁️ ✓ Local data already up to date")
            }
        } catch {
            print("☁️ ❌ Failed to restore: \(error)")
        }
        print("☁️ ═══════════════════════════════════════════")
    }

    /// Merge local and cloud watch progress (handles conflicts by keeping watched state)
    func mergeWatchProgressWithCloud() async {
        print("☁️ ═══════════════════════════════════════════")
        print("☁️ iCloud MERGE - Starting bidirectional sync")
        print("☁️ ═══════════════════════════════════════════")

        guard await cloudKit.isAvailable else {
            print("☁️ ⚠️ iCloud not available - sign in via Settings")
            print("☁️ ═══════════════════════════════════════════")
            return
        }

        // First restore from cloud (marks any cloud-watched episodes locally)
        await restoreWatchProgressFromCloud()

        // Then sync local state back to cloud (includes any local-only watched episodes)
        syncWatchProgressToCloud()
    }

    // MARK: - Show Sync State (Premium Feature)

    /// Sync a single show to iCloud if user is premium
    private func syncShowToCloudIfPremium(seriesId: Int) async {
        guard PremiumManager.shared.isPremium else { return }
        await syncShowToCloud(seriesId: seriesId)
    }

    /// Sync a single show to iCloud.
    /// Uses bgContext to fetch data for network call, writes isSynced to mainContext for UI.
    func syncShowToCloud(seriesId: Int) async {
        guard await cloudKit.isAvailable else { return }

        // Fetch show data on bgContext (independent of caller's lifecycle)
        let bgContext = ModelContext(container)
        let descriptor = FetchDescriptor<Series>(predicate: #Predicate { $0.id == seriesId })
        guard let bgSeries = try? bgContext.fetch(descriptor).first else { return }

        let tmdbId = bgSeries.id
        let followedAt = bgSeries.dateAdded
        let name = bgSeries.name

        do {
            try await cloudKit.saveFollowedShow(tmdbId: tmdbId, followedAt: followedAt)

            // Write isSynced on mainContext for immediate @Query visibility
            if let mainSeries = self.series(id: seriesId) {
                mainSeries.isSynced = true
                try? self.context.save()
            }
            print("☁️ ✓ Synced show: \(name)")
        } catch {
            print("☁️ ❌ Failed to sync show \(name): \(error)")
        }
    }

    /// Remove a single show from iCloud sync.
    /// Uses bgContext to fetch data for network call, writes isSynced to mainContext for UI.
    func unsyncShowFromCloud(seriesId: Int) async {
        guard await cloudKit.isAvailable else { return }

        // Fetch show data on bgContext
        let bgContext = ModelContext(container)
        let descriptor = FetchDescriptor<Series>(predicate: #Predicate { $0.id == seriesId })
        guard let bgSeries = try? bgContext.fetch(descriptor).first else { return }

        let tmdbId = bgSeries.id
        let name = bgSeries.name

        do {
            try await cloudKit.deleteFollowedShow(tmdbId: tmdbId)

            // Write isSynced on mainContext for immediate @Query visibility
            if let mainSeries = self.series(id: seriesId) {
                mainSeries.isSynced = false
                try? self.context.save()
            }
            print("☁️ ✓ Removed from cloud: \(name)")
        } catch {
            print("☁️ ❌ Failed to unsync show \(name): \(error)")
        }
    }

    /// Sync all followed shows to iCloud (called when user becomes premium)
    func syncAllShowsToCloud() async {
        guard await cloudKit.isAvailable else {
            print("☁️ ⚠️ iCloud not available")
            return
        }

        print("☁️ ═══════════════════════════════════════════")
        print("☁️ Syncing ALL shows to iCloud...")
        print("☁️ ═══════════════════════════════════════════")

        let shows = allSeries()
        var syncedCount = 0

        for s in shows {
            do {
                try await cloudKit.saveFollowedShow(tmdbId: s.id, followedAt: s.dateAdded)
                s.isSynced = true
                syncedCount += 1
                print("☁️ ✓ \(s.name)")
            } catch {
                print("☁️ ❌ \(s.name): \(error.localizedDescription)")
            }
        }

        try? context.save()
        syncWatchProgressToCloud()

        print("☁️ ───────────────────────────────────────────")
        print("☁️ ✅ Synced \(syncedCount)/\(shows.count) shows")
        print("☁️ ═══════════════════════════════════════════")
    }

    /// Remove all shows from iCloud (called when user loses premium)
    func unsyncAllShowsFromCloud() async {
        guard await cloudKit.isAvailable else { return }

        print("☁️ ═══════════════════════════════════════════")
        print("☁️ Removing ALL shows from iCloud...")
        print("☁️ ═══════════════════════════════════════════")

        let shows = allSeries()

        // Delete all followed shows from CloudKit
        let tmdbIds = shows.map { $0.id }
        do {
            try await cloudKit.deleteFollowedShows(tmdbIds)

            // Mark all as unsynced locally
            for s in shows {
                s.isSynced = false
            }
            try context.save()

            // Also delete watch progress
            try await cloudKit.deleteAllWatchProgress()

            print("☁️ ✅ Removed \(shows.count) shows from iCloud")
        } catch {
            print("☁️ ❌ Failed to remove shows: \(error)")
        }

        print("☁️ ═══════════════════════════════════════════")
    }

    /// Count of synced shows
    var syncedShowCount: Int {
        allSeries().filter { $0.isSynced }.count
    }

    // MARK: - Restore Shows from iCloud

    /// Restore followed shows from iCloud (call on fresh install/reinstall)
    /// This fetches show IDs from CloudKit and re-follows them from TMDB
    func restoreShowsFromCloud() async {
        guard await cloudKit.isAvailable else {
            print("☁️ ⚠️ iCloud not available for restore")
            return
        }

        print("☁️ ═══════════════════════════════════════════")
        print("☁️ iCloud RESTORE - Fetching Followed Shows")
        print("☁️ ═══════════════════════════════════════════")

        do {
            let cloudRecords = try await cloudKit.fetchAllFollowedShows()

            if cloudRecords.isEmpty {
                print("☁️ No shows found in iCloud")
                print("☁️ ═══════════════════════════════════════════")
                return
            }

            print("☁️ Found \(cloudRecords.count) shows in iCloud")

            var restoredCount = 0
            var failedCount = 0

            for record in cloudRecords {
                guard let tmdbId = record.tmdbId else { continue }

                // Skip if already following locally
                if isFollowing(id: tmdbId) {
                    print("☁️ ✓ Already following ID \(tmdbId)")
                    continue
                }

                // Follow the show (fetches from TMDB and creates Series)
                do {
                    let result = try await follow(id: tmdbId)
                    if case .followed(let series, _) = result {
                        series.isSynced = true
                        if let followedAt = record.followedAt {
                            series.dateAdded = followedAt
                        }
                        try? context.save()
                        restoredCount += 1
                        print("☁️ ↓ Restored: \(series.name)")
                    }
                } catch {
                    failedCount += 1
                    print("☁️ ❌ Failed to restore ID \(tmdbId): \(error.localizedDescription)")
                }
            }

            print("☁️ ───────────────────────────────────────────")
            if restoredCount > 0 {
                print("☁️ ✅ Restored \(restoredCount) shows from iCloud")
                }
            if failedCount > 0 {
                print("☁️ ⚠️ Failed to restore \(failedCount) shows")
            }
        } catch {
            print("☁️ ❌ Failed to fetch shows from iCloud: \(error)")
        }

        print("☁️ ═══════════════════════════════════════════")
    }
}

// MARK: - Results / Prompts

enum FollowResult {
    case followed(Series, addTimePrompt: AddTimeWatchedPrompt?)
    case alreadyFollowing(Series)
}

/// Instruction to the UI to ask the add-time watched question.
struct AddTimeWatchedPrompt: Equatable {
    let seriesId: Int
    let seasonNumber: Int
    let seasonName: String
}

// MARK: - Franchise abstraction

/// Minimal protocol so SeriesManager doesn't depend on FranchiseService's
/// concrete shape (and is testable with a mock).
///
/// INTEGRATION: make FranchiseService conform to this. It should return the
/// franchise's related TMDB ids (parent + spinoffs, EXCLUDING the show itself).
protocol FranchiseResolving {
    func relatedShowIds(forShowId showId: Int) async -> [Int]
}
