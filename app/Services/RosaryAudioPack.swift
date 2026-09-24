//
//  RosaryAudioPack.swift
//  Lumen Viae
//
//  The spoken Rosary's recordings on disk, one voice at a time: the
//  prayers, the announcements and the verses a Rosary is about to play,
//  fetched before its first word so no Hail Mary ever waits on the
//  network, and kept so the next Rosary prays with no signal at all.
//
//  Layout under Application Support/OfflineContent/rosary/<voice>/:
//    manifest.json               the last manifest the server gave
//    prayers/<name>-<hash>.mp3   one file per recording, named as the
//    announcements/…             server names it — new words or a new
//    verses/…                    model is a new name, so an old copy is
//                                a file the manifest no longer names,
//                                never one that has to be checked
//
//  OfflineContent is already excluded from iCloud backup, and removing
//  the offline library removes this with it; the pack simply fetches
//  again the next time a Rosary is prayed aloud. The library download
//  (OfflineContentService.downloadAll) fills the pack for the chosen
//  voice too, so the first Rosary said aloud needs no connection.
//
//  The manifest's links are signed for about a day. A saved manifest
//  whose links still have more than a few minutes to live is used as it
//  is, with no round trip; once they are dead or about to die it is
//  fetched again before anything is downloaded. With no connection the
//  saved one answers, nothing is downloaded from its dead links, and the
//  Rosary is said from the files already on disk.
//

import Foundation

@Observable
final class RosaryAudioPack {

    static let shared = RosaryAudioPack()

    // MARK: - What a Recording Is Called

    /// One recording, independent of voice: a prayer by id, a mystery's
    /// announcement, or one verse of a mystery.
    enum ClipID: Hashable {
        case prayer(String)
        case announcement(String)
        case verse(String, Int)

        /// Nil for a meditation, which is the set's narration, not the pack's
        init?(segment: SpokenSegment) {
            switch segment.kind {
            case .prayer(let id): self = .prayer(id)
            case .announcement: self = .announcement(segment.mysteryKey)
            case .verse(let number): self = .verse(segment.mysteryKey, number)
            case .meditation: return nil
            }
        }

        /// The manifest group the recording is served in
        var kind: String {
            switch self {
            case .prayer: return "prayers"
            case .announcement: return "announcements"
            case .verse: return "verses"
            }
        }
    }

    enum PackError: LocalizedError {
        /// No manifest could be had: never fetched, and no connection now
        case unavailable

        var errorDescription: String? {
            SpokenRosaryPlayer.Failure.offline.message
        }
    }

    // MARK: - Dependencies

    private let apiService: APIService
    private let root: URL

    /// Fail a stalled clip in 20s; the clips are small
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()

    private init(apiService: APIService = .shared) {
        self.apiService = apiService
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        root = base
            .appendingPathComponent("OfflineContent", isDirectory: true)
            .appendingPathComponent("rosary", isDirectory: true)
    }

    // MARK: - Preparing a Rosary

