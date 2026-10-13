//
//  ChantLibraryPages.swift
//  Lumen Viae
//
//  The pages the library's SEE ALL doors open (the "Chant shelf pages"
//  design, option B, Oct 2026). Both are pushed, with the gold Back in
//  the bar.
//
//    ALL CHANTS   the book's twelve sections as painted cards, two by
//                 six, each opening its own shelf (`.chantBrowse(.all)`)
//    A SHELF      a section, the Mass of the Angels or Songs to Mary,
//                 opening on its painting hung across the top: the name,
//                 when it is sung, how many chants and how long, an
//                 outlined PLAY ALL, then its chants in order
//                 (`.chantBrowse`)
//    SUNG SETS    the occasions and the reader's own sets as painted
//                 cards, then Make your own set (`.chantSets`)
//
//  A shelf's chants are rows of their names and length. Where they hang
//  paintings of their own (Songs to Mary, the seasons) each row carries
//  its painting, which plays it; where every chant shares the shelf's
//  painting (the Mass, Benediction) the rows are numbered and the disc
//  stands at their end, so one painting is not hung down the page again
//  and again.
//
//  All Chants was once one scroll of 104 rows under headings of three
//  sizes, with no painting on it, and every shelf a centred title over a
//  filled gold Play all. Sung Sets was a numbered index with no paintings
//  that left out the reader's own sets.
//

import SwiftUI

// MARK: - ChantBrowseScope

/// What the browse page lists
enum ChantBrowseScope: Hashable {
    /// Every chant, under its topic: the contents of the twelve sections
    case all
    /// One topic (`ChantGroup.id`)
    case group(String)
    /// The Ordinary of the Mass of the Angels, in the order it is sung
    case massOfTheAngels
    /// The home's Songs to Mary shelf, every song in the shelf's order
    case songsToMary

    nonisolated static let massSetting = "Mass of the Angels"

    var title: String {
        switch self {
        case .all: return "All Chants"
        case .group: return group.map(Self.cardTitle) ?? "Chants"
        case .massOfTheAngels: return Self.massSetting
        case .songsToMary: return "Songs to Mary"
        }
    }

    /// The section a scope of one topic lists
    var group: ChantGroup? {
        guard case .group(let id) = self else { return nil }
        return ChantCatalog.groups.first { $0.id == id }
    }

    /// The chants in a scope of one list; nil for every topic
    var chants: [Chant]? {
        switch self {
        case .all:
            return nil
        case .group:
            return group.map { ChantCatalog.chants(in: $0) } ?? []
        case .massOfTheAngels:
            return massOfTheAngelsPart.map { ChantCatalog.chants(in: $0) } ?? []
        case .songsToMary:
            return ChantLibraryData.songsToMary.compactMap { ChantCatalog.chant($0) }
        }
    }

    /// The Ordinary's first Mass is the Mass of the Angels
    private var massOfTheAngelsPart: ChantGroupPart? {
        ChantCatalog.groups.first { $0.id == "mass" }?.parts.first
    }

    /// The runs of chants the shelf lists, each under its subheading where
    /// it has one: the Masses of the Ordinary, the seasons. A shelf of one
    /// list is one run with no subheading.
    var parts: [ChantGroupPart] {
        if let group { return group.parts }
        guard let chants else { return [] }
        return [ChantGroupPart(title: nil, note: nil, chantIDs: chants.map(\.id))]
    }

    /// The line under the shelf's name: when it is sung, where the book
    /// says
    var note: String? {
        switch self {
        case .all, .songsToMary: return nil
        case .group: return group?.note
        case .massOfTheAngels: return massOfTheAngelsPart?.note.map(Self.withoutTitle)
        }
    }

    /// The painting hung at the head of the shelf: the section's card's,
    /// so the shelf opens on the painting the reader tapped
    @MainActor var painting: String {
        switch self {
        case .all:
            return ChantSet.emptyPainting
        case .group:
            return group.map(Self.contentsPainting) ?? ChantSet.emptyPainting
        case .massOfTheAngels:
            return ChantCatalog.groups.first { $0.id == "mass" }.map(Self.contentsPainting) ?? ChantSet.emptyPainting
        case .songsToMary:
            return chants?.first.map { ChantCatalog.painting(for: $0) } ?? ChantSet.emptyPainting
        }
    }

