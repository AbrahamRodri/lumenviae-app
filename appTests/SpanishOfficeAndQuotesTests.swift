//
//  SpanishOfficeAndQuotesTests.swift
//  appTests
//
//  The Hours of Prayer and the saints' quotations in a Spanish app: the
//  Office asked for in Divinum Officium's Spanish and kept apart on disk,
//  its English headings named in Spanish, and the daily line drawn from
//  the quotations that have their Spanish.
//

import Foundation
import Testing

@testable import app

struct SpanishOfficeTests {

    @Test func theOfficeIsAskedForInTheAppsLanguage() {
        #expect(OfficeAPIService.language(spanish: false) == "english")
        #expect(OfficeAPIService.language(spanish: true) == "espanol")
    }

    /// English pages keep the names they were saved under; Spanish ones
    /// are kept beside them, never read for the other language
    @Test func eachLanguageHasItsOwnCacheNames() {
        #expect(OfficeAPIService.edition(spanish: false) == OfficeAPIService.version)
        #expect(OfficeAPIService.edition(spanish: true) == "rubrics-1960-espanol")
        #expect(Set(OfficeAPIService.editions).count == 2)
        // No English name's prefix begins a Spanish one
        #expect(!"hour_rubrics-1960-espanol_2026-11-04_laudes.json".hasPrefix("hour_rubrics-1960_"))
    }

    @Test func englishHeadingsInTheSpanishOfficeAreNamedInSpanish() {
        let sections = [
            OfficeSection(
                latin: OfficeCell(title: "Martyrologium", note: nil, lines: ["…"]),
                vernacular: OfficeCell(title: "Martyrology", note: nil, lines: ["…"])),
            OfficeSection(
                latin: OfficeCell(title: "Psalmi", note: nil, lines: ["…"]),
                vernacular: OfficeCell(title: "Salmos", note: nil, lines: ["…"])),
        ]
        let spanish = OfficeReaderSection.build(from: sections, language: "espanol")
        #expect(spanish.map(\.englishName) == ["Martirologio", "Salmos"])
        // The English Office keeps its own word
        #expect(OfficeReaderSection.build(from: sections).first?.englishName == "Martyrology")
    }

    /// The Missal names the feast in English only, so a Spanish app
    /// takes the breviary's own (Latin) title, and none until it comes
    @Test func theSpanishOfficeNeverNamesTheFeastInEnglish() {
        let missal = "St. Charles Borromeo"
        let breviary = "S. Caroli Episcopi et Confessoris"
        #expect(OfficeViewModel.feastTitle(missal: missal, breviary: breviary, spanish: true) == breviary)
        #expect(OfficeViewModel.feastTitle(missal: missal, breviary: breviary, spanish: false) == missal)
        #expect(OfficeViewModel.feastTitle(missal: nil, breviary: breviary, spanish: false) == breviary)
        #expect(OfficeViewModel.feastTitle(missal: missal, breviary: nil, spanish: true) == nil)
    }

    /// A weekday or a Sunday never shows the breviary's long Latin
    /// day-title in a Spanish app
    @Test func aSpanishWeekdayIsFeriaAndASundayDomingo() {
        let feria = "Feria Quinta infra Hebd XXIII post Octavam Pentecostes I. Novembris"
        let sunday = "Dominica V Post Epiphaniam III. Novembris"
        #expect(OfficeViewModel.feastTitle(missal: nil, breviary: feria, spanish: true) == "Feria")
        #expect(OfficeViewModel.feastTitle(missal: "Thursday of the 23rd Week after Pentecost", breviary: feria, spanish: true) == "Feria")
        #expect(OfficeViewModel.feastTitle(missal: nil, breviary: sunday, spanish: true)?.lowercased() == "sunday")
        #expect(OfficeViewModel.feastTitle(missal: "5th Sunday after Epiphany", breviary: sunday, spanish: true)?.lowercased() == "sunday")
        // English keeps the Missal's own title
        #expect(OfficeViewModel.feastTitle(missal: "5th Sunday after Epiphany", breviary: sunday, spanish: false) == "5th Sunday after Epiphany")
    }

    /// Holy Thursday and Good Friday are "Feria …" in the breviary, but
    /// first-class days, never weekdays
    @Test func theTriduumIsNoWeekdayInLatin() {
        let holyThursday = "Feria Quinta in Cena Domini"
        #expect(!DayRank.isWeekday(holyThursday))
        #expect(!DayRank.isWeekday("Feria Sexta in Parasceve"))
        #expect(DayRank.isWeekday("Feria Quinta infra Hebd XXIII post Octavam Pentecostes I. Novembris"))
        #expect(DayRank.plainLabel(rank: 1, title: holyThursday) == DayRank.plainLabel(rank: 1, title: "Easter Sunday"))
        #expect(OfficeViewModel.feastTitle(missal: nil, breviary: holyThursday, spanish: true) == holyThursday)
    }
}

struct SpanishQuotesTests {

    @Test func aSpanishAppDrawsOnlySpanishLines() {
        let spanish = RosaryQuotes.catalog(spanish: true)
        #expect(spanish.count == 17)
        let english = Set(RosaryQuotes.all.map(\.text))
        #expect(spanish.allSatisfy { !english.contains($0.text) })
        #expect(spanish.allSatisfy { $0.spanish == nil })
    }

    @Test func theSaintsAreNamedInSpanish() {
        let pius = RosaryQuotes.all.first { $0.author == "St. Pius X" }?.shown(spanish: true)
        #expect(pius?.author == "San Pío X")
        #expect(pius?.aiTranslated == true)
    }

    /// Sixteen of the seventeen are the team's translation; the one
    /// with a published Spanish (St. Padre Pio's) carries no line
    @Test func theAILineFollowsTheApi() {
        let lines = RosaryQuotes.catalog(spanish: true)
        #expect(lines.filter(\.aiTranslated).count == 16)
    }

    @Test func englishIsUnchanged() {
        #expect(RosaryQuotes.catalog(spanish: false) == RosaryQuotes.all)
        #expect(RosaryQuotes.all.allSatisfy { !$0.aiTranslated })
        let date = Date(timeIntervalSince1970: 1_793_000_000)
        #expect(RosaryQuotes.all.contains(RosaryQuotes.quote(spanish: false, on: date)))
        #expect(
            RosaryQuotes.quote(spanish: true, on: date) != RosaryQuotes.quote(spanish: true, halfway: true, on: date))
    }

    @Test func theAILineHasItsSpanish() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try #require(Bundle(path: path))
        let key = "Translation made with artificial intelligence."
        #expect(spanish.localizedString(forKey: key, value: nil, table: nil) != key)
    }
}
