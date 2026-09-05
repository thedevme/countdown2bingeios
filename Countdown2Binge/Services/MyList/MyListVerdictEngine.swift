//
//  MyListVerdictEngine.swift
//  Countdown2Binge
//
//  The single source for "how long is this really going to take" — used by
//  BOTH the My List onboarding preview and the real My List cards, so a
//  promise made during onboarding can never disagree with what the live
//  list actually renders. Pure and stateless: feed it a remaining-time
//  total and the user's three answers, get back a verdict sentence, a pace
//  sentence, and a shelf tier. No SwiftUI, no SwiftData.
//
//  Degradation rules (all enforced HERE, once, so they can't leak):
//   - Precise input (Episodes/Time) + a picked schedule → names an exact day
//     ("DONE THURSDAY") or, for a weekend-only schedule, a weekend count.
//   - Precise input, no schedule → a duration, never a day.
//   - Vague input (Depends) → always a RANGE, never a single number or a
//     named day, no matter how precise the schedule is.
//   - Skipping the questions is just "Depends" + no schedule — never a
//     distinct, worse-supported code path.
//

import Foundation

// MARK: - Answers

/// Q1. The only answer that changes the screen's shape — the caller picks
/// which remaining-time total to hand the engine (whole-show vs
/// current-season); the engine itself doesn't know about layout.
enum MyListWatchScope: String, CaseIterable, Identifiable, Hashable {
    case straightThrough
    case jumpAround
    var id: String { rawValue }
}

/// Q2's session-size answer. Episodes is self-correcting — the same bucket
/// means a different number of hours for a 22-minute comedy and a 60-minute
/// drama, because it's multiplied by that show's OWN average episode length.
enum MyListSessionUnit: String, CaseIterable, Identifiable, Hashable {
    case episodes
    case time
    case depends
    var id: String { rawValue }
}

enum MyListEpisodeBucket: String, CaseIterable, Identifiable, Hashable {
    case oneToTwo, threeToFour, fivePlus
    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneToTwo: return "1–2"
        case .threeToFour: return "3–4"
        case .fivePlus: return "5+"
        }
    }

    /// The representative count used for math — the bucket's lower bound,
    /// i.e. "at least this many," which is the conservative reading of an
    /// open-ended bucket like "5+".
    var representativeCount: Int {
        switch self {
        case .oneToTwo: return 1
        case .threeToFour: return 3
        case .fivePlus: return 5
        }
    }
}

enum MyListTimeBucket: String, CaseIterable, Identifiable, Hashable {
    case fortyFiveMin, oneHour, twoHour, threePlusHour
    var id: String { rawValue }

    var label: String {
        switch self {
        case .fortyFiveMin: return "45m"
        case .oneHour: return "1h"
        case .twoHour: return "2h"
        case .threePlusHour: return "3h+"
        }
    }

    var seconds: Int {
        switch self {
        case .fortyFiveMin: return 45 * 60
        case .oneHour: return 3600
        case .twoHour: return 7200
        case .threePlusHour: return 3 * 3600
        }
    }
}

/// The full answer set. `selectedDays` uses Monday = 0 ... Sunday = 6 (the
/// app's existing convention, matching MyListOnboardingDaysStep); empty =
/// "no set schedule".
struct MyListAnswers: Hashable {
    var scope: MyListWatchScope
    var unit: MyListSessionUnit
    var episodeBucket: MyListEpisodeBucket
    var timeBucket: MyListTimeBucket
    var selectedDays: Set<Int>

    /// Skip · Use defaults, exactly — Jump around · Depends · No schedule.
    static let defaults = MyListAnswers(
        scope: .jumpAround,
        unit: .depends,
        episodeBucket: .threeToFour,
        timeBucket: .oneHour,
        selectedDays: []
    )

    var isPrecise: Bool { unit != .depends }
    private static let weekend: Set<Int> = [4, 5, 6] // Fri, Sat, Sun
    var isWeekendOnly: Bool { !selectedDays.isEmpty && selectedDays.isSubset(of: Self.weekend) }
}

// MARK: - Output

enum MyListShelfTier: String, CaseIterable, Identifiable {
    case oneSitting, weekend, month, commitment
    var id: String { rawValue }

