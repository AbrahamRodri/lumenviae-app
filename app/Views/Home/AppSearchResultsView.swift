//
//  AppSearchResultsView.swift
//  Lumen Viae
//
//  What the one search found, drawn as the "one app search" design's
//  option E (Oct 2026): the best match in the leading kind as a painted
//  card with its own act (Pray or Listen), then a section per kind, the
//  leading kind's first. `AppSearchChips` stands over the scroll under
//  the field; a chip scrolls to its section and the chip of the section
//  being read is lit. The chips never filter.
//
//  The finding and the order are `AppSearch`'s; this file only draws.
//

import SwiftUI

// MARK: - The results

struct AppSearchResultsView: View {
    let results: AppSearch.Results

    /// The day the search was made for, whose names the orders go by
    private var date: Date { results.date }

    /// What a found door of the app opens, by its `AppSearch.Page` id
    let openPage: (String) -> Void

    @Environment(AppRouter.self) private var router

    /// How many of a kind are listed before the section says how many more
    static let rowLimit = 12

    /// The best card's scroll id; a section's is its kind's raw value.
    /// The page's scroll position is one of these, which is how a chip
    /// jumps and how the chip of the section being read is lit.
    static let bestID = AppSearch.Results.bestScrollID

    /// The kind a scroll id stands for
    static func kind(ofScrollID id: String?, in results: AppSearch.Results) -> AppSearch.Kind? {
        guard let id else { return nil }
        if id == bestID { return results.best?.kind }
        return AppSearch.Kind(rawValue: id)
    }

    /// Where a chip scrolls to: the best card for its kind, else its section
    static func scrollID(of kind: AppSearch.Kind, in results: AppSearch.Results) -> String {
        results.best?.kind == kind ? bestID : kind.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            if let best = results.best {
                AppSearchBestCard(hit: best, date: date, open: { open(best) })
                    .id(Self.bestID)
            }

            ForEach(results.sections) { section in
                sectionView(section)
                    .id(section.kind.rawValue)
            }
        }
        // The card and the sections are the scroll's targets
        .scrollTargetLayout()
    }

    private func sectionView(_ section: AppSearch.Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            AppSearchSectionHeading(title: section.kind.title)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(section.hits.prefix(Self.rowLimit)) { hit in
                    row(hit)
                }
            }

            if section.hits.count > Self.rowLimit {
                Text("And \(section.hits.count - Self.rowLimit) more. Add a word to narrow the search.")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: Rows

    @ViewBuilder
    private func row(_ hit: AppSearch.Hit) -> some View {
        switch hit {
        case .prayer(let prayer):
            PrayersPictureRow(
                prayer: prayer,
                painting: BookPrayerView.painting(of: prayer.id),
                note: Self.note(for: prayer)
            ) { open(hit) }
        case .chant(let chant):
            ChantLibraryRow(chant: chant, player: ChantPlayer.shared) { open(hit) }
        case .topic(let chapter):
            AppSearchPictureRow(
                title: chapter.topic,
                note: PrayerBookView.prayerCount(chapter.prayerIDs.count),
                picture: .painting(PrayerBookPainting.topic(chapter))
            ) { open(hit) }
        case .order(let order):
            AppSearchPictureRow(
                title: order.title(on: date),
                note: order.occasion,
                picture: .painting(PrayerOrderView.painting(of: order, on: date))
            ) { open(hit) }
        case .mysteries(let category):
            AppSearchPictureRow(
                title: category.devotionTitle,
                note: category.subtitle,
                picture: .asset(category.cardImageName, focal: category.cardFocalPoint)
            ) { open(hit) }
        case .mystery(let mystery):
            AppSearchPictureRow(
                title: mystery.name,
                note: mystery.mysteryCategory?.devotionTitle,
                picture: Self.picture(of: mystery)
            ) { open(hit) }
        case .reading(let shelf, let reading):
            LedgerDoorRow(title: reading.title, note: reading.detail, icon: shelf.icon) { open(hit) }
        case .page(let page):
            LedgerDoorRow(title: page.title, note: nil, icon: page.icon) { open(hit) }
        case .meditationSet(let summary):
            LedgerDoorRow(title: summary.name, note: Self.note(for: summary), icon: "ph-cards") { open(hit) }
        }
    }

    // MARK: Opening

    private func open(_ hit: AppSearch.Hit) {
        switch hit {
        case .prayer(let prayer): router.push(.devotionPrayer(id: prayer.id))
        case .chant(let chant): router.push(.chant(id: chant.id))
        case .topic(let chapter): router.push(.prayerBookChapter(id: chapter.id))
        case .order(let order): router.push(.prayerOrder(id: order.id))
        case .mysteries(let category): router.navigateToMeditationSelection(category: category)
        case .mystery(let mystery):
            if let category = mystery.mysteryCategory {
                router.navigateToMeditationSelection(category: category)
            }
        case .reading(_, let reading): router.push(.libraryReading(id: reading.id))
        case .page(let page): openPage(page.id)
        case .meditationSet(let summary): router.navigateToMeditationSetDetail(summary)
        }
    }

    // MARK: Words

    /// A prayer's line: its Latin name, else the topic it stands in
    static func note(for prayer: BookPrayer) -> String? {
        prayer.latinTitle ?? PrayerBook.homeChapter(of: prayer.id)?.title
    }

    static func note(for summary: MeditationSetSummary) -> String {
        let category = MysteryCategory(rawValue: summary.category)?.devotionTitle ?? summary.category
        // A set named for its author would read the same line twice
        if let author = summary.author, !author.isEmpty, author != summary.name {
            return "\(author) · \(category)"
        }
        return category
    }

    static func picture(of mystery: Mystery) -> AppSearchPicture {
        if let name = Constants.mysteryImageURL(category: mystery.category, index: mystery.order - 1) {
            return .asset(name, focal: nil)
        }
        if let category = mystery.mysteryCategory {
            return .asset(category.cardImageName, focal: category.cardFocalPoint)
        }
        return .none
    }
}

