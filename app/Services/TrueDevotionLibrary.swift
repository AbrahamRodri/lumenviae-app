//
//  TrueDevotionLibrary.swift
//  Lumen Viae
//
//  Owns the full text of True Devotion. Unlike meditations, this is a fixed
//  public-domain book — the same for every user, never edited at runtime, and
//  needed offline mid-prayer — so it ships in the bundle rather than coming
//  from the content API.
//
//  The text is generated from Tools/TrueDevotion; see the README there before
//  changing anything about the resource.
//

import Foundation

/// Immutable once built, so it is safe to reach from any actor — which is what
/// lets `preload()` decode on a background task.
nonisolated final class TrueDevotionLibrary: Sendable {

    // MARK: - Shared Instance

    /// Decoding happens once, the first time this is touched. Swift guarantees
    /// that initialization is thread-safe, so `preload()` can warm it from a
    /// background task without racing a reader who opens the book early.
    static let shared = TrueDevotionLibrary()

    // MARK: - Properties

    /// Nil only if the bundled resource is missing or corrupt, which is a
    /// build error rather than a runtime condition — callers show an
    /// unavailable state instead of trapping.
    let book: TrueDevotionBook?

    // MARK: - Initialization

    /// Seam for previews and tests, which supply a book directly instead of
    /// paying to decode 280KB of bundled JSON.
    init(book: TrueDevotionBook?) {
        self.book = book
    }

    private convenience init() {
        self.init(book: Self.decodeBundledBook())
    }

    // MARK: - Preloading

    /// Decodes off the main thread at launch so the first tap into the reader
    /// doesn't pay for parsing before it can draw a frame.
    static func preload() {
        Task.detached(priority: .utility) { _ = shared }
    }

    // MARK: - Loading

    private static func decodeBundledBook() -> TrueDevotionBook? {
        guard let url = Bundle.main.url(forResource: "TrueDevotionBook", withExtension: "json") else {
            assertionFailure("TrueDevotionBook.json missing from bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(TrueDevotionBook.self, from: data)
        } catch {
            assertionFailure("TrueDevotionBook.json failed to decode: \(error)")
            return nil
        }
    }
}
