//
//  ChapelLayoutAndKeepsakesTests.swift
//  Lumen Viae Tests
//
//  What the Chapel and the journal keep: the Chapel's layout read back
//  from its stored strings (an unknown tile dropped, a new tile seated
//  in its default place, nothing lost), the streak's milestones (the
//  Church's own numbers, led by the days), and a passage kept from a
//  book taken apart again into passage, citation and comment.
//

import Foundation
import Testing
@testable import app

@MainActor
struct ChapelLayoutTests {

    @Test func theDefaultLayoutRoundTrips() {
        let raw = ChapelPlacement.defaultLayout.map(\.encoded)
        #expect(ChapelPlacement.decode(raw) == ChapelPlacement.defaultLayout)
    }

    @Test func theDefaultLayoutHoldsEveryTileOnce() {
        let tiles = ChapelPlacement.defaultLayout.map(\.tile)
        #expect(Set(tiles) == Set(ChapelTile.allCases))
        #expect(tiles.count == ChapelTile.allCases.count)
        #expect(tiles.first == .rule)
        #expect(tiles[1] == .flame, "the streak stands directly under Today")
        #expect(tiles.last == .library, "the Library's colophon is the last line before the foot")
    }

    @Test func anEncodingIsTileSpanAndWhetherItIsOn() {
        #expect(ChapelPlacement(tile: .chant, span: 1, on: false).encoded == "chant:1:0")
        #expect(ChapelPlacement(tile: .rule, span: 2, on: true).encoded == "rule:2:1")
    }

    @Test func aStoredOrderAndWidthsAreKept() {
        var raw = ChapelPlacement.defaultLayout.map(\.encoded)
        raw.swapAt(0, 3)
        raw[1] = "flame:1:0"
        let layout = ChapelPlacement.decode(raw)
        #expect(layout.map(\.encoded) == raw)
    }

    @Test func anUnknownTileOrAMalformedEntryIsDropped() {
        let raw = ChapelPlacement.defaultLayout.map(\.encoded) + ["oratory:2:1", "garbage", "rule"]
        #expect(ChapelPlacement.decode(raw) == ChapelPlacement.defaultLayout)
    }

    @Test func aTileStoredTwiceKeepsItsFirstPlacement() {
        var raw = ChapelPlacement.defaultLayout.map(\.encoded)
        raw.insert("chant:1:0", at: 0)
        let layout = ChapelPlacement.decode(raw)
        #expect(layout.filter { $0.tile == .chant }.count == 1)
        #expect(layout.first == ChapelPlacement(tile: .chant, span: 1, on: false))
    }

    @Test func anOddSpanIsReadAsFullWidth() {
        let layout = ChapelPlacement.decode(["rule:5:1"])
        #expect(layout.first { $0.tile == .rule }?.span == 2)
    }

    @Test func aTileTheStoreLacksIsInsertedInItsDefaultPlace() {
        // A layout saved before the Prayers tile existed
        let raw = ChapelPlacement.defaultLayout.filter { $0.tile != .prayers }.map(\.encoded)
        let layout = ChapelPlacement.decode(raw)
        #expect(layout.map(\.tile) == ChapelPlacement.defaultLayout.map(\.tile))
        #expect(layout.contains(ChapelPlacement(tile: .prayers, span: 2, on: true)))
    }

    @Test func theLiturgyTileTakesTheLibrarysWidthAndPlace() {
        // Saved before Today in the Church was cut from the Library
        let raw = ["rule:2:1", "library:1:0", "flame:2:1"]
        let layout = ChapelPlacement.decode(raw)
        let liturgy = layout.first { $0.tile == .liturgy }
        #expect(liturgy?.span == 1)
        #expect(liturgy?.on == false, "on the page only if the Library is")
        let libraryIndex = layout.firstIndex { $0.tile == .library }!
        let liturgyIndex = layout.firstIndex { $0.tile == .liturgy }!
        #expect(liturgyIndex == libraryIndex - 1, "seated beside the Library, before it as by default")
    }

    @Test func nothingStoredGivesTheDefault() {
        #expect(ChapelPlacement.decode([]) == ChapelPlacement.defaultLayout)
    }

    @Test func everyTileHasItsWords() {
        for tile in ChapelTile.allCases {
            #expect(!tile.title.isEmpty)
            #expect(!tile.detail.isEmpty)
            #expect(!tile.shortTitle.isEmpty)
        }
        #expect(ChapelTile.liturgy.shortTitle == "The Church")
        #expect(ChapelTile.flame.shortTitle == "Streak")
    }
}

@MainActor
struct StreakMilestoneOrderTests {

