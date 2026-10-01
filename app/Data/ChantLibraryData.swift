//
//  ChantLibraryData.swift
//  Lumen Viae
//
//  The Chant Library's curation: which chant is which kind, which belong
//  to which season and feast, the devotions of the week and the month,
//  the occasions sung as a set, and the course chants are learned in.
//  Hand-written, unlike `ChantCatalogData.swift` beside it, which the
//  generator writes from the recordings. Every id here is a catalog id,
//  and `ChantLibraryTests` fails if one is not, or if a chant is left
//  without a kind.
//
//  The rubrics between an occasion's chants are plain words for someone
//  who has never been to Benediction: what happens, and what to do.
//

import Foundation

enum ChantLibraryData {

    // MARK: - Forms

    /// Every chant's kind. Antiphons are the short chants; the sequences
    /// are the feast poems; the Rosary's prayers and their kin, the
    /// everyday prayers.
    static let forms: [String: ChantForm] = [
        // Short chants: antiphons
        "salve_regina_simple": .shortChant,
        "salve_regina_solemn": .shortChant,
        "alma_redemptoris": .shortChant,
        "ave_regina_simple": .shortChant,
        "ave_regina_solemn": .shortChant,
        "regina_caeli_simple": .shortChant,
        "regina_caeli_solemn": .shortChant,
        "sub_tuum": .shortChant,
        "tota_pulchra": .shortChant,
        "ave_maria_antiphon": .shortChant,
        "o_sacrum_convivium": .shortChant,
        "cor_jesu": .shortChant,
        "rorate_caeli": .shortChant,
        "parce_domine": .shortChant,
        "adoremus": .shortChant,
        "christus_vincit": .shortChant,

        // Hymns
        "ave_maris_stella": .hymn,
        "o_gloriosa": .hymn,
        "salve_mater": .hymn,
        "inviolata": .hymn,
        "adoro_te": .hymn,
        "ave_verum": .hymn,
        "o_salutaris": .hymn,
        "tantum_ergo": .hymn,
        "panis_angelicus": .hymn,
        "ubi_caritas": .hymn,
        "veni_creator": .hymn,
        "jesu_dulcis_memoria": .hymn,
        "te_joseph": .hymn,
        "creator_alme": .hymn,
        "veni_emmanuel": .hymn,
        "puer_natus": .hymn,
        "adeste_fideles": .hymn,
        "jesu_redemptor": .hymn,
        "attende_domine": .hymn,
        "vexilla_regis": .hymn,
        "o_filii": .hymn,

        // Feast poems: sequences
        "victimae_paschali": .sequence,
        "veni_sancte_spiritus": .sequence,
        "lauda_sion": .sequence,
        "ecce_panis": .sequence,
        "stabat_mater": .sequence,
        "dies_irae": .sequence,
        "flos_carmeli": .sequence,

        // Litanies
        "litany_loreto": .litany,
        "litany_sacred_heart": .litany,
        "litany_holy_name": .litany,
        "litany_st_joseph": .litany,
        "litany_saints": .litany,

        // Psalms and canticles
        "magnificat": .psalm,
        "miserere": .psalm,
        "te_deum": .psalm,

        // Everyday prayers
        "in_nomine_patris": .everydayPrayer,
        "credo_in_deum": .everydayPrayer,
        "pater_noster": .everydayPrayer,
        "ave_maria": .everydayPrayer,
        "gloria_patri": .everydayPrayer,
        "o_mi_jesu": .everydayPrayer,
        "angelus": .everydayPrayer,
        "sancte_michael": .everydayPrayer,
        "memorare": .everydayPrayer,
        "anima_christi": .everydayPrayer,
        "divine_praises": .everydayPrayer,
        "veni_sancte_reple": .everydayPrayer
    ]

    /// What one chant is, for a kicker, where its kind's own word would
    /// be wrong: Psalms and Canticles holds the Miserere, a psalm, beside
    /// the Magnificat and the Te Deum, which are canticles
    static let kindNames: [String: String] = [
        "magnificat": "Canticle",
        "te_deum": "Canticle",
        "miserere": "Psalm",
    ]