    // MARK: - The contents

    /// A section's name on its card and its shelf. The book's own title
    /// where it is short enough to read on a card; Our Lady's runs to
    /// fifty letters, and Benediction's thirty-six take the name it is
    /// known by. Not "Adoration and Blessing", the sung set's name, which
    /// would stand twice in the library for two different things.
    nonisolated static func cardTitle(of group: ChantGroup) -> String {
        switch group.id {
        case "ourLady": return "Hymns to Our Lady"
        case "benediction": return "Benediction"
        default: return group.title
        }
    }

    /// The painting a section's card hangs: the picker's (`ChantGroup.
    /// painting`), except where that would hang the Last Supper on three
    /// cards and the Annunciation on two. The hymns take the Ascension,
    /// their Te Deum's and Christus vincit's; Benediction the Blessed
    /// Sacrament; the Latin Rosary Our Lady of the Rosary.
    static func contentsPainting(for group: ChantGroup) -> String {
        switch group.id {
        case "hymns": return "glorious_ascension"
        case "benediction": return "topic_blessed_sacrament"
        case "rosary": return "feast_our_lady_of_the_rosary"
        default: return group.painting
        }
    }

    /// Where a card or a shelf's head cuts its painting: the curation's
    /// point (`ChantThumbnail.focalPoint`), except Dürer's All Saints,
    /// whose arched top left pale corners at the head of the Litanies
    static func focalPoint(for painting: String) -> UnitPoint {
        painting == "feast_all_saints" ? UnitPoint(x: 0.5, y: 0.85) : ChantThumbnail.focalPoint(for: painting)
    }

    /// Whether a shelf numbers its chants rather than hang a painting on
    /// each: true where every chant would hang the same one
    static func numbersItsChants(_ chants: [Chant]) -> Bool {
        Set(chants.map { ChantCatalog.painting(for: $0) }).count <= 1
    }

    /// A note that opens on the shelf's own name, said without it: "The
    /// Mass of the Angels: for feasts, and any Sunday" under "Mass of the
    /// Angels" reads "For feasts, and any Sunday"
    nonisolated static func withoutTitle(_ note: String) -> String {
        guard let colon = note.range(of: ": "),
              note[..<colon.lowerBound].localizedCaseInsensitiveContains(massSetting) else { return note }
        let rest = note[colon.upperBound...]
        return rest.prefix(1).uppercased() + rest.dropFirst()
    }

    /// Whether a row names its chant's setting: not where the shelf's name
    /// or the part's heading already says it ("Mass of the Angels" four
    /// times over under a shelf of that name); a setting no heading names,
    /// the Sequences' "feast poem", stays
    static func rowSaysSetting(of chant: Chant, under headings: [String?]) -> Bool {
        guard let setting = chant.settingMidLine else { return false }
        return !headings.compactMap { $0 }.contains { $0.localizedCaseInsensitiveContains(setting) }
    }

    /// "1 chant", "8 chants"
    static func chantCount(_ count: Int) -> String {
        count == 1 ? "1 chant" : "\(count) chants"
    }
}

// MARK: - ChantBrowsePage

struct ChantBrowsePage: View {

    let scope: ChantBrowseScope

    init(scope: ChantBrowseScope) {
        self.scope = scope
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.appGradient.ignoresSafeArea()

            if scope.chants == nil {
                ChantContents()
            } else {
                ChantShelf(scope: scope)
            }
        }
        .navigationBarBackButtonHidden(true)
        // No title of the bar's own: left automatic, the bar kept a large
        // title's room, and every page began under an empty band
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { ChantBackButton() }
            if scope.chants == nil {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(scope.title)
                            .font(AppFonts.titleFont(19))
                            .foregroundColor(AppColors.cream)
                        Text(ChantBrowseScope.chantCount(ChantCatalog.all.count))
                            .font(AppFonts.readingItalicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                }
            }
        }
    }
}

// MARK: - All Chants

