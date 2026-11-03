//
//  PrayerBook.swift
//  Lumen Viae
//
//  The Prayer Book: the Church's common prayers, kept by the server and
//  shipped in the app so they pray with no signal (`LibraryContent`),
//  gathered two ways at once — into chapters, as a
//  printed prayer book is bound, and into orders of prayer, the few
//  prayers a Catholic says together at one moment of the day or of the
//  week (on rising, at the Angelus bell, before Mass, after
//  Confession). The book opens on the order for the hour it is.
//
//  Every prayer's text is written in the small grammar `PrayerText`
//  reads (DesignSystem/ReadingText): ℣ ℟ ✠ in red, a litany's response
//  stated once at the head of each group, canticles pointed with ` * `,
//  "[Let us pray.]" in brackets as a rubric, prose one line per
//  paragraph. English always; Latin where the Church prays it in Latin,
//  never invented for a prayer composed in English. Where there is
//  Latin, the two pair line for line, blank lines included.
//

import Foundation

// MARK: - BookPrayer

/// One prayer of the book.
struct BookPrayer: Identifiable, Hashable {
    let id: String
    let title: String

    /// The prayer's name in the Church's own tongue — "Sub tuum
    /// præsidium" — or nil for one composed in English
    let latinTitle: String?

    /// Who wrote it and when, as a prayer book's small print — "St
    /// Bernard of Clairvaux · 12th century"
    let origin: String?

    /// When or how it is said, in one plain sentence
    let note: String?

    let english: String

    /// Nil when the prayer has no Latin of its own
    let latin: String?

    var hasLatin: Bool { latin != nil }

    /// The prayer's name in a list, as most people say it — "Hail Mary",
    /// "St Michael" — where its own page keeps the full title ("The Hail
    /// Mary", "Prayer to Saint Michael")
    var listTitle: String { PrayerBook.listTitles[id] ?? title }

    /// Other names it is looked for by — "Salve Regina", "Litany of
    /// Loreto" — beside its title and Latin title
    var searchWords: [String] { PrayerBook.prayerSearchWords[id] ?? [] }

    /// The line set small beneath its name: its Latin, only where the
    /// prayer goes by that name (`PrayerBook.latinNamesKnown`), or, for
    /// the one titled in Latin ("Memorare"), its English. A Latin that
    /// only translates the title ("Actus Fidei") stays for search and is
    /// not drawn. Never the name said twice, whatever its case or
    /// article: "Tantum Ergo" once stood over "Tantum ergo".
    var secondTitle: String? {
        if let english = PrayerBook.englishNames[id] { return english }
        guard let latinTitle, PrayerBook.latinNamesKnown.contains(id),
              !PrayerBook.isSameName(latinTitle, title)
        else { return nil }
        return latinTitle
    }

    /// The text as the page sets it in `language`. A prayer with no
    /// Latin is English in every mode — the bilingual modes would only
    /// pair it with nothing.
    func content(for language: PrayerLanguage) -> String {
        guard let latin else { return english }
        return BilingualText(english: english, latin: latin).formatted(for: language)
    }

    static func == (lhs: BookPrayer, rhs: BookPrayer) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension BookPrayer {

    /// A prayer the app already carries — the Rosary's, the
    /// consecration's — set in the book with its own small print, so
    /// the Memorare prayed after a Rosary and the Memorare in the book
    /// are the same words.
    static func bundled(
        _ id: String,
        title: String? = nil,
        origin: String?,
        note: String?
    ) -> BookPrayer? {
        guard let prayer = DevotionPrayers.find(id) else { return nil }
        return BookPrayer(
            id: id,
            title: title ?? prayer.englishTitle,
            latinTitle: prayer.latinTitle,
            origin: origin,
            note: note,
            english: prayer.content.english,
            latin: prayer.content.latin
        )
    }
}

// MARK: - PrayerBookChapter

/// A topic of the book. The topics follow the order of *Blessed Be God*
/// (Callan and McHugh, 1925): the day's prayers first, then the
/// sacraments, God, Our Lady and the saints, the Church's year, and
/// prayers for others and in need. Each is headed by a painting of its
/// own (`PrayerBookPainting.topic`) and printed under the book's own
/// sub-headings. Called a chapter in code, as the book was first bound.
struct PrayerBookChapter: Identifiable, Hashable {
    let id: String
    let numeral: String
    let title: String
    let latinTitle: String
    let icon: String

