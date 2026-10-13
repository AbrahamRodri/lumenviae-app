//
//  PrayerOrderView.swift
//  Lumen Viae
//
//  An order of prayer's own page — Morning Prayers, Before Confession —
//  (the "Saved and Prayer Orders" design, option A, Oct 2026): the
//  order's painting run up under the bar and dissolving into the page,
//  when it is prayed (and that it was prayed today), its name, its Latin
//  small beneath, and one line saying what it is; then its prayers as a
//  quiet numbered list, each a door to its own page, and where the
//  season decides what the order holds, a sentence saying so. At the
//  foot, PRAY, the page's one gold act, beside a round speaker that says
//  how it will be prayed, aloud or in silence, in one line beneath.
//
//  The page once stood as type alone: the order's glyph, an ornament,
//  a paragraph, a kicker counting the prayers, a Latin line under every
//  prayer and a two-line switch row stood between the reader and PRAY.
//

import SwiftUI

struct PrayerOrderView: View {

    let orderID: String

    @Environment(AppRouter.self) private var router

    private let store: PrayerBookStore
    private var voices = NarrationVoiceCatalog.shared

    /// A day to draw the page on, for a snapshot; otherwise the page
    /// reads the clock when it appears
    private let fixedDate: Date?

    @State private var now: Date
    @State private var footHeight: CGFloat = 0

    /// How tall the painting stands at the head of the page, the status
    /// bar's height included: low enough that four prayers or more stand
    /// above the foot on a phone
    private static let heroHeight: CGFloat = 280

    init(orderID: String, store: PrayerBookStore = .shared, date: Date? = nil) {
        self.orderID = orderID
        self.store = store
        self.fixedDate = date
        _now = State(initialValue: date ?? Date())
    }

    private var order: PrayerOrder? { PrayerBook.order(orderID) }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appGradient.ignoresSafeArea()

            if let order {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        hero(order)

                        header(order)
                            .padding(.horizontal, 22)
                            .padding(.top, -48)
                            .devotionalEntrance()

                        list(order)
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                            .devotionalEntrance(delay: 0.06)

                        if let season = seasonNote(order) {
                            Text(season)
                                .font(AppFonts.readingItalicFont(14))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 32)
                                .padding(.top, 18)
                        }

