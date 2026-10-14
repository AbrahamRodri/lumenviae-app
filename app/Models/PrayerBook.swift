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

    /// The line set small beneath its name: its Latin, or, for the one
    /// prayer known by its Latin name ("Memorare"), its English. Never
    /// the name said twice, whatever its case or article: "Tantum Ergo"
    /// once stood over "Tantum ergo".
    var secondTitle: String? {
        if let english = PrayerBook.englishNames[id] { return english }
        guard let latinTitle, !PrayerBook.isSameName(latinTitle, title) else { return nil }
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

    /// One italic line under the topic's name
    let epigraph: String

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
        epigraph: String,
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
        case .everyDay:   return "Every Day"
        case .sacraments: return "The Sacraments"
        case .god:        return "God, Our Lady and the Saints"
        case .year:       return "Through the Year"
        case .others:     return "For Others, and in Need"
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

    /// One italic line saying what the order is
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
            return "Queen of Heaven"
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
        case .almaRedemptoris:   return "Loving Mother of the Redeemer"
        case .aveReginaCaelorum: return "Hail, Queen of Heaven"
        case .reginaCaeli:       return "Queen of Heaven"
        case .salveRegina:       return "Hail, Holy Queen"
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
        case .almaRedemptoris:   return "Advent to February 2"
        case .aveReginaCaelorum: return "February 2 to Holy Week"
        case .reginaCaeli:       return "Easter to Pentecost"
        case .salveRegina:       return "Pentecost to Advent"
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
            (prayer.id, BookPrayer(
                id: prayer.id, title: prayer.title, latinTitle: prayer.latinTitle,
                origin: prayer.origin, note: prayer.note, english: prayer.english, latin: prayer.latin
            ))
        },
        uniquingKeysWith: { first, _ in first }
    )

    static func prayer(_ id: String) -> BookPrayer? { prayers[id] }

    // MARK: Chapters

    /// The book's topics, in its order: the words from the document, and
    /// how the app sets each (its glyph, its shelf, its orders of prayer)
    /// from `layouts`
    static let chapters: [PrayerBookChapter] = LibraryContent.prayerBook.chapters.map { chapter in
        let layout = layouts[chapter.id] ?? ChapterLayout(icon: "lv-prayer-book", part: .others)
        return PrayerBookChapter(
            id: chapter.id, numeral: chapter.numeral, title: chapter.title, latinTitle: chapter.latinTitle,
            icon: layout.icon, part: layout.part, epigraph: chapter.note ?? "",
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

    static var ourLady: PrayerBookChapter { chapter("our_lady")! }

    // MARK: Orders

    static let morningOrderID = "morning"
    static let angelusOrderID = "angelus"
    static let nightOrderID = "night"

    static let orders: [PrayerOrder] = [
        PrayerOrder(
            id: morningOrderID, title: "Morning Prayers", latinTitle: "Preces Matutinæ",
            icon: "lv-rooster", occasion: "On waking",
            detail: "A few short prayers on waking, giving the day to God.",
            prayerIDs: { _ in
                ["sign_of_cross", "morning_offering", "our_father", "hail_mary", "glory_be",
                 "act_of_faith", "act_of_hope", "act_of_charity", "angele_dei"]
            }
        ),
        PrayerOrder(
            id: angelusOrderID, title: "The Angelus", latinTitle: "Angelus Domini",
            icon: "lv-bell", occasion: "6 AM, noon and 6 PM",
            detail: "Remembering how God's Son became man, said three times a day when the church bell rings.",
            prayerIDs: { date in [isEastertide(date) ? "regina_caeli" : "angelus"] }
        ),
        PrayerOrder(
            id: nightOrderID, title: "Night Prayers", latinTitle: "Preces Vespertinæ",
            icon: "lv-lamp", occasion: "At bedtime",
            detail: "Look back on the day, ask God's forgiveness, and end with a song to Mary.",
            prayerIDs: { date in
                ["sign_of_cross", "examen", "act_of_contrition", "in_manus_tuas",
                 "visita_quaesumus", antiphon(on: date).prayerID]
            }
        ),
        PrayerOrder(
            id: "table", title: "At Meals", latinTitle: "Benedictio Mensæ",
            icon: "ch-bread", occasion: "Before and after meals",
            detail: "Grace before the meal, and thanks when it is done.",
            prayerIDs: { _ in ["grace_before", "grace_after"] }
        ),
        PrayerOrder(
            id: "before_mass", title: "Before Mass", latinTitle: "Præparatio ad Missam",
            icon: "ch-altar", occasion: "In the pew, before Mass begins",
            detail: "Prayers to get ready for Mass: for light, a ready heart, and faith, hope and love.",
            prayerIDs: { _ in
                ["sign_of_cross", "come_holy_ghost", "aquinas_before_mass",
                 "act_of_faith", "act_of_hope", "act_of_charity"]
            }
        ),
        PrayerOrder(
            id: "after_mass", title: "After Communion", latinTitle: "Gratiarum Actio",
            icon: "ch-chalice", occasion: "In thanksgiving, after Mass",
            detail: "Prayers of thanks for the minutes after you receive Communion.",
            prayerIDs: { _ in
                ["anima_christi", "en_ego", "aquinas_after_mass", "mary_after_communion", "suscipe"]
            }
        ),
        PrayerOrder(
            id: "before_confession", title: "Before Confession", latinTitle: "Ante Confessionem",
            icon: "ch-keys", occasion: "Before going in",
            detail: "Ask for light, go through the Ten Commandments, and be sorry for your sins.",
            prayerIDs: { _ in
                ["sign_of_cross", "come_holy_ghost", "before_confession",
                 "examination_of_conscience", "act_of_contrition", "the_confession"]
            }
        ),
        PrayerOrder(
            id: "after_confession", title: "After Confession", latinTitle: "Post Confessionem",
            icon: "ch-keys", occasion: "Kneeling afterwards",
            detail: "Say the prayers the priest gave you (your penance), then thank God for His mercy.",
            prayerIDs: { _ in ["after_confession", "beati_quorum", "hail_mary"] }
        ),
        PrayerOrder(
            id: "visit", title: "Visiting Jesus in Church", latinTitle: "Visitatio",
            icon: "ch-monstrance", occasion: "In church, or from anywhere",
            detail: "A few minutes with Jesus in the tabernacle, where the Host is kept in church, or in spirit from anywhere.",
            prayerIDs: { _ in
                ["adoro_te", "spiritual_communion", "o_sacrum_convivium", "tantum_ergo", "divine_praises"]
            }
        ),
        PrayerOrder(
            id: "holy_souls", title: "For Those Who Have Died", latinTitle: "Pro Defunctis",
            icon: "ch-candle", occasion: "At a death, or any day",
            detail: "Prayers asking God to give rest and peace to those who have died.",
            prayerIDs: { _ in ["de_profundis", "requiem_aeternam", "fidelium_deus"] }
        ),
        PrayerOrder(
            id: "trouble", title: "In Time of Trouble", latinTitle: "In Tribulatione",
            icon: "ph-shield", occasion: "When you need help",
            detail: "Prayers for help and protection, to Mary and to St Michael.",
            prayerIDs: { _ in ["sub_tuum", "memorare", "perpetual_help", "st_michael_prayer"] }
        )
    ]

    static func order(_ id: String) -> PrayerOrder? { ordersByID[id] }

    private static let ordersByID: [String: PrayerOrder] =
        Dictionary(orders.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    /// The orders that say each prayer on `date`, by prayer id, each
    /// list in the book's order of the orders. Only the Angelus and Night
    /// Prayers change, and only with the day, so the lookup is built once
    /// for the day and kept until it is asked for another.
    static func ordersSaying(on date: Date) -> [String: [String]] {
        let day = Calendar.current.startOfDay(for: date)
        if let kept = ordersSayingKept, kept.day == day { return kept.saying }
        var saying: [String: [String]] = [:]
        for order in orders {
            var seen = Set<String>()
            for id in order.prayerIDs(date) where seen.insert(id).inserted {
                saying[id, default: []].append(order.id)
            }
        }
        ordersSayingKept = (day, saying)
        return saying
    }

    private static var ordersSayingKept: (day: Date, saying: [String: [String]])?

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

    /// The English set beneath a prayer that is known by its Latin name,
    /// where its Latin would only say the name again
    static let englishNames: [String: String] = Dictionary(
        LibraryContent.prayerBook.prayers.compactMap { prayer in prayer.englishName.map { (prayer.id, $0) } },
        uniquingKeysWith: { first, _ in first }
    )

    /// The names a list gives a prayer where its title is longer than
    /// the name people use
    static let listTitles: [String: String] = Dictionary(
        LibraryContent.prayerBook.prayers.compactMap { prayer in prayer.listTitle.map { (prayer.id, $0) } },
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
    static let title = "Prayers Tab Audio"

    /// The Prayer Book's door glyph
    static let icon = "lv-prayer-book"

    /// The quieter way first, as the setting's `false`, as the Rosary's
    /// pills set theirs
    static let options: [RosaryChoice.Option] = [
        RosaryChoice.Option(value: false, name: "In Silence"),
        RosaryChoice.Option(value: true, name: "Aloud"),
    ]

    /// What the chosen option does. Until the reader has answered, the
    /// pill shows the default, Aloud, but the book has not yet spoken:
    /// it asks the first time (`PrayAloudChoiceSheet`), so the line
    /// says that instead.
    static func note(for aloud: Bool, answered: Bool = true) -> String {
        guard answered else {
            return "Not chosen yet. You'll be asked the first time you pray from the Prayers tab."
        }
        return aloud
            ? "Each prayer is read aloud to you."
            : "No sound. The words are on screen for you to say."
    }
}