// MARK: - The best match

/// The one card above the sections: the painting at its leading edge,
/// what kind of thing it is, its name in the display face, a line, and
/// its act — PRAY in an outlined capsule for a prayer or an order, the
/// chant library's play disc with LISTEN for a chant. The card itself
/// opens the thing's page; outlined, since the page's one filled gold
/// act is nobody's here.
struct AppSearchBestCard: View {
    let hit: AppSearch.Hit
    let date: Date
    let open: () -> Void

    @Environment(AppRouter.self) private var router
    private var player = ChantPlayer.shared

    init(hit: AppSearch.Hit, date: Date, open: @escaping () -> Void) {
        self.hit = hit
        self.date = date
        self.open = open
    }

    /// Whether the card carries an act of its own beside the door
    private var hasAct: Bool {
        switch hit {
        case .prayer, .order, .chant: return true
        default: return false
        }
    }

    /// The card is one door, its painting and words a single button
    /// VoiceOver reads as "Best match: …"; PRAY or the play disc stands
    /// over its foot as a control of its own, in room the door keeps
    /// for it
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Button(action: open) { face }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(["Best match: \(title)", kicker, line].compactMap { $0 }.joined(separator: ", "))
                .accessibilityAddTraits(.isButton)

            if hasAct {
                act
                    .padding(.leading, 118 + 14)
                    .padding(.bottom, 12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                .allowsHitTesting(false)
        )
    }