    // MARK: - Seasons

    static let seasonChants: [ChantSeason: [String]] = [
        .advent: ["rorate_caeli", "creator_alme", "veni_emmanuel", "alma_redemptoris", "ave_maria_antiphon"],
        .christmas: ["adeste_fideles", "puer_natus", "jesu_redemptor", "alma_redemptoris"],
        .lent: ["attende_domine", "parce_domine", "miserere", "vexilla_regis", "stabat_mater",
                "ubi_caritas", "ave_regina_simple", "ave_regina_solemn"],
        .easter: ["victimae_paschali", "o_filii", "regina_caeli_simple", "regina_caeli_solemn"],
        .pentecost: ["veni_sancte_spiritus", "veni_creator", "veni_sancte_reple",
                     "regina_caeli_simple", "regina_caeli_solemn"],
        .afterPentecost: ["salve_regina_simple", "salve_regina_solemn", "lauda_sion", "christus_vincit"]
    ]

    static let seasonNotes: [ChantSeason: String] = [
        .advent: "Four weeks of waiting for Christmas. The chants ask heaven to send the Saviour, and each day ends with the Alma Redemptoris Mater.",
        .christmas: "From Christmas, through the Epiphany, to Septuagesima: the carols and hymns of the Child.",
        .lent: "From Septuagesima, when the Alleluia is put away, through Lent and Passiontide to Easter.",
        .easter: "The fifty days of the Resurrection. The Regina Cæli is sung in place of the Angelus, and at the close of each day.",
        .pentecost: "The week of Pentecost, when the Church sings to the Holy Ghost.",
        .afterPentecost: "The longest season of the year. Until Advent, each day ends with the Salve Regina."
    ]

    /// Each season's painting, by subject
    static let seasonPaintings: [ChantSeason: String] = [
        .advent: "season_advent",
        .christmas: "joyful_nativity",
        .lent: "sorrowful_agony",
        .easter: "glorious_resurrection",
        .pentecost: "glorious_pentecost",
        .afterPentecost: "glorious_coronation"
    ]

    /// The chant to learn before each season comes
    static let seasonSignatures: [ChantSeason: String] = [
        .advent: "rorate_caeli",
        .christmas: "adeste_fideles",
        .lent: "attende_domine",
        .easter: "victimae_paschali",
        .pentecost: "veni_creator",
        .afterPentecost: "salve_regina_simple"
    ]

    // MARK: - Feasts

    static let feasts: [ChantFeast] = [
        ChantFeast(id: "holy_name", name: "The Holy Name of Jesus", rule: .holyName, chantID: "jesu_dulcis_memoria"),
        ChantFeast(id: "st_joseph", name: "St Joseph", rule: .fixed(month: 3, day: 19), chantID: "te_joseph", painting: "devotion_st_joseph"),
        ChantFeast(id: "annunciation", name: "The Annunciation", rule: .fixed(month: 3, day: 25), chantID: "ave_maria_antiphon"),
        ChantFeast(id: "holy_thursday", name: "Holy Thursday", rule: .easter(-3), chantID: "ubi_caritas"),
        ChantFeast(id: "good_friday", name: "Good Friday", rule: .easter(-2), chantID: "vexilla_regis"),
        ChantFeast(id: "easter", name: "Easter Sunday", rule: .easter(0), chantID: "victimae_paschali"),
        ChantFeast(id: "pentecost", name: "Pentecost", rule: .easter(49), chantID: "veni_sancte_spiritus"),
        ChantFeast(id: "corpus_christi", name: "Corpus Christi", rule: .easter(60), chantID: "lauda_sion"),
        ChantFeast(id: "sacred_heart", name: "The Sacred Heart", rule: .easter(68), chantID: "litany_sacred_heart"),
        ChantFeast(id: "mount_carmel", name: "Our Lady of Mount Carmel", rule: .fixed(month: 7, day: 16), chantID: "flos_carmeli"),
        ChantFeast(id: "assumption", name: "The Assumption", rule: .fixed(month: 8, day: 15), chantID: "ave_maris_stella"),
        ChantFeast(id: "seven_sorrows", name: "Our Lady of Sorrows", rule: .fixed(month: 9, day: 15), chantID: "stabat_mater"),
        ChantFeast(id: "st_michael", name: "St Michael", rule: .fixed(month: 9, day: 29), chantID: "sancte_michael"),
        ChantFeast(id: "rosary", name: "Our Lady of the Rosary", rule: .fixed(month: 10, day: 7), chantID: "litany_loreto", painting: "feast_our_lady_of_the_rosary"),
        ChantFeast(id: "christ_the_king", name: "Christ the King", rule: .lastSundayOfOctober, chantID: "christus_vincit", painting: "feast_christ_the_king"),
        ChantFeast(id: "all_saints", name: "All Saints", rule: .fixed(month: 11, day: 1), chantID: "litany_saints", painting: "feast_all_saints"),
        ChantFeast(id: "all_souls", name: "All Souls", rule: .fixed(month: 11, day: 2), chantID: "dies_irae", painting: "devotion_holy_souls"),
        ChantFeast(id: "immaculate_conception", name: "The Immaculate Conception", rule: .fixed(month: 12, day: 8), chantID: "tota_pulchra", painting: "season_advent"),
        ChantFeast(id: "christmas", name: "Christmas Day", rule: .fixed(month: 12, day: 25), chantID: "adeste_fideles")
    ]

