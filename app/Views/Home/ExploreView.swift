//
//  ExploreView.swift
//  Lumen Viae
//
//  Explore: one page that can reach everything, opened from the home
//  screen's search bar. Empty, it browses — the five devotions and the
//  library. Typed into, it searches those and every meditation set.
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
                    prompt: Text("Search mysteries, meditations, the library")
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

    /// The page at rest: an epigraph and two doorways. The meditation
    /// index is fetched quietly for search but never listed here — a
    /// catalog of every set belongs behind a typed word, not on a
    /// landing page.
    @ViewBuilder
    private var browseContent: some View {
        epigraph

        section("The Mysteries") {
            VStack(spacing: 10) {
                mysteryLedger(MysteryCategory.allCases)

                // Beneath the five: the other way of praying them. A
                // door of its own, because it is a devotion of its own —
                // the mysteries above open the shelf of meditations;
                // this opens the Rosary prayed on the Gospel's words.
                scripturalBanner

                // And the Rosary with nothing between its prayers but
                // the voice saying them
                aloudBanner

                // For someone who has never prayed it: the course, where
                // a newcomer looks first rather than at the page's foot
                newcomerDoor
            }
        }

        // Each kind of door carries its own shape: the two liturgical
        // books as a diptych — the same pairing the home page's shelf
        // makes — the books to read as a row of standing covers, and
        // the guides and records as a ruled index.
        section("The Liturgy") {
            liturgyDiptych
        }

        section("Spiritual Reading", link: ("The shelf", { router.push(.spiritualReading) })) {
            readingShelf
        }

        section("The Study") {
            libraryIndex
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

    /// The page's reason for being, in the Gospel's own words.
    private var epigraph: some View {
        VStack(spacing: 6) {
            Text("Seek, and you shall find.")
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.cream.opacity(0.9))

            Text("MATTHEW 7:7")
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    // MARK: - Search results

    private var searchResults: some View {
        let needle = trimmedQuery.lowercased()

        let categories = MysteryCategory.allCases.filter {
            $0.devotionTitle.lowercased().contains(needle)
                || $0.subtitle.lowercased().contains(needle)
        }
        let libraryHits = libraryEntries.filter { $0.matchText.lowercased().contains(needle) }
        let setHits = sets.filter { matches($0, needle: needle) }
        // The library's own readings — Lourdes, Kolbe, the marks of true
        // devotion — found by name or by their dating line. A shelf's
        // own title answers only when no reading does: matched as well,
        // "carlo" listed every one of St. Carlo's readings and buried
        // the one asked for.
        let shelved = LibraryReadings.shelves.flatMap { shelf in
            shelf.entries.map { ReadingHit(shelf: shelf, reading: $0) }
        }
        let namedHits = shelved.filter {
            $0.reading.title.lowercased().contains(needle)
                || $0.reading.detail.lowercased().contains(needle)
        }
        let readingHits = namedHits.isEmpty
            ? shelved.filter { $0.shelf.title.lowercased().contains(needle) }
            : namedHits

        return ZStack(alignment: .top) {
        if categories.isEmpty && libraryHits.isEmpty && readingHits.isEmpty && setHits.isEmpty {
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
                         ? "The meditations couldn't be reached — mysteries and the library are still searchable."
                         : "Try a mystery, a set's name, or a saint.")
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
                    section("The Mysteries") {
                        mysteryLedger(categories)
                    }
                    .transition(.opacity)
                }

                if !libraryHits.isEmpty {
                    section("The Library") {
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
        if let labels = summary.labels, labels.contains(where: { $0.lowercased().contains(needle) }) { return true }
        if let category = MysteryCategory(rawValue: summary.category),
           category.devotionTitle.lowercased().contains(needle) { return true }
        return false
    }

    // MARK: - Library entries

    private struct LibraryEntry {
        let icon: String
        let title: String
        let matchText: String
        let action: () -> Void
    }

    private var libraryEntries: [LibraryEntry] {
        [
            LibraryEntry(icon: "ch-altar", title: "Daily Missal",
                         matchText: "daily missal mass 1962 propers latin") { router.push(.missal) },
            LibraryEntry(icon: "ph-clock", title: "Divine Office",
                         matchText: "divine office breviary hours matins lauds prime terce sext none vespers compline") { router.push(.office) },
            LibraryEntry(icon: "ph-crown", title: "True Devotion",
                         matchText: "true devotion to mary montfort book") { router.push(.trueDevotionBook) },
            LibraryEntry(icon: "ph-scroll", title: "The Devotion in Summary",
                         matchText: "true devotion summary marks false devotions montfort") { router.push(.trueDevotion) },
            LibraryEntry(icon: "ph-book-open", title: "Spiritual Reading",
                         matchText: "spiritual reading books imitation of christ story of a soul confessions augustine dolorous passion emmerich therese kempis library") { router.push(.spiritualReading) },
            LibraryEntry(icon: "ch-bible", title: "Scriptural Rosary",
                         matchText: "scriptural rosary verse every bead gospel douay rheims bible") { router.push(.scripturalRosary) },
            LibraryEntry(icon: PrayerShortcut.rosaryAloud.icon, title: "The Rosary Aloud",
                         matchText: "rosary aloud said spoken audio listen voice hear prayers learn by ear") { router.push(.rosaryAloud) },
            LibraryEntry(icon: "ch-rosary", title: "How to Pray",
                         matchText: "how to pray the rosary guide montfort methods") { router.push(.howToPray) },
            // Not the Gospel glyph: that is the Scriptural Rosary's, and
            // the two doors stood side by side wearing the same one
            LibraryEntry(icon: "lv-breviary", title: "In Scripture",
                         matchText: "mysteries in scripture bible verses") { router.push(.scripture) },
            LibraryEntry(icon: "ch-lily", title: "Marian Library",
                         matchText: "marian theology library dogmas apparitions saints") { router.push(.marianLibrary) },
            LibraryEntry(icon: "ch-monstrance", title: "Carlo Acutis",
                         matchText: "carlo acutis eucharist digital altar saint") { router.push(.carloAcutis) },
            LibraryEntry(icon: "ph-flame", title: "Prayer Record",
                         matchText: "sacred record progress streak history calendar") { router.switchTo(.progress) }
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

    /// The Scriptural Rosary's door, in the ledger's own shape: the arch
    /// holds the Gospel's glyph rather than a painting, and the row
    /// stands on the card ground rather than a category's colours,
    /// because it belongs to no one set of mysteries.
    private var scripturalBanner: some View {
        devotionBanner(
            icon: PrayerShortcut.scripturalRosary.icon,
            title: "The Scriptural Rosary",
            detail: "A verse for every bead"
        ) {
            router.push(.scripturalRosary)
        }
    }

    /// The Rosary Aloud's door, in the same shape beside it: another way
    /// of praying whichever mysteries, so it too stands on the card
    /// ground, and its arch holds its own glyph.
    private var aloudBanner: some View {
        devotionBanner(
            icon: PrayerShortcut.rosaryAloud.icon,
            title: "The Rosary Aloud",
            detail: "Every prayer said aloud"
        ) {
            router.push(.rosaryAloud)
        }
    }

    private func devotionBanner(
        icon: String,
        title: String,
        detail: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                GothicArchShape(riseRatio: 0.42)
                    .fill(AppColors.background.opacity(0.6))
                    .frame(width: 44, height: 56)
                    .overlay(
                        AppIcon(icon, size: 20)
                            .foregroundColor(AppColors.gold)
                    )
                    .overlay(
                        GothicArchShape(riseRatio: 0.42)
                            .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 0.8)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)

                    Text(detail)
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
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("\(title). \(detail)")
    }

    /// A quiet line under the devotions for someone who has never
    /// prayed the Rosary: no card and no gold fill — a door, not a
    /// banner, beside the five that are. The glyph is How to Pray's own.
    private var newcomerDoor: some View {
        Button {
            router.push(.howToPray)
        } label: {
            HStack(spacing: 12) {
                AppIcon("ch-rosary", size: 16)
                    .foregroundColor(AppColors.gold.opacity(0.85))
                    .frame(width: 20)

                Text("New to the Rosary?")
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.85))

                Spacer(minLength: 8)

                HStack(spacing: 5) {
                    Text("HOW TO PRAY")
                        .font(AppFonts.labelFont(9))
                        .tracking(1.5)
                    AppIcon("ph-caret-right", size: 8)
                }
                .foregroundColor(AppColors.gold.opacity(0.85))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New to the Rosary? How to Pray")
    }

    // MARK: - The Liturgy

    /// The Mass and the Office side by side on one card — a diptych,
    /// hinged on a centre rule, the same pairing the home shelf makes.
    ///
    /// The card is its leaves' height and no more. The hinge was a bare
    /// `Rectangle` with a width and no height, and a shape takes all the
    /// height it is offered — the one flexible thing in the card — so
    /// the card could stand far taller than the two short leaves in it,
    /// a blank band under the names. The hinge has its own height now,
    /// and the card is held to what its leaves need.
    private var liturgyDiptych: some View {
        HStack(spacing: 0) {
            diptychLeaf(
                icon: "ch-altar",
                title: "Daily Missal",
                subtitle: "The Mass"
            ) { router.push(.missal) }

            Rectangle()
                .fill(AppColors.gold.opacity(0.25))
                .frame(width: AppLine.hairline, height: 48)

            // The Office's glyph everywhere is the clock of its hours
            diptychLeaf(
                icon: "ph-clock",
                title: "Divine Office",
                subtitle: "The Hours"
            ) { router.push(.office) }
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline)
        )
    }

    private func diptychLeaf(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                AppIcon(icon, size: 22)
                    .foregroundColor(AppColors.gold)

                Text(title)
                    .font(AppFonts.headlineFont(15))
                    .foregroundColor(AppColors.cream)

                Text(subtitle.uppercased())
                    .font(AppFonts.labelFont(8))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("\(title). \(subtitle)")
    }

    // MARK: - The Study index

    /// The guides and references as a ruled index — bare lines on the
    /// page, a book's own table of contents rather than a wall of
    /// boxes. The liturgical books and the reading shelf have their own
    /// sections above; the Prayer Record is the user's own book, not a
    /// thing to discover, so it stays off the browse page — typed
    /// search still finds its door, and the Chapel's Prayer Streak tile
    /// and Settings → Devotion keep the real ones.
    /// How to Pray stands under the mysteries, where a newcomer looks,
    /// and the two other ways of praying them stand there too.
    private var studyEntries: [LibraryEntry] {
        let housed = [
            "Daily Missal", "Divine Office",
            "True Devotion", "Spiritual Reading",
            "Scriptural Rosary", "The Rosary Aloud",
            "Prayer Record", "How to Pray"
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
                    if let live = try? await APIService.shared.fetchMeditationSets(category: category) {
                        return live
                    }
                    return await OfflineContentService.shared.storedSummaries(category: category) ?? []
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
