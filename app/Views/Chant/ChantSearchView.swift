//
//  ChantSearchView.swift
//  Lumen Viae
//
//  Search across the Chant Library: a chant's titles in Latin and in
//  English, the words it sings, and the prayer it is a sung form of —
//  accents and case aside, so "caeli" finds Cæli. Titles come back as one
//  result for each work, its settings a pill (the simple and the solemn
//  Salve Regina), the best match first as a card with its painting; the
//  words come back as the line they stand in, with the place in the
//  recording when the chant's lines have been timed, and none when they
//  have not. Every hit opens the chant's page; only the play disc beside
//  it sings it where it stands (`ChantTap`).
//
//  Before anything is typed the page offers three searches to try, each
//  one a way of searching, over tonight's song to Mary. Where to search
//  and the filters wait behind REFINE, and what is chosen there stands
//  under the field as chips that come off with a tap.
//
//  It stands in the library's place while it is open, its field at the
//  head and Cancel beside it.
//

import SwiftUI

struct ChantSearchView: View {

    let close: () -> Void
    let open: (Chant) -> Void

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    enum Scope: String, CaseIterable, Identifiable {
        case all, titles, words, prayers
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all:     return "All"
            case .titles:  return "Names"
            case .words:   return "Words"
            case .prayers: return "Prayers"
            }
        }
    }

    /// A search to try before typing: what is typed, and the way of
    /// searching it shows. The third stands for the accent note the page
    /// once printed under every state.
    struct Example: Hashable {
        let query: String
        let note: String
    }

    static let examples = [
        Example(query: "Ave Maris Stella", note: "a name"),
        Example(query: "spes nostra", note: "a line it sings"),
        Example(query: "regina caeli", note: "no accents needed")
    ]

    @State private var query: String
    @State private var scope: Scope = .all
    @State private var inSeason = false
    @State private var short = false
    @State private var stillToLearn = false
    @State private var form: ChantForm?
    @State private var chosenSettings: [String: String] = [:]
    @State private var showsAllWords = false
    @State private var refining = false
    @FocusState private var focused: Bool

    /// Shown on the Chant tab, where the last rows must clear the tab bar
    private let isTabRoot: Bool
    /// The day the seasons are read against; fixed only for snapshots
    private let today: Date

    init(
        isTabRoot: Bool = false,
        today: Date = Date(),
        query: String = "",
        close: @escaping () -> Void,
        open: @escaping (Chant) -> Void
    ) {
        self.isTabRoot = isTabRoot
        self.today = today
        self._query = State(initialValue: query)
        self.close = close
        self.open = open
    }

    private var needle: String { ChantSearch.fold(query.trimmingCharacters(in: .whitespaces)) }

    var body: some View {
        VStack(spacing: 0) {
            field
                .padding(.horizontal, 12)
                .padding(.top, 4)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    if filterCount > 0 {
                        chosenFilters
                    }

                    results
                        .padding(.horizontal, 20)
                }
                .padding(.top, 14)
                .padding(.bottom, isTabRoot ? 130 : 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear { focused = true }
        .onChange(of: query) { _, _ in showsAllWords = false }
        .sheet(isPresented: $refining) {
            ChantRefineSheet(
                scope: $scope,
                inSeason: $inSeason,
                short: $short,
                stillToLearn: $stillToLearn,
                form: $form
            )
            .fittedSheetDetent(estimate: 480)
            .sheetGround()
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }

    // MARK: - Field

    private var field: some View {
        HStack(spacing: 8) {
            HStack(spacing: 10) {
                AppIcon("ph-magnifying-glass", size: 17)
                    .foregroundColor(AppColors.gold)
                TextField("", text: $query, prompt: Text("Search the Chant Library").foregroundColor(AppColors.textSecondary))
                    .font(AppFonts.bodyFont(17))
                    .foregroundColor(AppColors.cream)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .focused($focused)
                    .accessibilityLabel("Search the Chant Library")
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        AppIcon("ph-x", size: 13)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Clear")
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 4)
            .frame(height: 46)
            .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.backgroundDeep))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: AppLine.hairline)
            )

            Button {
                focused = false
                close()
            } label: {
                Text("Cancel")
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.gold)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
        }
    }

    // MARK: - Filters

    private var filterCount: Int {
        [scope != .all, inSeason, short, stillToLearn, form != nil].filter { $0 }.count
    }

    private var filtering: Bool { inSeason || short || stillToLearn || form != nil }

    private func passes(_ chant: Chant) -> Bool {
        if form != nil, chant.form != form { return false }
        if short, chant.duration >= 180 { return false }
        if stillToLearn, shelf.isLearned(chant.id) { return false }
        if inSeason, !chant.seasons.contains(ChantSeason.season(on: today)) { return false }
        return true
    }

    /// What REFINE chose, each a chip that a tap takes off
    private var chosenFilters: some View {
        ChantSideScroll {
            HStack(spacing: 8) {
                if scope != .all {
                    chip("\(scope.title) only") { scope = .all }
                }
                if let form {
                    chip(form.title) { self.form = nil }
                }
                if inSeason {
                    chip("This season") { inSeason = false }
                }
                if short {
                    chip("Under 3 min") { short = false }
                }
                if stillToLearn {
                    chip("Still to learn") { stillToLearn = false }
                }
            }
            .padding(.horizontal, 20)
        }
        .transition(.opacity)
    }

    private func chip(_ title: String, remove: @escaping () -> Void) -> some View {
        Button {
            withAnimation(Motion.crossfade) { remove() }
        } label: {
            HStack(spacing: 7) {
                Text(title)
                    .font(AppFonts.readingFont(14))
                    .lineLimit(1)
                    .fixedSize()
                AppIcon("ph-x", size: 10)
            }
            .foregroundColor(AppColors.goldLight)
            .padding(.horizontal, 13)
            .frame(height: 34)
            .background(Capsule().fill(AppColors.gold.opacity(0.16)))
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.6), lineWidth: AppLine.hairline))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("Remove filter: \(title)")
    }

    /// The one door to where to search and the filters. Lit, and counting
    /// them, while any is on.
    private var refineButton: some View {
        Button {
            focused = false
            refining = true
        } label: {
            Text(filterCount > 0 ? "REFINE · \(filterCount)" : "REFINE")
                .font(AppFonts.labelFont(9.5))
                .tracking(2)
                .foregroundColor(filterCount > 0 ? AppColors.goldLight : AppColors.gold)
                .frame(minHeight: 44)
                .padding(.leading, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("Refine the search")
        .accessibilityValue(filterCount == 0 ? "No filters" : filterCount == 1 ? "1 filter on" : "\(filterCount) filters on")
        .accessibilityHint("Search in names, words or prayers, and filter by season, length or kind")
    }

    /// A line of the page with REFINE at its trailing edge
    private func headLine<Leading: View>(@ViewBuilder _ leading: () -> Leading) -> some View {
        HStack(alignment: .center) {
            leading()
            Spacer(minLength: 8)
            refineButton
        }
    }

    // MARK: - Results

    /// What stands under the field: the searches to try before anything is
    /// asked, a line saying nothing matched, or what did
    private enum ResultsState: Hashable {
        case start, nothing, found
    }

    /// The three share one slot and crossfade over one another, never
    /// laid out one above the other while they fade
    private var results: some View {
        let asking = !needle.isEmpty || filtering
        let titleWorks = asking && (scope == .all || scope == .titles)
            ? ChantSearch.works(matching: needle, where: passes) : []
        let prayerWorks = asking && (scope == .all || scope == .prayers)
            ? ChantSearch.works(singingPrayerMatching: needle, where: passes)
                .filter { work in !titleWorks.contains { $0.key == work.key } }
            : []
        let wordHits = asking && (scope == .all || scope == .words) && !needle.isEmpty
            ? ChantSearch.wordHits(matching: needle, where: passes) : []
        let state: ResultsState = !asking ? .start
            : titleWorks.isEmpty && prayerWorks.isEmpty && wordHits.isEmpty ? .nothing
            : .found

        return ZStack(alignment: .topLeading) {
            switch state {
            case .start:
                start
                    .transition(.opacity)
            case .nothing:
                nothing
                    .transition(.opacity)
            case .found:
                found(titleWorks: titleWorks, prayerWorks: prayerWorks, wordHits: wordHits)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.crossfade, value: state)
    }

    // MARK: - Before typing

    /// The searches to try stand first, so they are above the keyboard
    /// that opens with the page; tonight's song to Mary is beneath them.
    private var start: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 0) {
                headLine {
                    Text("TRY")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityLabel("Searches to try")
                }
                ForEach(Self.examples, id: \.self) { example in
                    exampleRow(example)
                }
            }

            if let chant = ChantCatalog.antiphonOfTheSeason(on: today) {
                tonight(chant)
            }
        }
    }

    private func exampleRow(_ example: Example) -> some View {
        Button {
            focused = false
            scope = .all
            query = example.query
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(example.query)
                    .font(AppFonts.readingFont(18))
                    .foregroundColor(AppColors.cream)
                Spacer(minLength: 8)
                Text(example.note)
                    .font(AppFonts.readingItalicFont(13.5))
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Search for \(example.query), \(example.note)")
        .accessibilityAddTraits(.isButton)
    }

    /// Tonight's song to Mary, its painting dissolving into the page with
    /// its names on the painting's foot. The painting opens the chant; the
    /// disc sings it.
    private func tonight(_ chant: Chant) -> some View {
        let painting = ChantLibraryView.tonightPainting(for: chant)
        return Button {
            open(chant)
        } label: {
            ZStack(alignment: .bottomLeading) {
            CachedAssetImage(painting, focal: ChantThumbnail.focalPoint(for: painting))
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .clipped()
                // Dark under the names, so they read on any painting
                .overlay(
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.backgroundDeep.opacity(0), location: 0.3),
                            .init(color: AppColors.backgroundDeep.opacity(0.72), location: 0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // Dissolving into the page above and below, never cut
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0), location: 0),
                            .init(color: .black, location: 0.16),
                            .init(color: .black, location: 0.62),
                            .init(color: .black.opacity(0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.horizontal, -20)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("TONIGHT'S SONG TO MARY")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                    Text(chant.latinTitle)
                        .font(AppFonts.titleFont(24))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(chant.englishTitle) · \(chant.durationLabel)")
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.cream.opacity(0.78))
                        .lineLimit(1)
                    // The room LISTEN stands in, laid over the button
                    Color.clear
                        .frame(height: Self.listenHeight)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tonight's song to Mary: \(chant.spokenName), \(ChantPlayer.spoken(chant.duration))")
        .accessibilityHint("Opens the chant")
        .accessibilityAddTraits(.isButton)
        .overlay(alignment: .bottomLeading) {
            listen(chant)
                .padding(.horizontal, 2)
        }
        .chantContextMenu(chant)
    }

    /// The height of the disc and LISTEN beside it
    private static let listenHeight: CGFloat = 44

    /// The disc and the word beside it: LISTEN, or PAUSE while it sounds
    private func listen(_ chant: Chant) -> some View {
        HStack(spacing: 8) {
            ChantPlayDisc(
                isPlaying: player.isPlaying(chant),
                isLoading: player.current.id == chant.id && player.isLoading,
                size: 30,
                label: chant.spokenName
            ) {
                player.toggle(chant)
            }
            Text(player.isPlaying(chant) ? "PAUSE" : "LISTEN")
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .accessibilityHidden(true)
        }
        .frame(height: Self.listenHeight)
    }

    // MARK: - Nothing found

    /// One line, then the kinds of chant as a way on: a kind opens every
    /// chant of it, the search let go
    private var nothing: some View {
        VStack(alignment: .leading, spacing: 22) {
            headLine {
                Text(needle.isEmpty ? "No chant fits every filter chosen." : "Nothing in the library matches “\(query)”.")
                    .font(AppFonts.readingItalicFont(16.5))
                    .foregroundColor(AppColors.cream.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 0) {
                groupHeading("Kinds of chant")
                ForEach(ChantForm.allCases) { kind in
                    kindRow(kind)
                }
            }
        }
    }

    /// The painting a kind is shown with, chosen here for the page
    static func painting(for kind: ChantForm) -> String {
        switch kind {
        case .shortChant:     return "glorious_assumption"
        case .hymn:           return "glorious_pentecost"
        case .sequence:       return "glorious_resurrection"
        case .litany:         return "glorious_coronation"
        case .psalm:          return "joyful_nativity"
        case .everydayPrayer: return "joyful_annunciation"
        }
    }

    private func kindRow(_ kind: ChantForm) -> some View {
        let count = ChantCatalog.all.filter { $0.form == kind }.count
        return Button {
            focused = false
            query = ""
            scope = .all
            inSeason = false
            short = false
            stillToLearn = false
            form = kind
        } label: {
            HStack(spacing: 12) {
                ChantThumbnail(name: Self.painting(for: kind), size: 40, radius: 20)
                Text(kind.title)
                    .font(AppFonts.readingFont(17))
                    .foregroundColor(AppColors.cream)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(count)")
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                AppIcon("ph-caret-right", size: 10)
                    .foregroundColor(AppColors.gold.opacity(0.4))
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.title), \(count == 1 ? "1 chant" : "\(count) chants")")
        .accessibilityHint("Shows every chant of this kind")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Found

    private func found(
        titleWorks: [ChantSearch.Work],
        prayerWorks: [ChantSearch.Work],
        wordHits: [ChantSearch.WordHit]
    ) -> some View {
        // The chants sung now first, then those of every season, then the
        // rest; the row's own line says when each is sung
        let season = ChantSeason.season(on: today)
        let titles = titleWorks.filter { $0.chants[0].seasons.contains(season) }
            + titleWorks.filter { $0.chants[0].seasons.isEmpty }
            + titleWorks.filter { !$0.chants[0].seasons.isEmpty && !$0.chants[0].seasons.contains(season) }
        let top = titles.first ?? prayerWorks.first
        let restTitles = titles.filter { $0.key != top?.key }
        let restPrayers = prayerWorks.filter { $0.key != top?.key }
        let works = titleWorks.count + prayerWorks.count

        return VStack(alignment: .leading, spacing: 26) {
            headLine {
                Text(summary(works: works, lines: wordHits.count))
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.72))
            }
            .padding(.bottom, -14)

            if let top {
                topResult(top, singsPrayer: titles.isEmpty)
            }
            if !restTitles.isEmpty {
                workGroup("Chants", restTitles)
            }
            if !restPrayers.isEmpty {
                workGroup("Sung prayers", restPrayers)
            }
            if !wordHits.isEmpty {
                wordGroup(wordHits)
            }
        }
    }

    private func summary(works: Int, lines: Int) -> String {
        var parts: [String] = []
        if works > 0 { parts.append(works == 1 ? "1 chant" : "\(works) chants") }
        if lines > 0 { parts.append(lines == 1 ? "1 line" : "\(lines) lines") }
        return parts.joined(separator: " · ")
    }

    private func groupHeading(_ title: String) -> some View {
        Text(title.uppercased())
            .font(AppFonts.labelFont(9))
            .tracking(2)
            .foregroundColor(AppColors.gold)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
            .overlay(alignment: .bottom) { ChantRule() }
    }

    private func chosen(in work: ChantSearch.Work) -> Chant {
        work.chants.first { $0.id == chosenSettings[work.key] } ?? work.chants[0]
    }

    private func choose(_ setting: Chant, in work: ChantSearch.Work) {
        let wasSounding = player.isPlaying(chosen(in: work))
        chosenSettings[work.key] = setting.id
        if wasSounding { player.play(setting) }
    }

    // MARK: - The best match

    /// The best match as a card: its painting, its kind and when it is
    /// sung, its names, and LISTEN; its settings in a pill beneath
    private func topResult(_ work: ChantSearch.Work, singsPrayer: Bool) -> some View {
        let chant = chosen(in: work)
        let kicker = [
            chant.form.singular,
            singsPrayer ? chant.bookPrayer.map { "sings \($0.title)" } : nil
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
        let line = [chant.englishTitle, work.chants.count == 1 ? chant.settingMidLine : nil, chant.seasonLine(on: today)]
            .compactMap { $0 }
            .joined(separator: " · ")

        return VStack(alignment: .leading, spacing: 10) {
            Button {
                open(chant)
            } label: {
                HStack(spacing: 0) {
                    ChantThumbnail(name: ChantCatalog.painting(for: chant), size: 132, radius: 0)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(kicker.uppercased())
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1.6)
                            .foregroundColor(AppColors.gold)
                            .lineLimit(2)
                        Text(ChantSearch.highlighted(chant.latinTitle, needle: needle))
                            .font(AppFonts.titleFont(19))
                            .foregroundColor(player.isPlaying(chant) ? AppColors.goldLight : AppColors.cream)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Text(ChantSearch.highlighted(line, needle: needle))
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                        // The room LISTEN stands in, laid over the button
                        Color.clear
                            .frame(height: Self.listenHeight)
                    }
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 132)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: AppLine.hairline)
                )
                .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            // Plain, so the disc laid over it never stands still while the card presses
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Best match: \(chant.latinTitle), \(line), \(kicker)")
            .accessibilityHint("Opens the chant")
            .accessibilityAddTraits(.isButton)
            .overlay(alignment: .bottomLeading) {
                listen(chant)
                    .padding(.leading, 132 + 14)
                    .padding(.bottom, 8)
            }
            .chantContextMenu(chant)

            if work.chants.count > 1 {
                ChantSettingPill(settings: work.chants, selected: chant.id) { choose($0, in: work) }
            }
        }
    }

    // MARK: - Works

    private func workGroup(_ title: String, _ works: [ChantSearch.Work]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            groupHeading(title)
            ForEach(works, id: \.key) { work in
                workRow(work)
            }
        }
    }

    private func workRow(_ work: ChantSearch.Work) -> some View {
        let chant = chosen(in: work)
        let when = chant.seasonLine(on: today)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    open(chant)
                } label: {
                    HStack(spacing: 12) {
                        ChantThumbnail(name: ChantCatalog.painting(for: chant), size: 48, radius: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ChantSearch.highlighted(chant.latinTitle, needle: needle))
                                .font(AppFonts.readingFont(17))
                                .foregroundColor(player.isPlaying(chant) ? AppColors.goldLight : AppColors.cream)
                            Text(ChantSearch.highlighted(
                                [chant.englishTitle, work.chants.count == 1 ? chant.settingMidLine : nil, when]
                                    .compactMap { $0 }
                                    .joined(separator: " · "),
                                needle: needle
                            ))
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens the chant")

                ChantPlayDisc(
                    isPlaying: player.isPlaying(chant),
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 34,
                    label: chant.spokenName
                ) {
                    player.toggle(chant)
                }
            }

            if work.chants.count > 1 {
                ChantSettingPill(settings: work.chants, selected: chant.id) { choose($0, in: work) }
                    .padding(.leading, 60)
            }
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
        .chantContextMenu(chant)
    }

    // MARK: - Words

    private func wordGroup(_ hits: [ChantSearch.WordHit]) -> some View {
        let shown = showsAllWords ? hits : Array(hits.prefix(3))
        return VStack(alignment: .leading, spacing: 0) {
            groupHeading("In the words")
            ForEach(shown) { hit in
                wordRow(hit)
            }
            if !showsAllWords, hits.count > 3 {
                Button {
                    withAnimation(Motion.crossfade) { showsAllWords = true }
                } label: {
                    Text("Show all \(hits.count)")
                        .font(AppFonts.readingFont(15))
                        .foregroundColor(AppColors.gold)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
            }
        }
    }

    /// A hit in the words opens the chant's page like every other row; it
    /// once sang the chant from that line as well, so a tap meant to read
    /// a chant started it sounding
    private func wordRow(_ hit: ChantSearch.WordHit) -> some View {
        Button {
            open(hit.chant)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ChantThumbnail(name: ChantCatalog.painting(for: hit.chant), size: 40, radius: 8)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text([hit.chant.latinTitle, ChantSearch.setting(of: hit)].compactMap { $0 }.joined(separator: " · "))
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(AppColors.cream)
                        Spacer(minLength: 8)
                        if let start = hit.start {
                            Text("AT \(ChantPlayer.clock(start))")
                                .font(AppFonts.labelFont(8.5))
                                .tracking(1)
                                .foregroundColor(AppColors.textSecondary)
                                .monospacedDigit()
                        }
                    }
                    Text(ChantSearch.highlighted(hit.snippet, needle: needle))
                        .font(AppFonts.readingFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.82))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 12)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(AppColors.gold.opacity(0.3))
                                .frame(width: 1)
                        }
                    Text(hit.chant.englishTitle)
                        .font(AppFonts.readingItalicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([
            hit.chant.latinTitle,
            ChantSearch.setting(of: hit),
            hit.start.map { "at \(ChantPlayer.spoken($0))" },
            hit.snippet,
            hit.chant.englishTitle
        ].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens the chant")
    }
}

