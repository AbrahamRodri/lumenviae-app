//
//  PrayerBookView.swift
//  Lumen Viae
//
//  Prayers: the Prayer Book as a tab of its own, in the Journal's old
//  place in the bar. One plain word for a title, the search field at the
//  head of the page rather than at its foot — finding one prayer by name
//  is the book's commonest errand — and the book in three parts beneath
//  it:
//
//  - Today: the prayer for the hour it is, over its painting, with the
//    day's three hours on a strip at the card's foot and the page's one
//    gold act; then Our Lady's prayers, led by the antiphon the season
//    sings; then the prayers the reader has saved with a ribbon.
//  - Occasions: the reader picks where they are — at Mass, Confession,
//    at home, in need — and the orders kept there stand beneath.
//  - All Prayers: every chapter of the book by topic, in plain words.
//
//  Typing searches every prayer by name, Latin name and words, and
//  names a chapter as a topic when the words name one.
//
//  It once stood as a row inside other pages — home's ledger, Explore,
//  the Chapel's tile — and opened as a pushed title page with an
//  ENCHIRIDION masthead and seven sections in five kinds of container,
//  the search at the very foot. Every one of those doors now comes here
//  (`AppRouter.push(.prayerBook)` turns to the tab).
//

import SwiftUI

// MARK: - PrayersSection

/// The three parts of the Prayers page
enum PrayersSection: String, CaseIterable, Identifiable {
    case today
    case occasions
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:     return "Today"
        case .occasions: return "Occasions"
        case .all:       return "All Prayers"
        }
    }
}

// MARK: - PrayerBookView

struct PrayerBookView: View {

    /// The root of the Prayers tab, under the bar, or a page pushed from
    /// some other page, with a Back of its own. Every door turns to the
    /// tab, so the pushed page is only the destination table's fallback.
    let isTabRoot: Bool

    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize

    private var store = PrayerBookStore.shared

    @State private var now = Date()
    @State private var query = ""
    @FocusState private var searching: Bool
    @State private var section: PrayersSection = .today

    /// One of the day's other hours, chosen on the Pray Now card's strip
    /// to see it and pray it; nil shows the hour it is
    @State private var chosenHourID: String?

    /// Where the reader last said they were, on Occasions. Kept, since
    /// someone who opens it in the pew opens it there every Sunday.
    @AppStorage("prayers.occasionPlace") private var placeRaw = PrayerOccasionPlace.mass.rawValue

    init(isTabRoot: Bool = false) {
        self.isTabRoot = isTabRoot
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !trimmedQuery.isEmpty }

    private var place: PrayerOccasionPlace {
        PrayerOccasionPlace(rawValue: placeRaw) ?? .mass
    }

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
                        .padding(.top, 4)
                        .devotionalEntrance()

