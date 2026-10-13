//
//  PrayerBookView.swift
//  Lumen Viae
//
//  Prayers: the Prayer Book as a tab of its own. A home page read top to
//  bottom, drawn as the Chant page is (the "Prayers Tab Redesign",
//  option A, Oct 2026), with what people come for first:
//
//    HEADER          PRAYERS over how many the book holds, and the glass
//                    that opens the app's one search, prayers first
//    SHORTCUTS       six ways in, two by three: the day's three orders,
//                    Saved, Before Mass and Before Confession
//    NOW             the order for the hour it is, as one wide card
//    EVERYDAY        the first prayers, a row each, SEE ALL to the chapter
//    MARY            her best-known prayers on a shelf, the season's song
//                    to Mary first
//    ALL TOPICS      the book's topics, in the order of Blessed Be God,
//                    a sideways shelf of paintings for each of its parts
//
//  The glass opens the search the whole app shares (`.search(from:
//  .prayers)`, Explore's), where a prayer, a topic or an order of prayer
//  leads and chants, mysteries and readings follow. The page once
//  searched itself, in place of its own home, and the Chant page did the
//  same in another look.
//
//  It opened on three parts chosen on a bar (Today, Occasions, All
//  Prayers), Today a 300-point painting for the hour: the prayers people
//  look up most stood two taps away, and the bar said little of what was
//  behind it. Every door to the book comes here
//  (`AppRouter.push(.prayerBook)` turns to the tab).
//

import SwiftUI

// MARK: - PrayerBookView

struct PrayerBookView: View {

    /// The root of the Prayers tab, under the bar, or a page pushed from
    /// some other page, with a Back of its own. Every door turns to the
    /// tab, so the pushed page is only the destination table's fallback.
    let isTabRoot: Bool

    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    private var store = PrayerBookStore.shared

    @State private var now = Date()

    init(isTabRoot: Bool = false) {
        self.isTabRoot = isTabRoot
    }

    /// The first prayers, a row each under Everyday Prayers
    static let everydayIDs = ["our_father", "hail_mary", "glory_be", "apostles_creed"]

    /// A line under a prayer to Mary on the shelf, where the book gives
    /// none: the words it is known by
    static let marianNotes = ["litany_loreto": "Holy Mary, pray for us"]

    /// The orders kept for an occasion with a shortcut of their own
    static let shortcutOccasionIDs = ["before_mass", "before_confession"]

    // MARK: Body

    @ViewBuilder
    var body: some View {
        if isTabRoot {
            page
        } else {
            page
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        GoldBackButton()
                    }
                }
        }
    }

    private var page: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    head
                        .padding(.horizontal, 18)
                        .padding(.top, 4)
                        .devotionalEntrance()

                    home
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 22)
                    .devotionalEntrance(delay: 0.06)
                }
                // Clear of the tab bar and its fade at the root
                .padding(.bottom, isTabRoot ? 130 : 56)
            }
            // At the root the page dissolves under the status bar, as the
            // Chapel's does; pushed, under the Back, and held clear of it
            .topChromeFade(height: isTabRoot ? 32 : 48)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = Date() }
        }
        .onAppear { now = Date() }
        // Left open across one of the book's hours — four, eleven, three,
        // eight — the page turns with it, on the timeline home's row and
        // the Chapel's tile keep
        .background {
            TimelineView(PrayerBookHourSchedule()) { context in
                Color.clear.onChange(of: context.date) { _, date in
                    withAnimation(Motion.crossfade) { now = date }
                }
            }
        }
    }

    // MARK: - Head

    /// PRAYERS over the book's count, centred, with the glass at the
    /// trailing edge: the head the Chant page wears too
    private var head: some View {
        PageSearchHead(
            title: "Prayers",
            count: "\(PrayerBook.prayerCount) prayers",
            origin: .prayers,
            hint: "Find a prayer, a chant or a mystery, prayers first"
        )
    }

    // MARK: - Home

    private var home: some View {
        VStack(alignment: .leading, spacing: 36) {
            shortcuts
                .padding(.horizontal, 18)

            VStack(alignment: .leading, spacing: 12) {
                PrayersShelfHeading(title: "Now")
                nowCard
            }
            .padding(.horizontal, 18)

            PrayersEverydayShelf()
                .padding(.horizontal, 18)

            // Its own view, handed the day: the season's song to Mary
            // changes with the day, not the hour, so the hour's turn
            // leaves the shelf alone
            PrayersToMaryShelf(day: Calendar.current.startOfDay(for: now))

            PrayersAllTopics()
        }
    }

    // MARK: Shortcuts

    private var shortcuts: some View {
        let day = PrayerBook.dayOrders
        let occasions = Self.shortcutOccasionIDs.compactMap { PrayerBook.order($0) }
        let kept = store.keptPrayers.count

        return LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            ForEach(day) { order in
                orderTile(order)
            }
            PrayersShortcutTile(
                title: "Saved",
                painting: .saved,
                spoken: kept == 0 ? "Saved prayers" : "Saved prayers, \(kept)"
            ) {
                router.push(.prayerBookSaved)
            }
            ForEach(occasions) { order in
                orderTile(order)
            }
        }
    }

    private func orderTile(_ order: PrayerOrder) -> some View {
        PrayersShortcutTile(
            title: order.title(on: now),
            painting: .order(order, on: now)
        ) {
            router.push(.prayerOrder(id: order.id))
        }
    }

    // MARK: Now

    /// Whether `order` is offered for the hour it is now. The Angelus is
    /// the bell's, not the day's: a noon Angelus leaves the evening's
    /// still to pray (`PrayerBook.isOfferedNow`).
    private func isOfferedNow(_ order: PrayerOrder) -> Bool {
        PrayerBook.isOfferedNow(
            order,
            at: now,
            offeredToday: store.wasOffered(order.id, on: now),
            lastOffered: store.lastOffered(order.id)
        )
    }

    private var nowCard: some View {
        let order = PrayerBook.dayOrder(at: now)
        return PrayersNowCard(
            order: order,
            now: now,
            offered: isOfferedNow(order),
            open: { router.push(.prayerOrder(id: order.id)) },
            pray: { router.push(.prayAlong(.order(order, on: now))) }
        )
    }

    /// "11 prayers"
    static func prayerCount(_ count: Int) -> String {
        count == 1 ? "1 prayer" : "\(count) prayers"
    }
}