    // MARK: - The week

    /// Sunday first, as `Calendar` counts
    static let weekdays: [ChantWeekday] = [
        ChantWeekday(weekday: 1, devotion: "the Holy Trinity",
                     headline: "Sundays honour the Holy Trinity",
                     collective: "chants to the Trinity",
                     chantIDs: ["te_deum", "gloria_patri", "in_nomine_patris"],
                     painting: "devotion_holy_trinity"),
        ChantWeekday(weekday: 2, devotion: "the Holy Souls",
                     headline: "Mondays remember the Holy Souls",
                     collective: "chants for the dead",
                     chantIDs: ["dies_irae", "miserere"],
                     painting: "devotion_holy_souls"),
        ChantWeekday(weekday: 3, devotion: "the Holy Angels",
                     headline: "Tuesdays honour the Holy Angels",
                     collective: "chants of the angels",
                     chantIDs: ["sancte_michael", "litany_saints"],
                     painting: "devotion_guardian_angels"),
        ChantWeekday(weekday: 4, devotion: "St Joseph",
                     headline: "Wednesdays honour St Joseph",
                     collective: "chants of St Joseph",
                     chantIDs: ["te_joseph", "litany_st_joseph"],
                     painting: "devotion_st_joseph"),
        ChantWeekday(weekday: 5, devotion: "the Blessed Sacrament",
                     headline: "Thursdays honour the Blessed Sacrament",
                     collective: "chants of the Blessed Sacrament",
                     chantIDs: ["adoro_te", "ave_verum", "tantum_ergo"],
                     painting: "luminous_eucharist"),
        ChantWeekday(weekday: 6, devotion: "the Passion",
                     headline: "Fridays keep the Passion",
                     collective: "chants of the Passion",
                     chantIDs: ["vexilla_regis", "stabat_mater", "anima_christi"],
                     painting: "sorrowful_crucifixion"),
        ChantWeekday(weekday: 7, devotion: "Our Lady",
                     headline: "Saturdays honour Our Lady",
                     collective: "chants of Our Lady",
                     chantIDs: ["ave_maris_stella", "sub_tuum", "salve_mater"],
                     painting: "glorious_coronation")
    ]

    // MARK: - The months

