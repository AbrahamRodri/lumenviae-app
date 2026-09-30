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
            id: "first", numeral: "I", title: "The First Prayers", latinTitle: "Orationes Primæ",
            icon: "ph-hands-praying",
            epigraph: "Learned at a mother's knee, and said until the last day.",
            prayerIDs: ["sign_of_cross", "our_father", "hail_mary", "glory_be", "apostles_creed",
                        "nicene_creed", "act_of_faith", "act_of_hope", "act_of_charity",
                        "act_of_contrition", "fatima_prayer"]
        ),
        PrayerBookChapter(
            id: "our_lady", numeral: "II", title: "Our Lady", latinTitle: "De Beata Maria Virgine",
            icon: "ch-lily",
            epigraph: "From the oldest prayer to her the Church keeps, to the youngest.",
            prayerIDs: ["hail_mary", "sub_tuum", "angelus", "regina_caeli", "hail_holy_queen",
                        "alma_redemptoris", "ave_regina_caelorum", "memorare", "magnificat",
                        "ave_maris_stella", "stabat_mater", "tota_pulchra", "flos_carmeli",
                        "litany_loreto", "o_domina_mea", "perpetual_help", "three_hail_marys",
                        "miraculous_medal", "mary_after_communion", "sorrows_closing_prayer"]
        ),
        PrayerBookChapter(
            id: "our_lord", numeral: "III", title: "Our Lord", latinTitle: "De Domino Nostro",
            icon: "ch-crown-of-thorns",
            epigraph: "To Christ, Who is the way to the Father.",
            prayerIDs: ["anima_christi", "en_ego", "jesus_prayer", "st_richard", "suscipe",
                        "o_jesus_living_in_mary", "litany_holy_name", "litany_sacred_heart"]
        ),
        PrayerBookChapter(
            id: "sacrament", numeral: "IV", title: "The Blessed Sacrament", latinTitle: "De Sanctissimo Sacramento",
            icon: "ch-monstrance",
            epigraph: "Before the altar, at Mass, and in the hour after it.",
            prayerIDs: ["aquinas_before_mass", "spiritual_communion", "adoro_te", "ave_verum",
                        "o_sacrum_convivium", "o_salutaris", "tantum_ergo", "divine_praises",
                        "aquinas_after_mass"]
        ),
        PrayerBookChapter(
            id: "holy_ghost", numeral: "V", title: "The Holy Ghost", latinTitle: "De Spiritu Sancto",
            icon: "ph-bird",
            epigraph: "Asked for light before any work of the soul.",
            prayerIDs: ["come_holy_ghost", "veni_creator", "veni_sancte_spiritus"]
        ),
        PrayerBookChapter(
            id: "saints", numeral: "VI", title: "Angels and Saints", latinTitle: "De Angelis et Sanctis",
            icon: "ph-user",
            epigraph: "The friends of God, asked to pray for us.",
            prayerIDs: ["angele_dei", "st_michael_prayer", "ad_te_beate_ioseph", "litany_st_joseph",
                        "st_patrick_breastplate"]
        ),
        PrayerBookChapter(
            id: "day", numeral: "VII", title: "Through the Day", latinTitle: "Per Diem",
            icon: "ph-sun-horizon",
            epigraph: "On rising, at table, at evening, and at the day's end.",
            prayerIDs: ["morning_offering", "benedictus", "grace_before", "grace_after",
                        "visita_quaesumus", "examen", "in_manus_tuas", "nunc_dimittis"]
        ),
        PrayerBookChapter(
            id: "penance", numeral: "VIII", title: "Penance", latinTitle: "De Pænitentia",
            icon: "ph-chat-teardrop-text",
            epigraph: "For the examination, the confession, and the thanks after it.",
            prayerIDs: ["before_confession", "examination_of_conscience", "the_confession",
                        "confiteor", "act_of_contrition", "miserere", "after_confession", "beati_quorum"]
        ),
        PrayerBookChapter(
            id: "departed", numeral: "IX", title: "The Faithful Departed", latinTitle: "Pro Defunctis",
            icon: "ch-candle",
            epigraph: "It is a holy and wholesome thought to pray for the dead.",
            prayerIDs: ["requiem_aeternam", "de_profundis", "fidelium_deus"]
        ),
        PrayerBookChapter(
            id: "church", numeral: "X", title: "The Church", latinTitle: "Pro Ecclesia",
            icon: "ch-church",
            epigraph: "For the Pope, for the Church, and in thanksgiving for both.",
            prayerIDs: ["prayer_for_the_pope", "te_deum", "st_michael_prayer", "rosary_closing_prayer"]
        ),
        PrayerBookChapter(
            id: "litanies", numeral: "XI", title: "The Litanies", latinTitle: "Litaniæ",
            icon: "ph-list",
            epigraph: "Titles called out one after another, and a response to every one.",
            prayerIDs: ["litany_loreto", "litany_holy_name", "litany_sacred_heart", "litany_st_joseph",
                        "litany_of_humility"]
        ),
        PrayerBookChapter(
            id: "short", numeral: "XII", title: "Short Prayers", latinTitle: "Iaculatoriæ",
            icon: "ph-sparkle",
            epigraph: "A breath of prayer, said in passing through the day.",
            prayerIDs: ["jmj", "sweet_heart", "jesus_meek", "my_jesus_mercy", "pardon_prayer",
                        "miraculous_medal", "blessed_be_conception", "totus_tuus", "requiem_aeternam"]
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
            icon: "ph-sun-horizon", occasion: "On rising",
            detail: "The day offered before it is begun.",
            prayerIDs: { _ in
                ["sign_of_cross", "morning_offering", "our_father", "hail_mary", "glory_be",
                 "act_of_faith", "act_of_hope", "act_of_charity", "angele_dei"]
            }
        ),
        PrayerOrder(
            id: angelusOrderID, title: "The Angelus", latinTitle: "Angelus Domini",
            icon: "ph-bell", occasion: "At six, noon and six",
            detail: "The Incarnation remembered three times a day, when the bell rings.",
            prayerIDs: { date in [isEastertide(date) ? "regina_caeli" : "angelus"] }
        ),
        PrayerOrder(
            id: nightOrderID, title: "Night Prayers", latinTitle: "Preces Vespertinæ",
            icon: "ph-moon-stars", occasion: "Before sleep",
            detail: "The day examined and given back, closing on Our Lady's antiphon.",
            prayerIDs: { date in
                ["sign_of_cross", "examen", "act_of_contrition", "in_manus_tuas",
                 "visita_quaesumus", antiphon(on: date).prayerID]
            }
        ),
        PrayerOrder(
            id: "table", title: "At Table", latinTitle: "Benedictio Mensæ",
            icon: "ph-leaf", occasion: "Before and after meals",
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
            icon: "ph-chat-teardrop-text", occasion: "Before going in",
            detail: "Light to see, the commandments to see by, and sorrow for what is seen.",
            prayerIDs: { _ in
                ["sign_of_cross", "come_holy_ghost", "before_confession",
                 "examination_of_conscience", "act_of_contrition", "the_confession"]
            }
        ),
        PrayerOrder(
            id: "after_confession", title: "After Confession", latinTitle: "Post Confessionem",
            icon: "ph-sparkle", occasion: "Kneeling afterwards",
            detail: "The penance said, and thanks given for mercy.",
            prayerIDs: { _ in ["after_confession", "beati_quorum", "hail_mary"] }
        ),
        PrayerOrder(
            id: "visit", title: "A Visit to the Blessed Sacrament", latinTitle: "Visitatio",
            icon: "ch-monstrance", occasion: "Before the tabernacle",
            detail: "A few minutes with Him in the tabernacle, or in spirit from wherever you are.",
            prayerIDs: { _ in
                ["adoro_te", "spiritual_communion", "o_sacrum_convivium", "tantum_ergo", "divine_praises"]
            }
        ),
        PrayerOrder(
            id: "holy_souls", title: "For the Holy Souls", latinTitle: "Pro Defunctis",
            icon: "ch-candle", occasion: "For the dead",
            detail: "For those who have gone before us, and wait.",
            prayerIDs: { _ in ["de_profundis", "requiem_aeternam", "fidelium_deus"] }
        ),
        PrayerOrder(
            id: "trouble", title: "In Time of Trouble", latinTitle: "In Tribulatione",
            icon: "ph-shield", occasion: "When help is needed",
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

    /// The hour's order said as a kicker — "AT NOON", "BEFORE SLEEP"
    nonisolated static func dayOrderMoment(at date: Date = Date(), calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case dayBeginsAtHour..<11:  return "On rising"
        case 11..<15: return "At noon"
        case 15..<20: return "At six in the evening"
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
