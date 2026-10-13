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
    /// painting to the Resurrection the Regina Cæli sings.
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
                ? PrayerBookPainting(asset: "glorious_resurrection", caption: "The Resurrection")
                : PrayerBookPainting(asset: "joyful_annunciation", focal: UnitPoint(x: 0.5, y: 0.18), caption: "The Annunciation")
        }
    }

    // MARK: Our Lady's antiphons

    /// The painting over the antiphon of the season
    static func antiphon(_ antiphon: MarianAntiphon) -> PrayerBookPainting {
        switch antiphon {
        case .almaRedemptoris:
            return PrayerBookPainting(asset: "joyful_nativity", focal: UnitPoint(x: 0.5, y: 0.35), caption: "The Nativity")
        case .reginaCaeli:
            return PrayerBookPainting(asset: "glorious_resurrection", caption: "The Resurrection")
        case .aveReginaCaelorum, .salveRegina:
            return PrayerBookPainting(asset: "glorious_coronation", focal: UnitPoint(x: 0.5, y: 0.12), caption: "The Coronation of Our Lady")
        }
    }

    // MARK: The Prayers page

    /// The Saved shortcut's painting
    static let saved = PrayerBookPainting(
        asset: "glorious_coronation", focal: UnitPoint(x: 0.5, y: 0.3), caption: "The Coronation of Our Lady"
    )

    /// An occasion's order on its shortcut: the Last Supper before Mass,
    /// Gethsemane before Confession, else the order's hour or the
    /// Annunciation
    static func order(_ order: PrayerOrder, on date: Date = Date()) -> PrayerBookPainting {
        switch order.id {
        case "before_mass", "after_mass":
            return PrayerBookPainting(
                asset: "luminous_eucharist", focal: UnitPoint(x: 0.5, y: 0.35), caption: "The Last Supper")
        case "before_confession", "after_confession":
            return PrayerBookPainting(
                asset: "sorrowful_agony", focal: UnitPoint(x: 0.5, y: 0.3), caption: "The Agony in the Garden")
        default:
            return hour(order, on: date)
        }
    }

    // MARK: The topics

    /// The painting over a topic, on its card in All Topics and at the
    /// head of its own page. Each topic has one of its own; the sources
    /// and licences are in Tools/ContentSourcing/sources.py.
    static func topic(_ chapter: PrayerBookChapter) -> PrayerBookPainting {
        topic(id: chapter.id)
    }

    /// A topic's painting by the topic's id ("mass", "day"), which Home's
    /// Today's Prayer hangs over the Mass and the Hours of Prayer too
    static func topic(id: String) -> PrayerBookPainting {
        topics[id] ?? PrayerBookPainting(
            asset: "glorious_coronation", focal: UnitPoint(x: 0.5, y: 0.2), caption: "The Coronation of Our Lady")
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

    /// A prayer's painting on the page's rows and shelves: the scene it
    /// speaks of — the Annunciation for the Hail Mary, Pentecost for the
    /// Creed the Apostles handed on
    static func prayer(_ prayerID: String) -> PrayerBookPainting {
        switch prayerID {
        case "our_father":
            return PrayerBookPainting(
                asset: "luminous_proclamation", focal: UnitPoint(x: 0.5, y: 0.3), caption: "The Sermon on the Mount")
        case "hail_mary":
            return PrayerBookPainting(
                asset: "joyful_annunciation", focal: UnitPoint(x: 0.5, y: 0.18), caption: "The Annunciation")
        case "glory_be":
            return PrayerBookPainting(
                asset: "devotion_holy_trinity", focal: UnitPoint(x: 0.5, y: 0.3), caption: "The Holy Trinity")
        case "apostles_creed":
            return PrayerBookPainting(
                asset: "glorious_pentecost", focal: UnitPoint(x: 0.5, y: 0.3), caption: "Pentecost")
        case "memorare":
            return PrayerBookPainting(
                asset: "glorious_assumption", focal: UnitPoint(x: 0.5, y: 0.3), caption: "The Assumption")
        case "litany_loreto":
            return PrayerBookPainting(
                asset: "feast_our_lady_of_the_rosary", focal: UnitPoint(x: 0.5, y: 0.3),
                caption: "Our Lady of the Rosary")
        default:
            return PrayerBookPainting(
                asset: "glorious_coronation", focal: UnitPoint(x: 0.5, y: 0.2), caption: "The Coronation of Our Lady")
        }
    }
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