/// The book's sections as painted cards, each a door to its shelf, the
/// way the Prayers page lists its topics
private struct ChantContents: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12, alignment: .top), GridItem(.flexible(), spacing: 12, alignment: .top)],
                alignment: .leading,
                spacing: 20
            ) {
                ForEach(ChantCatalog.groups) { group in
                    card(group)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 48)
        }
        // A shallow fade: the bar here stands on the bare page, and the
        // standard 48 points left a band of nothing under it
        .topChromeFade(height: 24, inset: 24)
        .modifier(ChantPlayerRoom())
    }

    private func card(_ group: ChantGroup) -> some View {
        let painting = ChantBrowseScope.contentsPainting(for: group)
        let count = ChantBrowseScope.chantCount(ChantCatalog.chants(in: group).count)
        let title = ChantBrowseScope.cardTitle(of: group)
        return Button {
            router.push(.chantBrowse(.group(group.id)))
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        CachedAssetImage(painting, focal: ChantBrowseScope.focalPoint(for: painting))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                    )
                    .padding(.bottom, 6)

                Text(title)
                    .font(AppFonts.titleFont(14.5))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(count)
                    .font(AppFonts.readingItalicFont(13.5))
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(count)")
        .accessibilityHint("Opens its chants")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - A shelf

/// A section, the Mass of the Angels or Songs to Mary: its painting, its
/// name, one outlined PLAY ALL, and its chants in order
private struct ChantShelf: View {

    @Environment(AppRouter.self) private var router
    let scope: ChantBrowseScope

    @State private var scroll = ChantSavedScroll()

    private var player = ChantPlayer.shared

    init(scope: ChantBrowseScope) {
        self.scope = scope
    }

    var body: some View {
        let chants = scope.chants ?? []
        let numbered = ChantBrowseScope.numbersItsChants(chants)
        let parts = scope.parts

        ZStack(alignment: .top) {
            ChantShelfPainting(name: scope.painting, scroll: scroll)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        head(chants)
                            .padding(.top, ChantShelfPainting.reach - 62)

                        if parts.contains(where: { $0.title != nil }) {
                            strip(parts, proxy: proxy)
                                .padding(.top, 26)
                        }

                        ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                            VStack(alignment: .leading, spacing: 4) {
                                if let title = part.title {
                                    ChantPartHeading(title: title, note: part.note)
                                        .padding(.bottom, 4)
                                }
                                let partChants = ChantCatalog.chants(in: part)
                                ForEach(Array(partChants.enumerated()), id: \.element.id) { number, chant in
                                    let showsSetting = ChantBrowseScope.rowSaysSetting(
                                        of: chant, under: [scope.title, part.title, part.note]
                                    )
                                    if numbered {
                                        ChantNumberedRow(
                                            number: number + 1, chant: chant, showsSetting: showsSetting, player: player
                                        ) {
                                            open(chant)
                                        }
                                    } else {
                                        ChantPaintedRow(chant: chant, showsSetting: showsSetting, player: player) {
                                            open(chant)
                                        }
                                    }
                                }
                            }
                            .padding(.top, part.title == nil ? 20 : 30)
                            .id(Self.partID(index))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 48)
                }
                .modifier(ChantSavedScrollReading(scroll: scroll))
                .topChromeFade()
                .modifier(ChantPlayerRoom())
            }
        }
    }

    // MARK: - The head

    private func head(_ chants: [Chant]) -> some View {
        VStack(spacing: 6) {
            Text(scope.title)
                .font(AppFonts.titleFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let note = scope.note {
                Text(note)
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(ChantSetCard.summary(count: chants.count, duration: chants.reduce(0) { $0 + $1.duration }))
                .font(AppFonts.readingFont(13.5))
                .foregroundColor(AppColors.textSecondary)
                .monospacedDigit()

            if chants.count > 1 {
                ChantShelfPlayAll(queue: ChantQueue.chants(chants, title: scope.title), title: scope.title)
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
    }

    // MARK: - The strip of parts

    /// The subheadings as a strip, each scrolling the page to its part:
    /// only on a shelf that has them (the Masses, the seasons)
    private func strip(_ parts: [ChantGroupPart], proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    if let title = part.title {
                        Button {
                            withAnimation(Motion.travel(0.4)) { proxy.scrollTo(Self.partID(index), anchor: .top) }
                        } label: {
                            Text(title)
                                .font(AppFonts.bodyFont(14))
                                .foregroundColor(AppColors.cream.opacity(0.88))
                                .padding(.horizontal, 14)
                                .frame(height: 32)
                                .overlay(
                                    Capsule().strokeBorder(AppColors.gold.opacity(0.32), lineWidth: AppLine.hairline)
                                )
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(SacredCardButtonStyle())
                        .accessibilityHint("Goes to its chants")
                    }
                }
            }
            .padding(.horizontal, 18)
        }
        .padding(.horizontal, -18)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Parts")
    }

    private func open(_ chant: Chant) {
        router.push(ChantTap.route(to: chant))
    }

    /// A part's place on the page for the strip to scroll to, apart from
    /// the strip's own buttons
    private static func partID(_ index: Int) -> String {
        "part-\(index)"
    }
}

// MARK: - Room for the player

/// Room at the foot of a page for the chant player while it stands there,
/// as Your Chants keeps it (`ChantSavedPage.playerRoom`), so the last row
/// is never under it; none once the app keeps the room itself
private struct ChantPlayerRoom: ViewModifier {
    @State private var bottomInset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(
                .bottom,
                ChantSavedPage.playerRoom(playerActive: ChantPlayer.shared.isActive, bottomInset: bottomInset)
            )
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { bottomInset = $0 }
    }
}