    @Test func theMilestonesAreTheChurchsNumbersInOrder() {
        #expect(StreakMilestone.all.map(\.days) == [3, 7, 9, 33, 54, 100, 365])
    }

    @Test func aMilestoneIsReachedOnlyOnItsDay() {
        #expect(StreakMilestone.milestone(reachedAt: 9)?.days == 9)
        #expect(StreakMilestone.milestone(reachedAt: 10) == nil)
        #expect(StreakMilestone.milestone(reachedAt: 0) == nil)
    }

    @Test func theNextAndTheLatest() {
        #expect(StreakMilestone.next(after: 0)?.days == 3)
        #expect(StreakMilestone.next(after: 9)?.days == 33)
        #expect(StreakMilestone.next(after: 365) == nil)
        #expect(StreakMilestone.latest(achievedBy: 2) == nil)
        #expect(StreakMilestone.latest(achievedBy: 53)?.days == 33)
        #expect(StreakMilestone.latest(achievedBy: 400)?.days == 365)
    }

    @Test func progressRunsFromTheLastMilestoneToTheNext() {
        #expect(StreakMilestone.progressTowardNext(streak: 0) == 0)
        #expect(StreakMilestone.progressTowardNext(streak: 3) == 0)
        #expect(StreakMilestone.progressTowardNext(streak: 5) == 0.5)
        #expect(StreakMilestone.progressTowardNext(streak: 500) == 1)
        for streak in 0...400 {
            let progress = StreakMilestone.progressTowardNext(streak: streak)
            #expect((0...1).contains(progress))
        }
    }

    @Test func aMilestoneIsLedByItsDays() {
        let novena = StreakMilestone.milestone(reachedAt: 9)!
        #expect(novena.name == "9 days")
        #expect(novena.title == "9 days · a novena")
        let consecration = StreakMilestone.milestone(reachedAt: 33)!
        #expect(consecration.title == "33 days", "no meaning, no dangling separator")
    }

    @Test func noMilestoneWearsAPrizeMedal() {
        for milestone in StreakMilestone.all {
            #expect(!milestone.icon.contains("medal"))
            #expect(!milestone.icon.contains("trophy"))
            #expect(!milestone.blessing.lowercased().contains("lose"))
        }
    }
}

@MainActor
struct KeptPassageTests {

    private let citation = "— St. Louis de Montfort, True Devotion to Mary, Chapter I (trans. F. W. Faber). Public domain."

    @Test func aNoteComesApartIntoItsThreeParts() throws {
        let entry = JournalEntry.note(
            passage: "To Jesus through Mary.",
            citation: citation,
            comment: "  Said this all day.  ",
            subject: "True Devotion",
            bookID: "true-devotion"
        )
        let kept = try #require(entry.keptPassage)
        #expect(kept.passage == "To Jesus through Mary.")
        #expect(kept.citation == "St. Louis de Montfort, True Devotion to Mary, Chapter I (trans. F. W. Faber).")
        #expect(kept.comment == "Said this all day.")
        #expect(entry.bookID == "true-devotion")
    }

    @Test func aNoteWithNoCommentOrCitation() throws {
        let entry = JournalEntry.note(passage: "Take up and read.", citation: "", subject: "Confessions", bookID: "confessions")
        #expect(entry.bookCitation == nil)
        let kept = try #require(entry.keptPassage)
        #expect(kept.citation == nil)
        #expect(kept.comment.isEmpty)
    }

    @Test func aPassageKeptWithTrailingWhitespaceStillMatches() throws {
        let entry = JournalEntry.note(passage: "Love is repaid by love alone.\n", citation: citation, subject: "Story of a Soul", bookID: "story")
        let kept = try #require(entry.keptPassage)
        #expect(kept.passage == "Love is repaid by love alone.")
    }

    @Test func aRewrittenPassageIsShownAsTheReaderLeftIt() {
        let entry = JournalEntry.note(passage: "To Jesus through Mary.", citation: citation, subject: "True Devotion", bookID: "td")
        entry.text = "My own words now."
        #expect(entry.keptPassage == nil)
    }

    @Test func anEditedCitationStaysInTheReadersWords() throws {
        let entry = JournalEntry.note(passage: "To Jesus through Mary.", citation: citation, comment: "Mine.", subject: "True Devotion", bookID: "td")
        entry.text = "\u{201C}To Jesus through Mary.\u{201D}\n\nMontfort, somewhere\n\nMine."
        let kept = try #require(entry.keptPassage)
        #expect(kept.citation == nil)
        #expect(kept.comment.contains("Montfort, somewhere"))
    }

    @Test func anOrdinaryEntryIsNoKeptPassage() {
        #expect(JournalEntry(text: "\u{201C}A saying\u{201D}").keptPassage == nil)
    }
}
