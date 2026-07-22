//
//  TabBadgeManager.swift
//  Countdown2Binge
//
//  Manages badge state for tab bar items based on show states.
//

import Foundation
import SwiftUI

/// Determines which tab a show belongs to based on its state
enum ShowTabDestination {
    case timeline    // Now playing, premiering soon
    case bingeReady  // Ended, canceled, anticipated
    case none        // Doesn't trigger a badge

    static func from(show: ShowData) -> ShowTabDestination {
        // Ended or canceled shows go to Binge Ready
        if show.status == .ended || show.status == .canceled {
            return .bingeReady
        }

        // Planned/anticipated shows go to Binge Ready
        if show.status == .planned {
            return .bingeReady
        }

        // Returning/in-production shows with active airing go to Timeline
        if show.status == .returning || show.status == .inProduction {
            return .timeline
        }

        // Pilot shows go to Timeline
        if show.status == .pilot {
            return .timeline
        }

        return .none
    }
}

@MainActor
@Observable
final class TabBadgeManager {
    /// Shared instance for app-wide badge management
    static let shared = TabBadgeManager()

    /// Badge state for each tab
    var timelineBadge: Bool = false
    var bingeReadyBadge: Bool = false

    /// Pending badge counts (for multiple adds)
    private var pendingTimelineCount: Int = 0
    private var pendingBingeReadyCount: Int = 0

    // MARK: - Badge Actions

    /// Called when a show is followed - determines which tab to badge
    func showFollowed(_ show: ShowData) {
        let destination = ShowTabDestination.from(show: show)

        switch destination {
        case .timeline:
            timelineBadge = true
            pendingTimelineCount += 1
        case .bingeReady:
            bingeReadyBadge = true
            pendingBingeReadyCount += 1
        case .none:
            break
        }
    }

    /// Called when a show transitions from airing to binge-ready
    func showBecameBingeReady(_ show: ShowData) {
        bingeReadyBadge = true
        pendingBingeReadyCount += 1
    }

    /// Clear timeline badge (called when user visits Timeline tab)
    func clearTimelineBadge() {
        timelineBadge = false
        pendingTimelineCount = 0
    }

    /// Clear binge ready badge (called when user visits Binge Ready tab)
    func clearBingeReadyBadge() {
        bingeReadyBadge = false
        pendingBingeReadyCount = 0
    }

    /// Clear badge for a specific tab
    func clearBadge(for tabId: String) {
        switch tabId {
        case "timeline":
            clearTimelineBadge()
        case "binge":
            clearBingeReadyBadge()
        default:
            break
        }
    }

    /// Check if a tab has a badge
    func hasBadge(for tabId: String) -> Bool {
        switch tabId {
        case "timeline":
            return timelineBadge
        case "binge":
            return bingeReadyBadge
        default:
            return false
        }
    }
}
