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

    struct Prayer: Codable, Equatable, Sendable {
        var id: String
        var title: String
        var latinTitle: String?
        var origin: String?
        var note: String?
        var english: String
        var latin: String?
        var listTitle: String?
        var englishName: String?
        var searchWords: [String]

        enum CodingKeys: String, CodingKey {
            case id, title, origin, note, english, latin
            case latinTitle = "latin_title"
            case listTitle = "list_title"
            case englishName = "english_name"
            case searchWords = "search_words"
        }

        init(
            id: String, title: String, latinTitle: String?, origin: String?, note: String?,
            english: String, latin: String?, listTitle: String?, englishName: String?, searchWords: [String]
        ) {
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
        case version, prayers, chapters
        case updatedAt = "updated_at"
    }

    init(version: String? = nil, updatedAt: String? = nil, prayers: [Prayer], chapters: [Chapter]) {
        self.version = version
        self.updatedAt = updatedAt
        self.prayers = prayers
        self.chapters = chapters
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(String.self, forKey: .version)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        prayers = try c.decode([Prayer].self, forKey: .prayers)
        chapters = try c.decode([Chapter].self, forKey: .chapters)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(version, forKey: .version)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try c.encode(prayers, forKey: .prayers)
        try c.encode(chapters, forKey: .chapters)
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
