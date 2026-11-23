//
//  ConsecrationChooserTests.swift
//  appTests
//
//  The consecration feast chooser's words: the dates on its rows, its
//  foot and its act carry no year, and a moved feast is read by the day
//  it is kept, with nothing said of its own day (Abraham's pick, option
//  A, as revised on 16 Nov 2026).
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

    @Test func datesCarryNoYear() throws {
        let lourdes = try preparation("lourdes", feastYear: 2027)
        #expect(ConsecrationDateSelectionView.rowDate(lourdes.feastDate) == "Thu, Feb 11")
        #expect(ConsecrationDateSelectionView.footDate(lourdes.start) == "Saturday, January 9")
        #expect(ConsecrationDateSelectionView.footDate(lourdes.feastDate) == "Thursday, February 11")
        #expect(ConsecrationDateSelectionView.beginTitle(lourdes, days: 54) == "Begin on January 9")
        #expect(ConsecrationDateSelectionView.beginTitle(lourdes, days: 0) == "Begin today")
    }

    @Test func aMovedFeastIsReadByTheDayItIsKept() throws {
        // 25 March 2027 is Holy Thursday: kept on Monday 5 April, and the
        // row says only that ("the moved from march 25 is also clutter")
        let annunciation = try preparation("annunciation", feastYear: 2027)
        #expect(ConsecrationDateSelectionView.rowDate(annunciation.feastDate) == "Mon, Apr 5")
        #expect(
            ConsecrationDateSelectionView.rowLabel(annunciation, isSoonest: false)
                == "The Annunciation, Monday, April 5.")
        #expect(
            ConsecrationDateSelectionView.rowLabel(try preparation("lourdes", feastYear: 2027), isSoonest: true)
                == "Our Lady of Lourdes, Thursday, February 11, the soonest.")
    }
}
