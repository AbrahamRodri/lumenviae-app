//
//  ContentExportTests.swift
//  appTests
//
//  The export of the Prayer Book's words and the chant catalog to the
//  server's two documents (Tools/ContentExport). Run with
//  TEST_RUNNER_CONTENT_EXPORT_WRITE=1 (Tools/ContentExport/export.sh) it
//  writes Tools/ContentExport/out/; every run checks that what is written
//  there decodes back to exactly the data the app compiles.
//

import CryptoKit
import Foundation
import Testing

@testable import app

@MainActor
struct ContentExportTests {

    // MARK: Paths

    /// The repository root, found from this file, since the simulator
    /// reads the Mac's disk
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    static let out = root.appendingPathComponent("Tools/ContentExport/out")
    static let chantsDir = "app/Resources/Chants"

    static var writes: Bool { ProcessInfo.processInfo.environment["CONTENT_EXPORT_WRITE"] == "1" }

    // MARK: The documents, from what the app compiles

    static func prayerBookDocument() -> PrayerBookDocument {
        var order: [String] = []
        var seen = Set<String>()
        for chapter in PrayerBook.chapters {
            for id in chapter.prayerIDs where seen.insert(id).inserted { order.append(id) }
        }
        order += PrayerBook.prayers.keys.filter { !seen.contains($0) }.sorted()

        let prayers = order.compactMap { PrayerBook.prayers[$0] }.map { prayer in
            PrayerBookDocument.Prayer(
                id: prayer.id, title: prayer.title, latinTitle: prayer.latinTitle,
                origin: prayer.origin, note: prayer.note, english: prayer.english, latin: prayer.latin,
                listTitle: PrayerBook.listTitles[prayer.id], englishName: PrayerBook.englishNames[prayer.id],
                searchWords: PrayerBook.prayerSearchWords[prayer.id] ?? []
            )
        }
        let chapters = PrayerBook.chapters.map { chapter in
            PrayerBookDocument.Chapter(
                id: chapter.id, numeral: chapter.numeral, title: chapter.title,
                latinTitle: chapter.latinTitle, note: chapter.epigraph,
                topic: chapter.topic.isEmpty ? nil : chapter.topic,
                searchWords: chapter.searchWords, prayerIDs: chapter.prayerIDs,
                sections: chapter.sections.map { .init(title: $0.title, prayerIDs: $0.prayerIDs) }
            )
        }
        return PrayerBookDocument(prayers: prayers, chapters: chapters)
    }

    static func chantLibraryDocument() throws -> ChantLibraryDocument {
        let groups = ChantCatalog.groups.map { group in
            ChantLibraryDocument.Group(
                id: group.id, title: group.title, note: group.note,
                parts: group.parts.map { .init(title: $0.title, note: $0.note, chantIDs: $0.chantIDs) }
            )
        }
        let chants = try ChantCatalog.all.map { chant in
            let audio = try asset(at: "\(chantsDir)/\(chant.id).m4a")
            let score = try chant.score.map { part in
                let file = try asset(at: "\(chantsDir)/Scores/\(part.file).lvscore")
                return ChantLibraryDocument.ScorePart(
                    file: part.file, caption: part.caption, aspectRatio: Double(part.aspectRatio),
                    url: nil, bytes: file.bytes, sha256: file.sha256
                )
            }
            return ChantLibraryDocument.Chant(
                id: chant.id, groupID: chant.groupID, latinTitle: chant.latinTitle,
                englishTitle: chant.englishTitle, setting: chant.setting, detail: chant.detail,
                prayerIDs: chant.prayerIDs, duration: chant.duration, sourceURL: chant.sourceURL.absoluteString,
                audio: audio, score: score,
                lines: chant.lines.map {
                    .init(latin: $0.latin, english: $0.english, start: $0.start, end: $0.end, part: $0.part)
                }
            )
        }
        return ChantLibraryDocument(groups: groups, chants: chants)
    }

    /// Every local file the chant document names, with its size and hash,
    /// for the server's upload: path relative to the repository root
    static func manifest(of library: ChantLibraryDocument) -> [[String: Any]] {
        var rows: [String: [String: Any]] = [:]
        for chant in library.chants {
            rows["\(chantsDir)/\(chant.id).m4a"] = [
                "kind": "audio", "chant_id": chant.id, "name": chant.id,
                "bytes": chant.audio.bytes, "sha256": chant.audio.sha256,
            ]
            for part in chant.score {
                rows["\(chantsDir)/Scores/\(part.file).lvscore"] = [
                    "kind": "score", "name": part.file,
                    "bytes": part.bytes, "sha256": part.sha256,
                ]
            }
        }
        return rows.keys.sorted().map { path in rows[path]!.merging(["path": path]) { a, _ in a } }
    }

    static func asset(at path: String) throws -> ChantLibraryDocument.Asset {
        let data = try Data(contentsOf: root.appendingPathComponent(path))
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return .init(url: nil, bytes: data.count, sha256: hash)
    }

    // MARK: The export

