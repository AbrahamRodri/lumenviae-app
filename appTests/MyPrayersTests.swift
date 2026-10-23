//
//  MyPrayersTests.swift
//  Lumen Viae Tests
//
//  The reader's own prayers and playlists, on a folder of their own so
//  nothing of theirs is touched: kept and read back when the app next
//  opens, a deleted prayer taken out of its playlists, a playlist prayed
//  on the pray-along with its own image, every painting the picker
//  offers in the catalog, and the family's morning prayers added once.
//

import Foundation
import Testing
import UIKit

@testable import app

@MainActor
struct MyPrayersTests {

    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("MyPrayersTests-\(UUID().uuidString)", isDirectory: true)

    private func store() -> MyPrayersStore { MyPrayersStore(directory: directory) }

    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: "MyPrayersTests.\(UUID().uuidString)")!
    }

    // MARK: Kept

    @Test func whatIsSavedIsThereWhenTheAppNextOpens() {
        let first = store()
        let prayer = CustomPrayer(title: "For the Day", text: "Lord, bless this day.", art: "hour_morning")
        first.save(prayer)
        first.save(PrayerPlaylist(name: "Mornings", prayerIDs: ["sign_of_cross", prayer.prayerID]))

        let again = store()
        #expect(again.prayers == [prayer])
        #expect(again.playlists.map(\.name) == ["Mornings"])
        #expect(again.playlists.first?.prayerIDs == ["sign_of_cross", prayer.prayerID])
    }

    @Test func anEditTakesThePrayersPlace() {
        let book = store()
        var prayer = CustomPrayer(title: "Old", text: "Words")
        book.save(prayer)
        prayer.title = "New"
        book.save(prayer)
        #expect(book.prayers.count == 1)
        #expect(book.prayers.first?.title == "New")
    }

    @Test func aDeletedPrayerLeavesEveryPlaylist() {
        let book = store()
        let prayer = CustomPrayer(title: "Mine", text: "Amen.")
        book.save(prayer)
        book.save(PrayerPlaylist(name: "A", prayerIDs: [prayer.prayerID, "glory_be", prayer.prayerID]))
        book.delete(prayer)
        #expect(book.prayers.isEmpty)
        #expect(book.playlists.first?.prayerIDs == ["glory_be"])
    }

    @Test func aCustomPrayersIDNeverMeetsTheBooks() {
        let prayer = CustomPrayer(title: "T", text: "W")
        #expect(PrayerBook.prayer(prayer.prayerID) == nil)
        #expect(CustomPrayer.uuid(in: prayer.prayerID) == prayer.id)
        #expect(CustomPrayer.uuid(in: "glory_be") == nil)
    }

    // MARK: Praying

    @Test func thePrayAlongFindsTheReadersPrayerAndItsPainting() {
        let shared = MyPrayersStore.shared
        let prayer = CustomPrayer(title: "Test Prayer", text: "First line.\nSecond line.", art: "saint_michael")
        shared.save(prayer)
        defer { shared.delete(prayer) }

        let resolved = PrayAlongLaunch.resolve(prayer.prayerID)
        #expect(resolved?.title == "Test Prayer")
        #expect(resolved?.english == "First line.\nSecond line.")
        #expect(PrayerBookPainting.prayer(prayer.prayerID).asset == "saint_michael")
    }

    @Test func aPlaylistIsPrayedWithItsImageAndWithoutWhatIsGone() {
        let playlist = PrayerPlaylist(
            name: "Evenings",
            prayerIDs: ["sign_of_cross", "a_prayer_since_withdrawn", "glory_be"],
            art: "hour_night"
        )
        let launch = PrayAlongLaunch.playlist(playlist, startingAt: 7)
        #expect(launch.prayerIDs == ["sign_of_cross", "glory_be"])
        #expect(launch.startIndex == 1)
        #expect(launch.art == "hour_night")
        #expect(launch.isPlaylist)
        #expect(launch.title == "Evenings")
        #expect(!PrayAlongLaunch.order(PrayerBook.orders[0]).isPlaylist)
    }

    // MARK: Images

    @Test func everyPaintingThePickerOffersIsInTheCatalog() {
        let names = MyPrayersPaintings.all + FamilyPrayersSeed.prayers.map(\.art) + ["hour_morning"]
        #expect(names.filter { UIImage(named: $0) == nil } == [])
        #expect(Set(MyPrayersPaintings.all).count == MyPrayersPaintings.all.count)
    }

    private func photo(in book: MyPrayersStore) throws -> String {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        return try UserPhotoStore.save(try #require(image.pngData()), in: book.photosDirectory)
    }

    private func isOnDisk(_ name: String, in book: MyPrayersStore) -> Bool {
        UserPhotoStore.url(for: name, in: book.photosDirectory).map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }

    @Test func aReplacedPhotoIsDeleted() throws {
        let book = store()
        let first = try photo(in: book)
        var prayer = CustomPrayer(title: "T", text: "W", art: first)
        book.save(prayer)
        prayer.art = "hour_morning"
        book.save(prayer)
        #expect(!isOnDisk(first, in: book))
    }

    @Test func aPhotoAnotherPrayerStillHangsIsKept() throws {
        let book = store()
        let shared = try photo(in: book)
        let one = CustomPrayer(title: "One", text: "W", art: shared)
        book.save(one)
        book.save(PrayerPlaylist(name: "P", prayerIDs: [one.prayerID], art: shared))
        book.delete(one)
        #expect(isOnDisk(shared, in: book))
        book.delete(book.playlists[0])
        #expect(!isOnDisk(shared, in: book))
    }

    @Test func aPhotoPickedAndNeverSavedIsSweptAway() throws {
        let book = store()
        let kept = try photo(in: book)
        let abandoned = try photo(in: book)
        book.save(CustomPrayer(title: "T", text: "W", art: kept))
        book.sweepUnusedPhotos()
        #expect(isOnDisk(kept, in: book))
        #expect(!isOnDisk(abandoned, in: book))
    }

    @Test func aLibraryThisBuildCannotReadIsSetAsideNotErased() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("library.json")
        try Data("{ not a library".utf8).write(to: file)

        let book = store()
        #expect(book.prayers.isEmpty)
        book.save(CustomPrayer(title: "New", text: "W"))

        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        let aside = try #require(names.first { $0.hasPrefix("library.unreadable-") })
        #expect(try String(contentsOf: directory.appendingPathComponent(aside), encoding: .utf8) == "{ not a library")
    }

    @Test func onlyANameTheStoreGaveNamesAFile() {
        #expect(UserPhotoStore.url(for: "photo:../escape.jpg") == nil)
        #expect(UserPhotoStore.url(for: "photo:..") == nil)
        #expect(UserPhotoStore.url(for: "photo:.") == nil)
        #expect(UserPhotoStore.url(for: "photo:") == nil)
        #expect(UserPhotoStore.url(for: "hour_morning") == nil)
        #expect(UserPhotoStore.url(for: "photo:\(UUID().uuidString).jpg") != nil)
    }

    @Test func aPrayerOfTheReadersSavedWithTheRibbonStandsInSaved() {
        let shared = MyPrayersStore.shared
        let prayer = CustomPrayer(title: "Kept Prayer", text: "Amen.")
        shared.save(prayer)
        defer { shared.delete(prayer) }
        let book = PrayerBookStore(defaults: defaults())
        book.toggleRibbon(prayer.prayerID)
        #expect(book.keptPrayers.map(\.id) == [prayer.prayerID])
    }

    @Test func aPhotoIsKeptSmallAndReadBackByItsName() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 2000)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 3000, height: 2000))
        }
        let name = try UserPhotoStore.save(try #require(image.pngData()))
        defer { UserPhotoStore.url(for: name).map { try? FileManager.default.removeItem(at: $0) } }

        #expect(UserPhotoStore.isPhoto(name))
        let read = try #require(PaintingSource.image(named: name))
        #expect(max(read.size.width * read.scale, read.size.height * read.scale) <= UserPhotoStore.maxSide)
        #expect(PaintingSource.exists(name))
    }

    // MARK: The family's morning prayers

    @Test func theFamilysPrayersAreAddedOnce() {
        let book = store()
        let flags = defaults()
        FamilyPrayersSeed.seed(into: book, defaults: flags)
        FamilyPrayersSeed.seed(into: book, defaults: flags)

        #expect(book.prayers.count == 9)
        #expect(book.playlists.count == 1)
        let playlist = book.playlists[0]
        #expect(playlist.name == "Family Morning Prayer")
        #expect(playlist.prayerIDs.count == 10)
        #expect(playlist.prayerIDs.first == playlist.prayerIDs.last)
        #expect(book.prayers.map(\.title).first == "Sign of the Cross")
        #expect(book.prayers.last?.text.contains("All you holy Angels and Saints, pray for us.") == true)
    }

    @Test func aPlaylistOfTheSameNameIsLeftAlone() {
        let book = store()
        book.save(PrayerPlaylist(name: "Family Morning Prayer", prayerIDs: ["glory_be"]))
        FamilyPrayersSeed.seed(into: book, defaults: defaults())
        #expect(book.playlists.count == 1)
        #expect(book.prayers.isEmpty)
    }
}
