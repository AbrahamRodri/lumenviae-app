//
//  PrayersThisSeasonShelf.swift
//  Lumen Viae
//
//  This Season on the Prayers tab: in Advent, the wreath's Sunday collects
//  and, from 17 to 23 December, the O Antiphons before them, each a card
//  naming today's part, opening the prayer at it. Out of season the shelf
//  is absent. Design's "This Season" frame (reports/design/
//  advent-this-season/BUILD.md), Abraham's "Looks right", 23 Nov 2026.
//

import SwiftUI

struct PrayersThisSeasonShelf: View {
    @Environment(AppRouter.self) private var router
    /// The prayer day's start: the shelf changes with the day
    let day: Date

    var body: some View {
        let cards = AdventPrayerPlace.seasonPrayers(on: day).compactMap { id in
            PrayerBook.prayer(id).map { ($0, AdventPrayerPlace.todaysPart(
                of: id, in: PrayAlongView.stanzas($0.english), on: day)) }
        }
        if !cards.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                PrayersShelfHeading(
                    title: String(localized: "This Season", comment: "Prayers tab: the heading over the Advent prayers' cards"),
                    label: String(localized: "ADVENT", comment: "Prayers tab: the season named at the right of This Season, in small gold capitals")
                )
                ForEach(cards, id: \.0.id) { prayer, part in
                    PrayersSeasonCard(
                        prayer: prayer,
                        part: part,
                        action: Self.action(for: prayer.id, on: day)
                    ) {
                        router.push(.devotionPrayer(id: prayer.id))
                    }
                }
            }
        }
    }

    /// The card's quiet gold line, saying what a tap reads
    static func action(for prayerID: String, on day: Date) -> String {
        if prayerID == AdventPrayerPlace.antiphonsID {
            return String(localized: "Read today's antiphon", comment: "Prayers tab, This Season: the O Antiphons card's action line")
        }
        return AdventPrayerPlace.isSundayOrEve(day)
            ? String(localized: "Read this Sunday's collect", comment: "Prayers tab, This Season: the Advent wreath card on a Sunday of Advent or its Saturday eve")
            : String(localized: "Read this week's collect", comment: "Prayers tab, This Season: the Advent wreath card on a weekday")
    }
}

/// One of This Season's cards, in the Your Novena card's look: the
/// prayer's painting at the left edge, today's part, the prayer's name and
/// what a tap reads; the whole card is the button
struct PrayersSeasonCard: View {
    let prayer: BookPrayer
    let part: String?
    let action: String
    let open: () -> Void

    private static let paintingWidth: CGFloat = 108
    /// Past this height a painting cut 108 wide loses half its scene (the
    /// wreath's Mary, when a Spanish title or the largest text wraps the
    /// card to four lines): it is drawn this tall from the card's top and
    /// dissolves into the card beneath
    private static let paintingMaxHeight: CGFloat = 128

    /// The prayer's own painting, the one its reader and Explore hang:
    /// Fra Angelico's Annunciation for the wreath, cut between the angel
    /// and Mary, and Isaiah for the O Antiphons (PrayerBookPainting.prayer)
    static func painting(for prayerID: String) -> PrayerBookPainting {
        PrayerBookPainting.prayer(prayerID)
    }

    var body: some View {
        Button(action: open) {
            HStack(spacing: 0) {
                GeometryReader { proxy in
                    let height = max(proxy.size.height, 120)
                    let drawn = min(height, Self.paintingMaxHeight)
                    PrayersPaintingThumb(
                        painting: Self.painting(for: prayer.id),
                        width: Self.paintingWidth,
                        height: drawn)
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .black, location: 0),
                                    .init(color: .black, location: height > drawn ? 0.7 : 1),
                                    .init(color: height > drawn ? .clear : .black, location: 1),
                                ],
                                startPoint: .top, endPoint: .bottom)
                        )
                        .frame(height: height, alignment: .top)
                }
                .frame(width: Self.paintingWidth)

                VStack(alignment: .leading, spacing: 6) {
                    if let part {
                        Text(part.uppercased())
                            .font(AppFonts.labelFont(9.5))
                            .tracking(2.2)
                            .foregroundColor(AppColors.gold)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(prayer.listTitle)
                        .font(AppFonts.titleFont(19))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(action.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .fixedSize(horizontal: false, vertical: true)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: AppLine.hairline)
            )
        }
        .buttonStyle(SacredCardButtonStyle(scales: false))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text([prayer.listTitle, part, action].compactMap { $0 }.joined(separator: ". ")))
        .accessibilityAddTraits(.isButton)
    }
}
