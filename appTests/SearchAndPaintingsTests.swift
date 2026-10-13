//
//  SearchAndPaintingsTests.swift
//  Lumen Viae Tests
//
//  The second pass over the Prayers and Chant pages: the chant search
//  folded once against the scan it replaced, the words VoiceOver hears
//  for a chant, the pray-along's stanza measures, and the small
//  paintings made off the main actor.
//

import Foundation
import SwiftUI
import Testing

@testable import app

@MainActor
struct SearchAndPaintingsTests {

    // MARK: - The chant search, folded once

    /// The words search as it was: every line folded at every search
    private func scannedWordChants(_ needle: String) -> [String] {
        guard needle.count >= 3 else { return [] }
        var quoted = Set<String>()
        var found: [String] = []
        for chant in ChantCatalog.all {
            if chant.hasLines {
                let hit = chant.lines.contains {
                    SearchText.fold($0.latin).contains(needle) || SearchText.fold($0.english).contains(needle)
                }
                if hit { found.append(chant.id) }
            } else if let prayer = chant.bookPrayer, !quoted.contains(prayer.id) {
                let lines = ((prayer.latin ?? "") + "\n" + prayer.english).components(separatedBy: "\n")
                let hit = lines.contains { raw in
                    let text = SearchText.clean(raw)
                    return !text.isEmpty && SearchText.fold(text).contains(needle)
                }
                if hit {
                    found.append(chant.id)
                    quoted.insert(prayer.id)
                }
            }
        }
        return found
    }

    @Test func aChantsWordsAreFoundAsTheScanFoundThem() {
        let queries = [
            "salve", "spes nostra", "regina", "caeli", "coeli", "ora pro nobis", "lord", "kyrie",
            "amen", "sancta maria", "glory", "zzz", "ve", "Dómine", "ÆTERNE", "œ",
        ]
        for query in queries {
            let needle = SearchText.needle(query)
            #expect(ChantSearch.chants(withWordsMatching: needle).map(\.id) == scannedWordChants(needle), "\(query)")
        }
    }

    @Test func aChantIsFoundByThePrayerItSingsAsTheScanFoundIt() {
        for query in ["hail", "mary", "glory be", "queen", "te deum", "creed", "zzz"] {
            let needle = SearchText.needle(query)
            let scanned = ChantCatalog.all.filter { chant in
                guard let prayer = chant.bookPrayer else { return false }
                return SearchText.fold(prayer.title).contains(needle)
                    || SearchText.fold(prayer.latinTitle ?? "").contains(needle)
            }
            let found = ChantSearch.chants(singingPrayerMatching: needle)
            #expect(Set(found.map(\.id)) == Set(scanned.map(\.id)), "\(query)")
            #expect(found.count == scanned.count, "\(query): each once")
        }
    }

    @Test func everyMysteryFoundOpensItsDevotion() {
        for query in ["the", "jesus", "mary", "cross", "temple"] {
            for hit in AppSearch.mysteryHits(SearchText.needle(query)) {
                if case .mystery(let mystery) = hit {
                    #expect(mystery.mysteryCategory != nil, "\(mystery.name)")
                }
            }
        }
    }

    // MARK: - What VoiceOver hears

    @Test func aChantsLengthIsSaidAsItIsShown() {
        for chant in ChantCatalog.all {
            let parts = chant.durationLabel.split(separator: ":").compactMap { Int($0) }
            let seconds = parts[0] * 60 + parts[1]
            #expect(chant.spokenLength == ChantPlayer.spoken(Double(seconds)), "\(chant.id)")
        }
    }

    @Test func twoSettingsOfOneWorkAreToldApart() throws {
        let simple = try #require(ChantCatalog.chant("salve_regina_simple"))
        let solemn = try #require(ChantCatalog.chant("salve_regina_solemn"))
        #expect(simple.spokenName == solemn.spokenName)
        #expect(simple.spokenNameAndSetting != solemn.spokenNameAndSetting)
        #expect(simple.spokenNameAndSetting.hasSuffix("simple melody"))
        // A title that says its setting is not said twice
        let credo = try #require(ChantCatalog.chant("credo_iii"))
        #expect(credo.spokenNameAndSetting == credo.spokenName)
    }

    // MARK: - The pray-along's measures

    @Test func aPrayersMeasureIsWorkedOutOnceAndRight() throws {
        let measures = StanzaMeasures()
        let loreto = try #require(PrayerBook.prayer("litany_loreto"))
        let measure = measures.of(loreto, in: .english)
        let weights = PrayAlongView.spokenWeights(loreto.english)
        #expect(measure.weights == weights)
        #expect(measure.total == weights.reduce(0, +))
        #expect(measure.displayed == PrayAlongView.stanzas(loreto.content(for: .english)).count)
        // Asked again, the same answer
        #expect(measures.of(loreto, in: .english).weights == weights)
    }

    // MARK: - Small paintings

    @Test func aSmallPaintingIsMadeOffTheMainActorAndKept() async {
        let asset = PrayerBookPainting.topic(PrayerBook.ourLady).resolvedAsset
        let request = PaintingThumbnails.Request(name: asset, size: CGSize(width: 21, height: 29), scale: 3)
        await PaintingThumbnails.prepare(request)
        guard case .small(let small) = PaintingThumbnails.ready(request) else {
            Issue.record("the copy was not kept")
            return
        }
        #expect(small.size.width * small.scale < 1000)

        let missing = PaintingThumbnails.Request(
            name: "no_such_painting", size: CGSize(width: 21, height: 29), scale: 3)
        await PaintingThumbnails.prepare(missing)
        guard case .whole = PaintingThumbnails.ready(missing) else {
            Issue.record("a missing painting is drawn as it is")
            return
        }
    }
}
