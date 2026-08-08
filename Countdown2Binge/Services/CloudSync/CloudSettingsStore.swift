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

    // Stored (not computed) so @Observable tracks them and SwiftUI reacts to
    // changes — e.g. resetting onboarding from Settings re-presents it live.
    // `didSet` mirrors the value into iCloud's key-value store.

    var hasCompletedOnboarding: Bool {
        didSet {
            store.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
            store.synchronize()
        }
    }

    var hasSeenWalkthrough: Bool {
        didSet {
            store.set(hasSeenWalkthrough, forKey: Keys.hasSeenWalkthrough)
            store.synchronize()
        }
    }

    // MARK: - Init

    private init() {
        // Sync from iCloud on launch, then seed the stored mirrors.
        store.synchronize()
        hasCompletedOnboarding = store.bool(forKey: Keys.hasCompletedOnboarding)
        hasSeenWalkthrough = store.bool(forKey: Keys.hasSeenWalkthrough)

        // Reflect changes made on other devices back into the observable mirrors.
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            // The observer is delivered on the main queue, so hop onto the main
            // actor synchronously instead of capturing self into a new Task.
            guard let self else { return }
            MainActor.assumeIsolated { self.syncFromStore() }
        }
    }

    private func syncFromStore() {
        let completed = store.bool(forKey: Keys.hasCompletedOnboarding)
        if completed != hasCompletedOnboarding { hasCompletedOnboarding = completed }
        let seen = store.bool(forKey: Keys.hasSeenWalkthrough)
        if seen != hasSeenWalkthrough { hasSeenWalkthrough = seen }
    }

    // MARK: - Reset

    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasSeenWalkthrough = false
    }
}
