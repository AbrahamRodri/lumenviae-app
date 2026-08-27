//
//  LibraryAudioDownloads.swift
//  Lumen Viae
//
//  Keeping a recording on the device, so a chapel with no signal still
//  has the voice — the same promise the missal makes about the day's
//  propers, and the Scriptural Rosary about its verses.
//
//  Per reading, never per book, and never quietly. The Story of a Soul
//  is about two hundred megabytes and the Dolorous Passion three
//  hundred; that is not something to hide behind one gold button. The
//  ledger says how many readings are saved and what they weigh, exactly
//  as the missal's calendar says how many of the month's days are
//  cached, and SAVE fetches the rest.
//
//  Downloads run in a background URLSession, so a reading keeps saving
//  while the reader prays, and finishes even if the app is put away.
//

import Foundation
import Observation

// MARK: - LibraryAudioDownloads

@MainActor
@Observable
final class LibraryAudioDownloads {

    static let shared = LibraryAudioDownloads()

    /// Where a reading stands on this device.
    enum State: Equatable {
        case absent
        /// 0…1, or nil while the server has not said how large it is
        case saving(Double?)
        case saved(bytes: Int64)
    }

    /// Sections currently downloading, keyed the same way as
    /// `savedBytes` — book and section together, so the two halves of
    /// one reading's state cannot disagree if a recording is ever shared
    /// between two catalog entries. With their last
    /// reported fraction — `nil` until the server says how large the
    /// file is. Observed, so rows redraw as they fill.
    ///
    /// Every write goes through `updateValue`/`removeValue` rather than
    /// the subscript: for a dictionary whose *value* is itself optional,
    /// `dict[key] = nil` removes the entry instead of storing a nil, so
    /// a download whose size was not yet known vanished from this map
    /// the moment it started and its row never showed it saving.
    private(set) var inFlight: [String: Double?] = [:]

    /// Byte sizes of readings already on disk, by file name — read once
    /// at launch and kept in step, so drawing the ledger never touches
    /// the file system on the main actor.
    private(set) var savedBytes: [String: Int64] = [:]

