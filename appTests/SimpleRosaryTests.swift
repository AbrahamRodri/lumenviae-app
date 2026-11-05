//
//  SimpleRosaryTests.swift
//  Lumen Viae Tests
//
//  The simple Rosary: where the pill's parts go in
//  a spoken Rosary, that nothing is lit without a recording's real
//  timings, muted or not, that a set with no recording opens as text,
//  who begins on the beginner's path (and that a no is kept), the
//  speed steps, the one text size, and the reader following real lines.
//

import Foundation
import SwiftUI
import Testing

@testable import app

@MainActor
struct SimpleRosaryTests {

    // MARK: - The Helps on a Spoken Pendant

    /// Said aloud, the opening and closing prayers are the spoken
    /// script's, and the beginner's helps must still find their step on
    /// the pendant: every opening and closing prayer of the voice's
    /// script is the same step the silent pendant has, and a prayer said
    /// after the Rosary has none
    @Test func everyPrayerTheVoiceSaysOnThePendantIsAStep() {
        let pendant = SilentPendant(category: .joyful)
        let keys = MysteryData.mysteries(for: .joyful).map { "\($0.category.lowercased())_\($0.order)" }
        let script = SpokenRosaryScript.build(
            category: .joyful, mysteryKeys: keys, hailMarys: 10, style: .plain,
            extras: [.holyFather, .memorare, .stMichael]
        )
        let opening = script.indices.filter { script[$0].phase == .opening }
        #expect(opening.compactMap { pendant.step(at: $0, in: script) }
            == pendant.opening.indices.map(SilentPendant.Step.opening))
        let closing = script.indices.compactMap { pendant.step(at: $0, in: script) }.filter {
            if case .closing = $0 { return true } else { return false }
        }
        #expect(closing == pendant.closing.indices.map(SilentPendant.Step.closing))
        let memorare = script.firstIndex { $0.kind == .prayer("memorare") }
        #expect(memorare.flatMap { pendant.step(at: $0, in: script) } == nil)
        let decade = script.firstIndex { $0.phase == .decade }
        #expect(decade.flatMap { pendant.step(at: $0, in: script) } == nil)
    }

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

    @Test func everyFormIsSaidAloud() {
        #expect(SimpleRosary.praysAloud(form: .meditation, setHasRecording: true))
        #expect(SimpleRosary.praysAloud(form: .scriptural))
        #expect(SimpleRosary.praysAloud(form: .holy))
    }

    @Test func aSetWithNoRecordingOpensAsText() {
        #expect(SimpleRosary.opensAsText(setHasRecording: false))
        #expect(!SimpleRosary.opensAsText(setHasRecording: true))
        #expect(!SimpleRosary.praysAloud(form: .meditation, setHasRecording: false))
    }

    // MARK: - The Beginner

    @Test func aLearnerTakesTheBeginnersPath() {
        #expect(SimpleRosary.beginnerPath(intentions: [.learning]))
        #expect(SimpleRosary.beginnerPath(intentions: [.peace, .learning]))
        #expect(!SimpleRosary.beginnerPath(intentions: [.peace, .habit]))
    }

    @Test func aNoOnTheBeginnersPageIsKept() {
        #expect(SimpleRosary.remembersDecline)
        #expect(!SimpleRosary.beginnerPath(intentions: [.learning], declined: true))
        #expect(SimpleRosary.beginnerPath(intentions: [.learning], declined: false))

        let settings = UserSettings.shared
        let (intentions, declined) = (settings.onboardingIntentions, settings.declinedBeginnerRosary)
        defer {
            settings.onboardingIntentions = intentions
            settings.declinedBeginnerRosary = declined
        }
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

    // MARK: - The Reader Follows Real Lines

    @Test func theReaderFindsTheParagraphALineIsIn() {
        let paragraphs = [
            "Behold, the angel Gabriel was sent from God to a city of Galilee.",
            "And the angel being come in, said unto her: Hail, full of grace, the Lord is with thee.",
        ]
        #expect(SimpleRosary.paragraph(of: "And the angel being come in, said unto her:", in: paragraphs) == 1)
        // Case, accents and punctuation folded
        #expect(SimpleRosary.paragraph(of: "behold — the ANGEL Gabriel", in: paragraphs) == 0)
        // A line no paragraph holds moves nothing
        #expect(SimpleRosary.paragraph(of: "Glory be to the Father", in: paragraphs) == nil)
        #expect(SimpleRosary.paragraph(of: "", in: paragraphs) == nil)
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

    @Test("A tall lit line is read down by its own start and end, never a guess")
    func theLitLinesProgressComesFromItsTimings() {
        let timings = [
            TimedLine(text: "And I will pour out upon the house of David", start: 2, end: 22),
            TimedLine(text: "Amen.", start: 23, end: 24),
        ]
        #expect(SimpleRosary.litLineProgress(timings: nil, at: 5) == nil)
        #expect(SimpleRosary.litLineProgress(timings: timings, at: 1) == nil)
        #expect(SimpleRosary.litLineProgress(timings: timings, at: 2) == 0)
        #expect(SimpleRosary.litLineProgress(timings: timings, at: 12) == 0.5)
        // Held at its end through the breath before the next line
        #expect(SimpleRosary.litLineProgress(timings: timings, at: 22.5) == 1)
        #expect(SimpleRosary.litLineProgress(timings: timings, at: 23.5) == 0.5)
    }

    @Test("In Spanish a prayer keeps its Spanish words, not the English recording's lines")
    func spanishPrayersKeepTheirWords() {
        #expect(SimpleRosary.keepsOwnWords(.prayer("hail_mary"), spanish: true))
        #expect(!SimpleRosary.keepsOwnWords(.prayer("hail_mary"), spanish: false))
        #expect(!SimpleRosary.keepsOwnWords(.meditation, spanish: true))
        #expect(!SimpleRosary.keepsOwnWords(.verse(3), spanish: true))
        // A meditation translated into Spanish keeps its Spanish too
        #expect(SimpleRosary.keepsOwnWords(.meditation, spanish: true, meditationIsSpanish: true))
        #expect(!SimpleRosary.keepsOwnWords(.meditation, spanish: false, meditationIsSpanish: true))
    }

    @Test("A tall line's foot comes to rest above the fade")
    func aTallLineEndsAboveTheFade() {
        let h: CGFloat = 600, v: CGFloat = 300
        #expect(SimpleRosaryWords.tallLineAnchor(progress: 0, lineHeight: h, wordsHeight: v) == 0)
        let end = SimpleRosaryWords.tallLineAnchor(progress: 1, lineHeight: h, wordsHeight: v)
        // The line's top sits at end * (V - H); its foot at that plus H
        let foot = end * Double(v - h) + Double(h)
        #expect(abs(foot - SimpleRosaryWords.tallLineFoot * Double(v)) < 0.001)
        // A line a little shorter than the words ends above the fade too
        let near: CGFloat = 280
        let nearEnd = SimpleRosaryWords.tallLineAnchor(progress: 1, lineHeight: near, wordsHeight: v)
        #expect(abs(nearEnd * Double(v - near) + Double(near) - SimpleRosaryWords.tallLineFoot * Double(v)) < 0.001)
    }

    @Test("With the words put away, the head is set low over the foot, not left where the words were")
    func theHeadIsPlacedWhenTheWordsArePutAway() {
        let shown = OneRosaryColumn<EmptyView>.layout(showsWords: true, columnTop: 300, headerFoot: 70)
        #expect(shown.top == 300 && shown.alignment == .top)
        let hidden = OneRosaryColumn<EmptyView>.layout(showsWords: false, columnTop: 300, headerFoot: 70)
        #expect(hidden.top == 0 && hidden.alignment == .bottom)
    }
}