    /// The recordings a Rosary needs, on disk, by what they are.
    ///
    /// Asks the server for the voice's manifest first; with no connection
    /// the manifest saved last time answers instead, and whatever it names
    /// that is already on disk plays. A recording that cannot be had is
    /// simply absent from the result — the player passes over it in
    /// silence rather than stopping the Rosary.
    ///
    /// A recording whose new file cannot be had — reworded on the server
    /// but not yet recorded there, or no connection to fetch it — is
    /// said from the copy already on the device instead, in its old
    /// words, rather than dropped from the Rosary. Old copies are only
    /// removed once their replacement is on disk.
    ///
    /// - Parameters:
    ///   - voice: the narration voice; a voice the server does not know
    ///     falls back to its default
    ///   - progress: files fetched so far, and how many were missing
    /// - Returns: the local file for each recording, the voice they are
    ///   actually in, and whether the server could not be reached (the
    ///   manifest saved last time answered instead)
    @MainActor
    func prepare(
        voice: String,
        clips: Set<ClipID>,
        progress: @escaping (Int, Int) -> Void = { _, _ in }
    ) async throws -> (files: [ClipID: URL], voice: String, offline: Bool) {
        let kinds = Array(Set(clips.map(\.kind))).sorted()
        let (manifest, offline) = try await manifest(voice: voice, kinds: kinds, clips: clips)
        // A saved manifest answering for an unreachable server may carry
        // links that have died: nothing is fetched from them, and what is
        // on disk is what is said
        let canDownload = !(offline && Self.linksExpiring(manifest))
        let voiceDir = root.appendingPathComponent(manifest.voice, isDirectory: true)

        var files: [ClipID: URL] = [:]
        var missing: [(ClipID, RosaryAudioClip, URL)] = []

        for id in clips {
            guard let clip = Self.clip(id, in: manifest) else { continue }
            let local = voiceDir
                .appendingPathComponent(id.kind, isDirectory: true)
                .appendingPathComponent(clip.file)
            if FileManager.default.fileExists(atPath: local.path) {
                files[id] = local
            } else {
                missing.append((id, clip, local))
            }
        }

        let fetchable = canDownload ? missing : []

        // Links from a manifest read off disk may be close to their end;
        // they are still worth one try each, and a dead one costs one
        // failed GET
        let total = fetchable.count
        var done = 0
        progress(done, total)

        let session = session
        await withTaskGroup(of: (ClipID, URL?).self) { group in
            var queue = fetchable[...]

            // Four at a time: enough to hide the round trips, few enough
            // not to crowd out a meditation already streaming
            func enqueue() {
                guard let (id, clip, local) = queue.popFirst() else { return }
                group.addTask {
                    let saved = try? await Self.download(with: session, from: clip.audioUrl, to: local)
                    return (id, saved)
                }
            }
            for _ in 0..<4 { enqueue() }

            for await (id, saved) in group {
                if let saved { files[id] = saved }
                done += 1
                progress(done, total)
                enqueue()
            }
        }

        // Whatever could not be fetched is said from an older copy, if
        // the device has one
        for (id, _, local) in missing where files[id] == nil {
            if let older = Self.olderCopy(of: local) { files[id] = older }
        }

        prune(manifest, kinds: kinds)
        return (files, manifest.voice, offline)
    }

    // MARK: - The Manifest

    /// The manifest for the voice: the saved one while its links live and
    /// it names every recording asked for; otherwise the server's, saved for
    /// next time; the saved one when the server cannot be reached,
    /// flagged as such.
    ///
    /// A saved manifest is at most a link's lifetime old — about a day —
    /// so a reworded prayer still reaches the device within a day.
    @MainActor
    private func manifest(
        voice: String,
        kinds: [String],
        clips: Set<ClipID>
    ) async throws -> (RosaryAudioManifest, offline: Bool) {
        let saved = savedManifest(voice: voice)
        if let saved, Self.covers(saved, kinds: kinds), !Self.linksExpiring(saved),
           clips.allSatisfy({ Self.clip($0, in: saved) != nil }) {
            return (saved, false)
        }
        do {
            let fetched = try await fetchManifest(voice: voice, kinds: kinds)
            let merged = merge(fetched, into: savedManifest(voice: fetched.voice))
            save(merged)
            return (merged, false)
        } catch {
            if let saved { return (saved, true) }
            throw PackError.unavailable
        }
    }

    /// A voice the server no longer knows (a stale voice list) is a 400;
    /// the default voice is a better answer than no prayers at all.
    @MainActor
    private func fetchManifest(voice: String, kinds: [String]) async throws -> RosaryAudioManifest {
        do {
            return try await apiService.fetchRosaryAudio(voice: voice, include: kinds)
        } catch APIError.serverError(let status, _) where status == 400 {
            return try await apiService.fetchRosaryAudio(voice: nil, include: kinds)
        }
    }

    /// The kinds just fetched replace the saved ones; the kinds not asked
    /// for this time are kept, unless the catalogue itself has changed
    /// under them, when they would name recordings that are no longer
    /// what the server serves.
    ///
    /// Links kept from the saved manifest were signed earlier and die
    /// earlier, so the merged manifest dies when the first of them does.
    private func merge(_ fetched: RosaryAudioManifest, into saved: RosaryAudioManifest?) -> RosaryAudioManifest {
        guard let saved, saved.version == fetched.version else { return fetched }
        let keepsSaved = (fetched.prayers == nil && saved.prayers != nil)
            || (fetched.announcements == nil && saved.announcements != nil)
            || (fetched.verses == nil && saved.verses != nil)
        let expiresAt: String?
        if keepsSaved {
            switch (saved.expiry, fetched.expiry) {
            case let (old?, new?): expiresAt = old < new ? saved.expiresAt : fetched.expiresAt
            default: expiresAt = nil
            }
        } else {
            expiresAt = fetched.expiresAt
        }
        return RosaryAudioManifest(
            voice: fetched.voice,
            version: fetched.version,
            expiresAt: expiresAt,
            prayers: fetched.prayers ?? saved.prayers,
            announcements: fetched.announcements ?? saved.announcements,
            verses: fetched.verses ?? saved.verses
        )
    }

