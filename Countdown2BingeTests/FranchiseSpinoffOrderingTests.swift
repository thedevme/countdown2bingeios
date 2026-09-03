//
//  FranchiseSpinoffOrderingTests.swift
//  Countdown2BingeTests
//
//  Tests for the RECOMMENDED/RELEASE ordering bug: RELEASE was silently
//  falling through to RECOMMENDED's row order (see FranchiseSpinoffOrdering.swift).
//

import Testing
import Foundation
@testable import Countdown2Binge

@Suite("Franchise Spinoff Ordering Tests")
struct FranchiseSpinoffOrderingTests {

    private let enLocale = Locale(identifier: "en")

    // MARK: - Bug 1: Game of Thrones RELEASE order

    @Test("Game of Thrones RELEASE order is GoT, House of the Dragon, A Knight of the Seven Kingdoms")
    func gameOfThronesReleaseOrder() async {
        let provider = BundledFranchiseProvider()
        let group = await provider.franchise(forShowId: 1399, mediaType: .tv, locale: enLocale)
        #expect(group != nil)

        let ordered = FranchiseSpinoffOrdering.orderedEntries(for: group!, order: .release)
        let titles = ordered.map(\.entry.title)

        #expect(titles == ["Game of Thrones", "House of the Dragon", "A Knight of the Seven Kingdoms"])
    }

    // MARK: - RELEASE is non-decreasing by year, unparsable last, across every franchise

    @Test("RELEASE order is non-decreasing by start year for every franchise, unparsable years last")
    func releaseOrderNonDecreasingAcrossCatalog() async {
        let provider = BundledFranchiseProvider()
        let groups = await provider.allFranchiseGroups(locale: enLocale)
        #expect(!groups.isEmpty)

        for group in groups {
            let ordered = FranchiseSpinoffOrdering.orderedEntries(for: group, order: .release)
            let years = ordered.map { FranchiseCatalogBuilder.parseStartYear($0.entry.years) }

            // Once a nil (unparsable) year appears, every entry after it must
            // also be nil — nils are only ever a trailing run.
            var seenNil = false
            for year in years {
                if year == nil {
                    seenNil = true
                } else {
                    #expect(!seenNil, "Franchise '\(group.franchiseName)': a parsable year appeared after an unparsable one")
                }
            }

            // Among the parsable (non-nil) years, still non-decreasing.
            let parsableYears = years.compactMap { $0 }
            #expect(parsableYears == parsableYears.sorted(), "Franchise '\(group.franchiseName)': RELEASE years are not non-decreasing")
        }
    }

    // MARK: - displayNumber is exactly 1...n for both orders, every franchise

    @Test("displayNumber is exactly 1...n for both RECOMMENDED and RELEASE, every franchise")
    func displayNumbersAreContinuousBothOrders() async {
        let provider = BundledFranchiseProvider()
        let groups = await provider.allFranchiseGroups(locale: enLocale)
        #expect(!groups.isEmpty)

        for group in groups {
            for order in FranchiseDisplayOrder.allCases {
                let ordered = FranchiseSpinoffOrdering.orderedEntries(for: group, order: order)
                let numbers = ordered.map(\.displayNumber)
                let expected = Array(1...group.totalEntryCount)
                #expect(numbers == expected, "Franchise '\(group.franchiseName)', order \(order): displayNumbers not 1...\(group.totalEntryCount): \(numbers)")
            }
        }
    }

    // MARK: - Numbers are never carried over between orders

