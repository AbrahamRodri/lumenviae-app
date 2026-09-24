//
//  OfflineContentService.swift
//  Lumen Viae
//
//  User-initiated offline downloads: every meditation set (text) and every
//  audio file (meditation narrations + consecration chants) saved to disk,
//  so the whole app prays without a connection. One set at a time can be
//  saved from its own page — same files, same directory, its own progress
//  so it never masquerades as the library-wide download.
//
//  Layout under Application Support/OfflineContent/:
//    sets/index_<category>.json   [MeditationSetSummary] per category
//    sets/<id>.json               full MeditationSet
//    audio/meditation_<id>_<voice>.mp3
//                                 meditation narration, one file per voice
//                                 it has been saved in (an older
//                                 meditation_<id>.mp3 is renamed to the
//                                 male voice at launch, which is what it
//                                 always was)
//    audio/prayer_<slug>.mp3      consecration chant
//    images/set_<id>_<hash>.jpg   the set's painting, named by the set and
//                                 the hash the S3 key carries — a replaced
//                                 painting is a different file name, so
//                                 staleness is a lookup, never a HEAD
//    manifest.json                download date, size, counts, completeness
//
//  Reads are fallbacks for when the API is unreachable, and audio is
//  always served locally when present (the bundled URLs are 24-hour
//  presigned links that expire). Heavy I/O runs off the main actor; the
//  content directory is excluded from iCloud backup (it's re-downloadable).
//
//  Paintings came later than text and audio, and a library downloaded
//  before them is deliberately not made stale by their arrival: every
//  download skips what is already on disk, so tapping Download again
//  fetches the few hundred KB of images and nothing else. No manifest
//  version, no forced re-download of an audio library.
//
//  The spoken Rosary's recordings (RosaryAudioPack) are fetched last, in
//  the chosen voice, into OfflineContent/rosary/<voice>/ - the pack's own
//  layout and its own download logic - so the first Rosary said aloud
//  prays without a connection. They are a convenience on top of the
//  library: a pack that cannot be had never marks the library as failed,
//  and the pack fetches whatever it lacks when next prayed aloud.
//
//  Voices came later still. The library download saves each meditation
//  in the voice the person has chosen (a set that lacks that voice is
//  saved in its default), so a library is one voice deep - a second voice
//  would double a download that is already hundreds of megabytes.
//  Changing the voice afterwards makes the library "incomplete" in the
//  new voice, and Download again fetches only the new voice's files.
//  When the chosen voice is not on disk the player still prefers any
//  saved voice over the network, because a Rosary on a plane in the
//  other voice beats silence.
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
    ///
    /// Cached rather than computed: Account reads this from its body, and
    /// enumerating both directories synchronously on every re-render stats
    /// hundreds of files on the main thread once a library is downloaded.
    /// Only download and removal change the answer, and both refresh it.
    private(set) var hasContentOnDisk: Bool = false

    /// Which (meditation, voice) narrations are saved.
    ///
    /// Published rather than left as a `fileExists` probe so a surface
    /// offering "Download"/"Remove download" tracks the library: wiping
    /// everything from Account updates an open tray instead of leaving it
    /// offering to remove a file that is gone.
    private(set) var downloadedAudio: Set<AudioKey> = []

    /// One saved narration: a meditation in a voice.
    struct AudioKey: Hashable {
        let meditationId: Int
        let voice: String
    }

    /// Which meditation sets have their text saved. Published for the
    /// same reason as `downloadedAudio`: a set's own page offers to
    /// save or remove it, and wiping the library from Account has to
    /// reach that page rather than leave it claiming a saved copy.
    private(set) var downloadedSetIds: Set<Int> = []

    /// Re-reads the directories. Called at init and after any write.
    private func refreshDiskState() {
        let fm = FileManager.default
        let sets = (try? fm.contentsOfDirectory(atPath: setsDir.path)) ?? []
        let audio = (try? fm.contentsOfDirectory(atPath: audioDir.path)) ?? []
        let images = (try? fm.contentsOfDirectory(atPath: imagesDir.path)) ?? []
        hasContentOnDisk = !sets.isEmpty || !audio.isEmpty || !images.isEmpty
        // Same listings, so the saved-id sets cost no extra I/O
        downloadedAudio = Set(audio.compactMap(Self.audioKey(fromAudioFile:)))
        downloadedSetIds = Set(sets.compactMap(Self.setId(fromFile:)))
    }

    /// The meditation and voice in `meditation_412_female.mp3`. Nil for a
    /// chant file, which shares the directory under a `prayer_` prefix,
    /// and for anything else that is not a narration.
    private nonisolated static func audioKey(fromAudioFile name: String) -> AudioKey? {
        let prefix = "meditation_", suffix = ".mp3"
        guard name.hasPrefix(prefix), name.hasSuffix(suffix) else { return nil }
        let stem = name.dropFirst(prefix.count).dropLast(suffix.count)
        guard let underscore = stem.lastIndex(of: "_"),
              let id = Int(stem[..<underscore]) else { return nil }
        let voice = String(stem[stem.index(after: underscore)...])
        return voice.isEmpty ? nil : AudioKey(meditationId: id, voice: voice)
    }

    /// Files saved before voices were named `meditation_<id>.mp3`, and
    /// every one of them was the original (male) voice. Renaming them once
    /// keeps those downloads instead of orphaning a few hundred megabytes
    /// the person chose to keep.
    private func migrateLegacyAudioNames() {
        let fm = FileManager.default
        let names = (try? fm.contentsOfDirectory(atPath: audioDir.path)) ?? []
        for name in names {
            let prefix = "meditation_", suffix = ".mp3"
            guard name.hasPrefix(prefix), name.hasSuffix(suffix),
                  let id = Int(name.dropFirst(prefix.count).dropLast(suffix.count)) else { continue }
            let destination = meditationAudioURL(meditationId: id, voice: NarrationVoice.legacyVoice)
            if fm.fileExists(atPath: destination.path) {
                try? fm.removeItem(at: audioDir.appendingPathComponent(name))
            } else {
                try? fm.moveItem(at: audioDir.appendingPathComponent(name), to: destination)
            }
        }
    }

    /// The id in `27.json`. Nil for `index_joyful.json`, which shares the
    /// directory and is a catalog rather than a set.
    private nonisolated static func setId(fromFile name: String) -> Int? {
        guard name.hasSuffix(".json") else { return nil }
        return Int(name.dropLast(".json".count))
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
    private var imagesDir: URL { root.appendingPathComponent("images", isDirectory: true) }
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
        migrateLegacyAudioNames()
        refreshDiskState()

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
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
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
            let voice = NarrationVoiceCatalog.shared.chosenSlug

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

                for meditation in set.meditations ?? [] {
                    if let narration = meditation.playableNarration(preferring: voice) {
                        audioJobs.append((
                            narration.audioUrl,
                            meditationAudioURL(meditationId: meditation.id, voice: narration.voice)
                        ))
                    }
                }

                textDone += 1
                state = .downloading(stage: "Meditations", completed: textDone, total: allSummaries.count)
            }

            for (category, summaries) in summariesByCategory {
                try await Self.writeJSON(summaries, to: indexURL(for: category))
            }

            var failures = 0

            // Stage 2 — artwork: the painting of every set that has one,
            // skipped when its hash-named file is already here. A set
            // without a painting costs nothing; a library downloaded
            // before paintings existed picks them up here and re-fetches
            // nothing else.
            let artworkJobs = allSummaries.compactMap { summary -> (setId: Int, url: String, destination: URL)? in
                guard let artwork = summary.artwork,
                      let destination = artworkFileURL(setId: summary.id, remote: artwork.url)
                else { return nil }
                return (summary.id, artwork.url, destination)
            }

            if !artworkJobs.isEmpty {
                var artDone = 0
                state = .downloading(stage: "Artwork", completed: 0, total: artworkJobs.count)

                for job in artworkJobs {
                    if !FileManager.default.fileExists(atPath: job.destination.path) {
                        do {
                            try await Self.download(with: downloadSession, from: job.url, to: job.destination)
                            retireOtherArtwork(setId: job.setId, keeping: job.destination)
                        } catch {
                            failures += 1
                        }
                    }
                    artDone += 1
                    state = .downloading(stage: "Artwork", completed: artDone, total: artworkJobs.count)
                }
            }

            // Stage 3 — audio: narrations discovered above, plus chants.
            // Its own monotonic counter; the denominator never moves.
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

            // Stage 4 — the spoken Rosary: every prayer, announcement and
            // verse in the chosen voice, through the pack's own download.
            // Best-effort: a failure here leaves the rest of the library
            // complete, and the pack tries again when next prayed aloud.
            state = .downloading(stage: "Spoken Prayers", completed: 0, total: 1)
            _ = try? await RosaryAudioPack.shared.prepare(
                voice: voice,
                clips: SpokenRosaryScript.everyClip()
            ) { [weak self] done, total in
                self?.state = .downloading(stage: "Spoken Prayers", completed: done, total: max(total, 1))
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
            refreshDiskState()

            if failures == 0 {
                state = .downloaded(at: manifest.downloadedAt, bytes: bytes)
            } else {
                state = .failed("\(failures) file\(failures == 1 ? "" : "s") couldn't be downloaded. Try Again to finish — finished files are kept.")
            }
        } catch {
            // Stage 1 may already have written sets before the throw, so
            // re-read before trusting the cached flag.
            refreshDiskState()
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
        refreshDiskState()
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
    ///
    /// `@concurrent` is what actually gets it off the main actor: the caller
    /// is @MainActor, and a plain `nonisolated async` function would inherit
    /// that isolation and block the very tap this exists to keep responsive.
    /// The URLs are resolved on the main actor first, then the disk work runs
    /// on the pool.
    func storedRandomSet(category: MysteryCategory) async -> MeditationSet? {
        await Self.randomSet(indexURL: indexURL(for: category), setsDir: setsDir)
    }

    @concurrent
    private nonisolated static func randomSet(indexURL: URL, setsDir: URL) async -> MeditationSet? {
        guard let data = try? Data(contentsOf: indexURL),
              let summaries = try? decoder().decode([MeditationSetSummary].self, from: data) else {
            return nil
        }

        // Same naming convention as `setURL(id:)` — kept in one expression
        // so the on-disk layout can't drift between the two readers.
        let file: (Int) -> URL = { setsDir.appendingPathComponent("\($0).json") }

        let available = summaries.filter {
            FileManager.default.fileExists(atPath: file($0.id).path)
        }
        guard let pick = available.randomElement(),
              let setData = try? Data(contentsOf: file(pick.id)) else { return nil }
        return try? decoder().decode(MeditationSet.self, from: setData)
    }

    /// Local narration audio for a meditation in one voice, if downloaded.
    func localAudioURL(meditationId: Int, voice: String) -> URL? {
        let url = meditationAudioURL(meditationId: meditationId, voice: voice)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Any saved narration of a meditation, with the voice it is in, when
    /// the one asked for is not on disk. For playing what there is rather
    /// than nothing; the caller decides whether that beats the network.
    func anyLocalAudio(meditationId: Int) -> (url: URL, voice: String)? {
        let saved = downloadedAudio
            .filter { $0.meditationId == meditationId }
            .sorted { $0.voice < $1.voice }
        for key in saved {
            if let url = localAudioURL(meditationId: key.meditationId, voice: key.voice) {
                return (url, key.voice)
            }
        }
        return nil
    }

    /// Local chant audio for a consecration prayer, if downloaded.
    func localPrayerAudioURL(prayerId: String) -> URL? {
        let url = prayerAudioURL(prayerId: prayerId)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// The set's painting on disk, if the copy here is of *this* URL.
    ///
    /// The file is named by the hash the S3 key carries, so a painting the
    /// curator has since replaced is simply not found under the new URL —
    /// the caller fetches the new one and never shows the old plate for
    /// the new record.
    func localArtworkURL(setId: Int, remote: String) -> URL? {
        guard let url = artworkFileURL(setId: setId, remote: remote) else { return nil }
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - One Set

    /// How one set stands on this device, as its own page reads it.
    enum SetOfflineState: Equatable {
        /// Not saved — the page offers to save it
        case available
        /// Being saved, with the share of its files already down
        case saving(fraction: Double)
        /// Text and every narration it has are on disk
        case saved
        /// Some file didn't come down; finished ones were kept
        case failed
    }

    /// Sets being saved right now, with their file counts. Kept apart
    /// from `state`, which belongs to the library-wide download: saving
    /// one set from its own page must not make Account report that the
    /// whole library is downloading.
    private(set) var savingSets: [Int: (completed: Int, total: Int)] = [:]

    /// Sets whose last save left something behind
    private(set) var failedSetIds: Set<Int> = []

    /// Where this set stands.
    ///
    /// Saved means the text *and* every narration the set carries, in the
    /// voice this person hears — a set whose audio is missing is not one
    /// you can pray on a plane, so it must not claim to be saved. A set
    /// with no audio at all is saved as soon as its text is down.
    func offlineState(for set: MeditationSet) -> SetOfflineState {
        if let progress = savingSets[set.id] {
            let fraction = progress.total > 0
                ? Double(progress.completed) / Double(progress.total)
                : 0
            return .saving(fraction: fraction)
        }

        if downloadedSetIds.contains(set.id) && missingAudioIds(for: set).isEmpty {
            return .saved
        }

        return failedSetIds.contains(set.id) ? .failed : .available
    }

    private func missingAudioIds(for set: MeditationSet) -> [Int] {
        let voice = NarrationVoiceCatalog.shared.chosenSlug
        return (set.meditations ?? [])
            .compactMap { meditation -> Int? in
                guard let narration = meditation.playableNarration(preferring: voice) else { return nil }
                let key = AudioKey(meditationId: meditation.id, voice: narration.voice)
                return downloadedAudio.contains(key) ? nil : meditation.id
            }
    }

    /// Saves one set — its text, its painting if it has one, and every
    /// narration it carries — for praying without a connection.
    ///
    /// The set is re-fetched first: presigned audio links live about a
    /// day, and the copy the caller is holding may have come from a cache
    /// old enough that they have expired. If that fetch fails the
    /// caller's own copy is used, which still works for a set opened
    /// moments ago.
    @MainActor
    func downloadSet(_ set: MeditationSet) async {
        guard savingSets[set.id] == nil else { return }

        createDirectories()
        failedSetIds.remove(set.id)
        savingSets[set.id] = (completed: 0, total: 1)
        defer { savingSets[set.id] = nil }

        let source = (try? await APIService.shared.fetchMeditationSet(id: set.id)) ?? set
        let voice = NarrationVoiceCatalog.shared.chosenSlug
        let jobs = (source.meditations ?? []).compactMap { meditation -> (id: Int, voice: String, url: String)? in
            guard let narration = meditation.playableNarration(preferring: voice) else { return nil }
            return (meditation.id, narration.voice, narration.audioUrl)
        }
        let artworkJob: (url: String, destination: URL)? = source.artwork.flatMap { artwork in
            artworkFileURL(setId: source.id, remote: artwork.url).map { (artwork.url, $0) }
        }

        var completed = 0
        let total = jobs.count + (artworkJob == nil ? 0 : 1) + 1
        savingSets[set.id] = (completed: 0, total: total)

        var failures = 0

        do {
            try await Self.writeJSON(source, to: setURL(id: source.id))
        } catch {
            failures += 1
        }
        completed += 1
        savingSets[set.id] = (completed: completed, total: total)

        if let artworkJob {
            if !FileManager.default.fileExists(atPath: artworkJob.destination.path) {
                do {
                    try await Self.download(with: downloadSession, from: artworkJob.url, to: artworkJob.destination)
                    retireOtherArtwork(setId: source.id, keeping: artworkJob.destination)
                } catch {
                    failures += 1
                }
            }
            completed += 1
            savingSets[set.id] = (completed: completed, total: total)
        }

        for job in jobs {
            let destination = meditationAudioURL(meditationId: job.id, voice: job.voice)
            if !FileManager.default.fileExists(atPath: destination.path) {
                do {
                    try await Self.download(with: downloadSession, from: job.url, to: destination)
                } catch {
                    failures += 1
                }
            }
            completed += 1
            savingSets[set.id] = (completed: completed, total: total)
        }

        refreshDiskState()
        if failures > 0 { failedSetIds.insert(set.id) }
    }

    /// Removes one set's saved text and narrations.
    ///
    /// The category index still lists the set afterwards, which is
    /// harmless — `storedSummaries` only offers sets whose body is
    /// actually on disk, so the catalog heals itself on the next read.
    func removeSet(_ set: MeditationSet) {
        try? FileManager.default.removeItem(at: setURL(id: set.id))
        for meditation in set.meditations ?? [] {
            for file in audioFiles(meditationId: meditation.id) {
                try? FileManager.default.removeItem(at: file)
            }
        }
        for file in artworkFiles(setId: set.id) {
            try? FileManager.default.removeItem(at: file)
        }
        failedSetIds.remove(set.id)
        refreshDiskState()
    }

    // MARK: - One Meditation's Narration

    /// Narrations being fetched right now.
    ///
    /// Kept apart from `state`, which belongs to the library-wide download:
    /// saving one meditation from the player must not make Account report
    /// that the whole library is downloading.
    private(set) var downloadingAudio: Set<AudioKey> = []

    /// Whether this meditation's narration in `voice` is already on disk.
    func hasLocalAudio(meditationId: Int, voice: String) -> Bool {
        downloadedAudio.contains(AudioKey(meditationId: meditationId, voice: voice))
    }

    /// Whether this meditation's narration in `voice` is being fetched.
    func isDownloadingAudio(meditationId: Int, voice: String) -> Bool {
        downloadingAudio.contains(AudioKey(meditationId: meditationId, voice: voice))
    }

    /// Saves one meditation's narration, in one voice, for offline prayer.
    ///
    /// The presigned URL on a meditation expires in about a day, so this
    /// takes whatever URL the caller is holding right now rather than
    /// re-resolving one - and the voice that URL really is, which the
    /// caller knows and the URL does not say.
    @discardableResult
    func downloadAudio(meditationId: Int, voice: String, from urlString: String) async -> Bool {
        let key = AudioKey(meditationId: meditationId, voice: voice)
        guard !downloadingAudio.contains(key) else { return false }
        guard !downloadedAudio.contains(key) else { return true }

        createDirectories()
        downloadingAudio.insert(key)
        defer { downloadingAudio.remove(key) }

        do {
            try await Self.download(
                with: downloadSession,
                from: urlString,
                to: meditationAudioURL(meditationId: meditationId, voice: voice)
            )
            refreshDiskState()
            return true
        } catch {
            return false
        }
    }

    /// Removes one meditation's saved narration in one voice.
    func removeAudio(meditationId: Int, voice: String) {
        try? FileManager.default.removeItem(at: meditationAudioURL(meditationId: meditationId, voice: voice))
        refreshDiskState()
    }

    // MARK: - Private Helpers

    private func indexURL(for category: MysteryCategory) -> URL {
        setsDir.appendingPathComponent("index_\(category.rawValue).json")
    }

    private func setURL(id: Int) -> URL {
        setsDir.appendingPathComponent("\(id).json")
    }

    private func meditationAudioURL(meditationId: Int, voice: String) -> URL {
        audioDir.appendingPathComponent("meditation_\(meditationId)_\(voice).mp3")
    }

    /// Every voice of one meditation saved here.
    private func audioFiles(meditationId: Int) -> [URL] {
        downloadedAudio
            .filter { $0.meditationId == meditationId }
            .map { meditationAudioURL(meditationId: $0.meditationId, voice: $0.voice) }
    }

    private func prayerAudioURL(prayerId: String) -> URL {
        audioDir.appendingPathComponent("prayer_\(prayerId).mp3")
    }

    /// `images/set_27_8f21c4d9e0b3a7f6.jpg` for
    /// `…/lumenviae-images/sets/27/8f21c4d9e0b3a7f6.jpg`.
    ///
    /// The URL's last path component is a hash of the file, so the name
    /// is the staleness check: a replaced painting asks for a file that is
    /// not there. Nil for a URL with no usable file name — nothing is
    /// saved under a name that could collide with another set's.
    private func artworkFileURL(setId: Int, remote: String) -> URL? {
        guard let url = URL(string: remote) else { return nil }
        let stem = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
        let safe = stem.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" }
        guard !stem.isEmpty, safe else { return nil }
        return imagesDir.appendingPathComponent("set_\(setId)_\(stem).\(ext)")
    }

    /// Every painting saved for one set — normally one, but a set whose
    /// painting was replaced can briefly hold two.
    private func artworkFiles(setId: Int) -> [URL] {
        let prefix = "set_\(setId)_"
        let names = (try? FileManager.default.contentsOfDirectory(atPath: imagesDir.path)) ?? []
        return names
            .filter { $0.hasPrefix(prefix) }
            .map { imagesDir.appendingPathComponent($0) }
    }

    /// After a new painting lands for a set, the one it replaced goes —
    /// the file names carry the set id, so the siblings are findable
    /// without reading any JSON.
    private func retireOtherArtwork(setId: Int, keeping current: URL) {
        for file in artworkFiles(setId: setId) where file.lastPathComponent != current.lastPathComponent {
            try? FileManager.default.removeItem(at: file)
        }
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

    // @concurrent: these must leave the main actor. `nonisolated async` alone
    // does not — under SWIFT_APPROACHABLE_CONCURRENCY an async function
    // inherits its caller's isolation, and every caller here is @MainActor,
    // so the encode/decode, the file writes, and the directory walk all ran
    // on the main thread and froze the UI for the length of a download.

    private nonisolated static func decoder() -> JSONDecoder { JSONDecoder() }

    @concurrent
    private nonisolated static func writeJSON<T: Encodable>(_ value: T, to url: URL) async throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }

    @concurrent
    private nonisolated static func readJSON<T: Decodable>(_ type: T.Type, from url: URL) async -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    @concurrent
    private nonisolated static func download(with session: URLSession, from urlString: String, to destination: URL) async throws {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (temp, response) = try await session.download(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temp, to: destination)
    }

    @concurrent
    private nonisolated static func directorySize(of url: URL) async -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        // nextObject() rather than for-in: DirectoryEnumerator's iterator is
        // unavailable from async contexts.
        var total: Int64 = 0
        while let fileURL = enumerator.nextObject() as? URL {
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            total += Int64(size)
        }
        return total
    }
}
