//
//  FollowDigest.swift
//  Countdown2Binge
//
//  A single "here's what you added" notification, sent once the user has put
//  the app down — never a burst of one alert per show.
//
//  Timing is keyed to LEAVING the app, not to the last follow. Adding a show
//  only records it; backgrounding starts the clock. So it can never
//  fire while the user is still browsing (local notifications don't present in
//  the foreground anyway), and adding a fourth show mid-session doesn't restart
//  anything — walking away does.
//
//  Coming back cancels the pending digest. If it had already been delivered,
//  the recorded list is cleared on that return, so the next digest only ever
//  covers shows added since the last one the user actually saw. Scheduled local
//  notifications survive a force-quit, so that case works too.
//
//  Premium-gated like every other notification.
//

import Foundation
import UserNotifications

@MainActor
final class FollowDigest {
    static let shared = FollowDigest()

    /// Deliberately outside the `show-{id}-` namespace so NotificationScheduler's
    /// per-show sweep in `applyPlans` never treats this as an orphan.
    static let identifier = "digest-shows-added"

    /// How long after leaving the app the digest fires. Short on purpose: it
    /// doubles as confirmation that the shows landed AND that notifications are
    /// working, so it wants to arrive while the user still remembers adding them.
    private let delay: TimeInterval = 2 * 60

    /// Names to list, in the order they were followed.
    private let pendingKey = "c2b_digest_pending_shows"

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Recording

    private var pendingShows: [String] {
        get { defaults.stringArray(forKey: pendingKey) ?? [] }
        set { defaults.set(newValue, forKey: pendingKey) }
    }

    /// Drop a show from the pending digest — it was unfollowed before the
    /// digest went out, so announcing it would be wrong.
    ///
    /// Without this the name survives in UserDefaults and the digest cheerfully
    /// tells the user they're now following something they just removed.
    func forget(showName: String) {
        guard !showName.isEmpty else { return }
        var shows = pendingShows
        guard let index = shows.firstIndex(of: showName) else { return }
        shows.remove(at: index)
        pendingShows = shows

        // A scheduled digest has its text baked in at registration time, so a
        // shrinking list has to be re-registered — otherwise it still names the
        // show that was just removed. Empty list means cancel outright.
        Task { await rescheduleIfPending(remaining: shows) }
    }

    /// Rewrite an already-scheduled digest to match the current list, keeping
    /// its original fire time. Cancels it when there's nothing left to say.
    private func rescheduleIfPending(remaining: [String]) async {
        let pending = await center.pendingNotificationRequests()
        guard let existing = pending.first(where: { $0.identifier == Self.identifier }) else { return }

        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])

        guard !remaining.isEmpty else {
            logNotif("➖ DEREGISTER \(Self.identifier) — every show was unfollowed")
            return
        }

        // Preserve the remaining time rather than restarting the clock: the
        // user already walked away, and this is a correction, not a new event.
        guard let trigger = existing.trigger as? UNTimeIntervalNotificationTrigger,
              let fireDate = trigger.nextTriggerDate() else { return }
        let secondsLeft = max(1, fireDate.timeIntervalSinceNow)

        let content = UNMutableNotificationContent()
        content.title = String(localized: "digest_title")
        content.body = body(for: remaining)
        content.sound = .default
        content.userInfo = ["type": "digest"]

        let request = UNNotificationRequest(
            identifier: Self.identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: secondsLeft, repeats: false)
        )
        do {
            try await center.add(request)
            logNotif("↻ REWROTE \(Self.identifier) — now \(remaining.count) show(s)")
        } catch {
            logNotif("⚠️ FAILED to rewrite \(Self.identifier): \(error.localizedDescription)")
        }
    }

    /// Record a newly followed show. Schedules nothing — see `appDidEnterBackground`.
    func record(showName: String) {
        guard !showName.isEmpty else { return }
        var shows = pendingShows
        guard !shows.contains(showName) else { return }
        shows.append(showName)
        pendingShows = shows
    }

    // MARK: - Lifecycle hooks

    /// User left the app — start the clock if there's anything to tell them.
    func appDidEnterBackground() async {
        let shows = pendingShows
        guard !shows.isEmpty else { return }
        guard PremiumManager.shared.isPremium else { return }
        guard await NotificationService.shared.currentlyAuthorized() else { return }

        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "digest_title")
        content.body = body(for: shows)
        content.sound = .default
        content.userInfo = ["type": "digest"]

        let request = UNNotificationRequest(
            identifier: Self.identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        )

        do {
            try await center.add(request)
            logNotif("➕ REGISTER \(Self.identifier) — \(shows.count) show(s), fires in \(Int(delay / 60))m")
        } catch {
            logNotif("⚠️ FAILED to register \(Self.identifier): \(error.localizedDescription)")
        }
    }

    /// User came back. Cancel anything pending, and if the digest already landed
    /// while they were away, clear the list so it isn't repeated next time.
    func appDidBecomeActive() async {
        let delivered = await center.deliveredNotifications()
        if delivered.contains(where: { $0.request.identifier == Self.identifier }) {
            center.removeDeliveredNotifications(withIdentifiers: [Self.identifier])
            pendingShows = []
            logNotif("✓ digest was delivered — pending list cleared")
        }
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }

    // MARK: - Copy

    /// "Silo, Lioness and Reacher" — capped, with a +N tail beyond three.
    private func body(for shows: [String]) -> String {
        let shown = shows.prefix(3)
        let overflow = shows.count - shown.count
        let list = ListFormatter.localizedString(byJoining: Array(shown))

        if overflow > 0 {
            return String(localized: "digest_body_more \(list) \(overflow)")
        }
        return String(localized: "digest_body \(list)")
    }
}
