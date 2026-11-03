//
//  MysteriesInScriptureView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  FINDING THE MYSTERIES IN SCRIPTURE
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A lectionary for the beads: where each mystery lives in the Bible,
//  and the verse to carry into its decade.
//
//  The sets of mysteries are tabs pinned under the title as the page
//  scrolls (today's chosen to begin with). Each mystery of the chosen
//  set is a card that can be read without opening: its painting, its
//  place and citation, its key verse set large, and the grace to ask
//  for — and it opens on the whole passage (`MysteryPassageView`).
//  Beneath the cards, how to read before a decade, the seven graces for
//  the Sorrows, and the page's one act: to pray these mysteries with a
//  verse on every bead.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - MysteriesInScriptureView

struct MysteriesInScriptureView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings

    private let today = ScheduleService.categoryForToday()

    /// The set whose cards are on the page
    @State private var category: MysteryCategory = ScheduleService.categoryForToday()

    /// The tab underlined — ahead of `category` for the length of a
    /// change, while the old set's cards fade out
    @State private var selection: MysteryCategory = ScheduleService.categoryForToday()

    /// The page beneath the tabs, faded out while the set is swapped.
    /// Out, swap, in: an `.id()` crossfade laid both sets' cards out
    /// together for the length of the fade, and the page beneath them
    /// stood twice as tall and leapt back.
    @State private var pageVisible = true

    /// Whether the tabs have reached the top and are riding over the
    /// cards. Only then do they need a ground to be read against.
    @State private var tabsPinned = false

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    masthead
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                        // The masthead's foot is where the tabs stand
                        // until they pin; once it has gone above the
                        // top, they are riding over the cards
                        .onGeometryChange(for: Bool.self) { proxy in
                            proxy.frame(in: .scrollView).maxY < 1
                        } action: { pinned in
                            withAnimation(Motion.chrome) { tabsPinned = pinned }
                        }

                    Section {
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(spacing: 14) {
                                ForEach(Array(MysteryData.mysteries(for: category).enumerated()), id: \.element.id) { index, mystery in
                                    lectionaryCard(mystery, index: index)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 18)

                            howToRead
                                .padding(.horizontal, 24)
                                .padding(.top, 44)

                            if category == .sevenSorrows {
                                sevenGraces
                                    .padding(.horizontal, 24)
                                    .padding(.top, 40)
                            }

                            prayThese
                                .padding(.horizontal, 24)
                                .padding(.top, 44)
                                .padding(.bottom, 56)
                        }
                        .opacity(pageVisible ? 1 : 0)
                        .allowsHitTesting(pageVisible)
                    } header: {
                        tabs
                    }
                }
            }
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
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

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THE WORD BEHIND THE BEADS")
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            Text("The Mysteries\nin Scripture")
                .font(AppFonts.titleFont(31))
                .foregroundColor(AppColors.cream)
                .lineSpacing(3)

            Text("Every mystery of the Rosary is a page of the Gospel. Read its verse before the decade (the ten Hail Marys said for it), and pray with the scene in front of you.")
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }

    // MARK: - Tabs

    /// The five sets as a row of tabs, the chosen one underlined in gold
    /// and today's marked with a dot; pinned as the page scrolls
    private var tabs: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(MysteryCategory.allCategories, id: \.self) { candidate in
                        let chosen = candidate == selection

                        Button {
                            choose(candidate)
                            withAnimation { proxy.scrollTo(candidate, anchor: .center) }
                        } label: {
                            VStack(spacing: 8) {
                                HStack(spacing: 5) {
                                    Text(candidate.displayName)
                                        .font(AppFonts.titleFont(15))
                                        .foregroundColor(chosen ? AppColors.goldLight : AppColors.cream.opacity(0.6))

                                    if candidate == today {
                                        Circle()
                                            .fill(AppColors.gold)
                                            .frame(width: 4, height: 4)
                                            .offset(y: -6)
                                    }
                                }

                                Capsule()
                                    .fill(chosen ? AppColors.goldLight : .clear)
                                    .frame(height: 2)
                            }
                            .fixedSize()
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(candidate)
                        .accessibilityLabel(
                            candidate == today
                                ? Text("\(candidate.devotionTitle), today's")
                                : Text(candidate.devotionTitle)
                        )
                        .accessibilityAddTraits(chosen ? [.isSelected, .isButton] : .isButton)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 4)
        // Pinned, the tabs stand on the page's own dark, which dissolves
        // to clear below them rather than ending on an edge — a flat
        // band with a rule under it read as a slab laid across the page
        // gradient. At rest under the masthead they need no ground.
        .background(alignment: .top) {
            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0.94), location: 0),
                    .init(color: AppColors.background.opacity(0.94), location: 0.55),
                    .init(color: AppColors.background.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // Runs past the band, so the fade happens beneath the words
            .padding(.bottom, -28)
            .opacity(tabsPinned ? 1 : 0)
            .allowsHitTesting(false)
        }
    }

    /// The tab follows the finger at once; the page beneath fades out,
    /// takes the new set while unseen, and fades back in, so the two
    /// sets are never laid out together.
    private func choose(_ candidate: MysteryCategory) {
        guard candidate != selection else { return }
        withAnimation(Motion.crossfade) { selection = candidate }

        withAnimation(Motion.crossfade, completionCriteria: .logicallyComplete) {
            pageVisible = false
        } completion: {
            var cut = Transaction()
            cut.disablesAnimations = true
            withTransaction(cut) { category = selection }

            withAnimation(Motion.crossfade) { pageVisible = true }
        }
    }

    // MARK: - A Mystery's Card

    /// Readable without opening: the painting, where it is found, the
    /// verse, and the grace — a tap reads the whole passage
    private func lectionaryCard(_ mystery: Mystery, index: Int) -> some View {
        let key = "\(category.rawValue)_\(mystery.order)"
        let verse = MysteriesInScriptureData.keyVerse(key)
        let fruit = MysteryData.traditionalFruits[key]
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let arch = GothicArchShape(riseRatio: 0.42)

        return Button {
            router.push(.mysteryInScripture(category: category, order: mystery.order))
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 14) {
                    if let painting = Constants.mysteryImageURL(category: category.rawValue, index: index) {
                        CachedAssetImage(painting)
                            .frame(width: 54, height: 70)
                            .clipShape(arch)
                            .overlay(arch.strokeBorder(AppColors.gold.opacity(0.5), lineWidth: AppLine.hairline))
                            .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(Self.cardKicker(mystery, in: category))
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1.8)
                            .foregroundColor(AppColors.gold.opacity(0.8))

                        Text(mystery.name)
                            .font(AppFonts.titleFont(18))
                            .foregroundColor(AppColors.cream)
                            .fixedSize(horizontal: false, vertical: true)

                        if let reference = mystery.scriptureReference {
                            Text(reference)
                                .font(AppFonts.readingItalicFont(15))
                                .foregroundColor(AppColors.gold.opacity(0.75))
                        }
                    }

                    Spacer(minLength: 0)
                }

                if let verse {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\u{201C}\(verse.text)\u{201D}")
                            .font(AppFonts.readingItalicFont(18))
                            .foregroundColor(AppColors.cream.opacity(0.92))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(verse.citation.uppercased())
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1.6)
                            .foregroundColor(AppColors.gold.opacity(0.7))
                    }
                    .padding(.leading, 14)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(AppColors.gold.opacity(0.45))
                            .frame(width: 2)
                    }
                }

                HStack(alignment: .firstTextBaseline) {
                    if let fruit {
                        Text("ASK FOR")
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1.8)
                            .foregroundColor(AppColors.gold.opacity(0.75))

                        Text(fruit)
                            .font(AppFonts.readingFont(15))
                            .foregroundColor(AppColors.goldLight)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 5) {
                        Text("THE PASSAGE")
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1.6)
                        AppIcon("ph-caret-right", size: 8)
                    }
                    .foregroundColor(AppColors.gold.opacity(0.85))
                }
            }
            .padding(18)
            .background(
                shape.fill(
                    LinearGradient(
                        colors: [AppColors.cardBackground.opacity(0.8), AppColors.cardBackground.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .overlay(shape.strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline))
            .contentShape(shape)
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    /// The card's kicker, "FIRST MYSTERY" or, in the chaplet, "FIRST
    /// SORROW": one phrase per case, so a translation sets its own order
    private static func cardKicker(_ mystery: Mystery, in category: MysteryCategory) -> String {
        let ordinal = mystery.ordinalName
        return category == .sevenSorrows
            ? String(
                localized: "\(ordinal) Sorrow",
                comment: "In Scripture, a sorrow's card: small capitals kicker over its name; the ordinal is a word like First … Seventh"
            ).uppercased()
            : String(
                localized: "\(ordinal) Mystery",
                comment: "In Scripture, a mystery's card: small capitals kicker over its name; the ordinal is a word like First … Fifth"
            ).uppercased()
    }

    // MARK: - How to Read

    private var howToRead: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BEFORE EACH DECADE")
                .font(AppFonts.labelFont(9.5))
                .tracking(2.8)
                .foregroundColor(AppColors.gold.opacity(0.9))

            HStack(alignment: .top, spacing: 12) {
                readStep(
                    "I",
                    String(localized: "Read", comment: "In Scripture, Before each decade, step I: the verb that begins the step's phrase, set in brighter type; the rest follows it, the verse slowly, and let one phrase settle"),
                    String(localized: "the verse slowly, and let one phrase settle", comment: "In Scripture, Before each decade, step I: the rest of the phrase after the verb Read, lower case")
                )
                readStep(
                    "II",
                    String(localized: "Picture", comment: "In Scripture, Before each decade, step II: the verb that begins the step's phrase, set in brighter type; the rest follows it, the scene, and stand in it beside Mary"),
                    String(localized: "the scene, and stand in it beside Mary", comment: "In Scripture, Before each decade, step II: the rest of the phrase after the verb Picture, lower case")
                )
                readStep(
                    "III",
                    String(localized: "Ask", comment: "In Scripture, Before each decade, step III: the verb that begins the step's phrase, set in brighter type; the rest follows it, for its grace, then begin the decade"),
                    String(localized: "for its grace, then begin the decade", comment: "In Scripture, Before each decade, step III: the rest of the phrase after the verb Ask, lower case")
                )
            }

            // Said once, here, for every card above: what ASK FOR names
            Text("Each mystery has its fruit — the grace, by long tradition, to ask for while its decade is prayed. The cards name it under Ask for.")
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func readStep(_ numeral: String, _ verb: String, _ rest: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(numeral)
                .font(AppFonts.titleFont(20))
                .foregroundColor(AppColors.goldLight)

            (Text(verb).foregroundColor(AppColors.cream)
                + Text(" " + rest).foregroundColor(AppColors.textSecondary))
                .font(AppFonts.readingFont(15))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - The Seven Graces

    private var sevenGraces: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("THE SEVEN GRACES")
                .font(AppFonts.labelFont(9.5))
                .tracking(2.8)
                .foregroundColor(AppColors.gold.opacity(0.9))

            Text("By tradition handed down through St. Bridget of Sweden, Our Lady promises seven graces to those who honour her daily by meditating on her sorrows.")
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(MysteriesInScriptureData.sevenGraces.enumerated()), id: \.offset) { index, grace in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)")
                        .font(AppFonts.titleFont(15))
                        .foregroundColor(AppColors.gold)
                        .frame(width: 18, alignment: .leading)

                    Text(grace)
                        .font(AppFonts.readingFont(16))
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Pray These

    /// The page's one act: these mysteries, prayed with a verse on every
    /// bead
    private var prayThese: some View {
        VStack(spacing: 12) {
            OrnamentDivider()
                .frame(width: 120)

            Text("Pray the \(category.devotionTitle) with a verse of Scripture on every bead.")
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Named as the passage page names it: one act, one name
            GoldCTAButton(
                title: String(localized: "Pray the Scriptural Rosary", comment: "In Scripture, foot of a set's page: the gold act, praying these mysteries with a verse on every bead"),
                glyph: .play
            ) {
                router.push(.scripturalRosaryPrayer(ScripturalRosaryLaunch(category: category)))
            }
            .padding(.top, 4)

            QuietGoldButton(
                title: String(localized: "Or with a meditation", comment: "In Scripture, under Pray the Scriptural Rosary: quiet link to these mysteries' meditation sets"),
                trailingIcon: "ph-caret-right",
                size: 10
            ) {
                router.navigateToMeditationSelection(category: category)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - MysteryPassageView

/// One mystery read in Scripture: its place in the set as the kicker,
/// its name in Cinzel, the painting in the arch, the verse to carry set
/// apart, what the mystery is, and then the passage itself — the
/// Scriptural Rosary's verses, set as running text under their book —
/// with the fruit to ask for and the doors to pray it. The
/// foot steps along the set in place.
struct MysteryPassageView: View {

    let category: MysteryCategory

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings

    @State private var order: Int

    /// The page, faded out while the next mystery is put in its place —
    /// out, swap, in, so two mysteries are never laid out together in
    /// the one column
    @State private var pageVisible = true

    init(category: MysteryCategory, order: Int) {
        self.category = category
        _order = State(initialValue: order)
    }

    private static let topAnchor = "mystery-passage-top"

    private var mysteries: [Mystery] { MysteryData.mysteries(for: category) }

    private var readingSize: CGFloat { max(16, settings.meditationFontSize - 2) }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppColors.appGradient
                    .ignoresSafeArea()

                if let index = mysteries.firstIndex(where: { $0.order == order }) {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            page(mysteries[index], index: index, width: geometry.size.width)
                                .opacity(pageVisible ? 1 : 0)
                                .allowsHitTesting(pageVisible)
                        }
                        .topChromeFade()
                        .onChange(of: order) {
                            proxy.scrollTo(Self.topAnchor, anchor: .top)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
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

    private var key: String { "\(category.rawValue)_\(order)" }

    private func page(_ mystery: Mystery, index: Int, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 1)
                .id(Self.topAnchor)

            VStack(spacing: 16) {
                Text(
                    category == .sevenSorrows
                        ? String(
                            localized: "The \(mystery.ordinalName) Sorrow",
                            comment: "In Scripture, a sorrow's passage page: small capitals kicker over its name; the ordinal is a word like First … Seventh"
                        ).uppercased()
                        : category.mysteryLabel(ordinal: mystery.order).uppercased()
                )
                    .font(AppFonts.labelFont(9))
                    .tracking(2.4)
                    .foregroundColor(AppColors.gold)
                    .multilineTextAlignment(.center)

                OrnamentDivider()
                    .frame(width: 150)

                Text(mystery.name)
                    .font(AppFonts.titleFont(27))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)

                if let reference = mystery.scriptureReference {
                    Text(reference)
                        .font(AppFonts.readingItalicFont(15))
                        .foregroundColor(AppColors.gold.opacity(0.8))
                }
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .devotionalEntrance()

            if let painting = Constants.mysteryImageURL(category: category.rawValue, index: index) {
                let arch = GothicArchShape(riseRatio: 0.34)
                let archWidth = min(width * 0.46, 210)

                arch
                    .fill(AppColors.cardBackground)
                    .frame(width: archWidth, height: archWidth * 1.22)
                    .overlay(CachedAssetImage(painting))
                    .clipShape(arch)
                    .accessibilityHidden(true)
                    .padding(.top, 26)
                    .devotionalEntrance(delay: 0.06)
            }

            if let verse = MysteriesInScriptureData.keyVerse(key) {
                QuotedPassageText(passage: verse.text, citation: verse.citation, size: readingSize - 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 40)
                    .padding(.trailing, 28)
                    .padding(.top, 30)
                    .devotionalEntrance(delay: 0.1)
            }

            if let description = mystery.description {
                ReadingText(text: description, size: readingSize, showsDropCap: true)
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .devotionalEntrance(delay: 0.14)
            }

            if let verses = ScripturalRosaryData.verses(category: category.rawValue, order: order) {
                passage(verses)
                    .padding(.horizontal, 28)
                    .padding(.top, 30)
            }

            VStack(spacing: 0) {
                if let fruit = MysteryData.traditionalFruits[key] {
                    SetSection(label: String(localized: "Ask for", comment: "In Scripture, a passage page: section heading over the mystery's fruit, the grace to ask for")) {
                        Text(fruit)
                            .font(AppFonts.readingFont(16))
                            .foregroundColor(AppColors.goldLight)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SetSection(label: String(localized: "Pray", comment: "In Scripture, a passage page: section heading over the doors that pray these mysteries")) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Straight to prayer in the set being read, as the
                        // list page's act does, and by the same name — this
                        // once opened the title page on today's set
                        LedgerDoorRow(
                            title: String(localized: "Pray the Scriptural Rosary", comment: "In Scripture, a passage page: door praying these mysteries with a verse on every bead"),
                            note: String(localized: "These verses, one on every bead", comment: "In Scripture, a passage page: line under Pray the Scriptural Rosary"),
                            icon: "ch-bible"
                        ) {
                            router.push(.scripturalRosaryPrayer(ScripturalRosaryLaunch(category: category)))
                        }
                        LedgerDoorRow(
                            title: category.devotionTitle,
                            note: String(localized: "Meditations on these mysteries", comment: "In Scripture, a passage page: line under the set's name, a door to its meditation sets"),
                            icon: "lv-rosary"
                        ) {
                            router.navigateToMeditationSelection(category: category)
                        }
                    }
                    .padding(.vertical, -10)
                }

                stepper(index: index)
            }
            .padding(.horizontal, 24)
            .padding(.top, 34)
            .padding(.bottom, 48)
        }
        .padding(.top, 8)
    }

    /// The passage as a Bible prints it: running prose under its book's
    /// name, each verse opened by its number in small gold figures, and
    /// a new paragraph only where the book changes.
    private func passage(_ verses: [ScripturalVerse]) -> some View {
        let split = verses.map { verse -> (book: String, number: String, text: String) in
            guard let space = verse.reference.lastIndex(of: " ") else { return ("", verse.reference, verse.text) }
            return (String(verse.reference[..<space]), String(verse.reference[verse.reference.index(after: space)...]), verse.text)
        }

        var groups: [(book: String, verses: [(number: String, text: String)])] = []
        for verse in split {
            if groups.last?.book == verse.book {
                groups[groups.count - 1].verses.append((verse.number, verse.text))
            } else {
                groups.append((verse.book, [(verse.number, verse.text)]))
            }
        }

        return VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Text(group.book.uppercased())
                            .font(AppFonts.labelFont(9))
                            .tracking(2)
                            .foregroundColor(AppColors.gold.opacity(0.85))
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
                    }

                    group.verses.reduce(Text("")) { running, verse in
                        running
                            + Text("\(verse.number)\u{2009}")
                                .font(AppFonts.labelFont(max(8, readingSize * 0.5)))
                                .foregroundColor(AppColors.gold.opacity(0.75))
                                .baselineOffset(readingSize * 0.3)
                            + Text(verse.text + " ")
                                .font(AppFonts.readingFont(readingSize))
                                .foregroundColor(AppColors.cream.opacity(0.92))
                    }
                    .lineSpacing(ReadingTypography.lineSpacing(for: readingSize))
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text("Douay-Rheims, the traditional Catholic English Bible")
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
        }
    }

    private func stepper(index: Int) -> some View {
        let previous = index > 0 ? mysteries[index - 1] : nil
        let next = index + 1 < mysteries.count ? mysteries[index + 1] : nil

        return VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.18))
                .frame(height: AppLine.hairline)

            HStack(alignment: .top, spacing: 16) {
                if let previous {
                    stepButton(previous, label: String(localized: "Previous", comment: "In Scripture, foot of a passage page: step to the previous mystery; VoiceOver adds its name"), leading: true)
                } else {
                    Spacer()
                }

                if let next {
                    stepButton(next, label: String(localized: "Next", comment: "In Scripture, foot of a passage page: step to the next mystery; VoiceOver adds its name"), leading: false)
                } else {
                    Spacer()
                }
            }
            .padding(.top, 14)
        }
    }

    /// Out, swap, in — the scroll returns to the top while the page is
    /// unseen (`onChange(of: order)`)
    private func step(to target: Int) {
        guard target != order else { return }
        withAnimation(Motion.crossfade, completionCriteria: .logicallyComplete) {
            pageVisible = false
        } completion: {
            var cut = Transaction()
            cut.disablesAnimations = true
            withTransaction(cut) { order = target }

            withAnimation(Motion.crossfade) { pageVisible = true }
        }
    }

    private func stepButton(_ mystery: Mystery, label: String, leading: Bool) -> some View {
        Button {
            step(to: mystery.order)
        } label: {
            VStack(alignment: leading ? .leading : .trailing, spacing: 5) {
                HStack(spacing: 5) {
                    if leading { AppIcon("ph-caret-left", size: 8) }
                    Text(label.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(1.8)
                    if !leading { AppIcon("ph-caret-right", size: 8) }
                }
                .foregroundColor(AppColors.gold.opacity(0.75))

                Text(mystery.name)
                    .font(AppFonts.readingFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.88))
                    .multilineTextAlignment(leading ? .leading : .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: leading ? .leading : .trailing)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(mystery.name)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MysteriesInScriptureView()
    }
    .environment(AppRouter())
}
