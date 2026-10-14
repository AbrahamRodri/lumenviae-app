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
        let paintings = ChantCatalog.groups.map(\.painting)
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
        #expect(titles["benediction"] == "Benediction")
        #expect(titles["mass"] == "The Ordinary of the Mass")
        #expect(ChantBrowseScope.group("benediction").title == "Benediction")
        // The sung set keeps that name, so the library never says it twice
        #expect(!titles.values.contains("Adoration and Blessing"))
    }

    // MARK: - A shelf

    @Test func aShelfOpensOnTheCardItWasOpenedFrom() {
        for group in ChantCatalog.groups {
            #expect(ChantBrowseScope.group(group.id).painting == group.painting)
            #expect(ChantBrowseScope.group(group.id).note == group.note)
        }
        #expect(ChantBrowseScope.songsToMary.painting == "glorious_coronation")
        // The shelf's note says when, not the shelf's name again
        #expect(ChantBrowseScope.massOfTheAngels.note == "For feasts, and any Sunday")
        // The Ordinary's part keeps its own
        #expect(ChantBrowseScope.group("mass").parts.first?.note == "The Mass of the Angels: for feasts, and any Sunday")
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

    @Test func rowsNameTheSettingOnlyWhereNoHeadingDoes() {
        let mass = ChantBrowseScope.massOfTheAngels
        // Four times "Mass of the Angels" under a shelf of that name says nothing
        for chant in mass.chants ?? [] {
            #expect(!ChantBrowseScope.rowSaysSetting(of: chant, under: [mass.title, nil, nil]))
        }
        // Under the Ordinary, each Mass's heading names its setting
        let ordinary = ChantBrowseScope.group("mass")
        for part in ordinary.parts {
            for chant in ChantCatalog.chants(in: part) {
                #expect(!ChantBrowseScope.rowSaysSetting(of: chant, under: [ordinary.title, part.title, part.note]))
            }
        }
        // The simple Salve Regina beside the solemn
        let salve = ChantCatalog.chant("salve_regina_simple")!
        #expect(ChantBrowseScope.rowSaysSetting(of: salve, under: ["Songs to Mary", nil, nil]))
        // No heading of the Sequences says "feast poem"
        let sequences = ChantBrowseScope.group("sequences")
        let poem = (sequences.chants ?? []).first { $0.settingMidLine != nil }
        #expect(poem != nil)
        if let poem {
            #expect(ChantBrowseScope.rowSaysSetting(of: poem, under: [sequences.title, nil, nil]))
        }
    }
}
