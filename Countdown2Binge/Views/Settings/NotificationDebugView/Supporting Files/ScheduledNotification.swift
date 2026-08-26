//
//  ScheduledNotification.swift
//  Countdown2Binge
//
//  DEBUG ONLY — a parsed view of one pending UNNotificationRequest.
//
//  Identifiers are structured by NotificationPlanner as
//  `show-{showId}-{type}-s{season}`, so they can be read back apart to say
//  which show and which event a scheduled notification belongs to.
//

#if DEBUG

import Foundation
import UserNotifications

struct ScheduledNotification: Identifiable {
    let id: String            // the raw identifier
    let showId: Int?
    let kind: String          // premiere / finale / bingeready / newseason
    let seasonNumber: Int?
    let title: String
    let body: String
    let fireDate: Date?

    /// Nil showId means the identifier didn't follow the `show-{id}-…` shape —
    /// a debug test notification, or something scheduled by older code.
    var isShowNotification: Bool { showId != nil }

    var kindLabel: String {
        switch kind {
        case "premiere":   return "Premiere"
        case "finale":     return "Finale"
        case "bingeready": return "Binge Ready"
        case "newseason":  return "New Season"
        default:           return kind.isEmpty ? "Unknown" : kind
        }
    }

    var fireDateLabel: String {
        guard let fireDate else { return "no trigger date" }
        let absolute = fireDate.formatted(date: .abbreviated, time: .shortened)
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        return "\(absolute) · \(relative.localizedString(for: fireDate, relativeTo: Date()))"
    }

    /// True when the trigger has already passed — it should have fired and been
    /// cleared, so seeing one here means something didn't get cleaned up.
    var isStale: Bool {
        guard let fireDate else { return false }
        return fireDate < Date()
    }

    init(request: UNNotificationRequest) {
        self.id = request.identifier
        self.title = request.content.title
        self.body = request.content.body

        // show-123-finale-s2
        let parts = request.identifier.split(separator: "-")
        if parts.count >= 3, parts[0] == "show", let id = Int(parts[1]) {
            self.showId = id
            self.kind = String(parts[2])
            if parts.count >= 4, parts[3].hasPrefix("s") {
                self.seasonNumber = Int(parts[3].dropFirst())
            } else {
                self.seasonNumber = nil
            }
        } else {
            self.showId = nil
            self.kind = ""
            self.seasonNumber = nil
        }

        if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
            self.fireDate = calendarTrigger.nextTriggerDate()
        } else if let intervalTrigger = request.trigger as? UNTimeIntervalNotificationTrigger {
            self.fireDate = intervalTrigger.nextTriggerDate()
        } else {
            self.fireDate = nil
        }
    }
}

#endif
