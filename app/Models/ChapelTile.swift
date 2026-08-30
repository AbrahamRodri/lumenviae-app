//
//  ChapelTile.swift
//  Lumen Viae
//
//  The vocabulary of the Chapel page: the sections a user can lay out
//  on it, and the record of how they laid them.
//
//  A placement is three facts — which tile, how wide it stands (full or
//  half), and whether it is on the page or put away in the tray. Order
//  is the array order. Nothing is ever deleted: a tile taken off the
//  page waits in the tray, and what it shows keeps living underneath.
//
//  Stored as raw strings in UserDefaults; a stored id this build no
//  longer knows is dropped on decode rather than corrupting the layout,
//  and a tile the build knows but the store doesn't gains its default
//  placement at the end.
//

import Foundation

// MARK: - ChapelTile

/// A section of the Chapel page.
enum ChapelTile: String, CaseIterable, Identifiable {
    case rule = "rule"
    case consecration = "consecration"
    case reading = "reading"
    case library = "library"
    case chant = "chant"
    case reflections = "reflections"
    case flame = "flame"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rule:         return "Today"
        case .consecration: return "Consecration"
        case .reading:      return "Reading"
        case .library:      return "Library"
        case .chant:        return "Chant"
        case .reflections:  return "Reflections"
        case .flame:        return "Prayer Streak"
        }
    }

    /// One line in the tray saying what the section shows.
    var detail: String {
        switch self {
        case .rule:         return "Your rule of prayer, act by act"
        case .consecration: return "Your place on the 33-day preparation"
        case .reading:      return "The book you have open"
        case .library:      return "The missal, office, books, and guides"
        case .chant:        return "Sung prayer, kept close to hand"
        case .reflections:  return "Your latest journal entries"
        case .flame:        return "Your streak and this week's prayer"
        }
    }

    var icon: String {
        switch self {
        case .rule:         return "ph-scroll"
        case .consecration: return "ph-crown"
        case .reading:      return "ph-book-open-fill"
        case .library:      return "ph-book"
        case .chant:        return "ph-music-note"
        case .reflections:  return "ph-note-pencil"
        case .flame:        return "ph-flame"
        }
    }

    /// Tiles ruled straight onto the page, with no card corner to hang
    /// chrome off — their ✕ badge rides in the row gap above instead.
    var isFrameless: Bool {
        switch self {
        case .rule, .consecration, .library, .chant: return true
        case .reading, .reflections, .flame:         return false
        }
    }
}

// MARK: - ChapelPlacement

/// One tile's place on the page: its width and whether it is out at all.
struct ChapelPlacement: Equatable, Identifiable {
    let tile: ChapelTile

    /// 2 = the full-width layout, 1 = the compact one. Each tile has its
    /// own drawing of both — the half is never the full squeezed.
    var span: Int

    /// On the page, or put away in the tray.
    var on: Bool

    var id: String { tile.rawValue }
}

// MARK: - Layout codec

extension ChapelPlacement {

    /// A fresh page: everything out at full width, the streak standing
    /// directly under the day's acts — a record of days prayed belongs
    /// beside the day it records, and the last thing onboarding promises
    /// is that the flame is keeping it. It used to wait in the tray, which
    /// made that promise point at an empty page. The tray earns its keep
    /// from the first section a user puts away.
    static let defaultLayout: [ChapelPlacement] = [
        ChapelPlacement(tile: .rule, span: 2, on: true),
        ChapelPlacement(tile: .flame, span: 2, on: true),
        ChapelPlacement(tile: .consecration, span: 2, on: true),
        ChapelPlacement(tile: .reading, span: 2, on: true),
        ChapelPlacement(tile: .library, span: 2, on: true),
        ChapelPlacement(tile: .chant, span: 2, on: true),
        ChapelPlacement(tile: .reflections, span: 2, on: true)
    ]

    /// "rule:2:1" — id, span, on.
    var encoded: String {
        "\(tile.rawValue):\(span):\(on ? 1 : 0)"
    }

    static func decode(_ raw: [String]) -> [ChapelPlacement] {
        var seen: Set<ChapelTile> = []
        var layout: [ChapelPlacement] = raw.compactMap { entry in
            let parts = entry.split(separator: ":")
            guard parts.count == 3,
                  let tile = ChapelTile(rawValue: String(parts[0])),
                  let span = Int(parts[1]),
                  seen.insert(tile).inserted
            else { return nil }
            return ChapelPlacement(
                tile: tile,
                span: span == 1 ? 1 : 2,
                on: parts[2] == "1"
            )
        }

        // A tile this build knows that the stored layout doesn't (a new
        // section) arrives in its default place: on the page if the
        // default puts it there, in the tray otherwise.
        for fallback in defaultLayout where !seen.contains(fallback.tile) {
            layout.append(fallback)
        }
        return layout
    }
}
