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
