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
import UIKit
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
    /// changed, with the paintings it names. Cheap enough to call on every
    /// change it may follow.
    func refresh(modelContext: ModelContext, now: Date = Date()) {
        guard let directory else { return }
        let sessions = (try? modelContext.fetch(FetchDescriptor<PrayerSession>())) ?? []
        let consecrations = (try? modelContext.fetch(FetchDescriptor<ConsecrationProgress>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
        let snapshot = WidgetSnapshot.make(
            resume: PrayerResumeService.shared.inProgress,
            novenas: NovenaStore.shared.progress,
            // In the app's language, as the novena's own page names it
            novenaInfo: { id in
                NovenaDayContext.novena(id, spanish: SpanishContent.isActive, translations: LibraryContent.novenaSpanish)
                    .map { WidgetSnapshot.NovenaInfo(name: $0.listTitle ?? $0.title, painting: $0.painting) }
            },
            prayerDays: PrayerHistoryService.prayerDays(of: sessions.map(\.completedAt)),
            consecration: TodaysPrayerRow.shownConsecration(among: consecrations, at: now),
            liturgicalDay: Self.liturgicalDay(on:),
            now: now
        )
        guard snapshot != lastWritten else { return }
        let names = snapshot.paintingNames
        // The paintings first, so a widget redrawn for the new snapshot
        // finds every painting it names
        Task.detached(priority: .utility) {
            Self.copyPaintings(names, into: directory.appendingPathComponent(WidgetSnapshot.paintingsFolder))
            await MainActor.run { _ = self.write(snapshot) }
        }
    }

    /// The day's feast as the Mass's propers name it, from the copy the
    /// Missal keeps on the phone; nil until it has the day
    static func liturgicalDay(on day: String) -> WidgetSnapshot.LiturgicalDay? {
        guard let info = MissalCacheService.shared.loadProper(for: day)?.first?.info else { return nil }
        let vestment = info.colors?.first.flatMap(MissalVestment.init(rawValue:))
        return WidgetSnapshot.LiturgicalDay(
            title: info.title,
            rank: info.rankLabel,
            colourName: vestment?.name,
            colourHex: vestment?.swatchHex,
            painting: PrayerBookPainting.topic(id: "mass").resolvedAsset
        )
    }

    /// The longest side a widget's painting is kept at: a large widget is
    /// 364 points, three pixels each, and a painting is never drawn wider
    nonisolated static let paintingPixels: CGFloat = 900

    /// Copies each painting `names` names that is not there yet, small
    nonisolated static func copyPaintings(_ names: Set<String>, into folder: URL) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for name in names {
            let file = folder.appendingPathComponent("\(name).jpg")
            guard !FileManager.default.fileExists(atPath: file.path),
                  let image = UIImage(named: name) else { continue }
            let scale = min(1, paintingPixels / max(image.size.width * image.scale, image.size.height * image.scale))
            let size = CGSize(
                width: (image.size.width * image.scale * scale).rounded(),
                height: (image.size.height * image.scale * scale).rounded())
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let small = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            try? small.jpegData(compressionQuality: 0.82)?.write(to: file, options: .atomic)
        }
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
