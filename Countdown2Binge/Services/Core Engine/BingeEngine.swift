//
//  BingeEngine.swift
//  Countdown2Binge
//
//  The PURE core state machine. No SwiftData, no network, no side effects.
//  Every rule we care about is a static function of (season data + today),
//  so it can be unit-tested in isolation and reused by both the DTO layer
//  and the SwiftData models.
//
//  This is the single source of truth for lifecycle RULES. The models and
//  SeriesManager call into this — they never re-implement date math.
//
//  ============================================================================
//  LOCKED RULES (do not change without updating the spec + tests):
//
//  1. FINALE DETECTION (conservative):
//     - If any episode is typed `.finale` → that's the finale.
//     - Else if the season has NO typed episodes at all (all `.standard`
//       AND TMDB gave us no type info) → fall back to the last episode by
//       number.
//     - Else (episodes ARE typed but none is `.finale`) → finale is UNKNOWN.
//       Finale date is nil. The season is `pending`, never `airing`/complete.
//
//  2. FINALE-DAY GRACE WINDOW:
//     - A season stays `airing` through the finale day AND the following full
//       day. It flips to `bingeReady` at the START of day +2 (two calendar
//       days after the finale date).
//
//  3. BINGE READY = ShowState.bingeReady (date fact) ∩ UserState.unwatched.
//     Only the single LATEST unwatched-complete season per show is surfaced.
//
//  4. Cancelled/ended production status does NOT force a show out of Binge
//     Ready. Bingeability is "complete + unwatched", not production status.
//  ============================================================================
//

import Foundation

enum BingeEngine {

    // MARK: - Calendar

    /// All comparisons use start-of-day in the current calendar to avoid
    /// time-of-day drift (TMDB air dates are date-only).
    private static var calendar: Calendar { Calendar.current }

    // MARK: - Finale Resolution (Rule 1)

    /// A minimal episode fact the engine needs. Both EpisodeData (DTO) and
    /// Episode (@Model) can produce this, so the engine works for both.
    struct EpisodeFact {
        let episodeNumber: Int
        let airDate: Date?
        let isTypedFinale: Bool      // episodeType == .finale
        let isTyped: Bool            // episodeType != .standard (TMDB gave a type)
    }

    /// The finale episode fact for a season, applying the conservative rule.
    /// Returns nil when the finale is genuinely unknown (→ pending).
    static func finaleEpisode(from episodes: [EpisodeFact]) -> EpisodeFact? {
        let regular = episodes.filter { $0.episodeNumber > 0 }
        guard !regular.isEmpty else { return nil }

        // 1. Explicit finale wins.
        if let explicit = regular.first(where: { $0.isTypedFinale }) {
            return explicit
        }

        // 2. Are ANY episodes typed? If TMDB typed episodes but none is a
        //    finale, we do NOT guess — finale is unknown.
        let anyTyped = regular.contains { $0.isTyped }
        if anyTyped {
            return nil
        }

        // 3. No type info at all → legacy fallback to last episode by number.
        return regular.max(by: { $0.episodeNumber < $1.episodeNumber })
    }

    /// The confirmed finale air date, or nil if unknown (→ pending).
    static func finaleDate(from episodes: [EpisodeFact]) -> Date? {
        finaleEpisode(from: episodes)?.airDate
    }

    /// The premiere date = first regular episode's air date.
    static func premiereDate(from episodes: [EpisodeFact]) -> Date? {
        episodes
            .filter { $0.episodeNumber > 0 }
            .min(by: { $0.episodeNumber < $1.episodeNumber })?
            .airDate
    }

    // MARK: - Season Predicates

    /// Has the season started airing? (premiere date is today or past)
    static func hasStarted(episodes: [EpisodeFact], now: Date = Date()) -> Bool {
        guard let premiere = premiereDate(from: episodes) else { return false }
        return calendar.startOfDay(for: premiere) <= calendar.startOfDay(for: now)
    }

    /// Is the finale date confirmed? (drives airing vs pending)
    static func hasConfirmedFinale(episodes: [EpisodeFact]) -> Bool {
        finaleDate(from: episodes) != nil
    }

    /// Does this season have anything real behind it yet?
    ///
    /// TMDB lists a next season as soon as one is ordered — no episodes, no
    /// air date, nothing but a number. Displaying it claims a season exists
    /// when there is nothing to show. A season earns its place once it has at
    /// least one episode, or a stated air date.
    ///
    /// Show-axis only (dates and data presence). Watch marks never affect it.
    /// Anywhere seasons are listed for display, filter on this.
    static func hasPublishedData(episodes: [EpisodeFact], airDate: Date?) -> Bool {
        !episodes.isEmpty || airDate != nil
    }

