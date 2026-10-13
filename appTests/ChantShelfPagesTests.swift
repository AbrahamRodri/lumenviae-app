//
//  ChantShelfPagesTests.swift
//  appTests
//
//  The pages SEE ALL opens: the contents of All Chants, a shelf, and how
//  a shelf lays out its rows.
//

import Testing

@testable import app

@MainActor
struct ChantShelfPagesTests {

    // MARK: - All Chants

    @Test func theTwelveCardsHangDifferentPaintings() {
        let paintings = ChantCatalog.groups.map { ChantBrowseScope.contentsPainting(for: $0) }
        #expect(paintings.count == 12)
        #expect(Set(paintings).count == paintings.count, "Two cards hang the same painting: \(paintings)")
        for name in paintings {
            #expect(ImageCacheService.shared.image(named: name) != nil, "No painting \(name)")
        }
    }

    @Test func everyChantIsBehindOneCard() {
        let behindCards = ChantCatalog.groups.flatMap { ChantBrowseScope.group($0.id).chants ?? [] }
        #expect(behindCards.map(\.id) == ChantCatalog.groups.flatMap { ChantCatalog.chants(in: $0) }.map(\.id))
        #expect(Set(behindCards.map(\.id)) == Set(ChantCatalog.all.map(\.id)))
    }

    @Test func aCardSaysItsCountInWords() {
        #expect(ChantBrowseScope.chantCount(1) == "1 chant")
        #expect(ChantBrowseScope.chantCount(8) == "8 chants")
    }

    @Test func longTitlesAreShortenedInPlainWords() {
        let titles = Dictionary(
            uniqueKeysWithValues: ChantCatalog.groups.map { ($0.id, ChantBrowseScope.cardTitle(of: $0)) })
        #expect(titles["ourLady"] == "Hymns to Our Lady")
        #expect(titles["benediction"] == "Adoration and Blessing")
        #expect(titles["mass"] == "The Ordinary of the Mass")
        #expect(ChantBrowseScope.group("benediction").title == "Adoration and Blessing")
    }

    // MARK: - A shelf

    @Test func aShelfOpensOnTheCardItWasOpenedFrom() {
        for group in ChantCatalog.groups {
            #expect(ChantBrowseScope.group(group.id).painting == ChantBrowseScope.contentsPainting(for: group))
            #expect(ChantBrowseScope.group(group.id).note == group.note)
        }
        #expect(ChantBrowseScope.songsToMary.painting == "glorious_coronation")
        #expect(ChantBrowseScope.massOfTheAngels.note == "The Mass of the Angels: for feasts, and any Sunday")
        #expect(ChantBrowseScope.songsToMary.note == nil)
    }

    @Test func aShelfOfOneListIsOnePartInItsOrder() {
        let parts = ChantBrowseScope.songsToMary.parts
        #expect(parts.count == 1)
        #expect(parts.first?.title == nil)
        #expect(parts.first?.chantIDs == ChantLibraryData.songsToMary)
        #expect(ChantBrowseScope.massOfTheAngels.parts.first?.chantIDs.count == 4)
        let seasons = ChantBrowseScope.group("seasons").parts
        #expect(seasons.compactMap(\.title).first == "Advent")
        #expect(ChantBrowseScope.all.parts.isEmpty)
    }

    @Test func rowsAreNumberedWhereEveryChantSharesOnePainting() {
        #expect(ChantBrowseScope.numbersItsChants(ChantBrowseScope.massOfTheAngels.chants ?? []))
        #expect(ChantBrowseScope.numbersItsChants(ChantBrowseScope.group("mass").chants ?? []))
        #expect(ChantBrowseScope.numbersItsChants(ChantBrowseScope.group("benediction").chants ?? []))
        #expect(!ChantBrowseScope.numbersItsChants(ChantBrowseScope.songsToMary.chants ?? []))
        #expect(!ChantBrowseScope.numbersItsChants(ChantBrowseScope.group("ourLady").chants ?? []))
        #expect(!ChantBrowseScope.numbersItsChants(ChantBrowseScope.group("hymns").chants ?? []))
        #expect(!ChantBrowseScope.numbersItsChants(ChantBrowseScope.group("seasons").chants ?? []))
    }

    @Test func rowsNameTheSettingOnlyWhereItTellsThemApart() {
        // Four times "Mass of the Angels" under a shelf of that name says nothing
        #expect(!ChantBrowseScope.rowsSaySetting(ChantBrowseScope.massOfTheAngels.chants ?? []))
        // The simple Salve Regina beside the solemn
        #expect(ChantBrowseScope.rowsSaySetting(ChantBrowseScope.songsToMary.chants ?? []))
    }
}
