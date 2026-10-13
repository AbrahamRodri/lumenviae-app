//
//  PrayerBookPaintings.swift
//  Lumen Viae
//
//  The paintings the Prayers page hangs over the hour's order and over
//  the antiphon of Our Lady the season sings. The Angelus is the
//  Annunciation it remembers; the antiphons are the mysteries they sing
//  of. Morning and Night Prayers have no mystery of their own, so each
//  names a painting of its own (`hour_morning`, `hour_night`, names
//  shared with the Chant Library's redesign, which is still being made)
//  and, until that painting is in the catalog, hangs the mystery nearest
//  it: the Presentation, a life offered as the morning offers the day,
//  and Gethsemane, where He asked the disciples to watch and pray through
//  the night.
//

import SwiftUI

/// One painting as a Prayers card hangs it: the asset it wants, the one
/// it hangs while that asset is missing, where its subject sits, and
/// what VoiceOver says of it.
struct PrayerBookPainting: Equatable {
    let asset: String
    let fallback: String
    let focal: UnitPoint
    let caption: String

    /// The asset the catalog actually has: the painting's own, else its
    /// stand-in. Looked up once per name: the image cache keeps what it
    /// finds but not what it misses, so a painting not yet in the catalog
    /// was looked for again on every redraw.
    var resolvedAsset: String {
        if let known = Self.resolved[asset] { return known }
        let found = ImageCacheService.shared.image(named: asset) == nil ? fallback : asset
        Self.resolved[asset] = found
        return found
    }

    /// Each asset's answer, for the life of the app: the catalog does not
    /// change while it runs
    private static var resolved: [String: String] = [:]

    init(asset: String, fallback: String? = nil, focal: UnitPoint = UnitPoint(x: 0.5, y: 0.2), caption: String) {
        self.asset = asset
        self.fallback = fallback ?? asset
        self.focal = focal
        self.caption = caption
    }

    // MARK: The hours

    /// The painting over one of the day's three orders on `date`. In
    /// Eastertide the Angelus gives way to the Regina Cæli, and its
    /// painting to the risen Christ coming to His Mother, whose joy the
    /// Regina Cæli sings.
    static func hour(_ order: PrayerOrder, on date: Date = Date()) -> PrayerBookPainting {
        switch order.id {
        case PrayerBook.morningOrderID:
            return PrayerBookPainting(
                asset: "hour_morning",
                fallback: "joyful_presentation",
                caption: "The Presentation in the Temple"
            )
        case PrayerBook.nightOrderID:
            return PrayerBookPainting(
                asset: "hour_night",
                fallback: "sorrowful_agony",
                focal: UnitPoint(x: 0.5, y: 0.3),
                caption: "The Agony in the Garden"
            )
        default:
            return PrayerBook.isEastertide(date)
                ? reginaCaeli
                : PrayerBookPainting(asset: "joyful_annunciation", focal: UnitPoint(x: 0.5, y: 0.18), caption: "The Annunciation")
        }
    }

    // MARK: Our Lady's antiphons

    /// The painting over the antiphon of the season: the Child she bore
    /// for the Alma Redemptoris, Our Lady taken up to heaven for the Ave
    /// Regina Cælorum, the risen Christ with His Mother for the Regina
    /// Cæli, and Our Lady crowned for the Salve Regina, the Queen it hails
    static func antiphon(_ antiphon: MarianAntiphon) -> PrayerBookPainting {
        switch antiphon {
        case .almaRedemptoris:
            return PrayerBookPainting(asset: "joyful_nativity", focal: UnitPoint(x: 0.5, y: 0.35), caption: "The Nativity")
        case .reginaCaeli:
            return reginaCaeli
        case .aveReginaCaelorum:
            return PrayerBookPainting(asset: "glorious_assumption", focal: UnitPoint(x: 0.5, y: 0.3), caption: "The Assumption")
        case .salveRegina:
            return PrayerBookPainting(asset: "glorious_coronation", focal: UnitPoint(x: 0.5, y: 0.12), caption: "The Coronation of Our Lady")
        }
    }

