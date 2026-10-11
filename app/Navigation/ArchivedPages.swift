//
//  ArchivedPages.swift
//  Lumen Viae
//
//  Pages put away until they are ready. Their views, data and routes stay
//  in the app; every door to them asks here first and stands down, so no
//  surface shows a dead link or a gap where a door was.
//
//  To bring a page back, take its route out of `routes`.
//

import Foundation

enum ArchivedPages {

    /// The archived pages. Remove a route to bring its page back.
    static let routes: Set<AppRoute> = [
        .trueDevotion,  // The Devotion in Summary (the book itself stays)
        .scripture,  // In Scripture
        .marianLibrary,  // The Marian Library
        .carloAcutis,  // St. Carlo Acutis
    ]

    /// Whether a route leads into an archived page: the page itself, a
    /// passage of In Scripture, or a reading on one of its shelves
    static func hides(_ route: AppRoute?) -> Bool {
        guard let route else { return false }
        switch route {
        case .mysteryInScripture:
            return routes.contains(.scripture)
        case .libraryReading(let id):
            guard let shelf = LibraryReadings.locate(id: id)?.section else { return false }
            return hides(shelf: shelf)
        default:
            return routes.contains(route)
        }
    }

    /// Whether a shelf of readings belongs to an archived page
    static func hides(shelf: ReadingShelf) -> Bool {
        guard let page = LibraryReadings.page(of: shelf) else { return false }
        return routes.contains(page)
    }

    /// Whether a reading's door leads into an archived page
    static func hides(_ door: ReadingDoor) -> Bool {
        if case .page(let route, _, _, _) = door { return hides(route) }
        return false
    }
}
