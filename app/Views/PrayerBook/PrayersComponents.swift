//
//  PrayersComponents.swift
//  Lumen Viae
//
//  The Prayers page's pieces, drawn as the Chant page draws its own (the
//  "Prayers Tab Redesign", option A, Oct 2026): a shelf's heading with
//  SEE ALL, a shortcut tile, the card for this hour, a row with its
//  painting, a square card for a shelf that scrolls sideways; then the
//  ruled row the lists share, a saved prayer's card, an occasion's row,
//  and the cards a search names a topic or an order with.
//
//  Cards here are filled with the card ground, as the Chant page's are:
//  they are doors that stand apart from the page. The page has no filled
//  gold act; the hour's PRAY is an outlined disc.
//

import SwiftUI

// MARK: - A shelf's heading

/// A shelf of the page: its name in the display face, and SEE ALL at the
/// trailing edge where there is more than the shelf shows
struct PrayersShelfHeading: View {
    let title: String
    var seeAll: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppFonts.titleFont(17))
                .foregroundColor(AppColors.cream)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let seeAll {
                Button(action: seeAll) {
                    Text("SEE ALL")
                        .font(AppFonts.labelFont(9.5))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("See all: \(title)")
            }
        }
        .frame(minHeight: 30)
    }
}

// MARK: - A painting, cut square

/// A painting cut to a square or a strip about its subject, for the
/// page's tiles, rows and cards
struct PrayersPaintingThumb: View {
    let painting: PrayerBookPainting
    var width: CGFloat
    var height: CGFloat
    var radius: CGFloat = 0

    var body: some View {
        CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .accessibilityHidden(true)
    }
}

// MARK: - A shortcut

/// One of the six shortcuts at the head of the page: a painting at its
/// leading edge and a name, on the card ground
struct PrayersShortcutTile: View {
    let title: String
    let painting: PrayerBookPainting
    var spoken: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                PrayersPaintingThumb(painting: painting, width: 56, height: 56)
                Text(title)
                    .font(AppFonts.bodyFont(14.5))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.trailing, 10)
            .frame(height: 56)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppColors.gold.opacity(0.16), lineWidth: AppLine.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken ?? title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - This hour

/// The order for the hour it is as one wide card: its painting, NOW and
/// the hour's name, the order's title and its line, and PRAY on an
/// outlined disc. The card opens the order's page; the disc prays it.
struct PrayersNowCard: View {
    let order: PrayerOrder
    let now: Date
    let offered: Bool
    let open: () -> Void
    let pray: () -> Void

    var body: some View {
        let title = order.title(on: now)
        let hour = PrayerBook.hourName(of: order, at: now).uppercased()

        HStack(spacing: 0) {
            ZStack {
                PrayersPaintingThumb(painting: PrayerBookPainting.hour(order, on: now), width: 136, height: 180)
                    .id(PrayerBookPainting.hour(order, on: now).resolvedAsset)
                    .transition(.opacity)
            }
            .animation(Motion.crossfade, value: order.id)

            VStack(alignment: .leading, spacing: 4) {
                Text(offered ? "\(hour) · PRAYED" : "NOW · \(hour)")
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold)
                    .contentTransition(.opacity)
                Text(title)
                    .font(AppFonts.titleFont(19))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.opacity)
                Text(PrayerBook.daySummary(of: order, on: now))
                    .font(AppFonts.readingItalicFont(13.5))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.9)
                    .contentTransition(.opacity)

                Spacer(minLength: 6)

                Button(action: pray) {
                    HStack(spacing: 10) {
                        AppIcon("ph-play-fill", size: 11)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 32, height: 32)
                            .overlay(Circle().strokeBorder(AppColors.gold, lineWidth: 1.2))
                            .haloGlow(AppColors.gold, radius: 10, intensity: 0.22)
                        Text(offered ? "PRAY AGAIN" : "PRAY")
                            .font(AppFonts.labelFont(10))
                            .tracking(2)
                            .foregroundColor(AppColors.gold)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel(offered ? "Pray \(title) again" : "Pray \(title)")
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .padding(.top, 14)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 180)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: AppLine.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture(perform: open)
        .animation(Motion.crossfade, value: order.id)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title), \(offered ? "prayed" : "the prayer for this hour")")
        .accessibilityAction(named: "Show its prayers", open)
    }
}

// MARK: - A row with its painting

/// A prayer as a row: a small painting, its name with a line under it,
/// the reader's marks, a caret
struct PrayersPictureRow: View {
    let prayer: BookPrayer
    let painting: PrayerBookPainting
    var note: String?
    var showsRule = true
    let action: () -> Void

    private var store = PrayerBookStore.shared

    init(
        prayer: BookPrayer,
        painting: PrayerBookPainting,
        note: String? = nil,
        showsRule: Bool = true,
        action: @escaping () -> Void
    ) {
        self.prayer = prayer
        self.painting = painting
        self.note = note
        self.showsRule = showsRule
        self.action = action
    }

    var body: some View {
        let kept = store.isKept(prayer.id)

        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 13) {
                    PrayersPaintingThumb(painting: painting, width: 44, height: 44, radius: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(prayer.listTitle)
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(AppColors.cream)
                            .lineLimit(1)
                        if let note {
                            Text(note)
                                .font(AppFonts.readingItalicFont(13.5))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    if kept {
                        RibbonMark(kept: true, width: 7, restLength: 12, keptLength: 16)
                    }
                    AppIcon("ph-caret-right", size: 12)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                }
                .padding(.vertical, 8)

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
        .accessibilityLabel([prayer.listTitle, note, kept ? "saved" : nil].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - A square card

/// A prayer on a shelf that scrolls sideways: its painting cut square,
/// its name and a line beneath
struct PrayersSquareCard: View {
    let title: String
    let note: String
    let painting: PrayerBookPainting
    let action: () -> Void

    static let side: CGFloat = 138

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                PrayersPaintingThumb(painting: painting, width: Self.side, height: Self.side, radius: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                    )
                    .padding(.bottom, 6)
                Text(title)
                    .font(AppFonts.readingFont(16))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(note)
                    .font(AppFonts.readingItalicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(width: Self.side, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(note)")
        .accessibilityAddTraits(.isButton)
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
        if byHeart { parts.append("learned by heart") }
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
                Label("Remove from Saved", systemImage: "minus.circle")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel([prayer.listTitle, topic].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Remove from Saved") {
            withAnimation(Motion.crossfade) { store.toggleRibbon(prayer.id) }
        }
    }
}

// MARK: - Occasions

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
        .accessibilityLabel("\(title), \(order.occasion)\(offered ? ", prayed today" : "")")
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