    /// Which part of the book it stands in, a shelf on the Prayers page
    let part: PrayerBookPart

    /// One italic line under the topic's name, only where the name does
    /// not say what the topic holds
    let epigraph: String?

    /// Its prayers under the book's sub-headings ("Before Mass", "At
    /// Communion"). A prayer may stand in more than one topic, and in more
    /// than one section — the Hail, Holy Queen is said after Mass and is
    /// one of the Church's songs to Mary.
    let sections: [PrayerBookSection]

    /// The orders of prayer said together that belong here — Before Mass
    /// and After Communion in Holy Mass and Communion — set at the head of
    /// the topic's page, since the page they once had to themselves (For
    /// an Occasion) is gone
    var orderIDs: [String] = []

    /// The topic named when a search finds it: "Prayers to Mary", where
    /// its own page says "The Blessed Virgin"
    var topic: String = ""

    /// The other words a reader might look for the topic by — the older
    /// names the book once printed ("Our Lady", "the Holy Ghost",
    /// "Penance") among them, so a reader who knew them still finds it
    var searchWords: [String] = []

    /// Every prayer the topic prints, each once, in the order printed
    let prayerIDs: [String]

    init(
        id: String,
        numeral: String,
        title: String,
        latinTitle: String,
        icon: String,
        part: PrayerBookPart,
        epigraph: String? = nil,
        sections: [PrayerBookSection],
        orderIDs: [String] = [],
        topic: String = "",
        searchWords: [String] = []
    ) {
        self.id = id
        self.numeral = numeral
        self.title = title
        self.latinTitle = latinTitle
        self.icon = icon
        self.part = part
        self.epigraph = epigraph
        self.sections = sections
        self.orderIDs = orderIDs
        self.topic = topic
        self.searchWords = searchWords
        var seen = Set<String>()
        prayerIDs = sections.flatMap(\.prayerIDs).filter { seen.insert($0).inserted }
    }

    var prayers: [BookPrayer] { prayerIDs.compactMap { PrayerBook.prayer($0) } }

    var orders: [PrayerOrder] { orderIDs.compactMap { PrayerBook.order($0) } }

    static func == (lhs: PrayerBookChapter, rhs: PrayerBookChapter) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// One of a topic's sub-headings and the prayers printed under it
struct PrayerBookSection: Hashable {
    let title: String
    let prayerIDs: [String]

    var prayers: [BookPrayer] { prayerIDs.compactMap { PrayerBook.prayer($0) } }
}

/// The five parts of the book the topics are gathered into, each a
/// sideways shelf on the Prayers page
enum PrayerBookPart: String, CaseIterable, Identifiable {
    case everyDay
    case sacraments
    case god
    case year
    case others

    var id: String { rawValue }

    var title: String {
        switch self {
        case .everyDay:   return String(
            localized: "Every Day",
            comment: "Prayers tab: the heading of one of the five shelves the prayer topics are gathered into"
        )
        case .sacraments: return String(
            localized: "The Sacraments",
            comment: "Prayers tab: the heading of one of the five shelves the prayer topics are gathered into"
        )
        case .god:        return String(
            localized: "God, Our Lady and the Saints",
            comment: "Prayers tab: the heading of one of the five shelves the prayer topics are gathered into"
        )
        case .year:       return String(
            localized: "Through the Year",
            comment: "Prayers tab: the heading of one of the five shelves the prayer topics are gathered into"
        )
        case .others:     return String(
            localized: "For Others, and in Need",
            comment: "Prayers tab: the heading of one of the five shelves the prayer topics are gathered into"
        )
        }
    }

    var chapters: [PrayerBookChapter] { PrayerBook.chapters.filter { $0.part == self } }
}

// MARK: - PrayerOrder

/// A few prayers said together, one after another — on rising, before
/// Mass, after Confession. Prayed through in one motion on the
/// pray-along screen, and on the rule of prayer as a single act.
struct PrayerOrder: Identifiable, Hashable {
    let id: String
    let title: String
    let latinTitle: String
    let icon: String

    /// When it is prayed, as a kicker — "ON WAKING"
    let occasion: String

    /// One italic line saying what the order is. No page draws it now;
    /// kept as the order's description
    let detail: String

