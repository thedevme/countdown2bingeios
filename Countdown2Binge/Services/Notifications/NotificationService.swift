//
//  NotificationService.swift
//  Countdown2Binge
//
//  Handles notification authorization and permission status.
//  Scheduling logic is in NotificationPlanner.swift.
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

    // MARK: - Cancel

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

    // MARK: - Debug

    func listPendingNotifications() async {
        let pending = await center.pendingNotificationRequests()
        print("Pending notifications: \(pending.count)")
        for request in pending {
            print("  - \(request.identifier): \(request.content.title)")
        }
    }

    #if DEBUG
    /// Schedule a test notification that fires in a few seconds
    func scheduleTestNotification(type: TestNotificationType, delaySeconds: TimeInterval = 5) async {
        // Ensure we have permission
        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else {
                print("DEBUG: Notification permission denied")
                return
            }
        }

        let identifier = "debug-test-\(UUID().uuidString)"
        let content = UNMutableNotificationContent()
        content.sound = .default

        switch type {
        case .premiere:
            content.title = "Season Premiere Today!"
            content.body = "Stranger Things Season 5 premieres today"
        case .finale:
            content.title = "Finale Reminder"
            content.body = "Stranger Things season finale is tomorrow"
        case .bingeReady:
            content.title = "Binge Ready!"
            content.body = "The full season of Stranger Things is now available to binge"
        case .newSeason:
            content.title = "New Season Announced!"
            content.body = "Stranger Things Season 6 has been announced"
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delaySeconds, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            print("DEBUG: Test notification scheduled, fires in \(delaySeconds) seconds")
        } catch {
            print("DEBUG: Failed to schedule test notification: \(error)")
        }
    }

    enum TestNotificationType: String, CaseIterable {
        case premiere = "Premiere"
        case finale = "Finale"
        case bingeReady = "Binge Ready"
        case newSeason = "New Season"
    }
    #endif
}

// MARK: - Notification Settings (Global)

/// Global notification settings applied to ALL followed shows.
/// No per-show customization — set once at onboarding, applies everywhere.
struct NotificationSettings: Codable, Equatable {
    var seasonPremiere: Bool = true
    var finaleReminder: Bool = true
    var finaleTiming: FinaleReminderTiming = .oneDayBefore
    var bingeReady: Bool = true
    var newSeason: Bool = true

    static let `default` = NotificationSettings()
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

    /// Compute reminder date from finale date (NOT from now).
    /// "1 week before" is always finaleDate - 7 days.
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
