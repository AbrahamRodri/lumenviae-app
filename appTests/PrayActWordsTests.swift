//
//  PrayActWordsTests.swift
//  Lumen Viae Tests
//
//  What the Pray tray and the Chapel's rule say of each act: one title
//  each, a line under it in plain words, the tray's detail naming the
//  day's mysteries and how they will sound, each of the Prayer Book's
//  three orders tied to the order it marks prayed, and the
//  consecration's period named by its day on the same days the
//  preparation keeps. Held to the plain-language rulings: PRAYED, never
//  OFFERED; no bare "1962"; the forms named as everywhere else.
//

import Foundation
import Testing
@testable import app

@MainActor
struct PrayActWordsTests {

    @Test func everyActHasItsOwnTitleAndLine() {
        let titles = PrayerShortcut.allCases.map(\.title)
        #expect(Set(titles).count == titles.count)
        for act in PrayerShortcut.allCases {
            #expect(!act.subtitle.isEmpty && !act.actName.isEmpty, "\(act)")
        }
    }

    @Test func theFormsAreNamedAsEverywhereElse() {
        #expect(PrayerShortcut.rosaryAloud.title == "The Rosary Said Aloud")
        #expect(PrayerShortcut.scripturalRosary.title == "The Scriptural Rosary")
        #expect(PrayerShortcut.sevenSorrows.title == "The Seven Sorrows of Mary")
        #expect(PrayerShortcut.consecration.title == "Consecration to Mary")
        #expect(PrayerShortcut.mass.title == "The Mass")
        #expect(PrayerShortcut.office.title == "Hours of Prayer")
        #expect(PrayerShortcut.chooseMeditation.title == "Today's Mysteries")
    }

    @Test func theWordsKeepThePlainLanguageRulings() {
        for act in PrayerShortcut.allCases {
            let words = [act.title, act.subtitle, act.actName,
                         act.trayDetail(today: .joyful, praysAloud: false),
                         act.trayDetail(today: .joyful, praysAloud: true)]
            for line in words {
                #expect(!line.uppercased().contains("OFFERED"), "\(act): \(line)")
                #expect(!line.contains("1962"), "\(act): \(line)")
                #expect(!line.contains("Holy Rosary") && !line.contains("Rosary Aloud"), "the form is the Rosary Said Aloud")
            }
        }
    }

    @Test func theTraysDetailNamesTheDaysMysteriesAndHowTheySound() {
        #expect(PrayerShortcut.todaysRosary.trayDetail(today: .glorious, praysAloud: false) == "Glorious Mysteries · meditation aloud")
        #expect(PrayerShortcut.todaysRosary.trayDetail(today: .glorious, praysAloud: true) == "Glorious Mysteries · whole Rosary aloud")
        #expect(PrayerShortcut.scripturalRosary.trayDetail(today: .joyful, praysAloud: false) == "Joyful Mysteries · a verse for every bead")
        #expect(PrayerShortcut.rosaryAloud.trayDetail(today: .sevenSorrows, praysAloud: false) == "Seven Sorrows of Mary · every prayer aloud")
        #expect(PrayerShortcut.mass.trayDetail(today: .joyful, praysAloud: true) == PrayerShortcut.mass.subtitle)
    }

    @Test func thePrayerBooksOrdersMarkTheirOwnOrderPrayed() {
        let orders: [PrayerShortcut] = [.morningPrayers, .angelus, .nightPrayers]
        for act in orders {
            let id = act.prayerOrderID
            #expect(id != nil, "\(act)")
            #expect(id.flatMap(PrayerBook.order) != nil, "\(act) marks an order the book does not hold")
        }
        for act in PrayerShortcut.allCases where !orders.contains(act) {
            #expect(act.prayerOrderID == nil, "\(act)")
        }
    }

    @Test func everyRuleActIsOneTheChapelCanWatch() {
        // Each eligible act is either a Rosary recorded in the history or
        // an order the Prayer Book marks prayed at its Amen
        let rosaries: Set<PrayerShortcut> = [.todaysRosary, .scripturalRosary, .rosaryAloud, .sevenSorrows]
        for act in PrayerShortcut.allCases where act.isRuleEligible {
            #expect(rosaries.contains(act) || act.prayerOrderID != nil, "\(act) is on the rule with nothing to ask")
        }
    }

    @Test func theAngelusIsQueenOfHeavenInEastertide() {
        #expect(PrayerShortcut.angelusTitle == PrayerBook.order(PrayerBook.angelusOrderID)?.title(on: Date()))
    }

    @Test func theConsecrationsPeriodIsNamedOnItsOwnDays() {
        let names: [ConsecrationPhase: String] = [
            .preparatory: "Renouncing the world",
            .knowledgeOfSelf: "Knowing yourself",
            .knowledgeOfMary: "Knowing Mary",
            .knowledgeOfJesus: "Knowing Christ",
            .consecrationDay: "Consecration Day"
        ]
        for day in 1...34 {
            let phase = ConsecrationPhase.phase(for: day)!
            #expect(ChapelConsecrationTile.phaseName(day: day) == names[phase], "day \(day)")
        }
    }
}
