//
//  SpanishContent.swift
//  app
//
//  The Rosary's prayers and the mysteries' names and fruits in Spanish,
//  bundled so a Spanish first launch, or a phone with no signal, prays in
//  Spanish. The two files are the api's own (priv/rosary_content/es/
//  prayers.json and mysteries.json), copied byte for byte into
//  Resources/Spanish, so the app and the server never say a prayer two ways.
//
//  Spanish stands where English stood: in a Spanish app the "English"
//  side of a prayer is its Spanish, beside the same Latin. What has no
//  Spanish yet (a mystery's description, the consecration's prayers) stays
//  English, whole, never mixed into one line.
//

import Foundation

enum SpanishContent {

    nonisolated struct Prayer: Decodable, Equatable {
        let title: String
        let text: [String]
        /// Part of its Spanish is the team's own translation, not a
        /// published text: the app says so under it
        let aiTranslated: Bool

        enum CodingKeys: String, CodingKey {
            case title, text
            case aiTranslated = "ai_translated"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decode(String.self, forKey: .title)
            text = try container.decode([String].self, forKey: .text)
            aiTranslated = try container.decodeIfPresent(Bool.self, forKey: .aiTranslated) ?? false
        }

        /// The lines as one text, in the PrayerText grammar the English uses
        var lines: String { text.joined(separator: "\n") }
    }

    nonisolated struct Mystery: Decodable, Equatable {
        let name: String
        let fruit: String
    }

    private nonisolated struct PrayersFile: Decodable {
        let prayers: [String: Prayer]
    }

    private nonisolated struct MysteriesFile: Decodable {
        let mysteries: [String: Mystery]
    }

    /// Whether the app is speaking Spanish this launch (the language is
    /// chosen before the app opens, and a change relaunches it)
    static var isActive: Bool { AppLanguage.isSpanish }

    /// The Rosary's twelve prayers, by the ids `RosaryPrayers` uses
    static let prayers: [String: Prayer] = load("es_rosary_prayers", as: PrayersFile.self)?.prayers ?? [:]

    /// Each mystery's name and fruit, keyed "<category>_<order>" as
    /// `MysteryData.traditionalFruits` is
    static let mysteries: [String: Mystery] = load("es_mysteries", as: MysteriesFile.self)?.mysteries ?? [:]

    private static func load<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Spanish in English's place

    /// The prayer as a Spanish app says it: its Spanish title and words in
    /// English's place, the Latin untouched. Unchanged when off, or when
    /// the prayer has no Spanish.
    static func vernacular(_ prayer: BilingualConsecrationPrayer, spanish: Bool = isActive)
        -> BilingualConsecrationPrayer
    {
        guard spanish, let es = prayers[prayer.id] else { return prayer }
        var swapped = BilingualConsecrationPrayer(
            id: prayer.id,
            englishTitle: es.title,
            latinTitle: prayer.latinTitle,
            englishContent: es.lines,
            latinContent: prayer.content.latin
        )
        swapped.aiTranslated = es.aiTranslated
        return swapped
    }

    /// A prayer's text by id, Spanish in English's place
    static func vernacular(_ text: BilingualText, id: String, spanish: Bool = isActive) -> BilingualText {
        guard spanish, let es = prayers[id] else { return text }
        return BilingualText(english: es.lines, latin: text.latin)
    }

    /// The mystery's name as the app shows it
    static func mysteryName(_ english: String, key: String, spanish: Bool = isActive) -> String {
        guard spanish, let es = mysteries[key] else { return english }
        return es.name
    }

    /// The grace a mystery asks for, as the app shows it
    static func fruit(_ english: String, key: String, spanish: Bool = isActive) -> String {
        guard spanish, let es = mysteries[key] else { return english }
        return es.fruit
    }
}