    /// Has the finale-day + 1 grace window fully elapsed?
    /// True starting at the beginning of day +2 after the finale date.
    /// (Rule 2)
    static func isPastGraceWindow(finale: Date, now: Date = Date()) -> Bool {
        let finaleDay = calendar.startOfDay(for: finale)
        // bingeReady begins at start of day +2.
        guard let bingeReadyStart = calendar.date(byAdding: .day, value: 2, to: finaleDay) else {
            return false
        }
        return now >= bingeReadyStart
    }

    /// Is the season fully complete AND past the grace window?
    /// (This is the date-fact half of Binge Ready — NOT the user half.)
    static func isSeasonBingeReadyByDate(episodes: [EpisodeFact], now: Date = Date()) -> Bool {
        guard hasStarted(episodes: episodes, now: now) else { return false }
        guard let finale = finaleDate(from: episodes) else { return false }
        return isPastGraceWindow(finale: finale, now: now)
    }

    // MARK: - Season Show-State (Axis 1)

    /// Compute the ShowState for a SINGLE season from its episodes.
    /// `hasPremiereDate` distinguishes anticipated (no date) from
    /// premieringSoon (dated) for not-yet-started seasons.
    static func seasonShowState(episodes: [EpisodeFact], now: Date = Date()) -> ShowState {
        let started = hasStarted(episodes: episodes, now: now)

        if !started {
            // Not started: dated → premieringSoon, undated → anticipated.
            return premiereDate(from: episodes) != nil ? .premieringSoon : .anticipated
        }

        // Started. Do we know the finale?
        guard let finale = finaleDate(from: episodes) else {
            // Premiered, no confirmed finale → pending.
            return .pending
        }

        // Finale known. Past the grace window → bingeReady, else still airing.
        if isPastGraceWindow(finale: finale, now: now) {
            return .bingeReady
        }
        return .airing
    }

    // MARK: - Show-Level Show-State (Axis 1)

    /// A minimal season fact the show-level computation needs.
    struct SeasonFact {
        let seasonNumber: Int
        let episodes: [EpisodeFact]
        let hasWatched: Bool          // user-axis, used only for Binge Ready intersect
    }

    /// The "current" season = the one the timeline should reflect.
    /// Priority: an in-progress season (airing/pending) at the lowest number,
    /// else the next not-yet-started season, else the most recent started one.
    static func currentSeason(seasons: [SeasonFact], now: Date = Date()) -> SeasonFact? {
        let regular = seasons.filter { $0.seasonNumber > 0 }

        // 1. In-progress (started, not yet past grace window).
        let inProgress = regular.filter { s in
            let state = seasonShowState(episodes: s.episodes, now: now)
            return state == .airing || state == .pending
        }
        if let current = inProgress.min(by: { $0.seasonNumber < $1.seasonNumber }) {
            return current
        }

        // 2. Next not-yet-started season (lowest number that hasn't started).
        let notStarted = regular.filter { !hasStarted(episodes: $0.episodes, now: now) }
        if let next = notStarted.min(by: { $0.seasonNumber < $1.seasonNumber }) {
            return next
        }

        // 3. Most recently started season.
        let started = regular.filter { hasStarted(episodes: $0.episodes, now: now) }
        return started.max(by: { $0.seasonNumber < $1.seasonNumber })
    }

    /// The show-level ShowState = the state of the current season.
    /// If there is no current season at all, the show is anticipated.
    static func showState(seasons: [SeasonFact], now: Date = Date()) -> ShowState {
        guard let current = currentSeason(seasons: seasons, now: now) else {
            return .anticipated
        }
        return seasonShowState(episodes: current.episodes, now: now)
    }

    // MARK: - Binge Ready Surface (Axis 1 ∩ Axis 2) — Rule 3

    /// The single LATEST season that is bingeReady-by-date AND unwatched.
    /// This is what the Binge Ready surface shows for a given show.
    /// Returns nil if the show has no unwatched complete season.
    static func bingeReadySeason(seasons: [SeasonFact], now: Date = Date()) -> SeasonFact? {
        seasons
            .filter { $0.seasonNumber > 0 }
            .filter { !$0.hasWatched }
            .filter { isSeasonBingeReadyByDate(episodes: $0.episodes, now: now) }
            .max(by: { $0.seasonNumber < $1.seasonNumber })
    }

    /// Whether the show currently belongs on the Binge Ready surface.
    static func isOnBingeReadySurface(seasons: [SeasonFact], now: Date = Date()) -> Bool {
        bingeReadySeason(seasons: seasons, now: now) != nil
    }

    // MARK: - My List Selection (Axis 1 ∩ Axis 2) — the season you're "on"

    /// Complete-by-date AND unwatched seasons — the same predicate as Binge Ready
    /// (`bingeReadySeason` is the max of this set). Shared so MyList and Binge
    /// Ready can never disagree about what "bingeable" means (the airing↔complete
    /// boundary invariant).
    private static func bingeableUnwatchedSeasons(seasons: [SeasonFact], now: Date) -> [SeasonFact] {
        seasons
            .filter { $0.seasonNumber > 0 }
            .filter { !$0.hasWatched }
            .filter { isSeasonBingeReadyByDate(episodes: $0.episodes, now: now) }
    }

