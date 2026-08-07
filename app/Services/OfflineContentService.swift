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
//    manifest.json                download date, size, counts
//
//  Reads are synchronous disk hits used as fallbacks when the API is
//  unreachable, and audio is always served locally when present (the
//  bundled URLs are 24-hour presigned links that expire).
//

import Foundation

@Observable
final class OfflineContentService {

    static let shared = OfflineContentService()

    // MARK: - State

    enum State: Equatable {
        case idle
        case downloading(completed: Int, total: Int)
        case downloaded(at: Date, bytes: Int64)
        case failed(String)
    }

    private(set) var state: State = .idle

    var isDownloading: Bool {
        if case .downloading = state { return true }
        return false
    }

    // MARK: - Manifest

    private struct Manifest: Codable {
        let downloadedAt: Date
        let bytes: Int64
        let setCount: Int
        let audioCount: Int
    }

    // MARK: - Storage Locations

    private let root: URL
    private var setsDir: URL { root.appendingPathComponent("sets", isDirectory: true) }
    private var audioDir: URL { root.appendingPathComponent("audio", isDirectory: true) }
    private var manifestURL: URL { root.appendingPathComponent("manifest.json") }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        root = base.appendingPathComponent("OfflineContent", isDirectory: true)
        try? FileManager.default.createDirectory(at: setsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)

        if let data = try? Data(contentsOf: manifestURL),
           let manifest = try? decoder.decode(Manifest.self, from: data) {
            state = .downloaded(at: manifest.downloadedAt, bytes: manifest.bytes)
        }
    }

    // MARK: - Download

    /// Downloads every meditation set and audio file. Already-present audio
    /// files are skipped, so retrying after a failure resumes rather than
    /// starting over.
    @MainActor
    func downloadAll() async {
        guard !isDownloading else { return }
        state = .downloading(completed: 0, total: 1)

        do {
            // Phase 1 — text: every set in every category
            var summariesByCategory: [MysteryCategory: [MeditationSetSummary]] = [:]
            for category in MysteryCategory.allCases {
                let summaries = try await APIService.shared.fetchMeditationSets(category: category)
                summariesByCategory[category] = summaries
                let data = try encoder.encode(summaries)
                try data.write(to: indexURL(for: category), options: .atomic)
            }

            let allSummaries = summariesByCategory.values.flatMap { $0 }

            // Chants come from local consecration data; enumerate once
            let chantPrayers = Self.consecrationPrayersWithAudio()

            var completed = 0
            var total = allSummaries.count + chantPrayers.count
            state = .downloading(completed: 0, total: total)

            var audioJobs: [(url: String, destination: URL)] = []

            for summary in allSummaries {
                let set = try await APIService.shared.fetchMeditationSet(id: summary.id)
                let data = try encoder.encode(set)
                try data.write(to: setURL(id: set.id), options: .atomic)

                for meditation in set.meditations ?? [] where meditation.hasAudio {
                    if let urlString = meditation.audioUrl {
                        audioJobs.append((urlString, meditationAudioURL(meditationId: meditation.id)))
                    }
                }

                completed += 1
                state = .downloading(completed: completed, total: total)
            }

            // Phase 2 — audio: narrations discovered above + chants
            total += audioJobs.count
            state = .downloading(completed: completed, total: total)

            var failures = 0

            for job in audioJobs {
                if !FileManager.default.fileExists(atPath: job.destination.path) {
                    do {
                        try await download(job.url, to: job.destination)
                    } catch {
                        failures += 1
                    }
                }
                completed += 1
                state = .downloading(completed: completed, total: total)
            }

            for prayer in chantPrayers {
                let destination = prayerAudioURL(prayerId: prayer)
                if !FileManager.default.fileExists(atPath: destination.path) {
                    do {
                        let presigned = try await APIService.shared.fetchPrayerAudioUrl(prayerId: prayer)
                        try await download(presigned, to: destination)
                    } catch {
                        failures += 1
                    }
                }
                completed += 1
                state = .downloading(completed: completed, total: total)
            }

            guard failures == 0 else {
                state = .failed("\(failures) file\(failures == 1 ? "" : "s") couldn't be downloaded. Try again to finish.")
                return
            }

            // Manifest
            let bytes = directorySize(root)
            let manifest = Manifest(
                downloadedAt: Date(),
                bytes: bytes,
                setCount: allSummaries.count,
                audioCount: audioJobs.count + chantPrayers.count
            )
            let manifestData = try encoder.encode(manifest)
            try manifestData.write(to: manifestURL, options: .atomic)
            state = .downloaded(at: manifest.downloadedAt, bytes: bytes)
        } catch {
            state = .failed("Download failed — check your connection and try again.")
        }
    }

    /// Deletes all downloaded content.
    func removeAll() {
        try? FileManager.default.removeItem(at: root)
        try? FileManager.default.createDirectory(at: setsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
        state = .idle
    }

    // MARK: - Offline Reads

    /// Stored set summaries for a category (picker fallback).
    func storedSummaries(category: MysteryCategory) -> [MeditationSetSummary]? {
        guard let data = try? Data(contentsOf: indexURL(for: category)),
              let summaries = try? decoder.decode([MeditationSetSummary].self, from: data),
              !summaries.isEmpty else { return nil }
        return summaries
    }

    /// A stored full meditation set by ID.
    func storedSet(id: Int) -> MeditationSet? {
        guard let data = try? Data(contentsOf: setURL(id: id)) else { return nil }
        return try? decoder.decode(MeditationSet.self, from: data)
    }

    /// All stored full sets for a category (quick-pray fallback).
    func storedSets(category: MysteryCategory) -> [MeditationSet]? {
        guard let summaries = storedSummaries(category: category) else { return nil }
        let sets = summaries.compactMap { storedSet(id: $0.id) }
        return sets.isEmpty ? nil : sets
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

    /// Every consecration prayer slug that has chant audio.
    private static func consecrationPrayersWithAudio() -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for phase in ConsecrationPhase.allCases {
            for prayer in ConsecrationData.prayers(for: phase) where prayer.hasAudio {
                if seen.insert(prayer.id).inserted {
                    result.append(prayer.id)
                }
            }
        }
        return result
    }

    private func download(_ urlString: String, to destination: URL) async throws {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (temp, response) = try await URLSession.shared.download(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temp, to: destination)
    }

    private func directorySize(_ url: URL) -> Int64 {
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
