//
//  ShowLifecycleState.swift
//  Countdown2Binge
//

import Foundation

/// Represents the lifecycle state of a TV show.
/// Derived automatically from show data—users never set this manually.
enum ShowLifecycleState: String, Codable, CaseIterable {
    /// Show announced but no air date yet
    case anticipated

    /// Currently airing episodes
    case airing

    /// Season finished airing, ready to binge
    case completed

    /// Show was cancelled (moves to binge ready regardless of completion)
    case cancelled
}