    /// The months' traditional dedications. February, the Holy Family's,
    /// has no chant of its own in the library and is left out rather
    /// than given another month's.
    static let months: [ChantMonth] = [
        ChantMonth(month: 1, title: "The Month of the Holy Name",
                   chantIDs: ["jesu_dulcis_memoria", "litany_holy_name"], occasionID: nil, feastID: "holy_name"),
        ChantMonth(month: 3, title: "The Month of St Joseph",
                   chantIDs: ["te_joseph", "litany_st_joseph"], occasionID: nil, feastID: "st_joseph"),
        ChantMonth(month: 4, title: "The Month of the Blessed Sacrament",
                   chantIDs: ["adoro_te", "ave_verum"], occasionID: "visit", feastID: nil),
        ChantMonth(month: 5, title: "The Month of Mary",
                   chantIDs: ["ave_maris_stella", "litany_loreto"], occasionID: "sung_rosary", feastID: nil),
        ChantMonth(month: 6, title: "The Month of the Sacred Heart",
                   chantIDs: ["litany_sacred_heart", "cor_jesu"], occasionID: nil, feastID: "sacred_heart"),
        ChantMonth(month: 7, title: "The Month of the Precious Blood",
                   chantIDs: ["anima_christi", "adoro_te"], occasionID: nil, feastID: nil),
        ChantMonth(month: 8, title: "The Month of the Immaculate Heart",
                   chantIDs: ["inviolata", "salve_mater"], occasionID: nil, feastID: "assumption"),
        ChantMonth(month: 9, title: "The Month of Our Lady of Sorrows",
                   chantIDs: ["stabat_mater"], occasionID: nil, feastID: "seven_sorrows"),
        ChantMonth(month: 10, title: "The Month of the Holy Rosary",
                   chantIDs: [], occasionID: "sung_rosary", feastID: "rosary"),
        ChantMonth(month: 11, title: "The Month of the Holy Souls",
                   chantIDs: [], occasionID: "for_the_dead", feastID: "all_souls"),
        ChantMonth(month: 12, title: "The Month of the Immaculate Conception",
                   chantIDs: [], occasionID: nil, feastID: "immaculate_conception")
    ]

    // MARK: - Occasions

