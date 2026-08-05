//
//  DebugSettings.swift
//  Countdown2Binge
//
//  Debug-only settings for development and testing.
//  These settings only work in DEBUG builds running on the simulator.
//

import Foundation
import SwiftUI

#if DEBUG
/// Debug settings that persist across app launches.
/// Only available in DEBUG builds.
@MainActor
@Observable
final class DebugSettings {
    static let shared = DebugSettings()

    private static let mockPendingKey = "debug_showMockPendingSection"

    /// Stored property for @Observable tracking
    private var _showMockPendingSection: Bool

    /// Toggle to show mock Pending section data in Timeline.
    /// Only works when running in the iOS Simulator.
    var showMockPendingSection: Bool {
        get { _showMockPendingSection }
        set {
            _showMockPendingSection = newValue
            UserDefaults.standard.set(newValue, forKey: Self.mockPendingKey)
        }
    }

    /// Whether mock pending data should actually be shown.
    /// Returns true only when:
    /// 1. Running in DEBUG mode (enforced by #if DEBUG)
    /// 2. Running in the iOS Simulator (enforced by #if targetEnvironment(simulator))
    /// 3. The toggle is enabled
    var shouldShowMockPendingData: Bool {
        #if targetEnvironment(simulator)
        return _showMockPendingSection
        #else
        return false
        #endif
    }

    /// Whether we're running in the simulator (for UI display purposes)
    var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private init() {
        // Load persisted value on init, defaulting to true if not set
        if UserDefaults.standard.object(forKey: Self.mockPendingKey) == nil {
            _showMockPendingSection = true
        } else {
            _showMockPendingSection = UserDefaults.standard.bool(forKey: Self.mockPendingKey)
        }
    }
}
#endif
