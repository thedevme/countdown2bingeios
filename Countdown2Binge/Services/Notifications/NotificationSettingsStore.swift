//
//  NotificationSettingsStore.swift
//  Countdown2Binge
//
//  Stores global default notification settings and per-show overrides.
//

import Foundation
import Combine

@MainActor
final class NotificationSettingsStore: ObservableObject {
    static let shared = NotificationSettingsStore()

    private let defaultsKey = "c2b_notification_defaults"
    private let showSettingsKey = "c2b_notification_shows"

    /// Global default settings applied to new follows
    @Published var defaults: ShowNotificationSettings {
        didSet { saveDefaults() }
    }

    /// Per-show notification settings (keyed by show ID)
    @Published private(set) var showSettings: [Int: ShowNotificationSettings] = [:]

    private init() {
        // Load defaults
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(ShowNotificationSettings.self, from: data) {
            self.defaults = decoded
        } else {
            self.defaults = .default
        }

        // Load per-show settings
        if let data = UserDefaults.standard.data(forKey: showSettingsKey),
           let decoded = try? JSONDecoder().decode([Int: ShowNotificationSettings].self, from: data) {
            self.showSettings = decoded
        }
    }

    // MARK: - Defaults

    private func saveDefaults() {
        if let data = try? JSONEncoder().encode(defaults) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    /// Update defaults from the current settings (when "Use as Default" is checked)
    func setAsDefault(_ settings: ShowNotificationSettings) {
        defaults = settings
    }

    // MARK: - Per-Show Settings

    /// Get settings for a specific show (falls back to defaults if not set)
    func settings(for showId: Int) -> ShowNotificationSettings {
        showSettings[showId] ?? defaults
    }

    /// Save settings for a specific show
    func saveSettings(_ settings: ShowNotificationSettings, for showId: Int) {
        showSettings[showId] = settings
        saveShowSettings()
    }

    /// Remove settings for a show (e.g., when unfollowing)
    func removeSettings(for showId: Int) {
        showSettings.removeValue(forKey: showId)
        saveShowSettings()
    }

    /// Check if a show has custom settings (different from defaults)
    func hasCustomSettings(for showId: Int) -> Bool {
        showSettings[showId] != nil
    }

    private func saveShowSettings() {
        if let data = try? JSONEncoder().encode(showSettings) {
            UserDefaults.standard.set(data, forKey: showSettingsKey)
        }
    }

    // MARK: - Scheduled Notification Count

    /// Get count of scheduled notification types for a show
    func scheduledCount(for showId: Int) -> Int {
        let settings = settings(for: showId)
        var count = 0
        if settings.seasonPremiere { count += 1 }
        if settings.newEpisodes { count += 1 }
        if settings.finaleReminder { count += 1 }
        return count
    }

    /// Get description of scheduled notifications
    func scheduledDescription(for showId: Int) -> String {
        let count = scheduledCount(for: showId)
        if count == 0 {
            return String(localized: "notif_none_scheduled")
        } else if count == 1 {
            return String(localized: "notif_one_scheduled")
        } else {
            return String(localized: "notif_count_scheduled \(count)")
        }
    }
}
