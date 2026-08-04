//
//  CloudSettingsStore.swift
//  Countdown2Binge
//
//  Stores user settings in iCloud using NSUbiquitousKeyValueStore.
//  Syncs automatically across devices signed into the same iCloud account.
//

import Foundation

@MainActor
@Observable
final class CloudSettingsStore {
    static let shared = CloudSettingsStore()

    private let store = NSUbiquitousKeyValueStore.default

    // MARK: - Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasSeenWalkthrough = "hasSeenWalkthrough"
    }

    // MARK: - Properties

    var hasCompletedOnboarding: Bool {
        get { store.bool(forKey: Keys.hasCompletedOnboarding) }
        set {
            store.set(newValue, forKey: Keys.hasCompletedOnboarding)
            store.synchronize()
        }
    }

    var hasSeenWalkthrough: Bool {
        get { store.bool(forKey: Keys.hasSeenWalkthrough) }
        set {
            store.set(newValue, forKey: Keys.hasSeenWalkthrough)
            store.synchronize()
        }
    }

    // MARK: - Init

    private init() {
        // Sync from iCloud on launch
        store.synchronize()

        // Listen for changes from other devices
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            // Trigger UI update by accessing properties
            _ = self?.hasCompletedOnboarding
            _ = self?.hasSeenWalkthrough
        }
    }

    // MARK: - Reset

    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasSeenWalkthrough = false
    }
}