    /// Whether a manifest's links are dead, or will be within five
    /// minutes — too near their end to begin a round of downloads on.
    /// A manifest that never said when is treated as stale.
    static func linksExpiring(_ manifest: RosaryAudioManifest, now: Date = Date()) -> Bool {
        guard let expiry = manifest.expiry else { return true }
        return expiry <= now.addingTimeInterval(5 * 60)
    }

    /// Whether a manifest holds every kind of recording asked for
    private static func covers(_ manifest: RosaryAudioManifest, kinds: [String]) -> Bool {
        kinds.allSatisfy { kind in
            switch kind {
            case "prayers": return manifest.prayers != nil
            case "announcements": return manifest.announcements != nil
            case "verses": return manifest.verses != nil
            default: return false
            }
        }
    }

    private func manifestURL(voice: String) -> URL {
        root.appendingPathComponent(voice, isDirectory: true).appendingPathComponent("manifest.json")
    }

    private func savedManifest(voice: String) -> RosaryAudioManifest? {
        guard let data = try? Data(contentsOf: manifestURL(voice: voice)) else { return nil }
        return try? JSONDecoder().decode(RosaryAudioManifest.self, from: data)
    }

    private func save(_ manifest: RosaryAudioManifest) {
        let url = manifestURL(voice: manifest.voice)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        if let data = try? JSONEncoder().encode(manifest) {
            try? data.write(to: url, options: .atomic)
        }
    }

    /// Removes recordings the manifest no longer names, in the kinds just
    /// prepared: a reworded prayer's old file, or a whole voice's files
    /// after it moved to another model. An old file is kept while its
    /// replacement is not yet on disk — it is what is said until then —
    /// and goes once the new one has arrived, or once the manifest no
    /// longer names that recording at all.
    private func prune(_ manifest: RosaryAudioManifest, kinds: [String]) {
        let voiceDir = root.appendingPathComponent(manifest.voice, isDirectory: true)
        for kind in kinds {
            let named: Set<String>
            switch kind {
            case "prayers": named = Set((manifest.prayers ?? [:]).values.map(\.file))
            case "announcements": named = Set((manifest.announcements ?? [:]).values.map(\.file))
            case "verses": named = Set((manifest.verses ?? [:]).values.flatMap { $0.map(\.file) })
            default: continue
            }
            let dir = voiceDir.appendingPathComponent(kind, isDirectory: true)
            let present = Set((try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? [])
            let namedByStem = Dictionary(named.map { (Self.stem(of: $0), $0) }, uniquingKeysWith: { a, _ in a })
            for file in present where !named.contains(file) {
                if let replacement = namedByStem[Self.stem(of: file)], !present.contains(replacement) {
                    continue
                }
                try? FileManager.default.removeItem(at: dir.appendingPathComponent(file))
            }
        }
    }

    /// The recording a file holds, without the hash of its words:
    /// "joyful_1_3" for "joyful_1_3-9f2c41ab07.mp3"
    private static func stem(of file: String) -> String {
        guard let dash = file.lastIndex(of: "-") else { return file }
        return String(file[..<dash])
    }

    /// Another copy of the same recording already on disk — the one the
    /// file at `local` replaces — if there is one
    private static func olderCopy(of local: URL) -> URL? {
        let dir = local.deletingLastPathComponent()
        let prefix = stem(of: local.lastPathComponent) + "-"
        let present = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        return present
            .first { $0.hasPrefix(prefix) && $0 != local.lastPathComponent }
            .map { dir.appendingPathComponent($0) }
    }

    private static func clip(_ id: ClipID, in manifest: RosaryAudioManifest) -> RosaryAudioClip? {
        switch id {
        case .prayer(let prayerId):
            return manifest.prayers?[prayerId]
        case .announcement(let key):
            return manifest.announcements?[key]
        case .verse(let key, let number):
            guard let verses = manifest.verses?[key], verses.indices.contains(number - 1) else { return nil }
            return verses[number - 1]
        }
    }

    // MARK: - Files

    @concurrent
    private nonisolated static func download(with session: URLSession, from urlString: String, to destination: URL) async throws -> URL {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (temp, response) = try await session.download(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temp, to: destination)
        return destination
    }
}
