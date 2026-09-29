//
//  PrayerBookTests.swift
//  Lumen Viae Tests
//
//  The Prayer Book: every chapter and order names prayers the book
//  carries, English and Latin pair line for line, the seasons choose the
//  right antiphon of Our Lady and the Regina Cæli in Eastertide, and the
//  voice asks for the Rosary's recordings where the Rosary has them.
//

import Foundation
import Testing
@testable import app

@MainActor
struct PrayerBookTests {

    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func everyChapterAndOrderNamesPrayersTheBookCarries() {
        for chapter in PrayerBook.chapters {
            for id in chapter.prayerIDs {
                #expect(PrayerBook.prayer(id) != nil, "chapter \(chapter.id) names \(id)")
            }
        }
        for order in PrayerBook.orders {
            for date in [day(2026, 4, 12), day(2026, 9, 24), day(2026, 12, 20)] {
                for id in order.prayerIDs(date) {
                    #expect(PrayerBook.prayer(id) != nil, "order \(order.id) names \(id)")
                }
            }
        }
    }

    @Test func englishAndLatinPairLineForLine() {
        for prayer in PrayerBook.prayers.values {
            guard let latin = prayer.latin else { continue }
            let english = prayer.english.components(separatedBy: "\n")
            let latinLines = latin.components(separatedBy: "\n")
            #expect(english.count == latinLines.count, "\(prayer.id) pairs \(english.count) with \(latinLines.count)")
        }
    }

    @Test func theAntiphonOfTheSeason() {
        // Easter 2026 is 5 April; Advent begins 29 November
        #expect(PrayerBook.antiphon(on: day(2026, 1, 15)) == .almaRedemptoris)
        #expect(PrayerBook.antiphon(on: day(2026, 2, 2)) == .aveReginaCaelorum)
        #expect(PrayerBook.antiphon(on: day(2026, 4, 4)) == .aveReginaCaelorum)
        #expect(PrayerBook.antiphon(on: day(2026, 4, 5)) == .reginaCaeli)
        #expect(PrayerBook.antiphon(on: day(2026, 5, 29)) == .reginaCaeli)
        #expect(PrayerBook.antiphon(on: day(2026, 9, 24)) == .salveRegina)
        #expect(PrayerBook.antiphon(on: day(2026, 11, 28)) == .almaRedemptoris)
    }

    @Test func theAngelusGivesWayToTheReginaCaeliInEastertide() {
        let angelus = PrayerBook.order(PrayerBook.angelusOrderID)!
        #expect(angelus.prayerIDs(day(2026, 4, 12)) == ["regina_caeli"])
        #expect(angelus.prayerIDs(day(2026, 9, 24)) == ["angelus"])
        #expect(angelus.title(on: day(2026, 4, 12)) == "The Regina Cæli")
    }

    @Test func theDayOrderFollowsTheClock() {
        func at(_ hour: Int) -> String {
            PrayerBook.dayOrder(at: calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: hour))!).id
        }
        #expect(at(7) == PrayerBook.morningOrderID)
        #expect(at(12) == PrayerBook.angelusOrderID)
        #expect(at(18) == PrayerBook.angelusOrderID)
        #expect(at(22) == PrayerBook.nightOrderID)
        #expect(at(2) == PrayerBook.nightOrderID)
    }

    @Test func theRosarysPrayersPlayTheRosarysRecordings() {
        #expect(PrayAlongVoice.clipID(for: "memorare") == .prayer("memorare"))
        #expect(PrayAlongVoice.clipID(for: "sub_tuum") == .book("sub_tuum"))
    }

    @Test func aLitanyIsSaidWithItsResponseAfterEveryInvocation() {
        let loreto = PrayerBook.prayer("litany_loreto")!
        let lines = PrayerWords.stanzas(of: loreto.english).flatMap { $0 }
        #expect(lines.contains("Holy Mother of God, pray for us."))
        #expect(!lines.contains { $0.contains("℟") })
    }
}
