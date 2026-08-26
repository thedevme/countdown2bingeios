//
//  UnfollowTombstones.swift
//  Countdown2Binge
//
//  Ids the user has unfollowed but which may still exist in iCloud.
//
//  Unfollow deletes locally straight away — the UI can't wait on a network
//  round-trip — and fires the CloudKit delete in the background. If that delete
//  fails (offline, CloudKit error, app killed mid-flight) the record survives
//  and `restoreShowsFromCloud()` would hand the show back on next launch,
//  silently undoing the unfollow.
//
//  So the id is written here first, synchronously, before anything else
//  happens. Two things then use it:
//    • restore SKIPS any id listed here — a tombstoned show can never come back
//    • launch retries the delete for anything still listed
//
//  An id is only forgotten once CloudKit confirms the record is gone.
//

import Foundation

enum UnfollowTombstones {
    private static let key = "c2b_pending_cloud_unfollows"
    private static let defaults = UserDefaults.standard

    /// Ids unfollowed locally that iCloud may still be holding.
    static var ids: Set<Int> {
        Set(defaults.array(forKey: key) as? [Int] ?? [])
    }

    /// Record an unfollow. Called synchronously, before the local delete, so a
    /// crash between the two can't lose the tombstone.
    static func add(_ id: Int) {
        var current = ids
        guard current.insert(id).inserted else { return }
        defaults.set(Array(current), forKey: key)
    }

    /// CloudKit confirmed the record is gone — stop tracking it.
    static func clear(_ id: Int) {
        var current = ids
        guard current.remove(id) != nil else { return }
        defaults.set(Array(current), forKey: key)
    }

    /// True when this id must not be restored from iCloud.
    static func contains(_ id: Int) -> Bool {
        ids.contains(id)
    }

    /// Re-following a show the user previously unfollowed clears its tombstone —
    /// otherwise restore would refuse to see it ever again.
    static func forget(_ id: Int) {
        clear(id)
    }
}
