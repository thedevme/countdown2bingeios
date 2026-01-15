//
//  ShowLifecycleManager.swift
//  Countdown2Binge
//

import Foundation

/// Derives lifecycle state from show data.
/// Users never set state manually—it's always computed from TMDB data.
protocol ShowLifecycleManagerProtocol {
    func deriveState(for show: Show) -> ShowLifecycleState
    func deriveState(for show: Show, season: Season) -> ShowLifecycleState
}

final class ShowLifecycleManager: ShowLifecycleManagerProtocol {

    /// Derive the lifecycle state for a show's current season
    func deriveState(for show: Show) -> ShowLifecycleState {
        // Cancelled shows are always binge-ready
        if show.status == .cancelled {
            return .cancelled
        }

        // Ended shows are complete
        if show.status == .ended {
            return .completed
        }

        // Check the current season's state
        guard let currentSeason = show.currentSeason else {
            // No seasons yet = anticipated
            return .anticipated
        }

        return deriveState(for: show, season: currentSeason)
    }

    /// Derive the lifecycle state for a specific season
    func deriveState(for show: Show, season: Season) -> ShowLifecycleState {
        // Cancelled shows are always binge-ready, regardless of season state
        if show.status == .cancelled {
            return .cancelled
        }

        // Season hasn't started airing
        if !season.hasStarted {
            return .anticipated
        }

        // Season is complete (all episodes aired)
        if season.isComplete {
            return .completed
        }

        // Season has started but isn't complete
        return .airing
    }
}

// MARK: - Show Extensions for Convenience

extension Show {
    /// Computed lifecycle state using the default manager
    var lifecycleState: ShowLifecycleState {
        ShowLifecycleManager().deriveState(for: self)
    }

    /// Check if show is ready to binge (completed or cancelled)
    var isBingeReady: Bool {
        let state = lifecycleState
        return state == .completed || state == .cancelled
    }

    /// Days until the current season finale
    var daysUntilFinale: Int? {
        currentSeason?.daysUntilFinale
    }

    /// Episodes until the current season finale
    var episodesUntilFinale: Int? {
        currentSeason?.episodesUntilFinale
    }

    /// Days until the next season premiere
    var daysUntilPremiere: Int? {
        upcomingSeason?.daysUntilPremiere ?? currentSeason?.daysUntilPremiere
    }
}
