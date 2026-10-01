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
    /// Bernard of Clairvaux · XII century"
    let origin: String?

    /// When or how it is said, in one plain sentence
    let note: String?

    let english: String

    /// Nil when the prayer has no Latin of its own
    let latin: String?

    var hasLatin: Bool { latin != nil }

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

    /// When it is prayed, as a kicker — "ON RISING"
    let occasion: String

    /// One italic line saying what the order is
    let detail: String

    /// Its prayers on a given day. Most never change; the Angelus gives
    /// way to the Regina Cæli in Eastertide, and Night Prayers close on
    /// the antiphon of Our Lady that the season sings.
    let prayerIDs: (Date) -> [String]

    func prayers(on date: Date = Date()) -> [BookPrayer] {
        prayerIDs(date).compactMap { PrayerBook.prayer($0) }
    }

    /// The order's name on a given day — the Angelus is the Regina Cæli
    /// in Eastertide, and says so
    func title(on date: Date = Date()) -> String {
        if id == PrayerBook.angelusOrderID, PrayerBook.isEastertide(date) {
            return "The Regina Cæli"
        }
        return title
    }

    static func == (lhs: PrayerOrder, rhs: PrayerOrder) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - The seasons of Our Lady's antiphon

/// The four antiphons of Our Lady, each sung at the close of the day
/// through its own part of the year — the last words of Compline, and
/// so the last words of Night Prayers here.
enum MarianAntiphon: CaseIterable {
    case almaRedemptoris
    case aveReginaCaelorum
    case reginaCaeli
    case salveRegina

    var prayerID: String {
        switch self {
        case .almaRedemptoris:   return "alma_redemptoris"
        case .aveReginaCaelorum: return "ave_regina_caelorum"
        case .reginaCaeli:       return "regina_caeli"
        case .salveRegina:       return "hail_holy_queen"
        }
    }

