//
//  NotificationService.swift
//  Countdown2Binge
//
//  Handles local notification scheduling for show reminders.
//

import Foundation
import Combine
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task { await checkAuthorizationStatus() }
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    // MARK: - Scheduling

    /// Schedule all notifications for a show based on settings
    func scheduleNotifications(for show: ShowData, settings: ShowNotificationSettings) async {
        // First ensure we have permission
        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        // Cancel existing notifications for this show
        await cancelNotifications(for: show.id)

        // Schedule based on settings
        if settings.seasonPremiere {
            await schedulePremiereNotification(for: show)
        }

        if settings.newEpisodes {
            await scheduleEpisodeNotifications(for: show)
        }

        if settings.finaleReminder {
            await scheduleFinaleNotification(for: show, timing: settings.finaleTiming)
        }
    }

    /// Cancel all notifications for a show
    func cancelNotifications(for showId: Int) async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .filter { $0.identifier.hasPrefix("show-\(showId)-") }
            .map { $0.identifier }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Cancel all notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Private Scheduling Methods

    private func schedulePremiereNotification(for show: ShowData) async {
        guard let season = show.anticipatedSeason ?? show.currentSeason,
              let premiereDate = season.premiereDate,
              premiereDate > Date() else { return }

        let identifier = "show-\(show.id)-premiere-s\(season.seasonNumber)"

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif_premiere_alert_title")
        content.body = String(localized: "notif_premiere_alert_body \(show.name) \(season.seasonNumber)")
        content.sound = .default
        content.userInfo = ["showId": show.id, "type": "premiere"]

        // Schedule for 9 AM on premiere day
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: premiereDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule premiere notification: \(error)")
        }
    }

    private func scheduleEpisodeNotifications(for show: ShowData) async {
        guard let season = show.currentSeason else { return }

        // Get episodes with air dates in the future
        let futureEpisodes = season.episodes.filter { episode in
            guard let airDate = episode.airDate else { return false }
            return airDate > Date()
        }

        for episode in futureEpisodes.prefix(10) { // Limit to next 10 episodes
            guard let airDate = episode.airDate else { continue }

            let identifier = "show-\(show.id)-episode-s\(season.seasonNumber)e\(episode.episodeNumber)"

            let content = UNMutableNotificationContent()
            content.title = String(localized: "notif_episode_alert_title \(show.name)")
            content.body = String(localized: "notif_episode_alert_body \(episode.episodeNumber) \(episode.name)")
            content.sound = .default
            content.userInfo = ["showId": show.id, "type": "episode", "season": season.seasonNumber, "episode": episode.episodeNumber]

            // Schedule for 9 AM on air date
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: airDate)
            dateComponents.hour = 9
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule episode notification: \(error)")
            }
        }
    }

    private func scheduleFinaleNotification(for show: ShowData, timing: FinaleReminderTiming) async {
        guard let season = show.currentSeason,
              let finaleDate = season.finaleDate,
              finaleDate > Date() else { return }

        let reminderDate = timing.reminderDate(before: finaleDate)
        guard reminderDate > Date() else { return }

        let identifier = "show-\(show.id)-finale-s\(season.seasonNumber)"

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif_finale_alert_title")
        content.body = String(localized: "notif_finale_alert_body \(show.name) \(timing.displayText)")
        content.sound = .default
        content.userInfo = ["showId": show.id, "type": "finale"]

        // Schedule for 9 AM on reminder date
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule finale notification: \(error)")
        }
    }

    // MARK: - Debug

    func listPendingNotifications() async {
        let pending = await center.pendingNotificationRequests()
        print("Pending notifications: \(pending.count)")
        for request in pending {
            print("  - \(request.identifier): \(request.content.title)")
        }
    }
}

// MARK: - Show Notification Settings

struct ShowNotificationSettings: Codable, Equatable {
    var seasonPremiere: Bool = true
    var newEpisodes: Bool = true
    var finaleReminder: Bool = true
    var finaleTiming: FinaleReminderTiming = .oneDayBefore

    static let `default` = ShowNotificationSettings()
}

// MARK: - Finale Reminder Timing

enum FinaleReminderTiming: String, Codable, CaseIterable {
    case dayOf = "day_of"
    case oneDayBefore = "1_day"
    case twoDaysBefore = "2_days"
    case oneWeekBefore = "1_week"

    var displayText: String {
        switch self {
        case .dayOf: return String(localized: "finale_timing_day_of")
        case .oneDayBefore: return String(localized: "finale_timing_1_day")
        case .twoDaysBefore: return String(localized: "finale_timing_2_days")
        case .oneWeekBefore: return String(localized: "finale_timing_1_week")
        }
    }

    var shortText: String {
        switch self {
        case .dayOf: return "DAY OF"
        case .oneDayBefore: return "1 DAY BEFORE"
        case .twoDaysBefore: return "2 DAYS BEFORE"
        case .oneWeekBefore: return "1 WEEK BEFORE"
        }
    }

    func reminderDate(before date: Date) -> Date {
        switch self {
        case .dayOf:
            return date
        case .oneDayBefore:
            return Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        case .twoDaysBefore:
            return Calendar.current.date(byAdding: .day, value: -2, to: date) ?? date
        case .oneWeekBefore:
            return Calendar.current.date(byAdding: .day, value: -7, to: date) ?? date
        }
    }
}
