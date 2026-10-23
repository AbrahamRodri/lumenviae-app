//
//  MyPrayersStore.swift
//  Lumen Viae
//
//  The reader's own prayers and playlists (`CustomPrayer`,
//  `PrayerPlaylist`), kept in one file in Application Support. Local
//  only, as the Journal is: nothing is sent to the server.
//
//  A file and not SwiftData, so the pray-along's one lookup of a prayer
//  by its id (`PrayAlongLaunch.resolve`) finds the reader's prayers as it
//  finds the book's, with no model context to hand it.
//

import Foundation
import SwiftUI
import UIKit

@Observable
final class MyPrayersStore {

    static let shared = MyPrayersStore()

    private(set) var prayers: [CustomPrayer] = []
    private(set) var playlists: [PrayerPlaylist] = []

    private let fileURL: URL

    /// False when the library file is there but could not be read (the
    /// phone still locked since it started): nothing is written over it
    /// and no photo is swept until a launch that can read it
    private var canWrite = true

    /// Where the reader's photos are kept, beside the library file
    let photosDirectory: URL

    /// `directory` is Application Support's `MyPrayers` except in a test,
    /// which brings a folder of its own
    init(directory: URL = MyPrayersStore.defaultDirectory) {
        fileURL = directory.appendingPathComponent("library.json")
        photosDirectory = UserPhotoStore.directory(in: directory)
        load()
    }

    nonisolated static var defaultDirectory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("MyPrayers", isDirectory: true)
    }

    // MARK: - Prayers

    func prayer(_ id: UUID) -> CustomPrayer? {
        prayers.first { $0.id == id }
    }

    /// The reader's prayer behind a `my_` id
    func prayer(withPrayerID prayerID: String) -> CustomPrayer? {
        CustomPrayer.uuid(in: prayerID).flatMap(prayer)
    }

    /// Adds the prayer, or puts the edited one in its place
    func save(_ prayer: CustomPrayer) {
        if let index = prayers.firstIndex(where: { $0.id == prayer.id }) {
            let old = prayers[index]
            prayers[index] = prayer
            if old.art != prayer.art { discardIfUnused(old.art) }
        } else {
            prayers.append(prayer)
        }
        write()
    }

    /// Takes the prayer out of every playlist with it
    func delete(_ prayer: CustomPrayer) {
        prayers.removeAll { $0.id == prayer.id }
        for index in playlists.indices {
            playlists[index].prayerIDs.removeAll { $0 == prayer.prayerID }
        }
        discardIfUnused(prayer.art)
        write()
    }

    // MARK: - Playlists

    func playlist(_ id: UUID) -> PrayerPlaylist? {
        playlists.first { $0.id == id }
    }

    func save(_ playlist: PrayerPlaylist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            let old = playlists[index]
            playlists[index] = playlist
            if old.art != playlist.art { discardIfUnused(old.art) }
        } else {
            playlists.append(playlist)
        }
        write()
    }

    func delete(_ playlist: PrayerPlaylist) {
        playlists.removeAll { $0.id == playlist.id }
        discardIfUnused(playlist.art)
        write()
    }

    /// The playlist's prayers that can still be prayed: a prayer of the
    /// reader's since deleted, or one the book no longer holds, is passed
    /// over
    func resolvedPrayers(of playlist: PrayerPlaylist) -> [BookPrayer] {
        playlist.prayerIDs.compactMap { PrayAlongLaunch.resolve($0) }
    }

    /// Every image a prayer or playlist hangs, for photo clean-up
    var artInUse: Set<String> {
        Set(prayers.compactMap(\.art) + playlists.compactMap(\.art))
    }

    // MARK: - Photos

    /// Deletes a photo no prayer or playlist hangs any more
    private func discardIfUnused(_ name: String?) {
        guard let name, !artInUse.contains(name),
              let url = UserPhotoStore.url(for: name, in: photosDirectory)
        else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Deletes every photo nothing hangs: a photo is kept the moment it is
    /// picked, so one picked in an editor then cancelled, or picked over,
    /// is left behind. Run at launch, when no editor is open.
    func sweepUnusedPhotos() {
        // A library set aside still names its photos: none is swept while
        // one is kept, nor while the library itself could not be read
        let folder = fileURL.deletingLastPathComponent()
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        guard canWrite, !names.contains(where: { $0.hasPrefix("library.unreadable-") }) else { return }
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: photosDirectory.path) else { return }
        let inUse = artInUse
        for file in files where !inUse.contains(UserPhotoStore.prefix + file) {
            try? FileManager.default.removeItem(at: photosDirectory.appendingPathComponent(file))
        }
    }

    // MARK: - File

    private struct Library: Codable {
        var prayers: [CustomPrayer]
        var playlists: [PrayerPlaylist]
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        guard let data = try? Data(contentsOf: fileURL) else {
            canWrite = false
            return
        }
        guard let library = try? JSONDecoder().decode(Library.self, from: data) else {
            // Never written over: a file this build cannot read (a later
            // build's, or one cut short) is set aside whole, so the next
            // save does not erase the reader's prayers
            let aside = fileURL.deletingPathExtension()
                .appendingPathExtension("unreadable-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: fileURL, to: aside)
            return
        }
        prayers = library.prayers
        playlists = library.playlists
    }

    private func write() {
        guard canWrite else { return }
        let library = Library(prayers: prayers, playlists: playlists)
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(library)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            print("MyPrayersStore: could not save: \(error)")
        }
    }
}

