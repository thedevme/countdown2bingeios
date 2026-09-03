//
//  FranchiseSpinoffOrdering.swift
//  Countdown2Binge
//
//  Pure, testable ordering logic for the era-grouped Spin-offs card's
//  RECOMMENDED / RELEASE toggle. No SwiftUI, no view state — takes a
//  FranchiseGroup and the active order, returns entries in FINAL display
//  order, each already paired with its final 1-based display number.
//
//  Numbers are always assigned fresh, AFTER ordering, continuously 1...n —
//  never reused from the other order, never restarted per era section. This
//  is the one place that rule is implemented, so the two tabs can't drift
//  apart the way they did before (see: RELEASE silently falling through to
//  RECOMMENDED's row order, only the label attempted — and failed — to differ).
//

import Foundation

enum FranchiseSpinoffOrdering {

    /// One entry as it should render for the active order: its data, plus
    /// the number to show next to it.
    struct OrderedEntry: Identifiable {
        let entry: FranchiseEntry
        let displayNumber: Int
        var id: MediaKey { entry.id }
    }

    /// Entries in final display order for `order`, numbered 1...n in that order.
    ///
    /// - `.recommended`: the engine's own order (bucket, then year-ascending
    ///   within bucket) — flattened across sections, not re-sorted.
    /// - `.release`: ALL entries — parent and every spin-off — sorted purely
    ///   by start year, ignoring bucket/era entirely (era headers make no
    ///   sense once the parent can sort ahead of its own prequels). Ties
    ///   broken by each entry's index in the recommended order, since
    ///   `sorted(by:)` is not guaranteed stable — sorting on the
    ///   `(year, originalIndex)` tuple makes correctness independent of that.
    static func orderedEntries(for group: FranchiseGroup, order: FranchiseDisplayOrder) -> [OrderedEntry] {
        let recommendedOrder = group.sections.flatMap(\.entries)

        let sequenced: [FranchiseEntry]
        switch order {
        case .recommended:
            sequenced = recommendedOrder
        case .release:
            sequenced = recommendedOrder.enumerated()
                .sorted { lhs, rhs in
                    let lhsYear = FranchiseCatalogBuilder.parseStartYear(lhs.element.years) ?? .max
                    let rhsYear = FranchiseCatalogBuilder.parseStartYear(rhs.element.years) ?? .max
                    if lhsYear != rhsYear { return lhsYear < rhsYear }
                    return lhs.offset < rhs.offset
                }
                .map(\.element)
        }

        return sequenced.enumerated().map { index, entry in
            OrderedEntry(entry: entry, displayNumber: index + 1)
        }
    }
}