    private let directory: URL
    private var session: URLSession!
    private let delegate = DownloadDelegate()

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var url = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)

        // A background session so a reading being saved survives the
        // reader leaving the app. `isDiscretionary` stays off: this is a
        // download the reader asked for by name and is waiting on.
        let config = URLSessionConfiguration.background(
            withIdentifier: "org.lumenviae.library.audio"
        )
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.allowsCellularAccess = true
        delegate.storage = directory
        session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        delegate.owner = self

        Task { await refreshSaved() }

        // A background session hands back the transfers it was still
        // running when the app went away. Without asking for them the
        // rows read "not saved", and tapping SAVE enqueues the same
        // twenty megabytes a second time.
        session.getAllTasks { tasks in
            let running = tasks.compactMap { task -> String? in
                guard let parts = task.taskDescription?.split(separator: "\u{1}"),
                      parts.count == 2 else { return nil }
                return Self.fileName(bookID: String(parts[0]), sectionID: String(parts[1]))
            }
            guard !running.isEmpty else { return }
            Task { @MainActor [weak self] in
                for name in running { self?.inFlight.updateValue(nil, forKey: name) }
            }
        }
    }

    /// Teaches the delegate which readings belong to which book, so a
    /// download the system hands back after a relaunch can still be
    /// filed. Called with each book's track list as it is fetched.
    func register(bookID: String, sections: [LibriVoxSection]) {
        for section in sections {
            guard let url = section.streamURL else { continue }
            delegate.identityByURL[url] = (bookID, section.id)
        }

        // An empty ledger is never evidence that a recording was
        // replaced. LibriVox can answer 200 with no sections at all —
        // a schema change, an empty cached ledger — and the book page
        // calls this on that answer as readily as on a good one. Pruning
        // against nothing deletes every reading the reader deliberately
        // saved, which for the Dolorous Passion is three hundred
        // megabytes and no way back. Absence of a list is not a list of
        // absences: with nothing to compare against, keep everything.
        guard !sections.isEmpty else { return }

        // Anything saved for this book that the ledger no longer carries
        // is a reading from a recording the catalog has since replaced.
        // It can never be played again and nothing else will ever ask
        // about it, so it would sit in Application Support — where iOS
        // does not purge and the reader cannot reach — forever.
        let wanted = Set(sections.map { Self.fileName(bookID: bookID, sectionID: $0.id) })
        let prefix = "\(bookID)_"
        for name in savedBytes.keys where name.hasPrefix(prefix) && !wanted.contains(name) {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
            savedBytes[name] = nil
        }
    }

    // MARK: - Reading the state

    func state(bookID: String, sectionID: String) -> State {
        let name = Self.fileName(bookID: bookID, sectionID: sectionID)
        if let bytes = savedBytes[name] { return .saved(bytes: bytes) }
        if let fraction = inFlight[name] { return .saving(fraction) }
        return .absent
    }

    /// The file to play, when this reading is on the device. Playing the
    /// local copy is the whole point — and it also means a saved reading
    /// never spends the reader's data twice.
    func localURL(bookID: String, sectionID: String) -> URL? {
        let url = directory.appendingPathComponent(
            Self.fileName(bookID: bookID, sectionID: sectionID)
        )
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// How much of a book is on the device: how many readings, and what
    /// they weigh. What the ledger's honest line is built from.
    /// What a book's ledger foot needs, counted in one pass: what is
    /// here, what is still coming, and what is not on the device at all.
    /// The three used to be three separate walks of the same list, and a
    /// running download re-evaluates the page on every progress report.
    struct Tally {
        var savedCount = 0
        var savedBytes: Int64 = 0
        var isSaving = false
        var missing: [LibriVoxSection] = []
    }

    func tally(bookID: String, sections: [LibriVoxSection]) -> Tally {
        var tally = Tally()
        for section in sections {
            switch state(bookID: bookID, sectionID: section.id) {
            case .saved(let size):
                tally.savedCount += 1
                tally.savedBytes += size
            case .saving:
                tally.isSaving = true
            case .absent:
                tally.missing.append(section)
            }
        }
        return tally
    }

    // MARK: - Saving

    func save(bookID: String, section: LibriVoxSection) {
        guard case .absent = state(bookID: bookID, sectionID: section.id) else { return }
        guard let raw = section.streamURL, let url = URL(string: raw) else { return }

        inFlight.updateValue(nil, forKey: Self.fileName(bookID: bookID, sectionID: section.id))
        delegate.identityByURL[url.absoluteString] = (bookID, section.id)
        let task = session.downloadTask(with: url)
        // The task carries what the delegate needs to file the result;
        // the delegate runs off the main actor and has no view of the
        // catalog.
        task.taskDescription = "\(bookID)\u{1}\(section.id)"
        task.resume()
    }

    /// Saves everything not already here. Never automatic — the reader
    /// asks for this, having been told what it weighs.
    func saveAll(bookID: String, sections: [LibriVoxSection]) {
        for section in sections {
            save(bookID: bookID, section: section)
        }
    }

    func cancelAll(bookID: String, sections: [LibriVoxSection]) {
        let ids = Set(sections.map(\.id))
        session.getAllTasks { tasks in
            for task in tasks {
                guard let parts = task.taskDescription?.split(separator: "\u{1}"),
                      parts.count == 2, ids.contains(String(parts[1])) else { continue }
                task.cancel()
            }
        }
        for section in sections {
            inFlight.removeValue(forKey: Self.fileName(bookID: bookID, sectionID: section.id))
        }
    }

    /// Gives a reading back to the network. The listening place is kept
    /// — where you are in a book is not the same thing as whether its
    /// audio happens to be on this phone.
    func remove(bookID: String, sectionID: String) {
        let name = Self.fileName(bookID: bookID, sectionID: sectionID)
        inFlight.removeValue(forKey: name)
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        savedBytes[name] = nil
    }

    func removeAll(bookID: String, sections: [LibriVoxSection]) {
        for section in sections {
            remove(bookID: bookID, sectionID: section.id)
        }
    }

    // MARK: - Bookkeeping

    /// Reads what is on disk. Called at launch and after a download
    /// lands, so the ledger's counts never require a file-system walk
    /// while a view is drawing.
    func refreshSaved() async {
        let directory = directory
        let found = await Self.scan(directory)
        // Merged, not replaced: the scan runs off the actor, and a
        // download that finished while it was running would otherwise be
        // wiped back to "not saved" by a listing taken before it landed.
        for (name, size) in found where savedBytes[name] == nil {
            savedBytes[name] = size
        }
    }

    @concurrent
    private nonisolated static func scan(_ directory: URL) async -> [String: Int64] {
        let manager = FileManager.default
        guard let names = try? manager.contentsOfDirectory(atPath: directory.path) else { return [:] }
        var sizes: [String: Int64] = [:]
        for name in names where name.hasSuffix(".mp3") {
            let path = directory.appendingPathComponent(name).path
            let size = (try? manager.attributesOfItem(atPath: path)[.size]) as? Int64
            sizes[name] = size ?? 0
        }
        return sizes
    }

    /// Called by the delegate once a file has been moved into place.
    fileprivate func finished(bookID: String, sectionID: String, bytes: Int64) {
        let name = Self.fileName(bookID: bookID, sectionID: sectionID)
        inFlight.removeValue(forKey: name)
        savedBytes[name] = bytes
    }

    fileprivate func progressed(bookID: String, sectionID: String, fraction: Double?) {
        // Only for a download still running — a late report must not
        // resurrect one that has already landed or been cancelled.
        let name = Self.fileName(bookID: bookID, sectionID: sectionID)
        guard inFlight[name] != nil else { return }
        inFlight.updateValue(fraction, forKey: name)
    }

    fileprivate func failed(bookID: String, sectionID: String) {
        inFlight.removeValue(forKey: Self.fileName(bookID: bookID, sectionID: sectionID))
    }

    // MARK: - Names and numbers

    /// The section id is LibriVox's own and is stable across re-fetches
    /// of the ledger, so a saved reading is still recognised after the
    /// track list is refreshed.
    nonisolated static func fileName(bookID: String, sectionID: String) -> String {
        "\(bookID)_\(sectionID).mp3"
    }

    /// "199 MB". Sizes are shown for what is actually on disk; before a
    /// download there is only the estimate below, and it says so.
    nonisolated static func size(_ bytes: Int64) -> String {
        let megabytes = Double(bytes) / 1_000_000
        if megabytes < 1 { return "under 1 MB" }
        if megabytes < 1000 { return "\(Int(megabytes.rounded())) MB" }
        return String(format: "%.1f GB", megabytes / 1000)
    }

    /// What a set of readings will weigh, from their stated lengths.
    /// LibriVox serves these at 64 kbps, so eight kilobytes a second —
    /// close enough to warn someone before they spend three hundred
    /// megabytes, and labelled as an approximation wherever it is shown.
    nonisolated static func estimate(_ sections: [LibriVoxSection]) -> Int64 {
        let seconds = sections.reduce(0.0) { $0 + ($1.playtimeSeconds ?? 0) }
        return Int64(seconds * 8_000)
    }

}

