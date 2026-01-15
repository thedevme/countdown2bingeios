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

    // MARK: - Keys

    private enum Keys {
        static let showAiringSeasonsInBingeReady = "showAiringSeasonsInBingeReady"
        static let countdownDisplayMode = "countdownDisplayMode"
    }

    private init() {
        // Load from UserDefaults
        self.showAiringSeasonsInBingeReady = UserDefaults.standard.bool(forKey: Keys.showAiringSeasonsInBingeReady)
        let rawValue = UserDefaults.standard.string(forKey: Keys.countdownDisplayMode) ?? CountdownDisplayMode.days.rawValue
        self.countdownDisplayMode = CountdownDisplayMode(rawValue: rawValue) ?? .days
    }
}
