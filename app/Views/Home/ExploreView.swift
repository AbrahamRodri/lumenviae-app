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

    /// Where the search was opened from: Home's glass, or a page's own
    let origin: AppSearch.Origin

    @State private var query = ""
    @FocusState private var fieldFocused: Bool

    /// Whether the field has been focused for the reader once: coming
    /// back from a result must not bring the keyboard up over the list
    @State private var didFocusOnArrival = false

    /// The result at the top of the scroll (`AppSearchResultsView`'s
    /// scroll ids): a chip sets it to jump, and its kind is the chip lit
    @State private var scrolledID: String?

    /// What the words found, searched again only when the words or the
    /// meditation sets change: drawn from the body, the search ran over
    /// every chant's lines and every prayer at each redraw, scrolling
    /// included
    @State private var results = AppSearch.Results.empty

    init(origin: AppSearch.Origin = .everywhere) {
        self.origin = origin
    }

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

            Group {
                VStack(spacing: 0) {
                    searchHeader

                    // The kinds found stand under the field, out of the
                    // scroll, so they are there to jump by wherever the
                    // page is read
                    if !trimmedQuery.isEmpty, !results.isEmpty {
                        AppSearchChips(
                            results: results,
                            active: litKind
                        ) { kind in
                            withAnimation(Motion.ease(0.35)) {
                                scrolledID = AppSearchResultsView.scrollID(of: kind, in: results)
                            }
                        }
                        .padding(.top, 12)
                        .transition(.opacity)
                    }

                    ScrollView(showsIndicators: false) {
                        // Browsing and searching share one slot, so typing
                        // the first letter crossfades the shelf into results
                        // rather than cutting to them — and each keystroke
                        // after that fades sections in and out in place
                        ZStack(alignment: .top) {
                            if trimmedQuery.isEmpty {
                                restingContent
                                    .transition(.opacity)
                            } else {
                                resultsContent(results)
                                    .transition(.opacity)
                            }
                        }
                        .animation(Motion.crossfade, value: trimmedQuery)
                        .animation(Motion.crossfade, value: isLoadingSets)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .scrollPosition(id: $scrolledID, anchor: .top)
                    .scrollDismissesKeyboard(.interactively)
                }
                .animation(Motion.crossfade, value: results.isEmpty)
            }
        }
        .navigationBarBackButtonHidden(true)
        // From Home the page keeps the system bar, its gold Back and its
        // name, like every other destination. Opened from a page's glass
        // it is that page's search: the field and CANCEL are the head,
        // and CANCEL is the way back.
        .toolbar(origin == .everywhere ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            if origin == .everywhere {
                ToolbarItem(placement: .navigationBarLeading) {
                    GoldBackButton()
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
        }
        // The index is worth fetching only once there is something to
        // match it against — at rest this page lists no sets.
        .onChange(of: trimmedQuery) { _, needle in
            search()
            guard !needle.isEmpty else { return }
            Task { await loadSets() }
        }
        // The sets arriving add their section where the reader is: put
        // back at the top, a reader already scrolling was thrown up there
        .onChange(of: sets) { _, _ in search(keepingPlace: true) }
        .onAppear {
            // A page's glass was a request to search: the keyboard rises
            if origin != .everywhere, !didFocusOnArrival {
                didFocusOnArrival = true
                fieldFocused = true
            }
        }
        // VoiceOver stays in the field and would hear nothing of the
        // results: what was found is said once the reader pauses. While
        // the meditations are still being fetched with nothing else found,
        // the page says it is searching, so "Nothing found" waits for
        // them; their arrival is said again.
        .task(id: "\(trimmedQuery)|\(isLoadingSets)") {
            guard !trimmedQuery.isEmpty, !(isLoadingSets && results.isEmpty) else { return }
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            let found = results
            let words = found.isEmpty
                ? "Nothing found"
                : found.kinds.map { "\($0.title), \(found.count(of: $0))" }.joined(separator: "; ")
            AccessibilityNotification.Announcement(words).post()
        }
    }

    // MARK: - Resting and results

    /// Before a word is typed: Explore's directory from Home; opened from
    /// a page's glass, one quiet line, since that page is its own
    /// directory and is a Cancel away
    @ViewBuilder
    private var restingContent: some View {
        if origin == .everywhere {
            // The browse page is several sections; they keep their column
            // inside the slot
            VStack(alignment: .leading, spacing: 28) {
                browseContent
            }
        } else {
            Text("Search every prayer, chant, mystery and book in the app.")
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Search header

    /// The field in the chant search's gold outline, brightening while
    /// it is being typed in. Opened from a page's glass, CANCEL stands
    /// beside it and is the way back.
    private var searchHeader: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                AppIcon("ph-magnifying-glass", size: 15)
                    .foregroundColor(AppColors.gold.opacity(0.75))

                TextField(
                    "",
                    text: $query,
                    prompt: Text(origin.prompt)
                        .font(AppFonts.readingFont(16))
                        .foregroundColor(AppColors.textSecondary)
                )
                .font(AppFonts.readingFont(17))
                .foregroundColor(AppColors.cream)
                .tint(AppColors.gold)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($fieldFocused)
                .accessibilityLabel("Search")

                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        AppIcon("ph-x-circle", size: 15)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    // The glyph keeps its place; only the target grows
                    .padding(.trailing, -7)
                    .accessibilityLabel("Clear the search")
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(fieldFocused ? 0.7 : 0.35), lineWidth: 1)
            )
            .animation(Motion.crossfade, value: fieldFocused)

            if origin != .everywhere {
                Button {
                    fieldFocused = false
                    router.pop()
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        // From Home deliberately not auto-focused: Explore is a place
        // first and a search second — the keyboard rises only when asked.
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
        // day here: the season's song to Mary stands on the library's Songs
        // to Mary shelf.
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

    /// Searches again for the words as they stand. New words put the
    /// page back at its top, the card's chip lit: kept where it was, a
    /// longer word left the list part-way down under another kind's chip.
    /// Searched again in place (`keepingPlace`, the sets arriving), the
    /// page stays where it was unless the section it stood on is gone.
    private func search(keepingPlace: Bool = false) {
        let wasEmpty = results.isEmpty
        results = AppSearch.results(for: trimmedQuery, from: origin, sets: sets, pages: searchPages)
        let standing = AppSearchResultsView.kind(ofScrollID: scrolledID, in: results)
        let stillThere = standing.map { results.kinds.contains($0) } ?? false
        if !keepingPlace || wasEmpty || !stillThere {
            scrolledID = results.firstScrollID
        }
    }

    /// The chip lit: the kind at the top of the scroll, else the first
    private var litKind: AppSearch.Kind? {
        let kind = AppSearchResultsView.kind(ofScrollID: scrolledID, in: results)
        if let kind, results.kinds.contains(kind) { return kind }
        return results.kinds.first
    }

    /// The app's doors, as the search knows them: by name and words
    private var searchPages: [AppSearch.Page] {
        libraryEntries.map {
            AppSearch.Page(id: $0.id, title: $0.title, matchText: $0.matchText, icon: $0.icon)
        }
    }

    private func openPage(_ id: String) {
        libraryEntries.first { $0.id == id }?.action()
    }

    @ViewBuilder
    private func resultsContent(_ results: AppSearch.Results) -> some View {
        ZStack(alignment: .top) {
            if results.isEmpty {
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
                             ? "Couldn't load the meditations. Check your connection. Prayers, chants, mysteries and books can still be searched."
                             : "Try a mystery, a prayer, a chant or a saint's name.")
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
                AppSearchResultsView(results: results, openPage: openPage)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Library entries

    private struct LibraryEntry {
        /// What names the door to the search and back, whatever its title
        /// says: a door renamed keeps its hit
        let id: String
        let icon: String
        let title: String
        let matchText: String
        /// The page it opens, where it opens one, so an archived page's
        /// door stands down (`ArchivedPages`)
        var route: AppRoute? = nil
        /// Listed in Learn More: a guide with no shelf of its own above.
        /// Every other door is found by search alone.
        var inLearnMore = false
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
            LibraryEntry(id: "missal", icon: "ch-altar", title: "Today's Mass",
                         matchText: "daily missal mass 1962 propers latin") { router.push(.missal) },
            LibraryEntry(id: "office", icon: "ph-clock", title: "Hours of Prayer",
                         matchText: "divine office breviary hours of prayer matins lauds prime terce sext none vespers compline") { router.push(.office) },
            LibraryEntry(id: "trueDevotion", icon: "ph-crown", title: "True Devotion",
                         matchText: "true devotion to mary montfort book") { router.push(.trueDevotionBook) },
            LibraryEntry(id: "devotionSummary", icon: "ph-scroll", title: "The Devotion in Summary",
                         matchText: "true devotion summary marks false devotions montfort", route: .trueDevotion, inLearnMore: true) { router.push(.trueDevotion) },
            LibraryEntry(id: "spiritualReading", icon: "ph-book-open", title: "Spiritual Reading",
                         matchText: "spiritual reading books imitation of christ story of a soul confessions augustine therese kempis library") { router.push(.spiritualReading) },
            // The Rosary's two forms beside the meditation sets, found by
            // name and opening the day's mysteries' page, where they stand
            // under WAYS TO PRAY with the sets beneath
            LibraryEntry(id: "scripturalRosary", icon: PrayerShortcut.scripturalRosary.icon, title: "The Scriptural Rosary",
                         matchText: "scriptural rosary verse every bead gospel douay rheims bible") { openTodaysMysteries() },
            LibraryEntry(id: "rosaryAloud", icon: PrayerShortcut.rosaryAloud.icon, title: "The Rosary Said Aloud",
                         matchText: "holy rosary aloud said spoken audio listen voice hear prayers learn by ear no meditation") { openTodaysMysteries() },
            LibraryEntry(id: "howToPray", icon: "lv-rosary", title: "How to Pray",
                         matchText: "how to pray the rosary guide montfort methods") { router.push(.howToPray) },
            // Not the Gospel glyph: that is the Scriptural Rosary's, and
            // the two doors stood side by side wearing the same one
            LibraryEntry(id: "scripture", icon: "lv-breviary", title: "In Scripture",
                         matchText: "mysteries in scripture bible verses", route: .scripture, inLearnMore: true) { router.push(.scripture) },
            LibraryEntry(id: "marianLibrary", icon: "ch-lily", title: "Marian Library",
                         matchText: "marian theology library dogmas apparitions saints", route: .marianLibrary, inLearnMore: true) { router.push(.marianLibrary) },
            LibraryEntry(id: "carloAcutis", icon: "ch-monstrance", title: "St. Carlo Acutis",
                         matchText: "carlo acutis eucharist digital altar saint", route: .carloAcutis, inLearnMore: true) { router.push(.carloAcutis) },
            LibraryEntry(id: "prayerBook", icon: "lv-prayer-book", title: "Prayers",
                         matchText: "prayer book prayers enchiridion morning night angelus grace confession examination conscience mass communion litany litanies marian our lady latin novena") { router.push(.prayerBook) },
            LibraryEntry(id: "chantLibrary", icon: "ph-music-note", title: "The Chant Library",
                         matchText: "chant chants gregorian sung song songs hymn hymns latin score scores sheet music antiphon sing") { router.push(.chantLibrary) },
            LibraryEntry(id: "prayerRecord", icon: "ph-flame", title: "Prayer Record",
                         matchText: "sacred record progress streak history calendar") { router.push(.prayerRecord) },
            // The Journal gave its place in the bar to Prayers; found by
            // name, it opens as the Chapel's Reflections tile opens it
            LibraryEntry(id: "journal", icon: "ph-book-open", title: "Journal",
                         matchText: "journal reflections reflection notes entries write diary") { router.push(.journal) }
        ]
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
                    .frame(height: AppLine.hairline)

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
                    .buttonStyle(QuietGlyphButtonStyle())
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
                        // The setting beside Recent, so the simple and the
                        // solemn Salve Regina are told apart
                        paintedTile(
                            title: chant.englishTitle,
                            note: ExploreShelves.recentChantNote(chant),
                            asset: ChantCatalog.painting(for: chant), focal: UnitPoint(x: 0.5, y: 0.3),
                            spoken: "\(chant.spokenName). Recent"
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
        spoken: String? = nil,
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
        .accessibilityLabel(spoken ?? note.map { "\(title). \($0)" } ?? title)
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
        libraryEntries.filter(\.inLearnMore)
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

    /// The shelf for these recents. A prayer or order the book no longer
    /// carries is passed over (the day's three hours are never kept,
    /// `PrayerBookStore.unkeptRecents`).
    static func prayerSlots(recents: [PrayerBookStore.RecentPrayer]) -> [RecentShelf.Slot<PrayerBookStore.RecentPrayer>] {
        let usable = recents.filter {
            switch $0 {
            case .order(let id): PrayerBook.order(id) != nil
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

    /// A recent chant's note: Recent, with its setting where its titles
    /// do not say it ("Recent · simple melody")
    static func recentChantNote(_ chant: Chant) -> String {
        chant.settingMidLine.map { "Recent · \($0)" } ?? "Recent"
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

// MARK: - Preview

#Preview {
    NavigationStack {
        ExploreView()
            .environment(AppRouter())
    }
}