// MARK: - The shelf's painting

/// The painting at the head of a shelf, run up under the bar and the
/// status bar and dissolving into the page beneath the shelf's name, as
/// Your Chants hangs its own. It rises with the page.
private struct ChantShelfPainting: View {
    let name: String
    let scroll: ChantSavedScroll

    /// How far the painting reaches below the bar: the name, PLAY ALL and
    /// the first chant still fit on the first screen
    static let reach: CGFloat = 200

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: Self.reach)
            .background(alignment: .bottom) {
                CachedAssetImage(name, focal: ChantBrowseScope.focalPoint(for: name))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .overlay {
                        // A veil under the status bar and the Back, and
                        // under the name where the painting fades
                        LinearGradient(
                            stops: [
                                .init(color: AppColors.background.opacity(0.7), location: 0),
                                .init(color: AppColors.background.opacity(0.1), location: 0.35),
                                .init(color: AppColors.background.opacity(0.1), location: 0.55),
                                .init(color: AppColors.background.opacity(0.6), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    // Dissolves to clear, so the page's own gradient shows
                    // through beneath it rather than a slab of one colour
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.55),
                                .init(color: .black.opacity(0.35), location: 0.82),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea(edges: .top)
            }
            .offset(y: -scroll.rise)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - PLAY ALL

/// The shelf's one act, outlined: the library's pages keep no filled gold
/// act. Play all until the shelf is under way, then its own pause and
/// resume, as a set's page does.
private struct ChantShelfPlayAll: View {
    let queue: ChantQueue
    let title: String

    private var player = ChantPlayer.shared

    init(queue: ChantQueue, title: String) {
        self.queue = queue
        self.title = title
    }

    var body: some View {
        let singing = player.isSinging(queue)
        let going = singing && player.isGoingOn
        let word =
            !singing
            ? "Play all"
            : player.waitingForNext
                ? "Play next"
                : going ? "Pause" : "Resume"
        Button {
            if singing { player.pauseOrResume() } else { player.play(queue) }
        } label: {
            HStack(spacing: 8) {
                AppIcon(going ? "ph-pause-fill" : "ph-play-fill", size: 12)
                Text(word.uppercased())
                    .font(AppFonts.labelFont(11))
                    .tracking(2.2)
                    .contentTransition(.opacity)
            }
            .foregroundColor(AppColors.gold)
            .padding(.horizontal, 26)
            .frame(minHeight: 46)
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.55), lineWidth: AppLine.hairline))
            .contentShape(Capsule())
        }
        .buttonStyle(SacredCardButtonStyle())
        .animation(Motion.crossfade, value: word)
        .accessibilityLabel(singing ? word : "Play all of \(title)")
    }
}

// MARK: - Rows

