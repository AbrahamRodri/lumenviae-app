//
//  NovenaDocument.swift
//  Lumen Viae
//
//  The Prayer Book document's `novenas` section, as the server serves it
//  (docs/JSON_API.md, "`novenas`"): days of prayer said one a day. Only a
//  build that names `novenas` in `fields[prayer_book]` receives it; every
//  older build shows each novena's twin, an ordinary prayer holding the
//  whole novena as text.
//
//  Decoded leniently: the optional fields may be missing, and a feast or
//  art block that does not read leaves that field nil rather than failing
//  the book.
//

import Foundation

extension PrayerBookDocument {
    nonisolated struct Novena: Codable, Equatable, Sendable, Identifiable {
        /// Stable forever: progress on the phone is kept by it
        var id: String
        var title: String
        var listTitle: String?
        var latinTitle: String?
        /// One sentence for its card
        var detail: String
        var note: String?
        var origin: String?
        /// The twin: one of `prayers` holding every day as plain text,
        /// shown in the novena's place by a build that knows novenas
        var prayerID: String
        var chapterID: String
        /// The number of days, usually 9; never assume 9
        var length: Int
        /// The feast it ends on; nil when it may be begun on any day
        var feast: Feast?
        /// The name the app bundles its painting under
        var painting: String?
        var art: Art?
        var chantIDs: [String]
        var searchWords: [String]
        var days: [Day]

        enum CodingKeys: String, CodingKey {
            case id, title, detail, note, origin, length, feast, painting, art, days
            case listTitle = "list_title"
            case latinTitle = "latin_title"
            case prayerID = "prayer_id"
            case chapterID = "chapter_id"
            case chantIDs = "chant_ids"
            case searchWords = "search_words"
        }

        init(
            id: String, title: String, listTitle: String? = nil, latinTitle: String? = nil, detail: String,
            note: String? = nil, origin: String? = nil, prayerID: String, chapterID: String, length: Int,
            feast: Feast? = nil, painting: String? = nil, art: Art? = nil, chantIDs: [String] = [],
            searchWords: [String] = [], days: [Day]
        ) {
            self.id = id
            self.title = title
            self.listTitle = listTitle
            self.latinTitle = latinTitle
            self.detail = detail
            self.note = note
            self.origin = origin
            self.prayerID = prayerID
            self.chapterID = chapterID
            self.length = length
            self.feast = feast
            self.painting = painting
            self.art = art
            self.chantIDs = chantIDs
            self.searchWords = searchWords
            self.days = days
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            title = try c.decode(String.self, forKey: .title)
            listTitle = try c.decodeIfPresent(String.self, forKey: .listTitle)
            latinTitle = try c.decodeIfPresent(String.self, forKey: .latinTitle)
            detail = try c.decodeIfPresent(String.self, forKey: .detail) ?? ""
            note = try c.decodeIfPresent(String.self, forKey: .note)
            origin = try c.decodeIfPresent(String.self, forKey: .origin)
            prayerID = try c.decode(String.self, forKey: .prayerID)
            chapterID = try c.decode(String.self, forKey: .chapterID)
            days = try c.decode([Day].self, forKey: .days)
            length = try c.decodeIfPresent(Int.self, forKey: .length) ?? days.count
            feast = try? c.decodeIfPresent(Feast.self, forKey: .feast)
            painting = try c.decodeIfPresent(String.self, forKey: .painting)
            art = try? c.decodeIfPresent(Art.self, forKey: .art)
            chantIDs = try c.decodeIfPresent([String].self, forKey: .chantIDs) ?? []
            searchWords = try c.decodeIfPresent([String].self, forKey: .searchWords) ?? []
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(title, forKey: .title)
            try c.encode(listTitle, forKey: .listTitle)
            try c.encode(latinTitle, forKey: .latinTitle)
            try c.encode(detail, forKey: .detail)
            try c.encode(note, forKey: .note)
            try c.encode(origin, forKey: .origin)
            try c.encode(prayerID, forKey: .prayerID)
            try c.encode(chapterID, forKey: .chapterID)
            try c.encode(length, forKey: .length)
            try c.encode(feast, forKey: .feast)
            try c.encode(painting, forKey: .painting)
            try c.encode(art, forKey: .art)
            try c.encode(chantIDs, forKey: .chantIDs)
            try c.encode(searchWords, forKey: .searchWords)
            try c.encode(days, forKey: .days)
        }

        /// The day numbered `number`, 1 to `length`
        func day(_ number: Int) -> Day? {
            days.first { $0.number == number }
        }
    }

    /// The feast a novena ends on, in the chant library's rule shape:
    /// `fixed` with a month and day, or `easter` with days from Easter
    nonisolated struct Feast: Codable, Equatable, Sendable {
        var kind: String
        var month: Int?
        var day: Int?
        var daysFromEaster: Int?

        enum CodingKeys: String, CodingKey {
            case kind, month, day
            case daysFromEaster = "days_from_easter"
        }
    }

    nonisolated struct Art: Codable, Equatable, Sendable {
        var url: String
        var bytes: Int?
        var sha256: String?
        var credit: String?
    }

    nonisolated struct Day: Codable, Equatable, Sendable {
        var number: Int
        var title: String
        var parts: [Part]
    }

    /// One part of a day: a book prayer (`prayerID`, said `times` times),
    /// the day's own words (`text`, with its `id`), or, for `kind`
    /// `rosary`, the decades of the day's mysteries prayed at that point
    nonisolated struct Part: Codable, Equatable, Sendable {
        /// `opening`, `meditation`, `novena_prayer`, `invocation`, `saying`,
        /// `closing`, `rosary`, and more may come: an unknown kind is shown
        /// as plain text
        var kind: String
        var prayerID: String?
        var times: Int?
        /// Words said every day keep one id on every day, so a place is
        /// `(day, id)`, never the id alone
        var id: String?
        var title: String?
        var text: String?
        var source: String?
        var decades: [Int]?

        enum CodingKeys: String, CodingKey {
            case kind, times, id, title, text, source, decades
            case prayerID = "prayer_id"
        }

        init(
            kind: String, prayerID: String? = nil, times: Int? = nil, id: String? = nil, title: String? = nil,
            text: String? = nil, source: String? = nil, decades: [Int]? = nil
        ) {
            self.kind = kind
            self.prayerID = prayerID
            self.times = times
            self.id = id
            self.title = title
            self.text = text
            self.source = source
            self.decades = decades
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(kind, forKey: .kind)
            try c.encode(prayerID, forKey: .prayerID)
            try c.encode(times, forKey: .times)
            try c.encode(id, forKey: .id)
            try c.encode(title, forKey: .title)
            try c.encode(text, forKey: .text)
            try c.encode(source, forKey: .source)
            try c.encode(decades, forKey: .decades)
        }

        var isRosary: Bool { kind == "rosary" }
    }
}
