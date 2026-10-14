//
//  PrayersComponents.swift
//  Lumen Viae
//
//  The Prayers page's pieces, drawn as the Chant page draws its own (the
//  "Prayers Tab Redesign", option A, Oct 2026): a shelf's heading with
//  SEE ALL, a painting cut square, a shortcut tile, the card for this
//  hour, a row with its painting, and a square card for a shelf that
//  scrolls sideways.
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
        PaintingThumbnail(painting: painting, size: CGSize(width: width, height: height))
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
/// outlined disc. The card is one door, opening the order's page; PRAY
/// stands over its foot as a control of its own, in room the door keeps
/// for it, as on the search's best card. The card opened on a tap
/// gesture once, which VoiceOver could not see as a button.
struct PrayersNowCard: View {
    let order: PrayerOrder
    let now: Date
    let offered: Bool
    let open: () -> Void
    let pray: () -> Void

    private static let paintingWidth: CGFloat = 136

    var body: some View {
        let title = order.title(on: now)

        ZStack(alignment: .bottomLeading) {
            Button(action: open) { face(title: title) }
                // PRAY lies over the face from outside it, so the face
                // dims when pressed but does not shrink out from under it
                .buttonStyle(SacredCardButtonStyle(scales: false))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(title), \(offered ? "prayed" : "the prayer for this hour"). \(PrayerBook.daySummary(of: order, on: now))"
                )
                .accessibilityHint("Shows its prayers")
                .accessibilityAddTraits(.isButton)

            prayButton(title: title)
                .padding(.leading, Self.paintingWidth + 16)
                .padding(.bottom, 6)
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: AppLine.hairline)
                .allowsHitTesting(false)
        )
        .animation(Motion.crossfade, value: order.id)
    }

    private func face(title: String) -> some View {
        let hour = PrayerBook.hourName(of: order, at: now).uppercased()
        let painting = PrayerBookPainting.hour(order, on: now)

        return HStack(spacing: 0) {
            // The painting runs the card's height, which is the words'
            // where they need more than the card's 180 points
            GeometryReader { proxy in
                ZStack {
                    PrayersPaintingThumb(
                        painting: painting,
                        width: Self.paintingWidth,
                        height: max(proxy.size.height, 180)
                    )
                    .id(painting.resolvedAsset)
                    .transition(.opacity)
                }
                .animation(Motion.crossfade, value: order.id)
            }
            .frame(width: Self.paintingWidth)

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

                // PRAY's room: it stands over this, outside the door
                Color.clear.frame(height: 44)
            }
            // At least the card's 180 points with its padding, and taller
            // where the words need it — a fixed height cut them short
            .frame(minHeight: 160, alignment: .top)
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .padding(.top, 14)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.cardBackground)
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }

    private func prayButton(title: String) -> some View {
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
