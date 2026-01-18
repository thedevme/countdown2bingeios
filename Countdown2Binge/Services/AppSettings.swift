//
//  AppSettings.swift
//  Countdown2Binge
//

import Foundation
import SwiftUI

/// Display mode for countdown (days vs episodes)
enum CountdownDisplayMode: String, CaseIterable {
    case days
    case episodes

    var label: String {
        switch self {
        case .days: return "Days"
        case .episodes: return "Episodes"
        }
    }

    var unit: String {
        switch self {
        case .days: return "DAYS"
        case .episodes: return "EPS"
        }
    }
}

/// Centralized app settings manager using UserDefaults
@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    // MARK: - General Settings

    /// Enable/disable sound effects
    var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled)
        }
    }

    /// Enable/disable haptic feedback
    var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: Keys.hapticsEnabled)
        }
    }

    // MARK: - Binge Ready Settings

    /// When enabled, shows currently airing seasons in Binge Ready page
    var showAiringSeasonsInBingeReady: Bool {
        didSet {
            UserDefaults.standard.set(showAiringSeasonsInBingeReady, forKey: Keys.showAiringSeasonsInBingeReady)
        }
    }

    // MARK: - Timeline Settings

    /// Display mode for countdown (days or episodes until finale)
    var countdownDisplayMode: CountdownDisplayMode {
        didSet {
            UserDefaults.standard.set(countdownDisplayMode.rawValue, forKey: Keys.countdownDisplayMode)
        }
    }

    // MARK: - Notification Settings

    /// Whether global notification defaults are enabled (skip per-show modal)
    var useGlobalNotificationDefaults: Bool {
        didSet {
            UserDefaults.standard.set(useGlobalNotificationDefaults, forKey: Keys.useGlobalNotificationDefaults)
        }
    }

    /// Global notification defaults applied to all new shows
    var globalNotificationDefaults: NotificationSettings {
        didSet {
            if let encoded = try? JSONEncoder().encode(globalNotificationDefaults) {
                UserDefaults.standard.set(encoded, forKey: Keys.globalNotificationDefaults)
            }
        }
    }

    // MARK: - Keys

    private enum Keys {
        static let soundEnabled = "soundEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let showAiringSeasonsInBingeReady = "showAiringSeasonsInBingeReady"
        static let countdownDisplayMode = "countdownDisplayMode"
        static let useGlobalNotificationDefaults = "useGlobalNotificationDefaults"
        static let globalNotificationDefaults = "globalNotificationDefaults"
    }

    private init() {
        // Load from UserDefaults (defaults to true for sound/haptics)
        self.soundEnabled = UserDefaults.standard.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.hapticsEnabled = UserDefaults.standard.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        self.showAiringSeasonsInBingeReady = UserDefaults.standard.bool(forKey: Keys.showAiringSeasonsInBingeReady)
        let rawValue = UserDefaults.standard.string(forKey: Keys.countdownDisplayMode) ?? CountdownDisplayMode.days.rawValue
        self.countdownDisplayMode = CountdownDisplayMode(rawValue: rawValue) ?? .days

        // Notification defaults
        self.useGlobalNotificationDefaults = UserDefaults.standard.bool(forKey: Keys.useGlobalNotificationDefaults)
        if let data = UserDefaults.standard.data(forKey: Keys.globalNotificationDefaults),
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.globalNotificationDefaults = decoded
        } else {
            self.globalNotificationDefaults = .default
        }
    }
}
