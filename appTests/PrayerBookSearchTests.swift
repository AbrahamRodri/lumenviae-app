//
//  PrayerBookSearchTests.swift
//  Lumen Viae Tests
//
//  The Prayer Book's prepared lookups answer exactly as the scans they
//  replaced: the search over prayers, orders and topics, a prayer's home
//  topic, a chapter or an order by id, and the orders that say each
//  prayer on a day. The old scans are kept here, as they were written,
//  and every answer is compared against them. And a painting drawn small
//  is drawn from a copy scaled to its frame.
//

import Foundation
import Testing
import UIKit

@testable import app

@MainActor
struct PrayerBookSearchTests {

    // MARK: - Searches

    /// What a reader types: names, parts of names, words of a prayer,
    /// Latin with and without its ligatures, the small words alone, and
    /// what finds nothing; then every prayer's, topic's and order's names
    private var queries: [String] {
        let typed = [
            "", " ", "a", "o", "st", "st.", "saint", "st michael", "St. Joseph", "saint joseph",
            "hail", "hail ma", "hail mary", "HAIL, HOLY", "loreto", "loretto", "regina caeli",
            "Regina Cæli", "praesidium", "præsidium", "salve", "the", "of the", "pray", "pra",
            "prayers to mary", "mary", "our lady", "holy ghost", "holy spirit", "blessed sacrament",
            "grace", "visiting", "ma", "our father", "who art in heaven", "forgive us", "amen",
            "lord have mercy", "kyrie", "TANTUM ergo", "memorare", "remember o most gracious",
            "novena", "newman", "jesus", "sacred heart", "dead", "for the dead", "purgatory",
            "angel", "angelus", "night", "morning", "on waking", "confession", "contrition",
            "coeli", "œ", "help", "danger", "pentecost", "trinity", "eucharist", "litany",
            "xyzzy", "1234", "  mary  ", "Ave", "ave maria", "gratia plena", "dominus tecum",
        ]
        let prayerNames = PrayerBook.prayers.values.flatMap {
            [$0.title, $0.listTitle] + ($0.latinTitle.map { [$0] } ?? [])
        }
        let topicNames = PrayerBook.chapters.flatMap { [$0.title, $0.topic, $0.latinTitle] }
        let orderNames = PrayerBook.orders.flatMap { [$0.title, $0.latinTitle, $0.occasion] }
        let prefixes = prayerNames.map { String($0.prefix(4)) }
        return typed + prayerNames + topicNames + orderNames + prefixes
    }

    @Test func prayerSearchAnswersAsTheScanDid() {
        for query in queries {
            #expect(
                PrayerBook.search(query).map(\.id) == Reference.search(query).map(\.id),
                "\"\(query)\""
            )
        }
    }

    @Test func orderSearchAnswersAsTheScanDid() {
        for query in queries {
            #expect(
                PrayerBook.searchOrders(query).map(\.id) == Reference.searchOrders(query).map(\.id),
                "\"\(query)\""
            )
        }
    }

    @Test func topicSearchAnswersAsTheScanDid() {
        for query in queries {
            #expect(
                PrayerBook.topics(matching: query).map(\.id) == Reference.topics(matching: query).map(\.id),
                "\"\(query)\""
            )
        }
    }

    @Test func searchesStillFindWhatThePageShows() {
        #expect(PrayerBook.search("st michael").first?.id == "st_michael_prayer")
        #expect(PrayerBook.search("regina caeli").contains { $0.id == "regina_caeli" })
        #expect(PrayerBook.searchOrders("blessed sacrament").map(\.id) == ["visit"])
        #expect(PrayerBook.topics(matching: "mary").map(\.id).contains("our_lady"))
    }

    /// A search lists each prayer once, however many topics print it
    @Test func searchListsEachPrayerOnce() {
        for query in ["hail", "mary", "st", "lord", "god"] {
            let ids = PrayerBook.search(query).map(\.id)
            #expect(ids.count == Set(ids).count, "\"\(query)\"")
        }
    }

    // MARK: - Lookups by id

    @Test func chaptersAndOrdersAreFoundByID() {
        for chapter in PrayerBook.chapters {
            #expect(PrayerBook.chapter(chapter.id)?.id == chapter.id)
        }
        for order in PrayerBook.orders {
            #expect(PrayerBook.order(order.id)?.id == order.id)
        }
        #expect(PrayerBook.chapter("nowhere") == nil)
        #expect(PrayerBook.order("nowhere") == nil)
    }

    @Test func everyPrayerHasTheHomeTheScanGaveIt() {
        for id in PrayerBook.prayers.keys.sorted() + ["nowhere"] {
            #expect(PrayerBook.homeChapter(of: id)?.id == Reference.homeChapter(of: id)?.id, "\(id)")
        }
    }

    @Test func chapterPrayersArePrintedOnceInOrder() {
        for chapter in PrayerBook.chapters {
            var seen = Set<String>()
            let printed = chapter.sections.flatMap(\.prayerIDs).filter { seen.insert($0).inserted }
            #expect(chapter.prayerIDs == printed, "\(chapter.id)")
        }
    }

    // MARK: - Small paintings

    @Test func aSmallPaintingIsScaledToItsFrame() throws {
        let asset = PrayerBookPainting.topic(PrayerBook.ourLady).resolvedAsset
        let full = try #require(UIImage(named: asset))
        let small = try #require(
            PaintingThumbnails.image(named: asset, filling: CGSize(width: 34, height: 44), scale: 3))

        let pixels = CGSize(width: small.size.width * small.scale, height: small.size.height * small.scale)
        #expect(pixels.width >= 34 * 3 - 1 && pixels.height >= 44 * 3 - 1, "covers the frame")
        #expect(pixels.width < full.size.width * full.scale, "smaller than the painting")
        let shape = full.size.width / full.size.height
        #expect(abs(pixels.width / pixels.height - shape) < 0.02, "keeps the painting's shape")

        let again = PaintingThumbnails.image(named: asset, filling: CGSize(width: 34, height: 44), scale: 3)
        #expect(again === small, "kept, not made again")
    }

    @Test func aMissingOrLargerPaintingIsNotScaled() {
        #expect(
            PaintingThumbnails.image(named: "no_such_painting", filling: CGSize(width: 34, height: 44), scale: 3) == nil
        )
        let asset = PrayerBookPainting.topic(PrayerBook.ourLady).resolvedAsset
        #expect(PaintingThumbnails.image(named: asset, filling: CGSize(width: 5000, height: 5000), scale: 3) == nil)
        #expect(PaintingThumbnails.image(named: asset, filling: .zero, scale: 3) == nil)
    }
}

