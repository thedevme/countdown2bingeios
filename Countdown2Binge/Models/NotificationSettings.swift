//
//  NotificationSettings.swift
//  Countdown2Binge
//

import Foundation

/// Reminder timing options for finale notifications
enum FinaleReminderTiming: String, CaseIterable, Codable {
    case dayOf = "day_of"
    case oneDayBefore = "1_day_before"
    case twoDaysBefore = "2_days_before"
    case oneWeekBefore = "1_week_before"

    var label: String {
        switch self {
        case .dayOf: return "DAY OF"
        case .oneDayBefore: return "1 DAY BEFORE"
        case .twoDaysBefore: return "2 DAYS BEFORE"
        case .oneWeekBefore: return "1 WEEK BEFORE"
        }
    }
}

/// Notification settings for a show or global defaults
struct NotificationSettings: Codable, Equatable {
    /// Notify when a new season premieres
    var seasonPremiere: Bool = true

    /// Notify when new episodes drop
    var newEpisodes: Bool = true

    /// Notify before the finale
    var finaleReminder: Bool = true

    /// When to send finale reminder
    var finaleReminderTiming: FinaleReminderTiming = .oneDayBefore

    /// Notify when all episodes are available (binge-ready)
    var seasonBingeReady: Bool = true

    /// Enable quiet hours for this show
    var quietHoursEnabled: Bool = false

    /// Quiet hours start time (stored as hour * 60 + minute)
    var quietHoursStart: Int = 22 * 60 // 10:00 PM

    /// Quiet hours end time (stored as hour * 60 + minute)
    var quietHoursEnd: Int = 8 * 60 // 8:00 AM

    // MARK: - Computed Properties

    var quietHoursStartDate: Date {
        get {
            let hour = quietHoursStart / 60
            let minute = quietHoursStart % 60
            return Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            quietHoursStart = (components.hour ?? 22) * 60 + (components.minute ?? 0)
        }
    }

    var quietHoursEndDate: Date {
        get {
            let hour = quietHoursEnd / 60
            let minute = quietHoursEnd % 60
            return Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            quietHoursEnd = (components.hour ?? 8) * 60 + (components.minute ?? 0)
        }
    }

    var quietHoursStartFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: quietHoursStartDate)
    }

    var quietHoursEndFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: quietHoursEndDate)
    }

    // MARK: - Default Instance

    static let `default` = NotificationSettings()
}