    /// Its prayers on a given day. Most never change; the Angelus gives
    /// way to Queen of Heaven (the Regina Cæli) in the Easter season, and
    /// Night Prayers close on the season's song to Mary.
    let prayerIDs: (Date) -> [String]

    func prayers(on date: Date = Date()) -> [BookPrayer] {
        prayerIDs(date).compactMap { PrayerBook.prayer($0) }
    }

    /// The order's name on a given day — the Angelus is Queen of Heaven
    /// (the Regina Cæli) in the Easter season, and says so
    func title(on date: Date = Date()) -> String {
        if id == PrayerBook.angelusOrderID, PrayerBook.isEastertide(date) {
            return String(
                localized: "Queen of Heaven",
                comment: "Prayers tab: the Angelus's name in the Easter season, when the Regina Caeli is said in its place"
            )
        }
        return title
    }

    /// Other names the order is looked for by — the visit was "A Visit
    /// to the Blessed Sacrament" before it was "Visiting Jesus in Church"
    var searchWords: [String] { PrayerBook.orderSearchWords[id] ?? [] }

    static func == (lhs: PrayerOrder, rhs: PrayerOrder) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - The season's song to Mary

/// The four songs to Mary (the antiphons of Our Lady), each sung at the
/// close of the day through its own part of the year — the last words
/// of the Church's Bedtime Prayer (Compline), and so the last words of
/// Night Prayers here.
enum MarianAntiphon: CaseIterable {
    case almaRedemptoris
    case aveReginaCaelorum
    case reginaCaeli
    case salveRegina

    /// Its name in English, as the lists say it — "Hail, Holy Queen"
    var name: String {
        switch self {
        case .almaRedemptoris:   return String(
            localized: "Loving Mother of the Redeemer",
            comment: "Prayers tab: the English name of one of the four seasonal songs to Mary (antiphons of Our Lady); its Latin name stands beside it"
        )
        case .aveReginaCaelorum: return String(
            localized: "Hail, Queen of Heaven",
            comment: "Prayers tab: the English name of one of the four seasonal songs to Mary (antiphons of Our Lady); its Latin name stands beside it"
        )
        case .reginaCaeli:       return String(
            localized: "Queen of Heaven",
            comment: "Prayers tab: the English name of one of the four seasonal songs to Mary (antiphons of Our Lady); its Latin name stands beside it"
        )
        case .salveRegina:       return String(
            localized: "Hail, Holy Queen",
            comment: "Prayers tab: the English name of one of the four seasonal songs to Mary (antiphons of Our Lady); its Latin name stands beside it"
        )
        }
    }

    /// Its name as it is sung, the first words of its Latin, set beside
    /// the English and never alone
    var latinName: String {
        switch self {
        case .almaRedemptoris:   return "Alma Redemptoris Mater"
        case .aveReginaCaelorum: return "Ave Regina Cælorum"
        case .reginaCaeli:       return "Regina Cæli"
        case .salveRegina:       return "Salve Regina"
        }
    }

    var prayerID: String {
        switch self {
        case .almaRedemptoris:   return "alma_redemptoris"
        case .aveReginaCaelorum: return "ave_regina_caelorum"
        case .reginaCaeli:       return "regina_caeli"
        case .salveRegina:       return "hail_holy_queen"
        }
    }

    /// The part of the year it keeps, in plain dates: February 2 is
    /// Candlemas (the Purification), and Pentecost stands for the Trinity
    /// Sunday a week after it, where the Salve Regina's season begins
    var season: String {
        switch self {
        case .almaRedemptoris:   return String(
            localized: "Advent to February 2",
            comment: "Prayers tab: the part of the year a seasonal song to Mary is sung, in plain dates (February 2 is Candlemas)"
        )
        case .aveReginaCaelorum: return String(
            localized: "February 2 to Holy Week",
            comment: "Prayers tab: the part of the year a seasonal song to Mary is sung, in plain dates (February 2 is Candlemas)"
        )
        case .reginaCaeli:       return String(
            localized: "Easter to Pentecost",
            comment: "Prayers tab: the part of the year a seasonal song to Mary is sung, in plain dates (February 2 is Candlemas)"
        )
        case .salveRegina:       return String(
            localized: "Pentecost to Advent",
            comment: "Prayers tab: the part of the year a seasonal song to Mary is sung, in plain dates (February 2 is Candlemas)"
        )
        }
    }
}

// MARK: - PrayerBook

enum PrayerBook {

