//
//  WatchTimeTests.swift
//  Countdown2BingeTests
//
//  Pure tests for the season watch-time sum (with average-fill for missing runtimes).
//

import Testing
import Foundation
@testable import Countdown2Binge

@Suite("Watch-time sum")
struct WatchTimeTests {

    @Test("All runtimes known → exact sum in seconds")
    func exactSum() {
        // 45 + 50 + 55 = 150 minutes = 9000 seconds
        #expect(WatchTime.totalSeconds(runtimesMinutes: [45, 50, 55]) == 9000)
    }

    @Test("Zero-runtime episode is average-filled (no under-count)")
    func averageFill() {
        // Known runtimes avg = (40 + 60) / 2 = 50. The 0 fills to 50.
        // Total = 40 + 60 + 50 = 150 minutes = 9000 seconds.
        #expect(WatchTime.totalSeconds(runtimesMinutes: [40, 60, 0]) == 9000)
    }

    @Test("Multiple zero-runtime episodes each fill with the average")
    func multipleFill() {
        // Known avg = 50. Two zeros → +100. Total = 50 + 50 + 50 = 150 min = 9000s.
        #expect(WatchTime.totalSeconds(runtimesMinutes: [50, 0, 0]) == 9000)
    }

    @Test("Empty season → 0")
    func empty() {
        #expect(WatchTime.totalSeconds(runtimesMinutes: []) == 0)
    }

    @Test("All-zero runtimes → 0 (nothing known to average)")
    func allZero() {
        #expect(WatchTime.totalSeconds(runtimesMinutes: [0, 0, 0]) == 0)
    }
}
