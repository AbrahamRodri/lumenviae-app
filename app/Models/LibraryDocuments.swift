//
//  LibraryDocuments.swift
//  Lumen Viae
//
//  The two documents the server keeps the Prayer Book's words and the
//  Chant Library's catalog in (`GET /api/v2/prayer-book`,
//  `GET /api/v2/chant-library`), in the shape the server serves them:
//  the attributes of a JSON:API resource, snake_case. The app ships a
//  copy of each as its starting point and keeps the newest the server
//  has given it. How the app arranges the words (orders of prayer,
//  paintings, icons, the library's shelves) stays in Swift.
//
//  A nil is encoded as null rather than left out, so a document written
//  by the app reads the same as one the server sends.
//

import Foundation

// MARK: - PrayerBookDocument

nonisolated struct PrayerBookDocument: Codable, Equatable, Sendable {
    /// The server's fingerprint of the content; nil in a document written
    /// by the app's export
    var version: String?
    var updatedAt: String?
    var prayers: [Prayer]
    var chapters: [Chapter]
    /// The novenas (`NovenaDocument.swift`), served only when named in
    /// `fields`; empty in a document from before them
    var novenas: [Novena] = []

    struct Prayer: Codable, Equatable, Sendable {
        var id: String
        var title: String
        var latinTitle: String?
        var origin: String?
        /// A long origin's cut for under the title ("Fr. Lawrence G.
        /// Lovasik, S.V.D. · as printed by EWTN"); nil where the origin is
        /// short enough to stand there itself
        var shortCredit: String?
        /// Whether the origin credits someone or something real (an
        /// author, a book, a publisher) and so stands at the prayer's foot;
        /// false for a tradition and a century alone (api #290). Nil in a
        /// copy from before it, which keeps the foot as it was
        var originCredit: Bool?
        var note: String?
        var english: String
        var latin: String?
        var listTitle: String?
        var englishName: String?
        var searchWords: [String]

        enum CodingKeys: String, CodingKey {
            case id, title, origin, note, english, latin
            case shortCredit = "short_credit"
            case originCredit = "origin_credit"
            case latinTitle = "latin_title"
            case listTitle = "list_title"
            case englishName = "english_name"
            case searchWords = "search_words"
        }

        init(
            id: String, title: String, latinTitle: String?, origin: String?, note: String?,
            english: String, latin: String?, listTitle: String?, englishName: String?, searchWords: [String],
            shortCredit: String? = nil, originCredit: Bool? = nil
        ) {
            self.shortCredit = shortCredit
            self.originCredit = originCredit
            self.id = id
            self.title = title
            self.latinTitle = latinTitle
            self.origin = origin
            self.note = note
            self.english = english
            self.latin = latin
            self.listTitle = listTitle
            self.englishName = englishName
            self.searchWords = searchWords
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            title = try c.decode(String.self, forKey: .title)
            latinTitle = try c.decodeIfPresent(String.self, forKey: .latinTitle)
            origin = try c.decodeIfPresent(String.self, forKey: .origin)
            shortCredit = try c.decodeIfPresent(String.self, forKey: .shortCredit)
            originCredit = try c.decodeIfPresent(Bool.self, forKey: .originCredit)
            note = try c.decodeIfPresent(String.self, forKey: .note)
            english = try c.decode(String.self, forKey: .english)
            latin = try c.decodeIfPresent(String.self, forKey: .latin)
            listTitle = try c.decodeIfPresent(String.self, forKey: .listTitle)
            englishName = try c.decodeIfPresent(String.self, forKey: .englishName)
            searchWords = try c.decodeIfPresent([String].self, forKey: .searchWords) ?? []
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(title, forKey: .title)
            try c.encode(latinTitle, forKey: .latinTitle)
            try c.encode(origin, forKey: .origin)
            try c.encodeIfPresent(shortCredit, forKey: .shortCredit)
            try c.encodeIfPresent(originCredit, forKey: .originCredit)
            try c.encode(note, forKey: .note)
            try c.encode(english, forKey: .english)
            try c.encode(latin, forKey: .latin)
            try c.encode(listTitle, forKey: .listTitle)
            try c.encode(englishName, forKey: .englishName)
            try c.encode(searchWords, forKey: .searchWords)
        }
    }

    struct Chapter: Codable, Equatable, Sendable {
        var id: String
        var numeral: String
        var title: String
        var latinTitle: String
        /// The chapter's one italic line
        var note: String?
        var topic: String?
        var searchWords: [String]
        /// Every prayer the chapter prints, each once, in the order printed
        var prayerIDs: [String]
        /// The chapter's sub-headings and the prayers under each; a prayer
        /// may stand under more than one
        var sections: [Section]

        enum CodingKeys: String, CodingKey {
            case id, numeral, title, note, topic, sections
            case latinTitle = "latin_title"
            case searchWords = "search_words"
            case prayerIDs = "prayer_ids"
        }

        init(
            id: String, numeral: String, title: String, latinTitle: String, note: String?,
            topic: String?, searchWords: [String], prayerIDs: [String], sections: [Section]
        ) {
            self.id = id
            self.numeral = numeral
            self.title = title
            self.latinTitle = latinTitle
            self.note = note
            self.topic = topic
            self.searchWords = searchWords
            self.prayerIDs = prayerIDs
            self.sections = sections
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            numeral = try c.decode(String.self, forKey: .numeral)
            title = try c.decode(String.self, forKey: .title)
            latinTitle = try c.decode(String.self, forKey: .latinTitle)
            note = try c.decodeIfPresent(String.self, forKey: .note)
            topic = try c.decodeIfPresent(String.self, forKey: .topic)
            searchWords = try c.decodeIfPresent([String].self, forKey: .searchWords) ?? []
            prayerIDs = try c.decode([String].self, forKey: .prayerIDs)
            // A server without sub-headings prints the chapter as one
            sections =
                try c.decodeIfPresent([Section].self, forKey: .sections)
                ?? [Section(title: title, prayerIDs: prayerIDs)]
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(numeral, forKey: .numeral)
            try c.encode(title, forKey: .title)
            try c.encode(latinTitle, forKey: .latinTitle)
            try c.encode(note, forKey: .note)
            try c.encode(topic, forKey: .topic)
            try c.encode(searchWords, forKey: .searchWords)
            try c.encode(prayerIDs, forKey: .prayerIDs)
            try c.encode(sections, forKey: .sections)
        }
    }

    struct Section: Codable, Equatable, Sendable {
        var title: String
        var prayerIDs: [String]

        enum CodingKeys: String, CodingKey {
            case title
            case prayerIDs = "prayer_ids"
        }
    }

    enum CodingKeys: String, CodingKey {
        case version, prayers, chapters, novenas
        case updatedAt = "updated_at"
    }

    init(
        version: String? = nil, updatedAt: String? = nil, prayers: [Prayer], chapters: [Chapter],
        novenas: [Novena] = []
    ) {
        self.version = version
        self.updatedAt = updatedAt
        self.prayers = prayers
        self.chapters = chapters
        self.novenas = novenas
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(String.self, forKey: .version)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        prayers = try c.decode([Prayer].self, forKey: .prayers)
        chapters = try c.decode([Chapter].self, forKey: .chapters)
        novenas = try c.decodeIfPresent([Novena].self, forKey: .novenas) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(version, forKey: .version)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try c.encode(prayers, forKey: .prayers)
        try c.encode(chapters, forKey: .chapters)
        // Left out when empty, so a book from before novenas writes as it did
        if !novenas.isEmpty { try c.encode(novenas, forKey: .novenas) }
    }
}

