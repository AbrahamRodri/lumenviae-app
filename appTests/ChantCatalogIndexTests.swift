//
//  ChantCatalogIndexTests.swift
//  Lumen Viae Tests
//
//  The catalog's lookups are built once (`ChantCatalogIndex`) where each
//  was a scan of every chant. Each is checked here against the scan it
//  replaced, for every chant, so the library answers exactly as before.
//  And the occasions, unrolled once a day, against unrolling them afresh.
//

import Foundation
import Testing
@testable import app

@MainActor
struct ChantCatalogIndexTests {

    private let all = ChantCatalog.all

    @Test func aChantIsFoundByItsIdAsTheScanFoundIt() {
        for chant in all {
            #expect(ChantCatalog.chant(chant.id) == all.first { $0.id == chant.id })
        }
        #expect(ChantCatalog.chant("no_such_chant") == nil)
    }

    @Test func aPrayersChantsAreTheScansInTheCatalogsOrder() {
        let prayers = Set(all.flatMap(\.prayerIDs))
        for prayer in prayers {
            #expect(ChantCatalog.chants(forPrayer: prayer) == all.filter { $0.prayerIDs.contains(prayer) }, "\(prayer)")
        }
        #expect(ChantCatalog.chants(forPrayer: "no_such_prayer").isEmpty)
    }

    @Test func aWorksSettingsAreTheScans() {
        for chant in all {
            let key = "\(chant.latinTitle)|\(chant.prayerIDs.sorted().joined(separator: ","))"
            #expect(chant.workKey == key)
            #expect(chant.settings == all.filter { "\($0.latinTitle)|\($0.prayerIDs.sorted().joined(separator: ","))" == key })
        }
    }

    @Test func theOtherSettingsAreTheScans() {
        for chant in all {
            let scanned = chant.prayerIDs.isEmpty ? [] : all.filter { other in
                other.id != chant.id && !Set(other.prayerIDs).isDisjoint(with: chant.prayerIDs)
            }
            #expect(ChantCatalog.otherSettings(of: chant) == scanned, "\(chant.id)")
        }
    }

    @Test func aChantsSeasonsAreTheScans() {
        for chant in all {
            let scanned = ChantSeason.allCases.filter { ChantLibraryData.seasonChants[$0]?.contains(chant.id) == true }
            #expect(chant.seasons == scanned, "\(chant.id)")
        }
    }

    @Test func eachKindAndLengthHoldsTheScansChants() {
        for form in ChantForm.allCases {
            #expect(form.chants == all.filter { $0.form == form })
        }
        for length in ChantLength.allCases {
            let scanned = all.filter { ChantLength.of($0.duration) == length }.sorted { $0.duration < $1.duration }
            #expect(length.chants == scanned)
        }
    }

    @Test func aChantsSectionIsFoundByItsId() {
        for chant in all {
            #expect(chant.group == ChantCatalog.groups.first { $0.id == chant.groupID })
        }
    }

    @Test func searchFindsWhatTheScanFound() {
        func scanned(_ query: String) -> [Chant] {
            let needle = SearchText.needle(query)
            guard !needle.isEmpty else { return [] }
            return all.filter { SearchText.fold($0.latinTitle).contains(needle) || SearchText.fold($0.englishTitle).contains(needle) }
        }
        for query in ["salve", "  Regina ", "caeli", "CÆLI", "ave", "queen", "o", "Te Deum", "zzz", "", "   "] {
            #expect(ChantCatalog.search(query) == scanned(query), "\(query)")
        }
        #expect(ChantCatalog.search("regina caeli").contains { $0.id == "regina_caeli_simple" })
        #expect(ChantCatalog.search("   ").isEmpty)
    }

    // MARK: - Search text

    @Test func foldingSetsCaseAccentsAndLigaturesAside() {
        #expect(SearchText.fold("Regína Cæli") == "regina caeli")
        #expect(SearchText.fold("CŒLI") == "coeli")
        #expect(SearchText.fold("Kýrie") == "kyrie")
        // Nothing is trimmed or dropped, so a match maps back to the words
        #expect(SearchText.fold(" Ave ") == " ave ")
        #expect(SearchText.needle("  Ave  ") == "ave")
    }

    @Test func aCleanLineIsItsWordsAlone() {
        #expect(SearchText.clean("℣. Ora pro nobis.") == "Ora pro nobis.")
        #expect(SearchText.clean("Magníficat * ánima mea") == "Magníficat ánima mea")
        #expect(SearchText.clean("[Let us pray.]") == "")
        #expect(SearchText.clean("✠ In nómine Patris") == "In nómine Patris")
    }

    // MARK: - Occasions

    @Test func anOccasionUnrolledOnceIsTheSameAsUnrolledAfresh() throws {
        let day = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        for occasion in ChantLibraryData.occasions {
            var chants: [Chant] = []
            for block in occasion.blocks {
                for _ in 0..<max(1, block.rounds) {
                    for step in block.steps {
                        guard let chant = step.chant.resolve(on: day) else { continue }
                        chants.append(contentsOf: Array(repeating: chant, count: max(1, step.times)))
                    }
                }
            }
            var seen = Set<String>()
            #expect(occasion.sequence(on: day) == chants, "\(occasion.id)")
            #expect(occasion.distinctChants(on: day) == chants.filter { seen.insert($0.id).inserted })
            #expect(occasion.duration(on: day) == chants.reduce(0) { $0 + $1.duration })
            // Asked again the same day, the same
            #expect(occasion.sequence(on: day.addingTimeInterval(3600)) == chants)
        }
    }

    @Test func anOccasionSingingTonightsSongFollowsTheDay() throws {
        let night = try #require(ChantLibraryData.occasions.first { occasion in
            occasion.blocks.contains { $0.steps.contains { $0.chant == .antiphonOfTheSeason } }
        })
        let calendar = Calendar.current
        let october = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        let december = try #require(calendar.date(from: DateComponents(year: 2026, month: 12, day: 10)))
        let inOctober = night.distinctChants(on: october).map(\.id)
        let inDecember = night.distinctChants(on: december).map(\.id)
        #expect(inOctober.contains(ChantCatalog.antiphonOfTheSeason(on: october)!.id))
        #expect(inDecember.contains(ChantCatalog.antiphonOfTheSeason(on: december)!.id))
        #expect(inOctober != inDecember)
    }
}
