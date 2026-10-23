//
//  MyPrayers.swift
//  Lumen Viae
//
//  The reader's own prayers and playlists, kept on the device beside the
//  Prayer Book (`MyPrayersStore`). A prayer of their own is written in
//  their words; a playlist is a run of prayers, the book's and their own
//  side by side, prayed one after another on the pray-along screen as an
//  order of the book is.
//
//  Each may hang a painting: one of the app's (an asset name) or a photo
//  the reader chose (`UserPhotoStore`, named `photo:<file>`). Every view
//  that draws a painting by name draws either (`PaintingSource`).
//

import Foundation

// MARK: - CustomPrayer

/// A prayer the reader wrote, or one written for them
struct CustomPrayer: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var text: String

    /// A painting's asset name or a chosen photo's, or nil for the
    /// book's own painting
    var art: String?

    init(id: UUID = UUID(), title: String, text: String, art: String? = nil) {
        self.id = id
        self.title = title
        self.text = text
        self.art = art
    }

    /// The id the book and the pray-along know it by: `my_` and its UUID,
    /// so it never meets an id of the book's
    var prayerID: String { CustomPrayer.prayerID(for: id) }

    static let idPrefix = "my_"

    static func prayerID(for id: UUID) -> String { idPrefix + id.uuidString }

    /// The UUID inside a `my_` id, or nil for an id of the book's
    static func uuid(in prayerID: String) -> UUID? {
        guard prayerID.hasPrefix(idPrefix) else { return nil }
        return UUID(uuidString: String(prayerID.dropFirst(idPrefix.count)))
    }

    /// The prayer as the book sets it, so every page that prays a book
    /// prayer prays this one too. Written in plain lines: each paragraph a
    /// line of its own, as the book's prose is.
    var bookPrayer: BookPrayer {
        BookPrayer(
            id: prayerID,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Prayer" : title,
            latinTitle: nil,
            origin: nil,
            note: nil,
            english: text.trimmingCharacters(in: .whitespacesAndNewlines),
            latin: nil
        )
    }
}

// MARK: - PrayerPlaylist

/// Prayers said one after another, in the reader's order
struct PrayerPlaylist: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String

    /// Book ids and `my_` ids, in the order they are prayed. The same
    /// prayer may stand twice (the Sign of the Cross opens and closes).
    var prayerIDs: [String]

    var art: String?

    init(id: UUID = UUID(), name: String, prayerIDs: [String] = [], art: String? = nil) {
        self.id = id
        self.name = name
        self.prayerIDs = prayerIDs
        self.art = art
    }

    /// The id the pray-along offers it under once its Amen is reached
    var orderID: String { "playlist_" + id.uuidString }

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Playlist" : name
    }
}
