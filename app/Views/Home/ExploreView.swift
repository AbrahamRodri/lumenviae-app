//
//  ExploreView.swift
//  Lumen Viae
//
//  Explore: one page that can reach everything, opened from the home
//  screen's search bar. Empty, it is a directory of the app — the five
//  devotions, the Prayer Book's occasions, the chant library, the Mass
//  and the Hours, and the books — and nothing on it turns with the hour
//  or the day: that is Home's and the Chapel's work. Typed into, it
//  searches all of those and every meditation set.
//
//  The meditation index is fetched per category from the API the first
//  time a word is typed, never on arrival: at rest this page lists no
//  sets, so nothing here is waiting on a network. Offline it falls back
//  to whatever has been downloaded, and while the fetch is in flight it
//  says so rather than reporting that nothing matched.
//

import SwiftUI
import SwiftData

struct ExploreView: View {

    @Environment(AppRouter.self) private var router

    /// What was prayed and sung lately, which the Prayers shelf and the
    /// Chant tiles take in over their defaults
    private var prayerBook = PrayerBookStore.shared
    private var chantShelf = ChantShelfStore.shared

    /// Which books have a reading under way — their covers wear the
    /// marker ribbon here as they do on the shelf itself. The same book
    /// must not carry a marker on one surface and none on another.
    @Query private var reading: [BookReadingProgress]

    private var readingIDs: Set<String> {
        Set(reading.filter { $0.hasReadingPlace || $0.hasResumableTrack }.map(\.bookID))
    }

    @State private var query = ""

    /// Every category's set summaries, fetched once per visit
    @State private var sets: [MeditationSetSummary] = []
    @State private var isLoadingSets = false

    /// The index was asked for and nothing came back — neither the API
    /// nor the offline store. An empty result then means "couldn't
    /// reach the meditations", not "no such set".
    @State private var setsUnavailable = false

    /// Whether the index has been asked for at all this visit. The
    /// re-entry guard hangs on this rather than on `sets.isEmpty`: a
    /// fetch that came back empty leaves that condition true forever,
    /// so every further keystroke started another five-request
    /// fan-out. Trying again is an act the reader chooses.
    @State private var didRequestSets = false

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                searchHeader

                ScrollView(showsIndicators: false) {
                    // Browsing and searching share one slot, so typing
                    // the first letter crossfades the shelf into results
                    // rather than cutting to them — and each keystroke
                    // after that fades sections in and out in place
                    ZStack(alignment: .top) {
                        if trimmedQuery.isEmpty {
                            // The browse page is several sections; they
                            // keep their column inside the slot
                            VStack(alignment: .leading, spacing: 28) {
                                browseContent
                            }
                            .transition(.opacity)
                        } else {
                            searchResults
                                .transition(.opacity)
                        }
                    }
                    .animation(Motion.crossfade, value: trimmedQuery)
                    .animation(Motion.crossfade, value: isLoadingSets)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        // A pushed content page keeps the system bar and draws its own
        // gold Back in it, like every other destination. The Daily
        // Missal is the one page allowed to hide the bar, because its
        // collapsing header *is* the chrome; Explore has no such header,
        // and hiding the bar here only cost the field its own line.
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
            // The page's name, the one the home masthead's glass and the
            // first-use tour call it by
            ToolbarItem(placement: .principal) {
                Text("Explore")
                    .font(AppFonts.headlineFont(17))
                    .foregroundColor(AppColors.cream)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        // The index is worth fetching only once there is something to
        // match it against — at rest this page lists no sets.
        .onChange(of: trimmedQuery) { _, needle in
            guard !needle.isEmpty else { return }
            Task { await loadSets() }
        }
    }

    // MARK: - Search header

    /// The field running the whole width — no pill, no card. Back lives
    /// in the navigation bar above, as it does on every other pushed
    /// page. The field's only furniture is the fading gold rule beneath
    /// it, the same thread the section labels run out on.
    private var searchHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                AppIcon("ph-magnifying-glass", size: 15)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.trailing, 10)

