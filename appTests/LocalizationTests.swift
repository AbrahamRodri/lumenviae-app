//
//  LocalizationTests.swift
//  appTests
//
//  The String Catalog's plural variations give English its singulars:
//  the code asks for "6 sets of meditations" and the catalog answers
//  "1 set of meditations" when there is one. If the catalog's entry is
//  lost, English reads "1 sets", and these fail.
//

import Foundation
import Testing

@testable import app

struct LocalizationTests {

    @Test func meditationSetCountsAreSingularForOne() {
        #expect(String(localized: "\(1) sets of meditations") == "1 set of meditations")
        #expect(String(localized: "\(6) sets of meditations") == "6 sets of meditations")
        #expect(String(localized: "\(1) of \(1) sets of meditations") == "1 of 1 set of meditations")
        #expect(String(localized: "\(2) of \(6) sets of meditations") == "2 of 6 sets of meditations")
    }

    @Test func narrationTimeIsSaidWithSingulars() {
        #expect(NarrationClock.spoken(61) == "1 minute 1 second")
        #expect(NarrationClock.spoken(200) == "3 minutes 20 seconds")
        #expect(NarrationClock.spoken(60) == "1 minute")
        #expect(NarrationClock.spoken(1) == "1 second")
    }

    @Test func openingPrayersLeadIntoTheDecadeInOneSentence() {
        #expect(PendantTitleBlock.leadIn(category: .glorious, ordinal: 1) == "Then the First Glorious Mystery")
        #expect(PendantTitleBlock.leadIn(category: .sevenSorrows, ordinal: 1) == "Then the First Sorrow of Mary")
        #expect(PendantTitleBlock.leadIn(category: nil, ordinal: 4) == "Then the Fourth Mystery")
    }

    @Test func consecrationAndLiturgyCountsAreSingularForOne() {
        #expect(String(localized: "\(1) chapters") == "1 chapter")
        #expect(String(localized: "in \(1) days") == "in 1 day")
        #expect(String(localized: "Opens a menu of \(1) devotions") == "Opens a menu of 1 devotion")
        #expect(String(localized: "\(1) of \(1) days on this device") == "1 of 1 day on this device")
        #expect(String(localized: "\(3) of \(30) days on this device") == "3 of 30 days on this device")
    }

    @Test func setNamesKeepTheirEnglishWording() {
        #expect(MysteryCategory.joyful.devotionTitle == "Joyful Mysteries")
        #expect(MysteryCategory.sevenSorrows.devotionTitle == "Seven Sorrows of Mary")
        #expect(MysteryCategory.luminous.displayName == "Luminous")
        #expect(MysteryCategory.sevenSorrows.displayName == "Seven Sorrows")
        #expect(MysteryCategory.joyful.subtitle == "Jesus' birth and childhood")
        #expect(MysteryCategory.sevenSorrows.subtitle == "Mary in her grief")
    }

    @Test func meditationKindsKeepTheirEnglishWording() {
        #expect(MeditationLabel.displayName("Considerations") == "Reflections")
        #expect(MeditationLabel.displayName("Contemplative") == "Inside the Scene")
        #expect(MeditationLabel.displayName("Scriptural") == "Gospel")
        #expect(MeditationLabel.displayName("Saints") == "Saints")
        #expect(MeditationLabel.displayName("Something New") == "Something New")
    }

    @Test func streakAndReadingCountsAreSingularForOne() {
        #expect(String(localized: "\(1) days in a row") == "1 day in a row")
        #expect(String(localized: "\(1) days away") == "1 day away")
        #expect(String(localized: "Next: \("A novena") · \(1) days away") == "Next: A novena · 1 day away")
        #expect(String(localized: "\(1) earlier chapters") == "1 earlier chapter")
        #expect(String(localized: "Show the \(1) earlier chapters") == "Show the earlier chapter")
        #expect(String(localized: "\("A chapter a day") · \(1) read today") == "A chapter a day · one read today")
        #expect(String(localized: "\("A chapter a day") · \(2) read today") == "A chapter a day · 2 read today")
        #expect(String(localized: "Sleep timer, \(1) minutes left") == "Sleep timer, 1 minute left")
    }

    @Test func chantOccasionsAreShownInTheirEnglishWording() {
        for occasion in ChantLibraryData.occasions {
            #expect(ChantLibraryData.displayWording(of: occasion.title) == occasion.title)
            #expect(occasion.shownTitle == occasion.title)
            for rubric in occasion.blocks.compactMap(\.rubric) {
                #expect(ChantLibraryData.displayWording(of: rubric) == rubric)
            }
        }
        #expect(ChantLibraryData.displayWording(of: "Silent prayer") == "Silent prayer")
        // A kept set in older words is shown as the occasion reads now
        #expect(ChantLibraryData.displayWording(of: "Benediction") == "Adoration and Blessing")
        // The reader's own words pass through
        #expect(ChantLibraryData.displayWording(of: "Thursday holy hour") == "Thursday holy hour")
    }
}

/// Spanish (1e): every key in the catalog carries a Spanish translation,
/// and the built app reads it.
struct SpanishCatalogTests {

    /// The catalog's source, read beside this file (the simulator shares
    /// the Mac's disk)
    private static var catalog: [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("app/Localizable.xcstrings")
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = json["strings"] as? [String: Any] else { return [:] }
        return strings
    }