    static let occasions: [ChantOccasion] = [
        ChantOccasion(
            id: "benediction",
            title: "Benediction",
            note: "The blessing with the Blessed Sacrament",
            painting: "luminous_eucharist",
            blocks: [
                ChantOccasionBlock(rubric: "The Blessed Sacrament is set on the altar. Kneel.",
                                   steps: [ChantOccasionStep(chant: .chant("o_salutaris"))]),
                ChantOccasionBlock(rubric: "The priest offers incense.",
                                   steps: [ChantOccasionStep(chant: .chant("tantum_ergo"))]),
                ChantOccasionBlock(rubric: "The priest blesses everyone with the Host. Then pray together:",
                                   steps: [ChantOccasionStep(chant: .chant("divine_praises"))]),
                ChantOccasionBlock(rubric: "The Blessed Sacrament is put back in the tabernacle.",
                                   steps: [ChantOccasionStep(chant: .chant("adoremus"))])
            ]
        ),
        ChantOccasion(
            id: "visit",
            title: "A Visit to the Blessed Sacrament",
            note: "Quiet time before the tabernacle",
            painting: "sorrowful_agony",
            blocks: [
                ChantOccasionBlock(rubric: "Kneel before the tabernacle.",
                                   steps: [ChantOccasionStep(chant: .chant("adoro_te"))]),
                ChantOccasionBlock(rubric: "Greet Our Lord, hidden there.",
                                   steps: [ChantOccasionStep(chant: .chant("ave_verum"))]),
                ChantOccasionBlock(rubric: "Before you go, give thanks.",
                                   steps: [ChantOccasionStep(chant: .chant("o_sacrum_convivium"))])
            ]
        ),
        ChantOccasion(
            id: "sung_rosary",
            title: "A Sung Rosary",
            note: "Every prayer of the Rosary, sung in Latin",
            painting: "joyful_annunciation",
            blocks: [
                ChantOccasionBlock(rubric: "On the crucifix: sign yourself, then the Creed.",
                                   steps: [ChantOccasionStep(chant: .chant("in_nomine_patris")),
                                           ChantOccasionStep(chant: .chant("credo_in_deum"))]),
                ChantOccasionBlock(rubric: "On the large bead, then the three small beads, for faith, hope and charity.",
                                   steps: [ChantOccasionStep(chant: .chant("pater_noster")),
                                           ChantOccasionStep(chant: .chant("ave_maria"), times: 3),
                                           ChantOccasionStep(chant: .chant("gloria_patri"))]),
                ChantOccasionBlock(rubric: "Name each mystery, then pray its decade. Five times.",
                                   steps: [ChantOccasionStep(chant: .chant("pater_noster")),
                                           ChantOccasionStep(chant: .chant("ave_maria"), times: 10),
                                           ChantOccasionStep(chant: .chant("gloria_patri")),
                                           ChantOccasionStep(chant: .chant("o_mi_jesu"))],
                                   rounds: 5),
                ChantOccasionBlock(rubric: "After the fifth decade.",
                                   steps: [ChantOccasionStep(chant: .chant("salve_regina_simple")),
                                           ChantOccasionStep(chant: .chant("in_nomine_patris"))])
            ]
        ),
        ChantOccasion(
            id: "before_bed",
            title: "Before Bed",
            note: "End the day with Our Lady",
            painting: "glorious_coronation",
            blocks: [
                ChantOccasionBlock(rubric: "Put yourself under her protection for the night.",
                                   steps: [ChantOccasionStep(chant: .chant("sub_tuum"))]),
                ChantOccasionBlock(rubric: "Then the antiphon the Church sings tonight.",
                                   steps: [ChantOccasionStep(chant: .antiphonOfTheSeason)])
            ]
        ),
        ChantOccasion(
            id: "before_work",
            title: "Before Work or Study",
            note: "Ask for help before you start",
            painting: "glorious_pentecost",
            blocks: [
                ChantOccasionBlock(rubric: "Before you begin, ask the Holy Ghost to come.",
                                   steps: [ChantOccasionStep(chant: .chant("veni_sancte_reple"))]),
                ChantOccasionBlock(rubric: "Then the hymn of every work begun.",
                                   steps: [ChantOccasionStep(chant: .chant("veni_creator"))])
            ]
        ),
        ChantOccasion(
            id: "for_the_dead",
            title: "For Those Who Have Died",
            note: "At a funeral, or any time in November",
            painting: "seven_sorrows_burial",
            blocks: [
                ChantOccasionBlock(rubric: "The sequence of the Requiem Mass.",
                                   steps: [ChantOccasionStep(chant: .chant("dies_irae"))]),
                ChantOccasionBlock(rubric: "Then ask all the saints to pray for them.",
                                   steps: [ChantOccasionStep(chant: .chant("litany_saints"))])
            ]
        )
    ]

    // MARK: - Learning

    /// The course, in the order it is offered. The first three stand
    /// open; the rest wait under "See more chants to learn".
    static let learningPaths: [ChantLearningPath] = [
        ChantLearningPath(id: "rosary", title: "Start here: the Rosary prayers",
                          note: "Short and simple. Sung on every bead.",
                          chantIDs: ["in_nomine_patris", "gloria_patri", "ave_maria", "pater_noster"]),
        ChantLearningPath(id: "marian", title: "Hymns to Mary",
                          note: "One for each season, sung at night.",
                          chantIDs: ["salve_regina_simple", "sub_tuum", "regina_caeli_simple",
                                     "ave_regina_simple", "alma_redemptoris"]),
        ChantLearningPath(id: "adoration", title: "Hymns for Adoration",
                          note: "Sung before the Blessed Sacrament.",
                          chantIDs: ["o_salutaris", "ave_verum", "tantum_ergo", "adoro_te"]),
        ChantLearningPath(id: "year", title: "Through the Year",
                          note: "One for each season, learned before it comes.",
                          chantIDs: ["rorate_caeli", "adeste_fideles", "attende_domine",
                                     "victimae_paschali", "veni_creator"]),
        ChantLearningPath(id: "longer", title: "The Longer Chants",
                          note: "The Creed, the canticles and a litany, for when the short ones are known.",
                          chantIDs: ["credo_in_deum", "magnificat", "te_deum", "litany_loreto"])
    ]

    /// How many paths stand open before "See more"
    static let openPaths = 3

    // MARK: - Paintings

