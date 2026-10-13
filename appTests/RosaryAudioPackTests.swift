//
//  RosaryAudioPackTests.swift
//  Lumen Viae Tests
//
//  The spoken Rosary's saved manifests, kept in memory once read: a kept
//  one answers only while its file is on disk, so removing every
//  download and downloading again saves the manifest again, and a
//  later save is the one left on disk.
//

import Foundation
import Testing

@testable import app

@MainActor
struct RosaryAudioPackTests {

    private func manifest(_ version: String) -> RosaryAudioManifest {
        RosaryAudioManifest(
            voice: "test_voice",
            version: version,
            expiresAt: nil,
            prayers: [
                "hail_mary": RosaryAudioClip(file: "hail_mary-\(version).mp3", audioUrl: "https://example.com/a.mp3", text: nil, reference: nil)
            ],
            announcements: nil,
            verses: nil
        )
    }

    private func pack(_ writer: SlowFirstWriter? = nil) -> (RosaryAudioPack, URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("RosaryAudioPackTests-\(UUID().uuidString)", isDirectory: true)
        let writeFile: (@concurrent @Sendable (Data, URL) async -> Void)? = writer.map { writer in
            { @concurrent @Sendable data, url in await writer.write(data, to: url) }
        }
        return (RosaryAudioPack(apiService: .shared, root: root, writeFile: writeFile), root)
    }

    private func onDisk(_ root: URL) -> RosaryAudioManifest? {
        let url = root.appendingPathComponent("test_voice/manifest.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(RosaryAudioManifest.self, from: data)
    }

    /// Remove downloads, then download again: the manifest kept in memory
    /// no longer answers, so the next preparation fetches and saves one
    @Test func aKeptManifestWhoseFileIsGoneIsLetGo() async {
        let (pack, root) = pack()
        defer { try? FileManager.default.removeItem(at: root) }

        await pack.save(manifest("1"))
        #expect(await pack.savedManifest(voice: "test_voice") == manifest("1"))

        try? FileManager.default.removeItem(at: root)
        #expect(await pack.savedManifest(voice: "test_voice") == nil, "the file was removed")

        await pack.save(manifest("2"))
        #expect(onDisk(root) == manifest("2"), "saved again")
        #expect(await pack.savedManifest(voice: "test_voice") == manifest("2"))
    }

    @Test func forgettingReadsTheDiskAgain() async throws {
        let (pack, root) = pack()
        defer { try? FileManager.default.removeItem(at: root) }

        await pack.save(manifest("1"))
        let url = root.appendingPathComponent("test_voice/manifest.json")
        try JSONEncoder().encode(manifest("2")).write(to: url)
        #expect(await pack.savedManifest(voice: "test_voice") == manifest("1"), "kept in memory")

        pack.forgetSavedManifests()
        #expect(await pack.savedManifest(voice: "test_voice") == manifest("2"))
    }

    /// Saves land in the order they were asked for, the first made slow
    /// so the two writes certainly overlap
    @Test func theLaterSaveIsTheOneOnDisk() async {
        let writer = SlowFirstWriter()
        let (pack, root) = pack(writer)
        defer { try? FileManager.default.removeItem(at: root) }

        async let first: Void = pack.save(manifest("1"))
        async let second: Void = pack.save(manifest("2"))
        _ = await (first, second)
        #expect(await writer.writes == 2)
        let kept = await pack.savedManifest(voice: "test_voice")
        #expect(onDisk(root) == kept, "the disk holds the manifest kept in memory")
    }

    /// Two preparations finishing together, one fetching the prayers and
    /// one the Prayer Book's: each adds its kind to the other's, and
    /// neither merges into the same older manifest
    @Test func overlappingPreparationsKeepEachOthersKinds() async {
        let writer = SlowFirstWriter()
        let (pack, root) = pack(writer)
        defer { try? FileManager.default.removeItem(at: root) }

        let book = RosaryAudioManifest(
            voice: "test_voice",
            version: "1",
            expiresAt: nil,
            prayers: nil,
            announcements: nil,
            verses: nil,
            book: ["memorare": RosaryAudioClip(file: "memorare-1.mp3", audioUrl: "https://example.com/b.mp3", text: nil, reference: nil)]
        )
        async let first = pack.keepMerged(manifest("1"))
        async let second = pack.keepMerged(book)
        _ = await (first, second)

        let kept = await pack.savedManifest(voice: "test_voice")
        #expect(kept?.prayers != nil, "the prayers kept")
        #expect(kept?.book != nil, "the book kept")
        #expect(onDisk(root) == kept)
    }

    /// A kept manifest whose write has not landed yet is still the one
    @Test func aKeptManifestStandsWhileItsWriteIsOnItsWay() async {
        let writer = SlowFirstWriter()
        let (pack, root) = pack(writer)
        defer { try? FileManager.default.removeItem(at: root) }

        let saving = Task { await pack.save(manifest("1")) }
        while await writer.writes == 0 { await Task.yield() }
        #expect(onDisk(root) == nil, "the write has not landed")
        #expect(await pack.savedManifest(voice: "test_voice") == manifest("1"))
        await saving.value
    }
}

/// Writes a manifest as the pack does, the first one a third of a second late
private actor SlowFirstWriter {
    private(set) var writes = 0

    func write(_ data: Data, to url: URL) async {
        writes += 1
        if writes == 1 { try? await Task.sleep(for: .milliseconds(300)) }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