    /// The EARLIEST complete-by-date, unwatched season — the season MyList shows
    /// for a show (the one you're currently on). Still-airing seasons are excluded
    /// (they live on the Timeline). Returns nil when nothing is bingeable/unwatched.
    static func earliestBingeableUnwatchedSeason(seasons: [SeasonFact], now: Date = Date()) -> SeasonFact? {
        bingeableUnwatchedSeasons(seasons: seasons, now: now)
            .min(by: { $0.seasonNumber < $1.seasonNumber })
    }

    /// Count of complete-by-date, unwatched seasons — the MyList wallet-deck depth
    /// (how many seasons remain to catch up). Cap at 5 in the UI.
    static func bingeableUnwatchedSeasonCount(seasons: [SeasonFact], now: Date = Date()) -> Int {
        bingeableUnwatchedSeasons(seasons: seasons, now: now).count
    }

    // MARK: - Countdowns

    /// Days until the current season's premiere (nil if started/undated).
    static func daysUntilPremiere(seasons: [SeasonFact], now: Date = Date()) -> Int? {
        guard let current = currentSeason(seasons: seasons, now: now),
              let premiere = premiereDate(from: current.episodes) else { return nil }
        let startToday = calendar.startOfDay(for: now)
        let startPremiere = calendar.startOfDay(for: premiere)
        guard startPremiere >= startToday else { return nil }
        return calendar.dateComponents([.day], from: startToday, to: startPremiere).day
    }

    /// Days until the current season's finale (nil if unknown/past).
    /// Only meaningful in `.airing` — `.pending` has no finale to count to.
    static func daysUntilFinale(seasons: [SeasonFact], now: Date = Date()) -> Int? {
        guard let current = currentSeason(seasons: seasons, now: now),
              let finale = finaleDate(from: current.episodes) else { return nil }
        let startToday = calendar.startOfDay(for: now)
        let startFinale = calendar.startOfDay(for: finale)
        guard startFinale >= startToday else { return nil }
        return calendar.dateComponents([.day], from: startToday, to: startFinale).day
    }

    /// Has an episode aired?
    ///
    /// Start-of-day, like every other date comparison in this engine: an
    /// episode dated today counts as aired for the whole day, rather than
    /// flipping partway through it depending on the timestamp TMDB happened to
    /// supply. No air date means it hasn't aired.
    ///
    /// The single definition — `Episode.hasAired` and `EpisodeData.hasAired`
    /// both delegate here, so counts, tick meters and countdowns agree.
    static func hasAired(airDate: Date?, now: Date = Date()) -> Bool {
        guard let airDate else { return false }
        return calendar.startOfDay(for: airDate) <= calendar.startOfDay(for: now)
    }

    /// Episodes of the current season still to air — the episode-count
    /// counterpart to `daysUntilFinale`, for the days/episodes toggle.
    /// An episode with no air date counts as still to come.
    static func episodesUntilFinale(seasons: [SeasonFact], now: Date = Date()) -> Int? {
        guard let current = currentSeason(seasons: seasons, now: now) else { return nil }
        return current.episodes
            .filter { $0.episodeNumber > 0 }
            .filter { !hasAired(airDate: $0.airDate, now: now) }
            .count
    }

    // MARK: - My List Grouping (Axis 2, with Axis 1 override for archive)

    /// Which My List tab a show belongs in.
    ///
    /// - archived shows go to `.archived` ONLY IF they have no dated upcoming
    ///   season. A dated new season pulls them back to `.active` (timeline),
    ///   because the timeline is a show-axis fact archive can't erase.
    /// - a show with no remaining in-production seasons and everything watched
    ///   goes to `.ended`.
    /// - everything else is `.active`.
    static func myListTab(
        seasons: [SeasonFact],
        isArchived: Bool,
        isInProduction: Bool,
        now: Date = Date()
    ) -> MyListTab {
        let state = showState(seasons: seasons, now: now)

        if isArchived {
            // A dated new season overrides archive and returns to active.
            if state == .premieringSoon || state == .airing || state == .pending {
                return .active
            }
            return .archived
        }

        // Ended = not in production AND nothing left unwatched-complete AND
        // no upcoming/in-progress season.
        let hasUnwatchedComplete = bingeReadySeason(seasons: seasons, now: now) != nil
        let hasFutureOrCurrent = state == .anticipated
            || state == .premieringSoon
            || state == .airing
            || state == .pending

        if !isInProduction && !hasUnwatchedComplete && !hasFutureOrCurrent {
            return .ended
        }

        return .active
    }
}
