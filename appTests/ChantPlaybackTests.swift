//
//  ChantPlaybackTests.swift
//  Lumen Viae Tests
//
//  What the chant player reckons with, apart from the player: the clock
//  carried between its readings (the line's end met on time, the mini
//  player's line moving smoothly), the reader's turn, what is said when a
//  chant will not play, the practice's words, the score file's reading,
//  and the shelf's writes gathered off the main actor.
//

import CoreGraphics
import Foundation
import SwiftUI
import Testing
import UIKit
@testable import app

@MainActor
struct ChantPlaybackTests {

    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    // MARK: - The clock

    @Test func theClockCarriesOnBetweenReadingsAtTheChantsPace() {
        var clock = ChantClock()
        clock.observe(10, playing: true, at: start)
        #expect(clock.time(at: start, rate: 1) == 10)
        #expect(abs(clock.time(at: start.addingTimeInterval(0.3), rate: 1) - 10.3) < 1e-6)
        #expect(abs(clock.time(at: start.addingTimeInterval(0.4), rate: 0.75) - 10.3) < 1e-6)
    }

    @Test func theSameReadingAgainDoesNotMoveTheAnchor() {
        var clock = ChantClock()
        clock.observe(10, playing: true, at: start)
        clock.observe(10, playing: true, at: start.addingTimeInterval(0.2))
        #expect(abs(clock.time(at: start.addingTimeInterval(0.4), rate: 1) - 10.4) < 1e-6)
        // A new reading anchors it afresh
        clock.observe(10.5, playing: true, at: start.addingTimeInterval(0.5))
        #expect(abs(clock.time(at: start.addingTimeInterval(0.6), rate: 1) - 10.6) < 1e-6)
    }

    @Test func aPausedClockStandsAtItsReading() {
        var clock = ChantClock()
        clock.observe(10, playing: true, at: start)
        clock.observe(10.2, playing: false, at: start.addingTimeInterval(0.2))
        #expect(clock.time(at: start.addingTimeInterval(30), rate: 1) == 10.2)
        // Taken up again, it counts from the moment it starts, not the pause
        clock.observe(10.2, playing: true, at: start.addingTimeInterval(30))
        #expect(abs(clock.time(at: start.addingTimeInterval(30.5), rate: 1) - 10.7) < 1e-6)
    }

    @Test func aResetClockAnchorsOnTheNextReadingEvenIfItRepeats() {
        var clock = ChantClock()
        clock.observe(10, playing: true, at: start)
        clock.reset()
        clock.observe(10, playing: true, at: start.addingTimeInterval(5))
        #expect(clock.time(at: start.addingTimeInterval(5), rate: 1) == 10)
    }

    // MARK: - The reader's turn

    @Test func aTurnIsTheLineAtItsPaceAndABreath() {
        let line = ChantLine(latin: "Salve", english: "Hail", start: 2, end: 5)
        #expect(abs(ChantTurn.length(of: line, speed: 1) - 3.6) < 1e-6)
        #expect(abs(ChantTurn.length(of: line, speed: 0.75) - 4.6) < 1e-6)
        // Never slower than half speed, and four seconds for no line
        #expect(abs(ChantTurn.length(of: line, speed: 0.1) - 6.6) < 1e-6)
        #expect(abs(ChantTurn.length(of: nil, speed: 1) - 4.6) < 1e-6)
    }

    // MARK: - Errors

    @Test func aChantThatWillNotPlaySaysWhy() {
        #expect(ChantPlayError.missing.message == "This chant's recording is missing.")
        #expect(ChantPlayError.failed.message == "The chant couldn't be played.")
        #expect(ChantPlayError.missing.caption.count <= 18)
        #expect(ChantPlayError.failed.caption.count <= 18)
    }

    // MARK: - Practice words

    @Test func practiceWordsAreCutToTheirFirstLetters() {
        let text = "Salve, Regína, Mater misericórdiæ:\nVita, dulcédo"
        #expect(ChantPracticeWords.hidden(text, .none) == text)
        #expect(ChantPracticeWords.hidden(text, .half) == "Salve, R·····, Mater m···········:\nVita, d······")
        #expect(ChantPracticeWords.hidden(text, .all) == "S····, R·····, M···· m···········:\nV···, d······")
        let prayer = "℣. Ora pro nobis.\n[Let us pray.]\n℟. Ut digni efficiámur."
        #expect(ChantPracticeWords.plain(prayer) == "Ora pro nobis.\nUt digni efficiámur.")
        #expect(ChantPracticeView.plain(prayer) == ChantPracticeWords.plain(prayer))
    }

    // MARK: - The score file

    @Test func aScoreFileReadsEachKindOfOperation() throws {
        let text = "LVSCORE 1\n0 0 100 50\nI M0,0h10v10h-10z\nR M20,0h5v5h-5z\nW M2,2h2v2h-2z\nS0.8 M0,40L100,40\nT1.5 M0,45L100,45\n"
        let drawing = try #require(ChantScoreDrawing.parse(text))
        #expect(drawing.operations.count == 5)
        guard case .fill(let ink, .ink) = drawing.operations[0] else { Issue.record("not an ink fill"); return }
        #expect(ink.boundingRect == CGRect(x: 0, y: 0, width: 10, height: 10))
        guard case .fill(_, .rubric) = drawing.operations[1] else { Issue.record("not a red fill"); return }
        guard case .erase(let white) = drawing.operations[2] else { Issue.record("not an erase"); return }
        #expect(white.boundingRect == CGRect(x: 2, y: 2, width: 2, height: 2))
        guard case .stroke(_, .ink, let width) = drawing.operations[3] else { Issue.record("not an ink stroke"); return }
        #expect(width == 0.8)
        guard case .stroke(_, .rubric, let red) = drawing.operations[4] else { Issue.record("not a red stroke"); return }
        #expect(red == 1.5)
    }