    /// The paintings the boards hang beside a chant. A chant not named
    /// here takes its shelf's.
    static let paintings: [String: String] = [
        "salve_regina_simple": "glorious_coronation",
        "salve_regina_solemn": "glorious_coronation",
        "alma_redemptoris": "joyful_nativity",
        "ave_regina_simple": "glorious_assumption",
        "ave_regina_solemn": "glorious_assumption",
        "regina_caeli_simple": "glorious_resurrection",
        "regina_caeli_solemn": "glorious_resurrection",
        "stabat_mater": "seven_sorrows_pieta",
        "victimae_paschali": "glorious_resurrection",
        "o_filii": "glorious_resurrection",
        "vexilla_regis": "sorrowful_crucifixion",
        "attende_domine": "sorrowful_crowning",
        "parce_domine": "sorrowful_scourging",
        "puer_natus": "joyful_nativity",
        "adeste_fideles": "joyful_nativity",
        "jesu_redemptor": "joyful_nativity",
        "rorate_caeli": "joyful_annunciation",
        "ave_maria_antiphon": "joyful_annunciation",
        "veni_creator": "glorious_pentecost",
        "veni_sancte_spiritus": "glorious_pentecost",
        "veni_sancte_reple": "glorious_pentecost",
        "dies_irae": "seven_sorrows_burial"
    ]

    /// The paintings asked for by subject, and the painting each falls
    /// back to until its imageset is in the app (`ChantCatalog.painting(
    /// subject:)`): the Annunciation for Advent, the Jordan's Trinity for
    /// Sunday, the angel in the garden for the Holy Angels
    /// Where a painting is cut to a square, when its middle would lose its
    /// subject: the Father over the Son in Ribera's Trinity, the angel's
    /// face in Strozzi's Guardian Angel, Our Lady's in Murillo's
    /// Immaculate Conception. 0…1 across and down; any painting not named
    /// here is cut about its middle.
    static let focalPoints: [String: (x: Double, y: Double)] = [
        "devotion_holy_trinity": (0.5, 0.25),
        "devotion_guardian_angels": (0.5, 0.3),
        "season_advent": (0.5, 0.3)
    ]

    static let subjectPaintings: [String: String] = [
        "season_advent": "joyful_annunciation",
        "devotion_holy_trinity": "luminous_baptism",
        "devotion_holy_souls": "seven_sorrows_burial",
        "devotion_guardian_angels": "sorrowful_agony",
        "devotion_st_joseph": "joyful_nativity",
        "feast_our_lady_of_the_rosary": "glorious_coronation",
        "feast_christ_the_king": "glorious_ascension",
        "feast_all_saints": "glorious_pentecost",
        "hour_morning": "glorious_resurrection",
        "hour_night": "glorious_coronation"
    ]

    static let groupPaintings: [String: String] = [
        "ourLady": "glorious_coronation",
        "rosary": "joyful_annunciation",
        "sacrament": "luminous_eucharist",
        "holyGhost": "glorious_pentecost",
        "ourLord": "sorrowful_crucifixion",
        "praise": "glorious_ascension",
        "saints": "glorious_assumption",
        "advent": "joyful_annunciation",
        "christmas": "joyful_nativity",
        "lent": "sorrowful_agony",
        "easter": "glorious_resurrection",
        "departed": "seven_sorrows_burial"
    ]

    /// Tonight's antiphon, introduced: keyed by the work, so both its
    /// settings read the same
    static let tonightLines: [String: String] = [
        "Salve Regina|hail_holy_queen": "Hail, Holy Queen. Sung to Our Lady at the close of each day, from Trinity Sunday until Advent.",
        "Alma Redemptoris Mater|alma_redemptoris": "Loving Mother of the Redeemer. Sung at the close of each day from Advent until the Purification.",
        "Ave Regina Cælorum|ave_regina_caelorum": "Hail, Queen of Heaven. Sung at the close of each day from the Purification until Holy Week.",
        "Regina Cæli|regina_caeli": "Queen of Heaven, rejoice. Sung through Eastertide at the close of each day, and in place of the Angelus."
    ]
}
