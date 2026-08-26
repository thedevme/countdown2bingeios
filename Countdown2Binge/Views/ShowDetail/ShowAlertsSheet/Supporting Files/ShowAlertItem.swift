//
//  ShowAlertItem.swift
//  Countdown2Binge
//
//  One notification type's status for a single show — what the alerts sheet
//  renders a row from.
//
//  Built from the app's own four NotificationTypes and the copy the planner
//  actually delivers, NOT from a parallel list. The sheet's job is to show the
//  user what they will really receive, so anything it displays has to come from
//  the same place the notification does.
//

import Foundation

struct ShowAlertItem: Identifiable {
    /// Where this alert stands for this show, in the order the design shows it.
    enum Status {
        /// Enabled, dated, still in the future.
        case scheduled(Date)
        /// Its moment has passed — it either fired or no longer applies.
        case alreadySent
        /// Enabled, but the show has no date to hang it on yet.
        case awaitingDate
        /// Switched off, for this show or for all shows.
        case turnedOff
    }

    let type: NotificationType
    let seasonNumber: Int?
    let title: String
    let body: String
    let status: Status

    var id: String { type.rawValue }

    /// True when the row should render dimmed — it isn't going to arrive.
    var isMuted: Bool {
        if case .turnedOff = status { return true }
        return false
    }
}

extension NotificationType {
    /// The badge text on the row. Uppercased by the view.
    var alertBadgeLabel: String {
        switch self {
        case .newSeason:  return String(localized: "alert_badge_new_season")
        case .premiere:   return String(localized: "alert_badge_premiere")
        case .finale:     return String(localized: "alert_badge_finale")
        case .bingeReady: return String(localized: "alert_badge_binge_ready")
        }
    }

    /// Order the sheet lists them in: the order a season actually moves through
    /// — announced, premieres, finale approaches, fully out.
    var alertSortIndex: Int {
        switch self {
        case .newSeason:  return 0
        case .premiere:   return 1
        case .finale:     return 2
        case .bingeReady: return 3
        }
    }
}
