//
//  WidgetSnapshotStore.swift
//  Lumen Viae
//
//  Writes the widgets' snapshot (`WidgetSnapshot`) into the App Group's
//  container and asks WidgetKit to redraw the widgets, only when the
//  snapshot has changed. Until the app carries the App Groups entitlement
//  (it waits on the developer account; see the widgets-setup slice) the
//  container is not there, and nothing is written.
//

import Foundation
import SwiftData
import WidgetKit

final class WidgetSnapshotStore {

    static let shared = WidgetSnapshotStore()

    /// Where the snapshot is kept; nil when the App Group's container is
    /// not there
    private let directory: URL?

    /// Asks the widgets to redraw; WidgetKit's in the app, counted in tests
    private let reloadWidgets: () -> Void

    /// The last snapshot written, so an unchanged one is not written again
    private(set) var lastWritten: WidgetSnapshot?

    init(
        directory: URL? = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WidgetSnapshot.appGroupID),
        reloadWidgets: @escaping () -> Void = { WidgetCenter.shared.reloadAllTimelines() }
    ) {
        self.directory = directory
        self.reloadWidgets = reloadWidgets
        lastWritten = directory.flatMap { Self.read(from: $0) }
    }

    var fileURL: URL? {
        directory?.appendingPathComponent(WidgetSnapshot.fileName)
    }

    /// Writes `snapshot` when it differs from the last one written, then
    /// asks the widgets to redraw. Says whether it wrote.
    @discardableResult
    func write(_ snapshot: WidgetSnapshot) -> Bool {
        guard let fileURL, snapshot != lastWritten else { return false }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(snapshot),
              (try? data.write(to: fileURL, options: .atomic)) != nil else { return false }
        lastWritten = snapshot
        reloadWidgets()
        return true
    }

    /// Builds the snapshot from the app's state now and writes it if it
    /// changed. Cheap enough to call on every change it may follow.
    func refresh(modelContext: ModelContext, now: Date = Date()) {
        guard directory != nil else { return }
        let sessions = (try? modelContext.fetch(FetchDescriptor<PrayerSession>())) ?? []
        let consecrations = (try? modelContext.fetch(FetchDescriptor<ConsecrationProgress>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
        let day = MissalAPIService.dayString(for: now)
        let liturgicalDay = MissalCacheService.shared.loadProper(for: day)?.first.map {
            WidgetSnapshot.LiturgicalDay(
                day: day, title: $0.info.title, rank: $0.info.rankLabel, colour: $0.info.colors?.first)
        }
        write(WidgetSnapshot.make(
            resume: PrayerResumeService.shared.inProgress,
            novenas: NovenaStore.shared.progress,
            // In the app's language, as the novena's own page names it
            novenaName: { id in
                NovenaDayContext.novena(id, spanish: SpanishContent.isActive, translations: LibraryContent.novenaSpanish)
                    .map { $0.listTitle ?? $0.title }
            },
            prayerDays: PrayerHistoryService.prayerDays(of: sessions.map(\.completedAt)),
            consecration: TodaysPrayerRow.shownConsecration(among: consecrations, at: now),
            liturgicalDay: liturgicalDay,
            now: now
        ))
    }

    /// The snapshot kept in `directory`, as a widget reads it
    static func read(from directory: URL) -> WidgetSnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(WidgetSnapshot.fileName)) else {
            return nil
        }
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }
}
