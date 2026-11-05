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
    /// The Spanish edition it is taken from, where the Spanish names one
    /// (the bundled sets' Spanish does; the server's sets keep their own)
    var source: String? = nil
    /// The Spanish is the team's own translation, not a published one
    var aiTranslated: Bool?

    enum CodingKeys: String, CodingKey {
        case id, title, content, source
        case aiTranslated = "ai_translated"
    }

    /// The Spanish of the five sets compiled into the app
    /// (`BundledMeditationSets`), keyed by their negative ids, bundled so
    /// they read in Spanish offline from the first launch.
    /// `Resources/Spanish/es_bundled_meditations.json` is the reviewed
    /// file from reports/rig-es (bundled-meditations-es.json), copied byte
    /// for byte: correct it there and copy it again.
    static let bundled: [MeditationTranslation] = {
        guard let url = Bundle.main.url(forResource: "es_bundled_meditations", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let translations = try? JSONDecoder().decode([MeditationTranslation].self, from: data)
        else { return [] }
        return translations
    }()

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
                // The Spanish edition stands where the English names one;
                // a meditation with no source of its own gets none
                source: meditation.source == nil ? nil : (es.source ?? meditation.source),
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

extension MeditationSet {
    /// The set with the Spanish for its own meditations beside its English
    /// (the bundled sets, which are never fetched)
    func withTranslations(_ all: [MeditationTranslation]) -> MeditationSet {
        let ids = Set((englishMeditations ?? []).map(\.id))
        let own = all.filter { ids.contains($0.id) }
        return MeditationSet(
            id: id, name: name, category: category, description: description, labels: labels,
            meditations: englishMeditations, author: author, source: source, audioExpiresAt: audioExpiresAt,
            imageUrl: imageUrl, imageAlignment: imageAlignment, imageFocalX: imageFocalX, imageFocalY: imageFocalY,
            imageWidth: imageWidth, imageHeight: imageHeight, imageAlt: imageAlt, imageAttribution: imageAttribution,
            translations: own.isEmpty ? translations : own)
    }
}
