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

/// A chapter of the book, as its contents page prints it.
struct PrayerBookChapter: Identifiable, Hashable {
    let id: String
    let numeral: String
    let title: String
    let latinTitle: String
    let icon: String

    /// One italic line under the chapter's name
    let epigraph: String

    /// In the order the chapter prints them. A prayer may stand in more
    /// than one chapter — the Hail Mary is a first prayer and Our Lady's.
    let prayerIDs: [String]

    /// The chapter named as a topic when a search finds it: "Prayers to
    /// Mary", where the contents page says "Mary"
    var topic: String = ""

    /// The other words a reader might look for the chapter by — the older
    /// names the book once printed ("Our Lady", "the Holy Ghost",
    /// "Penance") among them, so a reader who knew it then still finds it
    var searchWords: [String] = []

    var prayers: [BookPrayer] { prayerIDs.compactMap { PrayerBook.prayer($0) } }
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
            id: "first", numeral: "I", title: "Basic Prayers", latinTitle: "Orationes Primæ",
            icon: "ch-praying-hands",
            epigraph: "The first prayers every Catholic learns, said all through life.",
            prayerIDs: ["sign_of_cross", "our_father", "hail_mary", "glory_be", "apostles_creed",
                        "nicene_creed", "act_of_faith", "act_of_hope", "act_of_charity",
                        "act_of_contrition", "fatima_prayer"],
            topic: "Basic Prayers",
            searchWords: ["first prayers", "the first prayers", "basics", "creed", "acts"]
        ),
        PrayerBookChapter(
            id: "our_lady", numeral: "II", title: "Mary", latinTitle: "De Beata Maria Virgine",
            icon: "ch-lily",
            epigraph: "Prayers to Mary, the mother of Jesus, from the oldest to the newest.",
            prayerIDs: ["hail_mary", "sub_tuum", "angelus", "regina_caeli", "hail_holy_queen",
                        "alma_redemptoris", "ave_regina_caelorum", "memorare", "magnificat",
                        "ave_maris_stella", "stabat_mater", "tota_pulchra", "flos_carmeli",
                        "litany_loreto", "o_domina_mea", "perpetual_help", "three_hail_marys",
                        "miraculous_medal", "mary_after_communion", "sorrows_closing_prayer",
                        "our_lady_of_good_counsel", "our_lady_of_lourdes", "immaculate_heart",
                        "our_lady_of_sorrows", "litany_seven_sorrows", "mary_help_of_christians",
                        "our_lady_of_mount_carmel", "inviolata", "salve_mater"],
            topic: "Prayers to Mary",
            searchWords: ["our lady", "the virgin", "virgin mary", "blessed virgin", "marian", "mother of god"]
        ),
        PrayerBookChapter(
            id: "our_lord", numeral: "III", title: "Jesus", latinTitle: "De Domino Nostro",
            icon: "ch-chi-rho",
            epigraph: "To Christ, Who is the way to the Father.",
            prayerIDs: ["anima_christi", "en_ego", "jesus_prayer", "st_richard", "suscipe",
                        "o_jesus_living_in_mary", "litany_holy_name", "litany_sacred_heart",
                        "consecration_sacred_heart", "reparation_sacred_heart", "efficacious_novena",
                        "christ_the_king", "litany_precious_blood", "precious_blood_offering",
                        "golden_arrow", "divine_mercy_chaplet", "infant_of_prague", "peace_prayer",
                        "generosity_ignatius", "abandonment_foucauld", "nada_te_turbe", "radiating_christ"],
            topic: "Prayers to Jesus",
            searchWords: ["our lord", "christ", "sacred heart", "holy name"]
        ),
        PrayerBookChapter(
            id: "sacrament", numeral: "IV", title: "The Eucharist", latinTitle: "De Sanctissimo Sacramento",
            icon: "ch-monstrance",
            epigraph: "Prayers to Jesus, present in the Host, at Mass and before the altar.",
            prayerIDs: ["aquinas_before_mass", "st_ambrose_before_mass", "domine_non_sum_dignus",
                        "spiritual_communion", "adoro_te", "ave_verum",
                        "o_sacrum_convivium", "o_salutaris", "tantum_ergo", "divine_praises",
                        "aquinas_after_mass",
                        "transfige", "st_alphonsus_visit", "angels_prayer_fatima", "litany_blessed_sacrament"],
            topic: "Prayers of the Eucharist",
            searchWords: ["blessed sacrament", "holy communion", "communion", "adoration", "benediction", "the mass"]
        ),
        PrayerBookChapter(
            id: "holy_ghost", numeral: "V", title: "The Holy Spirit", latinTitle: "De Spiritu Sancto",
            icon: "ch-dove",
            epigraph: "Prayers asking the Holy Spirit for light and help.",
            prayerIDs: ["come_holy_ghost", "veni_creator", "veni_sancte_spiritus",
                        "breathe_in_me", "seven_gifts", "secret_of_sanctity", "litany_holy_ghost"],
            topic: "Prayers to the Holy Spirit",
            searchWords: ["holy ghost", "the holy ghost", "paraclete", "pentecost"]
        ),
        PrayerBookChapter(
            id: "saints", numeral: "VI", title: "Angels and Saints", latinTitle: "De Angelis et Sanctis",
            icon: "lv-saint",
            epigraph: "The friends of God, asked to pray for us.",
            prayerIDs: ["angele_dei", "st_michael_prayer", "ad_te_beate_ioseph", "litany_st_joseph",
                        "st_patrick_breastplate",
                        "memorare_st_joseph", "st_joseph_workers", "st_joseph_happy_death", "st_anne",
                        "st_anthony", "st_jude", "st_peregrine", "st_benedict_medal", "st_dominic_o_lumen",
                        "st_francis_before_crucifix", "litany_of_the_saints"],
            topic: "Prayers to the Angels and Saints",
            searchWords: ["angels", "saints", "guardian angel", "archangel"]
        ),
        PrayerBookChapter(
            id: "day", numeral: "VII", title: "Through the Day", latinTitle: "Per Diem",
            icon: "lv-hourglass",
            epigraph: "On waking, at meals, in the evening, and at the day's end.",
            prayerIDs: ["morning_offering", "benedictus", "grace_before", "grace_after",
                        "visita_quaesumus", "examen", "in_manus_tuas", "nunc_dimittis",
                        "actiones_nostras", "aquinas_before_study", "prayer_for_travel",
                        "prayer_for_family", "parents_for_children", "prayer_for_the_sick", "happy_death",
                        "newman_definite_service", "lead_kindly_light"],
            topic: "Prayers through the Day",
            searchWords: ["daily prayers", "morning", "evening", "bedtime", "meals", "grace"]
        ),
        PrayerBookChapter(
            id: "penance", numeral: "VIII", title: "Confession", latinTitle: "De Pænitentia",
            icon: "ch-keys",
            epigraph: "For getting ready, confessing, and giving thanks afterwards.",
            prayerIDs: ["before_confession", "examination_of_conscience", "the_confession",
                        "confiteor", "act_of_contrition", "miserere", "after_confession", "beati_quorum"],
            topic: "Prayers for Confession",
            searchWords: ["penance", "contrition", "examination", "sorrow for sin"]
        ),
        PrayerBookChapter(
            id: "departed", numeral: "IX", title: "For Those Who Have Died", latinTitle: "Pro Defunctis",
            icon: "ch-candle",
            epigraph: "It is a holy and wholesome thought to pray for the dead.",
            prayerIDs: ["requiem_aeternam", "de_profundis", "fidelium_deus",
                        "deceased_parents", "st_gertrude"],
            topic: "Prayers for Those Who Have Died",
            searchWords: ["for the dead", "the dead", "the faithful departed", "departed", "holy souls",
                          "purgatory", "funeral"]
        ),
        PrayerBookChapter(
            id: "church", numeral: "X", title: "The Church", latinTitle: "Pro Ecclesia",
            icon: "ch-church",
            epigraph: "For the Pope, for the Church, and in thanksgiving for both.",
            prayerIDs: ["prayer_for_the_pope", "te_deum", "st_michael_prayer", "rosary_closing_prayer",
                        "prayer_for_priests", "conversion_of_sinners", "da_pacem", "prayer_for_our_country"],
            topic: "Prayers for the Church",
            searchWords: ["the pope", "holy father", "thanksgiving"]
        ),
        PrayerBookChapter(
            id: "litanies", numeral: "XI", title: "Litanies", latinTitle: "Litaniæ",
            icon: "lv-procession-cross",
            epigraph: "Titles called out one after another, and a response to every one.",
            prayerIDs: ["litany_loreto", "litany_holy_name", "litany_sacred_heart", "litany_st_joseph",
                        "litany_of_humility",
                        "litany_of_the_saints", "litany_holy_ghost", "litany_precious_blood",
                        "litany_blessed_sacrament", "litany_seven_sorrows"],
            topic: "Litanies",
            searchWords: ["the litanies", "litany"]
        ),
        PrayerBookChapter(
            id: "short", numeral: "XII", title: "Short Prayers", latinTitle: "Iaculatoriæ",
            icon: "lv-dart",
            epigraph: "A breath of prayer, said in passing through the day.",
            prayerIDs: ["jmj", "sweet_heart", "jesus_meek", "my_jesus_mercy", "pardon_prayer",
                        "miraculous_medal", "blessed_be_conception", "totus_tuus", "requiem_aeternam",
                        "my_god_and_my_all", "my_lord_and_my_god", "jesus_i_trust_in_thee",
                        "sacred_heart_trust", "my_jesus_i_love_thee", "o_sacrament_most_holy",
                        "holy_spirit_enlighten", "st_joseph_pray", "jmj_heart_and_soul"],
            topic: "Short Prayers",
            searchWords: ["ejaculations", "aspirations", "aspiration"]
        )
    ]

    /// A line under a chapter's name in the All Prayers list, where the
    /// name alone is a Church word a newcomer may not know
    static let chapterNotes: [String: String] = [
        "sacrament": "Jesus present in the Host",
        "litanies": "Short petitions, each with the same response",
    ]

    static func chapter(_ id: String) -> PrayerBookChapter? {
        chapters.first { $0.id == id }
    }

    /// The first chapter a prayer is printed in — its home in the book
    static func homeChapter(of prayerID: String) -> PrayerBookChapter? {
        chapters.first { $0.prayerIDs.contains(prayerID) }
    }

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

    static func order(_ id: String) -> PrayerOrder? {
        orders.first { $0.id == id }
    }

    /// The three orders that keep the hours of an ordinary day
    static var dayOrders: [PrayerOrder] {
        [morningOrderID, angelusOrderID, nightOrderID].compactMap { order($0) }
    }

    /// The orders kept for an occasion rather than an hour
    static var occasionOrders: [PrayerOrder] {
        let day = Set([morningOrderID, angelusOrderID, nightOrderID])
        return orders.filter { !day.contains($0.id) }
    }

    /// Where the reader is when they pray an occasion's order — the
    /// Prayers page's four places, each with the orders kept there
    static func ordersKept(at place: PrayerOccasionPlace) -> [PrayerOrder] {
        place.orderIDs.compactMap { order($0) }
    }

    /// The hour the book's day begins. Morning Prayers are said from
    /// four, and Night Prayers said after midnight belong to the night
    /// before, not to the day they spill into.
    nonisolated static let dayBeginsAtHour = 4

    /// Which of the day's three orders the hour belongs to: the morning
    /// until eleven, the Angelus through the noon and evening bells
    /// until eight, and night after that.
    static func dayOrder(at date: Date = Date(), calendar: Calendar = .current) -> PrayerOrder {
        let hour = calendar.component(.hour, from: date)
        let id: String
        switch hour {
        case dayBeginsAtHour..<11:  id = morningOrderID
        case 11..<20: id = angelusOrderID
        default:      id = nightOrderID
        }
        return order(id)!
    }

    /// When the hour's order is said, in the words every surface that
    /// names it shares — the Prayers page's strip, home's hour row and
    /// the Chapel's Prayers tile: "On waking", "At noon", "At 6 PM", "At
    /// bedtime"
    nonisolated static func dayOrderMoment(
        at date: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case dayBeginsAtHour..<11:  return "On waking"
        case 11..<15: return "At noon"
        case 15..<20: return "At 6 PM"
        default:      return "At bedtime"
        }
    }

    /// The next moment the book's hour turns — the order for the hour, or
    /// the moment it names, giving way: four, eleven, three and eight
    /// o'clock. Read off `dayOrderMoment` itself, whose turns include
    /// `dayOrder`'s and the book's day's, so the three can never disagree.
    /// None of them is an hour of the Office, so `CanonicalClock` sleeps
    /// through every one.
    nonisolated static func nextTurn(after date: Date, calendar: Calendar = .current) -> Date {
        let moment = dayOrderMoment(at: date, calendar: calendar)
        var hour = calendar.dateInterval(of: .hour, for: date)?.start ?? date
        for _ in 0..<24 {
            guard let next = calendar.date(byAdding: .hour, value: 1, to: hour) else { break }
            hour = next
            if dayOrderMoment(at: hour, calendar: calendar) != moment { return hour }
        }
        return date.addingTimeInterval(3600)
    }

    // MARK: The day's three hours, in plain words

    /// What the Prayers page calls one of the day's three orders on its
    /// strip of hours: MORNING, NOON, EVENING, NIGHT. The middle station is
    /// the Angelus at noon and at 6 PM, named for the bell being kept
    /// (`angelusBellKept`), which is also the bell its PRAYED reads:
    /// NOON until three, the noon bell still to come before eleven, and
    /// EVENING from three until the day turns at four. The six o'clock
    /// morning bell has no station of its own, since MORNING is Morning
    /// Prayers', so the strip never says NOON at five, nor NOON offered
    /// for an Angelus said at the evening bell. (`offered` names the
    /// state in code; the reader sees PRAYED.)
    static func hourName(of order: PrayerOrder, at date: Date = Date(), calendar: Calendar = .current) -> String {
        switch order.id {
        case morningOrderID: return "Morning"
        case nightOrderID:   return "Night"
        default:             return angelusBellKept(at: date, calendar: calendar).name
        }
    }

    /// Where one of the day's orders stands at `date`: prayed today (the
    /// reader sees "Prayed"), the hour it is now, or when it is said, in
    /// `dayOrderMoment`'s words. Never "missed" — a morning not prayed by
    /// night still reads "On waking".
    enum HourStanding: Equatable {
        case offered
        case now
        case at(String)
    }

    static func standing(
        of order: PrayerOrder,
        at date: Date = Date(),
        offered: Bool,
        calendar: Calendar = .current
    ) -> HourStanding {
        if offered { return .offered }
        if dayOrder(at: date, calendar: calendar).id == order.id { return .now }
        switch order.id {
        case morningOrderID: return .at("On waking")
        case nightOrderID:   return .at("At bedtime")
        default:
            return .at(angelusBellKept(at: date, calendar: calendar) == .evening ? "At 6 PM" : "At noon")
        }
    }

    /// The two Angelus bells the Prayers page's strip keeps: noon's and the
    /// evening's. The bell at six in the morning has no station of its
    /// own; an Angelus said then counts for the day (`wasOffered`), which
    /// is the rule's measure, but not for the noon bell still to come.
    enum AngelusBell: Equatable {
        case noon
        case evening

        /// The bell's name on the strip
        var name: String {
            switch self {
            case .noon:    return "Noon"
            case .evening: return "Evening"
            }
        }

        /// The clock hour from which an Angelus said counts for the bell
        var keptFromHour: Int {
            switch self {
            case .noon:    return 11
            case .evening: return 15
            }
        }
    }

    /// The Angelus bell being kept at `date`: noon's from the day's turn at
    /// four, still to come before eleven, and the evening's from three on
    /// past midnight, until the day turns again
    static func angelusBellKept(at date: Date = Date(), calendar: Calendar = .current) -> AngelusBell {
        let hour = calendar.component(.hour, from: date)
        return hour < dayBeginsAtHour || hour >= AngelusBell.evening.keptFromHour ? .evening : .noon
    }

    /// From when an Angelus said counts for the bell being kept: noon's
    /// from eleven, the evening's from three, and after midnight still the
    /// evening before's, as the prayer day keeps it. Before eleven it is
    /// noon's eleven o'clock, still ahead, so nothing yet offers it: an
    /// Angelus said at six in the morning leaves PRAY THE ANGELUS, not
    /// AGAIN. One prayed at noon is the noon bell's; by evening the evening
    /// bell asks for its own. The rule of prayer still counts the Angelus
    /// once a day (`wasOffered`); only the Prayers page's strip keeps the
    /// bells apart.
    static func angelusBellBegan(at date: Date = Date(), calendar: Calendar = .current) -> Date {
        let hour = calendar.component(.hour, from: date)
        let today = calendar.startOfDay(for: date)
        let day = hour < dayBeginsAtHour
            ? calendar.date(byAdding: .day, value: -1, to: today) ?? today
            : today
        let bell = angelusBellKept(at: date, calendar: calendar)
        return calendar.date(bySettingHour: bell.keptFromHour, minute: 0, second: 0, of: day) ?? day
    }

    /// Whether `order` is offered for the hour it is now: the day's offering
    /// for most, and the bell's for the Angelus
    static func isOfferedNow(
        _ order: PrayerOrder,
        at date: Date = Date(),
        offeredToday: Bool,
        lastOffered: Date?,
        calendar: Calendar = .current
    ) -> Bool {
        guard offeredToday else { return false }
        guard order.id == angelusOrderID else { return true }
        guard let lastOffered else { return false }
        return lastOffered >= angelusBellBegan(at: date, calendar: calendar) && lastOffered <= date
    }

    /// One plain line saying what one of the day's three orders is, as
    /// the Prayers page's card sets it under the order's name: the
    /// Angelus at its three hours, Queen of Heaven in its place in the
    /// Easter season with its Latin name beneath the English, and Night
    /// Prayers ending on the season's song to Mary. Any other order is
    /// its own detail.
    static func daySummary(of order: PrayerOrder, on date: Date = Date()) -> String {
        switch order.id {
        case morningOrderID:
            return "A few short prayers on waking, giving the day to God."
        case angelusOrderID:
            return isEastertide(date)
                ? "Regina Cæli: a short Easter prayer to Mary, said instead of the Angelus from Easter to Pentecost."
                : "A short prayer to Mary, said at 6 AM, noon and 6 PM."
        case nightOrderID:
            return "Look back on the day, ask God's forgiveness, and end with this season's song to Mary: \(antiphon(on: date).name)."
        default:
            return order.detail
        }
    }

    // MARK: Our Lady's best-known prayers

    /// The three of her prayers the Prayers page sets beneath the
    /// season's song to Mary — the ones most Catholics know by heart
    static let bestKnownMarianIDs = ["hail_mary", "memorare", "litany_loreto"]

    // MARK: Seasons

    /// Easter Sunday to the Saturday after Pentecost: Queen of Heaven
    /// (the Regina Cæli) stands in the Angelus's place
    static func isEastertide(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: day)
        guard let easter = ScheduleService.easterSunday(year: year, calendar: calendar),
              let trinity = calendar.date(byAdding: .day, value: 56, to: easter)
        else { return false }
        return day >= easter && day < trinity
    }

    /// The song to Mary the Church sings at Bedtime Prayer on `date`
    static func antiphon(on date: Date, calendar: Calendar = .current) -> MarianAntiphon {
        let day = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: day)

        if let advent = ScheduleService.adventStart(year: year, calendar: calendar),
           let eve = calendar.date(byAdding: .day, value: -1, to: advent),
           day >= eve {
            return .almaRedemptoris
        }
        guard let purification = calendar.date(from: DateComponents(year: year, month: 2, day: 2)),
              let easter = ScheduleService.easterSunday(year: year, calendar: calendar),
              let trinityEve = calendar.date(byAdding: .day, value: 55, to: easter)
        else { return .salveRegina }

        if day < purification { return .almaRedemptoris }
        if day < easter { return .aveReginaCaelorum }
        if day < trinityEve { return .reginaCaeli }
        return .salveRegina
    }

    // MARK: Search

    /// The English set beneath a prayer that is known by its Latin name,
    /// where its Latin would only say the name again
    static let englishNames: [String: String] = [
        "memorare": "Remember, O most gracious Virgin Mary",
    ]

    /// Whether two names are one name, whatever their case, accents or
    /// leading article: "Tantum Ergo" and "Tantum ergo", "The Memorare"
    /// and "Memorare"
    static func isSameName(_ one: String, _ other: String) -> Bool {
        func bare(_ name: String) -> String {
            let folded = folded(name)
            return folded.hasPrefix("the ") ? String(folded.dropFirst(4)) : folded
        }
        return bare(one) == bare(other)
    }

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

    /// The other names a prayer is looked for by
    static let prayerSearchWords: [String: [String]] = [
        "litany_loreto": ["litany of loreto", "loretto", "litany of our lady"],
        "peace_prayer": ["prayer of st francis", "instrument of thy peace", "instrument of your peace"],
        "divine_mercy_chaplet": ["divine mercy", "chaplet", "st faustina"],
        "efficacious_novena": ["novena", "padre pio"],
        "litany_of_the_saints": ["all saints", "litaniae sanctorum"],
        "litany_seven_sorrows": ["our lady of sorrows", "seven sorrows"],
        "st_anthony": ["lost things", "anthony of padua"],
        "st_jude": ["hopeless cases", "desperate cases"],
        "st_peregrine": ["cancer"],
        "prayer_for_travel": ["journey", "travel", "itinerarium"],
        "aquinas_before_study": ["study", "students", "exams"],
        "prayer_for_the_sick": ["sick", "illness", "healing"],
        "lead_kindly_light": ["newman"],
        "newman_definite_service": ["newman", "purpose"],
        "christ_the_king": ["consecration to christ the king"],
        "consecration_sacred_heart": ["sacred heart", "enthronement"],
        "st_benedict_medal": ["vade retro satana", "benedict medal", "exorcism"],
        "hail_holy_queen": ["salve regina"],
        "st_michael_prayer": ["st michael", "michael the archangel"],
        "ad_te_beate_ioseph": ["st joseph", "prayer to st joseph"],
        "angele_dei": ["guardian angel"],
        "memorare": ["remember o most gracious"],
        "anima_christi": ["soul of christ"],
        "regina_caeli": ["queen of heaven rejoice"],
    ]

    /// The other names an order of prayer is looked for by
    static let orderSearchWords: [String: [String]] = [
        "visit": ["blessed sacrament", "visit to the blessed sacrament", "adoration", "tabernacle"],
        "table": ["grace", "meals", "at table"],
        "holy_souls": ["purgatory", "the dead", "for the dead", "holy souls", "for the holy souls"],
        "trouble": ["help", "danger"],
    ]

    /// Prayers a search finds. A name answers when every word searched
    /// begins one of its words — "St Joseph", "loreto", "hail ma" — the
    /// title, the Latin title and the names it is looked for by alike,
    /// with "st", "st." and "saint" one word; a prayer whose words hold
    /// the whole search comes after the names. It once matched only the
    /// whole search as one string, so "St Michael" found nothing.
    static func search(_ needle: String) -> [BookPrayer] {
        let wanted = searchWords(needle, asName: false)
        guard !wanted.isEmpty else { return [] }

        let phrase = folded(needle).trimmingCharacters(in: .whitespacesAndNewlines)

        var named: [BookPrayer] = []
        var worded: [BookPrayer] = []
        for chapter in chapters {
            for prayer in chapter.prayers where !named.contains(prayer) && !worded.contains(prayer) {
                let names = [prayer.title, prayer.listTitle, prayer.latinTitle ?? ""] + prayer.searchWords
                if names.contains(where: { nameAnswers(wanted, $0) }) {
                    named.append(prayer)
                } else if phrase.count >= 4,
                          folded(prayer.english).contains(phrase) || folded(prayer.latin ?? "").contains(phrase) {
                    worded.append(prayer)
                }
            }
        }
        return named + worded
    }

    /// The orders of prayer a search names — "blessed sacrament" finds
    /// Visiting Jesus in Church — by their title, Latin title, when they
    /// are said and the names they are looked for by
    static func searchOrders(_ needle: String) -> [PrayerOrder] {
        let wanted = searchWords(needle, asName: false)
        guard !wanted.isEmpty, wanted.joined().count >= 3 else { return [] }
        return orders.filter { order in
            let names = [order.title, order.latinTitle, order.occasion] + order.searchWords
            return names.contains { nameAnswers(wanted, $0) }
        }
    }

    /// Every word wanted begins one of the name's words. A lone "st"
    /// searched is a saint's or the start of a word, so it finds St
    /// Michael and the Stabat Mater alike.
    private static func nameAnswers(_ wanted: [String], _ name: String) -> Bool {
        let words = searchWords(name)
        return !words.isEmpty && wanted.allSatisfy { want in
            words.contains { $0.hasPrefix(want) || (want == "st" && $0 == "saint") }
        }
    }

    /// Text as the searches read it: case and accents let go, and the
    /// ligatures the Latin is printed with written out, so "regina caeli"
    /// finds the Regina Cæli and "praesidium" the Sub tuum præsidium
    private static func folded(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "Æ", with: "ae")
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "Œ", with: "oe")
    }

    /// A name or a search as the prayer search reads it: folded, split
    /// into words, the words that name nothing ("the", "of", "to") left
    /// out, unless they are all there is. In a name, "st" and "st." read
    /// as "saint"; searched, "st" stays as typed (`nameAnswers`).
    private static func searchWords(_ text: String, asName: Bool = true) -> [String] {
        let words = folded(text)
            .split { !$0.isLetter }
            .map { asName && $0 == "st" ? "saint" : String($0) }
        let kept = words.filter { !searchStopWords.contains($0) }
        return kept.isEmpty ? words : kept
    }

    private static let searchStopWords: Set<String> = ["a", "an", "and", "of", "the", "to", "o", "for", "in", "on", "at"]

    /// The chapters a search names as topics: "mary" finds Prayers to
    /// Mary, "holy ghost" the Holy Spirit's, under the names the book
    /// once printed as well as its own. Every word searched must begin a
    /// word of the topic's name, so "hail mary" finds the prayer and not
    /// the whole chapter, and the small words — "the", "prayers", "to" —
    /// count for nothing, or every topic would answer "pra".
    static func topics(matching needle: String) -> [PrayerBookChapter] {
        let wanted = topicWords(needle)
        guard let last = wanted.last, wanted.joined().count >= 3, last.count >= 2 else { return [] }

        return chapters.filter { chapter in
            let names = [chapter.title, chapter.topic, chapter.latinTitle] + chapter.searchWords
            return names.contains { name in
                let words = topicWords(name)
                return !words.isEmpty && wanted.allSatisfy { want in
                    words.contains { $0.hasPrefix(want) }
                }
            }
        }
    }

    private static let topicStopWords: Set<String> = [
        "a", "an", "and", "at", "for", "in", "of", "on", "the", "to", "with",
        "pray", "prayer", "prayers"
    ]

    /// A name as the topic search reads it: folded, split into words,
    /// the small words dropped
    private static func topicWords(_ text: String) -> [String] {
        folded(text)
            .split { !$0.isLetter }
            .map(String.init)
            .filter { !topicStopWords.contains($0) }
    }
}

// MARK: - PrayerOccasionPlace

/// Where the reader is, on the Prayers page's Occasions: at Mass, at
/// Confession, at home, or in need. Each keeps the orders said there, so
/// a reader picks where they are rather than reading a grid of eight.
enum PrayerOccasionPlace: String, CaseIterable, Identifiable {
    case mass
    case confession
    case home
    case need

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mass:       return "At Mass"
        case .confession: return "At Confession"
        case .home:       return "At Home"
        case .need:       return "In Need"
        }
    }

    /// The occasion orders kept here, in the order they are prayed
    var orderIDs: [String] {
        switch self {
        case .mass:       return ["before_mass", "after_mass", "visit"]
        case .confession: return ["before_confession", "after_confession"]
        case .home:       return ["table", "holy_souls"]
        case .need:       return ["trouble"]
        }
    }
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
    static let title = "Prayers Tab"

    /// The Prayer Book's door glyph
    static let icon = "ch-praying-hands"

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
