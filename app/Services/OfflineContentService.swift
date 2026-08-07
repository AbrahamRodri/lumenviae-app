//
//  OfflineContentService.swift
//  Lumen Viae
//
//  User-initiated offline downloads: every meditation set (text) and every
//  audio file (meditation narrations + consecration chants) saved to disk,
//  so the whole app prays without a connection.
//
//  Layout under Application Support/OfflineContent/:
//    sets/index_<category>.json   [MeditationSetSummary] per category
//    sets/<id>.json               full MeditationSet
//    audio/meditation_<id>.mp3    meditation narration
//    audio/prayer_<slug>.mp3      consecration chant
//    manifest.json                download date, size, counts, completeness
//
//  Reads are fallbacks for when the API is unreachable, and audio is
//  always served locally when present (the bundled URLs are 24-hour
//  presigned links that expire). Heavy I/O runs off the main actor; the
//  content directory is excluded from iCloud backup (it's re-downloadable).
//

import Foundation

@Observable
final class OfflineContentService {

    static let shared = OfflineContentService()

    // MARK: - State

    enum State: Equatable {
        case idle
        case downloading(stage: String, completed: Int, total: Int)
        case downloaded(at: Date, bytes: Int64)
        case failed(String)
    }

    private(set) var state: State = .idle

    var isDownloading: Bool {
        if case .downloading = state { return true }
        return false
    }

    /// Whether any downloaded files exist, regardless of `state` — drives
    /// the Remove affordance so partial downloads are never unreclaimable.
    var hasContentOnDisk: Bool {
        let fm = FileManager.default
        let sets = (try? fm.contentsOfDirectory(atPath: setsDir.path)) ?? []
        let audio = (try? fm.contentsOfDirectory(atPath: audioDir.path)) ?? []
        return !sets.isEmpty || !audio.isEmpty
    }

    // MARK: - Manifest

    private struct Manifest: Codable {
        let downloadedAt: Date
        let bytes: Int64
        let setCount: Int
        let audioCount: Int
        /// False when some files failed — restored as .failed so the UI
        /// offers Try Again instead of pretending nothing exists.
        let complete: Bool
    }

    // MARK: - Storage Locations

    private let root: URL
    private var setsDir: URL { root.appendingPathComponent("sets", isDirectory: true) }
    private var audioDir: URL { root.appendingPathComponent("audio", isDirectory: true) }
    private var manifestURL: URL { root.appendingPathComponent("manifest.json") }

    /// Dedicated session for audio files: fail a stalled connection in 30s
    /// instead of URLSession.shared's 60s, but allow large transfers.
    private let downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    // MARK: - Init

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        root = base.appendingPathComponent("OfflineContent", isDirectory: true)
        createDirectories()