/// A chant's two names and how long it sings, the Latin lit while it
/// sounds. The second line says the setting where the shelf holds both.
private struct ChantShelfNames: View {
    let chant: Chant
    let showsSetting: Bool
    let sounding: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(chant.latinTitle)
                .font(AppFonts.readingFont(16.5))
                .foregroundColor(sounding ? AppColors.goldLight : AppColors.cream)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .animation(Motion.crossfade, value: sounding)
            Text(Self.subtitle(of: chant, showsSetting: showsSetting))
                .font(AppFonts.readingItalicFont(13.5))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    static func subtitle(of chant: Chant, showsSetting: Bool) -> String {
        guard showsSetting, let setting = chant.settingMidLine else { return chant.englishTitle }
        return "\(chant.englishTitle) · \(setting)"
    }
}

/// Its length, or the moving bars while it sounds
private struct ChantShelfLength: View {
    let chant: Chant
    let sounding: Bool

    var body: some View {
        if sounding {
            ChantSoundingBars()
        } else {
            Text(chant.durationLabel)
                .font(AppFonts.readingFont(13.5))
                .foregroundColor(AppColors.textSecondary)
                .monospacedDigit()
        }
    }
}

/// A chant with a painting of its own: the painting, which plays it, then
/// its names and length. A tap anywhere else opens its page.
private struct ChantPaintedRow: View {
    let chant: Chant
    let showsSetting: Bool
    let player: ChantPlayer
    let open: () -> Void

    var body: some View {
        let sounding = player.isPlaying(chant)
        HStack(spacing: 12) {
            ZStack {
                ChantThumbnail(name: ChantCatalog.painting(for: chant), size: 46, radius: 8)
                ChantPlayDisc(
                    isPlaying: sounding,
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 26,
                    label: chant.spokenName
                ) {
                    player.toggle(chant)
                }
            }

            Button(action: open) {
                HStack(spacing: 10) {
                    ChantShelfNames(chant: chant, showsSetting: showsSetting, sounding: sounding)
                    ChantShelfLength(chant: chant, sounding: sounding)
                }
                .padding(.vertical, 9)
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(ChantShelfRow.spoken(chant, showsSetting: showsSetting, sounding: sounding))
            .accessibilityHint("Opens the chant with its sheet music")
            .accessibilityAddTraits(.isButton)
        }
        .modifier(ChantShelfRow())
        .chantContextMenu(chant)
    }
}

/// A chant on a shelf whose chants all share its painting: its number in
/// the order sung, its names and length, and the disc that plays it
private struct ChantNumberedRow: View {
    let number: Int
    let chant: Chant
    let showsSetting: Bool
    let player: ChantPlayer
    let open: () -> Void

    var body: some View {
        let sounding = player.isPlaying(chant)
        HStack(spacing: 12) {
            Button(action: open) {
                HStack(spacing: 12) {
                    Text("\(number)")
                        .font(AppFonts.titleFont(14))
                        .foregroundColor(sounding ? AppColors.goldLight : AppColors.textSecondary)
                        .monospacedDigit()
                        .frame(width: 24)
                    ChantShelfNames(chant: chant, showsSetting: showsSetting, sounding: sounding)
                    ChantShelfLength(chant: chant, sounding: sounding)
                }
                .padding(.vertical, 11)
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(number). " + ChantShelfRow.spoken(chant, showsSetting: showsSetting, sounding: sounding))
            .accessibilityHint("Opens the chant with its sheet music")
            .accessibilityAddTraits(.isButton)

            ChantPlayDisc(
                isPlaying: sounding,
                isLoading: player.current.id == chant.id && player.isLoading,
                size: 30,
                label: chant.spokenName
            ) {
                player.toggle(chant)
            }
        }
        .modifier(ChantShelfRow())
        .chantContextMenu(chant)
    }
}

/// The hairline under every row of a shelf, and what VoiceOver hears
private struct ChantShelfRow: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.12))
                .frame(height: AppLine.hairline)
        }
    }

    static func spoken(_ chant: Chant, showsSetting: Bool, sounding: Bool) -> String {
        let length = sounding ? "playing now" : ChantPlayer.spoken(chant.duration)
        return "\(chant.latinTitle), \(ChantShelfNames.subtitle(of: chant, showsSetting: showsSetting)), \(length)"
    }
}

// MARK: - ChantSetsPage

/// The sung sets as painted cards: the library's occasions, then the
/// reader's own, then a new one. Each opens on its own page
/// (`ChantSetPage`).
struct ChantSetsPage: View {

    @Environment(AppRouter.self) private var router

    @State private var namingSet = false

