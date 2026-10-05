//
//  AudioRateTests.swift
//  Lumen Viae Tests
//
//  The narration speed: any speed read or set is brought into range and
//  onto the twentieths, a nonsense speed falls back to 1×, and a speed a
//  flow borrows may reach further than the app's own.
//

import Testing
@testable import app

@MainActor
struct AudioRateTests {

    @Test(arguments: [
        (1.0, 1.0),
        (1.15, 1.15),
        (1.12, 1.1),
        (1.13, 1.15),
        (0.5, 0.7),
        (2.0, 1.7),
        (0.74, 0.75)
    ])
    func aSpeedIsClampedAndRoundedToTwentieths(rate: Double, resolved: Double) {
        #expect(abs(AudioService.resolvedRate(rate) - resolved) < 0.0001)
    }

    @Test(arguments: [0.0, -1.0, Double.nan, Double.infinity])
    func aNonsenseSpeedIsOneTimes(rate: Double) {
        #expect(AudioService.resolvedRate(rate) == 1.0)
    }

    @Test func everyResolvedSpeedStaysInRange() {
        for step in 0...60 {
            let rate = 0.4 + Double(step) * 0.03
            let resolved = AudioService.resolvedRate(rate)
            #expect(AudioService.rateRange.contains(resolved))
        }
    }

    @Test func aBorrowedSpeedMayReachTheShelfsTwoTimes() {
        #expect(AudioService.resolvedRate(2.0, in: 0.5...2.0) == 2.0)
    }

    @Test func theLockScreenPresetsIncludeOneTimes() {
        #expect(AudioService.supportedRates.contains(1.0))
        #expect(AudioService.supportedRates == AudioService.supportedRates.sorted())
    }
}
