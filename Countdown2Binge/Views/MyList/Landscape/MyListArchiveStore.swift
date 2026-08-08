//
//  MyListArchiveStore.swift
//  Countdown2Binge
//
//  Manual archive set for My List, persisted in UserDefaults under the same key
//  FollowedShowDetail writes ("archivedShowIds"). Archived shows are moved out of
//  Ready/Watched and shown in the Archived tab.
//

import SwiftUI

@MainActor
@Observable
final class MyListArchiveStore {
    private(set) var archivedShowIds: Set<Int> = []
    private let key = "archivedShowIds"

    init() { reload() }

    func isArchived(_ showId: Int) -> Bool { archivedShowIds.contains(showId) }

    func archive(_ showId: Int) {
        archivedShowIds.insert(showId)
        save()
    }

    func unarchive(_ showId: Int) {
        archivedShowIds.remove(showId)
        save()
    }

    func reload() {
        if let ids = UserDefaults.standard.array(forKey: key) as? [Int] {
            archivedShowIds = Set(ids)
        }
    }

    private func save() {
        UserDefaults.standard.set(Array(archivedShowIds), forKey: key)
    }
}
