//
//  WatchTime.swift
//  Countdown2Binge
//
//  Watch-time = sum of episode runtimes for a season. TMDB leaves `runtime` as 0
//  for unaired / missing episodes, so those are filled with the average of the
//  season's KNOWN runtimes — the full-season total never under-counts.
//

import Foundation

enum WatchTime {

    /// Total watch-time in SECONDS for a season, given per-episode runtimes in
    /// MINUTES (as stored on `Episode.runtime`). Episodes with runtime 0 are
    /// filled with the average of the season's known runtimes. Returns 0 when
    /// there are no episodes or no known runtimes to average from.
    static func totalSeconds(runtimesMinutes: [Int]) -> Int {
        guard !runtimesMinutes.isEmpty else { return 0 }
        let known = runtimesMinutes.filter { $0 > 0 }
        guard !known.isEmpty else { return 0 }

        let average = Double(known.reduce(0, +)) / Double(known.count)
        let totalMinutes = runtimesMinutes.reduce(0.0) { total, runtime in
            total + (runtime > 0 ? Double(runtime) : average)
        }
        return Int((totalMinutes * 60).rounded())
    }
}
