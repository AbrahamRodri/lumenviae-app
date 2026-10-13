//
//  ChantSetPageTests.swift
//  Lumen Viae Tests
//
//  A sung set's page: what its ··· holds for an occasion and for a set of
//  the reader's own, which acts a hold on a row offers (never a move past
//  either end, nothing on an occasion's notes), how its chants are
//  numbered, and what VoiceOver hears of a pause.
//

import Foundation
import Testing
@testable import app

@MainActor
struct ChantSetPageTests {

    typealias Page = ChantSetPage

    // MARK: - The ···

    @Test func anOccasionsMenuHoldsOnlyThePauseBetweenChants() {
        // Saving it is the bookmark's, beside the ···, never the menu's too
        #expect(Page.MoreItem.groups(own: false, hasItems: true) == [[.pausesBetween]])
    }

    @Test func aSetOfOnesOwnSharesRenamesPausesAndDeletes() {
        #expect(
            Page.MoreItem.groups(own: true, hasItems: true)
                == [[.share, .rename], [.pausesBetween], [.delete]])
    }

    @Test func anEmptySetHasNothingToShare() {
        #expect(
            Page.MoreItem.groups(own: true, hasItems: false)
                == [[.rename], [.pausesBetween], [.delete]])
    }

    // MARK: - A row's acts

    private var ownSet: ChantSet {
        ChantSet(name: "Test", items: [
            ChantSet.Item(kind: .chant(id: "ave_maria", times: 3)),
            ChantSet.Item(kind: .pause(note: "Silent prayer", seconds: 600)),
            ChantSet.Item(kind: .chant(id: "gloria_patri", times: 1))
        ])
    }

    @Test func theFirstRowCannotMoveUpNorTheLastDown() {
        let rows = Page.content(of: ownSet).rows
        #expect(Page.rowActions(for: rows[0], own: true, position: 0, count: 3) == [.playFromHere, .moveDown, .remove])
        #expect(Page.rowActions(for: rows[1], own: true, position: 1, count: 3) == [.moveUp, .moveDown, .remove])
        #expect(Page.rowActions(for: rows[2], own: true, position: 2, count: 3) == [.playFromHere, .moveUp, .remove])
    }

    @Test func aRowAloneCanOnlyBeRemoved() {
        let set = ChantSet(name: "One", items: [ChantSet.Item(kind: .pause(note: "Kneel.", seconds: 0))])
        let row = Page.content(of: set).rows[0]
        #expect(Page.rowActions(for: row, own: true, position: 0, count: 1) == [.remove])
    }

    @Test func anOccasionsChantsAreSungFromAndItsNotesHaveNoActs() throws {
        let rosary = try #require(ChantOccasion.occasion("sung_rosary"))
        let rows = Page.content(of: rosary).rows
        let note = try #require(rows.first)
        let chant = try #require(rows.dropFirst().first)
        #expect(Page.rowActions(for: note, own: false, position: 0, count: rows.count).isEmpty)
        #expect(Page.rowActions(for: chant, own: false, position: 1, count: rows.count) == [.playFromHere])
    }

    // MARK: - Numbers and words

    @Test func anOccasionsChantsAreNumberedAmongThemselves() throws {
        let rosary = try #require(ChantOccasion.occasion("sung_rosary"))
        let rows = Page.content(of: rosary).rows
        let numbers = Page.chantNumbers(of: rows)
        let chants = rows.filter { if case .chant = $0.kind { return true } else { return false } }
        #expect(chants.map { numbers[$0.id] } == Array(1...chants.count).map { Optional($0) })
        // Notes take no number
        #expect(numbers[rows[0].id] == nil)
    }

    @Test func aPauseIsHeardWithItsSilence() {
        #expect(Page.spokenPause("Silent prayer", seconds: 300) == "Silent prayer, 5 minutes of silence")
        #expect(Page.spokenPause("Kneel.", seconds: 0) == "Kneel., a note")
        #expect(Page.spokenPause("Kneel.", seconds: nil) == "Kneel.")
    }
}