    // MARK: Prayers

    /// Every prayer of the book, by id, from the book's document
    /// (`LibraryContent.prayerBook`): the server keeps the words, the
    /// Rosary's and the consecration's prayers among them, and the app
    /// ships a copy.
    static let prayers: [String: BookPrayer] = Dictionary(
        LibraryContent.prayerBook.prayers.map { prayer in
            (prayer.id, inSpanish(BookPrayer(
                id: prayer.id, title: prayer.title, latinTitle: prayer.latinTitle,
                origin: prayer.origin, note: prayer.note, english: prayer.english, latin: prayer.latin
            )))
        },
        uniquingKeysWith: { first, _ in first }
    )

    // MARK: In Spanish

    /// The prayer as a Spanish app sets it: the server's Spanish for the
    /// book (`LibraryContent.prayerBookSpanish`), else the Rosary's own
    /// bundled Spanish for a prayer the Rosary says, in English's place
    /// beside the same Latin. A prayer with neither keeps its English, whole.
    static func inSpanish(
        _ prayer: BookPrayer,
        translations: [String: PrayerBookTranslations.Translation] = LibraryContent.prayerBookSpanish,
        spanish: Bool = SpanishContent.isActive
    ) -> BookPrayer {
        guard spanish else { return prayer }
        let spanishWords: (title: String, text: String)?
        if let translation = translations[prayer.id] {
            spanishWords = (translation.title, translation.text)
        } else if let rosary = SpanishContent.prayers[prayer.id] {
            spanishWords = (rosary.title, rosary.lines)
        } else {
            spanishWords = nil
        }
        guard let spanishWords else { return prayer }
        return BookPrayer(
            id: prayer.id, title: spanishWords.title, latinTitle: prayer.latinTitle,
            origin: prayer.origin, note: prayer.note, english: spanishWords.text, latin: prayer.latin
        )
    }

    /// Whether the prayer is shown in Spanish this launch: its English list
    /// name and English second title then stand down, so no line mixes the two
    static func isInSpanish(_ id: String) -> Bool {
        SpanishContent.isActive && (LibraryContent.prayerBookSpanish[id] != nil || SpanishContent.prayers[id] != nil)
    }

    static func prayer(_ id: String) -> BookPrayer? { prayers[id] }

    // MARK: Chapters

    /// The book's topics, in its order: the words from the document, and
    /// how the app sets each (its glyph, its shelf, its orders of prayer)
    /// from `layouts`
    static let chapters: [PrayerBookChapter] = LibraryContent.prayerBook.chapters.map { chapter in
        let layout = layouts[chapter.id] ?? ChapterLayout(icon: "lv-prayer-book", part: .others)
        return PrayerBookChapter(
            id: chapter.id, numeral: chapter.numeral, title: chapter.title, latinTitle: chapter.latinTitle,
            icon: layout.icon, part: layout.part, epigraph: chapter.note,
            sections: chapter.sections.map { PrayerBookSection(title: $0.title, prayerIDs: $0.prayerIDs) },
            orderIDs: layout.orderIDs, topic: chapter.topic ?? "", searchWords: chapter.searchWords
        )
    }

    /// How the app sets a topic: not words, so not the server's. A topic
    /// the server adds that the app does not know yet stands on the last
    /// shelf under the book's own glyph.
    struct ChapterLayout {
        let icon: String
        let part: PrayerBookPart
        var orderIDs: [String] = []
    }

