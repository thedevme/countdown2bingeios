//
//  ShowLimitTests.swift
//  Countdown2BingeTests
//
//  The free tier caps the library at three shows. These tests pin that number
//  and the boundary either side of it.
//
//  Why this exists: the cap was enforced in one place (`canAddShow`) and read
//  in several others, and for a long stretch a debug override forced
//  `isPremium = true` on every Debug build — so the free path was never
//  actually exercised while developing. A test that fails when the cap moves
//  is cheaper than finding out from a shipped build.
//
//  These run against the real singleton with no RevenueCat configuration, so
//  `isPremium` is false — which is exactly the free-tier path under test.
//

import Testing
import Foundation
@testable import Countdown2Binge

@MainActor
struct ShowLimitTests {

    @Test("Free tier allows exactly three shows")
    func freeLimitIsThree() {
        #expect(PremiumManager.shared.isPremium == false,
                "No RevenueCat entitlement in tests — if this is true, something is granting premium for free")
        #expect(PremiumManager.shared.showLimit == 3)
    }

    @Test("Below the cap, a free user can add")
    func canAddBelowLimit() {
        let manager = PremiumManager.shared
        #expect(manager.canAddShow(currentCount: 0))
        #expect(manager.canAddShow(currentCount: 1))
        #expect(manager.canAddShow(currentCount: 2))
    }

    @Test("At and above the cap, a free user cannot add")
    func cannotAddAtOrAboveLimit() {
        let manager = PremiumManager.shared
        // 3 shows already followed means the third slot is taken, not free.
        #expect(manager.canAddShow(currentCount: 3) == false)
        #expect(manager.canAddShow(currentCount: 4) == false)
        #expect(manager.canAddShow(currentCount: 99) == false)
    }

    @Test("The boundary sits between 2 and 3, not 3 and 4")
    func boundaryIsExact() {
        let manager = PremiumManager.shared
        let lastAllowed = 2
        #expect(manager.canAddShow(currentCount: lastAllowed))
        #expect(manager.canAddShow(currentCount: lastAllowed + 1) == false)
    }

    @Test("Over-limit is what the launch check compares against")
    func overLimitMatchesLaunchCheck() {
        // ContentView.checkForDowngrade uses `count > showLimit`, so three
        // shows is NOT over the limit — only four or more is.
        let limit = PremiumManager.shared.showLimit
        #expect((3 > limit) == false)
        #expect(4 > limit)
    }
}
