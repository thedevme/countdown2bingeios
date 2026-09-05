//
//  MyListVerdictEngineTests.swift
//  Countdown2BingeTests
//
//  The four worked examples from the personalization-flow spec, asserted as
//  exact strings — this is also how Landman/Lioness's fixture runtime
//  numbers were tuned (by solving for them here, not by hand-guessing).
//

import Testing
import Foundation
@testable import Countdown2Binge

@Suite("My List Verdict Engine")
struct MyListVerdictEngineTests {

    // Fixed "today" so day-naming tests are deterministic: a Wednesday.
    private let wednesday: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 9; c.day = 2 // a Wednesday
        return Calendar.current.date(from: c)!
    }()

    private let fridaySatSun: Set<Int> = [4, 5, 6]

    // MARK: - Worked examples

    @Test("Straight + Episodes 5+ + Fri/Sat/Sun → Landman, DONE IN 3 WEEKENDS")
    func straightEpisodesWeekend() {
        let answers = MyListAnswers(
            scope: .straightThrough, unit: .episodes,
            episodeBucket: .fivePlus, timeBucket: .oneHour,
            selectedDays: fridaySatSun
        )
        let result = MyListVerdictEngine.evaluate(
            remainingSeconds: 227_520, // 63h12m — Landman, whole show
            answers: answers, avgEpisodeSeconds: 5400, // 90m/ep fixture
            today: wednesday
        )
        #expect(result.paceText == "5 EPISODES A NIGHT")
        #expect(result.verdictText == "DONE IN 3 WEEKENDS")
    }

    @Test("Straight + Time 2h + No schedule → Landman, ABOUT A MONTH")
    func straightTimeNoSchedule() {
        let answers = MyListAnswers(
            scope: .straightThrough, unit: .time,
            episodeBucket: .threeToFour, timeBucket: .twoHour,
            selectedDays: []
        )
        let result = MyListVerdictEngine.evaluate(
            remainingSeconds: 227_520, answers: answers, avgEpisodeSeconds: 5400, today: wednesday
        )
        #expect(result.paceText == "2H A NIGHT")
        #expect(result.verdictText == "ABOUT A MONTH")
    }

    @Test("Jump + Episodes 3–4 + Fri/Sat/Sun → Lioness, A WEEKEND shelf, DONE SUNDAY")
    func jumpEpisodesWeekend() {
        let answers = MyListAnswers(
            scope: .jumpAround, unit: .episodes,
            episodeBucket: .threeToFour, timeBucket: .oneHour,
            selectedDays: fridaySatSun
        )
        let result = MyListVerdictEngine.evaluate(
            remainingSeconds: 21_420, // 5h57m — Lioness, current season
            answers: answers, avgEpisodeSeconds: 2678, // 8 eps left fixture
            today: wednesday
        )
        #expect(result.paceText == "3 EPISODES A NIGHT")
        #expect(result.verdictText == "DONE SUNDAY")
        #expect(result.shelfTier == .weekend)
        #expect(result.shelfDateSuffix == "BY SUNDAY")
    }

    @Test("Jump + Depends + No schedule → Lioness, A WEEKEND shelf, A FEW NIGHTS")
    func jumpDependsNoSchedule() {
        let answers = MyListAnswers(
            scope: .jumpAround, unit: .depends,
            episodeBucket: .threeToFour, timeBucket: .oneHour,
            selectedDays: []
        )
        let result = MyListVerdictEngine.evaluate(
            remainingSeconds: 21_420, answers: answers, avgEpisodeSeconds: 2678, today: wednesday
        )
        #expect(result.paceText == "A COUPLE HOURS A NIGHT")
        #expect(result.verdictText == "A FEW NIGHTS")
        #expect(result.shelfTier == .weekend)
        // Vague input never names a day, even though a shelf tier still applies.
        #expect(result.shelfDateSuffix == nil)
    }

    // MARK: - Degradation rules

    @Test("Skip defaults match Jump around · Depends · No schedule exactly")
    func skipDefaults() {
        let d = MyListAnswers.defaults
        #expect(d.scope == .jumpAround)
        #expect(d.unit == .depends)
        #expect(d.selectedDays.isEmpty)
    }

    @Test("Vague input always ranges, never a single number or a day, even with a picked schedule")
    func vagueAlwaysRanges() {
        let answers = MyListAnswers(
            scope: .jumpAround, unit: .depends,
            episodeBucket: .threeToFour, timeBucket: .oneHour,
            selectedDays: fridaySatSun
        )
        // A long remaining time that would otherwise land on a named day.
        let result = MyListVerdictEngine.evaluate(
            remainingSeconds: 90_000, answers: answers, avgEpisodeSeconds: 2700, today: wednesday
        )
        #expect(!result.verdictText.hasPrefix("DONE "))
        #expect(result.shelfDateSuffix == nil)
    }

    @Test("Precise input with no schedule never names a day")
    func preciseNoScheduleNeverNamesDay() {
        let answers = MyListAnswers(
            scope: .jumpAround, unit: .episodes,
            episodeBucket: .fivePlus, timeBucket: .oneHour,
            selectedDays: []
        )
        let result = MyListVerdictEngine.evaluate(
            remainingSeconds: 90_000, answers: answers, avgEpisodeSeconds: 2700, today: wednesday
        )
        #expect(!result.verdictText.hasPrefix("DONE "))
        #expect(result.shelfDateSuffix == nil)
    }

    @Test("A single session is always ONE SITTING regardless of unit")
    func oneSittingRegardlessOfUnit() {
        for unit in MyListSessionUnit.allCases {
            let answers = MyListAnswers(
                scope: .jumpAround, unit: unit,
                episodeBucket: .fivePlus, timeBucket: .threePlusHour,
                selectedDays: []
            )
            let result = MyListVerdictEngine.evaluate(
                remainingSeconds: 1800, answers: answers, avgEpisodeSeconds: 2700, today: wednesday
            )
            #expect(result.verdictText == "ONE SITTING")
            #expect(result.shelfTier == .oneSitting)
        }
    }

    @Test("Shelf tier is the SAME fixed total-hours chart for every user, regardless of session size or nights")
    func shelfTierIsNotPersonalized() {
        // Same 3-hour remaining total, two very different users — the tier
        // must not differ. Sessions/schedule still drive the pace TEXT
        // ("DONE THURSDAY" vs "A FEW NIGHTS"), just never which shelf a
        // show lands in.
        let generous = MyListAnswers(
            scope: .jumpAround, unit: .time,
            episodeBucket: .threeToFour, timeBucket: .threePlusHour, // one 3h+ session finishes it
            selectedDays: [0, 1, 2, 3, 4, 5, 6]
        )
        let sparse = MyListAnswers(
            scope: .jumpAround, unit: .time,
            episodeBucket: .threeToFour, timeBucket: .fortyFiveMin, // needs 4 of their short sessions
            selectedDays: [5] // one night a week
        )
        let threeHours = 3 * 3600
        let generousResult = MyListVerdictEngine.evaluate(
            remainingSeconds: threeHours, answers: generous, avgEpisodeSeconds: 2700, today: wednesday
        )
        let sparseResult = MyListVerdictEngine.evaluate(
            remainingSeconds: threeHours, answers: sparse, avgEpisodeSeconds: 2700, today: wednesday
        )
        #expect(generousResult.shelfTier == .oneSitting)
        #expect(sparseResult.shelfTier == .oneSitting)
        #expect(generousResult.shelfTier == sparseResult.shelfTier)
    }

    @Test("Shelf tier boundaries match My List Cards.html's own chart: ≤3h/8h/15h, >15h else")
    func shelfTierFixedHourBoundaries() {
        let answers = MyListAnswers.defaults // answers must not matter — see shelfTierIsNotPersonalized
        func tier(_ hours: Double) -> MyListShelfTier {
            MyListVerdictEngine.evaluate(
                remainingSeconds: Int(hours * 3600), answers: answers, avgEpisodeSeconds: 2700, today: wednesday
            ).shelfTier
        }
        #expect(tier(3) == .oneSitting)
        #expect(tier(3.01) == .weekend)
        #expect(tier(8) == .weekend)
        #expect(tier(8.01) == .month)
        #expect(tier(15) == .month)
        #expect(tier(15.01) == .commitment)
    }
}
