//
//  LocaleFormatters.swift
//  Countdown2Binge
//
//  Locale-aware date and number formatters for proper internationalization.
//

import Foundation

// MARK: - Date Formatters

enum LocaleFormatters {

    // MARK: - Cached Formatters

    /// Full date with weekday: "Mon, Jan 5" / "lun. 5 janv." / "月, 1月5日"
    private static let weekdayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
        return formatter
    }()

    /// Short date without weekday: "Jan 5" / "5 janv." / "1月5日"
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()

    /// Full date with year: "Jan 5, 2026" / "5 janv. 2026" / "2026年1月5日"
    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d yyyy")
        return formatter
    }()

    /// Year only: "2026"
    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        return formatter
    }()

    /// Number formatter for counts (episodes, seasons, days)
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    // MARK: - Date Formatting

    /// Format date with weekday: "Mon, Jan 5" (localized)
    static func weekdayDate(_ date: Date) -> String {
        weekdayDateFormatter.string(from: date)
    }

    /// Format short date: "Jan 5" (localized)
    static func shortDate(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    /// Format full date with year: "Jan 5, 2026" (localized)
    static func fullDate(_ date: Date) -> String {
        fullDateFormatter.string(from: date)
    }

    /// Format year only: "2026"
    static func year(_ date: Date) -> String {
        yearFormatter.string(from: date)
    }

    // MARK: - Number Formatting

    /// Format a number with locale-appropriate grouping: "1,234" / "1.234" / "1 234"
    static func number(_ value: Int) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Runtime Formatting

    /// Format runtime in minutes to localized hours/minutes
    /// Examples: "45m" / "45min" / "45分", "1h 30m" / "1h 30min" / "1時間30分"
    static func runtime(_ minutes: Int) -> String {
        guard minutes > 0 else { return "" }

        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins > 0 {
                return String(localized: "runtime_hours_minutes \(hours) \(mins)")
            }
            return String(localized: "runtime_hours_only \(hours)")
        }
        return String(localized: "runtime_minutes_only \(minutes)")
    }
}

// MARK: - Date Extension

extension Date {
    /// Formatted with weekday: "Mon, Jan 5" (localized)
    var localizedWeekdayDate: String {
        LocaleFormatters.weekdayDate(self)
    }

    /// Formatted short: "Jan 5" (localized)
    var localizedShortDate: String {
        LocaleFormatters.shortDate(self)
    }

    /// Formatted with year: "Jan 5, 2026" (localized)
    var localizedFullDate: String {
        LocaleFormatters.fullDate(self)
    }

    /// Year only: "2026"
    var localizedYear: String {
        LocaleFormatters.year(self)
    }
}

// MARK: - Int Extension for Formatting

extension Int {
    /// Formatted with locale grouping: "1,234" / "1.234"
    var localizedNumber: String {
        LocaleFormatters.number(self)
    }

    /// Formatted as runtime: "45m" / "1h 30m" (localized)
    var localizedRuntime: String {
        LocaleFormatters.runtime(self)
    }
}
