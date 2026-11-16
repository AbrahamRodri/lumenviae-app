//
//  LumenTimeline.swift
//  Lumen Viae Widgets
//
//  One timeline for every widget: the snapshot the app last wrote, read
//  afresh each time, and an entry at every moment something on a widget
//  turns — midnight (the day's mysteries and feast), four in the morning
//  (the prayer day), each Angelus bell and the hour after it, and each
//  hour of the Office. The app asks WidgetKit to redraw whenever it
//  writes a new snapshot.
//

import Foundation
import WidgetKit

enum SnapshotReader {

    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetSnapshot.appGroupID)
    }

    static var paintingsFolder: URL? {
        container?.appendingPathComponent(WidgetSnapshot.paintingsFolder)
    }

    /// The snapshot the app last wrote, or nil before it has written one
    static func read() -> WidgetSnapshot? {
        guard let file = container?.appendingPathComponent(WidgetSnapshot.fileName),
              let data = try? Data(contentsOf: file) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(WidgetSnapshot.self, from: data),
              snapshot.version == WidgetSnapshot.currentVersion else { return nil }
        return snapshot
    }
}

struct LumenEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    var day: WidgetSnapshot.Day? { snapshot?.day(at: date) }
    var prayerDay: WidgetSnapshot.Day? { snapshot?.prayerDay(at: date) }
}

struct LumenTimeline: TimelineProvider {

    func placeholder(in context: Context) -> LumenEntry {
        LumenEntry(date: Date(), snapshot: SnapshotReader.read())
    }

    func getSnapshot(in context: Context, completion: @escaping (LumenEntry) -> Void) {
        completion(LumenEntry(date: Date(), snapshot: SnapshotReader.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LumenEntry>) -> Void) {
        let now = Date()
        let snapshot = SnapshotReader.read()
        let entries = [now] + Self.turns(after: now, officeHours: snapshot?.hours.map(\.beginsAt) ?? WidgetSnapshot.officeHourStarts)
        completion(Timeline(entries: entries.map { LumenEntry(date: $0, snapshot: snapshot) }, policy: .atEnd))
    }

    /// The moments in the next day at which some widget changes
    static func turns(after now: Date, officeHours: [Int], calendar: Calendar = .current) -> [Date] {
        let hours: Set<Int> = Set([0, 4, 6, 7, 12, 13, 18, 19] + officeHours)
        let today = calendar.startOfDay(for: now)
        var turns: [Date] = []
        for dayOffset in 0...1 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            for hour in hours.sorted() {
                guard let turn = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                      turn > now, turn <= now.addingTimeInterval(24 * 3600) else { continue }
                turns.append(turn)
            }
        }
        return turns
    }
}

extension WidgetSnapshot {
    /// The clock hours the Office's eight hours begin at, as the app's
    /// `CanonicalHour.beginsAtClockHour`, until a snapshot gives its own
    static let officeHourStarts = [0, 5, 7, 9, 12, 14, 16, 19]
}
