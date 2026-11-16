//
//  ConsecrationChooserTests.swift
//  appTests
//
//  The consecration feast chooser's words: a moved feast says why under
//  its name, and the dates on its rows, its sentence and its act carry
//  no year (Abraham's pick, option A with the one-sentence panel).
//

import Foundation
import Testing
@testable import app

@Suite("Consecration chooser")
struct ConsecrationChooserTests {

    private func preparation(_ id: String, feastYear year: Int) throws -> FeastPreparation {
        let feast = try #require(MarianFeastDay.find(id))
        let feastDate = try #require(feast.date(for: year))
        let start = try #require(Calendar.current.date(byAdding: .day, value: -33, to: feastDate))
        return FeastPreparation(feast: feast, start: start, feastDate: feastDate)
    }

    @Test func aMovedAnnunciationSaysWhy() throws {
        // 25 March 2027 is Holy Thursday: kept on Monday 5 April
        #expect(
            ConsecrationDateSelectionView.movedNote(try preparation("annunciation", feastYear: 2027))
                == "Moved from March 25, which is Holy Thursday in 2027")
        // 2029: Palm Sunday; 2035: Easter Sunday; 2046: a Sunday of Lent
        #expect(
            ConsecrationDateSelectionView.movedNote(try preparation("annunciation", feastYear: 2029))
                == "Moved from March 25, which is Palm Sunday in 2029")
        #expect(
            ConsecrationDateSelectionView.movedNote(try preparation("annunciation", feastYear: 2035))
                == "Moved from March 25, which is Easter Sunday in 2035")
        #expect(
            ConsecrationDateSelectionView.movedNote(try preparation("annunciation", feastYear: 2046))
                == "Moved from March 25, which is a Sunday of Lent in 2046")
    }

    @Test func aFeastOnItsOwnDaySaysNothing() throws {
        #expect(ConsecrationDateSelectionView.movedNote(try preparation("annunciation", feastYear: 2028)) == nil)
        #expect(ConsecrationDateSelectionView.movedNote(try preparation("lourdes", feastYear: 2027)) == nil)
        #expect(ConsecrationDateSelectionView.movedNote(try preparation("assumption", feastYear: 2027)) == nil)
    }

    @Test func datesCarryNoYear() throws {
        let lourdes = try preparation("lourdes", feastYear: 2027)
        #expect(ConsecrationDateSelectionView.rowDate(lourdes.feastDate) == "Thu, Feb 11")
        #expect(ConsecrationDateSelectionView.spanDate(lourdes.start) == "Saturday, January 9")
        #expect(ConsecrationDateSelectionView.spanDate(lourdes.feastDate) == "Thursday, February 11")
        #expect(ConsecrationDateSelectionView.beginTitle(lourdes, days: 54) == "Begin on January 9")
        #expect(ConsecrationDateSelectionView.beginTitle(lourdes, days: 0) == "Begin today")
    }

    @Test func aRowIsOneSentenceToVoiceOver() throws {
        let annunciation = try preparation("annunciation", feastYear: 2027)
        let moved = ConsecrationDateSelectionView.movedNote(annunciation)
        #expect(
            ConsecrationDateSelectionView.rowLabel(annunciation, isSoonest: false, moved: moved)
                == "The Annunciation, Monday, April 5. Moved from March 25, which is Holy Thursday in 2027.")
    }
}
