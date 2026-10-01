//
//  PrayersComponents.swift
//  Lumen Viae
//
//  The Prayers page's pieces: the bar its three parts are chosen on, a
//  section's title, the strip of the day's three hours at the foot of
//  the Pray Now card, the season's antiphon set over its painting, the
//  ruled row every list on the page shares, a saved prayer's card, a
//  place chip on Occasions and an occasion's row, and the card a search
//  names a topic with.
//
//  Ruled rows and hairline outlines on the bare page, as the rest of the
//  app is drawn; the one gold act on the page is the Pray Now card's.
//

import SwiftUI

// MARK: - The three parts

/// TODAY · OCCASIONS · ALL PRAYERS: the part chosen in gold over a short
/// rule, the others quiet, and a hairline under all three. While a
/// search stands in the parts' place none is lit.
struct PrayersSectionBar: View {
    let selection: PrayersSection?
    let onSelect: (PrayersSection) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PrayersSection.allCases) { section in
                let selected = section == selection
                Button { onSelect(section) } label: {
                    VStack(spacing: 6) {
                        Text(section.title.uppercased())
                            .font(AppFonts.labelFont(10))
                            .tracking(2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(selected ? AppColors.gold : AppColors.textSecondary)

                        Rectangle()
                            .fill(AppColors.gold)
                            .frame(width: 26, height: 1)
                            .opacity(selected ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel(section.title)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .animation(Motion.crossfade, value: selection)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.15))
                .frame(height: AppLine.hairline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Prayer views")
    }
}

// MARK: - Section title

/// A section of the page: its name in the display face and one italic
/// line saying what stands beneath it
struct PrayersSectionTitle: View {
    let title: String
    var note: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFonts.titleFont(19))
                .foregroundColor(AppColors.cream)
                .accessibilityAddTraits(.isHeader)

            if let note {
                Text(note)
                    .font(AppFonts.readingItalicFont(14.5))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - The day's three hours, at the card's foot

/// MORNING · NOON · NIGHT across the foot of the Pray Now card, each
/// saying where it stands — Offered, Now, or when it is said — and each a
/// way to see that hour's prayers above. The hour shown is lit. Never
/// "missed": a morning not prayed by evening still reads "On rising".
/// The Angelus is offered for its bell, not its day: prayed at noon, it
/// reads OFFERED until three, and then the evening bell asks again.
struct PrayerHourStations: View {
    let now: Date

    /// The order the card above is showing
    let shownID: String

    let onSelect: (PrayerOrder) -> Void

    private var store = PrayerBookStore.shared

    init(now: Date, shownID: String, onSelect: @escaping (PrayerOrder) -> Void) {
        self.now = now
        self.shownID = shownID
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(PrayerBook.dayOrders.enumerated()), id: \.element.id) { index, order in
                if index > 0 {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.18))
                        .frame(width: AppLine.hairline)
                }
                station(order)
            }
        }
        // So the hairlines between the stations run their full height
        .fixedSize(horizontal: false, vertical: true)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.2))
                .frame(height: AppLine.hairline)
        }
        .animation(Motion.crossfade, value: shownID)
    }

    private func station(_ order: PrayerOrder) -> some View {
        let offered = PrayerBook.isOfferedNow(
            order,
            at: now,
            offeredToday: store.wasOffered(order.id, on: now),
            lastOffered: store.lastOffered(order.id)
        )
        let standing = PrayerBook.standing(of: order, at: now, offered: offered)
        let hourName = PrayerBook.hourName(of: order, at: now)
        let shown = order.id == shownID
        let color: Color = shown
            ? AppColors.goldLight
            : standing == .offered ? AppColors.cream.opacity(0.7) : AppColors.textSecondary

        return Button { onSelect(order) } label: {
            VStack(spacing: 3) {
                Text(hourName.uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 4) {
                    if standing == .offered {
                        AppIcon("ph-seal-check-fill", size: 10)
                            .foregroundColor(AppColors.gold)
                    }
                    Text(Self.word(for: standing))
                        .font(AppFonts.readingItalicFont(13))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .foregroundColor(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(AppColors.gold.opacity(shown ? 0.1 : 0))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppColors.goldLight)
                    .frame(height: 1.5)
                    .padding(.horizontal, 20)
                    .opacity(shown ? 1 : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityElement(children: .combine)
        // Led by the word on the glass, so Voice Control finds it by
        // what it shows: "Noon, the Angelus, the hour it is now"
        .accessibilityLabel("\(hourName), \(order.title(on: now)), \(Self.spoken(standing))")
        .accessibilityAddTraits(shown ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(shown ? "" : "Shows it above")
    }

    static func word(for standing: PrayerBook.HourStanding) -> String {
        switch standing {
        case .offered:       return "Offered"
        case .now:           return "Now"
        case .at(let when):  return when
        }
    }

    private static func spoken(_ standing: PrayerBook.HourStanding) -> String {
        switch standing {
        case .offered:       return "offered"
        case .now:           return "the hour it is now"
        case .at(let when):  return when.lowercased()
        }
    }
}

// MARK: - The season's antiphon

/// The antiphon of Our Lady the Church sings at the close of the day in
/// this part of the year, over the mystery it sings of
struct MarianSeasonCard: View {
    let prayer: BookPrayer
    let antiphon: MarianAntiphon

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PrayerBookPaintingGround(painting: .antiphon(antiphon), footOpacity: 0.9)

            VStack(alignment: .leading, spacing: 3) {
                Text("THIS SEASON")
                    .font(AppFonts.labelFont(8.5))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold)

                Text(prayer.listTitle)
                    .font(AppFonts.titleFont(23))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text("Said at the end of the day")
                    .font(AppFonts.readingItalicFont(14.5))
                    .foregroundColor(AppColors.cream.opacity(0.8))
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("This season: \(prayer.listTitle). Said at the end of the day, \(antiphon.season).")
        .accessibilityHint("Opens the prayer")
    }
}

// MARK: - The ruled row

/// One line of a list on the Prayers page: a name, an italic note under
/// it, and at the trailing edge whatever the list says of it — how many
/// prayers a topic holds, or the reader's own marks on a prayer (BY
/// HEART, its ribbon) — then a caret.
struct PrayersLedgerRow: View {
    let title: String
    var note: String?
    var count: Int?

    /// The prayer the row opens, so it can wear the reader's marks
    var prayerID: String?

    var showsRule: Bool
    let action: () -> Void

    private var store = PrayerBookStore.shared

    init(
        title: String,
        note: String? = nil,
        count: Int? = nil,
        prayerID: String? = nil,
        showsRule: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.note = note
        self.count = count
        self.prayerID = prayerID
        self.showsRule = showsRule
        self.action = action
    }

    var body: some View {
        let byHeart = prayerID.map { store.isByHeart($0) } ?? false
        let kept = prayerID.map { store.isKept($0) } ?? false

        Button(action: action) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        if let note {
                            Text(note)
                                .font(AppFonts.readingItalicFont(13.5))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    if byHeart {
                        ByHeartMark()
                    }
                    if kept {
                        RibbonMark(kept: true, width: 7, restLength: 12, keptLength: 16)
                    }
                    if let count {
                        Text("\(count)")
                            .font(AppFonts.bodyFont(14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    AppIcon("ph-caret-right", size: 12)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                }
                .padding(.vertical, 8)
                .frame(minHeight: 48)

                if showsRule {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.12))
                        .frame(height: AppLine.hairline)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spokenLabel(byHeart: byHeart, kept: kept))
        .accessibilityAddTraits(.isButton)
    }

    private func spokenLabel(byHeart: Bool, kept: Bool) -> String {
        var parts = [title]
        if let note { parts.append(note) }
        if let count { parts.append(count == 1 ? "1 prayer" : "\(count) prayers") }
        if byHeart { parts.append("known by heart") }
        if kept { parts.append("saved") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - A saved prayer

/// A prayer the reader keeps with a ribbon, standing on the page as a
/// small outlined card the ribbon hangs from: its name, and the topic it
/// belongs to. Every card is one height, so a row of them ends on one
/// line: a long name takes three lines at most, a little smaller.
struct SavedPrayerCard: View {
    let prayer: BookPrayer
    let action: () -> Void

    private var store = PrayerBookStore.shared

    private static let height: CGFloat = 132

    init(prayer: BookPrayer, action: @escaping () -> Void) {
        self.prayer = prayer
        self.action = action
    }

    var body: some View {
        let topic = PrayerBook.homeChapter(of: prayer.id)?.title

        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(prayer.listTitle)
                    .font(AppFonts.readingFont(16))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)

                if let topic {
                    Text(topic)
                        .font(AppFonts.readingItalicFont(12))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.top, 40)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, minHeight: Self.height, maxHeight: Self.height, alignment: .bottomLeading)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: AppLine.hairline)
            )
            // The ribbon the prayer was kept with, hung from the card's
            // head as it hangs from the head of the prayer's page
            .overlay(alignment: .topTrailing) {
                RibbonMark(kept: true, width: 11, restLength: 30, keptLength: 38)
                    .padding(.trailing, 14)
                    .offset(y: -1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(SacredCardButtonStyle())
        .contextMenu {
            Button {
                withAnimation(Motion.crossfade) { store.toggleRibbon(prayer.id) }
            } label: {
                Label("Take the ribbon out", systemImage: "minus.circle")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel([prayer.listTitle, topic].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Take the ribbon out") {
            withAnimation(Motion.crossfade) { store.toggleRibbon(prayer.id) }
        }
    }
}

// MARK: - Occasions

/// One place on Occasions — AT MASS, CONFESSION — as a pill: lit in gold
/// when chosen, a quiet outline when not
struct PrayersPlaceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(9.5))
                .tracking(2)
                .lineLimit(1)
                .foregroundColor(isSelected ? AppColors.goldLight : AppColors.textSecondary)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .background(Capsule().fill(AppColors.gold.opacity(isSelected ? 0.12 : 0)))
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? AppColors.gold.opacity(0.7) : AppColors.textSecondary.opacity(0.4),
                        lineWidth: isSelected ? 1 : AppLine.hairline
                    )
                )
                // The pill is drawn 36 tall and answers to 44
                .padding(.vertical, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .animation(Motion.crossfade, value: isSelected)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// An order of prayer kept for an occasion, as a ruled row: its glyph in
/// a small outlined frame, its name, and when it is said
struct PrayersOccasionRow: View {
    let order: PrayerOrder
    let now: Date
    var showsRule: Bool
    let action: () -> Void

    private var store = PrayerBookStore.shared

    init(order: PrayerOrder, now: Date, showsRule: Bool = true, action: @escaping () -> Void) {
        self.order = order
        self.now = now
        self.showsRule = showsRule
        self.action = action
    }

    var body: some View {
        let offered = store.wasOffered(order.id, on: now)
        let title = order.title(on: now)

        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    AppIcon(order.icon, size: 18)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 38, height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(order.occasion)
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    if offered {
                        AppIcon("ph-seal-check-fill", size: 13)
                            .foregroundColor(AppColors.gold.opacity(0.85))
                    }
                    AppIcon("ph-caret-right", size: 12)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                }
                .padding(.vertical, 10)
                .frame(minHeight: 64)

                if showsRule {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.12))
                        .frame(height: AppLine.hairline)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(order.occasion)\(offered ? ", offered today" : "")")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - An order found

/// An order of prayer a search's words name, standing with the topics
/// above the prayers found: "Visiting Jesus in Church · Said together ·
/// 5 prayers"
struct PrayersOrderCard: View {
    let order: PrayerOrder
    let now: Date
    let action: () -> Void

    var body: some View {
        let count = order.prayers(on: now).count
        let title = order.title(on: now)
        let line = count == 1 ? "\(order.occasion) · one prayer" : "\(order.occasion) · \(count) prayers"

        Button(action: action) {
            HStack(spacing: 12) {
                AppIcon(order.icon, size: 18)
                    .foregroundColor(AppColors.gold)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(line)
                        .font(AppFonts.readingItalicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.gold.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 58)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prayers said together: \(title), \(line)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - A topic found

/// A chapter the search's words name, standing above the prayers found:
/// "Prayers to Mary · Topic · 20 prayers"
struct PrayersTopicCard: View {
    let chapter: PrayerBookChapter
    let action: () -> Void

    var body: some View {
        let count = chapter.prayerIDs.count

        Button(action: action) {
            HStack(spacing: 12) {
                AppIcon(chapter.icon, size: 18)
                    .foregroundColor(AppColors.gold)

                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.topic)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Topic · \(count) prayers")
                        .font(AppFonts.readingItalicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer(minLength: 8)

                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.gold.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 58)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Topic: \(chapter.topic), \(count) prayers")
        .accessibilityAddTraits(.isButton)
    }
}
