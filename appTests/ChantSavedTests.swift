//
//  ChantSavedTests.swift
//  appTests
//
//  Your Chants' rules: which shelf it opens on, which painting hangs at
//  its head, what the recent plays are called, and what a set's cover
//  says and is heard as.
//

import Foundation
import SwiftUI
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
        // Learned's own painting is the Coronation; the first chant's leads
        #expect(ChantSavedShelf.learned.painting(of: [veni, salve]) == "glorious_pentecost")
        #expect(ChantSavedShelf.favorites.painting(of: []) == ChantSavedShelf.favorites.emptyPainting)
        #expect(ChantSavedShelf.learned.painting(of: []) == ChantSavedShelf.learned.emptyPainting)
    }

    /// An empty shelf's arch never repeats the painting at the page's head
    @Test func anEmptyShelfHangsTwoPaintings() {
        for shelf in [ChantSavedShelf.favorites, .learned] {
            #expect(shelf.emptyArchPainting != shelf.painting(of: []))
        }
    }

    @Test func anEmptyShelfIsNotToldItHasNone() {
        #expect(ChantSavedShelf.spokenCount(0) == nil)
        #expect(ChantSavedShelf.spokenCount(1) == "1 chant")
        #expect(ChantSavedShelf.spokenCount(5) == "5 chants")
    }

    @Test func recentPlaysAreNamedByWhen() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let locale = Locale(identifier: "en_US")
        func at(_ month: Int, _ day: Int, _ hour: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
        }
        func when(_ date: Date) -> String {
            ChantSavedSection.when(date, now: at(10, 12, 21), calendar: calendar, locale: locale)
        }
        // A Monday evening: the day's three parts turn at noon and 6 pm
        #expect(when(at(10, 12, 11)) == "This morning")
        #expect(when(at(10, 12, 12)) == "This afternoon")
        #expect(when(at(10, 12, 17)) == "This afternoon")
        #expect(when(at(10, 12, 18)) == "Tonight")
        #expect(when(at(10, 11, 20)) == "Yesterday")
        #expect(when(at(10, 9, 20)) == "Friday")
        #expect(when(at(10, 6, 9)) == "Tuesday")
        // A play dated after now, the clock turned back, takes its date
        #expect(when(at(10, 14, 9)) == "Oct 14")
        // A week or more ago, the date
        #expect(when(at(10, 5, 9)) == "Oct 5")
        #expect(when(at(9, 22, 9)) == "Sep 22")
    }

    @Test func aSetsCoverSaysItsChantsAndMinutes() throws {
        let suite = "ChantSavedTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let shelf = ChantShelfStore(defaults: defaults)
        let empty = shelf.newSet(named: "Lauds")
        #expect(ChantSavedSetCover.summary(of: empty) == "No chants yet")
        #expect(ChantSavedSetCover.spoken(empty) == "Lauds, no chants yet")

        // 66 + 264 + 600 of silence + 137.4 + 127.1 seconds
        let hour = shelf.newSet(named: "Thursday holy hour", with: "o_salutaris")
        shelf.addChant("adoro_te", to: hour.id)
        shelf.addPause(note: "Silent prayer", seconds: 600, to: hour.id)
        shelf.addChant("tantum_ergo", to: hour.id)
        shelf.addChant("divine_praises", to: hour.id)
        let kept = try #require(shelf.set(hour.id))
        #expect(ChantSavedSetCover.summary(of: kept) == "4 chants · 20 min")
        #expect(ChantSavedSetCover.spoken(kept) == "Thursday holy hour, 4 chants, 20 minutes")

        // The Pater Noster's 56 seconds
        let one = shelf.newSet(named: "Grace", with: "pater_noster")
        let grace = try #require(shelf.set(one.id))
        #expect(ChantSavedSetCover.summary(of: grace) == "1 chant · 1 min")
        #expect(ChantSavedSetCover.spoken(grace) == "Grace, 1 chant, 1 minute")
    }

    /// The page keeps room for the player only while one stands there and
    /// the app has not kept it already, on a phone with a home indicator
    /// or a Home button
    @Test func roomForThePlayerIsNeverKeptTwice() {
        let room = ChantSavedPage.playerRoomHeight
        #expect(ChantSavedPage.playerRoom(playerActive: false, bottomInset: 34) == 0)
        #expect(ChantSavedPage.playerRoom(playerActive: true, bottomInset: 34) == room)
        #expect(ChantSavedPage.playerRoom(playerActive: true, bottomInset: 0) == room)
        // The app's room (the player's height and 8) has arrived
        #expect(ChantSavedPage.playerRoom(playerActive: true, bottomInset: 34 + 70) == 0)
        #expect(ChantSavedPage.playerRoom(playerActive: true, bottomInset: 70) == 0)
    }

    /// Under Reduce Motion a count changes without rolling its digits;
    /// the page's crossfades stay, since a fade is not travel
    @Test func underReduceMotionACountDoesNotRoll() {
        #expect(ChantShelfSwitch.countTransition(reduceMotion: true) == .identity)
        #expect(ChantShelfSwitch.countTransition(reduceMotion: false) == .numericText())
    }
}
