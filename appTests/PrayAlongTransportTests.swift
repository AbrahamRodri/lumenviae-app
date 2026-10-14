//
//  PrayAlongTransportTests.swift
//  Lumen Viae Tests
//
//  Play and pause on the pray-along between two prayers: a pause in the
//  breath holds the next prayer and play goes on to it; a pause while the
//  next prayer is on its way lets it arrive still, and a play before it
//  arrives lets it begin after all; the disc shows Pause through the
//  breath and the arrival.
//

import Testing

@testable import app

@MainActor
struct PrayAlongTransportTests {

    @Test func aPauseInTheBreathHoldsTheNextPrayerAndPlayGoesOnToIt() {
        var turn = PrayAlongTransport()
        turn.breathBegan()
        #expect(turn.goesOn(voiceSounding: false))

        #expect(turn.handle(.pause, voiceSounding: false) == .pause)
        #expect(!turn.goesOn(voiceSounding: false))
        #expect(turn.handle(.pause, voiceSounding: false) == .nothing)

        #expect(turn.handle(.play, voiceSounding: false) == .goToNext)
    }

    @Test func aPauseWhileTheNextPrayerLoadsLetsItArriveStill() {
        var turn = PrayAlongTransport()
        turn.turnBegan()
        #expect(turn.goesOn(voiceSounding: false), "on its way, the disc shows Pause")
        #expect(turn.startsOnArrival)

        #expect(turn.handle(.pause, voiceSounding: false) == .pause)
        #expect(!turn.startsOnArrival)
        #expect(!turn.goesOn(voiceSounding: false))

        // The page finishing its turn does not undo the pause
        turn.turnBegan()
        #expect(!turn.startsOnArrival)

        turn.arrived()
        #expect(turn.stage == .onPrayer)
        #expect(turn.handle(.play, voiceSounding: false) == .resume)
    }

    @Test func aPlayBeforeItArrivesLetsItBeginAfterAll() {
        var turn = PrayAlongTransport()
        turn.turnBegan()
        _ = turn.handle(.pause, voiceSounding: false)
        #expect(turn.handle(.play, voiceSounding: false) == .nothing)
        #expect(turn.startsOnArrival)
        #expect(turn.goesOn(voiceSounding: false))
    }

    @Test func toggleFollowsWhatTheDiscShows() {
        var turn = PrayAlongTransport()
        #expect(turn.handle(.toggle, voiceSounding: true) == .pause)
        #expect(turn.handle(.toggle, voiceSounding: false) == .resume)

        turn.breathBegan()
        #expect(turn.handle(.toggle, voiceSounding: false) == .pause)
        #expect(turn.stage == .heldInBreath)
        #expect(turn.handle(.toggle, voiceSounding: false) == .goToNext)
    }

    @Test func playWhileSoundingDoesNothing() {
        var turn = PrayAlongTransport()
        #expect(turn.handle(.play, voiceSounding: true) == .nothing)
        turn.breathBegan()
        #expect(turn.handle(.play, voiceSounding: false) == .nothing)
        turn.reset()
        #expect(turn.stage == .onPrayer)
    }
}
