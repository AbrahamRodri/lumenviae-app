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

    private func pack() -> (RosaryAudioPack, URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("RosaryAudioPackTests-\(UUID().uuidString)", isDirectory: true)
        return (RosaryAudioPack(apiService: .shared, root: root), root)
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

    /// Saves land in the order they were asked for
    @Test func theLaterSaveIsTheOneOnDisk() async {
        let (pack, root) = pack()
        defer { try? FileManager.default.removeItem(at: root) }

        async let first: Void = pack.save(manifest("1"))
        async let second: Void = pack.save(manifest("2"))
        _ = await (first, second)
        let kept = await pack.savedManifest(voice: "test_voice")
        #expect(onDisk(root) == kept, "the disk holds the manifest kept in memory")
    }
}