// MARK: - ChantRefineSheet

/// Where to search, and the filters, in the sheet grammar: what the page
/// once set out above every result, kept behind REFINE
struct ChantRefineSheet: View {
    @Binding var scope: ChantSearchView.Scope
    @Binding var inSeason: Bool
    @Binding var short: Bool
    @Binding var stillToLearn: Bool
    @Binding var form: ChantForm?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(kicker: "Refine", title: "Narrow the search") {
                SheetHeaderAction(title: "Done") { dismiss() }
            }

            SheetSectionLabel("Search in")
            scopes
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.bottom, 12)

            SheetToggleRow(title: "This season", isOn: $inSeason)
            SheetToggleRow(title: "Under 3 minutes", isOn: $short)
            SheetToggleRow(title: "Still to learn", detail: "Leaves out the chants you have learned", isOn: $stillToLearn)

            Menu {
                Picker("Kind of chant", selection: $form) {
                    Text("Every kind").tag(ChantForm?.none)
                    ForEach(ChantForm.allCases) { each in
                        Text(each.title).tag(ChantForm?.some(each))
                    }
                }
            } label: {
                SheetRow("Kind of chant", showsDivider: false) {
                    HStack(spacing: 8) {
                        Text(form?.title ?? "Every kind")
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(form == nil ? AppColors.textSecondary : AppColors.goldLight)
                        AppIcon("ph-caret-right", size: 10)
                            .foregroundColor(AppColors.gold.opacity(0.4))
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kind of chant")
            .accessibilityValue(form?.title ?? "Every kind")
        }
        .padding(.bottom, 12)
    }

    /// All · Names · Words · Prayers, the lit one on a wash of gold
    private var scopes: some View {
        HStack(spacing: 4) {
            ForEach(ChantSearchView.Scope.allCases) { each in
                let lit = each == scope
                Button {
                    withAnimation(Motion.choice) { scope = each }
                } label: {
                    Text(each.title)
                        .font(AppFonts.readingFont(15))
                        .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Capsule().fill(lit ? AppColors.gold.opacity(0.18) : Color.clear))
                        .contentShape(Capsule())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityAddTraits(lit ? [.isSelected] : [])
            }
        }
        .padding(3)
        .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.25), lineWidth: AppLine.hairline))
        .frame(minHeight: 44)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search in")
        .sensoryFeedback(.selection, trigger: scope)
    }
}