                TextField(
                    "",
                    text: $query,
                    prompt: Text("Search prayers, mysteries, books and chant")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.textSecondary.opacity(0.8))
                )
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.cream)
                .tint(AppColors.gold)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .frame(height: 52)

                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        AppIcon("ph-x-circle", size: 15)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 36, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 16)

            // The field's ground: a rule that fades out before either
            // edge, so the line ends softly rather than being cut off.
            LinearGradient(
                stops: [
                    .init(color: AppColors.gold.opacity(0), location: 0),
                    .init(color: AppColors.gold.opacity(0.4), location: 0.12),
                    .init(color: AppColors.gold.opacity(0.4), location: 0.88),
                    .init(color: AppColors.gold.opacity(0), location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .padding(.horizontal, 16)
        }
        .padding(.top, 6)
        // Deliberately not auto-focused: this page is a place first and
        // a search second — the keyboard rises only when asked.
    }

    // MARK: - Browse

    /// The page at rest: a directory, each section a shelf of paintings.
    /// The meditation index is fetched quietly for search but never
    /// listed here — a catalog of every set belongs behind a typed word,
    /// not on a landing page.
    @ViewBuilder
    private var browseContent: some View {
        // Each opens its mysteries' page, where the Rosary is chosen in
        // its three forms — a meditation set, the Scriptural Rosary, or
        // the Rosary Said Aloud; typed search still finds the two forms
        section("Rosary Mysteries") {
            mysteryLedger(MysteryCategory.allCases)
        }

        // The Prayer Book's orders kept for an occasion, as a shelf of
        // paintings. The day's three hours stay off this page: which one
        // is now is Home's and the Chapel's to say.
        section("Prayers", link: ("All prayers", { router.push(.prayerBook) })) {
            occasionShelf
        }

        // The chant library's ways in, as painted tiles. No chant of the
        // day here: tonight's song to Mary is the library's own to offer.
        section("Chant", link: ("Library", { router.push(.chantLibrary) })) {
            chantTiles
        }

        // The Church's two books, named for what they are rather than for
        // today
        section("Mass and Hours") {
            liturgyTiles
        }

        section("Spiritual Reading", link: ("All books", { router.push(.spiritualReading) })) {
            readingShelf
        }

        // Gone while every guide it lists is archived (`ArchivedPages`)
        if !studyEntries.isEmpty {
            section("Learn More") {
                libraryIndex
            }
        }
    }

    /// The books themselves, standing in a row — True Devotion among
    /// them, because it is one: each cover opens its own book directly.
    private var readingShelf: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 14) {
                coverTile(LibraryCatalog.trueDevotionDisplay) { router.push(.trueDevotionBook) }

                ForEach(LibraryCatalog.books) { book in
                    coverTile(book, hasRibbon: readingIDs.contains(book.id)) {
                        router.push(.libraryBook(id: book.id))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
        // Out to the screen edges, so the row scrolls under the page
        // margin instead of being clipped by it
        .padding(.horizontal, -20)
    }

    private func coverTile(
        _ info: LibraryBookInfo,
        hasRibbon: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            BookCover(info: info, hasRibbon: hasRibbon)
                .frame(width: 106)
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(
            "\(info.title), \(info.author)\(hasRibbon ? ". Reading under way." : "")"
        )
    }

    // MARK: - Search results

    private var searchResults: some View {
        let needle = trimmedQuery.lowercased()

        let categories = MysteryCategory.allCases.filter {
            $0.devotionTitle.lowercased().contains(needle)
                || $0.subtitle.lowercased().contains(needle)
        }
        // A door answers to its own name as well as its words: matched on
        // the words alone, "chant library" found nothing, since the Chant
        // Library's words say "chant" and "gregorian" but never the two
        // together, and "prayer record" missed the Prayer Record
        let libraryHits = libraryEntries.filter {
            "\($0.title) \($0.matchText)".lowercased().contains(needle)
        }
        let setHits = sets.filter { matches($0, needle: needle) }
        // The library's own readings — Lourdes, Kolbe, the marks of true
        // devotion — found by name or by their dating line. A shelf's
        // own title answers only when no reading does: matched as well,
        // "carlo" listed every one of St. Carlo's readings and buried
        // the one asked for.
        let shelved = LibraryReadings.shelves.filter { !ArchivedPages.hides(shelf: $0) }.flatMap { shelf in
            shelf.entries.map { ReadingHit(shelf: shelf, reading: $0) }
        }
        let namedHits = shelved.filter {
            $0.reading.title.lowercased().contains(needle)
                || $0.reading.detail.lowercased().contains(needle)
        }
        let readingHits = namedHits.isEmpty
            ? shelved.filter { $0.shelf.title.lowercased().contains(needle) }
            : namedHits
        // The Prayer Book's orders by name or occasion, and its prayers
        // by name, Latin name, or — for a word of four letters or more —
        // their words
        let orderHits = PrayerBook.orders.filter {
            $0.title(on: Date()).lowercased().contains(needle)
                || $0.occasion.lowercased().contains(needle)
                || $0.latinTitle.lowercased().contains(needle)
                || $0.searchWords.contains { $0.contains(needle) }
        }
        let prayerHits = PrayerBook.search(needle)
        let chantHits = ChantCatalog.search(needle)

        return ZStack(alignment: .top) {
        if categories.isEmpty && libraryHits.isEmpty && readingHits.isEmpty && setHits.isEmpty
            && orderHits.isEmpty && prayerHits.isEmpty && chantHits.isEmpty {
            if isLoadingSets {
                // The set index can be seconds away on a cold server.
                // Saying nothing matched before it lands is a confident
                // wrong answer, so the page waits visibly instead.
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(AppColors.gold)

                    Text("Searching the meditations…")
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .transition(.opacity)
            } else {
                VStack(spacing: 8) {
                    Text("Nothing found")
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)

                    Text(setsUnavailable
                         ? "Couldn't load the meditations. Check your connection. Prayers, mysteries and books can still be searched."
                         : "Try a mystery, a prayer, or a saint's name.")
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // The index is asked for once; if it never came, the
                    // reader asks again when they have signal rather
                    // than the page retrying on every keystroke.
                    if setsUnavailable {
                        QuietGoldButton(
                            title: "Try again",
                            leadingIcon: "ph-arrow-counter-clockwise",
                            leadingIconSize: 10,
                            size: 10
                        ) {
                            retrySets()
                        }
                        .padding(.top, 6)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .transition(.opacity)
            }
        } else {
            VStack(alignment: .leading, spacing: 28) {
                if !categories.isEmpty {
                    section("Rosary Mysteries") {
                        mysteryLedger(categories)
                    }
                    .transition(.opacity)
                }

                if !libraryHits.isEmpty {
                    section("Pages") {
                        tileGrid(libraryHits.map { entry in
                            ExploreTile(icon: entry.icon, title: entry.title, action: entry.action)
                        })
                    }
                    .transition(.opacity)
                }

                if !readingHits.isEmpty {
                    section("Readings") {
                        VStack(alignment: .leading, spacing: 0) {
                            // Each row wears its shelf's glyph, so a
                            // Carlo reading and a Marian one are told
                            // apart before their names are read
                            ForEach(readingHits.prefix(Self.readingLimit)) { hit in
                                LedgerDoorRow(title: hit.reading.title, note: hit.reading.detail, icon: hit.shelf.icon) {
                                    router.push(.libraryReading(id: hit.reading.id))
                                }
                            }

                            // A cut list says so, and how to narrow it
                            if readingHits.count > Self.readingLimit {
                                Text("And \(readingHits.count - Self.readingLimit) more — add a word to narrow the search.")
                                    .font(AppFonts.italicFont(13))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .transition(.opacity)
                }

                if !orderHits.isEmpty || !prayerHits.isEmpty {
                    section("Prayers") {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(orderHits) { order in
                                LedgerDoorRow(title: order.title(on: Date()), note: order.occasion, icon: order.icon) {
                                    router.push(.prayerOrder(id: order.id))
                                }
                            }
                            ForEach(prayerHits.prefix(Self.readingLimit)) { prayer in
                                LedgerDoorRow(
                                    title: prayer.listTitle,
                                    note: prayer.latinTitle ?? PrayerBook.homeChapter(of: prayer.id)?.title,
                                    icon: PrayerBook.homeChapter(of: prayer.id)?.icon
                                ) {
                                    router.push(.devotionPrayer(id: prayer.id))
                                }
                            }
                            if prayerHits.count > Self.readingLimit {
                                Text("And \(prayerHits.count - Self.readingLimit) more — add a word to narrow the search.")
                                    .font(AppFonts.italicFont(13))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .transition(.opacity)
                }

                if !chantHits.isEmpty {
                    section("Chants") {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(chantHits.prefix(Self.readingLimit)) { chant in
                                ChantLibraryRow(chant: chant, player: ChantPlayer.shared) {
                                    router.push(.chant(id: chant.id))
                                }
                            }
                            if chantHits.count > Self.readingLimit {
                                Text("And \(chantHits.count - Self.readingLimit) more — add a word to narrow the search.")
                                    .font(AppFonts.italicFont(13))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .transition(.opacity)
                }

                if !setHits.isEmpty {
                    section("Meditations") {
                        setRows(setHits)
                    }
                    .transition(.opacity)
                }
            }
            .transition(.opacity)
        }
        }
    }

    /// How many readings a search lists before it says how many more
    private static let readingLimit = 12

    /// A reading found, with the shelf it stands on
    private struct ReadingHit: Identifiable {
        let shelf: ReadingShelf
        let reading: LibraryReading
        var id: String { reading.id }
    }

    private func matches(_ summary: MeditationSetSummary, needle: String) -> Bool {
        if summary.name.lowercased().contains(needle) { return true }
        if let author = summary.author, author.lowercased().contains(needle) { return true }
        if let source = summary.source, source.lowercased().contains(needle) { return true }
        // By the label the shelf shows ("Gospel", "Reflections") as well
        // as the one the server stores
        if let labels = summary.labels, labels.contains(where: {
            $0.lowercased().contains(needle) || MeditationLabel.displayName($0).lowercased().contains(needle)
        }) { return true }
        if let category = MysteryCategory(rawValue: summary.category),
           category.devotionTitle.lowercased().contains(needle) { return true }
        return false
    }

    // MARK: - Library entries

    private struct LibraryEntry {
        let icon: String
        let title: String
        let matchText: String
        /// The page it opens, where it opens one, so an archived page's
        /// door stands down (`ArchivedPages`)
        var route: AppRoute? = nil
        let action: () -> Void
    }

    /// The day's mysteries' page, where the Rosary's forms are chosen
    private func openTodaysMysteries() {
        router.navigateToMeditationSelection(category: ScheduleService.categoryForToday())
    }

    private var libraryEntries: [LibraryEntry] {
        allLibraryEntries.filter { !ArchivedPages.hides($0.route) }
    }

    private var allLibraryEntries: [LibraryEntry] {
        [
            LibraryEntry(icon: "ch-altar", title: "Today's Mass",
                         matchText: "daily missal mass 1962 propers latin") { router.push(.missal) },
            LibraryEntry(icon: "ph-clock", title: "Hours of Prayer",
                         matchText: "divine office breviary hours of prayer matins lauds prime terce sext none vespers compline") { router.push(.office) },
            LibraryEntry(icon: "ph-crown", title: "True Devotion",
                         matchText: "true devotion to mary montfort book") { router.push(.trueDevotionBook) },
            LibraryEntry(icon: "ph-scroll", title: "The Devotion in Summary",
                         matchText: "true devotion summary marks false devotions montfort", route: .trueDevotion) { router.push(.trueDevotion) },
            LibraryEntry(icon: "ph-book-open", title: "Spiritual Reading",
                         matchText: "spiritual reading books imitation of christ story of a soul confessions augustine therese kempis library") { router.push(.spiritualReading) },
            // The Rosary's two forms beside the meditation sets, found by
            // name and opening the day's mysteries' page, where they stand
            // under OTHER WAYS TO PRAY with the sets beneath
            LibraryEntry(icon: PrayerShortcut.scripturalRosary.icon, title: "The Scriptural Rosary",
                         matchText: "scriptural rosary verse every bead gospel douay rheims bible") { openTodaysMysteries() },
            LibraryEntry(icon: PrayerShortcut.rosaryAloud.icon, title: "The Rosary Said Aloud",
                         matchText: "holy rosary aloud said spoken audio listen voice hear prayers learn by ear no meditation") { openTodaysMysteries() },
            LibraryEntry(icon: "lv-rosary", title: "How to Pray",
                         matchText: "how to pray the rosary guide montfort methods") { router.push(.howToPray) },
            // Not the Gospel glyph: that is the Scriptural Rosary's, and
            // the two doors stood side by side wearing the same one
            LibraryEntry(icon: "lv-breviary", title: "In Scripture",
                         matchText: "mysteries in scripture bible verses", route: .scripture) { router.push(.scripture) },
            LibraryEntry(icon: "ch-lily", title: "Marian Library",
                         matchText: "marian theology library dogmas apparitions saints", route: .marianLibrary) { router.push(.marianLibrary) },
            LibraryEntry(icon: "ch-monstrance", title: "St. Carlo Acutis",
                         matchText: "carlo acutis eucharist digital altar saint", route: .carloAcutis) { router.push(.carloAcutis) },
            LibraryEntry(icon: "lv-prayer-book", title: "Prayers",
                         matchText: "prayer book prayers enchiridion morning night angelus grace confession examination conscience mass communion litany litanies marian our lady latin novena") { router.push(.prayerBook) },
            LibraryEntry(icon: "ph-music-note", title: "The Chant Library",
                         matchText: "chant chants gregorian sung song songs hymn hymns latin score scores sheet music antiphon sing") { router.push(.chantLibrary) },
            LibraryEntry(icon: "ph-flame", title: "Prayer Record",
                         matchText: "sacred record progress streak history calendar") { router.push(.prayerRecord) },
            // The Journal gave its place in the bar to Prayers; found by
            // name, it opens as the Chapel's Reflections tile opens it
            LibraryEntry(icon: "ph-book-open", title: "Journal",
                         matchText: "journal reflections reflection notes entries write diary") { router.push(.journal) }
        ]
    }

    /// Search hits keep the compact tile — a found door, not a browsed
    /// shelf.
    private func tileGrid(_ tiles: [ExploreTile]) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in
                tile
            }
        }
    }

    // MARK: - Pieces

    private func section<Content: View>(
        _ title: String,
        link: (String, () -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // The label runs out on a fading rule, the same line the
            // day label draws on home.
            HStack(spacing: 12) {
                Text(title.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .fixedSize()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.gold.opacity(0.35), AppColors.gold.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                if let link {
                    Button(action: link.1) {
                        HStack(spacing: 5) {
                            Text(link.0.uppercased())
                                .font(AppFonts.labelFont(9))
                                .tracking(1.5)

                            AppIcon("ph-caret-right", size: 8)
                        }
                        .foregroundColor(AppColors.gold.opacity(0.8))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(link.0)
                }
            }

            content()
        }
    }

    /// The five devotions, each carrying its own painting in a small
    /// lancet arch on its own ground — the category's colours, so the
    /// Sorrowful reads sorrowful before a word is read. Art is what
    /// tells the mysteries apart everywhere else in the app; here too.
    private func mysteryLedger(_ categories: [MysteryCategory]) -> some View {
        VStack(spacing: 10) {
            ForEach(categories, id: \.self) { category in
                mysteryBanner(category)
            }
        }
    }

    private func mysteryBanner(_ category: MysteryCategory) -> some View {
        Button {
            router.navigateToMeditationSelection(category: category)
        } label: {
            HStack(spacing: 14) {
                CachedAssetImage(category.cardImageName, focal: category.cardFocalPoint)
                    .frame(width: 44, height: 56)
                    .clipShape(GothicArchShape(riseRatio: 0.42))
                    .overlay(
                        GothicArchShape(riseRatio: 0.42)
                            .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 0.8)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.devotionTitle)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)

                    Text(category.subtitle)
                        .font(AppFonts.italicFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer(minLength: 8)

                AppIcon("ph-caret-right", size: 13)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: category.gradientColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(SacredCardButtonStyle())
        // The subtitle is half the row; an override would drop it
        .accessibilityLabel("\(category.devotionTitle). \(category.subtitle)")
    }

    // MARK: - Painted shelves

    /// The Prayer Book's orders kept for an occasion, most needed first,
    /// each a painting and its name, scrolling sideways to the screen's
    /// edges. What the reader prayed lately leads, marked RECENT, and
    /// pushes out the least needed defaults (`ExploreShelves`).
    private var occasionShelf: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(ExploreShelves.prayerSlots(recents: prayerBook.recent), id: \.item) { slot in
                    if let door = ExploreShelves.PrayerDoor(slot.item) {
                        Button {
                            router.push(door.route)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                CachedAssetImage(door.painting.resolvedAsset, focal: door.painting.focal)
                                    .frame(width: 128, height: 128)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline)
                                    )
                                    .padding(.bottom, 4)

                                Text(door.title)
                                    .font(AppFonts.bodyFont(15))
                                    .foregroundColor(AppColors.cream)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)

                                if slot.isRecent {
                                    Text("RECENT")
                                        .font(AppFonts.labelFont(8.5))
                                        .tracking(1.7)
                                        .foregroundColor(AppColors.gold)
                                }
                            }
                            .frame(width: 128, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(SacredCardButtonStyle())
                        .accessibilityLabel(slot.isRecent ? "\(door.title). Recent" : door.title)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
        // Out to the screen edges, so the row scrolls under the page
        // margin instead of being clipped by it
        .padding(.horizontal, -20)
    }

    /// The chant library's ways in, two by two: every chant and the songs
    /// to Mary, then the two chants sung last, or until anything has been
    /// sung, the Mass of the Angels and the sets of chants
    private var chantTiles: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            paintedTile(
                title: "All \(ChantCatalog.all.count) Chants", note: nil,
                asset: "glorious_pentecost", focal: UnitPoint(x: 0.5, y: 0.3)
            ) { router.push(.chantBrowse(.all)) }

            paintedTile(
                title: "Songs to Mary", note: nil,
                asset: "mary_sistine_madonna", focal: UnitPoint(x: 0.5, y: 0.25)
            ) { router.push(.chantBrowse(.songsToMary)) }

            ForEach(ExploreShelves.chantSlots(recentIDs: chantShelf.recent.map(\.chantID)), id: \.item) { slot in
                switch slot.item {
                case .massOfTheAngels:
                    paintedTile(
                        title: ChantBrowseScope.massSetting, note: nil,
                        asset: "luminous_proclamation", focal: UnitPoint(x: 0.5, y: 0.3)
                    ) { router.push(.chantBrowse(.massOfTheAngels)) }
                case .sets:
                    paintedTile(
                        title: "Sets of Chants", note: nil,
                        asset: "feast_our_lady_of_the_rosary", focal: UnitPoint(x: 0.5, y: 0.3)
                    ) { router.push(.chantSets) }
                case .chant(let id):
                    if let chant = ChantCatalog.chant(id) {
                        paintedTile(
                            title: chant.englishTitle, note: "Recent",
                            asset: ChantCatalog.painting(for: chant), focal: UnitPoint(x: 0.5, y: 0.3)
                        ) { router.push(.chant(id: id)) }
                    }
                }
            }
        }
    }

    /// The Mass and the Office as two painted tiles of the chant's shape
    private var liturgyTiles: some View {
        HStack(spacing: 10) {
            paintedTile(
                title: "The Mass", note: "Daily Missal",
                asset: "luminous_eucharist", focal: UnitPoint(x: 0.5, y: 0.35)
            ) { router.push(.missal) }

            paintedTile(
                title: "Hours of Prayer", note: "Divine Office",
                asset: "hour_morning", focal: UnitPoint(x: 0.5, y: 0.35)
            ) { router.push(.office) }
        }
    }

    /// A painting run to a small card's edges, its name on a scrim along
    /// the foot
    private func paintedTile(
        title: String,
        note: String?,
        asset: String,
        focal: UnitPoint,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            CachedAssetImage(asset, focal: focal)
                .frame(maxWidth: .infinity)
                .frame(height: 92)
                .overlay(
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.backgroundDeep.opacity(0), location: 0.2),
                            .init(color: AppColors.backgroundDeep.opacity(0.9), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(AppFonts.bodyFont(15))
                            .foregroundColor(AppColors.cream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        if let note {
                            Text(note)
                                .font(AppFonts.italicFont(12))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 9)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline)
                )
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(note.map { "\(title). \($0)" } ?? title)
    }

    // MARK: - The Study index

    /// The guides and references as a ruled index — bare lines on the
    /// page, a book's own table of contents rather than a wall of
    /// boxes. The liturgical books and the reading shelf have their own
    /// sections above; the Prayer Record is the user's own book, not a
    /// thing to discover, so it stays off the browse page — typed
    /// search still finds its door, and the Chapel's Prayer Streak tile
    /// and Settings → Devotion keep the real ones.
    /// How to Pray is found by search and from Home and the Chapel; the
    /// Rosary's other two forms stand on every mysteries' page.
    private var studyEntries: [LibraryEntry] {
        let housed = [
            "Today's Mass", "Hours of Prayer",
            "True Devotion", "Spiritual Reading",
            "The Scriptural Rosary", "The Rosary Said Aloud",
            "Prayer Record", "How to Pray", "The Chant Library",
            "Journal", "Prayers"
        ]
        return libraryEntries.filter { !housed.contains($0.title) }
    }

    private var libraryIndex: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)],
            spacing: 0
        ) {
            ForEach(Array(studyEntries.enumerated()), id: \.offset) { _, entry in
                Button(action: entry.action) {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            AppIcon(entry.icon, size: 15)
                                .foregroundColor(AppColors.gold.opacity(0.85))
                                .frame(width: 18)

                            Text(entry.title)
                                .font(AppFonts.bodyFont(14))
                                .foregroundColor(AppColors.cream)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 46)

                        Rectangle()
                            .fill(AppColors.gold.opacity(0.14))
                            .frame(height: AppLine.hairline)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(entry.title)
            }
        }
    }

    private func setRows(_ summaries: [MeditationSetSummary]) -> some View {
        VStack(spacing: 0) {
            ForEach(summaries) { summary in
                Button {
                    router.navigateToMeditationSetDetail(summary)
                } label: {
                    HStack(spacing: 14) {
                        AppIcon("ph-cards", size: 16)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(summary.name)
                                .font(AppFonts.bodyFont(15))
                                .foregroundColor(AppColors.cream)

                            Text(setSubtitle(summary))
                                .font(AppFonts.bodyFont(12))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        AppIcon("ph-caret-right", size: 13)
                            .foregroundColor(AppColors.textSecondary.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if summary.id != summaries.last?.id {
                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: AppLine.hairline)
        )
    }

    private func setSubtitle(_ summary: MeditationSetSummary) -> String {
        let category = MysteryCategory(rawValue: summary.category)?.devotionTitle ?? summary.category
        // A set named for its author would read the same line twice
        if let author = summary.author, !author.isEmpty, author != summary.name {
            return "\(author) · \(category)"
        }
        return category
    }

    // MARK: - Data

    /// Every category's summaries, fetched concurrently on the first
    /// typed word. A category that fails falls back to whatever has been
    /// downloaded for offline reading — the same store the meditation
    /// picker reads — so a chapel with no signal can still find a set it
    /// already holds.
    private func loadSets() async {
        guard !didRequestSets, !isLoadingSets else { return }
        didRequestSets = true
        isLoadingSets = true
        // Restored: a `defer` cannot be skipped by an early return or a
        // cancellation, and a flag left true wedges search on
        // "Searching the meditations…" for the rest of the visit.
        defer { isLoadingSets = false }

        let fetched = await withTaskGroup(of: [MeditationSetSummary].self) { group in
            for category in MysteryCategory.allCases {
                group.addTask {
                    // The bundled set for these mysteries stands in the
                    // index as it stands on the mysteries' page, with no
                    // signal and nothing downloaded
                    let bundled = await BundledMeditationSets.summaries(for: category)
                    if let live = try? await APIService.shared.fetchMeditationSets(category: category) {
                        return live + bundled
                    }
                    return (await OfflineContentService.shared.storedSummaries(category: category) ?? []) + bundled
                }
            }

            var all: [MeditationSetSummary] = []
            for await summaries in group {
                all.append(contentsOf: summaries)
            }
            return all
        }

        sets = fetched.sorted { $0.name < $1.name }
        // A search that finds nothing because the index never arrived is
        // a different answer from one that finds nothing, and the page
        // says which.
        setsUnavailable = sets.isEmpty
    }

    /// The reader asking for the index again, after signal returns.
    private func retrySets() {
        didRequestSets = false
        setsUnavailable = false
        Task { await loadSets() }
    }
}

// MARK: - ExploreShelves

/// What Explore's Prayers shelf and Chant tiles hold: defaults ranked by
/// importance, giving way to what the reader prays and sings
/// (`RecentShelf`)
enum ExploreShelves {

    /// The occasion orders, most needed first. Before Mass is the last to
    /// give way to the reader's own.
    static let prayerDefaults: [PrayerBookStore.RecentPrayer] = [
        "before_mass", "before_confession", "after_mass", "after_confession",
        "visit", "table", "holy_souls", "trouble",
    ].map { .order($0) }

    /// The shelf for these recents. The day's three hours stay off it,
    /// as they always have: which is now is Home's to say. A prayer or
    /// order the book no longer carries is passed over.
    static func prayerSlots(recents: [PrayerBookStore.RecentPrayer]) -> [RecentShelf.Slot<PrayerBookStore.RecentPrayer>] {
        let occasions = Set(PrayerBook.occasionOrders.map(\.id))
        let usable = recents.filter {
            switch $0 {
            case .order(let id): occasions.contains(id)
            case .prayer(let id): PrayerBook.prayer(id) != nil
            }
        }
        return RecentShelf.fill(defaults: prayerDefaults, recents: usable)
    }

    /// One place on the Prayers shelf, as it is drawn and where it goes
    struct PrayerDoor {
        let title: String
        let painting: PrayerBookPainting
        let route: AppRoute

        init?(_ item: PrayerBookStore.RecentPrayer, on date: Date = Date()) {
            switch item {
            case .order(let id):
                guard let order = PrayerBook.order(id) else { return nil }
                title = order.title(on: date)
                painting = PrayerBookPainting.order(order, on: date)
                route = .prayerOrder(id: id)
            case .prayer(let id):
                guard let prayer = PrayerBook.prayer(id) else { return nil }
                title = prayer.listTitle
                painting = PrayerBookPainting.prayer(id)
                route = .devotionPrayer(id: id)
            }
        }
    }

    enum ChantTile: Hashable {
        case massOfTheAngels
        case sets
        case chant(String)
    }

    /// The two chant tiles after every chant and the songs to Mary
    static func chantSlots(recentIDs: [String]) -> [RecentShelf.Slot<ChantTile>] {
        RecentShelf.fill(
            defaults: [.massOfTheAngels, .sets],
            recents: recentIDs.filter { ChantCatalog.chant($0) != nil }.map { .chant($0) }
        )
    }
}

// MARK: - ExploreTile

/// A small door: icon and name in a quiet cell — how a library door
/// found by typed search is set.
private struct ExploreTile: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                AppIcon(icon, size: 16)
                    .foregroundColor(AppColors.gold)

                Text(title)
                    .font(AppFonts.bodyFont(13))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: AppLine.hairline)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExploreView()
            .environment(AppRouter())
    }
}