    static let layouts: [String: ChapterLayout] = [
        "first": ChapterLayout(icon: "ch-praying-hands", part: .everyDay),
        "day": ChapterLayout(icon: "lv-hourglass", part: .everyDay, orderIDs: ["morning", "angelus", "night", "table"]),
        "short": ChapterLayout(icon: "lv-dart", part: .everyDay),
        "mass": ChapterLayout(icon: "ch-altar", part: .sacraments, orderIDs: ["before_mass", "after_mass"]),
        "penance": ChapterLayout(icon: "ch-keys", part: .sacraments, orderIDs: ["before_confession", "after_confession"]),
        "sacrament": ChapterLayout(icon: "ch-monstrance", part: .sacraments, orderIDs: ["visit"]),
        "holy_ghost": ChapterLayout(icon: "ch-dove", part: .god),
        "our_lord": ChapterLayout(icon: "ch-chi-rho", part: .god),
        "our_lady": ChapterLayout(icon: "ch-lily", part: .god),
        "st_joseph": ChapterLayout(icon: "lv-saint", part: .god),
        "saints": ChapterLayout(icon: "lv-saint", part: .god),
        "seasons": ChapterLayout(icon: "ch-window", part: .year),
        "thanks": ChapterLayout(icon: "lv-wheat", part: .year),
        "litanies": ChapterLayout(icon: "lv-procession-cross", part: .year),
        "church": ChapterLayout(icon: "ch-church", part: .others),
        "sick": ChapterLayout(icon: "ch-chalice", part: .others),
        "departed": ChapterLayout(icon: "ch-candle", part: .others, orderIDs: ["holy_souls"]),
        "needs": ChapterLayout(icon: "lv-stella-maris", part: .others, orderIDs: ["trouble"]),
    ]

    /// How many prayers the book holds, each counted once, however many
    /// chapters print it — "152 prayers" under the page's title
    static let prayerCount = Set(chapters.flatMap(\.prayerIDs)).count

    static func chapter(_ id: String) -> PrayerBookChapter? { chaptersByID[id] }

