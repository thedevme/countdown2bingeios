//
//  MyListPreferencesStore.swift
//  Countdown2Binge
//
//  Persists the My List onboarding answers (iCloud key-value store, same
//  pattern as CloudSettingsStore) so the REAL My List screen can read them —
//  not just the onboarding preview. This is what makes MyListVerdictEngine
//  an actual single source rather than two implementations that happen to
//  agree today.
//

import Foundation

@MainActor
@Observable
final class MyListPreferencesStore {
    static let shared = MyListPreferencesStore()

    private let store = NSUbiquitousKeyValueStore.default

    private enum Keys {
        static let scope = "myListScope"
        static let unit = "myListUnit"
        static let episodeBucket = "myListEpisodeBucket"
        static let timeBucket = "myListTimeBucket"
        static let selectedDays = "myListSelectedDays"
    }

    /// Stored (not computed) so @Observable tracks it and SwiftUI reacts —
    /// finishing onboarding updates the real My List screen live.
    var answers: MyListAnswers {
        didSet { persist() }
    }

    private init() {
        store.synchronize()
        answers = Self.load(from: store)

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.answers = Self.load(from: self.store)
            }
        }
    }

    private func persist() {
        store.set(answers.scope.rawValue, forKey: Keys.scope)
        store.set(answers.unit.rawValue, forKey: Keys.unit)
        store.set(answers.episodeBucket.rawValue, forKey: Keys.episodeBucket)
        store.set(answers.timeBucket.rawValue, forKey: Keys.timeBucket)
        store.set(Array(answers.selectedDays), forKey: Keys.selectedDays)
        store.synchronize()
    }

    private static func load(from store: NSUbiquitousKeyValueStore) -> MyListAnswers {
        let defaults = MyListAnswers.defaults
        let scope = (store.string(forKey: Keys.scope)).flatMap(MyListWatchScope.init) ?? defaults.scope
        let unit = (store.string(forKey: Keys.unit)).flatMap(MyListSessionUnit.init) ?? defaults.unit
        let episodeBucket = (store.string(forKey: Keys.episodeBucket)).flatMap(MyListEpisodeBucket.init) ?? defaults.episodeBucket
        let timeBucket = (store.string(forKey: Keys.timeBucket)).flatMap(MyListTimeBucket.init) ?? defaults.timeBucket
        let days = (store.array(forKey: Keys.selectedDays) as? [Int]).map(Set.init) ?? defaults.selectedDays

        return MyListAnswers(
            scope: scope, unit: unit,
            episodeBucket: episodeBucket, timeBucket: timeBucket,
            selectedDays: days
        )
    }
}
