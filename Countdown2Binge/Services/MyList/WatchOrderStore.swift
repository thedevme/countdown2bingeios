//
//  WatchOrderStore.swift
//  Countdown2Binge
//
//  Persists a user-chosen watch order for Straight Through's "Upcoming"
//  section — the shows queued behind Next, reordered up/down from the
//  Watch Order sheet. iCloud key-value store, same pattern as
//  CloudSettingsStore/MyListPreferencesStore. This is a resettable UI
//  preference, not watch-state, so it stays out of the Core Engine /
//  SeriesManager write funnel entirely.
//

import Foundation

@MainActor
@Observable
final class WatchOrderStore {
    static let shared = WatchOrderStore()

    private let store = NSUbiquitousKeyValueStore.default

    private enum Keys {
        static let customOrder = "myListWatchOrder"
    }

    /// Show ids in the user's chosen order. nil = no custom order — the
    /// Upcoming section falls back to its default "shortest first" sort.
    var customOrder: [Int]? {
        didSet { persist() }
    }

    private init() {
        store.synchronize()
        customOrder = store.array(forKey: Keys.customOrder) as? [Int]

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.customOrder = self.store.array(forKey: Keys.customOrder) as? [Int]
            }
        }
    }

    private func persist() {
        if let customOrder {
            store.set(customOrder, forKey: Keys.customOrder)
        } else {
            store.removeObject(forKey: Keys.customOrder)
        }
        store.synchronize()
    }

    /// Moves the show with `id` one step up (`direction: -1`) or down
    /// (`direction: 1`) within `currentOrder` — the Upcoming section's
    /// CURRENT displayed order, default or already-custom — then saves the
    /// result as the new custom order. Out of range is a no-op (matches
    /// the sheet's disabled top/bottom buttons).
    func move(id: Int, direction: Int, within currentOrder: [Int]) {
        var ids = customOrder ?? currentOrder
        guard let i = ids.firstIndex(of: id) else { return }
        let j = i + direction
        guard ids.indices.contains(j) else { return }
        ids.swapAt(i, j)
        customOrder = ids
    }

    func reset() {
        customOrder = nil
    }

    /// Applies the saved custom order to a default-ordered list — ids in
    /// the saved order first (that still appear in `items`), then anything
    /// not in it appended, keeping ITS OWN relative order from `items`.
    /// Exactly the design's `queued` computation
    /// (My List Cards.html:423-426): "a custom order only reshuffles what's
    /// queued behind Next."
    func apply<T>(to items: [T], id: (T) -> Int) -> [T] {
        guard let customOrder else { return items }
        var remaining = Dictionary(uniqueKeysWithValues: items.map { (id($0), $0) })
        var result: [T] = []
        for orderedId in customOrder {
            if let item = remaining.removeValue(forKey: orderedId) {
                result.append(item)
            }
        }
        result += items.filter { remaining[id($0)] != nil }
        return result
    }
}