// MARK: - Delegate

/// Runs off the main actor, knows nothing but how to file a finished
/// download and report a fraction.
private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {

    weak var owner: LibraryAudioDownloads?

    /// Where finished downloads are filed. Held here rather than read
    /// off the owner, because the move below cannot wait for an actor
    /// hop — see the comment inside.
    var storage: URL?

    /// Which book and reading each download URL belongs to.
    ///
    /// `taskDescription` alone is not enough. A background session hands
    /// its tasks back to a *relaunched* app, and that string is not
    /// promised to survive the trip — which would mean silently throwing
    /// away a reading that finished downloading while the app was gone,
    /// the one case this whole background session exists for. The URL
    /// does survive, so the catalog is indexed by it at startup and the
    /// description is only a fast path.
    var identityByURL: [String: (bookID: String, sectionID: String)] = [:]

    /// The book and reading a finished task belongs to.
    func identity(of task: URLSessionTask) -> (bookID: String, sectionID: String)? {
        if let parts = task.taskDescription?.split(separator: "\u{1}"), parts.count == 2 {
            return (String(parts[0]), String(parts[1]))
        }
        guard let url = task.originalRequest?.url?.absoluteString else { return nil }
        return identityByURL[url]
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let identity = identity(of: downloadTask), let storage else { return }
        let bookID = identity.bookID
        let sectionID = identity.sectionID

        // URLSession calls a 403 or a 503 a successful download whose
        // body happens to be an error page. Filed as an .mp3 it counts
        // toward "n of m readings saved" and — because a saved copy is
        // preferred over the network — makes that reading permanently
        // unplayable. Check before moving; the temporary file dies the
        // moment this method returns.
        if let http = downloadTask.response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            Task { @MainActor [weak owner] in
                owner?.failed(bookID: bookID, sectionID: sectionID)
            }
            return
        }

        // The move happens here, synchronously, and nowhere else. The
        // system deletes the temporary file the instant this method
        // returns — hopping to the main actor first and moving it there
        // means moving a file that is already gone, which is how a
        // download that the log showed finishing perfectly still left
        // the row empty.
        let manager = FileManager.default
        let destination = storage.appendingPathComponent(
            LibraryAudioDownloads.fileName(bookID: bookID, sectionID: sectionID)
        )
        try? manager.removeItem(at: destination)

        var moved = false
        do {
            try manager.moveItem(at: location, to: destination)
            moved = true
        } catch {
            #if DEBUG
            print("LibraryAudioDownloads: couldn't file the download — \(error)")
            #endif
        }
        let bytes = moved
            ? ((try? manager.attributesOfItem(atPath: destination.path)[.size]) as? Int64 ?? 0)
            : 0

        Task { @MainActor [weak owner] in
            guard let owner else { return }
            if moved {
                owner.finished(bookID: bookID, sectionID: sectionID, bytes: bytes)
            } else {
                owner.failed(bookID: bookID, sectionID: sectionID)
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let identity = identity(of: downloadTask) else { return }
        let fraction: Double? = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : nil

        Task { @MainActor [weak owner] in
            owner?.progressed(
                bookID: identity.bookID, sectionID: identity.sectionID, fraction: fraction
            )
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        #if DEBUG
        print("LibraryAudioDownloads: download failed — \(error)")
        #endif
        guard let identity = identity(of: task) else { return }
        Task { @MainActor [weak owner] in
            owner?.failed(bookID: identity.bookID, sectionID: identity.sectionID)
        }
    }
}
