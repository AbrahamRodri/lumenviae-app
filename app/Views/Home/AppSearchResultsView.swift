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
    let query: String

    /// What a found door of the app opens, by its `AppSearch.Page` id
    let openPage: (String) -> Void

    /// Tells the page where each section's top stands in the scroll, so
    /// the chip of the section being read can be lit
    let onSectionTop: (AppSearch.Kind, CGFloat) -> Void

    @Environment(AppRouter.self) private var router

    /// How many of a kind are listed before the section says how many more
    static let rowLimit = 12

    /// The scroll's coordinate space, which the section tops are read in
    static let space = "appSearch"

    /// The best card's scroll id; a section's is its kind's raw value
    static let bestID = "best"

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            if let best = results.best {
                AppSearchBestCard(hit: best, open: { open(best) })
                    .id(Self.bestID)
                    .reportsTop(of: best.kind, to: onSectionTop)
            }

            ForEach(results.sections) { section in
                sectionView(section)
                    .id(section.kind.rawValue)
                    // A section whose kind the best card belongs to is
                    // reached through the card, which stands above it
                    .reportsTop(of: section.kind, to: results.best?.kind == section.kind ? { _, _ in } : onSectionTop)
            }
        }
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
                title: order.title(on: Date()),
                note: order.occasion,
                picture: .painting(PrayerOrderView.painting(of: order, on: Date()))
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

// MARK: - Section tops

extension View {
    /// Reports this view's top in the search's scroll, for the lit chip
    fileprivate func reportsTop(of kind: AppSearch.Kind, to report: @escaping (AppSearch.Kind, CGFloat) -> Void)
        -> some View
    {
        onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .named(AppSearchResultsView.space)).minY
        } action: { top in
            report(kind, top)
        }
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
    let open: () -> Void

    @Environment(AppRouter.self) private var router
    private var player = ChantPlayer.shared

    init(hit: AppSearch.Hit, open: @escaping () -> Void) {
        self.hit = hit
        self.open = open
    }

    var body: some View {
        HStack(spacing: 0) {
            picture
                .frame(width: 118)
                .frame(maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)

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

                act
                    .padding(.top, 6)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 140)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture(perform: open)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Best match: \(title)")
        .accessibilityAction(named: "Open", open)
    }

    // MARK: Parts

    @ViewBuilder
    private var picture: some View {
        switch hit {
        case .prayer(let prayer):
            AppSearchPicture.painting(BookPrayerView.painting(of: prayer.id)).view
        case .topic(let chapter):
            AppSearchPicture.painting(PrayerBookPainting.topic(chapter)).view
        case .order(let order):
            AppSearchPicture.painting(PrayerOrderView.painting(of: order, on: Date())).view
        case .chant(let chant):
            AppSearchPicture.asset(ChantCatalog.painting(for: chant), focal: nil).view
        case .mysteries(let category):
            AppSearchPicture.asset(category.cardImageName, focal: category.cardFocalPoint).view
        case .mystery(let mystery):
            AppSearchResultsView.picture(of: mystery).view
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
        case .order(let order): return order.title(on: Date())
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
        case .chant(let chant): return "\(chant.englishTitle) · \(chant.durationLabel)"
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
            prayButton { router.push(.prayAlong(.order(order))) }
        case .chant(let chant):
            HStack(spacing: 10) {
                ChantPlayDisc(
                    isPlaying: player.isPlaying(chant),
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 34,
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
/// nothing
enum AppSearchPicture {
    case painting(PrayerBookPainting)
    case asset(String, focal: UnitPoint?)
    case none

    @ViewBuilder
    var view: some View {
        switch self {
        case .painting(let painting):
            CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
        case .asset(let name, let focal):
            CachedAssetImage(name, focal: focal)
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
                    picture.view
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
