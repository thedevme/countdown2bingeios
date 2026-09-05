//
//  MyListOnboardingPreviewState.swift
//  Countdown2Binge
//
//  Feeds the live "so this card now reads" preview from MyListVerdictEngine
//  — the same engine the real My List cards use — so the preview can never
//  promise something the live list doesn't actually do. One fixture show
//  per scope (Landman for Straight Through's whole-show clock, Lioness for
//  Jump Around's current-season clock), matching the spec's worked examples
//  exactly; only which show/scope is fixture, the math is real.
//

import Foundation

struct MyListOnboardingPreviewState {
    let scope: MyListWatchScope
    let verdict: MyListVerdict
    let showTitle: String
    /// nil → LandscapeBackdrop's deterministic gradient placeholder (Lioness
    /// has no bundled poster; Landman does).
    let posterAssetName: String?
    /// "REMAINING · 6 SEASONS" (straight through) or "S1 · 8 EPISODES LEFT"
    /// (jump around) — the clock's own sub-label, per spec.
    let metaText: String

    static func make(answers: MyListAnswers, today: Date = Date()) -> MyListOnboardingPreviewState {
        switch answers.scope {
        case .straightThrough:
            let remaining = 227_520 // 63h12m — Landman, whole show remaining
            let verdict = MyListVerdictEngine.evaluate(
                remainingSeconds: remaining, answers: answers, avgEpisodeSeconds: 5400, today: today
            )
            return MyListOnboardingPreviewState(
                scope: .straightThrough, verdict: verdict,
                showTitle: "Landman", posterAssetName: "landman",
                metaText: "REMAINING · 6 SEASONS"
            )
        case .jumpAround:
            let remaining = 21_420 // 5h57m — Lioness, current season remaining
            let verdict = MyListVerdictEngine.evaluate(
                remainingSeconds: remaining, answers: answers, avgEpisodeSeconds: 2678, today: today
            )
            return MyListOnboardingPreviewState(
                scope: .jumpAround, verdict: verdict,
                showTitle: "Lioness", posterAssetName: nil,
                metaText: "S1 · 8 EPISODES LEFT"
            )
        }
    }
}
