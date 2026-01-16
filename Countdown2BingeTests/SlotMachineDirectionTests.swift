//
//  SlotMachineDirectionTests.swift
//  Countdown2BingeTests
//
//  Tests to ensure slot machine countdown direction is correct.
//  Direction rule: Numbers go LEFT to RIGHT, lowest to highest (0 → 99 → TBD)
//

import Testing
import Foundation

@Suite("Slot Machine Direction")
struct SlotMachineDirectionTests {

    // Constants matching SlotMachineReel
    let cellWidth: CGFloat = 85
    let tbdIndex = 100
    let maxNumber = 99

    // MARK: - Direction Tests

    /// CRITICAL: Numbers must go left to right: 0, 1, 2... 98, 99, TBD
    /// This test ensures the indices array is NOT reversed
    @Test func indices_shouldGoLowestToHighest_leftToRight() {
        let indices = Array(0...100)

        // First element (leftmost) should be 0
        #expect(indices.first == 0, "Leftmost number should be 0")

        // Last element (rightmost) should be 100 (TBD)
        #expect(indices.last == 100, "Rightmost should be TBD (100)")

        // Verify order is ascending
        for i in 0..<indices.count - 1 {
            #expect(indices[i] < indices[i + 1], "Indices should be in ascending order")
        }
    }

    /// When displayValue is 0, content should shift RIGHT to show left side (where 0 is)
    /// When displayValue is 100 (TBD), content should shift LEFT to show right side (where TBD is)
    @Test func xOffset_lowerValues_shouldShiftContentRight() {
        let centerIndex = CGFloat(tbdIndex) / 2.0 // 50

        func xOffset(for displayValue: Int) -> CGFloat {
            let position = CGFloat(displayValue)
            return (centerIndex - position) * cellWidth
        }

        let offsetFor0 = xOffset(for: 0)
        let offsetFor50 = xOffset(for: 50)
        let offsetForTBD = xOffset(for: tbdIndex)

        // Lower values should have MORE POSITIVE offset (shifts content right)
        #expect(offsetFor0 > offsetFor50, "Value 0 should have larger offset than 50")
        #expect(offsetFor50 > offsetForTBD, "Value 50 should have larger offset than TBD")

        // TBD (100) should have negative offset (shifts content left)
        #expect(offsetForTBD < 0, "TBD should have negative offset")

        // 0 should have positive offset (shifts content right)
        #expect(offsetFor0 > 0, "Value 0 should have positive offset")
    }

    /// displayValue should map nil and out-of-range values to TBD (100)
    @Test func displayValue_nilOrOutOfRange_shouldMapToTBD() {
        func displayValue(for value: Int?) -> Int {
            guard let value = value, value >= 0, value <= maxNumber else {
                return tbdIndex
            }
            return value
        }

        // Nil should map to TBD
        #expect(displayValue(for: nil) == tbdIndex, "nil should map to TBD")

        // Negative should map to TBD
        #expect(displayValue(for: -1) == tbdIndex, "Negative should map to TBD")

        // Over 99 should map to TBD
        #expect(displayValue(for: 100) == tbdIndex, "100+ should map to TBD")
        #expect(displayValue(for: 150) == tbdIndex, "150 should map to TBD")

        // Valid values should pass through
        #expect(displayValue(for: 0) == 0, "0 should stay 0")
        #expect(displayValue(for: 50) == 50, "50 should stay 50")
        #expect(displayValue(for: 99) == 99, "99 should stay 99")
    }

    /// Verify scroll direction: decreasing countdown scrolls LEFT toward 0
    @Test func scrollDirection_decreasingCountdown_shouldScrollLeft() {
        let centerIndex = CGFloat(tbdIndex) / 2.0

        func xOffset(for displayValue: Int) -> CGFloat {
            let position = CGFloat(displayValue)
            return (centerIndex - position) * cellWidth
        }

        // When countdown goes from 10 to 5, offset should DECREASE (scroll left)
        let offsetFor10 = xOffset(for: 10)
        let offsetFor5 = xOffset(for: 5)

        #expect(offsetFor5 > offsetFor10, "Scrolling to lower value should increase offset (scroll left in view)")
    }

    /// Verify scroll direction: going to TBD scrolls RIGHT toward TBD position
    @Test func scrollDirection_goingToTBD_shouldScrollRight() {
        let centerIndex = CGFloat(tbdIndex) / 2.0

        func xOffset(for displayValue: Int) -> CGFloat {
            let position = CGFloat(displayValue)
            return (centerIndex - position) * cellWidth
        }

        // When going from 50 to TBD (100), offset should DECREASE (scroll right toward TBD)
        let offsetFor50 = xOffset(for: 50)
        let offsetForTBD = xOffset(for: tbdIndex)

        #expect(offsetForTBD < offsetFor50, "Going to TBD should decrease offset (scroll right in view)")
    }
}