                    // The three parts and the search's results take turns
                    // in one slot, crossfading over each other
                    ZStack(alignment: .top) {
                        if isSearching {
                            results
                                .transition(.opacity)
                        } else {
                            switch section {
                            case .today:
                                today
                                    .transition(.opacity)
                            case .occasions:
                                occasions
                                    .transition(.opacity)
                            case .all:
                                allPrayers
                                    .transition(.opacity)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .animation(Motion.crossfade, value: isSearching)
                    .animation(Motion.crossfade, value: section)
                    .padding(.top, 28)
                    .devotionalEntrance(delay: 0.06)
                }
                .padding(.horizontal, 20)
                // Clear of the tab bar and its fade at the root
                .padding(.bottom, isTabRoot ? 130 : 56)
            }
            .scrollDismissesKeyboard(.interactively)
            // At the root the page dissolves under the status bar, as the
            // Chapel's does; pushed, under the Back, and held clear of it
            .topChromeFade(height: isTabRoot ? 32 : 48)
        }
        .onChange(of: scenePhase) { _, phase in
            // Back in the foreground, the card shows the hour it is now,
            // not one chosen on the strip some hours ago
            if phase == .active {
                now = Date()
                chosenHourID = nil
            }
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
                    withAnimation(Motion.crossfade) {
                        now = date
                        chosenHourID = nil
                    }
                }
            }
        }
    }

    // MARK: - Head

    private var head: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Prayers")
                .font(AppFonts.titleFont(30))
                .foregroundColor(AppColors.cream)
                .accessibilityAddTraits(.isHeader)

            searchField

            PrayersSectionBar(
                selection: isSearching ? nil : section
            ) { chosen in
                // A part chosen mid-search puts the search away: the
                // results stand where the parts do, so the two never
                // show at once
                if isSearching {
                    query = ""
                    searching = false
                }
                section = chosen
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            AppIcon("ph-magnifying-glass", size: 15)
                .foregroundColor(AppColors.gold.opacity(0.75))
            TextField(
                "",
                text: $query,
                prompt: Text("Search prayers — Hail Mary, St Joseph…")
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
                .strokeBorder(
                    AppColors.gold.opacity(searching || isSearching ? 0.6 : 0.25),
                    lineWidth: AppLine.hairline
                )
        )
        .animation(Motion.crossfade, value: searching)
    }

    // MARK: - Today

    private var today: some View {
        VStack(alignment: .leading, spacing: 44) {
            prayNow
            prayersToMary
            saved
        }
    }

    /// The order for the hour it is, or for the hour chosen on the strip
    private var shownOrder: PrayerOrder {
        chosenHourID.flatMap { PrayerBook.order($0) } ?? PrayerBook.dayOrder(at: now)
    }

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

    private var prayNow: some View {
        let order = shownOrder
        let offered = isOfferedNow(order)
        let painting = PrayerBookPainting.hour(order, on: now)

        return VStack(alignment: .leading, spacing: 16) {
            PrayersSectionTitle(title: "This Time of Day", note: "Prayers for this hour. Tap a time below to see another.")

            VStack(spacing: 0) {
                Button {
                    router.push(.prayerOrder(id: order.id))
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        // One painting crossfades over the other in its
                        // own slot as the hour changes; swapped in place,
                        // it cut while the words above it faded
                        ZStack {
                            PrayerBookPaintingGround(painting: painting)
                                .id(painting.resolvedAsset)
                                .transition(.opacity)
                        }
                        .animation(Motion.crossfade, value: painting.resolvedAsset)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(order.title(on: now))
                                .font(AppFonts.titleFont(27))
                                .foregroundColor(AppColors.cream)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .contentTransition(.opacity)

                            Text(PrayerBook.daySummary(of: order, on: now))
                                .font(AppFonts.readingItalicFont(15))
                                .foregroundColor(AppColors.cream.opacity(0.82))
                                .fixedSize(horizontal: false, vertical: true)
                                .contentTransition(.opacity)
                        }
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
                    .contentShape(Rectangle())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Shows its prayers")

                PrayerHourStations(now: now, shownID: order.id) { chosen in
                    let current = PrayerBook.dayOrder(at: now).id
                    chosenHourID = chosen.id == current ? nil : chosen.id
                }
            }
            .animation(Motion.crossfade, value: order.id)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            // Outlined, never filled, and the halo the outline's own, so
            // the strip's names cast no glow and no band of fill stands
            // under them
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline)
                    .haloGlow(AppColors.gold, radius: 16, intensity: 0.19)
            )

            GoldCTAButton(title: prayTitle(order, offered: offered), glyph: .play) {
                router.push(.prayAlong(.order(order, on: now)))
            }
        }
    }

    /// "Pray the Angelus" — the order's own name, its article lowered —
    /// and "Pray the Angelus again" once it is offered, so the button
    /// always says which prayer it begins
    private func prayTitle(_ order: PrayerOrder, offered: Bool) -> String {
        let title = order.title(on: now)
        let named = title.hasPrefix("The ") ? "the " + title.dropFirst(4) : title
        return offered ? "Pray \(named) again" : "Pray \(named)"
    }

    private var prayersToMary: some View {
        let chapter = PrayerBook.ourLady
        let antiphon = PrayerBook.antiphon(on: now)
        let seasonal = PrayerBook.prayer(antiphon.prayerID)
        let known = PrayerBook.bestKnownMarianIDs
            .filter { $0 != antiphon.prayerID }
            .compactMap { PrayerBook.prayer($0) }
        // In the Easter season Queen of Heaven is the Angelus, already set
        // large on the card above over the same painting; the section
        // opens on its rows rather than showing it twice
        let seasonalIsPrayNow = shownOrder.prayerIDs(now) == [antiphon.prayerID]

        return VStack(alignment: .leading, spacing: 16) {
            PrayersSectionTitle(
                title: "Prayers to Mary",
                note: "This season's song to Mary, and her best-known prayers."
            )

            if let seasonal, !seasonalIsPrayNow {
                Button {
                    router.push(.devotionPrayer(id: seasonal.id))
                } label: {
                    MarianSeasonCard(prayer: seasonal, antiphon: antiphon)
                }
                .buttonStyle(SacredCardButtonStyle())
            }

            VStack(spacing: 0) {
                ForEach(Array(known.enumerated()), id: \.element.id) { i, prayer in
                    PrayersLedgerRow(
                        title: prayer.listTitle,
                        note: PrayerBook.englishNames[prayer.id],
                        prayerID: prayer.id,
                        showsRule: i < known.count - 1
                    ) {
                        router.push(.devotionPrayer(id: prayer.id))
                    }
                }
            }

            QuietGoldButton(
                title: "All \(chapter.prayerIDs.count) prayers to Mary",
                trailingIcon: "ph-caret-right",
                size: 10,
                color: AppColors.gold,
                horizontalPadding: 0
            ) {
                router.push(.prayerBookChapter(id: chapter.id))
            }
            .padding(.top, -10)
        }
    }

    private var saved: some View {
        let kept = store.keptPrayers
        let columns = typeSize >= .xLarge ? 2 : 3

        return VStack(alignment: .leading, spacing: 16) {
            PrayersSectionTitle(
                title: "Saved",
                note: "To save a prayer here, tap the bookmark at the top of its page."
            )

            if !kept.isEmpty {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: columns),
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach(kept) { prayer in
                        SavedPrayerCard(prayer: prayer) {
                            router.push(.devotionPrayer(id: prayer.id))
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .animation(Motion.crossfade, value: store.ribbons)
    }

    // MARK: - Occasions

    private var occasions: some View {
        VStack(alignment: .leading, spacing: 16) {
            PrayersSectionTitle(
                title: "Occasions",
                note: "Choose where you are, or what you need, to see its prayers."
            )

            WordFlow(spacing: 8, lineSpacing: 4) {
                ForEach(PrayerOccasionPlace.allCases) { option in
                    PrayersPlaceChip(title: option.title, isSelected: option == place) {
                        placeRaw = option.rawValue
                    }
                }
            }

            // The orders of one place give way to another's in one slot
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    let orders = PrayerBook.ordersKept(at: place)
                    ForEach(Array(orders.enumerated()), id: \.element.id) { i, order in
                        PrayersOccasionRow(
                            order: order,
                            now: now,
                            showsRule: i < orders.count - 1
                        ) {
                            router.push(.prayerOrder(id: order.id))
                        }
                    }
                }
                .id(place)
                .transition(.opacity)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .animation(Motion.crossfade, value: place)
        }
    }

    // MARK: - All Prayers

    private var allPrayers: some View {
        VStack(alignment: .leading, spacing: 16) {
            PrayersSectionTitle(title: "All Prayers", note: "Every prayer, by topic.")

            VStack(spacing: 0) {
                ForEach(PrayerBook.chapters) { chapter in
                    PrayersLedgerRow(
                        title: chapter.title,
                        note: PrayerBook.chapterNotes[chapter.id],
                        count: chapter.prayerIDs.count
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
            if hits.isEmpty && topics.isEmpty && orders.isEmpty {
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