    @Test func aScoreFileThatIsNotOneReadsAsNothing() {
        #expect(ChantScoreDrawing.parse("") == nil)
        #expect(ChantScoreDrawing.parse("LVSCORE 2\n0 0 100 50\n") == nil)
        #expect(ChantScoreDrawing.parse("LVSCORE 1\n0 0 0 50\n") == nil)
        #expect(ChantScoreDrawing.parse("LVSCORE 1\n0 0 100\n") == nil)
        // A line of a kind this build does not know is passed over
        #expect(ChantScoreDrawing.parse("LVSCORE 1\n0 0 100 50\nX M0,0h1\nI M0,0h1v1z\n")?.operations.count == 1)
    }

    // MARK: - The shelf's writes

    @Test func aGatheredShelfWritesOnceFlushedAndKeepsWhatALaterBuildWrote() throws {
        let defaults = try #require(UserDefaults(suiteName: "ChantPlaybackTests.\(UUID().uuidString)"))
        let record: [String: Any] = ["chantID": "sub_tuum", "step": 2, "touched": 0, "reminder": "evening"]
        defaults.set(try JSONSerialization.data(withJSONObject: [record]), forKey: "chantShelf.learning")

        let shelf = ChantShelfStore(defaults: defaults, writes: .afterAPause, appIsActive: { true })
        let set = shelf.newSet(named: "Holy hour")
        shelf.addChant("adoro_te", to: set.id)
        shelf.setStep(.singAlong, for: "sub_tuum")
        shelf.notePlayed("adoro_te")
        #expect(defaults.data(forKey: "chantShelf.sets") == nil, "held back until flushed")
        #expect(defaults.data(forKey: "chantShelf.recent") == nil, "held back until flushed")
        shelf.flush()

        let again = ChantShelfStore(defaults: defaults)
        #expect(again.set(set.id)?.items.count == 1)
        #expect(again.step(of: "sub_tuum") == .singAlong)
        #expect(again.recent.first?.chantID == "adoro_te")
        let written = try JSONSerialization.jsonObject(with: try #require(defaults.data(forKey: "chantShelf.learning")))
        let learning = try #require(written as? [[String: Any]])
        #expect(learning.first?["reminder"] as? String == "evening")
    }

    @Test func theLastGatheredChangeWins() throws {
        let defaults = try #require(UserDefaults(suiteName: "ChantPlaybackTests.\(UUID().uuidString)"))
        let shelf = ChantShelfStore(defaults: defaults, writes: .afterAPause, appIsActive: { true })
        let set = shelf.newSet(named: "First")
        shelf.rename(set.id, to: "Second")
        shelf.rename(set.id, to: "Third")
        #expect(ChantShelfStore(defaults: defaults).set(set.id) == nil, "held back until flushed")
        shelf.flush()
        #expect(ChantShelfStore(defaults: defaults).set(set.id)?.name == "Third")
    }

    /// What is still gathered is written as the app leaves the front
    @Test func aGatheredShelfWritesAsTheAppResigns() async throws {
        let defaults = try #require(UserDefaults(suiteName: "ChantPlaybackTests.\(UUID().uuidString)"))
        let shelf = ChantShelfStore(defaults: defaults, writes: .afterAPause, appIsActive: { true })
        shelf.notePlayed("adoro_te")
        #expect(defaults.data(forKey: "chantShelf.recent") == nil, "held back until the app resigns")
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        for _ in 0..<20 where defaults.data(forKey: "chantShelf.recent") == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(ChantShelfStore(defaults: defaults).recent.first?.chantID == "adoro_te")
        withExtendedLifetime(shelf) {}
    }

    /// A change made with the app in the background, from the Lock
    /// Screen, is written at once rather than gathered
    @Test func aShelfInTheBackgroundWritesAtOnce() throws {
        let defaults = try #require(UserDefaults(suiteName: "ChantPlaybackTests.\(UUID().uuidString)"))
        let shelf = ChantShelfStore(defaults: defaults, writes: .afterAPause, appIsActive: { false })
        shelf.notePlayed("adoro_te")
        #expect(ChantShelfStore(defaults: defaults).recent.first?.chantID == "adoro_te")
    }

    @Test func aGatheredShelfWritesOnItsOwnAfterAPause() async throws {
        let defaults = try #require(UserDefaults(suiteName: "ChantPlaybackTests.\(UUID().uuidString)"))
        let shelf = ChantShelfStore(defaults: defaults, writes: .afterAPause, appIsActive: { true })
        let set = shelf.newSet(named: "Night prayer")
        for _ in 0..<40 {
            if ChantShelfStore(defaults: defaults).set(set.id) != nil { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(ChantShelfStore(defaults: defaults).set(set.id)?.name == "Night prayer")
    }
}
