//
//  ChapelPrayerBookTile.swift
//  Lumen Viae
//
//  Prayers on the Chapel page — the Prayer Book, under the name its
//  tab now carries: the order for the hour it is —
//  Morning Prayers, the Angelus, Night Prayers — set like a page of the
//  book, over the day's three hours.
//
//  Full: the hour's order by name, with the line that says what it is,
//  as a door to the book; PRAY beneath it, outlined, since the page's
//  one filled gold act is the focus block's; and the three hours ruled
//  off along the card's floor — MORNING, NOON or EVENING, NIGHT, the
//  Prayers page's own stations — each a door that prays its own order
//  and each saying where it stands: prayed, now, or when it is said.
//  Never "missed".
//  Half: the hour's order and when it is said, the three hours along
//  the floor, and the whole tile prays it.
//
//  The reader's ribbons are not on this tile: they stand under Saved
//  on Prayers' Today.
//

import SwiftUI

struct ChapelPrayerBookTile: View {

    let span: Int

    @Environment(AppRouter.self) private var router

    private var store = PrayerBookStore.shared

    init(span: Int) {
        self.span = span
    }

    var body: some View {
        // Redrawn when the book's hour turns: the Chapel keeps no clock,
        // and the tile went on offering the order it was first drawn with
        TimelineView(PrayerBookHourSchedule()) { _ in
            if span == 2 { full } else { half }
        }
    }

    private var order: PrayerOrder { PrayerBook.dayOrder(at: Date()) }

    private var offered: Bool { prayedNow(order) }

    /// Prayed for the hour it is now, as the Prayers page reads it: the
    /// day's offering for Morning and Night Prayers, the bell's for the
    /// Angelus (`PrayerBook.isOfferedNow`), so an Angelus said at noon
    /// leaves EVENING still to pray, where the strip names that bell
    private func prayedNow(_ order: PrayerOrder) -> Bool {
        PrayerBook.isOfferedNow(
            order,
            at: Date(),
            offeredToday: store.wasOffered(order.id),
            lastOffered: store.lastOffered(order.id)
        )
    }

    private func pray(_ order: PrayerOrder) {
        router.push(.prayAlong(.order(order)))
    }

    /// "At noon", or "Prayed today" once it has been
    private var momentLine: String {
        offered ? "Prayed today" : PrayerBook.dayOrderMoment(at: Date())
    }

    /// The part of the day the book is at, for the title line's note, in
    /// the Prayers page's own station names — Morning, Noon, Evening,
    /// Night (`PrayerBook.hourName`) — so the note and the station lit
    /// beneath it can never disagree: the Angelus is Noon's at the noon
    /// bell and Evening's at the six o'clock one
    private var dayPart: String {
        PrayerBook.hourName(of: order, at: Date())
    }

    // MARK: Full

    private var full: some View {
        ChapelTileFrame(
            tile: .prayers,
            span: 2,
            surface: .leaf,
            note: dayPart
        ) {
            VStack(spacing: 0) {
                Button { router.push(.prayerBook) } label: {
                    VStack(spacing: 8) {
                        Text(order.title(on: Date()))
                            .font(AppFonts.titleFont(26))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .contentTransition(.opacity)

                        // The Prayers page's own sentence for the hour, the
                        // one its Pray Now card sets, so the two never say
                        // what the same order is in two ways
                        Text(PrayerBook.daySummary(of: order, on: Date()))
                            .font(AppFonts.italicFont(16))
                            .foregroundColor(AppColors.cream.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .frame(maxWidth: 260)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens Prayers.")

                GoldCTAButton(
                    title: "Pray",
                    fill: .outline,
                    prominence: .inline,
                    silhouette: .rounded(14),
                    glyph: .play,
                    fullWidth: false
                ) {
                    pray(order)
                }
                .accessibilityLabel("Pray \(order.title(on: Date()))")
                .padding(.top, 18)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.top, 26)
            .padding(.bottom, 24)
            .animation(Motion.crossfade, value: order.id)
        } floor: {
            hours
        }
    }

    // MARK: Half

    private var half: some View {
        ChapelTileFrame(
            tile: .prayers,
            span: 1,
            surface: .leaf,
            onTap: { pray(order) },
            accessibilityLabel: "\(order.title(on: Date())), \(momentLine.lowercased()). Double-tap to pray."
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.title(on: Date()))
                    .font(AppFonts.titleFont(16))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)

                Text(momentLine)
                    .font(AppFonts.italicFont(13.5))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            .animation(Motion.crossfade, value: momentLine)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 18)
            .padding(.bottom, 14)
        } floor: {
            hours
        }
    }