    /// The Regina Cæli's painting, wherever it stands in for the Angelus
    private static let reginaCaeli = PrayerBookPainting(
        asset: "easter_appears_to_mary", focal: UnitPoint(x: 0.5, y: 0.55), caption: "Christ Appearing to His Mother")

    // MARK: The Prayers page

    /// The Saved shortcut's painting: Our Lady at prayer, over the
    /// prayers a reader keeps
    static let saved = PrayerBookPainting(
        asset: "mary_virgin_in_prayer", focal: UnitPoint(x: 0.5, y: 0.35), caption: "The Virgin in Prayer"
    )

    /// An order's painting on its shortcut and its page: the Last Supper
    /// at Mass, the Prodigal Son at Confession, Christ with the Host on a
    /// visit to Him, the Day of the Dead, the storm on the lake in time of
    /// trouble, Emmaus at table; else the order's hour
    static func order(_ order: PrayerOrder, on date: Date = Date()) -> PrayerBookPainting {
        switch order.id {
        case "before_mass", "after_mass":
            return PrayerBookPainting(
                asset: "luminous_eucharist", focal: UnitPoint(x: 0.5, y: 0.35), caption: "The Last Supper")
        case "before_confession", "after_confession":
            return PrayerBookPainting(
                asset: "topic_confession", focal: UnitPoint(x: 0.5, y: 0.35), caption: "The Return of the Prodigal Son")
        case "visit":
            return PrayerBookPainting(
                asset: "jesus_eucharist_saviour", focal: UnitPoint(x: 0.5, y: 0.3), caption: "The Saviour")
        case "holy_souls":
            return PrayerBookPainting(
                asset: "devotion_holy_souls", focal: UnitPoint(x: 0.5, y: 0.4), caption: "The Day of the Dead")
        case "trouble":
            return PrayerBookPainting(
                asset: "topic_needs", focal: UnitPoint(x: 0.5, y: 0.35),
                caption: "Christ in the Storm on the Sea of Galilee")
        case "table":
            return PrayerBookPainting(
                asset: "prayer_supper_emmaus", focal: UnitPoint(x: 0.5, y: 0.35), caption: "The Supper at Emmaus")
        default:
            return hour(order, on: date)
        }
    }

    // MARK: The topics

    /// The painting over a topic, on its card in All Topics and at the
    /// head of its own page. Each topic has one of its own; the sources
    /// and licences are in Tools/ContentSourcing/sources.py.
    static func topic(_ chapter: PrayerBookChapter) -> PrayerBookPainting {
        topics[chapter.id] ?? PrayerBookPainting(
            asset: "topic_first_prayers", focal: UnitPoint(x: 0.5, y: 0.3), caption: "St Anne teaching the Virgin")
    }

