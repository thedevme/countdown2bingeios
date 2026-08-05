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

    private let context: ModelContext
    private let tmdb: TMDBServiceProtocol
    private let franchise: FranchiseResolving

    /// Shows refreshed from TMDB are considered fresh for this long.
    private let refreshInterval: TimeInterval = 60 * 60 * 24  // 24h

    init(
        context: ModelContext,
        tmdb: TMDBServiceProtocol = TMDBService(),
        franchise: FranchiseResolving = FranchiseService.shared
    ) {
        self.context = context
        self.tmdb = tmdb
        self.franchise = franchise
    }

    // MARK: - Queries

    func series(id: Int) -> Series? {
        let descriptor = FetchDescriptor<Series>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    func isFollowing(id: Int) -> Bool {
        series(id: id) != nil
    }

    func allSeries() -> [Series] {
        let descriptor = FetchDescriptor<Series>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func followedCount() -> Int {
        (try? context.fetchCount(FetchDescriptor<Series>())) ?? 0
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

        let series = SeriesMapper.makeSeries(from: show, in: context)
        series.lastRefreshedAt = .now
        try context.save()

        // Resolve spinoffs once, in the background (non-blocking).
        Task { await self.resolveSpinoffs(for: series.id) }

        // Decide whether to prompt the add-time watched question.
        let prompt = addTimeWatchedPrompt(for: series)
        return .followed(series, addTimePrompt: prompt)
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
        guard let series = series(id: id) else { return }
        context.delete(series)               // cascades to seasons/episodes
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
    }

    // MARK: - Watch state

    func markSeasonWatched(seriesId: Int, seasonNumber: Int, watched: Bool = true) throws {
        guard let series = series(id: seriesId),
              let season = series.regularSeasons.first(where: { $0.seasonNumber == seasonNumber })
        else { return }
        setSeasonWatched(season, watched: watched)
        try context.save()
    }

    /// Toggle episode watched by TMDB episode ID.
    func toggleEpisodeWatched(seriesId: Int, episodeId: Int) throws {
        guard let series = series(id: seriesId) else { return }
        for season in series.seasons {
            if let ep = season.episodes.first(where: { $0.id == episodeId }) {
                ep.hasWatched.toggle()
                ep.watchedAt = ep.hasWatched ? .now : nil
                syncSeasonWatchedState(season)
                try context.save()
                return
            }
        }
    }

    /// Toggle episode watched by season/episode number (for views without episode ID).
    func toggleEpisodeWatched(seriesId: Int, seasonNumber: Int, episodeNumber: Int) throws {
        guard let series = series(id: seriesId),
              let season = series.regularSeasons.first(where: { $0.seasonNumber == seasonNumber }),
              let episode = season.episodes.first(where: { $0.episodeNumber == episodeNumber })
        else { return }

        episode.hasWatched.toggle()
        episode.watchedAt = episode.hasWatched ? .now : nil
        syncSeasonWatchedState(season)
        try context.save()
    }

    /// Mark all aired episodes in a season as watched.
    /// Note: season.hasWatched only becomes true if ALL episodes (including unaired)
    /// are watched. For a still-airing season, this correctly leaves hasWatched=false
    /// since unaired episodes aren't marked — the season isn't complete yet.
    func markAiredEpisodesWatched(seriesId: Int, seasonNumber: Int) throws {
        guard let series = series(id: seriesId),
              let season = series.regularSeasons.first(where: { $0.seasonNumber == seasonNumber })
        else { return }

        for episode in season.episodes where episode.hasAired {
            episode.hasWatched = true
            episode.watchedAt = .now
        }
        syncSeasonWatchedState(season)
        try context.save()
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
        guard let series = series(id: seriesId) else { return }
        series.isArchived = archived
        try context.save()
    }

    // MARK: - Refresh (the ONLY TMDB→Series write path)

    /// Refresh a single show from TMDB (metadata + new seasons/episodes),
    /// preserving watch state. `force` ignores the refresh interval.
    func refresh(id: Int, force: Bool = false) async {
        guard let series = series(id: id) else { return }
        if !force, let last = series.lastRefreshedAt,
           Date().timeIntervalSince(last) < refreshInterval {
            return
        }
        do {
            let show = try await tmdb.getShowDetails(id: id)
            SeriesMapper.update(series, from: show, in: context)
            series.lastRefreshedAt = .now
            try context.save()
        } catch {
            // Silent: keep existing data on failure.
        }
    }

    /// Refresh every followed show. Call on launch / background refresh.
    func refreshAll(force: Bool = false) async {
        for series in allSeries() {
            await refresh(id: series.id, force: force)
        }
    }

    // MARK: - Spinoffs (Firebase, ONCE, stored — kills the flicker)

    /// Resolve franchise/spinoff ids for a show and store them on the Series.
    /// Runs at most once per show (guarded by spinoffsResolved).
    func resolveSpinoffs(for seriesId: Int) async {
        guard let series = series(id: seriesId), !series.spinoffsResolved else { return }
        let relatedIds = await franchise.relatedShowIds(forShowId: seriesId)
        series.relatedShowIds = relatedIds
        series.spinoffsResolved = true
        try? context.save()
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