// MARK: - ChantLibraryDocument

nonisolated struct ChantLibraryDocument: Codable, Equatable, Sendable {
    var version: String?
    var updatedAt: String?
    var groups: [Group]
    var chants: [Chant]

    struct Group: Codable, Equatable, Sendable {
        var id: String
        var title: String
        var note: String?
        var parts: [Part]

        init(id: String, title: String, note: String?, parts: [Part]) {
            self.id = id
            self.title = title
            self.note = note
            self.parts = parts
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            title = try c.decode(String.self, forKey: .title)
            note = try c.decodeIfPresent(String.self, forKey: .note)
            parts = try c.decode([Part].self, forKey: .parts)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(title, forKey: .title)
            try c.encode(note, forKey: .note)
            try c.encode(parts, forKey: .parts)
        }

        enum CodingKeys: String, CodingKey { case id, title, note, parts }
    }

    struct Part: Codable, Equatable, Sendable {
        var title: String?
        var note: String?
        var chantIDs: [String]

        enum CodingKeys: String, CodingKey {
            case title, note
            case chantIDs = "chant_ids"
        }

        init(title: String?, note: String?, chantIDs: [String]) {
            self.title = title
            self.note = note
            self.chantIDs = chantIDs
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            title = try c.decodeIfPresent(String.self, forKey: .title)
            note = try c.decodeIfPresent(String.self, forKey: .note)
            chantIDs = try c.decode([String].self, forKey: .chantIDs)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(title, forKey: .title)
            try c.encode(note, forKey: .note)
            try c.encode(chantIDs, forKey: .chantIDs)
        }
    }

    /// A file the server keeps for a chant. Its URL is content-addressed
    /// (a changed file is a new URL), so a copy is kept by it; nil in a
    /// document written by the app's export, before the upload.
    struct Asset: Codable, Equatable, Sendable {
        var url: String?
        var bytes: Int
        var sha256: String

        init(url: String?, bytes: Int, sha256: String) {
            self.url = url
            self.bytes = bytes
            self.sha256 = sha256
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            url = try c.decodeIfPresent(String.self, forKey: .url)
            bytes = try c.decode(Int.self, forKey: .bytes)
            sha256 = try c.decode(String.self, forKey: .sha256)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(url, forKey: .url)
            try c.encode(bytes, forKey: .bytes)
            try c.encode(sha256, forKey: .sha256)
        }

        enum CodingKeys: String, CodingKey { case url, bytes, sha256 }
    }

    struct ScorePart: Codable, Equatable, Sendable {
        var file: String
        var caption: String
        var aspectRatio: Double
        var url: String?
        var bytes: Int
        var sha256: String

        enum CodingKeys: String, CodingKey {
            case file, caption, url, bytes, sha256
            case aspectRatio = "aspect_ratio"
        }

        init(file: String, caption: String, aspectRatio: Double, url: String?, bytes: Int, sha256: String) {
            self.file = file
            self.caption = caption
            self.aspectRatio = aspectRatio
            self.url = url
            self.bytes = bytes
            self.sha256 = sha256
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            file = try c.decode(String.self, forKey: .file)
            caption = try c.decode(String.self, forKey: .caption)
            aspectRatio = try c.decode(Double.self, forKey: .aspectRatio)
            url = try c.decodeIfPresent(String.self, forKey: .url)
            bytes = try c.decode(Int.self, forKey: .bytes)
            sha256 = try c.decode(String.self, forKey: .sha256)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(file, forKey: .file)
            try c.encode(caption, forKey: .caption)
            try c.encode(aspectRatio, forKey: .aspectRatio)
            try c.encode(url, forKey: .url)
            try c.encode(bytes, forKey: .bytes)
            try c.encode(sha256, forKey: .sha256)
        }
    }

    struct Line: Codable, Equatable, Sendable {
        var latin: String
        var english: String
        var start: Double
        var end: Double
        var part: Int?

        init(latin: String, english: String, start: Double, end: Double, part: Int?) {
            self.latin = latin
            self.english = english
            self.start = start
            self.end = end
            self.part = part
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            latin = try c.decode(String.self, forKey: .latin)
            english = try c.decode(String.self, forKey: .english)
            start = try c.decode(Double.self, forKey: .start)
            end = try c.decode(Double.self, forKey: .end)
            part = try c.decodeIfPresent(Int.self, forKey: .part)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(latin, forKey: .latin)
            try c.encode(english, forKey: .english)
            try c.encode(start, forKey: .start)
            try c.encode(end, forKey: .end)
            try c.encode(part, forKey: .part)
        }

        enum CodingKeys: String, CodingKey { case latin, english, start, end, part }
    }

    struct Chant: Codable, Equatable, Sendable {
        var id: String
        var groupID: String
        var latinTitle: String
        var englishTitle: String
        var setting: String?
        var detail: String
        var prayerIDs: [String]
        var duration: Double
        var sourceURL: String
        var audio: Asset
        var score: [ScorePart]
        var lines: [Line]

        enum CodingKeys: String, CodingKey {
            case id, setting, detail, duration, audio, score, lines
            case groupID = "group_id"
            case latinTitle = "latin_title"
            case englishTitle = "english_title"
            case prayerIDs = "prayer_ids"
            case sourceURL = "source_url"
        }

        init(
            id: String, groupID: String, latinTitle: String, englishTitle: String, setting: String?,
            detail: String, prayerIDs: [String], duration: Double, sourceURL: String,
            audio: Asset, score: [ScorePart], lines: [Line]
        ) {
            self.id = id
            self.groupID = groupID
            self.latinTitle = latinTitle
            self.englishTitle = englishTitle
            self.setting = setting
            self.detail = detail
            self.prayerIDs = prayerIDs
            self.duration = duration
            self.sourceURL = sourceURL
            self.audio = audio
            self.score = score
            self.lines = lines
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            groupID = try c.decode(String.self, forKey: .groupID)
            latinTitle = try c.decode(String.self, forKey: .latinTitle)
            englishTitle = try c.decode(String.self, forKey: .englishTitle)
            setting = try c.decodeIfPresent(String.self, forKey: .setting)
            detail = try c.decode(String.self, forKey: .detail)
            prayerIDs = try c.decodeIfPresent([String].self, forKey: .prayerIDs) ?? []
            duration = try c.decode(Double.self, forKey: .duration)
            sourceURL = try c.decode(String.self, forKey: .sourceURL)
            audio = try c.decode(Asset.self, forKey: .audio)
            score = try c.decodeIfPresent([ScorePart].self, forKey: .score) ?? []
            lines = try c.decodeIfPresent([Line].self, forKey: .lines) ?? []
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(groupID, forKey: .groupID)
            try c.encode(latinTitle, forKey: .latinTitle)
            try c.encode(englishTitle, forKey: .englishTitle)
            try c.encode(setting, forKey: .setting)
            try c.encode(detail, forKey: .detail)
            try c.encode(prayerIDs, forKey: .prayerIDs)
            try c.encode(duration, forKey: .duration)
            try c.encode(sourceURL, forKey: .sourceURL)
            try c.encode(audio, forKey: .audio)
            try c.encode(score, forKey: .score)
            try c.encode(lines, forKey: .lines)
        }
    }

    enum CodingKeys: String, CodingKey {
        case version, groups, chants
        case updatedAt = "updated_at"
    }

    init(version: String? = nil, updatedAt: String? = nil, groups: [Group], chants: [Chant]) {
        self.version = version
        self.updatedAt = updatedAt
        self.groups = groups
        self.chants = chants
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(String.self, forKey: .version)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        groups = try c.decode([Group].self, forKey: .groups)
        chants = try c.decode([Chant].self, forKey: .chants)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(version, forKey: .version)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try c.encode(groups, forKey: .groups)
        try c.encode(chants, forKey: .chants)
    }
}