    private static let chaptersByID: [String: PrayerBookChapter] =
        Dictionary(chapters.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    /// A prayer's home in the book: the topic named for it in `homes`, or
    /// else the first topic that prints it. Its page is headed by it, steps
    /// along it, and search names it.
    static func homeChapter(of prayerID: String) -> PrayerBookChapter? {
        homeChapterIDs[prayerID].flatMap { chapter($0) }
    }

    /// Each prayer's home topic, by prayer id, worked out once
    private static let homeChapterIDs: [String: String] = {
        var home: [String: String] = [:]
        for chapter in chapters {
            for id in chapter.prayerIDs where home[id] == nil {
                home[id] = chapter.id
            }
        }
        for (prayerID, chapterID) in homes where chapter(chapterID)?.prayerIDs.contains(prayerID) == true {
            home[prayerID] = chapterID
        }
        return home
    }()

    /// Prayers printed in more than one topic whose home is not the first
    /// of them. The topics follow Blessed Be God, so Daily Prayers and Holy
    /// Mass come before Mary and the saints; without these, the Hail, Holy
    /// Queen would be headed Holy Mass and Communion.
    static let homes: [String: String] = [
        "angele_dei": "saints",
        "angelus": "our_lady",
        "regina_caeli": "our_lady",
        "miraculous_medal": "our_lady",
        "mary_after_communion": "our_lady",
        "hail_holy_queen": "our_lady",
        "requiem_aeternam": "departed",
        "st_gertrude": "departed",
        "come_holy_ghost": "holy_ghost",
        "spiritual_communion": "sacrament",
        "anima_christi": "our_lord",
        "en_ego": "our_lord",
        "suscipe": "our_lord",
        "st_michael_prayer": "saints",
        "st_patrick_breastplate": "saints",
        "st_francis_before_crucifix": "saints",
        "rosary_closing_prayer": "church",
        "te_deum": "thanks",
    ]

    /// Our Lady's topic. The book's document always has it (a copy without
    /// it is refused, `PrayerBookDocument.namedChapterIDs`); an empty one
    /// stands in should it ever not
    static var ourLady: PrayerBookChapter {
        chapter("our_lady")
            ?? PrayerBookChapter(
                id: "our_lady", numeral: "", title: "The Blessed Virgin", latinTitle: "",
                icon: "ch-lily", part: .god, sections: [])
    }

    // MARK: Orders

    static let morningOrderID = "morning"
    static let angelusOrderID = "angelus"
    static let nightOrderID = "night"

    static let orders: [PrayerOrder] = [
        PrayerOrder(
            id: morningOrderID,
            title: String(
                localized: "Morning Prayers",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "Preces Matutinæ",
            icon: "lv-rooster",
            occasion: String(
                localized: "On waking",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "A few short prayers on waking, giving the day to God.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { _ in
                ["sign_of_cross", "morning_offering", "our_father", "hail_mary", "glory_be",
                 "act_of_faith", "act_of_hope", "act_of_charity", "angele_dei"]
            }
        ),
        PrayerOrder(
            id: angelusOrderID,
            title: String(
                localized: "The Angelus",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "Angelus Domini",
            icon: "lv-bell",
            occasion: String(
                localized: "6 AM, noon and 6 PM",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "Remembering how God's Son became man, said three times a day when the church bell rings.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { date in [isEastertide(date) ? "regina_caeli" : "angelus"] }
        ),
        PrayerOrder(
            id: nightOrderID,
            title: String(
                localized: "Night Prayers",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "Preces Vespertinæ",
            icon: "lv-lamp",
            occasion: String(
                localized: "At bedtime",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "Look back on the day, ask God's forgiveness, and end with a song to Mary.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { date in
                ["sign_of_cross", "examen", "act_of_contrition", "in_manus_tuas",
                 "visita_quaesumus", antiphon(on: date).prayerID]
            }
        ),
        PrayerOrder(
            id: "table",
            title: String(
                localized: "At Meals",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "Benedictio Mensæ",
            icon: "ch-bread",
            occasion: String(
                localized: "Before and after meals",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "Grace before the meal, and thanks when it is done.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { _ in ["grace_before", "grace_after"] }
        ),
        PrayerOrder(
            id: "before_mass",
            title: String(
                localized: "Before Mass",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "Præparatio ad Missam",
            icon: "ch-altar",
            occasion: String(
                localized: "In the pew",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "Prayers to get ready for Mass: for light, a ready heart, and faith, hope and love.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { _ in
                ["sign_of_cross", "come_holy_ghost", "aquinas_before_mass",
                 "act_of_faith", "act_of_hope", "act_of_charity"]
            }
        ),
        PrayerOrder(
            id: "after_mass",
            title: String(
                localized: "After Communion",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "Gratiarum Actio",
            icon: "ch-chalice",
            occasion: String(
                localized: "After Mass",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "Prayers of thanks for the minutes after you receive Communion.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { _ in
                ["anima_christi", "en_ego", "aquinas_after_mass", "mary_after_communion", "suscipe"]
            }
        ),
        PrayerOrder(
            id: "before_confession",
            title: String(
                localized: "Before Confession",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "Ante Confessionem",
            icon: "ch-keys",
            occasion: String(
                localized: "Before going in",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "Ask for light, go through the Ten Commandments, and be sorry for your sins.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { _ in
                ["sign_of_cross", "come_holy_ghost", "before_confession",
                 "examination_of_conscience", "act_of_contrition", "the_confession"]
            }
        ),
        PrayerOrder(
            id: "after_confession",
            title: String(
                localized: "After Confession",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "Post Confessionem",
            icon: "ch-keys",
            occasion: String(
                localized: "Kneeling afterwards",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "Say the prayers the priest gave you (your penance), then thank God for His mercy.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { _ in ["after_confession", "beati_quorum", "hail_mary"] }
        ),
        PrayerOrder(
            id: "visit",
            title: String(
                localized: "Visiting Jesus in Church",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "Visitatio",
            icon: "ch-monstrance",
            occasion: String(
                localized: "In church, or from anywhere",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "A few minutes with Jesus in the tabernacle, where the Host is kept in church, or in spirit from anywhere.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { _ in
                ["adoro_te", "spiritual_communion", "o_sacrum_convivium", "tantum_ergo", "divine_praises"]
            }
        ),
        PrayerOrder(
            id: "holy_souls",
            title: String(
                localized: "For Those Who Have Died",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "Pro Defunctis",
            icon: "ch-candle",
            occasion: String(
                localized: "At a death, or any day",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "Prayers asking God to give rest and peace to those who have died.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { _ in ["de_profundis", "requiem_aeternam", "fidelium_deus"] }
        ),
        PrayerOrder(
            id: "trouble",
            title: String(
                localized: "In Time of Trouble",
                comment: "Prayers tab: the name of an order of prayer, a few prayers said together"
            ),
            latinTitle: "In Tribulatione",
            icon: "ph-shield",
            occasion: String(
                localized: "When you need help",
                comment: "Prayers tab: when an order of prayer is said, shown as a short line or a small-capitals kicker"
            ),
            detail: String(
                localized: "Prayers for help and protection, to Mary and to St Michael.",
                comment: "Prayers tab: one sentence saying what an order of prayer is"
            ),
            prayerIDs: { _ in ["sub_tuum", "memorare", "perpetual_help", "st_michael_prayer"] }
        )
    ]

    static func order(_ id: String) -> PrayerOrder? { ordersByID[id] }

    private static let ordersByID: [String: PrayerOrder] =
        Dictionary(orders.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    /// The three orders that keep the hours of an ordinary day
    static var dayOrders: [PrayerOrder] {
        [morningOrderID, angelusOrderID, nightOrderID].compactMap { order($0) }
    }

    /// The orders kept for an occasion rather than an hour
    static var occasionOrders: [PrayerOrder] {
        let day = Set([morningOrderID, angelusOrderID, nightOrderID])
        return orders.filter { !day.contains($0.id) }
    }

    // MARK: Names

    /// The prayers that go by their Latin name, whose Latin is set
    /// beneath the English title. Any other prayer's Latin title only
    /// translates its English one, or is the first words of a prayer
    /// nobody calls by them, and is not drawn.
    static let latinNamesKnown: Set<String> = [
        "our_father", "hail_mary", "glory_be", "hail_holy_queen",
        "angele_dei", "visita_quaesumus", "in_manus_tuas", "nunc_dimittis", "benedictus",
        "magnificat", "te_deum", "confiteor", "requiem_aeternam", "de_profundis",
        "beati_quorum", "miserere", "domine_non_sum_dignus", "anima_christi", "suscipe",
        "adoro_te", "o_sacrum_convivium", "ave_verum", "o_salutaris", "tantum_ergo",
        "veni_creator", "veni_sancte_spiritus", "sub_tuum", "ave_maris_stella",
        "alma_redemptoris", "ave_regina_caelorum", "regina_caeli", "inviolata", "salve_mater",
        "tota_pulchra", "flos_carmeli", "stabat_mater", "totus_tuus", "ad_te_beate_ioseph",
        "actiones_nostras", "da_pacem",
    ]

    /// The English set beneath a prayer that is known by its Latin name,
    /// where its Latin would only say the name again
    static let englishNames: [String: String] = Dictionary(
        LibraryContent.prayerBook.prayers.compactMap { prayer in
            isInSpanish(prayer.id) ? nil : prayer.englishName.map { (prayer.id, $0) }
        },
        uniquingKeysWith: { first, _ in first }
    )

    /// The names a list gives a prayer where its title is longer than
    /// the name people use
    static let listTitles: [String: String] = Dictionary(
        LibraryContent.prayerBook.prayers.compactMap { prayer in
            isInSpanish(prayer.id) ? nil : prayer.listTitle.map { (prayer.id, $0) }
        },
        uniquingKeysWith: { first, _ in first }
    )

    // MARK: Our Lady's best-known prayers

    /// The three of her prayers the Prayers page sets beneath the
    /// season's song to Mary — the ones most Catholics know by heart
    static let bestKnownMarianIDs = ["hail_mary", "memorare", "litany_loreto"]
}

// MARK: - PrayAlongLaunch

/// What the pray-along screen prays: an order of prayer, or one prayer.
/// Hashable, so it rides in the navigation path.
struct PrayAlongLaunch: Hashable {
    /// The order being prayed — offered on the rule once its Amen is
    /// reached — or nil for a single prayer
    var orderID: String?

    var prayerIDs: [String]

    /// The kicker over every page: "MORNING PRAYERS"
    var title: String

    var startIndex: Int = 0

    /// The painting or photo a playlist of the reader's hangs behind its
    /// prayers (`PrayerPlaylist.art`), or nil for the book's own
    var art: String?

    /// Whether this is one of the reader's playlists, whose prayers each
    /// hang their own painting as the page turns
    var isPlaylist: Bool { orderID?.hasPrefix("playlist_") == true }

    static func playlist(_ playlist: PrayerPlaylist, startingAt start: Int = 0) -> PrayAlongLaunch {
        let ids = playlist.prayerIDs.filter { resolve($0) != nil }
        return PrayAlongLaunch(
            orderID: playlist.orderID,
            prayerIDs: ids,
            title: playlist.displayName,
            startIndex: min(max(start, 0), max(ids.count - 1, 0)),
            art: playlist.art
        )
    }

    static func order(_ order: PrayerOrder, on date: Date = Date()) -> PrayAlongLaunch {
        PrayAlongLaunch(
            orderID: order.id,
            prayerIDs: order.prayers(on: date).map(\.id),
            title: order.title(on: date)
        )
    }

    static func prayer(_ prayer: BookPrayer) -> PrayAlongLaunch {
        PrayAlongLaunch(orderID: nil, prayerIDs: [prayer.id], title: prayer.title)
    }

    /// An order begun at one of its prayers, the one tapped on the
    /// order's page, and going on from it. `start` counts the order's
    /// prayers as the screen does.
    static func order(_ order: PrayerOrder, on date: Date = Date(), startingAt start: Int) -> PrayAlongLaunch {
        var launch = Self.order(order, on: date)
        launch.startIndex = min(max(start, 0), max(launch.prayerIDs.count - 1, 0))
        return launch
    }

    /// What every door to one prayer opens (`AppRoute.devotionPrayer`):
    /// the prayer alone, or, from an order's page, the order from the
    /// prayer tapped. `set`'s place counts the order's ids, an id that
    /// names no prayer included; where it no longer holds the prayer, the
    /// prayer's first place in the order is taken.
    static func opening(_ prayerID: String, from set: PrayerSet?, on date: Date = Date()) -> PrayAlongLaunch {
        if case .order(let id, let place) = set, let order = PrayerBook.order(id) {
            let ids = order.prayerIDs(date)
            let tapped = ids.indices.contains(place) && ids[place] == prayerID ? place : ids.firstIndex(of: prayerID)
            if let tapped {
                let start = ids[..<tapped].filter { PrayerBook.prayer($0) != nil }.count
                return .order(order, on: date, startingAt: start)
            }
        }
        return PrayAlongLaunch(orderID: nil, prayerIDs: [prayerID], title: resolve(prayerID)?.title ?? String(
            localized: "Prayers",
            comment: "Pray-along screen: the kicker when a prayer's own title cannot be found"
        ))
    }

    /// A prayer by its id: the book's, one of the Rosary's or the
    /// consecration's the book does not print, or one of the reader's own
    /// (`my_` ids, `MyPrayersStore`)
    static func resolve(_ id: String) -> BookPrayer? {
        if CustomPrayer.uuid(in: id) != nil {
            return MyPrayersStore.shared.prayer(withPrayerID: id)?.bookPrayer
        }
        return PrayerBook.prayer(id) ?? BookPrayer.bundled(id, origin: nil, note: nil)
    }
}

// MARK: - PrayerBookAudio

/// The Prayer Book's one choice as Settings sets it, under the Rosary's
/// Audio and in the same pill: whether the book speaks at all
/// (`PrayerBookStore.praysAloud`). The two are kept apart on purpose.
/// The Rosary's decides whether its voice leads every prayer or reads
/// the meditation alone; this one whether the book makes a sound, for
/// prayers said in the pew, before the tabernacle and beside someone
/// asleep.
enum PrayerBookAudio {

    /// The book's own name, as its tab says it, with the word tab, so the
    /// row is never read as a second Audio, or as every prayer in the app
    static let title = String(
        localized: "Prayers Tab Audio",
        comment: "Settings: whether the Prayers tab reads its prayers aloud"
    )

    /// The Prayer Book's door glyph
    static let icon = "lv-prayer-book"

    /// The quieter way first, as the setting's `false`, as the Rosary's
    /// pills set theirs
    static let options: [RosaryChoice.Option] = [
        RosaryChoice.Option(value: false, name: String(
            localized: "In Silence",
            comment: "Prayers Tab Audio option: no sound"
        )),
        RosaryChoice.Option(value: true, name: String(
            localized: "With a Voice",
            comment: "Prayers Tab Audio option: a voice reads the prayers"
        )),
    ]

    /// What the chosen option does. Until the reader has answered, the
    /// pill shows the default, Aloud, but the book has not yet spoken:
    /// it asks the first time (`PrayAloudChoiceSheet`), so the line
    /// says that instead.
    static func note(for aloud: Bool, answered: Bool = true) -> String {
        guard answered else {
            return String(
                localized: "Not chosen yet. You'll be asked the first time you pray from the Prayers tab.",
                comment: "Settings, Prayers Tab Audio: the line before the reader has chosen"
            )
        }
        return aloud
            ? String(
                localized: "A voice reads each prayer to you.",
                comment: "Settings, Prayers Tab Audio: the line under the chosen option"
            )
            : String(
                localized: "No sound. The words are on screen for you to say.",
                comment: "Settings, Prayers Tab Audio: the line under the chosen option"
            )
    }
}