    @Test("RECOMMENDED and RELEASE numbering are independent — not copied from one another")
    func numberingIsRecomputedPerOrder() async {
        let provider = BundledFranchiseProvider()
        // Game of Thrones: RECOMMENDED numbers HotD=1, Knight=2, GoT=3 (bucket
        // order); RELEASE numbers GoT=1, HotD=2, Knight=3 (year order). If
        // numbering were ever copied from the other tab instead of recomputed,
        // these two entries would show the same number in both.
        let group = await provider.franchise(forShowId: 1399, mediaType: .tv, locale: enLocale)!

        let recommended = FranchiseSpinoffOrdering.orderedEntries(for: group, order: .recommended)
        let release = FranchiseSpinoffOrdering.orderedEntries(for: group, order: .release)

        let recommendedByTitle = Dictionary(uniqueKeysWithValues: recommended.map { ($0.entry.title, $0.displayNumber) })
        let releaseByTitle = Dictionary(uniqueKeysWithValues: release.map { ($0.entry.title, $0.displayNumber) })

        #expect(recommendedByTitle["Game of Thrones"] == 3)
        #expect(releaseByTitle["Game of Thrones"] == 1)
        #expect(recommendedByTitle["House of the Dragon"] == 1)
        #expect(releaseByTitle["House of the Dragon"] == 2)
    }

    // MARK: - Stability: ties in RELEASE keep source (recommended) order

    @Test("RELEASE keeps source order for entries sharing a start year (stability)")
    func releaseOrderIsStableForTies() {
        // Two spin-offs with the SAME start year, appearing in this order in
        // the recommended list (both .alongside — the bucket the fixture
        // exercises for its own reasons doesn't matter here, only that the
        // recommended-order index is 0 then 1 for these two ties).
        let group = FranchiseGroup(
            franchiseName: "Tie Fixture",
            sections: [
                FranchiseSection(bucket: .main, title: "Main", entries: [
                    FranchiseEntry(id: MediaKey(tmdbId: 1, mediaType: .tv), tmdbId: 1, mediaType: .tv,
                                   title: "Parent", years: "2010-2015", displayNumber: 1,
                                   relationLabel: "Main Series", statusLabel: nil, note: nil,
                                   isCurrentShow: false, isMainSeries: true)
                ]),
                FranchiseSection(bucket: .alongside, title: "Alongside", entries: [
                    FranchiseEntry(id: MediaKey(tmdbId: 2, mediaType: .tv), tmdbId: 2, mediaType: .tv,
                                   title: "Companion A", years: "2016", displayNumber: 2,
                                   relationLabel: "Spin-off", statusLabel: nil, note: nil,
                                   isCurrentShow: false, isMainSeries: false),
                    FranchiseEntry(id: MediaKey(tmdbId: 3, mediaType: .tv), tmdbId: 3, mediaType: .tv,
                                   title: "Companion B", years: "2016", displayNumber: 3,
                                   relationLabel: "Spin-off", statusLabel: nil, note: nil,
                                   isCurrentShow: false, isMainSeries: false)
                ])
            ],
            showsSectionHeaders: true,
            totalEntryCount: 3
        )

        let release = FranchiseSpinoffOrdering.orderedEntries(for: group, order: .release)
        let titles = release.map(\.entry.title)

        // Parent (2010) first, then the two 2016 ties in their original
        // (recommended-order) sequence: Companion A before Companion B.
        #expect(titles == ["Parent", "Companion A", "Companion B"])
    }

    // MARK: - Real-data sanity: the catalog actually has TBA entries, exercised above

    @Test("Yellowstone's TBA-year entries sort last in RELEASE without crashing")
    func yellowstoneTBAEntriesSortLast() async {
        let provider = BundledFranchiseProvider()
        // Yellowstone's real tmdbId in this catalog.
        guard let group = await provider.franchise(forShowId: 73586, mediaType: .tv, locale: enLocale) else {
            Issue.record("Yellowstone not found in the bundled catalog — tmdbId may have changed")
            return
        }

        let release = FranchiseSpinoffOrdering.orderedEntries(for: group, order: .release)
        let tbaEntries = release.filter { FranchiseCatalogBuilder.parseStartYear($0.entry.years) == nil }
        guard !tbaEntries.isEmpty else {
            Issue.record("Expected at least one TBA entry in Yellowstone for this test to be meaningful")
            return
        }

        let lastParsableIndex = release.lastIndex { FranchiseCatalogBuilder.parseStartYear($0.entry.years) != nil } ?? -1
        let firstTBAIndex = release.firstIndex { FranchiseCatalogBuilder.parseStartYear($0.entry.years) == nil } ?? Int.max
        #expect(firstTBAIndex > lastParsableIndex)
    }
}
