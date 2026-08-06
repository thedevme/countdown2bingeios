//
//  NotificationSettingsStore.swift
//  Countdown2Binge
//
//  Stores GLOBAL notification settings applied to ALL followed shows.
//  No per-show customization — set once at onboarding, applies everywhere.
//

import Foundation
import Combine

@MainActor
final class NotificationSettingsStore: ObservableObject {
    static let shared = NotificationSettingsStore()

    private let settingsKey = "c2b_notification_settings"
    private let onboardingCompleteKey = "c2b_notification_onboarding_complete"

    /// Whether the user has completed the one-time notification onboarding
    @Published private(set) var hasCompletedOnboarding: Bool

    /// Global settings applied to ALL shows
    @Published var settings: NotificationSettings {
        didSet { save() }
    }

    private init() {
        // Load onboarding state
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingCompleteKey)

        // Load settings
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    // MARK: - Onboarding

    /// Mark the one-time notification onboarding as complete
    func markOnboardingComplete() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingCompleteKey)
    }

    /// Reset onboarding (for testing/debug)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: onboardingCompleteKey)
    }

    // MARK: - Settings

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    /// Update settings (from onboarding or settings screen)
    func updateSettings(_ newSettings: NotificationSettings) {
        settings = newSettings
    }

    // MARK: - Scheduled Notification Count

    /// Get count of enabled notification types
    var enabledCount: Int {
        var count = 0
        if settings.seasonPremiere { count += 1 }
        if settings.finaleReminder { count += 1 }
        if settings.bingeReady { count += 1 }
        if settings.newSeason { count += 1 }
        return count
    }

    /// Get description of enabled notifications
    var enabledDescription: String {
        let count = enabledCount
        if count == 0 {
            return String(localized: "notif_none_enabled")
        } else if count == 1 {
            return String(localized: "notif_one_enabled")
        } else {
            return String(localized: "notif_count_enabled \(count)")
        }
    }
}