    @Test func exportDecodesToTheCompiledData() throws {
        let book = Self.prayerBookDocument()
        let library = try Self.chantLibraryDocument()
        let encoder = LibraryDocumentCoding.encoder()

        if Self.writes {
            try FileManager.default.createDirectory(at: Self.out, withIntermediateDirectories: true)
            try encoder.encode(book).write(to: Self.out.appendingPathComponent("prayer_book.json"))
            try encoder.encode(library).write(to: Self.out.appendingPathComponent("chant_library.json"))
            let manifest = try JSONSerialization.data(
                withJSONObject: ["assets": Self.manifest(of: library)],
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
            try manifest.write(to: Self.out.appendingPathComponent("chant_assets.json"))
        }

        let decoder = JSONDecoder()
        let writtenBook = try decoder.decode(
            PrayerBookDocument.self, from: Data(contentsOf: Self.out.appendingPathComponent("prayer_book.json")))
        let writtenLibrary = try decoder.decode(
            ChantLibraryDocument.self, from: Data(contentsOf: Self.out.appendingPathComponent("chant_library.json")))

        #expect(
            writtenBook == book, "Tools/ContentExport/out/prayer_book.json is stale: run Tools/ContentExport/export.sh")
        #expect(
            writtenLibrary == library,
            "Tools/ContentExport/out/chant_library.json is stale: run Tools/ContentExport/export.sh")
    }

    /// Every field of every prayer, chapter and chant read back from the
    /// written documents is the compiled one
    @Test func writtenDocumentsHoldEveryField() throws {
        let decoder = JSONDecoder()
        let book = try decoder.decode(
            PrayerBookDocument.self, from: Data(contentsOf: Self.out.appendingPathComponent("prayer_book.json")))
        let library = try decoder.decode(
            ChantLibraryDocument.self, from: Data(contentsOf: Self.out.appendingPathComponent("chant_library.json")))

        #expect(Set(book.prayers.map(\.id)) == Set(PrayerBook.prayers.keys))
        #expect(book.prayers.count == PrayerBook.prayers.count)
        for written in book.prayers {
            let prayer = try #require(PrayerBook.prayers[written.id])
            #expect(written.title == prayer.title)
            #expect(written.latinTitle == prayer.latinTitle)
            #expect(written.origin == prayer.origin)
            #expect(written.note == prayer.note)
            #expect(written.english == prayer.english)
            #expect(written.latin == prayer.latin)
            #expect((written.listTitle ?? written.title) == prayer.listTitle)
            #expect(written.searchWords == prayer.searchWords)
            #expect(written.englishName == PrayerBook.englishNames[written.id])
        }

        #expect(book.chapters.map(\.id) == PrayerBook.chapters.map(\.id))
        for (written, chapter) in zip(book.chapters, PrayerBook.chapters) {
            #expect(written.numeral == chapter.numeral)
            #expect(written.title == chapter.title)
            #expect(written.latinTitle == chapter.latinTitle)
            #expect(written.note == chapter.epigraph)
            #expect((written.topic ?? "") == chapter.topic)
            #expect(written.searchWords == chapter.searchWords)
            #expect(written.prayerIDs == chapter.prayerIDs)
            #expect(written.sections.map(\.title) == chapter.sections.map(\.title))
            #expect(written.sections.map(\.prayerIDs) == chapter.sections.map(\.prayerIDs))
            #expect(written.prayerIDs.allSatisfy { PrayerBook.prayers[$0] != nil })
        }

        #expect(library.groups.map(\.id) == ChantCatalog.groups.map(\.id))
        for (written, group) in zip(library.groups, ChantCatalog.groups) {
            #expect(written.title == group.title)
            #expect(written.note == group.note)
            #expect(written.parts.map(\.title) == group.parts.map(\.title))
            #expect(written.parts.map(\.note) == group.parts.map(\.note))
            #expect(written.parts.map(\.chantIDs) == group.parts.map(\.chantIDs))
        }

        #expect(library.chants.map(\.id) == ChantCatalog.all.map(\.id))
        for (written, chant) in zip(library.chants, ChantCatalog.all) {
            #expect(written.groupID == chant.groupID)
            #expect(written.latinTitle == chant.latinTitle)
            #expect(written.englishTitle == chant.englishTitle)
            #expect(written.setting == chant.setting)
            #expect(written.detail == chant.detail)
            #expect(written.prayerIDs == chant.prayerIDs)
            #expect(written.duration == chant.duration)
            #expect(written.sourceURL == chant.sourceURL.absoluteString)
            #expect(written.score.map(\.file) == chant.score.map(\.file))
            #expect(written.score.map(\.caption) == chant.score.map(\.caption))
            #expect(written.score.map { CGFloat($0.aspectRatio) } == chant.score.map(\.aspectRatio))
            #expect(written.lines.count == chant.lines.count)
            for (line, compiled) in zip(written.lines, chant.lines) {
                #expect(line.latin == compiled.latin)
                #expect(line.english == compiled.english)
                #expect(line.start == compiled.start)
                #expect(line.end == compiled.end)
                #expect(line.part == compiled.part)
            }
            #expect(written.audio.bytes > 0 && written.audio.sha256.count == 64)
            #expect(written.score.allSatisfy { $0.bytes > 0 && $0.sha256.count == 64 })
        }
    }
}
