//
//  ChantSavedTests.swift
//  appTests
//
//  Your Chants' rules: which shelf it opens on, which painting hangs at
//  its head, what the recent plays are called, and what a set's cover
//  says and is heard as.
//

import Foundation
import Testing

@testable import app

@Suite("Your Chants")
struct ChantSavedTests {

    @Test func opensOnTheShelfTheTileNamed() {
        #expect(ChantSavedShelf.shown(choice: .learned, favorites: 5, learned: 0) == .learned)
        #expect(ChantSavedShelf.shown(choice: .favorites, favorites: 0, learned: 3) == .favorites)
    }

    @Test func withNoShelfNamedFavouritesLeadUnlessEmpty() {
        #expect(ChantSavedShelf.shown(choice: nil, favorites: 2, learned: 3) == .favorites)
        #expect(ChantSavedShelf.shown(choice: nil, favorites: 0, learned: 3) == .learned)
        #expect(ChantSavedShelf.shown(choice: nil, favorites: 0, learned: 0) == .favorites)
    }

    @Test func paintingIsTheFirstChantsElseTheShelfsOwn() throws {
        let salve = try #require(ChantCatalog.chant("salve_regina_simple"))
        let veni = try #require(ChantCatalog.chant("veni_creator"))
        #expect(ChantSavedShelf.favorites.painting(of: [veni, salve]) == ChantCatalog.painting(for: veni))
        #expect(ChantSavedShelf.favorites.painting(of: []) == ChantSavedShelf.favorites.emptyPainting)
        #expect(ChantSavedShelf.learned.painting(of: []) == ChantSavedShelf.learned.emptyPainting)
    }

    @Test func anEmptyShelfIsNotToldItHasNone() {
        #expect(ChantSavedShelf.spokenCount(0) == nil)
        #expect(ChantSavedShelf.spokenCount(1) == "1 chant")
        #expect(ChantSavedShelf.spokenCount(5) == "5 chants")
    }

    @Test func recentPlaysAreNamedByWhen() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        func at(_ day: Int, _ hour: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
        }
        let now = at(12, 21)
        #expect(ChantSavedSection.when(at(12, 8), now: now, calendar: calendar) == "This morning")
        #expect(ChantSavedSection.when(at(12, 14), now: now, calendar: calendar) == "This afternoon")
        #expect(ChantSavedSection.when(at(12, 20), now: now, calendar: calendar) == "Tonight")
        #expect(ChantSavedSection.when(at(11, 20), now: now, calendar: calendar) == "Yesterday")
        #expect(ChantSavedSection.when(at(9, 20), now: now, calendar: calendar)
            == at(9, 20).formatted(.dateTime.weekday(.wide)))
    }

    @Test func aSetsCoverSaysItsChantsAndMinutes() throws {
        let defaults = try #require(UserDefaults(suiteName: "ChantSavedTests.\(UUID().uuidString)"))
        let shelf = ChantShelfStore(defaults: defaults)
        let empty = shelf.newSet(named: "Lauds")
        #expect(ChantSavedSetCover.summary(of: empty) == "No chants yet")
        #expect(ChantSavedSetCover.spoken(empty) == "Lauds, no chants yet")

        let hour = shelf.newSet(named: "Thursday holy hour", with: "o_salutaris")
        shelf.addChant("adoro_te", to: hour.id)
        shelf.addPause(note: "Silent prayer", seconds: 600, to: hour.id)
        shelf.addChant("tantum_ergo", to: hour.id)
        shelf.addChant("divine_praises", to: hour.id)
        let kept = try #require(shelf.set(hour.id))
        let minutes = Int((kept.duration / 60).rounded())
        #expect(ChantSavedSetCover.summary(of: kept) == "4 chants · \(minutes) min")
        #expect(ChantSavedSetCover.spoken(kept) == "Thursday holy hour, 4 chants, \(minutes) minutes")
    }
}
