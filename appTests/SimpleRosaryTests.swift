//
//  SimpleRosaryTests.swift
//  Lumen Viae Tests
//
//  The simple Rosary (the One Rosary beta): where the pill's parts go in
//  a spoken Rosary, that nothing is lit without a recording's real
//  timings, muted or not, that a set with no recording opens as text,
//  who begins on the beginner's path (and that a no is kept), the
//  speed steps and the one text size, and that with the switch off
//  every rule is the app's as it was.
//

import Foundation
import Testing

@testable import app

@MainActor
struct SimpleRosaryTests {

    // MARK: - The Pill's Parts

    @Test func theStopsRunFromTheOpeningToTheClose() {
        #expect(RosaryStop.all(decades: 5, includesPendant: true)
            == [.opening, .mystery(0), .mystery(1), .mystery(2), .mystery(3), .mystery(4), .closing])
        #expect(RosaryStop.all(decades: 7, includesPendant: true).count == 9)
        #expect(RosaryStop.all(decades: 5, includesPendant: false) == (0..<5).map(RosaryStop.mystery))
    }

    @Test(arguments: [MysteryCategory.joyful, .sevenSorrows])
    func eachStopGoesToItsPartOfTheScript(category: MysteryCategory) {
        let decades = category == .sevenSorrows ? 7 : 5
        let keys = (1...decades).map { "\(category.rawValue)_\($0)" }
        let script = SpokenRosaryScript.build(
            category: category, mysteryKeys: keys,
            hailMarys: category == .sevenSorrows ? 7 : 10, style: .meditation)

        #expect(RosaryStop.opening.scriptIndex(in: script) == 0)
        for n in 0..<decades {
            let index = try! #require(RosaryStop.mystery(n).scriptIndex(in: script))
            // A mystery begins on its announcement, its meditation next
            #expect(script[index].kind == .announcement)
            #expect(script[index].mystery == n)
            #expect(script[index + 1].kind == .meditation)
        }
        let closing = try! #require(RosaryStop.closing.scriptIndex(in: script))
        #expect(script[closing].phase == .closing)
        #expect(script[closing - 1].phase == .decade)
    }

    @Test func theStopUnderTheHand() {
        #expect(RosaryStop.current(phase: .opening, mystery: 0) == .opening)
        #expect(RosaryStop.current(phase: .decade, mystery: 3) == .mystery(3))
        #expect(RosaryStop.current(phase: nil, mystery: 2) == .mystery(2))
        #expect(RosaryStop.current(phase: .closing, mystery: 4) == .closing)
        let stops = RosaryStop.all(decades: 5, includesPendant: true)
        #expect(RosaryStop.mystery(1).position(in: stops) == 2)
    }

    // MARK: - Muted, and Lit Only From Real Timings

    @Test func withNoTimingsNothingIsLitMutedOrNot() {
        #expect(SimpleRosary.highlightedLine(timings: nil, at: 12) == nil)
        #expect(SimpleRosary.highlightedLine(timings: [], at: 12) == nil)
        let lines = ["Hail Mary, full of grace", "the Lord is with thee"]
        #expect(SimpleRosary.displayedLines(timings: nil, fallback: lines) == lines)
    }

    @Test func withTimingsTheLineBeingSaidIsLit() {
        let timings = [
            TimedLine(text: "One", start: 0.4, end: 3),
            TimedLine(text: "Two", start: 3.5, end: 6),
            TimedLine(text: "Three", start: 6.2, end: 9),
        ]
        #expect(SimpleRosary.highlightedLine(timings: timings, at: 0.1) == nil)
        #expect(SimpleRosary.highlightedLine(timings: timings, at: 1) == 0)
        // The breath between two lines keeps the last one lit
        #expect(SimpleRosary.highlightedLine(timings: timings, at: 3.2) == 0)
        #expect(SimpleRosary.highlightedLine(timings: timings, at: 4) == 1)
        #expect(SimpleRosary.highlightedLine(timings: timings, at: 30) == 2)
        #expect(SimpleRosary.displayedLines(timings: timings, fallback: ["x"]) == ["One", "Two", "Three"])
    }

    @Test func theServersLinesDecode() throws {
        let json = #"[{"meditation_id":127,"voice":"female","audio":{"url":"https://x/voices/female/a.mp3","expires_at":"2026-11-06T03:30:50Z"},"lines":[{"text":"Seven centuries before","start":0.0,"end":11.9}]},{"meditation_id":128,"voice":"female","audio":{"url":"https://x/b.mp3"},"lines":null}]"#
        let answer = try JSONDecoder().decode([APIService.TimedNarration].self, from: Data(json.utf8))
        #expect(answer[0].lines?.first?.end == 11.9)
        #expect(answer[1].lines == nil)
        let clip = #"{"file":"hail_mary-1.mp3","audio_url":"https://x/h.mp3"}"#
        #expect(try JSONDecoder().decode(RosaryAudioClip.self, from: Data(clip.utf8)).lines == nil)
    }

    @Test func timingsInAShapeTheAppDoesNotExpectNeverBreakTheManifest() throws {
        // Lines as a string, lines with a field missing, lines as an
        // object: each clip still decodes, with no timings, and so does
        // the whole manifest it stands in
        let odd = [
            #""lines":"soon""#,
            #""lines":[{"text":"Hail Mary","start":0}]"#,
            #""lines":{"text":"Hail Mary"}"#,
            #""lines":[{"text":"Hail Mary","start":"0","end":2.5}]"#,
        ]
        for lines in odd {
            let clip = #"{"file":"hail_mary-1.mp3","audio_url":"https://x/h.mp3",\#(lines)}"#
            let decoded = try JSONDecoder().decode(RosaryAudioClip.self, from: Data(clip.utf8))
            #expect(decoded.lines == nil)
            #expect(decoded.file == "hail_mary-1.mp3")

            let manifest = #"{"voice":"frederick","version":"v1","prayers":{"hail_mary":\#(clip)}}"#
            let read = try JSONDecoder().decode(RosaryAudioManifest.self, from: Data(manifest.utf8))
            #expect(read.prayers?["hail_mary"]?.audioUrl == "https://x/h.mp3")
        }
        // Lines in the shape served still read
        let good = #"{"file":"f.mp3","audio_url":"https://x/f.mp3","lines":[{"text":"Hail Mary","start":0,"end":2.5}]}"#
        #expect(try JSONDecoder().decode(RosaryAudioClip.self, from: Data(good.utf8)).lines?.count == 1)
    }

    // MARK: - Every Prayer Aloud, or Read

    @Test func withTheBetaEveryFormIsSaidAloud() {
        #expect(SimpleRosary.praysAloud(beta: true, setting: false, form: .meditation, setHasRecording: true))
        #expect(SimpleRosary.praysAloud(beta: true, setting: false, form: .scriptural))
        #expect(SimpleRosary.praysAloud(beta: true, setting: false, form: .holy))
    }

    @Test func aSetWithNoRecordingOpensAsText() {
        #expect(SimpleRosary.opensAsText(beta: true, setHasRecording: false))
        #expect(!SimpleRosary.opensAsText(beta: true, setHasRecording: true))
        #expect(!SimpleRosary.praysAloud(beta: true, setting: true, form: .meditation, setHasRecording: false))
    }

    @Test func withTheSwitchOffTheAudioChoiceDecidesAsItDid() {
        for setting in [false, true] {
            for recording in [false, true] {
                #expect(SimpleRosary.praysAloud(beta: false, setting: setting, form: .meditation, setHasRecording: recording) == setting)
                #expect(!SimpleRosary.opensAsText(beta: false, setHasRecording: recording))
            }
            #expect(SimpleRosary.praysAloud(beta: false, setting: setting, form: .scriptural) == setting)
            #expect(SimpleRosary.praysAloud(beta: false, setting: setting, form: .holy))
        }
        #expect(RosaryChoice.offered(for: .meditation, aloud: false, oneRosary: false) == [.audio, .counting])
    }

    // MARK: - The Beginner

    @Test func aLearnerTakesTheBeginnersPathOnlyWithTheBeta() {
        #expect(SimpleRosary.beginnerPath(beta: true, intentions: [.learning]))
        #expect(SimpleRosary.beginnerPath(beta: true, intentions: [.peace, .learning]))
        #expect(!SimpleRosary.beginnerPath(beta: true, intentions: [.peace, .habit]))
        #expect(!SimpleRosary.beginnerPath(beta: false, intentions: [.learning]))
    }

    @Test func aNoOnTheBeginnersPageIsKept() {
        #expect(SimpleRosary.remembersDecline)
        #expect(!SimpleRosary.beginnerPath(beta: true, intentions: [.learning], declined: true))
        #expect(SimpleRosary.beginnerPath(beta: true, intentions: [.learning], declined: false))

        let settings = UserSettings.shared
        let (beta, intentions, declined) = (settings.oneRosaryBeta, settings.onboardingIntentions, settings.declinedBeginnerRosary)
        defer {
            settings.oneRosaryBeta = beta
            settings.onboardingIntentions = intentions
            settings.declinedBeginnerRosary = declined
        }
        settings.oneRosaryBeta = true
        settings.onboardingIntentions = [PrayerIntention.learning.rawValue]
        settings.declinedBeginnerRosary = false
        #expect(SimpleRosary.offersBeginnerPath(settings))
        settings.declinedBeginnerRosary = true
        #expect(!SimpleRosary.offersBeginnerPath(settings))
    }

    @Test func theBeginnersSetIsStAlphonsus() throws {
        let json = #"[{"id":26,"name":"Blessed Fulton J. Sheen","category":"joyful","author":"Archbishop Fulton J. Sheen"},{"id":29,"name":"St. Alphonsus Liguori","category":"joyful","author":"St. Alphonsus Liguori"}]"#
        let joyful = try JSONDecoder().decode([MeditationSetSummary].self, from: Data(json.utf8))
        #expect(SimpleRosary.beginnerSet(from: joyful)?.id == 29)
        // Where he wrote none, the first set offered
        #expect(SimpleRosary.beginnerSet(from: [joyful[0]])?.id == 26)
        #expect(SimpleRosary.beginnerSet(from: []) == nil)
    }

    // MARK: - Speed and Size

    @Test func meditationsAreHeardAtTheirOwnPaceAndPrayersAtTheChosenOne() {
        #expect(SpokenRosaryPlayer.playsAtNaturalPace(.meditation))
        #expect(!SpokenRosaryPlayer.playsAtNaturalPace(.prayer("hail_mary")))
        #expect(!SpokenRosaryPlayer.playsAtNaturalPace(.announcement))
        #expect(!SpokenRosaryPlayer.playsAtNaturalPace(.verse(3)))
    }

    @Test func theSpeedStepsRunFromPointEightToOnePointThree() {
        #expect(PlaybackSpeedChoice.steps == [0.8, 0.9, 1.0, 1.1, 1.2, 1.3])
        // Every step is a speed the service keeps as it is
        for step in PlaybackSpeedChoice.steps {
            #expect(AudioService.resolvedRate(step) == step)
        }
        #expect(PlaybackSpeedChoice.isChosen(1.1, appRate: AudioService.resolvedRate(1.1)))
        // A speed kept from the slider that is no step lights none
        #expect(!PlaybackSpeedChoice.steps.contains { PlaybackSpeedChoice.isChosen($0, appRate: 1.5) })
    }

    @Test func everyPrayerIsSetAtOneSizeThatNeverOutgrowsTheColumn() {
        #expect(SimpleRosary.wordsSize(scale: 0) == 15)
        #expect(SimpleRosary.wordsSize(scale: 1) == 22)
        #expect(SimpleRosary.wordsSize(scale: 0.5) == 18.5)
        // The slider's whole travel changes the size, and nothing past it
        #expect(SimpleRosary.wordsSize(scale: 0.2) < SimpleRosary.wordsSize(scale: 0.8))
        #expect(SimpleRosary.wordsSize(scale: 4) == 22)
        #expect(SimpleRosary.wordsSize(scale: -1) == 15)
    }
}
