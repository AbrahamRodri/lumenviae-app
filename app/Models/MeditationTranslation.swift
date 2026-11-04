//
//  MeditationTranslation.swift
//  app
//
//  A meditation's Spanish, as `GET /meditation-sets/:id?lang=es` sends it
//  in the set's `translations` (api docs/IOS_API_CONTRACT.md, section 14):
//  the meditation's id, its Spanish title (nil where the English has none)
//  and text, and whether the Spanish is the team's own translation. Laid
//  over the English by id in a Spanish app; a meditation with none, and
//  every meditation of a bundled set or of Sheen's, stays English. The
//  recordings stay English in every language.
//

import Foundation

nonisolated struct MeditationTranslation: Codable, Hashable, Sendable {
    let id: Int
    let title: String?
    let content: String
    /// The Spanish is the team's own translation, not a published one
    var aiTranslated: Bool?

    enum CodingKeys: String, CodingKey {
        case id, title, content
        case aiTranslated = "ai_translated"
    }

    /// Whether this launch shows the meditations in Spanish. The language
    /// is chosen before the app opens and a change relaunches it, so it is
    /// read once; read off the main actor too, since offline sets are
    /// decoded and walked there.
    static let isActive: Bool = Bundle.main.preferredLocalizations.first?.hasPrefix("es") ?? false

    /// The language a set is asked for in: Spanish in a Spanish app, else
    /// nothing, so an English app's request is exactly what it always was
    static var requestLanguage: String? { isActive ? "es" : nil }

    /// The meditations with each one's Spanish in place of its English,
    /// title and text together; English, unchanged, when off or when a
    /// meditation has none
    static func overlay(
        _ meditations: [Meditation]?, with translations: [MeditationTranslation]?, spanish: Bool = isActive
    ) -> [Meditation]? {
        guard spanish, let meditations, let translations, !translations.isEmpty else { return meditations }
        let byID = Dictionary(translations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return meditations.map { meditation in
            guard let es = byID[meditation.id], !es.content.isEmpty else { return meditation }
            var spanish = Meditation(
                id: meditation.id,
                title: es.title,
                content: es.content,
                author: meditation.author,
                source: meditation.source,
                audioUrl: meditation.audioUrl,
                narrations: meditation.narrations,
                mystery: meditation.mystery
            )
            spanish.isSpanish = true
            spanish.aiTranslated = es.aiTranslated == true
            return spanish
        }
    }
}
