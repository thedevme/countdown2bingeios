//
//  ShowState.swift
//  Countdown2Binge
//
//  The two-axis state model for a followed show.
//
//  AXIS 1 — ShowState: a fact about the world, computed purely from TMDB
//           season/episode air dates. The user's watch history has ZERO
//           influence on it.
//
//  AXIS 2 — UserState: a fact about the person, driven purely by what they
//           have marked. Knows nothing about air dates.
//
//  "Binge Ready" as a user-facing surface is the INTERSECTION of the two:
//  ShowState.bingeReady  AND  UserState.unwatched.
//

import Foundation

// MARK: - Axis 1: Show State (date-driven)

/// Where a show sits in its airing lifecycle, computed from air dates only.
///
/// Progression for a season:
///   anticipated → premieringSoon → (airing | pending) → bingeReady
///
/// - `anticipated`:   A next season is expected but has NO premiere date yet.
/// - `premieringSoon`: The next season HAS a premiere date and hasn't started.
/// - `airing`:        Season has premiered AND has a confirmed finale date
///                    (so a real finale countdown can be shown). Also covers
///                    the finale-day + 1 grace window (see BingeEngine).
/// - `pending`:       Season has premiered but has NO confirmed finale date.
///                    It's running, but we can't count down to an unknown end.
/// - `bingeReady`:    The finale has aired and the grace window has elapsed —
///                    the season is complete and watchable in full.
enum ShowState: String, Codable, Sendable, CaseIterable {
    case anticipated
    case premieringSoon
    case airing
    case pending
    case bingeReady

    /// Whether this state should appear on the main timeline.
    /// Binge Ready is NOT a timeline state — it's its own surface.
    var appearsOnTimeline: Bool {
        switch self {
        case .anticipated, .premieringSoon, .airing, .pending:
            return true
        case .bingeReady:
            return false
        }
    }
}

// MARK: - Axis 2: User State (mark-driven)

/// What the user has done with a show. Independent of air dates.
///
/// - `unwatched`: The user has not marked the latest complete season watched.
/// - `watched`:   The user has marked the latest complete season watched.
///                (Per-season watched flags live on `Season.hasWatched`; this
///                enum reflects the show as a whole for the latest season.)
/// - `archived`:  The user manually filed the show away. Suppresses user-axis
///                surfaces (Binge Ready, My List active), but a DATED new
///                season can still pull the show back onto the timeline —
///                because the timeline is show-axis, not user-axis.
enum UserState: String, Codable, Sendable, CaseIterable {
    case unwatched
    case watched
    case archived
}

// MARK: - My List Tab (user-facing grouping)

/// The three tabs on the My List screen. This is a user-axis grouping.
enum MyListTab: String, Codable, Sendable, CaseIterable {
    case active
    case ended
    case archived
}
