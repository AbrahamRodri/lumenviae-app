//
//  APIContractAndFeastsTests.swift
//  Lumen Viae Tests
//
//  What the app reads from the server, decoded as the server sends it —
//  a meditation set with its meditations, narrations in voices, and its
//  painting as a flat block of image_* keys — and the voice a meditation
//  is played in; then the Marian feasts a consecration can end on, each
//  begun thirty-three days before.
//

import Foundation
import Testing
@testable import app

@MainActor
struct MeditationSetDecodingTests {

    private let setJSON = """
    {
      "id": 12,
      "name": "St. Alphonsus Liguori",
      "category": "Joyful",
      "description": "The Glories of Mary.",
      "labels": ["Saints", "Considerations"],
      "author": "St. Alphonsus Liguori",
      "source": "The Glories of Mary",
      "audio_expires_at": "2000-01-01T00:00:00Z",
      "image_url": "https://example.org/annunciation.jpg",
      "image_alignment": null,
      "image_focal_x": 0.4,
      "image_focal_y": null,
      "image_width": 1200,
      "image_height": 1600,
      "image_alt": "The Annunciation",
      "image_attribution": {"title": "The Annunciation", "artist": "Fra Angelico", "year": "c. 1440", "source_url": null, "license": "Public domain"},
      "meditations": [
        {
          "id": 101,
          "title": null,
          "content": "Consider how the Angel...",
          "author": null,
          "source": null,
          "audio_url": "https://example.org/101-frederick.mp3",
          "narrations": [
            {"voice": "frederick", "audio_url": "https://example.org/101-frederick.mp3"},
            {"voice": "female", "audio_url": "https://example.org/101-female.mp3"}
          ],
          "mystery": {"id": 1, "name": "The Annunciation", "category": "joyful", "order": 1, "description": null, "scripture_reference": "Luke 1:26-38"}
        }
      ]
    }
    """

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: Data(json.utf8))
    }

    @Test func aFullSetDecodesWithItsMeditations() throws {
        let set = try decode(MeditationSet.self, setJSON)
        #expect(set.id == 12)
        #expect(set.mysteryCategory == .joyful, "the category is read whatever its case")
        #expect(set.meditationCount == 1, "meditations must never decode to nil")
        #expect(set.labels == ["Saints", "Considerations"])
        #expect(set.hasAudio)
        let meditation = try #require(set.meditations?.first)
        #expect(meditation.displayTitle == "The Annunciation", "untitled, it takes its mystery's name")
        #expect(meditation.mystery?.scriptureReference == "Luke 1:26-38")
        #expect(meditation.availableVoices == ["frederick", "female"])
    }

    @Test func thePaintingIsReadFromTheFlatBlock() throws {
        let artwork = try #require(try decode(MeditationSet.self, setJSON).artwork)
        #expect(artwork.url == "https://example.org/annunciation.jpg")
        #expect(artwork.focalX == 0.4)
        #expect(artwork.focalY == 0.5, "a missing focal point is the middle")
        #expect(artwork.intrinsicSize == CGSize(width: 1200, height: 1600))
        #expect(artwork.attribution?.creditLine == "The Annunciation  ·  Fra Angelico  ·  c. 1440")
    }

    @Test func aSetWithNoPaintingHasNone() throws {
        let set = try decode(MeditationSet.self, #"{"id": 1, "name": "A", "category": "glorious", "description": null, "labels": null, "meditations": []}"#)
        #expect(set.artwork == nil)
        #expect(!set.hasAudio)
        #expect(!set.audioURLsHaveExpired, "a set that never said is not known to be dead")
    }

    @Test func audioLinksPastTheirTimeAreKnownDead() throws {
        #expect(try decode(MeditationSet.self, setJSON).audioURLsHaveExpired)
    }

    @Test func anUnknownCategoryIsNoCategory() throws {
        let set = try decode(MeditationSet.self, #"{"id": 1, "name": "A", "category": "mournful", "description": null, "labels": null, "meditations": null}"#)
        #expect(set.mysteryCategory == nil)
        #expect(MysteryCategory(fromAPIString: "SEVEN_SORROWS") == .sevenSorrows)
    }

    @Test func aSummaryDecodesWithoutMeditations() throws {
        let summary = try decode(MeditationSetSummary.self, #"{"id": 4, "name": "Sheen", "category": "sorrowful", "description": null, "labels": ["Saints"], "author": null}"#)
        #expect(summary.id == 4)
        #expect(summary.labels == ["Saints"])
    }

    @Test func voicesDecodeWithTheirDefault() throws {
        let voices = try decode([NarrationVoice].self, #"[{"slug": "frederick", "name": "Male", "description": null, "default": true}, {"slug": "female", "name": "Female", "default": false}]"#)
        #expect(voices.map(\.slug) == ["frederick", "female"])
        #expect(voices.first?.isDefault == true)
        #expect(voices.first?.displayName == "Male voice")
    }
}

@MainActor
struct NarrationChoiceTests {

    private func meditation(audioUrl: String?, narrations: [Narration]?) -> Meditation {
        Meditation(id: 1, title: nil, content: "…", author: nil, source: nil,
                   audioUrl: audioUrl, narrations: narrations, mystery: nil)
    }

    @Test func theChosenVoiceIsPlayedWhenTheMeditationHasIt() {
        let m = meditation(audioUrl: "d", narrations: [Narration(voice: "frederick", audioUrl: "d"), Narration(voice: "female", audioUrl: "f")])
        #expect(m.playableNarration(preferring: "female") == Narration(voice: "female", audioUrl: "f"))
    }

    @Test func otherwiseTheServersDefaultFirst() {
        let m = meditation(audioUrl: "d", narrations: [Narration(voice: "frederick", audioUrl: "d")])
        #expect(m.playableNarration(preferring: "female")?.voice == "frederick")
        #expect(m.playableNarration(preferring: nil)?.voice == "frederick")
    }

    @Test func aMeditationFromBeforeVoicesPlaysItsOneRecording() {
        let m = meditation(audioUrl: "legacy.mp3", narrations: nil)
        #expect(m.playableNarration(preferring: "female") == Narration(voice: NarrationVoice.legacyVoice, audioUrl: "legacy.mp3"))
    }

    @Test func aMeditationWithNoRecordingIsSilent() {
        #expect(meditation(audioUrl: nil, narrations: nil).playableNarration(preferring: "female") == nil)
        #expect(meditation(audioUrl: "", narrations: [Narration(voice: "female", audioUrl: "")]).playableNarration(preferring: "female") == nil)
        #expect(!meditation(audioUrl: "", narrations: nil).hasAudio)
    }

    @Test func aRetiredVoiceHasASuccessorTheAppOffers() {
        for (_, successor) in NarrationVoice.successors {
            #expect(NarrationVoice.builtIn.contains { $0.slug == successor })
        }
        #expect(NarrationVoice.builtIn.filter(\.isDefault).count == 1)
        #expect(NarrationVoice.builtIn.first?.isDefault == true, "the default first")
    }
}

@MainActor
struct MarianFeastDayTests {

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func monthDay(_ date: Date?) -> [Int] {
        guard let date else { return [] }
        return [Calendar.current.component(.month, from: date), Calendar.current.component(.day, from: date)]
    }

    @Test func thePreparationBeginsThirtyThreeDaysBefore() throws {
        let starts: [String: [Int]] = [
            "lourdes": [1, 9], "annunciation": [2, 20], "mount_carmel": [6, 13],
            "assumption": [7, 13], "nativity_mary": [8, 6], "sorrows": [8, 13],
            "presentation_mary": [10, 19], "immaculate_conception": [11, 5], "guadalupe": [11, 9]
        ]
        for feast in MarianFeastDay.all {
            #expect(monthDay(feast.startDate(for: 2026)) == starts[feast.id], "\(feast.name)")
        }
        // In a leap year the Annunciation's begins a day later in February
        #expect(monthDay(try #require(MarianFeastDay.find("annunciation")).startDate(for: 2028)) == [2, 21])
    }

    @Test func theNextFeastIsThisYearsOrNextYears() throws {
        let assumption = try #require(MarianFeastDay.find("assumption"))
        #expect(assumption.nextOccurrence(from: day(2026, 3, 1)) == assumption.date(for: 2026))
        #expect(assumption.nextOccurrence(from: day(2026, 10, 3)) == assumption.date(for: 2027))
    }

    @Test func aPreparationCanBeginOnlyOnItsStartDay() throws {
        let lourdes = try #require(MarianFeastDay.find("lourdes"))
        #expect(lourdes.canStartToday(from: day(2027, 1, 9)))
        #expect(!lourdes.canStartToday(from: day(2027, 1, 8)))
        #expect(!lourdes.canStartToday(from: day(2027, 1, 10)))
    }

    @Test func theFeastsAreSortedByWhichComesFirst() {
        let sorted = MarianFeastDay.sortedByNextOccurrence(from: day(2026, 10, 3))
        #expect(sorted.first?.id == "presentation_mary")
        #expect(sorted.last?.id == "sorrows")
        #expect(sorted.count == MarianFeastDay.all.count)
    }

    @Test func everyFeastIsFoundByItsId() {
        let ids = MarianFeastDay.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        for feast in MarianFeastDay.all {
            #expect(MarianFeastDay.find(feast.id) == feast)
        }
        #expect(MarianFeastDay.find("nowhere") == nil)
    }
}
