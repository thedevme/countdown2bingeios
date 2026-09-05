//
//  ReviewPrompt.swift
//  Countdown2Binge
//
//  Decides WHEN to ask for an App Store rating. Asking is done by the view,
//  since `requestReview` is a SwiftUI environment action.
//
//  Two independent triggers, each with its own record:
//    • search  — every 5th show followed: 5, 10, 15, 20, …
//    • import  — the first successful bulk import, once ever
//
//  They don't share state. A bulk import doesn't advance the search cadence
//  (twelve pasted titles are one decision), and search follows don't consume
//  the import's one-time ask.
//
//  ── Why there's a confirm step ─────────────────────────────────────────────
//  Apple's `requestReview` reports nothing back: no callback, no way to know
//  whether the sheet appeared or what the user did with it. So we ask first,
//  with our own two-button prompt. Tapping "Rate" is a signal we DO own — it
//  sets `hasRated` and the app never asks again, on any trigger, forever.
//  "Not now" records nothing, so the cadence can come back around later.
//
//  The prompt is deliberately neutral. It must not filter unhappy users toward
//  private feedback instead of the App Store — that's an App Review violation.
//
//  Note also that iOS caps prompts at three per app per 365 days and silently
//  ignores the rest, so these are the moments we ask; the system decides what
//  is actually shown.
//

import Foundation

@MainActor
enum ReviewPrompt {
    private static let countKey = "c2b_follow_count_for_review"
    private static let bulkImportAskedKey = "c2b_review_asked_after_import"

    // MARK: - Done for good

    /// The user accepted a prompt and was handed to the App Store. Once true,
    /// nothing in the app ever asks again.
    ///
    /// Backed by iCloud (CloudSettingsStore), not local UserDefaults, so a
    /// reinstall or a second device doesn't start asking all over again —
    /// same treatment the onboarding flags get.
    static var hasRated: Bool {
        CloudSettingsStore.shared.hasRatedApp
    }

    /// Call when the user taps "Rate" on our confirm prompt — the one moment we
    /// can actually observe.
    static func markRated() {
        CloudSettingsStore.shared.hasRatedApp = true
    }

    // MARK: - Search cadence

    /// Total shows followed, ever. Not the current library size — unfollowing
    /// doesn't decrement it, or the prompt would re-trigger on churn.
    private(set) static var followCount: Int {
        get { UserDefaults.standard.integer(forKey: countKey) }
        set { UserDefaults.standard.set(newValue, forKey: countKey) }
    }

    /// Record a follow and report whether this one is a prompt point.
    static func registerFollowAndShouldAsk() -> Bool {
        followCount += 1
        guard !hasRated else { return false }
        return isPromptPoint(followCount)
    }

    /// 5, 10, 15, 20 … — not the 1st follow, too early to be asking.
    static func isPromptPoint(_ count: Int) -> Bool {
        count > 0 && count % 5 == 0
    }

    // MARK: - Bulk import

    /// The first successful bulk import asks for a rating, and only the first.
    /// Returns true once in the app's lifetime, then always false.
    static func registerBulkImportAndShouldAsk() -> Bool {
        guard !hasRated else { return false }
        guard !UserDefaults.standard.bool(forKey: bulkImportAskedKey) else { return false }
        UserDefaults.standard.set(true, forKey: bulkImportAskedKey)
        return true
    }
}