    // MARK: The day's three hours

    /// Morning, the Angelus and Night along the card's floor, ruled off
    /// from the order above and from one another
    private var hours: some View {
        HStack(spacing: 0) {
            ForEach(Array(PrayerBook.dayOrders.enumerated()), id: \.element.id) { index, dayOrder in
                hour(dayOrder)
                    .overlay(alignment: .leading) {
                        if index > 0 {
                            Rectangle()
                                .fill(AppColors.gold.opacity(0.16))
                                .frame(width: AppLine.hairline)
                        }
                    }
            }
        }
        .padding(.top, span == 2 ? 14 : 12)
        .padding(.bottom, span == 2 ? 16 : 14)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.16))
                .frame(height: AppLine.hairline)
        }
    }

    /// One hour: its bead — gold once prayed, ringed while it is the
    /// hour's — its name, and at full width where it stands
    @ViewBuilder
    private func hour(_ dayOrder: PrayerOrder) -> some View {
        let isCurrent = dayOrder.id == order.id
        let wasOffered = prayedNow(dayOrder)
        let place = PrayerBook.standing(of: dayOrder, at: Date(), offered: wasOffered)
        let standing = Self.word(for: place)
        let name = PrayerBook.hourName(of: dayOrder, at: Date())

        let face = VStack(spacing: 6) {
            HourBead(offered: wasOffered, current: isCurrent)

            if span == 2 {
                Text(name.uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2)
                    .foregroundColor(isCurrent ? AppColors.cream : AppColors.cream.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(standing)
                    .font(AppFonts.italicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .contentTransition(.opacity)
                    .animation(Motion.crossfade, value: standing)
            } else {
                // At half width the hour's own glyph — the cock, the
                // bell, the lamp — where its name had no room: MORNING
                // and ANGELUS shrank to two sizes beside NIGHT, and the
                // Regina Cæli could not be set at all
                AppIcon(dayOrder.icon, size: 14)
                    .foregroundColor(isCurrent ? AppColors.cream : AppColors.cream.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)

        if span == 2 {
            // At full width each hour is a door to its own order, so the
            // morning's can still be said at noon
            Button { pray(dayOrder) } label: {
                face
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            // Led by the word on the glass, so Voice Control finds it by
            // what it shows: "Noon, the Angelus, the hour it is now"
            .accessibilityLabel("\(name), \(dayOrder.title(on: Date())), \(Self.spoken(place))")
            .accessibilityHint("Double-tap to pray.")
            .accessibilityAddTraits(.isButton)
        } else {
            face
                .accessibilityHidden(true)
        }
    }

    /// Where an hour stands, in the strip's words: "Prayed", "Now", or
    /// when it is said, in the Prayers page's words ("At noon")
    private static func word(for standing: PrayerBook.HourStanding) -> String {
        switch standing {
        case .offered:      return "Prayed"
        case .now:          return "Now"
        case .at(let when): return when
        }
    }

    /// The same, as VoiceOver hears it
    private static func spoken(_ standing: PrayerBook.HourStanding) -> String {
        switch standing {
        case .offered:      return "prayed"
        case .now:          return "the hour it is now"
        case .at(let when): return when.lowercased()
        }
    }
}

/// An hour's bead on the Prayer Book's strip: gold once prayed
private struct HourBead: View {
    let offered: Bool
    let current: Bool

    var body: some View {
        ZStack {
            if offered {
                Circle()
                    .fill(AppColors.goldGradient)
                    .frame(width: 7, height: 7)
                    .shadow(color: AppColors.gold.opacity(0.55), radius: 1.5)
            } else if current {
                Circle()
                    .strokeBorder(AppColors.gold, lineWidth: 1.5)
                    .frame(width: 9, height: 9)
                    .shadow(color: AppColors.gold.opacity(0.35), radius: 4)
            } else {
                Circle()
                    .fill(AppColors.textSecondary.opacity(0.4))
                    .frame(width: 7, height: 7)
            }
        }
        .frame(width: 10, height: 10)
        .animation(Motion.settle, value: offered)
    }
}
