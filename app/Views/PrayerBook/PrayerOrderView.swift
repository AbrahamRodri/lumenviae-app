//
//  PrayerOrderView.swift
//  Lumen Viae
//
//  An order of prayer's own page — Morning Prayers, Before Confession —
//  (the "Saved and Prayer Orders" design, option A, Oct 2026): the
//  order's painting run up under the bar and dissolving into the page,
//  when it is prayed (and that it was prayed today) and its name; then
//  its prayers as a quiet numbered list, each a door to its own page
//  (the "Holy Cards" pick's list), and in Eastertide, a sentence saying
//  the Angelus gives way to Queen of Heaven. At the
//  foot, PRAY, the page's one gold act, at the inline size, so the list
//  keeps the room. Aloud or in silence is the pray-along's own choice:
//  its head says it in a word, and it asks before its first sound.
//
//  The foot once carried a round speaker beside PRAY and a line saying
//  "Aloud, in the male voice": two controls for one choice the
//  pray-along already offers, taking the list's room.
//  The page once stood as type alone: the order's glyph, an ornament,
//  a paragraph, a kicker counting the prayers, a Latin line under every
//  prayer and a two-line switch row stood between the reader and PRAY.
//  Its Latin name under the title, and a sentence on the season's song
//  to Mary under Night Prayers, went in the small-print trim (Oct 2026).
//

import SwiftUI

struct PrayerOrderView: View {

    let orderID: String

    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    private let store: PrayerBookStore

    /// A day to draw the page on, for a snapshot; otherwise the page
    /// reads the clock when it appears
    private let fixedDate: Date?

    @State private var now: Date
    @State private var footHeight: CGFloat = 0

    /// Whether the page is scrolled far enough that its words travel
    /// under the bar. Measured as a flag, so a scroll redraws the page
    /// only when it flips, never frame by frame.
    @State private var wordsUnderBar = false

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
                            .onGeometryChange(for: Bool.self) { proxy in
                                -proxy.frame(in: .global).minY > 70
                            } action: { under in
                                withAnimation(Motion.crossfade) { wordsUnderBar = under }
                            }

                        header(order)
                            .padding(.horizontal, 20)
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
                        // foot outgrows a fixed height and hid the last row
                        Color.clear.frame(height: max(160, footHeight))
                    }
                }
                .ignoresSafeArea(edges: .top)
                .overlay(alignment: .top) { barVeil }

                foot(order)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footHeight = $0 }
            } else {
                missing
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                GoldBackButton()
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
        // Left open across the day's turn or brought back to the front,
        // the page reads the clock again: PRAYED TODAY, the season's name
        // and its note are the day's, as on the Prayers page
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, fixedDate == nil { now = Date() }
        }
        .background {
            if fixedDate == nil {
                TimelineView(PrayerBookHourSchedule()) { context in
                    Color.clear.onChange(of: context.date) { _, date in
                        withAnimation(Motion.crossfade) { now = date }
                    }
                }
            }
        }
    }

    /// An order the book does not hold: said, as the prayer's page says
    /// it, under the bar's Back
    private var missing: some View {
        Text("This order of prayer could not be found.")
            .font(AppFonts.readingItalicFont(16))
            .foregroundColor(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .frame(maxHeight: .infinity)
    }

    // MARK: - Head

    /// The order's painting, run to the top of the glass and dissolving
    /// into the page beneath the title, never to a flat slab
    private func hero(_ order: PrayerOrder) -> some View {
        let painting = Self.painting(of: order, on: now)
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

    /// The order's painting. Night Prayers' Magdalen is hung from the top
    /// of the canvas, so her face and the flame stand clear of the bar,
    /// where the Prayers page's shortcut cuts her at the shoulders.
    static func painting(of order: PrayerOrder, on date: Date) -> PrayerBookPainting {
        let painting = PrayerBookPainting.order(order, on: date)
        guard order.id == PrayerBook.nightOrderID else { return painting }
        return PrayerBookPainting(
            asset: painting.asset,
            fallback: painting.fallback,
            focal: UnitPoint(x: 0.5, y: 0),
            caption: painting.caption
        )
    }

    /// A veil under the status bar and the bar's Back: light over the
    /// painting at rest, and near opaque down past the bar once the title
    /// travels under it, so no word of the page stands inside the Back
    private var barVeil: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [AppColors.background.opacity(0.55), AppColors.background.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 110)

            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0.99), location: 0),
                    .init(color: AppColors.background.opacity(0.99), location: 0.8),
                    .init(color: AppColors.background.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 172)
            .opacity(wordsUnderBar ? 1 : 0)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    private func header(_ order: PrayerOrder) -> some View {
        let offered = store.wasOffered(order.id, on: now)
        let title = order.title(on: now)

        return VStack(alignment: .leading, spacing: 6) {
            // When it is said, and that it was prayed today beside it;
            // where the line has no room, PRAYED TODAY takes a line of its
            // own rather than be cut, since it is the news
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    Text(order.occasion.uppercased())
                    if offered {
                        Text("·")
                            .foregroundColor(AppColors.gold.opacity(0.5))
                        prayedToday
                    }
                }
                .fixedSize()

                VStack(alignment: .leading, spacing: 4) {
                    Text(order.occasion.uppercased())
                        .fixedSize(horizontal: false, vertical: true)
                    if offered {
                        prayedToday
                    }
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var prayedToday: some View {
        HStack(spacing: 6) {
            AppIcon("ph-seal-check-fill", size: 11)
            Text("PRAYED TODAY")
        }
        .fixedSize()
    }

    // MARK: - The prayers

    private func list(_ order: PrayerOrder) -> some View {
        // A prayer tapped begins the order there, so the order goes on
        // from it as PRAY's does from the first
        let prayers = order.prayers(on: now)
        return VStack(spacing: 0) {
            ForEach(Array(prayers.enumerated()), id: \.offset) { i, prayer in
                OrderPrayerRow(
                    prayer: prayer,
                    number: i + 1,
                    store: store,
                    showsRule: i < prayers.count - 1
                ) {
                    router.push(.prayAlong(.order(order, on: now, startingAt: i)))
                }
            }
        }
    }

    /// Why the order holds what it holds today, where the season decides
    private func seasonNote(_ order: PrayerOrder) -> String? {
        switch order.id {
        case PrayerBook.angelusOrderID where PrayerBook.isEastertide(now):
            return "Said in place of the Angelus until Pentecost."
        default:
            return nil
        }
    }

    // MARK: - Foot

    private func foot(_ order: PrayerOrder) -> some View {
        GoldCTAButton(title: "Pray", prominence: .inline, glyph: .play) {
            router.push(.prayAlong(.order(order, on: now)))
        }
        .padding(.horizontal, 24)
        // Clear of the ground's fade, so the list never reads through
        // the button
        .padding(.top, 72)
        .padding(.bottom, 16)
        .background(PrayFootGround())
    }
}

// MARK: - A prayer of the order

/// One prayer of the order: its number, its name, the reader's own marks
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
                        Text("\(number)")
                            .font(AppFonts.titleFont(15))
                            .foregroundColor(AppColors.gold.opacity(0.85))
                            .frame(width: 22, alignment: .leading)

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