    private var face: some View {
        HStack(spacing: 0) {
            // The text sets the card's height; the painting fills it
            Color.clear
                .frame(width: 118)
                .overlay { picture }
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(kicker.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.8)
                    .foregroundColor(AppColors.gold.opacity(0.85))
                    .lineLimit(1)

                Text(title)
                    .font(AppFonts.titleFont(20))
                    .foregroundColor(AppColors.cream)
                    .fixedSize(horizontal: false, vertical: true)

                if let line {
                    Text(line)
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // The act's room: it stands over this, outside the door
                if hasAct {
                    Color.clear.frame(height: 44)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 140)
        .background(AppColors.cardBackground)
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: Parts

    /// The painting at the card's leading edge, from a copy made for the
    /// height the words give the card
    private var picture: some View {
        GeometryReader { proxy in
            picture(size: proxy.size)
        }
    }

    @ViewBuilder
    private func picture(size: CGSize) -> some View {
        switch hit {
        case .prayer(let prayer):
            AppSearchPicture.painting(BookPrayerView.painting(of: prayer.id)).view(size: size)
        case .topic(let chapter):
            AppSearchPicture.painting(PrayerBookPainting.topic(chapter)).view(size: size)
        case .order(let order):
            AppSearchPicture.painting(PrayerOrderView.painting(of: order, on: date)).view(size: size)
        case .chant(let chant):
            AppSearchPicture.asset(ChantCatalog.painting(for: chant), focal: nil).view(size: size)
        case .mysteries(let category):
            AppSearchPicture.asset(category.cardImageName, focal: category.cardFocalPoint).view(size: size)
        case .mystery(let mystery):
            AppSearchResultsView.picture(of: mystery).view(size: size)
        case .reading, .page, .meditationSet:
            ZStack {
                AppColors.backgroundDeep
                AppIcon(icon, size: 26)
                    .foregroundColor(AppColors.gold.opacity(0.8))
            }
        }
    }

    private var icon: String {
        switch hit {
        case .reading(let shelf, _): return shelf.icon
        case .page(let page): return page.icon
        default: return "ph-cards"
        }
    }

    private var kicker: String {
        switch hit {
        case .prayer(let prayer): return PrayerBook.homeChapter(of: prayer.id)?.title ?? "Prayer"
        case .topic: return "Topic"
        case .order: return "Prayers said together"
        case .chant(let chant): return chant.form.singular
        case .mysteries: return "Rosary Mysteries"
        case .mystery(let mystery): return mystery.mysteryCategory?.devotionTitle ?? "Mystery"
        case .reading(let shelf, _): return shelf.title
        case .page: return "Page"
        case .meditationSet: return "Meditation"
        }
    }

    private var title: String {
        switch hit {
        case .prayer(let prayer): return prayer.listTitle
        case .topic(let chapter): return chapter.topic
        case .order(let order): return order.title(on: date)
        case .chant(let chant): return chant.latinTitle
        case .mysteries(let category): return category.devotionTitle
        case .mystery(let mystery): return mystery.name
        case .reading(_, let reading): return reading.title
        case .page(let page): return page.title
        case .meditationSet(let summary): return summary.name
        }
    }

    private var line: String? {
        switch hit {
        case .prayer(let prayer): return prayer.latinTitle
        case .topic(let chapter): return PrayerBookView.prayerCount(chapter.prayerIDs.count)
        case .order(let order): return order.occasion
        // The setting where neither title says it, as the rows beneath
        // say theirs: the two Salve Reginas are told apart
        case .chant(let chant):
            return [chant.englishTitle, chant.settingMidLine, chant.durationLabel].compactMap { $0 }
                .joined(separator: " · ")
        case .mysteries(let category): return category.subtitle
        case .mystery: return nil
        case .reading(_, let reading): return reading.detail
        case .page: return nil
        case .meditationSet(let summary): return AppSearchResultsView.note(for: summary)
        }
    }

    @ViewBuilder
    private var act: some View {
        switch hit {
        case .prayer(let prayer):
            prayButton { router.push(.prayAlong(.prayer(prayer))) }
        case .order(let order):
            prayButton { router.push(.prayAlong(.order(order, on: date))) }
        case .chant(let chant):
            HStack(spacing: 10) {
                ChantPlayDisc(
                    isPlaying: player.isPlaying(chant),
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 34,
                    label: chant.spokenNameAndSetting
                ) {
                    player.toggle(chant)
                }
                // The word is the disc's too: a tap on it plays, where it
                // once fell on nothing. VoiceOver has the disc.
                Button {
                    player.toggle(chant)
                } label: {
                    Text(player.isPlaying(chant) ? "PAUSE" : "LISTEN")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityHidden(true)
            }
        default:
            EmptyView()
        }
    }

    private func prayButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("PRAY")
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .padding(.horizontal, 16)
                .frame(height: 34)
                .overlay(Capsule().strokeBorder(AppColors.gold, lineWidth: 1))
                .frame(minHeight: 44)
                .contentShape(Capsule())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("Pray \(title)")
    }
}

// MARK: - The chips

/// The kinds found, each with its count, under the field. A tap scrolls
/// to that kind's section; the lit chip is the section being read. They
/// never hide anything, so there is no All.
struct AppSearchChips: View {
    let results: AppSearch.Results
    let active: AppSearch.Kind?
    let jump: (AppSearch.Kind) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(results.kinds) { kind in
                    chip(kind)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }

    private func chip(_ kind: AppSearch.Kind) -> some View {
        let lit = kind == active
        let count = results.count(of: kind)
        return Button {
            jump(kind)
        } label: {
            HStack(spacing: 6) {
                Text(kind.chipTitle)
                    .font(AppFonts.readingFont(15))
                    .foregroundColor(lit ? AppColors.cream : AppColors.cream.opacity(0.8))
                Text("\(count)")
                    .font(AppFonts.labelFont(10))
                    .foregroundColor(lit ? AppColors.gold : AppColors.textSecondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 13)
            .frame(height: 32)
            .background(Capsule().fill(AppColors.gold.opacity(lit ? 0.12 : 0)))
            .overlay(
                Capsule().strokeBorder(AppColors.gold.opacity(lit ? 0.9 : 0.22), lineWidth: lit ? 1 : AppLine.hairline)
            )
            .frame(minHeight: 44)
            .contentShape(Capsule())
        }
        .buttonStyle(SacredCardButtonStyle())
        .animation(Motion.crossfade, value: lit)
        .accessibilityLabel("\(kind.title), \(count)")
        .accessibilityHint("Scrolls to them")
        .accessibilityAddTraits(lit ? .isSelected : [])
    }
}

// MARK: - Pieces

/// A small square picture: a Prayer Book painting, an asset by name, or
/// nothing. Drawn from a copy made for its frame (`ThumbnailImage`), so a
/// search never keeps a painting whole.
enum AppSearchPicture {
    case painting(PrayerBookPainting)
    case asset(String, focal: UnitPoint?)
    case none

    @ViewBuilder
    func view(size: CGSize) -> some View {
        switch self {
        case .painting(let painting):
            ThumbnailImage(name: painting.resolvedAsset, focal: painting.focal, size: size)
        case .asset(let name, let focal):
            ThumbnailImage(name: name, focal: focal ?? .center, size: size)
        case .none:
            AppColors.backgroundDeep
        }
    }
}

/// A found thing with a picture: the picture, its name, a line, a caret
struct AppSearchPictureRow: View {
    let title: String
    let note: String?
    let picture: AppSearchPicture
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 13) {
                    picture.view(size: CGSize(width: 44, height: 44))
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                        )
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(AppColors.cream)
                            .lineLimit(2)
                        if let note {
                            Text(note)
                                .font(AppFonts.readingItalicFont(13.5))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    AppIcon("ph-caret-right", size: 12)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                }
                .padding(.vertical, 8)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.12))
                    .frame(height: AppLine.hairline)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel([title, note].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
    }
}

/// A section's heading: its name in small gold capitals over a rule
struct AppSearchSectionHeading: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.8))
            Rectangle()
                .fill(AppColors.gold.opacity(0.18))
                .frame(height: AppLine.hairline)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - The field's words

extension AppSearch.Origin {
    /// What the empty field says: where the search starts
    var prompt: String {
        switch self {
        case .everywhere: return "Search prayers, mysteries, books and chant"
        case .prayers: return "Search, starting with prayers"
        case .chant: return "Search, starting with chant"
        }
    }
}

// MARK: - A page's head with the glass

/// The head the Prayers and Chant pages share: the page's name in the
/// display face over its count, centred, and the glass at the trailing
/// edge on a dark disc, opening the app's one search with this page's
/// kind leading
struct PageSearchHead: View {
    let title: String
    let count: String
    let origin: AppSearch.Origin
    let hint: String

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            VStack(spacing: 1) {
                Text(title)
                    .font(AppFonts.titleFont(24))
                    .foregroundColor(AppColors.cream)
                Text(count)
                    .font(AppFonts.readingItalicFont(13.5))
                    .foregroundColor(AppColors.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            HStack {
                Spacer()
                Button {
                    router.push(.search(from: origin))
                } label: {
                    AppIcon("ph-magnifying-glass", size: 18)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(AppColors.cardBackground))
                        .contentShape(Circle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("Search")
                .accessibilityHint(hint)
            }
        }
        .frame(minHeight: 52)
    }
}
