//
//  SourcesCreditsTests.swift
//  appTests
//
//  Sources & Credits in Spanish: every licence the generated credits
//  carry is said in Spanish, or is a name that reads the same.
//

import Foundation
import Testing

@testable import app

@MainActor
struct SourcesCreditsTests {

    private var spanish: Bundle {
        Bundle(path: Bundle.main.path(forResource: "es", ofType: "lproj")!)!
    }

    @Test func everyLicenceIsSaidInSpanishOrIsAName() {
        let licences = Set((SourcesAndCredits.paintings + SourcesAndCredits.texts).map(\.licence))
        for licence in licences where !SourcesCreditsSheet.licenceNames.contains(licence) {
            let said = SourcesCreditsSheet.licenceName(licence, bundle: spanish)
            #expect(said != licence, "\(licence) has no Spanish")
        }
    }

    @Test func publicDomainReadsInSpanish() {
        #expect(SourcesCreditsSheet.licenceName("Public domain", bundle: spanish) == "Dominio público")
        #expect(SourcesCreditsSheet.licenceName("CC0", bundle: spanish) == "CC0")
    }
}
