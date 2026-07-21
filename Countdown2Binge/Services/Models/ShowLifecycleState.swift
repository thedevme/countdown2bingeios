//
//  ShowLifecycleState.swift
//  Countdown2Binge
//
//  Defines the 4 lifecycle states for shows.
//  These are derived automatically from TMDB data, never set manually.
//

import Foundation

/// Lifecycle state of a show - derived from TMDB data
enum ShowLifecycleState: String, Codable, Sendable {
    /// Show announced but no air date yet, or between seasons
    case anticipated

    /// Currently airing episodes
    case airing

    /// User has watched all available episodes
    case completed

    /// Show is no longer in production (finished or cancelled)
    case ended

    /// Show was cancelled
    case cancelled
}

/// Timeline category for UI display
enum TimelineCategory: String, Codable, Sendable {
    /// Completed or cancelled shows - ready to watch
    case bingeReady

    /// Currently releasing episodes
    case airingNow

    /// Has known premiere date in the future
    case premieringSoon

    /// No date announced (TBD)
    case anticipated

    var displayName: String {
        switch self {
        case .bingeReady: return "BINGE READY"
        case .airingNow: return "NOW AIRING"
        case .premieringSoon: return "PREMIERING SOON"
        case .anticipated: return "ANTICIPATED"
        }
    }

    var sortOrder: Int {
        switch self {
        case .airingNow: return 0
        case .premieringSoon: return 1
        case .anticipated: return 2
        case .bingeReady: return 3
        }
    }
}
