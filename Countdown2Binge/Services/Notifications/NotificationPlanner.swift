//
//  NotificationPlanner.swift
//  Countdown2Binge
//
//  Pure notification planning logic. No side effects.
//  Takes dates + settings + now → returns what SHOULD be scheduled.
//

import Foundation
import UserNotifications
import os

// MARK: - Notification Logging

/// Logs to both the unified log (filterable in Console.app / `log stream`) and
/// stdout (visible in Xcode's console). Registration = a UNNotificationRequest
/// added; deregistration = a pending request removed.
nonisolated func logNotif(_ message: String) {
    Logger(subsystem: "com.countdown2binge", category: "notifications")
        .log("\(message, privacy: .public)")
    print("🔔[Notifications] \(message)")
}

// MARK: - Notification Types

enum NotificationType: String, Codable, CaseIterable {
    case premiere
    case finale
    case bingeReady
    case newSeason
}

// MARK: - Data Types

/// Input: dates extracted from Series (not ShowData)
struct ShowDateInfo {
    let showId: Int
    let showName: String
    let currentSeasonNumber: Int?
    let premiereDate: Date?
    let finaleDate: Date?        // nil if pending (no confirmed finale)
}

/// Output: what to schedule
nonisolated struct NotificationPlan: Equatable {
    let identifier: String       // stable key: "show-123-finale-s2"
    let type: NotificationType
    let showId: Int
    let showName: String
    let fireDate: Date
    let seasonNumber: Int?
}

// MARK: - Pure Planning Function

/// Pure, testable function. No side effects.
/// Given dates + settings + now → returns what SHOULD be scheduled.
///
/// NOTE: the finale alert fires ON the finale date, and binge-ready 24 hours
/// after it. No offsets are subtracted from either — the dates come straight
/// from TMDB and only the hour is stamped (noon, see `scheduleOne`).
func planNotifications(
    dates: ShowDateInfo,
    settings: NotificationSettings,
    now: Date,
    bingeReadyDelayDays: Int = 1
) -> [NotificationPlan] {
    var plans: [NotificationPlan] = []

    guard let seasonNum = dates.currentSeasonNumber else { return plans }

    // PREMIERE — if enabled, date exists, date is in future
    if settings.seasonPremiere,
       let premiere = dates.premiereDate,
       premiere > now {
        plans.append(NotificationPlan(
            identifier: "show-\(dates.showId)-premiere-s\(seasonNum)",
            type: .premiere,
            showId: dates.showId,
            showName: dates.showName,
            fireDate: premiere,
            seasonNumber: seasonNum
        ))
    }

    // FINALE — if enabled, date exists, and it hasn't already passed.
    // Fires ON the finale date at noon. `settings.finaleTiming` is deliberately
    // NOT applied: subtracting a day put the alert out before the episode
    // existed, and the pair (finale, then binge-ready 24h later) only reads
    // correctly if the first one lands on the day itself.
    if settings.finaleReminder,
       let finale = dates.finaleDate {
        let reminderDate = finale
        if reminderDate > now {
            plans.append(NotificationPlan(
                identifier: "show-\(dates.showId)-finale-s\(seasonNum)",
                type: .finale,
                showId: dates.showId,
                showName: dates.showName,
                fireDate: reminderDate,
                seasonNumber: seasonNum
            ))
        }
    }

    // BINGE READY — if enabled, finale date exists, binge date is in future.
    // 24 hours after the finale, which lands at noon the following day once
    // the scheduler stamps the hour. NOT the engine's grace window: that one
    // governs how long a finished season lingers on the timeline before moving
    // to My List, and is a separate question from when we tell the user.
    if settings.bingeReady,
       let finale = dates.finaleDate {
        let bingeDate = Calendar.current.date(
            byAdding: .day, value: bingeReadyDelayDays, to: finale
        )!
        if bingeDate > now {
            plans.append(NotificationPlan(
                identifier: "show-\(dates.showId)-bingeready-s\(seasonNum)",
                type: .bingeReady,
                showId: dates.showId,
                showName: dates.showName,
                fireDate: bingeDate,
                seasonNumber: seasonNum
            ))
        }
    }

    // NOTE: newSeason is event-driven, not planned here.
    // It fires once on detection in refresh/follow.

    return plans
}

// MARK: - Date Extraction from Series

/// Extract notification-relevant dates from Series.
/// Uses BingeEngine for currentSeason and conservative finale detection.
func extractDateInfo(from series: Series, now: Date) -> ShowDateInfo {
    let facts = series.regularSeasons.map { season in
        BingeEngine.SeasonFact(
            seasonNumber: season.seasonNumber,
            episodes: season.episodeFacts,
            hasWatched: season.hasWatched
        )
    }

    let currentSeason = BingeEngine.currentSeason(seasons: facts, now: now)

    let premiereDate: Date? = {
        guard let num = currentSeason?.seasonNumber,
              let season = series.regularSeasons.first(where: { $0.seasonNumber == num })
        else { return nil }
        return season.episodes.compactMap { $0.airDate }.min()
    }()

    // Conservative finale: only if BingeEngine confirms it
    let finaleDate: Date? = {
        guard let num = currentSeason?.seasonNumber,
              let season = series.regularSeasons.first(where: { $0.seasonNumber == num })
        else { return nil }
        return BingeEngine.finaleEpisode(from: season.episodeFacts)?.airDate
    }()

    return ShowDateInfo(
        showId: series.id,
        showName: series.name,
        currentSeasonNumber: currentSeason?.seasonNumber,
        premiereDate: premiereDate,
        finaleDate: finaleDate
    )
}

// MARK: - Notification Scheduler (Thin Executor)

