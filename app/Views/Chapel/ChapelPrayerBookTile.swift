//
//  ChapelPrayerBookTile.swift
//  Lumen Viae
//
//  The Prayer Book on the Chapel page: the order for the hour it is —
//  Morning Prayers, the Angelus, Night Prayers — set like a page of the
//  book, over the day's three hours.
//
//  Full: the hour's order by name, with the line that says what it is,
//  as a door to the book; PRAY beneath it, outlined, since the page's
//  one filled gold act is the focus block's; and the three hours ruled
//  off along the card's floor, each a door that prays its own order and
//  each saying where it stands — offered, or when it is said. Never
//  "missed".
//  Half: the hour's order and when it is said, the three hours along
//  the floor, and the whole tile prays it.
//
//  The reader's ribbons are not on this tile: they stand on the book's
//  own first page.
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

    private var offered: Bool { store.wasOffered(order.id) }

    private func pray(_ order: PrayerOrder) {
        router.push(.prayAlong(.order(order)))
    }

    /// "At noon", or "Offered today" once it has been
    private var momentLine: String {
        offered ? "Offered today" : PrayerBook.dayOrderMoment(at: Date())
    }

    /// The part of the day the book is at, for the title line's note —
    /// turning where the book's own moments turn (four, eleven, three
    /// and eight, `PrayerBook.dayOrderMoment`), so the note and the order
    /// beneath it change together on `PrayerBookHourSchedule`
    private var dayPart: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case PrayerBook.dayBeginsAtHour..<11: return "Morning"
        case 11..<15: return "Midday"
        case 15..<20: return "Afternoon"
        default:      return "Evening"
        }
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

                        Text(order.detail)
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
                .accessibilityHint("Opens the Prayer Book")

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
            accessibilityLabel: "\(order.title(on: Date())), \(momentLine). Prays it."
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.title(on: Date()))
                    .font(AppFonts.titleFont(16))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                Text(momentLine)
                    .font(AppFonts.italicFont(13.5))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
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

    /// One hour: its bead — gold once offered, ringed while it is the
    /// hour's — its name, and at full width where it stands
    @ViewBuilder
    private func hour(_ dayOrder: PrayerOrder) -> some View {
        let isCurrent = dayOrder.id == order.id
        let wasOffered = store.wasOffered(dayOrder.id)
        let standing = wasOffered
            ? "Offered"
            : (isCurrent ? PrayerBook.dayOrderMoment(at: Date()) : dayOrder.occasion)

        let face = VStack(spacing: 6) {
            HourBead(offered: wasOffered, current: isCurrent)

            Text(Self.shortName(dayOrder).uppercased())
                .font(AppFonts.labelFont(span == 2 ? 9.5 : 8.5))
                .tracking(span == 2 ? 2 : 1.5)
                .foregroundColor(isCurrent ? AppColors.cream : AppColors.cream.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if span == 2 {
                Text(standing)
                    .font(AppFonts.italicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
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
            .accessibilityLabel("\(dayOrder.title(on: Date())), \(standing.lowercased()). Prays it.")
            .accessibilityAddTraits(.isButton)
        } else {
            face
                .accessibilityHidden(true)
        }
    }

    /// The hour's name as the strip has room to set it
    private static func shortName(_ order: PrayerOrder) -> String {
        switch order.id {
        case PrayerBook.morningOrderID: return "Morning"
        case PrayerBook.angelusOrderID: return PrayerBook.isEastertide(Date()) ? "Regina Cæli" : "Angelus"
        case PrayerBook.nightOrderID:   return "Night"
        default:                        return order.title
        }
    }
}

/// An hour's bead on the Prayer Book's strip
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