// MARK: - Writing

nonisolated enum LibraryDocumentCoding {
    /// The encoder the export and the kept copies write with: keys sorted
    /// and pretty, so a diff of two versions reads line by line
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}

// MARK: - The Prayer Book in Spanish

/// The Spanish the server lays over the Prayer Book's English
/// (`GET /api/v2/prayer-book?lang=es`, `fields[prayer_book]=version,
/// updated_at,translations`): every prayer the book prints that has a
/// Spanish text, by id. A prayer not listed has no Spanish yet and keeps
/// its English. A server that has no Spanish answers with none, and the
/// book stays English.
nonisolated struct PrayerBookTranslations: Codable, Sendable, Equatable {
    var version: String?
    var updatedAt: String?
    var translations: [Translation]

    nonisolated struct Translation: Codable, Sendable, Equatable {
        let id: String
        let title: String
        /// In the same PrayerText grammar as the book's `english`
        let text: String
        /// Part of its Spanish is the team's own translation
        var aiTranslated: Bool?
        /// Where the prayer comes from, in Spanish (api #269); nil where
        /// the book gives none in Spanish, and then none is shown
        var origin: String?
        /// A long Spanish origin cut short for under the title (api #277),
        /// the whole origin then standing at the foot, as English does;
        /// absent where the origin is short
        var shortCredit: String?
        /// The exact line the Spanish foot shows (api #292): the whole
        /// Spanish origin where the English is a credit, "Según <source>"
        /// where only the Spanish wording's source is, absent where nothing
        /// is owed (the team's own translations)
        var footCredit: String?

        enum CodingKeys: String, CodingKey {
            case id, title, text, origin
            case aiTranslated = "ai_translated"
            case shortCredit = "short_credit"
            case footCredit = "foot_credit"
        }
    }

    /// A novena's Spanish (`fields[prayer_book]=…,novena_translations`, api
    /// docs/JSON_API.md, "The Prayer Book in Spanish"): its names, a title
    /// per day, and its own words by part id. A part naming a prayer takes
    /// that prayer's Spanish from `translations`; a rosary part has no words.
    var novenaTranslations: [NovenaTranslation]

    nonisolated struct NovenaTranslation: Codable, Sendable, Equatable {
        /// The novena's id
        let id: String
        let title: String
        var listTitle: String?
        var detail: String?
        var note: String?
        var origin: String?
        var searchWords: [String]?
        /// One per day, day 1 first
        var dayTitles: [String]?
        var parts: [Part]

        nonisolated struct Part: Codable, Sendable, Equatable {
            /// The part id in the novena's `days`
            let id: String
            var title: String?
            let text: String
        }

        enum CodingKeys: String, CodingKey {
            case id, title, detail, note, origin, parts
            case listTitle = "list_title"
            case searchWords = "search_words"
            case dayTitles = "day_titles"
        }
    }

    /// A topic's Spanish (`fields[prayer_book]=…,chapter_translations`, api
    /// #275): its names, its line, its sub-headings in the English's order
    /// and the words it is looked for by. The numeral and the Latin stay.
    nonisolated struct ChapterTranslation: Codable, Sendable, Equatable {
        let id: String
        let title: String
        var topic: String?
        /// Nil where the English has no line either
        var note: String?
        /// One per sub-heading of the English chapter, in its order
        var sectionTitles: [String]?
        var searchWords: [String]?

        enum CodingKeys: String, CodingKey {
            case id, title, topic, note
            case sectionTitles = "section_titles"
            case searchWords = "search_words"
        }
    }

    var chapterTranslations: [ChapterTranslation] = []

    enum CodingKeys: String, CodingKey {
        case version, translations
        case updatedAt = "updated_at"
        case novenaTranslations = "novena_translations"
        case chapterTranslations = "chapter_translations"
    }

    init(
        version: String? = nil, updatedAt: String? = nil, translations: [Translation] = [],
        novenaTranslations: [NovenaTranslation] = [], chapterTranslations: [ChapterTranslation] = []
    ) {
        self.version = version
        self.updatedAt = updatedAt
        self.translations = translations
        self.novenaTranslations = novenaTranslations
        self.chapterTranslations = chapterTranslations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        translations = try container.decodeIfPresent([Translation].self, forKey: .translations) ?? []
        novenaTranslations =
            try container.decodeIfPresent([NovenaTranslation].self, forKey: .novenaTranslations) ?? []
        // A topic's Spanish that cannot be read leaves the topics in English,
        // never the prayers unread
        chapterTranslations =
            (try? container.decodeIfPresent([ChapterTranslation].self, forKey: .chapterTranslations)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encode(translations, forKey: .translations)
        if !novenaTranslations.isEmpty { try container.encode(novenaTranslations, forKey: .novenaTranslations) }
        if !chapterTranslations.isEmpty { try container.encode(chapterTranslations, forKey: .chapterTranslations) }
    }

    /// The topics' Spanish by chapter id
    var chaptersByID: [String: ChapterTranslation] {
        Dictionary(chapterTranslations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// The novenas' Spanish by novena id
    var novenasByID: [String: NovenaTranslation] {
        Dictionary(novenaTranslations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// The translations by prayer id
    var byID: [String: Translation] {
        Dictionary(translations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
}

// MARK: - The Chant Library's Spanish

/// The chant library's names in Spanish, as `GET /api/v2/chant-library
/// ?lang=es` sends its `translations` (api PR #261): each chant's title
/// (standing for its English title) and setting, and each section's
/// title, by id. The Latin, the sung words and the files stay the
/// English document's. Kept with a version of its own, apart from it.
nonisolated struct ChantLibraryTranslations: Codable, Sendable, Equatable {
    var version: String?
    var updatedAt: String?
    var translations: Names

    nonisolated struct Names: Codable, Sendable, Equatable {
        var chants: [ChantName]
        var groups: [GroupName]

        init(chants: [ChantName] = [], groups: [GroupName] = []) {
            self.chants = chants
            self.groups = groups
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            chants = try container.decodeIfPresent([ChantName].self, forKey: .chants) ?? []
            groups = try container.decodeIfPresent([GroupName].self, forKey: .groups) ?? []
        }
    }

    nonisolated struct ChantName: Codable, Sendable, Equatable {
        let id: String
        let title: String
        /// Nil exactly where the English setting is nil
        var setting: String?
    }

    nonisolated struct GroupName: Codable, Sendable, Equatable {
        let id: String
        let title: String
        /// When the section is sung, in Spanish; nil where the English
        /// has none
        var note: String? = nil
        /// The section's parts in the English parts' order, each its
        /// heading and note in Spanish (nil where the English is); empty
        /// where the parts have no words
        var parts: [PartName] = []

        init(id: String, title: String, note: String? = nil, parts: [PartName] = []) {
            self.id = id
            self.title = title
            self.note = note
            self.parts = parts
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            title = try container.decode(String.self, forKey: .title)
            note = try container.decodeIfPresent(String.self, forKey: .note)
            parts = (try? container.decodeIfPresent([PartName].self, forKey: .parts)) ?? []
        }

        enum CodingKeys: String, CodingKey { case id, title, note, parts }
    }

    nonisolated struct PartName: Codable, Sendable, Equatable {
        var title: String?
        var note: String?
    }

    enum CodingKeys: String, CodingKey {
        case version, translations
        case updatedAt = "updated_at"
    }

    init(version: String? = nil, updatedAt: String? = nil, translations: Names = Names()) {
        self.version = version
        self.updatedAt = updatedAt
        self.translations = translations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        // An empty list arrives as [] rather than an object
        translations = (try? container.decodeIfPresent(Names.self, forKey: .translations)) ?? Names()
    }

    var chantsByID: [String: ChantName] {
        Dictionary(translations.chants.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    var groupsByID: [String: GroupName] {
        Dictionary(translations.groups.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Each chant's names with the Spanish laid over by id; a chant or a
    /// section with no Spanish keeps its English
    func laidOver(_ document: ChantLibraryDocument) -> ChantLibraryDocument {
        let chants = chantsByID
        let groups = groupsByID
        guard !chants.isEmpty || !groups.isEmpty else { return document }
        var spanish = document
        spanish.chants = document.chants.map { chant in
            guard let name = chants[chant.id] else { return chant }
            var chant = chant
            chant.englishTitle = name.title
            if chant.setting != nil, let setting = name.setting { chant.setting = setting }
            return chant
        }
        spanish.groups = document.groups.map { group in
            guard let name = groups[group.id] else { return group }
            var group = group
            group.title = name.title
            if let note = name.note, group.note != nil { group.note = note }
            // By position, the server's parts in the English parts' order
            for (index, part) in name.parts.enumerated() where group.parts.indices.contains(index) {
                if let title = part.title, group.parts[index].title != nil { group.parts[index].title = title }
                if let note = part.note, group.parts[index].note != nil { group.parts[index].note = note }
            }
            return group
        }
        return spanish
    }
}

// MARK: - The Consecration's Spanish

/// The Consecration in Spanish, as `GET /api/v2/consecration?lang=es` sends
/// its `translations` (api docs/JSON_API.md, "The Consecration in
/// Spanish"): the days and prayers that have Spanish, keyed as the bundled
/// English keys them (a day by its number, a reading by its order, a prayer
/// by its id), with `ai_translated` on the team's own translation. The
/// phases' and the feasts' names are the app's own words, in the String
/// Catalog, so they are not read from here. Kept with a version of its own,
/// apart from the English, which stays bundled.
nonisolated struct ConsecrationTranslations: Codable, Sendable, Equatable {
    var version: String?
    var updatedAt: String?
    var days: [Day]
    var prayers: [Prayer]

    nonisolated struct Day: Codable, Sendable, Equatable {
        let number: Int
        let title: String?
        let journalPrompt: String?
        var readings: [Reading]
        /// The title and the journal question are the team's translation
        var aiTranslated: Bool?

        enum CodingKeys: String, CodingKey {
            case number, title, readings
            case journalPrompt = "journal_prompt"
            case aiTranslated = "ai_translated"
        }

        init(number: Int, title: String?, journalPrompt: String?, readings: [Reading] = [], aiTranslated: Bool? = nil) {
            self.number = number
            self.title = title
            self.journalPrompt = journalPrompt
            self.readings = readings
            self.aiTranslated = aiTranslated
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            number = try container.decode(Int.self, forKey: .number)
            title = try container.decodeIfPresent(String.self, forKey: .title)
            journalPrompt = try container.decodeIfPresent(String.self, forKey: .journalPrompt)
            readings = try container.decodeIfPresent([Reading].self, forKey: .readings) ?? []
            aiTranslated = try container.decodeIfPresent(Bool.self, forKey: .aiTranslated)
        }
    }

    nonisolated struct Reading: Codable, Sendable, Equatable {
        let order: Int
        /// The Spanish citation
        let title: String
        /// In the same ReadingText grammar as the English
        let text: String
        /// The Spanish edition ("Biblia de Torres Amat")
        let source: String?
        var aiTranslated: Bool?

        enum CodingKeys: String, CodingKey {
            case order, title, text, source
            case aiTranslated = "ai_translated"
        }
    }

    nonisolated struct Prayer: Codable, Sendable, Equatable {
        let id: String
        let title: String
        /// In the PrayerText grammar the English uses
        let text: String
        var aiTranslated: Bool?

        enum CodingKeys: String, CodingKey {
            case id, title, text
            case aiTranslated = "ai_translated"
        }
    }

    private nonisolated struct Sections: Codable, Sendable {
        var days: [Day]?
        var prayers: [Prayer]?
    }

    enum CodingKeys: String, CodingKey {
        case version, translations
        case updatedAt = "updated_at"
    }

    init(version: String? = nil, updatedAt: String? = nil, days: [Day] = [], prayers: [Prayer] = []) {
        self.version = version
        self.updatedAt = updatedAt
        self.days = days
        self.prayers = prayers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        let sections = try container.decodeIfPresent(Sections.self, forKey: .translations)
        days = sections?.days ?? []
        prayers = sections?.prayers ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encode(Sections(days: days, prayers: prayers), forKey: .translations)
    }

    /// The days by number
    var dayByNumber: [Int: Day] {
        Dictionary(days.map { ($0.number, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// The prayers by id
    var prayerByID: [String: Prayer] {
        Dictionary(prayers.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
