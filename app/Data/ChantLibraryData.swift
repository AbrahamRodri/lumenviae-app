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
        "vidi_aquam": .shortChant,
        "o_vos_omnes": .shortChant,
        "o_oriens_magnificat": .shortChant,
        "alma_redemptoris_simple": .shortChant,
        "o_sapientia_magnificat": .shortChant,
        "o_adonai_magnificat": .shortChant,
        "o_radix_magnificat": .shortChant,
        "o_clavis_magnificat": .shortChant,
        "o_rex_magnificat": .shortChant,
        "o_emmanuel_magnificat": .shortChant,
        "adoramus_te": .shortChant,
        "da_pacem": .shortChant,
        "asperges_me": .shortChant,
        // A responsory: a short chant answered after each verse
        "media_vita": .shortChant,

        // Hymns
        "ave_maris_stella": .hymn,
        "ave_maris_stella_feasts": .hymn,
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
        "pange_lingua": .hymn,
        "audi_benigne": .hymn,
        "ad_regias": .hymn,
        "quem_terra": .hymn,
        "omni_die": .hymn,
        "concordi_laetitia": .hymn,
        "jesu_nostra_redemptio": .hymn,
        "te_saeculorum": .hymn,
        "salvete_christi_vulnera": .hymn,
        "lucis_creator": .hymn,
        "ut_queant_laxis": .hymn,
        "en_clara_vox": .hymn,
        "salve_festa_dies": .hymn,
        "aurora_caelum": .hymn,

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
        "te_deum_simple": .psalm,
        // The Te Deum's Marian echo, in its form and its tone: prose
        // verses sung one by one, not a hymn's verses in metre
        "te_matrem": .psalm,

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
        "veni_sancte_reple": .everydayPrayer,

        // The Ordinary of the Mass, sung as on Sundays
        "kyrie_de_angelis": .everydayPrayer,
        "gloria_de_angelis": .everydayPrayer,
        "sanctus_de_angelis": .everydayPrayer,
        "agnus_de_angelis": .everydayPrayer,
        "credo_iii": .everydayPrayer,
        "kyrie_orbis_factor": .everydayPrayer,
        "gloria_orbis_factor": .everydayPrayer,
        "sanctus_orbis_factor": .everydayPrayer,
        "agnus_orbis_factor": .everydayPrayer
    ]

    /// What one chant is, for a kicker, where its kind's own word would
    /// be wrong: Psalms and Canticles holds the Miserere, a psalm, beside
    /// the Magnificat, the Te Deum and the Te Matrem, which are canticles
    static let kindNames: [String: String] = [
        "magnificat": "Canticle",
        "te_deum": "Canticle",
        "te_deum_simple": "Canticle",
        "te_matrem": "Canticle",
        "miserere": "Psalm"
    ]

    // MARK: - Seasons

    static let seasonChants: [ChantSeason: [String]] = [
        .advent: ["rorate_caeli", "creator_alme", "veni_emmanuel", "en_clara_vox",
                  "o_sapientia_magnificat", "o_adonai_magnificat", "o_radix_magnificat",
                  "o_clavis_magnificat", "o_oriens_magnificat", "o_rex_magnificat",
                  "o_emmanuel_magnificat", "alma_redemptoris_simple", "alma_redemptoris",
                  "ave_maria_antiphon"],
        .christmas: ["adeste_fideles", "puer_natus", "jesu_redemptor", "alma_redemptoris_simple",
                     "alma_redemptoris"],
        .lent: ["media_vita", "attende_domine", "audi_benigne", "parce_domine", "miserere", "vexilla_regis",
                "o_vos_omnes", "stabat_mater", "ubi_caritas", "ave_regina_simple", "ave_regina_solemn"],
        // The Vidi Aquam is sung before Sunday Mass from Easter through
        // Pentecost Sunday, as the Regina Cæli runs on into Pentecost's week
        .easter: ["victimae_paschali", "o_filii", "salve_festa_dies", "aurora_caelum", "vidi_aquam",
                  "ad_regias", "jesu_nostra_redemptio", "concordi_laetitia",
                  "regina_caeli_simple", "regina_caeli_solemn"],
        .pentecost: ["veni_sancte_spiritus", "veni_creator", "veni_sancte_reple", "vidi_aquam",
                     "regina_caeli_simple", "regina_caeli_solemn"],
        .afterPentecost: ["salve_regina_simple", "salve_regina_solemn", "lauda_sion", "lucis_creator",
                          "christus_vincit", "te_saeculorum"]
    ]

    static let seasonNotes: [ChantSeason: String] = [
        .advent: "Four weeks of waiting for Christmas. The chants ask heaven to send the Saviour, and each day ends with “Loving Mother of the Redeemer” (Alma Redemptoris Mater).",
        .christmas: "From Christmas, through the Epiphany on January 6, to Pre-Lent: the carols and hymns of the Christ Child.",
        .lent: "From Pre-Lent, the three Sundays before Lent, when the Church stops singing Alleluia, through Lent to Easter.",
        .easter: "The fifty days from Easter to Pentecost. “Queen of Heaven” (Regina Cæli) is sung in place of the Angelus, and at the close of each day.",
        .pentecost: "The week of Pentecost, the feast of the Holy Spirit's coming.",
        .afterPentecost: "The longest season, from late May or June until Advent. Each day ends with “Hail, Holy Queen” (Salve Regina)."
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
        // Sung as the Blessed Sacrament is carried to the altar of repose
        ChantFeast(id: "holy_thursday", name: "Holy Thursday", rule: .easter(-3), chantID: "pange_lingua"),
        ChantFeast(id: "good_friday", name: "Good Friday", rule: .easter(-2), chantID: "vexilla_regis"),
        ChantFeast(id: "easter", name: "Easter Sunday", rule: .easter(0), chantID: "victimae_paschali"),
        ChantFeast(id: "ascension", name: "The Ascension", rule: .easter(39), chantID: "jesu_nostra_redemptio"),
        ChantFeast(id: "pentecost", name: "Pentecost", rule: .easter(49), chantID: "veni_sancte_spiritus"),
        ChantFeast(id: "corpus_christi", name: "Corpus Christi (the Body of Christ)", rule: .easter(60), chantID: "lauda_sion"),
        ChantFeast(id: "sacred_heart", name: "The Sacred Heart", rule: .easter(68), chantID: "litany_sacred_heart"),
        ChantFeast(id: "st_john_baptist", name: "The Birth of St John the Baptist", rule: .fixed(month: 6, day: 24), chantID: "ut_queant_laxis"),
        ChantFeast(id: "precious_blood", name: "The Precious Blood", rule: .fixed(month: 7, day: 1), chantID: "salvete_christi_vulnera"),
        ChantFeast(id: "mount_carmel", name: "Our Lady of Mount Carmel", rule: .fixed(month: 7, day: 16), chantID: "flos_carmeli"),
        ChantFeast(id: "assumption", name: "The Assumption", rule: .fixed(month: 8, day: 15), chantID: "ave_maris_stella_feasts"),
        ChantFeast(id: "seven_sorrows", name: "Our Lady of Sorrows", rule: .fixed(month: 9, day: 15), chantID: "stabat_mater"),
        ChantFeast(id: "st_michael", name: "St Michael", rule: .fixed(month: 9, day: 29), chantID: "sancte_michael"),
        ChantFeast(id: "rosary", name: "Our Lady of the Rosary", rule: .fixed(month: 10, day: 7), chantID: "litany_loreto", painting: "feast_our_lady_of_the_rosary"),
        ChantFeast(id: "christ_the_king", name: "Christ the King", rule: .lastSundayOfOctober, chantID: "christus_vincit", painting: "feast_christ_the_king"),
        ChantFeast(id: "all_saints", name: "All Saints", rule: .fixed(month: 11, day: 1), chantID: "litany_saints", painting: "feast_all_saints"),
        ChantFeast(id: "all_souls", name: "All Souls", rule: .fixed(month: 11, day: 2), chantID: "dies_irae", painting: "devotion_holy_souls"),
        ChantFeast(id: "immaculate_conception", name: "The Immaculate Conception", rule: .fixed(month: 12, day: 8), chantID: "tota_pulchra", painting: "season_advent"),
        // Not feasts but days of the Office: the O antiphons ring round
        // the Magnificat at Vespers from the 17th to the 23rd, one a day
        ChantFeast(id: "o_sapientia", name: "Advent's “O Wisdom”", rule: .fixed(month: 12, day: 17), chantID: "o_sapientia_magnificat"),
        ChantFeast(id: "o_adonai", name: "Advent's “O Lord and Ruler”", rule: .fixed(month: 12, day: 18), chantID: "o_adonai_magnificat"),
        ChantFeast(id: "o_radix", name: "Advent's “O Root of Jesse”", rule: .fixed(month: 12, day: 19), chantID: "o_radix_magnificat"),
        ChantFeast(id: "o_clavis", name: "Advent's “O Key of David”", rule: .fixed(month: 12, day: 20), chantID: "o_clavis_magnificat"),
        ChantFeast(id: "o_oriens", name: "Advent's “O Morning Star”", rule: .fixed(month: 12, day: 21), chantID: "o_oriens_magnificat"),
        ChantFeast(id: "o_rex", name: "Advent's “O King of the Nations”", rule: .fixed(month: 12, day: 22), chantID: "o_rex_magnificat"),
        ChantFeast(id: "o_emmanuel", name: "Advent's “O Emmanuel”", rule: .fixed(month: 12, day: 23), chantID: "o_emmanuel_magnificat"),
        ChantFeast(id: "christmas", name: "Christmas Day", rule: .fixed(month: 12, day: 25), chantID: "adeste_fideles")
    ]

    // MARK: - The week

    /// Sunday first, as `Calendar` counts
    static let weekdays: [ChantWeekday] = [
        ChantWeekday(weekday: 1, devotion: "the Holy Trinity",
                     headline: "Sundays honour the Holy Trinity",
                     collective: "chants to the Trinity",
                     chantIDs: ["te_deum_simple", "gloria_patri", "in_nomine_patris"],
                     painting: "devotion_holy_trinity"),
        ChantWeekday(weekday: 2, devotion: "those who have died",
                     headline: "Mondays remember those who have died",
                     collective: "chants for those who have died",
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
        ChantWeekday(weekday: 5, devotion: "Jesus present in the Host",
                     headline: "Thursdays honour Jesus, present in the Host",
                     collective: "chants to Jesus in the Host",
                     // The whole Pange Lingua, whose last two verses are
                     // the Tantum Ergo
                     chantIDs: ["adoro_te", "ave_verum", "pange_lingua"],
                     painting: "luminous_eucharist"),
        ChantWeekday(weekday: 6, devotion: "the Passion",
                     headline: "Fridays remember the Passion",
                     collective: "chants of the Passion",
                     chantIDs: ["vexilla_regis", "stabat_mater", "anima_christi"],
                     painting: "sorrowful_crucifixion"),
        ChantWeekday(weekday: 7, devotion: "Mary",
                     headline: "Saturdays honour Mary",
                     collective: "chants of Mary",
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
                   chantIDs: ["ave_maris_stella_feasts", "litany_loreto"], occasionID: "sung_rosary", feastID: nil),
        ChantMonth(month: 6, title: "The Month of the Sacred Heart",
                   chantIDs: ["litany_sacred_heart", "cor_jesu"], occasionID: nil, feastID: "sacred_heart"),
        ChantMonth(month: 7, title: "The Month of the Precious Blood",
                   chantIDs: ["salvete_christi_vulnera", "anima_christi"], occasionID: nil, feastID: "precious_blood"),
        ChantMonth(month: 8, title: "The Month of the Immaculate Heart",
                   chantIDs: ["inviolata", "salve_mater"], occasionID: nil, feastID: "assumption"),
        ChantMonth(month: 9, title: "The Month of Our Lady of Sorrows",
                   chantIDs: ["stabat_mater"], occasionID: nil, feastID: "seven_sorrows"),
        ChantMonth(month: 10, title: "The Month of the Holy Rosary",
                   chantIDs: [], occasionID: "sung_rosary", feastID: "rosary"),
        ChantMonth(month: 11, title: "The Month for Those Who Have Died",
                   chantIDs: [], occasionID: "for_the_dead", feastID: "all_souls"),
        ChantMonth(month: 12, title: "The Month of the Immaculate Conception",
                   chantIDs: [], occasionID: nil, feastID: "immaculate_conception")
    ]

    // MARK: - Occasions

    static let occasions: [ChantOccasion] = [
        ChantOccasion(
            id: "benediction",
            title: "Adoration and Blessing",
            note: "Benediction: hymns before the Host, then the priest's blessing",
            painting: "luminous_eucharist",
            blocks: [
                ChantOccasionBlock(rubric: "The Host is placed on the altar for all to see. Kneel.",
                                   steps: [ChantOccasionStep(chant: .chant("o_salutaris"))]),
                ChantOccasionBlock(rubric: "The priest offers incense.",
                                   steps: [ChantOccasionStep(chant: .chant("tantum_ergo"))]),
                ChantOccasionBlock(rubric: "The priest blesses everyone with the Host. Then pray together:",
                                   steps: [ChantOccasionStep(chant: .chant("divine_praises"))]),
                ChantOccasionBlock(rubric: "The Host is put back in the tabernacle, where it is kept in church.",
                                   steps: [ChantOccasionStep(chant: .chant("adoremus"))])
            ]
        ),
        ChantOccasion(
            id: "visit",
            title: "A Visit to Jesus in Church",
            note: "Quiet time with Jesus, present in the Host",
            painting: "sorrowful_agony",
            blocks: [
                ChantOccasionBlock(rubric: "Kneel before the tabernacle, where the Host is kept.",
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
                ChantOccasionBlock(rubric: "On the crucifix: make the Sign of the Cross, then sing the Creed.",
                                   steps: [ChantOccasionStep(chant: .chant("in_nomine_patris")),
                                           ChantOccasionStep(chant: .chant("credo_in_deum"))]),
                ChantOccasionBlock(rubric: "On the large bead, then the three small beads, for faith, hope and charity.",
                                   steps: [ChantOccasionStep(chant: .chant("pater_noster")),
                                           ChantOccasionStep(chant: .chant("ave_maria"), times: 3),
                                           ChantOccasionStep(chant: .chant("gloria_patri"))]),
                ChantOccasionBlock(rubric: "Name each mystery, then pray its decade of ten Hail Marys. Five times.",
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
            note: "End the day with Mary",
            painting: "glorious_coronation",
            blocks: [
                ChantOccasionBlock(rubric: "Put yourself under her protection for the night.",
                                   steps: [ChantOccasionStep(chant: .chant("sub_tuum"))]),
                ChantOccasionBlock(rubric: "Then tonight's song to Mary.",
                                   steps: [ChantOccasionStep(chant: .antiphonOfTheSeason)])
            ]
        ),
        ChantOccasion(
            id: "before_work",
            title: "Before Work or Study",
            note: "Ask for help before you start",
            painting: "glorious_pentecost",
            blocks: [
                ChantOccasionBlock(rubric: "Before you begin, ask the Holy Spirit to come.",
                                   steps: [ChantOccasionStep(chant: .chant("veni_sancte_reple"))]),
                ChantOccasionBlock(rubric: "Then the hymn sung at the start of any work.",
                                   steps: [ChantOccasionStep(chant: .chant("veni_creator"))])
            ]
        ),
        ChantOccasion(
            id: "for_the_dead",
            title: "For Those Who Have Died",
            note: "At a funeral, or any time in November",
            painting: "seven_sorrows_burial",
            blocks: [
                ChantOccasionBlock(rubric: "The poem sung at the funeral Mass.",
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
        ChantLearningPath(id: "marian", title: "Songs to Mary",
                          note: "One for each season, sung at night, and the oldest prayer to her.",
                          chantIDs: ["salve_regina_simple", "sub_tuum", "regina_caeli_simple",
                                     "ave_regina_simple", "alma_redemptoris_simple"]),
        ChantLearningPath(id: "adoration", title: "Hymns for Adoration",
                          note: "Sung before Jesus, present in the Host.",
                          chantIDs: ["o_salutaris", "ave_verum", "tantum_ergo", "adoro_te"]),
        ChantLearningPath(id: "year", title: "Through the Year",
                          note: "One for each season, learned before it comes.",
                          chantIDs: ["rorate_caeli", "adeste_fideles", "attende_domine",
                                     "victimae_paschali", "veni_creator"]),
        ChantLearningPath(id: "longer", title: "The Longer Chants",
                          note: "The Creed, two great songs of praise and a litany, for when the short ones are known.",
                          chantIDs: ["credo_in_deum", "magnificat", "te_deum_simple", "litany_loreto"]),
        ChantLearningPath(id: "mass", title: "The Sung Mass",
                          note: "The Mass of the Angels (Mass VIII), the best-known sung Mass, and the Sunday Creed.",
                          chantIDs: ["kyrie_de_angelis", "gloria_de_angelis", "sanctus_de_angelis",
                                     "agnus_de_angelis", "credo_iii"]),
        ChantLearningPath(id: "sunday_mass", title: "The Sundays through the Year",
                          note: "Mass XI, Orbis Factor, sung on the green Sundays, with the sprinkling of holy water before it.",
                          chantIDs: ["asperges_me", "kyrie_orbis_factor", "gloria_orbis_factor",
                                     "sanctus_orbis_factor", "agnus_orbis_factor"])
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
        "alma_redemptoris_simple": "joyful_nativity",
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
        "dies_irae": "seven_sorrows_burial",
        "o_vos_omnes": "sorrowful_crucifixion",
        "vidi_aquam": "glorious_resurrection",
        "ad_regias": "glorious_resurrection",
        "salve_festa_dies": "glorious_resurrection",
        "aurora_caelum": "glorious_resurrection",
        "concordi_laetitia": "glorious_resurrection",
        "jesu_nostra_redemptio": "glorious_ascension",
        "quem_terra": "joyful_annunciation",
        "ut_queant_laxis": "joyful_visitation",
        "salvete_christi_vulnera": "sorrowful_crucifixion",
        "media_vita": "sorrowful_agony"
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
        "departed": "seven_sorrows_burial",
        "mass": "luminous_eucharist"
    ]

    /// Tonight's antiphon, introduced: keyed by the work, so both its
    /// settings read the same
    static let tonightLines: [String: String] = [
        "Salve Regina|hail_holy_queen": "Hail, Holy Queen. Sung to Mary at the close of each day, from Trinity Sunday (late May or June) until Advent.",
        "Alma Redemptoris Mater|alma_redemptoris": "Loving Mother of the Redeemer. Sung at the close of each day from Advent until February 2 (Candlemas).",
        "Ave Regina Cælorum|ave_regina_caelorum": "Hail, Queen of Heaven. Sung at the close of each day from February 2 (Candlemas) until Holy Week.",
        "Regina Cæli|regina_caeli": "Queen of Heaven, rejoice. Sung at the close of each day through the Easter season, and in place of the Angelus."
    ]

    /// The names the day's four hours give their chants under the arc,
    /// in English and as short as they honestly can be: a station is a
    /// quarter of the glass wide
    static let stationNames: [String: String] = [
        "angelus": "Angelus",
        "magnificat": "Mary's Song",
        "salve_regina_simple": "Hail, Holy Queen",
        "salve_regina_solemn": "Hail, Holy Queen",
        "alma_redemptoris": "Loving Mother",
        "alma_redemptoris_simple": "Loving Mother",
        "ave_regina_simple": "Hail, Queen of Heaven",
        "ave_regina_solemn": "Hail, Queen of Heaven",
        "regina_caeli_simple": "Queen of Heaven",
        "regina_caeli_solemn": "Queen of Heaven"
    ]

    /// The words an occasion's title or a red note once had, by the words
    /// it has now. A set kept from an occasion before its words were made
    /// plain carries the old ones, and is still the occasion's own copy:
    /// the shelf reads its name and notes through this before comparing
    static let formerWords: [String: String] = [
        "Benediction": "Adoration and Blessing",
        "The Blessed Sacrament is set on the altar. Kneel.": "The Host is placed on the altar for all to see. Kneel.",
        "The Blessed Sacrament is put back in the tabernacle.": "The Host is put back in the tabernacle, where it is kept in church.",
        "A Visit to the Blessed Sacrament": "A Visit to Jesus in Church",
        "Kneel before the tabernacle.": "Kneel before the tabernacle, where the Host is kept.",
        "On the crucifix: sign yourself, then the Creed.": "On the crucifix: make the Sign of the Cross, then sing the Creed.",
        "Name each mystery, then pray its decade. Five times.": "Name each mystery, then pray its decade of ten Hail Marys. Five times.",
        "Then the antiphon the Church sings tonight.": "Then tonight's song to Mary.",
        "Before you begin, ask the Holy Ghost to come.": "Before you begin, ask the Holy Spirit to come.",
        "Then the hymn of every work begun.": "Then the hymn sung at the start of any work.",
        "The sequence of the Requiem Mass.": "The poem sung at the funeral Mass."
    ]

    /// Words as they read now, whichever wording they were kept in
    static func currentWording(of words: String) -> String {
        formerWords[words] ?? words
    }
}
