//
//  PrayerBook.swift
//  Lumen Viae
//
//  The Prayer Book: the Church's common prayers, bundled so they pray
//  with no signal, gathered two ways at once — into chapters, as a
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

// MARK: - PrayerBookTexts

/// The texts, one file per part of the book (`Data/PrayerBook/`), each
/// an extension adding its own array.
enum PrayerBookTexts {}

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

    /// Every prayer of the book, by id. The book's own texts, then the
    /// prayers the Rosary and the consecration already carry.
    static let prayers: [String: BookPrayer] = {
        var all: [String: BookPrayer] = [:]
        let parts: [[BookPrayer]] = [
            PrayerBookTexts.ourLady,
            PrayerBookTexts.foundations,
            PrayerBookTexts.ourLord1,
            PrayerBookTexts.ourLord2,
            PrayerBookTexts.ourLord3,
            PrayerBookTexts.ourLord4,
            PrayerBookTexts.ourLord5,
            PrayerBookTexts.ourLord6,
            PrayerBookTexts.day,
            PrayerBookTexts.mary2,
            PrayerBookTexts.jesus2,
            PrayerBookTexts.jesus3,
            PrayerBookTexts.jesus4,
            PrayerBookTexts.jesus5,
            PrayerBookTexts.eucharist2,
            PrayerBookTexts.eucharist3,
            PrayerBookTexts.saints2,
            PrayerBookTexts.saints3,
            PrayerBookTexts.saints4,
            PrayerBookTexts.saints5,
            PrayerBookTexts.saints6,
            PrayerBookTexts.day2,
            bundled
        ]
        for prayer in parts.joined() where all[prayer.id] == nil {
            all[prayer.id] = prayer
        }
        return all
    }()

    static func prayer(_ id: String) -> BookPrayer? { prayers[id] }

    /// The Rosary's prayers and the consecration's, with the small print
    /// the book gives them
    private static let bundled: [BookPrayer] = [
        BookPrayer.bundled("sign_of_cross", origin: "Apostolic tradition",
                           note: "Begins and ends every prayer; the right hand touches the forehead, the breast, the left shoulder and the right."),
        BookPrayer.bundled("our_father", origin: "Our Lord · Matthew 6:9–13",
                           note: "The prayer Christ Himself taught when the disciples asked Him how to pray."),
        BookPrayer.bundled("hail_mary", origin: "Luke 1:28, 42 · the Church, 15th century",
                           note: "The Angel's greeting and Elizabeth's, and the Church's petition after them."),
        BookPrayer.bundled("glory_be", origin: "The Church · 4th century",
                           note: "Praise of the Trinity, said after each ten Hail Marys of the Rosary and after the psalms in the Church's Hours of Prayer."),
        BookPrayer.bundled("apostles_creed", origin: "The Roman Church · 2nd century",
                           note: "The creed said at baptism in Rome: the faith of the Apostles in twelve statements."),
        BookPrayer.bundled("fatima_prayer", title: "The Fatima Prayer", origin: "Our Lady of Fatima · 1917",
                           note: "Asked for by Mary at Fatima, to be said in the Rosary after each Glory Be."),
        BookPrayer.bundled("hail_holy_queen", origin: "Western Church · 11th century",
                           note: "Said at the end of the Rosary, and sung to close the Church's Bedtime Prayer (Compline) from Pentecost to Advent."),
        BookPrayer.bundled("memorare", origin: "Attributed to St Bernard of Clairvaux · 12th century",
                           note: "Spread by Fr Claude Bernard in the seventeenth century, who owed his own conversion to it."),
        BookPrayer.bundled("act_of_contrition", origin: "Traditional",
                           note: "Said in the confessional, and each night at bedtime."),
        BookPrayer.bundled("st_michael_prayer", origin: "Pope Leo XIII · 1886",
                           note: "Once said kneeling at the end of every spoken Mass, asking St Michael to defend the Church."),
        BookPrayer.bundled("sorrows_closing_prayer", title: "To Our Lady of Sorrows", origin: "The Servants of Mary (Servites)",
                           note: "The last prayer of the Seven Sorrows of Mary, prayed on their own beads."),
        BookPrayer.bundled("rosary_closing_prayer", title: "Prayer after the Rosary", origin: "The Mass of the Holy Rosary",
                           note: "The Church's prayer from the Mass of the Holy Rosary, said when the beads are done."),
        BookPrayer.bundled("veni_creator", origin: "Attributed to Rabanus Maurus · 9th century",
                           note: "Sung at Pentecost, at ordinations, and whenever the Church asks the Holy Spirit to come."),
        BookPrayer.bundled("ave_maris_stella", origin: "Western Church · 9th century",
                           note: "The hymn the Church sings at Evening Prayer (Vespers) on Mary's feast days."),
        BookPrayer.bundled("magnificat", origin: "Our Lady · Luke 1:46–55",
                           note: "Mary's own song when she visited Elizabeth, sung every evening at the Church's Evening Prayer (Vespers)."),
        BookPrayer.bundled("litany_loreto", origin: "The Holy House of Loreto · 16th century",
                           note: "Sung at Loreto since the 1550s, and approved for the whole Church in 1587."),
        BookPrayer.bundled("litany_holy_name", origin: "St Bernardine of Siena · 15th century",
                           note: "A litany to the Holy Name, approved for the whole Church in 1862."),
        BookPrayer.bundled("o_jesus_living_in_mary", origin: "Fr Charles de Condren · 17th century",
                           note: "Said each day of the 33-day preparation to give yourself to Jesus through Mary, on the Consecrate tab.")
    ].compactMap { $0 } + consecrationOnly

    /// The consecration's English-only prayers the book prints too
    private static let consecrationOnly: [BookPrayer] = [
        ConsecrationData.allPrayers["litany_holy_ghost"].map { prayer in
            BookPrayer(id: prayer.id, title: "Litany of the Holy Spirit", latinTitle: nil,
                       origin: "Traditional",
                       note: "Said in the first days of the 33-day preparation, asking the Holy Spirit to come.",
                       english: prayer.content, latin: nil)
        }
    ].compactMap { $0 }

    // MARK: Chapters

    static let chapters: [PrayerBookChapter] = [
        PrayerBookChapter(
            id: "first", numeral: "I", title: "The First Prayers", latinTitle: "Orationes Primæ",
            icon: "ch-praying-hands", part: .everyDay,
            epigraph: "The prayers every Catholic learns first.",
            sections: [
                PrayerBookSection(title: "The first prayers", prayerIDs: ["sign_of_cross", "our_father", "hail_mary", "glory_be", "fatima_prayer"]),
                PrayerBookSection(title: "The creeds", prayerIDs: ["apostles_creed", "nicene_creed"]),
                PrayerBookSection(title: "Faith, hope, love and sorrow", prayerIDs: ["act_of_faith", "act_of_hope", "act_of_charity", "act_of_contrition"]),
            ],
            topic: "The First Prayers",
            searchWords: ["basic prayers", "first prayers", "basics", "creed", "acts"]
        ),
        PrayerBookChapter(
            id: "day", numeral: "II", title: "Daily Prayers", latinTitle: "Preces Quotidianæ",
            icon: "lv-hourglass", part: .everyDay,
            epigraph: "Morning, the Angelus, meals and night.",
            sections: [
                PrayerBookSection(title: "In the morning", prayerIDs: ["morning_offering", "benedictus", "angele_dei"]),
                PrayerBookSection(title: "The Angelus", prayerIDs: ["angelus", "regina_caeli"]),
                PrayerBookSection(title: "At meals", prayerIDs: ["grace_before", "grace_after"]),
                PrayerBookSection(title: "Through the day", prayerIDs: ["actiones_nostras", "aquinas_before_study", "newman_definite_service", "lead_kindly_light"]),
                PrayerBookSection(title: "At night", prayerIDs: ["examen", "act_of_contrition", "in_manus_tuas", "nunc_dimittis", "visita_quaesumus"]),
            ],
            orderIDs: ["morning", "angelus", "night", "table"],
            topic: "Daily Prayers",
            searchWords: ["through the day", "morning", "evening", "bedtime", "night", "meals", "grace", "angelus"]
        ),
        PrayerBookChapter(
            id: "short", numeral: "III", title: "Short Prayers", latinTitle: "Iaculatoriæ",
            icon: "lv-dart", part: .everyDay,
            epigraph: "A few words said in passing.",
            sections: [
                PrayerBookSection(title: "To Jesus", prayerIDs: ["my_jesus_mercy", "jesus_meek", "sweet_heart", "sacred_heart_trust", "jesus_i_trust_in_thee", "my_jesus_i_love_thee", "my_lord_and_my_god", "my_god_and_my_all", "o_sacrament_most_holy", "pardon_prayer"]),
                PrayerBookSection(title: "To Mary and St Joseph", prayerIDs: ["miraculous_medal", "blessed_be_conception", "totus_tuus", "st_joseph_pray", "jmj", "jmj_heart_and_soul"]),
                PrayerBookSection(title: "To the Holy Spirit, and for the dead", prayerIDs: ["holy_spirit_enlighten", "requiem_aeternam"]),
            ],
            topic: "Short Prayers",
            searchWords: ["ejaculations", "aspirations", "aspiration"]
        ),
        PrayerBookChapter(
            id: "mass", numeral: "IV", title: "Holy Mass and Communion", latinTitle: "De Sancta Missa",
            icon: "ch-altar", part: .sacraments,
            epigraph: "Before Mass, at Communion, and after.",
            sections: [
                PrayerBookSection(title: "Before Mass", prayerIDs: ["aquinas_before_mass", "st_ambrose_before_mass", "come_holy_ghost"]),
                PrayerBookSection(title: "At Communion", prayerIDs: ["domine_non_sum_dignus", "spiritual_communion"]),
                PrayerBookSection(title: "After Communion", prayerIDs: ["anima_christi", "en_ego", "aquinas_after_mass", "transfige", "mary_after_communion", "suscipe"]),
                PrayerBookSection(title: "After Mass", prayerIDs: ["hail_holy_queen", "st_michael_prayer"]),
            ],
            orderIDs: ["before_mass", "after_mass"],
            topic: "Prayers for Mass",
            searchWords: ["the mass", "holy communion", "communion", "before mass", "after mass", "thanksgiving after communion"]
        ),
        PrayerBookChapter(
            id: "penance", numeral: "V", title: "Confession", latinTitle: "De Pænitentia",
            icon: "ch-keys", part: .sacraments,
            epigraph: "Getting ready, confessing, giving thanks.",
            sections: [
                PrayerBookSection(title: "Before Confession", prayerIDs: ["before_confession", "examination_of_conscience", "miserere"]),
                PrayerBookSection(title: "In the confessional", prayerIDs: ["the_confession", "confiteor", "act_of_contrition"]),
                PrayerBookSection(title: "After Confession", prayerIDs: ["after_confession", "beati_quorum"]),
            ],
            orderIDs: ["before_confession", "after_confession"],
            topic: "Prayers for Confession",
            searchWords: ["penance", "contrition", "examination", "sorrow for sin"]
        ),
        PrayerBookChapter(
            id: "sacrament", numeral: "VI", title: "The Blessed Sacrament", latinTitle: "De Sanctissimo Sacramento",
            icon: "ch-monstrance", part: .sacraments,
            epigraph: "Jesus present in the Host.",
            sections: [
                PrayerBookSection(title: "A visit", prayerIDs: ["st_alphonsus_visit", "adoro_te", "spiritual_communion", "angels_prayer_fatima", "o_sacrament_most_holy"]),
                PrayerBookSection(title: "Benediction", prayerIDs: ["o_salutaris", "tantum_ergo", "divine_praises", "o_sacrum_convivium", "ave_verum"]),
                PrayerBookSection(title: "The litany", prayerIDs: ["litany_blessed_sacrament"]),
            ],
            orderIDs: ["visit"],
            topic: "Prayers of the Eucharist",
            searchWords: ["eucharist", "the eucharist", "adoration", "benediction", "visit", "holy hour"]
        ),
        PrayerBookChapter(
            id: "holy_ghost", numeral: "VII", title: "The Holy Trinity and the Holy Spirit", latinTitle: "De Sanctissima Trinitate",
            icon: "ch-dove", part: .god,
            epigraph: "Father, Son and Holy Spirit.",
            sections: [
                PrayerBookSection(title: "The Holy Trinity", prayerIDs: ["glory_be", "st_patrick_breastplate"]),
                PrayerBookSection(title: "The Holy Spirit", prayerIDs: ["come_holy_ghost", "veni_creator", "veni_sancte_spiritus", "breathe_in_me", "seven_gifts", "secret_of_sanctity", "holy_spirit_enlighten", "litany_holy_ghost"]),
            ],
            topic: "Prayers to the Holy Spirit",
            searchWords: ["holy spirit", "holy ghost", "the holy ghost", "paraclete", "pentecost", "trinity"]
        ),
        PrayerBookChapter(
            id: "our_lord", numeral: "VIII", title: "Our Lord", latinTitle: "De Domino Nostro",
            icon: "ch-chi-rho", part: .god,
            epigraph: "His Name, His Heart, His Blood, His mercy.",
            sections: [
                PrayerBookSection(title: "The Holy Name", prayerIDs: ["litany_holy_name", "jesus_prayer"]),
                PrayerBookSection(title: "The Holy Child", prayerIDs: ["infant_of_prague"]),
                PrayerBookSection(title: "The Sacred Heart", prayerIDs: ["litany_sacred_heart", "consecration_sacred_heart", "reparation_sacred_heart", "efficacious_novena"]),
                PrayerBookSection(title: "The Holy Face", prayerIDs: ["golden_arrow"]),
                PrayerBookSection(title: "The Precious Blood", prayerIDs: ["litany_precious_blood", "precious_blood_offering"]),
                PrayerBookSection(title: "The Passion", prayerIDs: ["en_ego", "st_francis_before_crucifix"]),
                PrayerBookSection(title: "Christ the King", prayerIDs: ["christ_the_king"]),
                PrayerBookSection(title: "Divine Mercy", prayerIDs: ["divine_mercy_chaplet", "jesus_i_trust_in_thee"]),
                PrayerBookSection(title: "Prayers to Christ", prayerIDs: ["anima_christi", "st_richard", "suscipe", "o_jesus_living_in_mary", "generosity_ignatius", "abandonment_foucauld", "radiating_christ", "peace_prayer"]),
            ],
            topic: "Prayers to Jesus",
            searchWords: ["jesus", "christ", "sacred heart", "holy name", "precious blood", "holy face", "divine mercy", "passion"]
        ),
        PrayerBookChapter(
            id: "our_lady", numeral: "IX", title: "The Blessed Virgin", latinTitle: "De Beata Maria Virgine",
            icon: "ch-lily", part: .god,
            epigraph: "Prayers to Mary, from the oldest to the newest.",
            sections: [
                PrayerBookSection(title: "The Rosary", prayerIDs: ["hail_mary", "fatima_prayer", "hail_holy_queen", "rosary_closing_prayer"]),
                PrayerBookSection(title: "The litany", prayerIDs: ["litany_loreto"]),
                PrayerBookSection(title: "The Church's songs to Mary", prayerIDs: ["alma_redemptoris", "ave_regina_caelorum", "regina_caeli", "hail_holy_queen", "magnificat", "ave_maris_stella", "inviolata", "salve_mater", "tota_pulchra", "flos_carmeli"]),
                PrayerBookSection(title: "Every day", prayerIDs: ["angelus", "sub_tuum", "memorare", "o_domina_mea", "three_hail_marys", "miraculous_medal", "totus_tuus", "mary_after_communion"]),
                PrayerBookSection(title: "Her titles", prayerIDs: ["perpetual_help", "our_lady_of_good_counsel", "our_lady_of_lourdes", "immaculate_heart", "mary_help_of_christians", "our_lady_of_mount_carmel"]),
                PrayerBookSection(title: "Her Seven Sorrows", prayerIDs: ["stabat_mater", "our_lady_of_sorrows", "litany_seven_sorrows", "sorrows_closing_prayer"]),
            ],
            topic: "Prayers to Mary",
            searchWords: ["mary", "our lady", "the virgin", "virgin mary", "blessed virgin", "marian", "mother of god"]
        ),
        PrayerBookChapter(
            id: "st_joseph", numeral: "X", title: "St Joseph", latinTitle: "De Sancto Ioseph",
            icon: "lv-saint", part: .god,
            epigraph: "Patron of the Church, of workers and of a happy death.",
            sections: [
                PrayerBookSection(title: "Prayers to St Joseph", prayerIDs: ["ad_te_beate_ioseph", "memorare_st_joseph", "litany_st_joseph", "st_joseph_workers", "st_joseph_happy_death", "st_joseph_pray", "jmj"]),
            ],
            topic: "Prayers to St Joseph",
            searchWords: ["joseph", "saint joseph"]
        ),
        PrayerBookChapter(
            id: "saints", numeral: "XI", title: "Angels and Saints", latinTitle: "De Angelis et Sanctis",
            icon: "lv-saint", part: .god,
            epigraph: "The friends of God, asked to pray for us.",
            sections: [
                PrayerBookSection(title: "The angels", prayerIDs: ["angele_dei", "st_michael_prayer"]),
                PrayerBookSection(title: "The saints", prayerIDs: ["litany_of_the_saints", "st_anne", "st_anthony", "st_jude", "st_peregrine", "st_benedict_medal", "st_dominic_o_lumen", "st_patrick_breastplate", "st_francis_before_crucifix"]),
            ],
            topic: "Prayers to the Angels and Saints",
            searchWords: ["angels", "saints", "guardian angel", "archangel"]
        ),
        PrayerBookChapter(
            id: "seasons", numeral: "XII", title: "Feasts and Seasons", latinTitle: "De Festis et Temporibus",
            icon: "ch-window", part: .year,
            epigraph: "Through the Church's year.",
            sections: [
                PrayerBookSection(title: "Advent and Christmas", prayerIDs: ["alma_redemptoris", "nunc_dimittis"]),
                PrayerBookSection(title: "Lent and the Passion", prayerIDs: ["stabat_mater", "miserere", "en_ego"]),
                PrayerBookSection(title: "Easter", prayerIDs: ["regina_caeli"]),
                PrayerBookSection(title: "Pentecost", prayerIDs: ["veni_creator", "veni_sancte_spiritus"]),
                PrayerBookSection(title: "Christ the King", prayerIDs: ["christ_the_king"]),
                PrayerBookSection(title: "All Saints and All Souls", prayerIDs: ["litany_of_the_saints", "st_gertrude"]),
                PrayerBookSection(title: "The year's end", prayerIDs: ["te_deum"]),
            ],
            topic: "Prayers for the Church's Year",
            searchWords: ["feasts", "seasons", "advent", "christmas", "lent", "easter", "liturgical year"]
        ),
        PrayerBookChapter(
            id: "thanks", numeral: "XIII", title: "Thanksgiving", latinTitle: "Gratiarum Actio",
            icon: "lv-wheat", part: .year,
            epigraph: "The Church's songs of thanks.",
            sections: [
                PrayerBookSection(title: "Songs of thanks", prayerIDs: ["te_deum", "magnificat", "benedictus", "nunc_dimittis", "grace_after"]),
            ],
            topic: "Prayers of Thanksgiving",
            searchWords: ["thanks", "thank you", "gratitude", "te deum"]
        ),
        PrayerBookChapter(
            id: "litanies", numeral: "XIV", title: "Litanies", latinTitle: "Litaniæ",
            icon: "lv-procession-cross", part: .year,
            epigraph: "Short petitions, each with the same response.",
            sections: [
                PrayerBookSection(title: "Litanies", prayerIDs: ["litany_loreto", "litany_holy_name", "litany_sacred_heart", "litany_st_joseph", "litany_of_the_saints", "litany_holy_ghost", "litany_precious_blood", "litany_blessed_sacrament", "litany_seven_sorrows", "litany_of_humility"]),
            ],
            topic: "Litanies",
            searchWords: ["the litanies", "litany"]
        ),
        PrayerBookChapter(
            id: "church", numeral: "XV", title: "For the Church and the Living", latinTitle: "Pro Vivis",
            icon: "ch-church", part: .others,
            epigraph: "For the Pope, priests, family and country.",
            sections: [
                PrayerBookSection(title: "The Church", prayerIDs: ["prayer_for_the_pope", "prayer_for_priests", "conversion_of_sinners", "rosary_closing_prayer"]),
                PrayerBookSection(title: "Family", prayerIDs: ["prayer_for_family", "parents_for_children"]),
                PrayerBookSection(title: "Country and peace", prayerIDs: ["prayer_for_our_country", "da_pacem"]),
            ],
            topic: "Prayers for the Church and the Living",
            searchWords: ["the church", "the pope", "holy father", "priests", "family", "country", "peace", "the living"]
        ),
        PrayerBookChapter(
            id: "sick", numeral: "XVI", title: "The Sick and the Dying", latinTitle: "Pro Infirmis et Morientibus",
            icon: "ch-chalice", part: .others,
            epigraph: "For healing, and for a holy death.",
            sections: [
                PrayerBookSection(title: "For the sick", prayerIDs: ["prayer_for_the_sick", "st_peregrine"]),
                PrayerBookSection(title: "For a happy death", prayerIDs: ["happy_death", "st_joseph_happy_death"]),
            ],
            topic: "Prayers for the Sick and the Dying",
            searchWords: ["sick", "illness", "healing", "dying", "happy death", "death"]
        ),
        PrayerBookChapter(
            id: "departed", numeral: "XVII", title: "The Faithful Departed", latinTitle: "Pro Defunctis",
            icon: "ch-candle", part: .others,
            epigraph: "Rest and peace for those who have died.",
            sections: [
                PrayerBookSection(title: "For the dead", prayerIDs: ["requiem_aeternam", "de_profundis", "fidelium_deus", "deceased_parents", "st_gertrude"]),
            ],
            orderIDs: ["holy_souls"],
            topic: "Prayers for Those Who Have Died",
            searchWords: ["for the dead", "the dead", "for those who have died", "departed", "holy souls", "purgatory", "funeral"]
        ),
        PrayerBookChapter(
            id: "needs", numeral: "XVIII", title: "In Time of Need", latinTitle: "In Variis Necessitatibus",
            icon: "lv-stella-maris", part: .others,
            epigraph: "For help, protection and peace of heart.",
            sections: [
                PrayerBookSection(title: "In trouble", prayerIDs: ["sub_tuum", "memorare", "perpetual_help", "st_michael_prayer", "st_jude"]),
                PrayerBookSection(title: "At work, at study, on the road", prayerIDs: ["actiones_nostras", "aquinas_before_study", "prayer_for_travel", "st_anthony"]),
                PrayerBookSection(title: "For trust and peace", prayerIDs: ["nada_te_turbe", "abandonment_foucauld", "lead_kindly_light", "litany_of_humility"]),
            ],
            orderIDs: ["trouble"],
            topic: "Prayers in Time of Need",
            searchWords: ["need", "trouble", "help", "protection", "occasions", "travel", "work", "study", "trust", "peace"]
        )
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
    static let englishNames: [String: String] = [
        "memorare": "Remember, O most gracious Virgin Mary",
    ]

    /// The names a list gives a prayer where its title is longer than
    /// the name people use
    static let listTitles: [String: String] = [
        "hail_mary": "Hail Mary",
        "our_father": "Our Father",
        "glory_be": "Glory Be",
        "memorare": "Memorare",
        "litany_loreto": "Litany of Loreto",
        "st_michael_prayer": "St Michael",
        "apostles_creed": "Apostles' Creed",
        "act_of_contrition": "Act of Contrition",
        "sign_of_cross": "Sign of the Cross",
    ]

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
        return PrayAlongLaunch(orderID: nil, prayerIDs: [prayerID], title: resolve(prayerID)?.title ?? "Prayers")
    }

    /// A prayer by its id: the book's, or one of the Rosary's or the
    /// consecration's the book does not print
    static func resolve(_ id: String) -> BookPrayer? {
        PrayerBook.prayer(id) ?? BookPrayer.bundled(id, origin: nil, note: nil)
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