/// Manages scheduling with change detection.
/// Schedule-once / update-only-on-change pattern.
actor NotificationScheduler {
    private let center = UNUserNotificationCenter.current()

    /// Apply a set of plans, only changing what's different.
    /// Scoped to THIS show's identifier prefix only.
    func applyPlans(_ plans: [NotificationPlan], for showId: Int) async {
        // Build map of what SHOULD exist: identifier → fireDate
        let desired: [String: NotificationPlan] = Dictionary(
            uniqueKeysWithValues: plans.map { ($0.identifier, $0) }
        )

        // Get what currently exists FOR THIS SHOW ONLY
        let prefix = "show-\(showId)-"
        let pending = await center.pendingNotificationRequests()
        let existing: [String: Date] = Dictionary(uniqueKeysWithValues:
            pending
                .filter { $0.identifier.hasPrefix(prefix) }
                .compactMap { request -> (String, Date)? in
                    guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                          let date = trigger.nextTriggerDate()
                    else { return nil }
                    return (request.identifier, date)
                }
        )

        var toCancel: [String] = []
        var toAdd: [NotificationPlan] = []

        // Check each desired notification
        for plan in plans {
            if let existingDate = existing[plan.identifier] {
                // Already scheduled — check if date changed (same day = leave it)
                if !Calendar.current.isDate(existingDate, inSameDayAs: plan.fireDate) {
                    // Date changed: cancel old, add new
                    toCancel.append(plan.identifier)
                    toAdd.append(plan)
                }
                // Same date: leave it alone
            } else {
                // Not scheduled yet: add it
                toAdd.append(plan)
            }
        }

        // Check for notifications that should no longer exist
        // SCOPED TO THIS SHOW'S PREFIX ONLY
        for identifier in existing.keys {
            if desired[identifier] == nil {
                toCancel.append(identifier)
            }
        }

        // Execute changes
        if !toCancel.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: toCancel)
            for id in toCancel { logNotif("➖ DEREGISTER \(id)") }
        }

        for plan in toAdd {
            await scheduleOne(plan)
        }

        if toCancel.isEmpty && toAdd.isEmpty {
            logNotif("• no change for show-\(showId) (\(desired.count) desired, already in sync)")
        }
    }

    /// Cancel all notifications for a specific show
    func cancelAll(for showId: Int) async {
        let prefix = "show-\(showId)-"
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .filter { $0.identifier.hasPrefix(prefix) }
            .map { $0.identifier }

        if !identifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            logNotif("➖ DEREGISTER ALL for show-\(showId): \(identifiers.joined(separator: ", "))")
        }
    }

    /// Check if a newSeason notification has already been fired/scheduled
    func hasNewSeasonFired(showId: Int, seasonNumber: Int) async -> Bool {
        let identifier = "show-\(showId)-newseason-s\(seasonNumber)"

        // Check pending
        let pending = await center.pendingNotificationRequests()
        if pending.contains(where: { $0.identifier == identifier }) {
            return true
        }

        // Check delivered
        let delivered = await center.deliveredNotifications()
        if delivered.contains(where: { $0.request.identifier == identifier }) {
            return true
        }

        return false
    }

    /// Fire an immediate notification (for newSeason event)
    func fireImmediate(_ plan: NotificationPlan) async {
        let content = UNMutableNotificationContent()
        content.title = title(for: plan)
        content.body = body(for: plan)
        content.sound = .default
        content.userInfo = [
            "showId": plan.showId,
            "type": plan.type.rawValue
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1, repeats: false
        )

        let request = UNNotificationRequest(
            identifier: plan.identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            logNotif("🔔 FIRE-NOW \(plan.identifier) — \(plan.showName)")
        } catch {
            logNotif("⚠️ FAILED to fire \(plan.identifier): \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private func scheduleOne(_ plan: NotificationPlan) async {
        let content = UNMutableNotificationContent()
        content.title = title(for: plan)
        content.body = body(for: plan)
        content.sound = .default
        content.userInfo = [
            "showId": plan.showId,
            "type": plan.type.rawValue
        ]

        // Fire at noon local on the fire date. TMDB carries no air time — its
        // air_date is date-only — so there is no real release time to honour.
        // Noon is late enough that a same-day release has landed in most
        // places, and it never buzzes anyone overnight. A show that airs in
        // the evening is simply announced a few hours early; for a binge
        // tracker "the season is complete" is the message, not "it's starting".
        var components = Calendar.current.dateComponents(
            [.year, .month, .day], from: plan.fireDate
        )
        components.hour = 12
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components, repeats: false
        )

        let request = UNNotificationRequest(
            identifier: plan.identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            let when = plan.fireDate.formatted(date: .abbreviated, time: .omitted)
            logNotif("➕ REGISTER \(plan.identifier) — \(title(for: plan)) · fires \(when) 12PM · \(plan.showName)")
        } catch {
            logNotif("⚠️ FAILED to register \(plan.identifier): \(error.localizedDescription)")
        }
    }

    private func title(for plan: NotificationPlan) -> String {
        switch plan.type {
        case .premiere:
            return String(localized: "notif_premiere_title")
        case .finale:
            return String(localized: "notif_finale_title")
        case .bingeReady:
            return String(localized: "notif_bingeready_title")
        case .newSeason:
            return String(localized: "notif_newseason_title")
        }
    }

    private func body(for plan: NotificationPlan) -> String {
        switch plan.type {
        case .premiere:
            return String(localized: "notif_premiere_body \(plan.showName)")
        case .finale:
            return String(localized: "notif_finale_body \(plan.showName)")
        case .bingeReady:
            return String(localized: "notif_bingeready_body \(plan.showName)")
        case .newSeason:
            let season = plan.seasonNumber ?? 0
            return String(localized: "notif_newseason_body \(plan.showName) \(season)")
        }
    }
}
