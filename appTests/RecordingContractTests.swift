//
//  RecordingContractTests.swift
//  Lumen Viae Tests
//
//  The words the server records must be the app's own. The Scriptural
//  Rosary's verses reach the server as Tools/ScripturalRosary/
//  scriptural_rosary.json and the Prayer Book's as Tools/PrayerBook/
//  prayer_book.json; a verse or a prayer changed in the app and not
//  exported again is heard one way and read another. Read here from the
//  repository beside these tests, and held to the bundled text. Then
//  the manifest of recordings as the server sends it, and when its
//  links are too near their end to begin downloading on.
//

import Foundation
import Testing
@testable import app

@MainActor
struct RecordingContractTests {

    /// The repository's root, found from this file's own place in it
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private func json(_ path: String) throws -> Any {
        let data = try Data(contentsOf: Self.root.appendingPathComponent(path))
        return try JSONSerialization.jsonObject(with: data)
    }

    @Test func theServersVersesAreTheBundledVerses() throws {
        let exported = try #require(try json("Tools/ScripturalRosary/scriptural_rosary.json") as? [String: [[String: String]]])
        #expect(Set(exported.keys) == Set(ScripturalRosaryData.all.keys))
        for (key, verses) in ScripturalRosaryData.all {
            let theirs = exported[key] ?? []
            #expect(theirs.map { $0["reference"] } == verses.map(\.reference), "\(key)'s references differ")
            #expect(theirs.map { $0["text"] } == verses.map(\.text), "\(key) is read one way and heard another; rerun generate.py")
        }
    }

    @Test func everyPrayerExportedIsAPrayerTheBookHolds() throws {
        let export = try #require(try json("Tools/PrayerBook/prayer_book.json") as? [String: Any])
        let prayers = try #require(export["prayers"] as? [[String: Any]])
        let ids = prayers.compactMap { $0["id"] as? String }
        #expect(ids.count == prayers.count)
        #expect(Set(ids).count == ids.count, "a prayer exported twice")
        for id in ids {
            #expect(PrayerBook.prayer(id) != nil, "\(id) is recorded but the book no longer holds it")
        }
    }

    @Test func everyPrayerTheBookHoldsIsExportedOrTheRosarysOwn() throws {
        let export = try #require(try json("Tools/PrayerBook/prayer_book.json") as? [String: Any])
        let exported = Set((export["prayers"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String })
        // A prayer the Rosary also says plays its `prayers` recording
        let rosarys = Set(RosaryPrayers.all.map(\.id))
        for id in PrayerBook.prayers.keys where !exported.contains(id) && !rosarys.contains(id) {
            // Joined in from the consecration's own store, with recordings of its own
            #expect(BilingualConsecrationPrayers.allPrayers[id] != nil || ConsecrationData.prayer(id) != nil,
                    "\(id) has no recording to be said aloud; re-export the Prayer Book")
        }
    }

    @Test func everyExportedPrayerHasWordsToSay() throws {
        let export = try #require(try json("Tools/PrayerBook/prayer_book.json") as? [String: Any])
        for prayer in export["prayers"] as? [[String: Any]] ?? [] {
            let text = prayer["text"] as? String ?? ""
            #expect(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(prayer["id"] ?? "?")")
            #expect(!text.contains("|||"), "only the English is said")
            #expect(!text.contains("℣") && !text.contains("℟"), "marks are silent")
        }
    }
}

@MainActor
struct RosaryAudioManifestTests {

    private let manifestJSON = """
    {
      "voice": "frederick",
      "version": "7",
      "expires_at": "2026-10-05T12:00:00Z",
      "prayers": {"our_father": {"file": "our_father_ab12.mp3", "audio_url": "https://s3/our_father", "text": null, "reference": null}},
      "announcements": {"joyful_1": {"file": "joyful_1_cd34.mp3", "audio_url": "https://s3/j1"}},
      "verses": {"joyful_1": [{"file": "v1.mp3", "audio_url": "https://s3/v1", "text": "And in the sixth month…", "reference": "Luke 1:26"}]}
    }
    """

    private func manifest(_ json: String? = nil) throws -> RosaryAudioManifest {
        try JSONDecoder().decode(RosaryAudioManifest.self, from: Data((json ?? manifestJSON).utf8))
    }

    @Test func theManifestDecodesAsTheServerSendsIt() throws {
        let m = try manifest()
        #expect(m.voice == "frederick")
        #expect(m.prayers?["our_father"]?.file == "our_father_ab12.mp3")
        #expect(m.verses?["joyful_1"]?.first?.reference == "Luke 1:26")
        #expect(m.book == nil, "the book's recordings only when asked for")
        #expect(m.expiry == ISO8601DateFormatter().date(from: "2026-10-05T12:00:00Z"))
    }

    @Test func linksNearTheirEndAreNotBegunOn() throws {
        let m = try manifest()
        let expiry = try #require(m.expiry)
        #expect(!RosaryAudioPack.linksExpiring(m, now: expiry.addingTimeInterval(-3600)))
        #expect(RosaryAudioPack.linksExpiring(m, now: expiry.addingTimeInterval(-4 * 60)), "under five minutes left")
        #expect(RosaryAudioPack.linksExpiring(m, now: expiry.addingTimeInterval(60)))
    }

    @Test func aManifestThatNeverSaidWhenIsStale() throws {
        let m = try manifest(#"{"voice": "female", "version": "1", "expires_at": null}"#)
        #expect(RosaryAudioPack.linksExpiring(m))
        #expect(m.prayers == nil)
    }

    @Test func eachRecordingIsAskedForInItsOwnGroup() {
        #expect(RosaryAudioPack.ClipID.prayer("hail_mary").kind == "prayers")
        #expect(RosaryAudioPack.ClipID.announcement("joyful_1").kind == "announcements")
        #expect(RosaryAudioPack.ClipID.verse("joyful_1", 3).kind == "verses")
        #expect(RosaryAudioPack.ClipID.book("memorare").kind == "book")
    }
}