        if let data = try? Data(contentsOf: manifestURL),
           let manifest = try? Self.decoder().decode(Manifest.self, from: data) {
            state = manifest.complete
                ? .downloaded(at: manifest.downloadedAt, bytes: manifest.bytes)
                : .failed("The last download didn't finish. Try Again to complete it — finished files are kept.")
        } else if hasContentOnDisk {
            // Files but no readable manifest: a previous run was interrupted.
            state = .failed("A previous download didn't finish. Try Again to complete it, or remove the partial files.")
        }
    }

    private func createDirectories() {
        try? FileManager.default.createDirectory(at: setsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
        excludeFromBackup()
    }

    /// The whole library is re-downloadable — it must never consume the
    /// user's iCloud backup quota.
    private func excludeFromBackup() {
        var url = root
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    // MARK: - Download

    /// Downloads every meditation set and audio file.
    ///
    /// Already-present files are skipped (retrying resumes rather than
    /// starting over); pass `refreshText: true` to re-fetch set text for
    /// content updates. Network and disk work run off the main actor.
    @MainActor
    func downloadAll(refreshText: Bool = false) async {
        guard !isDownloading else { return }
        state = .downloading(stage: "Preparing", completed: 0, total: 0)

        do {
            // Stage 1 — text: every set in every category. Indexes are
            // written after their bodies so an interruption can't leave a
            // catalog that lists sets with no content.
            var summariesByCategory: [MysteryCategory: [MeditationSetSummary]] = [:]
            for category in MysteryCategory.allCases {
                summariesByCategory[category] = try await APIService.shared.fetchMeditationSets(category: category)
            }

            let allSummaries = summariesByCategory.values.flatMap { $0 }
            let chantIds = Self.consecrationChantIds()

            var textDone = 0
            state = .downloading(stage: "Meditations", completed: 0, total: allSummaries.count)

            var audioJobs: [(url: String, destination: URL)] = []

            for summary in allSummaries {
                let file = setURL(id: summary.id)
                let set: MeditationSet

                if !refreshText, let stored = await Self.readJSON(MeditationSet.self, from: file) {
                    set = stored
                } else {
                    set = try await APIService.shared.fetchMeditationSet(id: summary.id)
                    try await Self.writeJSON(set, to: file)
                }

                for meditation in set.meditations ?? [] where meditation.hasAudio {
                    if let urlString = meditation.audioUrl {
                        audioJobs.append((urlString, meditationAudioURL(meditationId: meditation.id)))
                    }
                }

                textDone += 1
                state = .downloading(stage: "Meditations", completed: textDone, total: allSummaries.count)
            }

            for (category, summaries) in summariesByCategory {
                try await Self.writeJSON(summaries, to: indexURL(for: category))
            }

            // Stage 2 — audio: narrations discovered above, plus chants.
            // Its own monotonic counter; the denominator never moves.
            var failures = 0
            var audioDone = 0
            let audioTotal = audioJobs.count + chantIds.count
            state = .downloading(stage: "Audio", completed: 0, total: max(audioTotal, 1))

            for job in audioJobs {
                if !FileManager.default.fileExists(atPath: job.destination.path) {
                    do {
                        try await Self.download(with: downloadSession, from: job.url, to: job.destination)
                    } catch {
                        failures += 1
                    }
                }
                audioDone += 1
                state = .downloading(stage: "Audio", completed: audioDone, total: audioTotal)
            }

            for prayerId in chantIds {
                let destination = prayerAudioURL(prayerId: prayerId)
                if !FileManager.default.fileExists(atPath: destination.path) {
                    do {
                        let presigned = try await APIService.shared.fetchPrayerAudioUrl(prayerId: prayerId)
                        try await Self.download(with: downloadSession, from: presigned, to: destination)
                    } catch {
                        failures += 1
                    }
                }
                audioDone += 1
                state = .downloading(stage: "Audio", completed: audioDone, total: audioTotal)
            }

            // Manifest is written for partial runs too, so a relaunch
            // restores an honest .failed instead of pretending .idle.
            let bytes = await Self.directorySize(of: root)
            let manifest = Manifest(
                downloadedAt: Date(),
                bytes: bytes,
                setCount: allSummaries.count,
                audioCount: audioTotal,
                complete: failures == 0
            )
            try? await Self.writeJSON(manifest, to: manifestURL)

            if failures == 0 {
                state = .downloaded(at: manifest.downloadedAt, bytes: bytes)
            } else {
                state = .failed("\(failures) file\(failures == 1 ? "" : "s") couldn't be downloaded. Try Again to finish — finished files are kept.")
            }
        } catch {
            if hasContentOnDisk {
                let bytes = await Self.directorySize(of: root)
                let manifest = Manifest(downloadedAt: Date(), bytes: bytes, setCount: 0, audioCount: 0, complete: false)
                try? await Self.writeJSON(manifest, to: manifestURL)
            }
            state = .failed("Download failed — check your connection and try again.")
        }
    }

    /// Deletes all downloaded content.
    func removeAll() {
        try? FileManager.default.removeItem(at: root)
        createDirectories()
        state = .idle
    }

    // MARK: - Offline Reads

    /// Stored set summaries for a category (picker fallback). Only
    /// summaries whose full set is actually on disk are listed — a
    /// partial download must never show sets that fail on tap.
    func storedSummaries(category: MysteryCategory) -> [MeditationSetSummary]? {
        guard let data = try? Data(contentsOf: indexURL(for: category)),
              let summaries = try? Self.decoder().decode([MeditationSetSummary].self, from: data) else {
            return nil
        }
        let available = summaries.filter {
            FileManager.default.fileExists(atPath: setURL(id: $0.id).path)
        }
        return available.isEmpty ? nil : available
    }

    /// A stored full meditation set by ID.
    func storedSet(id: Int) -> MeditationSet? {
        guard let data = try? Data(contentsOf: setURL(id: id)) else { return nil }
        return try? Self.decoder().decode(MeditationSet.self, from: data)
    }

    /// One random stored set for a category, read and decoded off the main
    /// actor — quick-pray's offline fallback must not freeze the Pray tap.
    nonisolated func storedRandomSet(category: MysteryCategory) async -> MeditationSet? {
        let index = await indexURL(for: category)
        let dir = await setsDir

        guard let data = try? Data(contentsOf: index),
              let summaries = try? Self.decoder().decode([MeditationSetSummary].self, from: data) else {
            return nil
        }

        let available = summaries.filter {
            FileManager.default.fileExists(atPath: dir.appendingPathComponent("\($0.id).json").path)
        }
        guard let pick = available.randomElement() else { return nil }

        let file = dir.appendingPathComponent("\(pick.id).json")
        guard let setData = try? Data(contentsOf: file) else { return nil }
        return try? Self.decoder().decode(MeditationSet.self, from: setData)
    }

    /// Local narration audio for a meditation, if downloaded.
    func localAudioURL(meditationId: Int) -> URL? {
        let url = meditationAudioURL(meditationId: meditationId)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Local chant audio for a consecration prayer, if downloaded.
    func localPrayerAudioURL(prayerId: String) -> URL? {
        let url = prayerAudioURL(prayerId: prayerId)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Private Helpers

    private func indexURL(for category: MysteryCategory) -> URL {
        setsDir.appendingPathComponent("index_\(category.rawValue).json")
    }

    private func setURL(id: Int) -> URL {
        setsDir.appendingPathComponent("\(id).json")
    }

    private func meditationAudioURL(meditationId: Int) -> URL {
        audioDir.appendingPathComponent("meditation_\(meditationId).mp3")
    }

    private func prayerAudioURL(prayerId: String) -> URL {
        audioDir.appendingPathComponent("prayer_\(prayerId).mp3")
    }

    /// Every consecration prayer slug that has chant audio. Uses the
    /// language-aware prayer list — the same one the prayer flow renders —
    /// because that's where the bilingual chants (and their audio flags)
    /// are merged in.
    private static func consecrationChantIds() -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for phase in ConsecrationPhase.allCases {
            for prayer in ConsecrationData.prayers(for: phase, language: .both) where prayer.hasAudio {
                if seen.insert(prayer.id).inserted {
                    result.append(prayer.id)
                }
            }
        }
        return result
    }

    // MARK: - Off-Main I/O

    // nonisolated async: runs on the concurrency pool, never the main actor.

    private nonisolated static func decoder() -> JSONDecoder { JSONDecoder() }

    private nonisolated static func writeJSON<T: Encodable>(_ value: T, to url: URL) async throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }

    private nonisolated static func readJSON<T: Decodable>(_ type: T.Type, from url: URL) async -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private nonisolated static func download(with session: URLSession, from urlString: String, to destination: URL) async throws {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (temp, response) = try await session.download(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temp, to: destination)
    }

    private nonisolated static func directorySize(of url: URL) async -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            total += Int64(size)
        }
        return total
    }
}
