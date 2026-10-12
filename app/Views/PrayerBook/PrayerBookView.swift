//
//  PrayerBookView.swift
//  Lumen Viae
//
//  Prayers: the Prayer Book as a tab of its own. A home page read top to
//  bottom, drawn as the Chant page is (the "Prayers Tab Redesign",
//  option A, Oct 2026), with what people come for first:
//
//    HEADER          PRAYERS over how many the book holds, and the glass
//                    that turns the page into a search
//    SHORTCUTS       six ways in, two by three: the day's three orders,
//                    Saved, Before Mass and Before Confession
//    NOW             the order for the hour it is, as one wide card
//    EVERYDAY        the first prayers, a row each, SEE ALL to the chapter
//    MARY            her best-known prayers on a shelf, the season's song
//                    to Mary first
//    OCCASIONS       every order kept for an occasion
//    ALL TOPICS      the book's twelve chapters
//
//  Typing searches every prayer by name, Latin name and words, and names
//  a topic or an order of prayer when the words name one.
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
    @State private var query = ""
    @State private var searchOpen = false
    @FocusState private var searching: Bool

    init(isTabRoot: Bool = false) {
        self.isTabRoot = isTabRoot
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !trimmedQuery.isEmpty }

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
                        Button(action: { router.pop() }) {
                            HStack(spacing: 6) {
                                AppIcon("ph-caret-left", size: 14)
                                Text("Back")
                                    .font(AppFonts.bodyFont(16))
                            }
                            .foregroundColor(AppColors.gold)
                        }
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

                    // The home page and the search take turns in one
                    // slot, crossfading over each other
                    ZStack(alignment: .top) {
                        if searchOpen {
                            results
                                .padding(.horizontal, 18)
                                .transition(.opacity)
                        } else {
                            home
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .animation(Motion.crossfade, value: searchOpen)
                    .padding(.top, 22)
                    .devotionalEntrance(delay: 0.06)
                }
                // Clear of the tab bar and its fade at the root
                .padding(.bottom, isTabRoot ? 130 : 56)
            }
            .scrollDismissesKeyboard(.interactively)
            // At the root the page dissolves under the status bar, as the
            // Chapel's does; pushed, under the Back, and held clear of it
            .topChromeFade(height: isTabRoot ? 32 : 48)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = Date() }
        }
        .onAppear { now = Date() }
        // Said once the reader pauses, not at every letter
        .task(id: trimmedQuery) {
            guard !trimmedQuery.isEmpty else { return }
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            announceResults(for: trimmedQuery)
        }
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
    /// trailing edge; searching, the field and CANCEL in its place
    @ViewBuilder
    private var head: some View {
        ZStack {
            if searchOpen {
                HStack(spacing: 12) {
                    searchField
                    Button {
                        closeSearch()
                    } label: {
                        Text("CANCEL")
                            .font(AppFonts.labelFont(10))
                            .tracking(2)
                            .foregroundColor(AppColors.gold)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                }
                .transition(.opacity)
            } else {
                ZStack {
                    VStack(spacing: 1) {
                        Text("Prayers")
                            .font(AppFonts.titleFont(24))
                            .foregroundColor(AppColors.cream)
                        Text("\(PrayerBook.prayerCount) prayers")
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)

                    HStack {
                        Spacer()
                        Button {
                            withAnimation(Motion.crossfade) { searchOpen = true }
                            searching = true
                        } label: {
                            AppIcon("ph-magnifying-glass", size: 18)
                                .foregroundColor(AppColors.gold)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(AppColors.cardBackground))
                                .contentShape(Circle())
                        }
                        .buttonStyle(QuietGlyphButtonStyle())
                        .accessibilityLabel("Search prayers")
                        .accessibilityHint("Find a prayer by its name or its words")
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(minHeight: 52)
        .animation(Motion.crossfade, value: searchOpen)
    }

    private func closeSearch() {
        query = ""
        searching = false
        withAnimation(Motion.crossfade) { searchOpen = false }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            AppIcon("ph-magnifying-glass", size: 15)
                .foregroundColor(AppColors.gold.opacity(0.75))
            TextField(
                "",
                text: $query,
                prompt: Text("Hail Mary, St Joseph…")
                    .foregroundColor(AppColors.textSecondary)
            )
            .font(AppFonts.readingFont(16))
            .foregroundColor(AppColors.cream)
            .tint(AppColors.gold)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .focused($searching)
            .accessibilityLabel("Search prayers")

            if !query.isEmpty {
                Button { query = "" } label: {
                    AppIcon("ph-x-circle", size: 15)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // The glyph keeps its place; only the target grows
                .padding(.trailing, -7)
                .accessibilityLabel("Clear the search")
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 46)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColors.gold.opacity(searching ? 0.6 : 0.25), lineWidth: AppLine.hairline)
        )
        .animation(Motion.crossfade, value: searching)
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

            everyday
                .padding(.horizontal, 18)

            prayersToMary

            occasions
                .padding(.horizontal, 18)

            allTopics
                .padding(.horizontal, 18)
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

    // MARK: Everyday prayers

    private var everyday: some View {
        let prayers = Self.everydayIDs.compactMap { PrayerBook.prayer($0) }

        return VStack(alignment: .leading, spacing: 6) {
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

    // MARK: Prayers to Mary

    /// The season's song to Mary first, then her best-known prayers, on a
    /// shelf that scrolls sideways
    private var prayersToMary: some View {
        let antiphon = PrayerBook.antiphon(on: now)
        let known = PrayerBook.bestKnownMarianIDs
            .filter { $0 != antiphon.prayerID && !Self.everydayIDs.contains($0) }
            .compactMap { PrayerBook.prayer($0) }

        return VStack(alignment: .leading, spacing: 12) {
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
                            note: PrayerBook.englishNames[prayer.id] ?? Self.marianNotes[prayer.id] ?? PrayerBook.ourLady.title,
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

    // MARK: Occasions

    /// Every order kept for an occasion, in the order of the places it is
    /// prayed — at Mass, at Confession, at home, in need
    private var occasions: some View {
        let orders = PrayerOccasionPlace.allCases.flatMap { PrayerBook.ordersKept(at: $0) }

        return VStack(alignment: .leading, spacing: 6) {
            PrayersShelfHeading(title: "For an Occasion")
            VStack(spacing: 0) {
                ForEach(Array(orders.enumerated()), id: \.element.id) { i, order in
                    PrayersOccasionRow(order: order, now: now, showsRule: i < orders.count - 1) {
                        router.push(.prayerOrder(id: order.id))
                    }
                }
            }
        }
    }

    // MARK: All topics

    private var allTopics: some View {
        VStack(alignment: .leading, spacing: 6) {
            PrayersShelfHeading(title: "All Topics")
            VStack(spacing: 0) {
                ForEach(Array(PrayerBook.chapters.enumerated()), id: \.element.id) { i, chapter in
                    PrayersLedgerRow(
                        title: chapter.title,
                        note: PrayerBook.chapterNotes[chapter.id],
                        count: chapter.prayerIDs.count,
                        showsRule: i < PrayerBook.chapters.count - 1
                    ) {
                        router.push(.prayerBookChapter(id: chapter.id))
                    }
                }
            }
        }
    }

    // MARK: - Search

    @ViewBuilder
    private var results: some View {
        let hits = PrayerBook.search(trimmedQuery)
        let topics = Array(PrayerBook.topics(matching: trimmedQuery).prefix(2))
        let orders = Array(PrayerBook.searchOrders(trimmedQuery).prefix(3))
        let seasonalID = PrayerBook.antiphon(on: now).prayerID

        VStack(alignment: .leading, spacing: 14) {
            if !isSearching {
                Text("Type a prayer's name or a word from it: \"Memorare\", \"Joseph\", \"mercy\".")
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if hits.isEmpty && topics.isEmpty && orders.isEmpty {
                Text("No prayer by that name. Try a word from it — \"mercy\", \"Joseph\", \"light\".")
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                if !hits.isEmpty {
                    Text(Self.matchCount(hits.count))
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(AppColors.textSecondary)
                        .contentTransition(.numericText())
                        .animation(Motion.crossfade, value: hits.count)
                }

                ForEach(topics) { chapter in
                    PrayersTopicCard(chapter: chapter) {
                        router.push(.prayerBookChapter(id: chapter.id))
                    }
                }

                // An order of prayer the words name — "blessed sacrament"
                // finds Visiting Jesus in Church — as a card of its own,
                // since it is prayed as one
                ForEach(orders) { order in
                    PrayersOrderCard(order: order, now: now) {
                        router.push(.prayerOrder(id: order.id))
                    }
                }

                VStack(spacing: 0) {
                    ForEach(Array(hits.enumerated()), id: \.element.id) { i, prayer in
                        PrayersLedgerRow(
                            title: prayer.listTitle,
                            note: chapterNote(for: prayer, seasonalID: seasonalID),
                            prayerID: prayer.id,
                            showsRule: i < hits.count - 1
                        ) {
                            router.push(.devotionPrayer(id: prayer.id))
                        }
                    }
                }
            }
        }
    }

    /// "7 prayers match"
    private static func matchCount(_ count: Int) -> String {
        count == 1 ? "1 prayer matches" : "\(count) prayers match"
    }

    /// Says what the search found as the results change, since VoiceOver
    /// stays in the field and would otherwise hear nothing of them: the
    /// topic and the orders of prayer as well as the prayers, as the page
    /// sets them, so "visiting" is never "No prayer by that name" over
    /// the card it found
    private func announceResults(for query: String) {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return }
        let found = PrayerBook.search(needle).count
        let topics = PrayerBook.topics(matching: needle).prefix(2).map { $0.topic }
        let orders = PrayerBook.searchOrders(needle).prefix(3).map { $0.title(on: now) }

        var parts = topics + orders
        if found > 0 { parts.append(Self.matchCount(found)) }
        let words = parts.isEmpty ? "No prayer by that name" : parts.joined(separator: ", ")
        AccessibilityNotification.Announcement(words).post()
    }

    /// The topic a found prayer belongs to — "Mary · this season"
    private func chapterNote(for prayer: BookPrayer, seasonalID: String) -> String? {
        guard let chapter = PrayerBook.homeChapter(of: prayer.id) else { return nil }
        return prayer.id == seasonalID ? "\(chapter.title) · this season" : chapter.title
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