    private static let topics: [String: PrayerBookPainting] = [
        "first": PrayerBookPainting(asset: "topic_first_prayers", focal: UnitPoint(x: 0.5, y: 0.3), caption: "St Anne teaching the Virgin"),
        "day": PrayerBookPainting(asset: "topic_daily_prayers", focal: UnitPoint(x: 0.5, y: 0.45), caption: "The Angelus"),
        "short": PrayerBookPainting(asset: "topic_short_prayers", focal: UnitPoint(x: 0.5, y: 0.3), caption: "Saint Francis in Meditation"),
        "mass": PrayerBookPainting(asset: "topic_holy_mass", focal: UnitPoint(x: 0.5, y: 0.5), caption: "The Mass at Bolsena"),
        "penance": PrayerBookPainting(asset: "topic_confession", focal: UnitPoint(x: 0.5, y: 0.35), caption: "The Return of the Prodigal Son"),
        "sacrament": PrayerBookPainting(asset: "topic_blessed_sacrament", focal: UnitPoint(x: 0.5, y: 0.45), caption: "The Disputation of the Holy Sacrament"),
        "holy_ghost": PrayerBookPainting(asset: "topic_holy_trinity", focal: UnitPoint(x: 0.5, y: 0.2), caption: "The Holy Trinity"),
        "our_lord": PrayerBookPainting(asset: "topic_our_lord", focal: UnitPoint(x: 0.5, y: 0.25), caption: "The Sacred Heart of Jesus"),
        "our_lady": PrayerBookPainting(asset: "season_advent", focal: UnitPoint(x: 0.5, y: 0.25), caption: "The Immaculate Conception"),
        "st_joseph": PrayerBookPainting(asset: "devotion_st_joseph", focal: UnitPoint(x: 0.5, y: 0.2), caption: "Saint Joseph and the Christ Child"),
        "saints": PrayerBookPainting(asset: "devotion_guardian_angels", focal: UnitPoint(x: 0.5, y: 0.3), caption: "The Guardian Angel"),
        "seasons": PrayerBookPainting(asset: "topic_feasts_seasons", focal: UnitPoint(x: 0.5, y: 0.4), caption: "The Adoration of the Magi"),
        "thanks": PrayerBookPainting(asset: "topic_thanksgiving", focal: UnitPoint(x: 0.5, y: 0.3), caption: "The Madonna of the Magnificat"),
        "litanies": PrayerBookPainting(asset: "feast_all_saints", focal: UnitPoint(x: 0.5, y: 0.3), caption: "The Adoration of the Trinity"),
        "church": PrayerBookPainting(asset: "topic_for_the_living", focal: UnitPoint(x: 0.5, y: 0.6), caption: "The Delivery of the Keys"),
        "sick": PrayerBookPainting(asset: "topic_sick_dying", focal: UnitPoint(x: 0.5, y: 0.55), caption: "The Death of Saint Joseph"),
        "departed": PrayerBookPainting(asset: "devotion_holy_souls", focal: UnitPoint(x: 0.5, y: 0.4), caption: "The Day of the Dead"),
        "needs": PrayerBookPainting(asset: "topic_needs", focal: UnitPoint(x: 0.5, y: 0.35), caption: "Christ in the Storm on the Sea of Galilee")
    ]

    /// A prayer's painting on the page's rows and shelves, its own page,
    /// Saved and Learn by Heart: the scene it speaks of where it has one
    /// (`scenes`), else its topic's painting, so no prayer stands under a
    /// painting chosen for nothing
    static func prayer(_ prayerID: String) -> PrayerBookPainting {
        if let scene = scenes[prayerID] { return scene }
        if let topic = PrayerBook.homeChapter(of: prayerID) { return self.topic(topic) }
        return saved
    }

