//
//  SetTranslationTests.swift
//  Lumen Viae Tests
//
//  A meditation set's own words in Spanish (the api's `set_translation`,
//  sent with `lang=es`): decoded beside the English and kept there, so a
//  stored copy reads right in either language, and shown only in a
//  Spanish app.
//

import Foundation
import Testing

@testable import app

struct SetTranslationTests {

    private let json = Data(
        """
        {"id": 29, "name": "St. Alphonsus Liguori", "category": "joyful",
         "description": "Short Consideration and a Prayer", "labels": ["Saints"],
         "author": "St. Alphonsus Liguori", "source": "The Glories of Mary",
         "image_alt": "Portrait of St. Alphonsus",
         "set_translation": {"name": "San Alfonso María de Ligorio",
           "description": "Una breve reflexión", "author": "San Alfonso María de Ligorio",
           "source": "Las glorias de María", "image_alt": "Retrato de San Alfonso",
           "ai_translated": true}}
        """.utf8)

    @Test("The list's set keeps its English and its Spanish side by side")
    func aSummaryDecodesBoth() throws {
        let set = try JSONDecoder().decode(MeditationSetSummary.self, from: json)
        #expect(set.englishName == "St. Alphonsus Liguori")
        #expect(set.setTranslation?.name == "San Alfonso María de Ligorio")
        #expect(set.setTranslation?.imageAlt == "Retrato de San Alfonso")
        #expect(set.setTranslation?.aiTranslated == true)
    }

    @Test("A stored set comes back with both, unchanged")
    func aSetRoundTrips() throws {
        let set = try JSONDecoder().decode(MeditationSet.self, from: json)
        let again = try JSONDecoder().decode(MeditationSet.self, from: JSONEncoder().encode(set))
        #expect(again == set)
        #expect(again.englishSource == "The Glories of Mary")
        #expect(again.setTranslation?.source == "Las glorias de María")
    }

    @Test("Spanish only in a Spanish app, and English where it has none")
    func theSpanishIsShownOnlyInSpanish() {
        #expect(SetTranslation.pick("San Alfonso", "St. Alphonsus", spanish: true) == "San Alfonso")
        #expect(SetTranslation.pick("San Alfonso", "St. Alphonsus", spanish: false) == "St. Alphonsus")
        #expect(SetTranslation.pick(nil, "St. Alphonsus", spanish: true) == "St. Alphonsus")
        #expect(SetTranslation.pick("", "St. Alphonsus", spanish: true) == "St. Alphonsus")
    }

    @Test("A set without set_translation reads as it always did")
    func noTranslationIsNoChange() throws {
        let english = Data(
            """
            {"id": 1, "name": "Gospel", "category": "joyful", "description": null, "labels": null}
            """.utf8)
        let set = try JSONDecoder().decode(MeditationSetSummary.self, from: english)
        #expect(set.setTranslation == nil)
        #expect(set.name == "Gospel")
    }
}