    /// The part of the year it keeps, in words
    var season: String {
        switch self {
        case .almaRedemptoris:   return "Advent to the Purification"
        case .aveReginaCaelorum: return "The Purification to Holy Week"
        case .reginaCaeli:       return "Eastertide"
        case .salveRegina:       return "Trinity Sunday to Advent"
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
        BookPrayer.bundled("hail_mary", origin: "Luke 1:28, 42 · the Church, XV century",
                           note: "The Angel's greeting and Elizabeth's, and the Church's petition after them."),
        BookPrayer.bundled("glory_be", origin: "The Church · IV century",
                           note: "The lesser doxology, closing psalms, decades, and every hour of the Office."),
        BookPrayer.bundled("apostles_creed", origin: "The Roman Church · II century",
                           note: "The baptismal creed of Rome, the faith of the Apostles in twelve articles."),
        BookPrayer.bundled("fatima_prayer", title: "The Fatima Prayer", origin: "Our Lady of Fatima · 1917",
                           note: "Asked by Our Lady at Fatima to be said after the Glory Be of every decade."),
        BookPrayer.bundled("hail_holy_queen", origin: "Western Church · XI century",
                           note: "Sung at the close of Compline from Trinity Sunday to Advent, and said at the end of the Rosary."),
        BookPrayer.bundled("memorare", origin: "Attributed to St Bernard of Clairvaux · XII century",
                           note: "Spread by Fr Claude Bernard in the seventeenth century, who owed his own conversion to it."),
        BookPrayer.bundled("act_of_contrition", origin: "Traditional",
                           note: "Said in the confessional, and each night before sleep."),
        BookPrayer.bundled("st_michael_prayer", origin: "Pope Leo XIII · 1886",
                           note: "Once said kneeling after every Low Mass, for the defence of the Church."),
        BookPrayer.bundled("sorrows_closing_prayer", title: "To Our Lady of Sorrows", origin: "The Servite chaplet",
                           note: "The prayer that closes the chaplet of the Seven Sorrows."),
        BookPrayer.bundled("rosary_closing_prayer", title: "Prayer after the Rosary", origin: "Roman Missal · the Rosary's collect",
                           note: "The collect of the feast of the Holy Rosary, said when the beads are done."),
        BookPrayer.bundled("veni_creator", origin: "Attributed to Rabanus Maurus · IX century",
                           note: "Sung at Pentecost, at ordinations, and whenever the Church asks the Holy Ghost to come."),
        BookPrayer.bundled("ave_maris_stella", origin: "Western Church · IX century",
                           note: "The Vespers hymn of Our Lady's feasts."),
        BookPrayer.bundled("magnificat", origin: "Our Lady · Luke 1:46–55",
                           note: "Our Lady's own song at the Visitation, sung every evening at Vespers."),
        BookPrayer.bundled("litany_loreto", origin: "The Holy House of Loreto · XVI century",
                           note: "Sung at Loreto since the 1550s, and approved for the whole Church in 1587."),
        BookPrayer.bundled("litany_holy_name", origin: "St Bernardine of Siena · XV century",
                           note: "A litany to the Holy Name, approved for the whole Church in 1862."),
        BookPrayer.bundled("o_jesus_living_in_mary", origin: "Fr Charles de Condren · XVII century",
                           note: "Prayed each day of Montfort's preparation for consecration.")
    ].compactMap { $0 }

    // MARK: Chapters

    static let chapters: [PrayerBookChapter] = [
        PrayerBookChapter(
            id: "first", numeral: "I", title: "Basic Prayers", latinTitle: "Orationes Primæ",
            icon: "ch-praying-hands",
            epigraph: "Learned at a mother's knee, and said until the last day.",
            prayerIDs: ["sign_of_cross", "our_father", "hail_mary", "glory_be", "apostles_creed",
                        "nicene_creed", "act_of_faith", "act_of_hope", "act_of_charity",
                        "act_of_contrition", "fatima_prayer"],
            topic: "Basic Prayers",
            searchWords: ["first prayers", "the first prayers", "basics", "creed", "acts"]
        ),
        PrayerBookChapter(
            id: "our_lady", numeral: "II", title: "Mary", latinTitle: "De Beata Maria Virgine",
            icon: "ch-lily",
            epigraph: "From the oldest prayer to her the Church keeps, to the youngest.",
            prayerIDs: ["hail_mary", "sub_tuum", "angelus", "regina_caeli", "hail_holy_queen",
                        "alma_redemptoris", "ave_regina_caelorum", "memorare", "magnificat",
                        "ave_maris_stella", "stabat_mater", "tota_pulchra", "flos_carmeli",
                        "litany_loreto", "o_domina_mea", "perpetual_help", "three_hail_marys",
                        "miraculous_medal", "mary_after_communion", "sorrows_closing_prayer"],
            topic: "Prayers to Mary",
            searchWords: ["our lady", "the virgin", "virgin mary", "blessed virgin", "marian", "mother of god"]
        ),
        PrayerBookChapter(
            id: "our_lord", numeral: "III", title: "Jesus", latinTitle: "De Domino Nostro",
            icon: "ch-chi-rho",
            epigraph: "To Christ, Who is the way to the Father.",
            prayerIDs: ["anima_christi", "en_ego", "jesus_prayer", "st_richard", "suscipe",
                        "o_jesus_living_in_mary", "litany_holy_name", "litany_sacred_heart"],
            topic: "Prayers to Jesus",
            searchWords: ["our lord", "christ", "sacred heart", "holy name"]
        ),
        PrayerBookChapter(
            id: "sacrament", numeral: "IV", title: "The Eucharist", latinTitle: "De Sanctissimo Sacramento",
            icon: "ch-monstrance",
            epigraph: "Before the altar, at Mass, and in the hour after it.",
            prayerIDs: ["aquinas_before_mass", "spiritual_communion", "adoro_te", "ave_verum",
                        "o_sacrum_convivium", "o_salutaris", "tantum_ergo", "divine_praises",
                        "aquinas_after_mass"],
            topic: "Prayers of the Eucharist",
            searchWords: ["blessed sacrament", "holy communion", "communion", "adoration", "benediction", "the mass"]
        ),
        PrayerBookChapter(
            id: "holy_ghost", numeral: "V", title: "The Holy Spirit", latinTitle: "De Spiritu Sancto",
            icon: "ch-dove",
            epigraph: "Asked for light before any work of the soul.",
            prayerIDs: ["come_holy_ghost", "veni_creator", "veni_sancte_spiritus"],
            topic: "Prayers to the Holy Spirit",
            searchWords: ["holy ghost", "the holy ghost", "paraclete", "pentecost"]
        ),
        PrayerBookChapter(
            id: "saints", numeral: "VI", title: "Angels and Saints", latinTitle: "De Angelis et Sanctis",
            icon: "lv-saint",
            epigraph: "The friends of God, asked to pray for us.",
            prayerIDs: ["angele_dei", "st_michael_prayer", "ad_te_beate_ioseph", "litany_st_joseph",
                        "st_patrick_breastplate"],
            topic: "Prayers to the Angels and Saints",
            searchWords: ["angels", "saints", "guardian angel", "archangel"]
        ),
        PrayerBookChapter(
            id: "day", numeral: "VII", title: "Through the Day", latinTitle: "Per Diem",
            icon: "lv-hourglass",
            epigraph: "On rising, at table, at evening, and at the day's end.",
            prayerIDs: ["morning_offering", "benedictus", "grace_before", "grace_after",
                        "visita_quaesumus", "examen", "in_manus_tuas", "nunc_dimittis"],
            topic: "Prayers through the Day",
            searchWords: ["daily prayers", "morning", "evening", "bedtime", "meals", "grace"]
        ),
        PrayerBookChapter(
            id: "penance", numeral: "VIII", title: "Confession", latinTitle: "De Pænitentia",
            icon: "ch-keys",
            epigraph: "For the examination, the confession, and the thanks after it.",
            prayerIDs: ["before_confession", "examination_of_conscience", "the_confession",
                        "confiteor", "act_of_contrition", "miserere", "after_confession", "beati_quorum"],
            topic: "Prayers for Confession",
            searchWords: ["penance", "contrition", "examination", "sorrow for sin"]
        ),
        PrayerBookChapter(
            id: "departed", numeral: "IX", title: "For the Dead", latinTitle: "Pro Defunctis",
            icon: "ch-candle",
            epigraph: "It is a holy and wholesome thought to pray for the dead.",
            prayerIDs: ["requiem_aeternam", "de_profundis", "fidelium_deus"],
            topic: "Prayers for the Dead",
            searchWords: ["the faithful departed", "departed", "holy souls", "purgatory", "funeral"]
        ),
        PrayerBookChapter(
            id: "church", numeral: "X", title: "The Church", latinTitle: "Pro Ecclesia",
            icon: "ch-church",
            epigraph: "For the Pope, for the Church, and in thanksgiving for both.",
            prayerIDs: ["prayer_for_the_pope", "te_deum", "st_michael_prayer", "rosary_closing_prayer"],
            topic: "Prayers for the Church",
            searchWords: ["the pope", "holy father", "thanksgiving"]
        ),
        PrayerBookChapter(
            id: "litanies", numeral: "XI", title: "Litanies", latinTitle: "Litaniæ",
            icon: "lv-procession-cross",
            epigraph: "Titles called out one after another, and a response to every one.",
            prayerIDs: ["litany_loreto", "litany_holy_name", "litany_sacred_heart", "litany_st_joseph",
                        "litany_of_humility"],
            topic: "Litanies",
            searchWords: ["the litanies", "litany"]
        ),
        PrayerBookChapter(
            id: "short", numeral: "XII", title: "Short Prayers", latinTitle: "Iaculatoriæ",
            icon: "lv-dart",
            epigraph: "A breath of prayer, said in passing through the day.",
            prayerIDs: ["jmj", "sweet_heart", "jesus_meek", "my_jesus_mercy", "pardon_prayer",
                        "miraculous_medal", "blessed_be_conception", "totus_tuus", "requiem_aeternam"],
            topic: "Short Prayers",
            searchWords: ["ejaculations", "aspirations", "aspiration"]
        )
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
            icon: "lv-rooster", occasion: "On rising",
            detail: "The day offered before it is begun.",
            prayerIDs: { _ in
                ["sign_of_cross", "morning_offering", "our_father", "hail_mary", "glory_be",
                 "act_of_faith", "act_of_hope", "act_of_charity", "angele_dei"]
            }
        ),
        PrayerOrder(
            id: angelusOrderID, title: "The Angelus", latinTitle: "Angelus Domini",
            icon: "lv-bell", occasion: "At six, noon and six",
            detail: "The Incarnation remembered three times a day, when the bell rings.",
            prayerIDs: { date in [isEastertide(date) ? "regina_caeli" : "angelus"] }
        ),
        PrayerOrder(
            id: nightOrderID, title: "Night Prayers", latinTitle: "Preces Vespertinæ",
            icon: "lv-lamp", occasion: "Before sleep",
            detail: "The day examined and given back, closing on Our Lady's antiphon.",
            prayerIDs: { date in
                ["sign_of_cross", "examen", "act_of_contrition", "in_manus_tuas",
                 "visita_quaesumus", antiphon(on: date).prayerID]
            }
        ),
        PrayerOrder(
            id: "table", title: "At Table", latinTitle: "Benedictio Mensæ",
            icon: "ch-bread", occasion: "Before and after meals",
            detail: "Grace before the meal, and thanks when it is done.",
            prayerIDs: { _ in ["grace_before", "grace_after"] }
        ),
        PrayerOrder(
            id: "before_mass", title: "Before Mass", latinTitle: "Præparatio ad Missam",
            icon: "ch-altar", occasion: "In the pew, before Mass begins",
            detail: "Light asked for, the heart made ready, and faith, hope and love renewed.",
            prayerIDs: { _ in
                ["sign_of_cross", "come_holy_ghost", "aquinas_before_mass",
                 "act_of_faith", "act_of_hope", "act_of_charity"]
            }
        ),
        PrayerOrder(
            id: "after_mass", title: "After Communion", latinTitle: "Gratiarum Actio",
            icon: "ch-chalice", occasion: "In thanksgiving, after Mass",
            detail: "The minutes after Communion, when He is closest.",
            prayerIDs: { _ in
                ["anima_christi", "en_ego", "aquinas_after_mass", "mary_after_communion", "suscipe"]
            }
        ),
        PrayerOrder(
            id: "before_confession", title: "Before Confession", latinTitle: "Ante Confessionem",
            icon: "ch-keys", occasion: "Before going in",
            detail: "Light to see, the commandments to see by, and sorrow for what is seen.",
            prayerIDs: { _ in
                ["sign_of_cross", "come_holy_ghost", "before_confession",
                 "examination_of_conscience", "act_of_contrition", "the_confession"]
            }
        ),
        PrayerOrder(
            id: "after_confession", title: "After Confession", latinTitle: "Post Confessionem",
            icon: "ch-keys", occasion: "Kneeling afterwards",
            detail: "The penance said, and thanks given for mercy.",
            prayerIDs: { _ in ["after_confession", "beati_quorum", "hail_mary"] }
        ),
        PrayerOrder(
            id: "visit", title: "Visiting Jesus in Church", latinTitle: "Visitatio",
            icon: "ch-monstrance", occasion: "Before the tabernacle",
            detail: "A few minutes with Him in the tabernacle, or in spirit from wherever you are.",
            prayerIDs: { _ in
                ["adoro_te", "spiritual_communion", "o_sacrum_convivium", "tantum_ergo", "divine_praises"]
            }
        ),
        PrayerOrder(
            id: "holy_souls", title: "For the Holy Souls", latinTitle: "Pro Defunctis",
            icon: "ch-candle", occasion: "For those who have gone before us",
            detail: "For those who have gone before us, and wait.",
            prayerIDs: { _ in ["de_profundis", "requiem_aeternam", "fidelium_deus"] }
        ),
        PrayerOrder(
            id: "trouble", title: "In Time of Trouble", latinTitle: "In Tribulatione",
            icon: "ph-shield", occasion: "When you need help",
            detail: "The oldest prayers of refuge, to Our Lady and to St Michael.",
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
    static func orders(at place: PrayerOccasionPlace) -> [PrayerOrder] {
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

    /// The hour's order said as a kicker — "AT NOON", "BEFORE SLEEP" — or,
    /// `short`, as home's ledger sets it among its other facts: "AT SIX"
    nonisolated static func dayOrderMoment(
        at date: Date = Date(),
        calendar: Calendar = .current,
        short: Bool = false
    ) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case dayBeginsAtHour..<11:  return "On rising"
        case 11..<15: return "At noon"
        case 15..<20: return short ? "At six" : "At six in the evening"
        default:      return "Before sleep"
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
    /// strip of hours: MORNING, NOON, NIGHT. The Angelus's hour is noon
    /// until three and the evening after, when it is the six o'clock
    /// bell that is coming, so the strip never says NOON at five.
    static func hourName(of order: PrayerOrder, at date: Date = Date(), calendar: Calendar = .current) -> String {
        switch order.id {
        case morningOrderID: return "Morning"
        case nightOrderID:   return "Night"
        default:
            let hour = calendar.component(.hour, from: date)
            return (15..<20).contains(hour) ? "Evening" : "Noon"
        }
    }

    /// Where one of the day's orders stands at `date`: offered today,
    /// the hour it is now, or when it is said. Never "missed" — a
    /// morning not prayed by night still reads "On rising".
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
        case morningOrderID: return .at("On rising")
        case nightOrderID:   return .at("At bedtime")
        default:             return .at("At noon")
        }
    }

    // MARK: Our Lady's best-known prayers

    /// The three of her prayers the Prayers page sets beneath the
    /// season's antiphon — the ones most Catholics know by heart
    static let bestKnownMarianIDs = ["hail_mary", "memorare", "litany_loreto"]

    // MARK: Seasons

    /// Easter Sunday to the Saturday after Pentecost: the Regina Cæli
    /// stands in the Angelus's place
    static func isEastertide(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: day)
        guard let easter = ScheduleService.easterSunday(year: year, calendar: calendar),
              let trinity = calendar.date(byAdding: .day, value: 56, to: easter)
        else { return false }
        return day >= easter && day < trinity
    }

    /// The antiphon of Our Lady the Church sings at Compline on `date`
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

    /// Prayers whose name, Latin name or words hold `needle`. A match in
    /// the name ranks before a match in the text.
    static func search(_ needle: String) -> [BookPrayer] {
        let needle = needle.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        guard !needle.isEmpty else { return [] }

        func folded(_ s: String?) -> String {
            (s ?? "").folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        }

        var named: [BookPrayer] = []
        var worded: [BookPrayer] = []
        for chapter in chapters {
            for prayer in chapter.prayers where !named.contains(prayer) && !worded.contains(prayer) {
                if folded(prayer.title).contains(needle) || folded(prayer.latinTitle).contains(needle) {
                    named.append(prayer)
                } else if needle.count >= 4,
                          folded(prayer.english).contains(needle) || folded(prayer.latin).contains(needle) {
                    worded.append(prayer)
                }
            }
        }
        return named + worded
    }

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
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
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
        case .confession: return "Confession"
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

    /// The book's own name, so the row is never read as a second Audio
    static let title = "Prayer Book"

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
            return "Not yet chosen. The book asks the first time you pray along."
        }
        return aloud
            ? "Each prayer is said aloud as you pray along."
            : "The prayers stand on the page. You say them."
    }
}