    private var shelf: ChantShelfStore
    private var player = ChantPlayer.shared

    init(shelf: ChantShelfStore = .shared) {
        self.shelf = shelf
    }

    /// The reader's own sets. A set kept from an occasion and never
    /// changed is that occasion's card above; one the reader has changed
    /// since is theirs, and stands here with the rest
    private var ownSets: [ChantSet] {
        shelf.sets.filter { set in
            guard let id = set.occasionID, let occasion = ChantOccasion.occasion(id) else { return true }
            return !shelf.isUntouchedCopy(set, of: occasion)
        }
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chants sung one after another, for a time of prayer.")
                        .font(AppFonts.readingItalicFont(16))
                        .foregroundColor(AppColors.cream.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)

                    ForEach(ChantLibraryData.occasions) { occasion in
                        let chants = occasion.distinctChants()
                        card(
                            title: occasion.title,
                            note: occasion.note,
                            painting: occasion.painting,
                            summary: ChantSetCard.summary(count: chants.count, duration: occasion.duration()),
                            singing: isGoingOn(ChantQueue.occasion(occasion))
                        ) {
                            router.push(.chantSet(.occasion(occasion.id)))
                        }
                    }

                    if !ownSets.isEmpty {
                        Text("Your sets")
                            .font(AppFonts.titleFont(17))
                            .foregroundColor(AppColors.cream)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, 22)
                            .padding(.bottom, 2)

                        ForEach(ownSets) { set in
                            card(
                                title: set.name,
                                note: nil,
                                painting: set.painting,
                                summary: ChantSavedSetCover.summary(of: set),
                                singing: isGoingOn(ChantQueue.set(set))
                            ) {
                                router.push(.chantSet(.own(set.id)))
                            }
                        }
                    }

                    makeYourOwn
                        .padding(.top, 14)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
            // A shallow fade: the bar here stands on the bare page, and the
            // standard 48 points left a band of nothing under it
            .topChromeFade(height: 24, inset: 24)
            .modifier(ChantPlayerRoom())
        }
        .navigationBarBackButtonHidden(true)
        // No title of the bar's own: left automatic, the bar kept a large
        // title's room, and every page began under an empty band
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { ChantBackButton() }
            ToolbarItem(placement: .principal) {
                Text("Sung Sets")
                    .font(AppFonts.titleFont(19))
                    .foregroundColor(AppColors.cream)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .sheet(isPresented: $namingSet) {
            ChantNewSetSheet(shelf: shelf) { set in router.push(.chantSet(.own(set.id))) }
                .presentationDetents([.medium])
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }

    private func isGoingOn(_ queue: ChantQueue) -> Bool {
        player.isSinging(queue) && player.isGoingOn
    }

    /// A set as a wide card: its painting, its name, what it is for, and
    /// how many chants and how long
    private func card(
        title: String,
        note: String?,
        painting: String,
        summary: String,
        singing: Bool,
        open: @escaping () -> Void
    ) -> some View {
        Button(action: open) {
            HStack(spacing: 14) {
                CachedAssetImage(painting, focal: ChantThumbnail.focalPoint(for: painting))
                    .frame(width: 112)
                    .frame(maxHeight: .infinity)
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(title)
                            .font(AppFonts.titleFont(16))
                            .foregroundColor(AppColors.cream)
                            .fixedSize(horizontal: false, vertical: true)
                        if singing {
                            ChantSoundingBars()
                        }
                    }
                    if let note {
                        Text(note)
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(summary)
                        .font(AppFonts.readingFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                }
                .padding(.vertical, 14)
                .padding(.trailing, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 112)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [title, note, summary, singing ? "playing now" : nil].compactMap { $0 }.joined(separator: ", ")
        )
        .accessibilityHint("Opens the set")
        .accessibilityAddTraits(.isButton)
    }

    private var makeYourOwn: some View {
        Button {
            namingSet = true
        } label: {
            HStack(spacing: 14) {
                AppIcon("ph-plus", size: 16)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.5), lineWidth: AppLine.hairline))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Make your own set")
                        .font(AppFonts.titleFont(16))
                        .foregroundColor(AppColors.cream)
                    Text("Choose chants for an hour of prayer in church, a prayer group or family prayer")
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
    }
}
