//
//  MyListLandscapeModel.swift
//  Countdown2Binge
//
//  Presentation model for the landscape My List cards. Built from a real
//  `Series` + its `earliestUnwatchedSeason` (see MyListLandscapeView). Kept as a
//  lightweight struct so the card views stay dumb/testable; the selection and
//  watch-time logic live in BingeEngine / Series.
//

import SwiftUI

// MARK: - Season watch state (drives the pip + tones)

/// The presentation states a season card can be in.
enum SeasonWatchState: Int, CaseIterable {
    case ready = 5       // complete, unwatched — bingeable now
    case watching = 4    // complete, partially watched
    case airing = 3      // releasing weekly (not shown in MyList — Timeline)
    case soon = 2        // premiere locked, not started
    case done = 1        // fully watched

    var label: String {
        switch self {
        case .ready: return "READY"
        case .watching: return "WATCHING"
        case .airing: return "AIRING"
        case .soon: return "SOON"
        case .done: return "WATCHED"
        }
    }

    var tone: Color {
        switch self {
        case .ready: return .c2bTealBright
        case .watching: return .c2bTeal
        case .airing: return .c2bDim
        case .soon, .done: return .c2bMuted
        }
    }

    var isReady: Bool { self == .ready }
}

// MARK: - Display model

/// One season card's worth of presentation data.
struct MyListSeasonDisplay: Identifiable {
    var id: String
    var showTitle: String
    /// Real backdrop URL (16:9). `nil` → a deterministic gradient placeholder.
    var backdropURL: URL?
    var seasonNumber: Int
    var episodeCount: Int
    var watchedCount: Int
    /// Episodes released so far (aired).
    var releasedCount: Int
    var state: SeasonWatchState
    /// Small mono status note under the title.
    var note: String
    /// Remaining complete-unwatched seasons to catch up — drives wallet-deck depth.
    var remainingSeasons: Int
    /// Full-season watch-time in seconds (sum of episode runtimes, average-filled).
    var watchTimeSeconds: Int

    init(
        id: String,
        showTitle: String,
        backdropURL: URL? = nil,
        seasonNumber: Int,
        episodeCount: Int,
        watchedCount: Int,
        releasedCount: Int? = nil,
        state: SeasonWatchState,
        note: String,
        remainingSeasons: Int = 1,
        watchTimeSeconds: Int = 0
    ) {
        self.id = id
        self.showTitle = showTitle
        self.backdropURL = backdropURL
        self.seasonNumber = seasonNumber
        self.episodeCount = episodeCount
        self.watchedCount = watchedCount
        self.releasedCount = releasedCount ?? episodeCount
        self.state = state
        self.note = note
        self.remainingSeasons = remainingSeasons
        self.watchTimeSeconds = watchTimeSeconds
    }

    // MARK: Derived

    var isReady: Bool { state.isReady }
    var isDone: Bool { state == .done }
    var allWatched: Bool { watchedCount >= episodeCount }

    /// The episode the deck-face highlights (1-based, clamped).
    var upNextEpisode: Int { min(watchedCount + 1, max(1, episodeCount)) }

    /// "SEASON COMPLETE" / "START HERE" / "UP NEXT".
    var deckSublabel: String {
        if allWatched { return "SEASON COMPLETE" }
        if watchedCount == 0 { return "START HERE" }
        return "UP NEXT"
    }

    var totalSeconds: Int { watchTimeSeconds }

    /// "~3 nights" — ~2 hours of watching per evening.
    var nightsText: String {
        let mins = watchTimeSeconds / 60
        let n = max(1, Int((Double(mins) / 120.0).rounded()))
        return n == 1 ? "1 night" : "\(n) nights"
    }

    /// Wallet-deck depth = remaining seasons to catch up, clamped 1…5.
    var stackDepth: Int { min(max(remainingSeasons, 1), 5) }
}

// MARK: - Landscape tabs

enum LandscapeListTab: String, CaseIterable, Identifiable {
    case ready, watched, archived
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ready: return "Ready"
        case .watched: return "Watched"
        case .archived: return "Archived"
        }
    }
    var desc: String {
        switch self {
        case .ready: return "Full seasons out — start one or pick up where you left off."
        case .watched: return "Seasons you've watched all the way through."
        case .archived: return "Shows you've set aside."
        }
    }
}

// MARK: - Sample data (previews only)

enum MyListLandscapeSample {
    static let active: [MyListSeasonDisplay] = [
        .init(id: "severance", showTitle: "Severance", seasonNumber: 2, episodeCount: 10,
              watchedCount: 3, state: .watching, note: "3/10 WATCHED",
              remainingSeasons: 2, watchTimeSeconds: 2887 * 10),
        .init(id: "shogun", showTitle: "Shōgun", seasonNumber: 1, episodeCount: 10,
              watchedCount: 0, state: .ready, note: "READY TO BINGE",
              remainingSeasons: 1, watchTimeSeconds: 3502 * 10),
        .init(id: "reacher", showTitle: "Reacher", seasonNumber: 3, episodeCount: 8,
              watchedCount: 0, state: .ready, note: "READY TO BINGE",
              remainingSeasons: 5, watchTimeSeconds: 2905 * 8),
    ]

    static func items(for tab: LandscapeListTab) -> [MyListSeasonDisplay] {
        tab == .ready ? active : []
    }
}