// MARK: - UserPhotoStore

/// The photos the reader chose for their prayers and playlists, scaled
/// down and kept as JPEG beside the library file. Named `photo:<file>`
/// wherever a painting's asset name would stand.
nonisolated enum UserPhotoStore {

    static let prefix = "photo:"

    /// The longest side a photo is kept at: the pray-along's ground, full
    /// screen at 3x, never needs more
    static let maxSide: CGFloat = 1600

    static func isPhoto(_ name: String) -> Bool { name.hasPrefix(prefix) }

    /// The reader's photos, in the folder of the store that keeps them
    static func directory(in storeDirectory: URL = MyPrayersStore.defaultDirectory) -> URL {
        storeDirectory.appendingPathComponent("Photos", isDirectory: true)
    }

    /// The file behind a photo's name. Only a name this store gave, a
    /// UUID and `.jpg`, names a file: never a path out of the folder, nor
    /// the folder itself
    static func url(for name: String, in directory: URL = UserPhotoStore.directory()) -> URL? {
        guard isPhoto(name) else { return nil }
        let file = String(name.dropFirst(prefix.count))
        guard file.hasSuffix(".jpg"), UUID(uuidString: String(file.dropLast(4))) != nil else { return nil }
        return directory.appendingPathComponent(file)
    }

    /// Saves the picked photo and returns the name it is kept under
    static func save(_ data: Data, in directory: URL = UserPhotoStore.directory()) throws -> String {
        guard let image = UIImage(data: data) else { throw CocoaError(.fileReadCorruptFile) }
        let scaled = scaledDown(image)
        guard let jpeg = scaled.jpegData(compressionQuality: 0.82) else { throw CocoaError(.fileWriteUnknown) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = UUID().uuidString + ".jpg"
        try jpeg.write(to: directory.appendingPathComponent(file), options: .atomic)
        return prefix + file
    }

    static func image(named name: String) -> UIImage? {
        url(for: name).flatMap { UIImage(contentsOfFile: $0.path) }
    }

    private static func scaledDown(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxSide else { return image }
        let factor = maxSide / longest
        let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

}

// MARK: - PaintingSource

/// A painting by name: an asset of the catalog, or a photo the reader
/// chose. Every view that draws a painting by its name reads it here.
nonisolated enum PaintingSource {
    static func image(named name: String) -> UIImage? {
        if UserPhotoStore.isPhoto(name) { return UserPhotoStore.image(named: name) }
        return UIImage(named: name)
    }

    static func exists(_ name: String) -> Bool {
        if UserPhotoStore.isPhoto(name) {
            return UserPhotoStore.url(for: name).map { FileManager.default.fileExists(atPath: $0.path) } ?? false
        }
        return UIImage(named: name) != nil
    }
}