    /// Exactly the wording specified — not to be reworded.
    var label: String {
        switch self {
        case .oneSitting: return "ONE SITTING"
        case .weekend: return "A WEEKEND"
        case .month: return "A MONTH"
        case .commitment: return "A COMMITMENT"
        }
    }

    var why: String {
        switch self {
        case .oneSitting: return "Sit down and finish it"
        case .weekend: return "More to watch, still manageable"
        case .month: return "A substantial stack, cleanly paced"
        case .commitment: return "An epic binge, worth the time"
        }
    }

    var assetName: String {
        switch self {
        case .oneSitting: return "one_sitting_v3"
        case .weekend: return "weekend_v3"
        case .month: return "a_month_v3"
        case .commitment: return "commitment_v3"
        }
    }
}

struct MyListVerdict: Equatable {
    /// "DONE SUNDAY" / "A FEW NIGHTS" / "ABOUT A MONTH" / "DONE IN 3 WEEKENDS".
    let verdictText: String
    /// "3 EPISODES A NIGHT" / "2H A NIGHT" / "A COUPLE HOURS A NIGHT".
    let paceText: String
    let shelfTier: MyListShelfTier
    /// "11h" — rounded, always present regardless of precision.
    let rawHoursText: String
    /// "BY SUNDAY" — present only once a schedule is picked; nil for "no
    /// set schedule" or Skip, since no day is ever named from a guess.
    let shelfDateSuffix: String?
}

// MARK: - Engine

enum MyListVerdictEngine {

    /// Bump this whenever `shelfTier`'s FORMULA changes (not its inputs).
    /// `Season.pinnedShelfTierVersion` is checked against this before a
    /// pinned tier is trusted — a season pinned under an old formula
    /// version is treated as unpinned and recomputed, instead of staying
    /// stuck on a category that formula no longer produces. 1 = the
    /// original session/schedule-based formula; 2 = fixed total-hours
    /// bands (≤3h/8h/15h), matching "My List Cards.html"'s own chart.
    static let currentShelfTierVersion = 2