                        // Room to scroll the last prayer clear of the
                        // foot, measured: at the larger text sizes the
                        // foot outgrows a fixed 240 and hid the last row
                        Color.clear.frame(height: max(240, footHeight))
                    }
                }
                .ignoresSafeArea(edges: .top)
                .overlay(alignment: .top) { barVeil }

                foot(order)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footHeight = $0 }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { router.pop() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
            // Prayers is a tab, and the door to it clears the stack it is
            // opened from. Opened from the tab itself, Back already goes
            // there without losing the way back, so the door stands down
            if router.selectedTab != .prayers {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { router.push(.prayerBook) } label: {
                        AppIcon("lv-prayer-book", size: 18)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Prayers")
                }
            }
        }
        .onAppear { now = fixedDate ?? Date() }
    }

    // MARK: - Head

    /// The order's painting, run to the top of the glass and dissolving
    /// into the page beneath the title, never to a flat slab
    private func hero(_ order: PrayerOrder) -> some View {
        let painting = PrayerBookPainting.order(order, on: now)
        return CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
            .frame(maxWidth: .infinity)
            .frame(height: Self.heroHeight)
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.5),
                        .init(color: .black.opacity(0.35), location: 0.8),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .accessibilityHidden(true)
    }

    /// A veil held under the status bar and the bar's Back, over the
    /// painting at rest and over the prayers as they scroll beneath it
    private var barVeil: some View {
        LinearGradient(
            stops: [
                .init(color: AppColors.background.opacity(0.85), location: 0),
                .init(color: AppColors.background.opacity(0.7), location: 0.6),
                .init(color: AppColors.background.opacity(0), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 130)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    private func header(_ order: PrayerOrder) -> some View {
        let offered = store.wasOffered(order.id, on: now)
        let title = order.title(on: now)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(order.occasion.uppercased())
                if offered {
                    Text("·")
                        .foregroundColor(AppColors.gold.opacity(0.5))
                    AppIcon("ph-seal-check-fill", size: 11)
                    Text("PRAYED TODAY")
                }
            }
            .font(AppFonts.labelFont(9.5))
            .tracking(2.4)
            .foregroundColor(AppColors.gold)
            // Lifted off the painting's dissolve, where a light passage
            // of the painting can stand behind it
            .shadow(color: AppColors.background.opacity(0.9), radius: 6)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(offered ? "\(order.occasion). Prayed today" : order.occasion)

            Text(title)
                .font(AppFonts.titleFont(29))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.85)
                .accessibilityAddTraits(.isHeader)

            Text(order.latinTitle)
                .font(AppFonts.readingItalicFont(14.5))
                .foregroundColor(AppColors.cream.opacity(0.55))

            Text(order.detail)
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.82))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - The prayers

    private func list(_ order: PrayerOrder) -> some View {
        let prayers = order.prayers(on: now)
        return VStack(spacing: 0) {
            ForEach(Array(prayers.enumerated()), id: \.element.id) { i, prayer in
                OrderPrayerRow(
                    prayer: prayer,
                    number: i + 1,
                    store: store,
                    showsRule: i < prayers.count - 1
                ) {
                    router.push(.devotionPrayer(id: prayer.id))
                }
            }
        }
    }

    /// Why the order holds what it holds today, where the season decides
    private func seasonNote(_ order: PrayerOrder) -> String? {
        switch order.id {
        case PrayerBook.nightOrderID:
            // The season named as it is written, never lowered: lowered,
            // it once read "trinity Sunday" and "eastertide"
            let antiphon = PrayerBook.antiphon(on: now)
            return "Night Prayers end with this season's song to Mary, \(antiphon.name) (\(antiphon.latinName)), sung at night from \(antiphon.season)."
        case PrayerBook.angelusOrderID where PrayerBook.isEastertide(now):
            return "From Easter to Pentecost, Queen of Heaven (Regina Cæli) is said instead of the Angelus."
        default:
            return nil
        }
    }

    // MARK: - Foot

    private func foot(_ order: PrayerOrder) -> some View {
        let aloud = store.praysAloud
        let voice = voices.chosenVoice.name.lowercased()

        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                // How it will be prayed, as a round speaker beside PRAY:
                // a tap anywhere on the disc changes it, and the line
                // beneath says the choice in words
                Button {
                    withAnimation(Motion.settle) { store.praysAloud.toggle() }
                } label: {
                    AloudGlyph(aloud: aloud)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle().strokeBorder(AppColors.gold.opacity(aloud ? 0.6 : 0.35), lineWidth: 1.2)
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("Pray aloud")
                .accessibilityValue(aloud ? "On, the \(voice) voice" : "Off")

                GoldCTAButton(title: "Pray", glyph: .play) {
                    // The speaker stands beside PRAY, so what it shows is
                    // the reader's answer; the pray-along screen won't ask
                    store.chooseAloud(store.praysAloud)
                    router.push(.prayAlong(.order(order, on: now)))
                }
            }

            Text(aloud ? "Aloud, in the \(voice) voice" : "In silence")
                .font(AppFonts.readingItalicFont(13))
                .foregroundColor(AppColors.textSecondary)
                .contentTransition(.opacity)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 24)
        // Clear of the ground's fade, so the list never reads through
        // the speaker
        .padding(.top, 92)
        .padding(.bottom, 16)
        .background(PrayFootGround())
    }
}

// MARK: - The speaker

/// The speaker on the foot's disc: sounding when the order will be read
/// aloud, struck through and dimmed when it will be prayed in silence
private struct AloudGlyph: View {
    let aloud: Bool

    var body: some View {
        ZStack {
            AppIcon(aloud ? "ph-speaker-high-fill" : "ph-speaker-high", size: 19)
                .foregroundColor(AppColors.gold.opacity(aloud ? 1 : 0.55))
            Capsule()
                .fill(AppColors.gold)
                .frame(width: 1.4, height: 26)
                .rotationEffect(.degrees(-45))
                .opacity(aloud ? 0 : 1)
        }
    }
}

// MARK: - A prayer of the order

/// One prayer of the order: its numeral, its name, the reader's own marks
/// on it, a caret. The Latin each prayer carries stands on its own page.
private struct OrderPrayerRow: View {
    let prayer: BookPrayer
    let number: Int
    let store: PrayerBookStore
    let showsRule: Bool
    let action: () -> Void

    var body: some View {
        let byHeart = store.isByHeart(prayer.id)
        let kept = store.isKept(prayer.id)

        Button(action: action) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 14) {
                    // The numeral stands on the name's first line, as a
                    // contents page sets it
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text(LiturgicalCalendarFormat.roman(number))
                            .font(AppFonts.titleFont(13))
                            .foregroundColor(AppColors.gold.opacity(0.85))
                            .frame(width: 30, alignment: .leading)

                        Text(prayer.title)
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 10) {
                        if byHeart {
                            ByHeartMark()
                        }
                        if kept {
                            RibbonMark(kept: true, width: 7, restLength: 12, keptLength: 16)
                        }
                        AppIcon("ph-caret-right", size: 11)
                            .foregroundColor(AppColors.gold.opacity(0.5))
                    }
                }
                .padding(.vertical, 14)
                .frame(minHeight: 52)

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
        .accessibilityLabel(
            ["\(number), \(prayer.title)", byHeart ? "learned by heart" : nil, kept ? "saved" : nil]
                .compactMap { $0 }
                .joined(separator: ", ")
        )
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack {
        PrayerOrderView(orderID: "before_confession")
            .environment(AppRouter())
    }
}
