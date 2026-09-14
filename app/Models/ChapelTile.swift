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
//  placement, in its default place.
//

import Foundation

// MARK: - ChapelTile

/// A section of the Chapel page.
enum ChapelTile: String, CaseIterable, Identifiable {
    case rule = "rule"
    case consecration = "consecration"
    case reading = "reading"
    case liturgy = "liturgy"
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
        case .liturgy:      return "Liturgy"
        case .library:      return "Library"
        case .chant:        return "Chant"
        case .reflections:  return "Reflections"
        case .flame:        return "Prayer Streak"
        }
    }

    /// The kicker's name at half width, where a long one would leave no
    /// room beside it for its note. The tray and the ghost keep the
    /// full name.
    var shortTitle: String {
        switch self {
        case .flame: return "Streak"
        default:     return title
        }
    }

    /// One line in the tray saying what the section shows.
    var detail: String {
        switch self {
        case .rule:         return "Your rule of prayer, act by act"
        case .consecration: return "Your place on the 33-day preparation"
        case .reading:      return "The book you have open"
        case .liturgy:      return "The Mass and the Hours of the day"
        case .library:      return "The books, the guides, and the saints"
        case .chant:        return "Sung prayer, kept close to hand"
        case .reflections:  return "Your latest journal entries"
        case .flame:        return "Your streak and this week's prayer"
        }
    }

    /// The tile this one was cut out of, where it was. A stored layout
    /// that predates it seats it beside that tile, at that tile's width,
    /// and only if that tile is on the page: the Liturgy's two doors
    /// lived in the Library, and a reader who put the Library away had
    /// put the Missal and the Office away with it.
    var cutFrom: ChapelTile? {
        switch self {
        case .liturgy: return .library
        default:       return nil
        }
    }

    var icon: String {
        switch self {
        case .rule:         return "ph-scroll"
        case .consecration: return "ch-consecration"
        case .reading:      return "ph-book-open"
        case .liturgy:      return "ch-altar"
        case .library:      return "ph-book"
        case .chant:        return "ph-music-note"
        case .reflections:  return "ph-note-pencil"
        case .flame:        return "ph-flame"
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
    ///
    /// The live sections come first, in the order a day meets them: the
    /// acts, the record of them, the preparation under way, the book left
    /// open, the chant, the reader's own words. The two indexes of doors
    /// stand last — the Liturgy, then the Library, whose colophon is the
    /// right last line before the imprint.
    static let defaultLayout: [ChapelPlacement] = [
        ChapelPlacement(tile: .rule, span: 2, on: true),
        ChapelPlacement(tile: .flame, span: 2, on: true),
        ChapelPlacement(tile: .consecration, span: 2, on: true),
        ChapelPlacement(tile: .reading, span: 2, on: true),
        ChapelPlacement(tile: .chant, span: 2, on: true),
        ChapelPlacement(tile: .reflections, span: 2, on: true),
        ChapelPlacement(tile: .liturgy, span: 2, on: true),
        ChapelPlacement(tile: .library, span: 2, on: true)
    ]

    /// "rule:2:1" — id, span, on.
    var encoded: String {
        "\(tile.rawValue):\(span):\(on ? 1 : 0)"
    }

    static func decode(_ raw: [String]) -> [ChapelPlacement] {
        var seen: Set<ChapelTile> = []
        let layout: [ChapelPlacement] = raw.compactMap { entry in
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
        // section) arrives as its default placement puts it
        return completing(layout)
    }

    /// Seats every tile `layout` lacks, each in its default place —
    /// before the first tile the default order puts after it — so a new
    /// section lands beside its neighbours rather than at the foot of a
    /// page arranged before it existed.
    ///
    /// `placing` decides a newcomer's placement from its default; the
    /// stored layout takes it as it is, and the Me page's migration puts
    /// what that page never showed in the tray. A tile cut out of
    /// another (`cutFrom`) then takes that tile's width and whether it
    /// is out, as that tile stands in the finished layout.
    static func completing(
        _ layout: [ChapelPlacement],
        placing: (ChapelPlacement) -> ChapelPlacement = { $0 }
    ) -> [ChapelPlacement] {
        let present = Set(layout.map(\.tile))
        var result = layout

        for (position, fallback) in defaultLayout.enumerated() where !present.contains(fallback.tile) {
            var placement = placing(fallback)

            if let source = fallback.tile.cutFrom {
                let sourcePlacement = layout.first { $0.tile == source }
                    ?? defaultLayout.first { $0.tile == source }.map(placing)
                if let sourcePlacement {
                    placement.span = sourcePlacement.span
                    placement.on = sourcePlacement.on
                }
            }

            let followers = Set(defaultLayout[(position + 1)...].map(\.tile))
            let at = result.firstIndex { followers.contains($0.tile) } ?? result.count
            result.insert(placement, at: at)
        }
        return result
    }
}