    /// `avgEpisodeSeconds` is the SHOW's own average (whole-show for
    /// Straight Through, current-season for Jump Around — whichever total
    /// `remainingSeconds` itself represents), so Episodes stays
    /// self-correcting per-show rather than using one global average.
    static func evaluate(
        remainingSeconds: Int,
        answers: MyListAnswers,
        avgEpisodeSeconds: Int,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> MyListVerdict {
        let remaining = max(0, remainingSeconds)
        let session = sessionSeconds(answers: answers, avgEpisodeSeconds: avgEpisodeSeconds)
        let sessions = max(1, Int((Double(remaining) / Double(session)).rounded(.up)))
        let nightsPerWeek = answers.selectedDays.isEmpty ? 3 : answers.selectedDays.count

        return MyListVerdict(
            verdictText: verdictText(
                sessions: sessions, nightsPerWeek: nightsPerWeek, answers: answers,
                today: today, calendar: calendar
            ),
            paceText: paceText(answers: answers),
            shelfTier: shelfTier(remainingSeconds: remaining),
            rawHoursText: "\(Int((Double(remaining) / 3600).rounded()))h",
            shelfDateSuffix: shelfDateSuffix(answers: answers, sessions: sessions, today: today, calendar: calendar)
        )
    }

    // MARK: Session size

    static func sessionSeconds(answers: MyListAnswers, avgEpisodeSeconds: Int) -> Int {
        switch answers.unit {
        case .depends:
            return Int(2.5 * 3600)
        case .time:
            return answers.timeBucket.seconds
        case .episodes:
            return answers.episodeBucket.representativeCount * max(1, avgEpisodeSeconds)
        }
    }

    private static func paceText(answers: MyListAnswers) -> String {
        switch answers.unit {
        case .depends:
            return "A COUPLE HOURS A NIGHT"
        case .time:
            return "\(answers.timeBucket.label.uppercased()) A NIGHT"
        case .episodes:
            let n = answers.episodeBucket.representativeCount
            return "\(n) \(n == 1 ? "EPISODE" : "EPISODES") A NIGHT"
        }
    }

    // MARK: Shelf tier

    /// Fixed total-hours bands — "My List Cards.html"'s own chart
    /// (`secsLeft(s)<=3*H` / `<=8*H` / `<=15*H` / else), not the user's
    /// session size or schedule. A 9-hour season is "a weekend" for
    /// everyone, the same way, regardless of how fast anyone watches.
    static func shelfTier(remainingSeconds: Int) -> MyListShelfTier {
        let hours = Double(remainingSeconds) / 3600
        if hours <= 3 { return .oneSitting }
        if hours <= 8 { return .weekend }
        if hours <= 15 { return .month }
        return .commitment
    }

    // MARK: Verdict text (the degradation rules)

    private static func verdictText(
        sessions: Int, nightsPerWeek: Int, answers: MyListAnswers, today: Date, calendar: Calendar
    ) -> String {
        if sessions <= 1 { return "ONE SITTING" }

        // Vague input (Depends) always ranges — never a single number, never
        // a named day, regardless of what schedule is picked.
        guard answers.isPrecise else {
            if sessions <= nightsPerWeek { return "A FEW NIGHTS" }
            let weeks = Int((Double(sessions) / Double(nightsPerWeek)).rounded(.up))
            return weeks == 1 ? "ABOUT A WEEK" : "\(weeks)–\(weeks + 1) WEEKS"
        }

        // Precise input, but nothing to hang a date on ⇒ a duration.
        guard !answers.selectedDays.isEmpty else {
            if sessions <= 3 { return "A FEW NIGHTS" }
            let weeks = Int((Double(sessions) / 3.0).rounded(.up))
            if weeks == 1 { return "ABOUT A WEEK" }
            if weeks <= 4 { return "ABOUT \(weeks) WEEKS" }
            return "ABOUT A MONTH"
        }

        // Precise input AND a schedule ⇒ name the day, if it lands this week.
        let days = answers.selectedDays.sorted()
        if let day = nthOccurrence(sessions, of: days, from: today, calendar: calendar), day.week == 0 {
            return "DONE \(weekdayName(day.weekday).uppercased())"
        }
        if answers.isWeekendOnly {
            let weekends = Int((Double(sessions) / Double(days.count)).rounded(.up))
            return "DONE IN \(weekends) \(weekends == 1 ? "WEEKEND" : "WEEKENDS")"
        }
        let weeks = Int((Double(sessions) / Double(nightsPerWeek)).rounded(.up))
        return "DONE IN \(weeks) \(weeks == 1 ? "WEEK" : "WEEKS")"
    }

    private static func shelfDateSuffix(
        answers: MyListAnswers, sessions: Int, today: Date, calendar: Calendar
    ) -> String? {
        // Only once precision AND a real schedule both hold — same gate as
        // the verdict's own named-day branch, so the two can't disagree.
        guard answers.isPrecise, !answers.selectedDays.isEmpty, sessions > 1 else { return nil }
        let days = answers.selectedDays.sorted()
        guard let day = nthOccurrence(sessions, of: days, from: today, calendar: calendar), day.week == 0
        else { return nil }
        return "BY \(weekdayName(day.weekday).uppercased())"
    }

    // MARK: Calendar walk

    /// Walks forward from `from` (inclusive) counting only the given
    /// weekdays (Monday = 0 ... Sunday = 6) until the nth one is reached.
    /// Returns its weekday and which week it falls in (0 = this week).
    private static func nthOccurrence(
        _ n: Int, of days: [Int], from: Date, calendar: Calendar
    ) -> (weekday: Int, week: Int)? {
        guard !days.isEmpty else { return nil }
        // Calendar.weekday is 1 = Sunday ... 7 = Saturday; convert to
        // Monday = 0 ... Sunday = 6 to match `selectedDays`.
        let todayIndex = (calendar.component(.weekday, from: from) + 5) % 7
        var count = 0
        for offset in 0..<84 {
            let weekday = (todayIndex + offset) % 7
            guard days.contains(weekday) else { continue }
            count += 1
            if count == n { return (weekday, offset / 7) }
        }
        return nil
    }

    private static let weekdayNames = [
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
    ]
    private static func weekdayName(_ index: Int) -> String { weekdayNames[index] }
}
