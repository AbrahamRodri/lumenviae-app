//
//  ShareTextTests.swift
//  appTests
//
//  What a reader sends a friend from a meditation or a prayer (W5).
//

import Foundation
import Testing

@testable import app

struct ShareTextTests {

    private let prayer = BookPrayer(
        id: "test_prayer",
        title: "The Hail Mary",
        latinTitle: "Ave Maria",
        origin: "Luke 1 · 11th century",
        note: nil,
        english: "Hail Mary, full of grace,\nthe Lord is with thee.",
        latin: "Ave Maria, gratia plena,\nDominus tecum."
    )

    @Test func endsOnTheLineAndTheAppStoreLink() {
        let text = ShareText.prayer(prayer, language: .english, invitation: "Prayed with Lumen Viae:")
        #expect(text.hasSuffix("Prayed with Lumen Viae:\nhttps://apps.apple.com/app/id6760320749"))
        #expect(text.hasPrefix("The Hail Mary\n\nHail Mary, full of grace,"))
        #expect(text.contains("— Luke 1 · 11th century"))
    }

    @Test func aPrayerIsSharedInTheLanguageItIsShownIn() {
        let latin = ShareText.prayer(prayer, language: .latin)
        #expect(latin.hasPrefix("Ave Maria\n\nAve Maria, gratia plena,"))
        #expect(!latin.contains("full of grace"))

        let english = ShareText.prayer(prayer, language: .english)
        #expect(!english.contains("gratia plena"))

        let both = ShareText.prayer(prayer, language: .both)
        #expect(both.range(of: "gratia plena")!.lowerBound < both.range(of: "full of grace")!.lowerBound)
        let underEnglish = ShareText.prayer(prayer, language: .latinUnderEnglish)
        #expect(
            underEnglish.range(of: "full of grace")!.lowerBound < underEnglish.range(of: "gratia plena")!.lowerBound)
    }

    @Test func aSpanishPrayerIsSharedInSpanish() {
        // In a Spanish app the vernacular slot holds the Spanish
        let spanish = BookPrayer(
            id: "ave_es", title: "El Ave María", latinTitle: "Ave Maria", origin: "Luke 1:28 · 15th century", note: nil,
            english: "Dios te salve, María, llena eres de gracia,", latin: "Ave Maria, gratia plena,"
        )
        let text = ShareText.prayer(spanish, language: .english, spanish: true, invitation: "Rezado con Lumen Viae:")
        #expect(text.hasPrefix("El Ave María\n\nDios te salve, María"))
        #expect(text.hasSuffix("Rezado con Lumen Viae:\nhttps://apps.apple.com/app/id6760320749"))
        // The book's origins are English alone: never under a Spanish prayer,
        // nor under its Latin in a Spanish app
        #expect(!text.contains("Luke"))
        #expect(!ShareText.prayer(spanish, language: .latin, spanish: true).contains("Luke"))
        #expect(ShareText.prayer(spanish, language: .english, spanish: false).contains("— Luke 1:28"))
    }

    @Test func theSpanishCatalogCarriesTheLine() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try #require(Bundle(path: path))
        let key = "Prayed with Lumen Viae, a Rosary and prayer companion:"
        let line = spanish.localizedString(forKey: key, value: nil, table: nil)
        #expect(line != key)
        #expect(line.contains("Lumen Viae"))
    }

    @Test func aLongMeditationIsCutToAnExcerpt() {
        let paragraph = String(repeating: "The Angel came to Mary in Nazareth. ", count: 8)
        let content = Array(repeating: paragraph.trimmingCharacters(in: .whitespaces), count: 6).joined(
            separator: "\n\n")
        #expect(content.count > ShareText.excerptLimit)
        let text = ShareText.meditation(
            title: "The Annunciation", content: content, author: "St. Alphonsus Liguori", source: "The Glories of Mary",
            setName: "Liguori"
        )
        let body = text.components(separatedBy: "\n\n")[1...].prefix { !$0.hasPrefix("— ") }.joined(separator: "\n\n")
        #expect(body.count <= ShareText.excerptLimit + 2)
        #expect(body.hasSuffix(" …"))
        #expect(text.contains("— St. Alphonsus Liguori, The Glories of Mary"))
        #expect(text.hasSuffix(ShareText.appStoreLink))
    }

    @Test func aShortMeditationIsSharedWhole() {
        let text = ShareText.meditation(
            title: "The Visitation", content: "Mary went in haste.", author: nil, source: nil, setName: "The Gospel"
        )
        #expect(text.contains("\n\nMary went in haste.\n\n"))
        #expect(!text.contains("…"))
        #expect(text.contains("— The Gospel"))
    }

    @Test func oneLongParagraphIsCutAtASentence() {
        let long = String(repeating: "Behold the handmaid of the Lord. ", count: 40)
        let cut = ShareText.excerpt(long)
        #expect(cut.count <= ShareText.excerptLimit + 2)
        #expect(cut.hasSuffix("Lord. …"))
    }

    @Test func thePageMarkupIsTakenOut() {
        let marked = "# The Title\n\nMy soul * doth magnify the Lord.\n\n[Let us pray.]\n\n─────\n\nAmen."
        #expect(ShareText.plain(marked) == "The Title\n\nMy soul doth magnify the Lord.\n\nAmen.")
    }
}