// MARK: - ChantSearch

/// The library's search, apart from its page so it can be tested: the
/// folding, the grouping into works, the hits in the words, and the
/// highlighting.
enum ChantSearch {

    /// The chants of one work, its settings in the catalog's order
    struct Work {
        let key: String
        let chants: [Chant]
    }

    /// A match in a chant's words: the line it stands in, and where that
    /// line sounds when the chant's lines are timed
    struct WordHit: Identifiable {
        let id: String
        let chant: Chant
        let snippet: String
        /// The line's index in `Chant.lines`, for a timed chant
        let line: Int?
        let start: TimeInterval?
    }

    /// The setting a hit in the words was sung in, named where its work
    /// has more than one, as Titles names it with its pill: the simple
    /// and the solemn Salve Regina would otherwise give rows that read
    /// alike. A hit in the Prayer Book's text is the words of every
    /// setting, quoted once, and names none
    static func setting(of hit: WordHit) -> String? {
        guard hit.line != nil, hit.chant.settings.count > 1 else { return nil }
        return hit.chant.settingName
    }

    /// Case, accents and the ligatures aside: "Cæli" and "caeli" fold alike
    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "œ", with: "oe")
    }

    private static func group(_ chants: [Chant]) -> [Work] {
        var order: [String] = []
        var byKey: [String: [Chant]] = [:]
        for chant in chants {
            if byKey[chant.workKey] == nil { order.append(chant.workKey) }
            byKey[chant.workKey, default: []].append(chant)
        }
        return order.map { Work(key: $0, chants: byKey[$0] ?? []) }
    }

    /// Works whose Latin or English title holds `needle`, or every work
    /// when it is empty, the chants the filter passes
    static func works(matching needle: String, where passes: (Chant) -> Bool) -> [Work] {
        let chants = ChantCatalog.all.filter { chant in
            guard passes(chant) else { return false }
            guard !needle.isEmpty else { return true }
            return fold(chant.latinTitle).contains(needle) || fold(chant.englishTitle).contains(needle)
        }
        return group(chants)
    }

    /// Works that sing a prayer whose name, in the Prayer Book, holds
    /// `needle`: "glory be" finds the Gloria Patri
    static func works(singingPrayerMatching needle: String, where passes: (Chant) -> Bool) -> [Work] {
        guard !needle.isEmpty else { return [] }
        let chants = ChantCatalog.all.filter { chant in
            guard passes(chant), let prayer = chant.bookPrayer else { return false }
            return fold(prayer.title).contains(needle) || fold(prayer.latinTitle ?? "").contains(needle)
        }
        return group(chants)
    }

    /// Every line of every chant's words holding `needle`: a timed
    /// chant's own lines, with their place; else the lines of the Prayer
    /// Book's text, with none
    static func wordHits(matching needle: String, where passes: (Chant) -> Bool) -> [WordHit] {
        guard needle.count >= 3 else { return [] }
        var hits: [WordHit] = []
        var seenTexts = Set<String>()
        for chant in ChantCatalog.all where passes(chant) {
            if chant.hasLines {
                for (index, line) in chant.lines.enumerated() {
                    let latin = fold(line.latin).contains(needle)
                    let english = fold(line.english).contains(needle)
                    guard latin || english else { continue }
                    hits.append(WordHit(
                        id: "\(chant.id)#\(index)",
                        chant: chant,
                        snippet: latin ? line.latin : line.english,
                        line: index,
                        start: line.start
                    ))
                }
            } else if let prayer = chant.bookPrayer {
                // A prayer sung in two settings is quoted once, under the
                // first, rather than twice in the same words
                guard !seenTexts.contains(prayer.id) else { continue }
                let lines = ((prayer.latin ?? "") + "\n" + prayer.english).components(separatedBy: "\n")
                var found = false
                for (index, raw) in lines.enumerated() {
                    let text = clean(raw)
                    guard !text.isEmpty, fold(text).contains(needle) else { continue }
                    hits.append(WordHit(id: "\(chant.id)~\(index)", chant: chant, snippet: text, line: nil, start: nil))
                    found = true
                }
                if found { seenTexts.insert(prayer.id) }
            }
        }
        return hits
    }

    /// A line of the Prayer Book's grammar as plain words: the marks of
    /// versicle and response, the pointing and a rubric's brackets gone.
    /// Words in, words out, touching nothing else, so it is called from
    /// anywhere — a function reference to it included.
    nonisolated static func clean(_ line: String) -> String {
        var text = line
        for mark in ["℣.", "℟.", "℣", "℟", "✠", "|||"] {
            text = text.replacingOccurrences(of: mark, with: " ")
        }
        text = text.replacingOccurrences(of: " * ", with: " ")
        if text.hasPrefix("["), text.hasSuffix("]") { return "" }
        return text
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Where the folded `needle` stands in `text`, as ranges of the text
    /// as written: a match on "caeli" is the range of "Cæli"
    static func matches(in text: String, needle: String) -> [Range<String.Index>] {
        guard !needle.isEmpty else { return [] }

        // Each folded character remembers the character it came from
        var folded: [Character] = []
        var origin: [String.Index] = []
        for index in text.indices {
            for character in fold(String(text[index])) {
                folded.append(character)
                origin.append(index)
            }
        }
        let pattern = Array(needle)
        guard !pattern.isEmpty, folded.count >= pattern.count else { return [] }

        var ranges: [Range<String.Index>] = []
        var i = 0
        while i <= folded.count - pattern.count {
            if Array(folded[i..<(i + pattern.count)]) == pattern {
                let lower = origin[i]
                let upper = text.index(after: origin[i + pattern.count - 1])
                ranges.append(lower..<upper)
                i += pattern.count
            } else {
                i += 1
            }
        }
        return ranges
    }

    /// `text` with every match of the folded `needle` underlined in gold
    static func highlighted(_ text: String, needle: String) -> AttributedString {
        let ranges = matches(in: text, needle: needle)
        guard !ranges.isEmpty else { return AttributedString(text) }

        var result = AttributedString()
        var cursor = text.startIndex
        for range in ranges where range.lowerBound >= cursor {
            result += AttributedString(String(text[cursor..<range.lowerBound]))
            var match = AttributedString(String(text[range]))
            // Typed, so the attributes are SwiftUI's and not UIKit's
            match.foregroundColor = AppColors.goldLight as Color
            match.underlineStyle = Text.LineStyle(pattern: .solid)
            result += match
            cursor = range.upperBound
        }
        result += AttributedString(String(text[cursor...]))
        return result
    }
}