    /// The prayers that speak of a scene, a saint or a mystery of their
    /// own. A painting stands over more than one prayer only where they
    /// share its subject: the Sacred Heart's acts, Our Lady of Sorrows'
    /// prayers. The sources and licences are in
    /// Tools/ContentSourcing/sources.py.
    static let scenes: [String: PrayerBookPainting] = {
        func p(_ asset: String, _ x: Double, _ y: Double, _ caption: String) -> PrayerBookPainting {
            PrayerBookPainting(asset: asset, focal: UnitPoint(x: x, y: y), caption: caption)
        }
        let trinity = p("devotion_holy_trinity", 0.5, 0.3, "The Holy Trinity")
        let nicene = p("topic_holy_trinity", 0.5, 0.2, "The Holy Trinity")
        let pentecost = p("glorious_pentecost", 0.5, 0.3, "Pentecost")
        let rosary = p("feast_our_lady_of_the_rosary", 0.5, 0.3, "Our Lady of the Rosary")
        let prodigal = p("topic_confession", 0.5, 0.35, "The Return of the Prodigal Son")
        let immaculate = p("mary_immaculate_conception", 0.5, 0.25, "The Immaculate Conception")
        let atPrayer = p("mary_virgin_in_prayer", 0.5, 0.35, "The Virgin in Prayer")
        let mercy = p("mary_mother_of_mercy", 0.5, 0.3, "Our Lady of Mercy")
        let carmel = p("mary_mount_carmel", 0.5, 0.25, "Our Lady of Mount Carmel")
        let sorrows = p("mary_mater_dolorosa", 0.45, 0.35, "Our Lady of Sorrows")
        let holyName = p("jesus_holy_name", 0.5, 0.2, "The Adoration of the Name of Jesus")
        let sacredHeart = p("topic_our_lord", 0.5, 0.25, "The Sacred Heart of Jesus")
        let blood = p("jesus_precious_blood", 0.5, 0.35, "The Blood of the Redeemer")
        let host = p("jesus_eucharist_saviour", 0.5, 0.3, "The Saviour")
        let joseph = p("devotion_st_joseph", 0.5, 0.2, "Saint Joseph and the Christ Child")
        let carpenter = p("saint_joseph_carpenter", 0.5, 0.4, "Saint Joseph the Carpenter")
        let happyDeath = p("topic_sick_dying", 0.5, 0.55, "The Death of Saint Joseph")
        let family = p("prayer_holy_family", 0.6, 0.4, "The Holy Family")
        let aquinas = p("saint_thomas_aquinas", 0.5, 0.3, "Saint Thomas Aquinas")
        let david = p("psalm_king_david", 0.5, 0.25, "King David")
        let night = p("hour_night", 0.5, 0.4, "Night Prayers")
        let emmaus = p("prayer_supper_emmaus", 0.5, 0.35, "The Supper at Emmaus")
        let healing = p("prayer_healing_sick", 0.45, 0.4, "Christ Healing the Sick")
        let allSaints = p("feast_all_saints", 0.5, 0.3, "The Adoration of the Trinity")
        return [
            // The First Prayers
            "sign_of_cross": trinity,
            "our_father": p("luminous_proclamation", 0.5, 0.3, "The Sermon on the Mount"),
            "hail_mary": p("joyful_annunciation", 0.5, 0.18, "The Annunciation"),
            "glory_be": trinity,
            "fatima_prayer": rosary,
            "apostles_creed": pentecost,
            "nicene_creed": nicene,
            "act_of_contrition": prodigal,
            // Daily Prayers
            "morning_offering": p("hour_morning", 0.5, 0.35, "Morning Prayers"),
            "benedictus": p("saint_john_baptist_birth", 0.65, 0.6, "The Birth of St John the Baptist"),
            "grace_before": emmaus,
            "grace_after": emmaus,
            "actiones_nostras": carpenter,
            "aquinas_before_study": aquinas,
            "examen": night,
            "in_manus_tuas": night,
            "nunc_dimittis": p("joyful_presentation", 0.5, 0.3, "The Presentation in the Temple"),
            "visita_quaesumus": family,
            // Short Prayers
            "sweet_heart": sacredHeart,
            "sacred_heart_trust": sacredHeart,
            "jesus_meek": sacredHeart,
            "my_lord_and_my_god": p("easter_saint_thomas", 0.4, 0.4, "The Incredulity of Saint Thomas"),
            "o_sacrament_most_holy": host,
            "blessed_be_conception": immaculate,
            "totus_tuus": atPrayer,
            "st_joseph_pray": joseph,
            "jmj": family,
            "jmj_heart_and_soul": family,
            "holy_spirit_enlighten": pentecost,
            // Holy Mass and Communion
            "aquinas_before_mass": aquinas,
            "domine_non_sum_dignus": host,
            "aquinas_after_mass": aquinas,
            // Confession
            "miserere": david,
            "beati_quorum": david,
            // The Blessed Sacrament
            "adoro_te": host,
            "spiritual_communion": host,
            "o_sacrum_convivium": host,
            "ave_verum": host,
            // The Holy Spirit
            "come_holy_ghost": pentecost,
            "veni_creator": pentecost,
            "veni_sancte_spiritus": pentecost,
            // Our Lord
            "litany_holy_name": holyName,
            "jesus_prayer": holyName,
            "golden_arrow": holyName,
            "infant_of_prague": p("jesus_good_shepherd", 0.4, 0.45, "The Child Jesus as the Good Shepherd"),
            "litany_sacred_heart": sacredHeart,
            "consecration_sacred_heart": sacredHeart,
            "reparation_sacred_heart": sacredHeart,
            "efficacious_novena": sacredHeart,
            "litany_precious_blood": blood,
            "precious_blood_offering": blood,
            "en_ego": p("sorrowful_crucifixion", 0.5, 0.3, "Christ Crucified"),
            "christ_the_king": p("feast_christ_the_king", 0.5, 0.3, "Christ the King"),
            "anima_christi": p("jesus_anima_christi", 0.5, 0.3, "Christ Embracing Saint Bernard"),
            // Our Lady
            "hail_holy_queen": p("glorious_coronation", 0.5, 0.12, "The Coronation of Our Lady"),
            "litany_loreto": rosary,
            "alma_redemptoris": antiphon(.almaRedemptoris),
            "ave_regina_caelorum": antiphon(.aveReginaCaelorum),
            "regina_caeli": reginaCaeli,
            "magnificat": p("topic_thanksgiving", 0.5, 0.3, "The Madonna of the Magnificat"),
            "ave_maris_stella": p("feast_annunciation", 0.7, 0.5, "The Annunciation"),
            "inviolata": immaculate,
            "salve_mater": mercy,
            "tota_pulchra": immaculate,
            "flos_carmeli": carmel,
            "angelus": p("joyful_annunciation", 0.5, 0.18, "The Annunciation"),
            "sub_tuum": mercy,
            "memorare": p("glorious_assumption", 0.5, 0.3, "The Assumption"),
            "o_domina_mea": atPrayer,
            "three_hail_marys": atPrayer,
            "miraculous_medal": immaculate,
            "mary_after_communion": atPrayer,
            "perpetual_help": mercy,
            "our_lady_of_good_counsel": p("mary_sistine_madonna", 0.5, 0.25, "The Sistine Madonna"),
            "our_lady_of_lourdes": immaculate,
            "immaculate_heart": atPrayer,
            "mary_help_of_christians": mercy,
            "our_lady_of_mount_carmel": carmel,
            "stabat_mater": p("seven_sorrows_calvary", 0.5, 0.35, "Our Lady at the Foot of the Cross"),
            "our_lady_of_sorrows": sorrows,
            "litany_seven_sorrows": sorrows,
            "sorrows_closing_prayer": sorrows,
            // St Joseph
            "ad_te_beate_ioseph": joseph,
            "memorare_st_joseph": joseph,
            "litany_st_joseph": joseph,
            "st_joseph_workers": carpenter,
            "st_joseph_happy_death": happyDeath,
            // Angels and Saints
            "angele_dei": p("devotion_guardian_angels", 0.5, 0.3, "The Guardian Angel"),
            "st_michael_prayer": p("saint_michael", 0.5, 0.3, "Saint Michael"),
            "litany_of_the_saints": allSaints,
            "st_anne": p("topic_first_prayers", 0.5, 0.3, "St Anne teaching the Virgin"),
            "st_anthony": p("saint_anthony", 0.5, 0.35, "Saint Anthony of Padua"),
            "st_peregrine": healing,
            "st_dominic_o_lumen": rosary,
            "st_francis_before_crucifix": p("topic_short_prayers", 0.5, 0.3, "Saint Francis in Meditation"),
            // Thanksgiving
            "te_deum": allSaints,
            // For the Church and the Living
            "prayer_for_priests": p("topic_holy_mass", 0.5, 0.5, "The Mass at Bolsena"),
            "conversion_of_sinners": p("saint_paul_conversion", 0.5, 0.6, "The Conversion of Saint Paul"),
            "rosary_closing_prayer": rosary,
            "prayer_for_family": family,
            "parents_for_children": family,
            // The Sick and the Dying
            "prayer_for_the_sick": healing,
            "happy_death": happyDeath,
            // In Time of Need
            "prayer_for_travel": p("prayer_tobias_angel", 0.5, 0.3, "Tobias and the Angel")
        ]
    }()
}

/// A painting set as a card's ground: cropped about its subject and
/// dissolving to the page beneath the words laid over it, never to a
/// flat slab. Hidden from VoiceOver, which reads the card's words.
struct PrayerBookPaintingGround: View {
    let painting: PrayerBookPainting

    /// How dark the foot runs, under the title set across it
    var footOpacity: Double = 1

    var body: some View {
        ZStack {
            CachedAssetImage(painting.resolvedAsset, focal: painting.focal)

            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0), location: 0),
                    .init(color: AppColors.background.opacity(0.45), location: 0.42),
                    .init(color: AppColors.background.opacity(0.9), location: 0.78),
                    .init(color: AppColors.background.opacity(footOpacity), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .accessibilityHidden(true)
    }
}