// MARK: - Everyday prayers

/// The first prayers, a row each, SEE ALL to their topic
private struct PrayersEverydayShelf: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        let prayers = PrayerBookView.everydayIDs.compactMap { PrayerBook.prayer($0) }

        VStack(alignment: .leading, spacing: 6) {
            PrayersShelfHeading(title: "Everyday Prayers") {
                router.push(.prayerBookChapter(id: "first"))
            }
            VStack(spacing: 0) {
                ForEach(Array(prayers.enumerated()), id: \.element.id) { i, prayer in
                    PrayersPictureRow(
                        prayer: prayer,
                        painting: .prayer(prayer.id),
                        note: PrayerBook.englishNames[prayer.id],
                        showsRule: i < prayers.count - 1
                    ) {
                        router.push(.devotionPrayer(id: prayer.id))
                    }
                }
            }
        }
    }
}

// MARK: - Prayers to Mary

/// The season's song to Mary first, then her best-known prayers, on a
/// shelf that scrolls sideways. Drawn for a day, so it is worked out
/// again only when the day changes.
private struct PrayersToMaryShelf: View {
    let day: Date

    @Environment(AppRouter.self) private var router

    var body: some View {
        let antiphon = PrayerBook.antiphon(on: day)
        let known = PrayerBook.bestKnownMarianIDs
            .filter { $0 != antiphon.prayerID && !PrayerBookView.everydayIDs.contains($0) }
            .compactMap { PrayerBook.prayer($0) }

        VStack(alignment: .leading, spacing: 12) {
            PrayersShelfHeading(title: "Prayers to Mary") {
                router.push(.prayerBookChapter(id: PrayerBook.ourLady.id))
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    if let seasonal = PrayerBook.prayer(antiphon.prayerID) {
                        PrayersSquareCard(
                            title: seasonal.listTitle,
                            note: "This season's song to Mary",
                            painting: .antiphon(antiphon)
                        ) {
                            router.push(.devotionPrayer(id: seasonal.id))
                        }
                    }
                    ForEach(known) { prayer in
                        PrayersSquareCard(
                            title: prayer.listTitle,
                            note: PrayerBook.englishNames[prayer.id]
                                ?? PrayerBookView.marianNotes[prayer.id] ?? PrayerBook.ourLady.title,
                            painting: .prayer(prayer.id)
                        ) {
                            router.push(.devotionPrayer(id: prayer.id))
                        }
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }
}

// MARK: - All topics

/// The topics under the part of the book each stands in, every part a
/// shelf of paintings that scrolls sideways, as Prayers to Mary does.
/// The orders once listed here as For an Occasion stand at the head of
/// their topics' pages. Nothing here changes with the hour or the day.
private struct PrayersAllTopics: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PrayersShelfHeading(title: "All Topics")
                .padding(.horizontal, 18)

            VStack(alignment: .leading, spacing: 26) {
                ForEach(PrayerBookPart.allCases) { part in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(part.title)
                            .font(AppFonts.labelFont(9.5))
                            .tracking(2.4)
                            .textCase(.uppercase)
                            .foregroundColor(AppColors.gold)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.horizontal, 18)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 14) {
                                ForEach(part.chapters) { chapter in
                                    PrayersSquareCard(
                                        title: chapter.title,
                                        note: PrayerBookView.prayerCount(chapter.prayerIDs.count),
                                        painting: .topic(chapter)
                                    ) {
                                        router.push(.prayerBookChapter(id: chapter.id))
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrayerBookView(isTabRoot: true)
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