// MARK: - The scans as they were

/// The book's searches and lookups as they were written before their
/// answers were prepared: every name folded and split at every search,
/// every chapter and order scanned for every lookup
@MainActor
private enum Reference {

    static func search(_ needle: String) -> [BookPrayer] {
        let wanted = searchWords(needle, asName: false)
        guard !wanted.isEmpty else { return [] }
        let phrase = folded(needle).trimmingCharacters(in: .whitespacesAndNewlines)
        var named: [BookPrayer] = []
        var worded: [BookPrayer] = []
        for chapter in PrayerBook.chapters {
            for prayer in chapter.prayers where !named.contains(prayer) && !worded.contains(prayer) {
                let names = [prayer.title, prayer.listTitle, prayer.latinTitle ?? ""] + prayer.searchWords
                if names.contains(where: { nameAnswers(wanted, $0) }) {
                    named.append(prayer)
                } else if phrase.count >= 4,
                    folded(prayer.english).contains(phrase) || folded(prayer.latin ?? "").contains(phrase)
                {
                    worded.append(prayer)
                }
            }
        }
        return named + worded
    }

    static func searchOrders(_ needle: String) -> [PrayerOrder] {
        let wanted = searchWords(needle, asName: false)
        guard !wanted.isEmpty, wanted.joined().count >= 3 else { return [] }
        return PrayerBook.orders.filter { order in
            let names = [order.title, order.latinTitle, order.occasion] + order.searchWords
            return names.contains { nameAnswers(wanted, $0) }
        }
    }

    static func topics(matching needle: String) -> [PrayerBookChapter] {
        let wanted = topicWords(needle)
        guard let last = wanted.last, wanted.joined().count >= 3, last.count >= 2 else { return [] }
        return PrayerBook.chapters.filter { chapter in
            let names = [chapter.title, chapter.topic, chapter.latinTitle] + chapter.searchWords
            return names.contains { name in
                let words = topicWords(name)
                return !words.isEmpty
                    && wanted.allSatisfy { want in
                        words.contains { $0.hasPrefix(want) }
                    }
            }
        }
    }

    static func homeChapter(of prayerID: String) -> PrayerBookChapter? {
        if let id = PrayerBook.homes[prayerID],
            let home = PrayerBook.chapters.first(where: { $0.id == id }),
            home.prayerIDs.contains(prayerID)
        {
            return home
        }
        return PrayerBook.chapters.first { $0.prayerIDs.contains(prayerID) }
    }

    private static func nameAnswers(_ wanted: [String], _ name: String) -> Bool {
        let words = searchWords(name)
        return !words.isEmpty
            && wanted.allSatisfy { want in
                words.contains { $0.hasPrefix(want) || (want == "st" && $0 == "saint") }
            }
    }

    private static func folded(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "Æ", with: "ae")
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "Œ", with: "oe")
            // Heaven's older spelling, which the one fold reads alike
            .replacingOccurrences(of: "coel", with: "cael")
    }

    private static func searchWords(_ text: String, asName: Bool = true) -> [String] {
        let words = folded(text)
            .split { !$0.isLetter }
            .map { asName && $0 == "st" ? "saint" : String($0) }
        let stop: Set<String> = ["a", "an", "and", "of", "the", "to", "o", "for", "in", "on", "at"]
        let kept = words.filter { !stop.contains($0) }
        return kept.isEmpty ? words : kept
    }

    private static func topicWords(_ text: String) -> [String] {
        let stop: Set<String> = [
            "a", "an", "and", "at", "for", "in", "of", "on", "the", "to", "with",
            "pray", "prayer", "prayers",
        ]
        return folded(text)
            .split { !$0.isLetter }
            .map(String.init)
            .filter { !stop.contains($0) }
    }
}