    private static func specifiers(_ text: String) -> [String] {
        let regex = /%(?:\d+\$)?(?:@|lld|ld|d|lf|f|\.\d+f|%)/
        return text.matches(of: regex)
            .map { String($0.output).replacing(/\d+\$/, with: "") }
            .sorted()
    }

    @Test func everyKeyHasSpanish() {
        let strings = Self.catalog
        #expect(strings.count > 2000)
        var missing: [String] = []
        var mismatched: [String] = []
        for (key, value) in strings {
            guard key.contains(where: \.isLetter),
                  let entry = value as? [String: Any],
                  (entry["shouldTranslate"] as? Bool) != false else { continue }
            let localizations = entry["localizations"] as? [String: Any]
            guard let spanish = localizations?["es"] as? [String: Any] else {
                missing.append(key)
                continue
            }
            // A plain string keeps the English's placeholders; a plural's
            // forms are checked by building them (below)
            if let unit = spanish["stringUnit"] as? [String: Any],
               spanish["substitutions"] == nil,
               let text = unit["value"] as? String {
                let english = ((localizations?["en"] as? [String: Any])?["stringUnit"] as? [String: Any])?["value"] as? String ?? key
                if text.isEmpty || Self.specifiers(text) != Self.specifiers(english) {
                    mismatched.append(key)
                }
            }
        }
        #expect(missing.isEmpty, "Keys with no Spanish: \(missing.sorted().prefix(20))")
        #expect(mismatched.isEmpty, "Spanish with other placeholders: \(mismatched.sorted().prefix(20))")
    }

    /// The prayer is feminine (DPD): "una sola Ave María", "la primera
    /// Ave María", never "un solo Ave María", "el primer Ave María". Right
    /// before its stressed "a" it takes "el", as "el ave" does: "el Ave
    /// María", "del Ave María", never "la Ave María". The name is two words
    /// and the count "Ave Marías", as most apps and the Mexican bishops
    /// write it (Abraham, 10 Nov 2026: "Follow how other apps do it"); the
    /// old one-word spelling is caught as well.
    static let masculineAvemaria =
        #"(?i)\b((un|este|ese|otro|primer|último|solo|único)\s+((solo|primer|último|otro|único)\s+)?|la\s+)(avemar|ave\s+mar[ií]a)"#

    /// The settled wording (Mexican usage, ustedes not vosotros), held:
    /// these slipped past five translators and a proofreader once
    @Test func spanishKeepsTheSettledWording() {
        var broken: [String] = []
        for (key, value) in Self.catalog {
            guard let entry = value as? [String: Any],
                  let spanish = (entry["localizations"] as? [String: Any])?["es"] else { continue }
            let text = (try? JSONSerialization.data(withJSONObject: spanish))
                .flatMap { String(data: $0, encoding: .utf8) } ?? ""
            // Añadir in any case: the small-capital "AÑADIR" buttons got past a check for two spellings
            if text.contains("vosotros") || text.contains("Ajustes")
                || text.range(of: "añad", options: .caseInsensitive) != nil
                || text.range(of: Self.masculineAvemaria, options: .regularExpression) != nil
                || text.range(of: "avemar", options: .caseInsensitive) != nil {
                broken.append(key)
            }
        }
        #expect(broken.isEmpty, "Spanish against the settled wording: \(broken.sorted().prefix(20))")
    }

    @Test func theBuiltAppReadsSpanish() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try #require(Bundle(path: path))
        #expect(spanish.localizedString(forKey: "App Language", value: nil, table: nil) == "Idioma de la app")
        #expect(
            spanish.localizedString(forKey: "The words of this app were translated into Spanish with artificial intelligence. The prayers use the Church's traditional texts.", value: nil, table: nil)
                == "Las palabras de esta app se tradujeron al español con inteligencia artificial. Las oraciones usan los textos tradicionales de la Iglesia cuando existen."
        )
        #expect(spanish.localizedString(forKey: "Spanish (beta)", value: nil, table: nil) == "Español (beta)")
        #expect(
            spanish.localizedString(forKey: "Spanish is in beta: the recordings and some meditations are still in English.", value: nil, table: nil)
                == "El español está en beta: las grabaciones y algunas meditaciones siguen en inglés."
        )
    }

    @Test func spanishPluralsAgreeWithTheirCount() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try #require(Bundle(path: path))
        let locale = Locale(identifier: "es_MX")
        let format = spanish.localizedString(forKey: "%lld days in a row", value: nil, table: nil)
        #expect(String(format: format, locale: locale, 1) == "1 día seguido")
        #expect(String(format: format, locale: locale, 12) == "12 días seguidos")
    }
}

/// The one-time AI notice (Spanish only): owed until its OK is pressed,
/// never to an English reader
struct TranslationNoticeTests {

    private func freshDefaults() -> UserDefaults {
        let name = "TranslationNoticeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func owedInSpanishUntilDismissed() {
        let defaults = freshDefaults()
        #expect(AppLanguage.owesTranslationNotice(defaults: defaults, inSpanish: true))
        // Raised but not dismissed (a sheet came up first): still owed
        #expect(AppLanguage.owesTranslationNotice(defaults: defaults, inSpanish: true))
        AppLanguage.markTranslationNoticeShown(defaults: defaults)
        #expect(!AppLanguage.owesTranslationNotice(defaults: defaults, inSpanish: true))
    }

    @Test func neverOwedInEnglish() {
        #expect(!AppLanguage.owesTranslationNotice(defaults: freshDefaults(), inSpanish: false))
    }
}
