//
//  ChantLibraryView.swift
//  Lumen Viae
//
//  The Chant Library: the Church's own songs, each with its recording and
//  its score, to hear, to follow and to learn. A home page read top to
//  bottom, like a music app's (the "Simpler Chant Library" design, round
//  9, Oct 2026):
//
//    TILES          six quick ways in, two by three: the chant sounding or
//                   last sung, the reader's favourites, and the sets sung
//                   most (a sung Rosary, Adoration and Blessing, the Mass
//                   of the Angels, Before Bed)
//    TONIGHT        tonight's song to Mary as one wide card
//    PLAYED LATELY  a song list, the one sounding marked with moving bars
//    SONGS TO MARY  square cards, each with its length and its play
//    SUNG SETS      cards listing their chants in order, with lengths
//    BROWSE ALL     every chant, under its topic
//
//  Every card says how long it plays and has its own play, so the page
//  reads as a library of songs rather than of prayers. A tap on a chant,
//  wherever it stands, opens its page; only its disc plays (`ChantTap`).
//  Search stands in the bar.
//
//  It once opened on a strip of six sections (Today, Seasons, Occasions,
//  Types, Learn, Saved) with the first screen a chart of the day's hours:
//  nothing on it said what to do. The year wheel, the kinds and the
//  learning course went with it; a chant is learned from its own page.
//
//  What the library is singing stands at the foot of the whole app
//  (`ContentView`), not of this page alone. Everything here is bundled: a
//  chapel with no signal still has every chant.
//
//  Reached from the Chapel's Chant tile, Explore, and a chant's page.
//

import SwiftUI

// MARK: - ChantLibraryView

struct ChantLibraryView: View {

    @Environment(AppRouter.self) private var router

    @State private var searching = false

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    /// Shown as the Chant tab's page: no Back, and room at the foot for
    /// the tab bar
    private let isTabRoot: Bool

    init(isTabRoot: Bool = false) {
        self.isTabRoot = isTabRoot
    }

    /// The key the build with six sections kept the one last opened
    /// under. The page has no sections now, so whatever it holds opens
    /// the same page; it is let go so it never decides anything again.
    static let legacySectionKey = "chantLibrary.section"

    static func forgetLegacySection(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: legacySectionKey)
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            // The library stays where it is while the search stands over
            // it, hidden, so Cancel comes back to the same place
            ZStack {
                library
                    .opacity(searching ? 0 : 1)
                    .allowsHitTesting(!searching)
                    .accessibilityHidden(searching)
                if searching {
                    ChantSearchView(
                        isTabRoot: isTabRoot,
                        close: { withAnimation(Motion.crossfade) { searching = false } },
                        open: openChant
                    )
                    .transition(.opacity)
                }
            }
            .animation(Motion.crossfade, value: searching)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if !searching {
                if !isTabRoot {
                    ToolbarItem(placement: .navigationBarLeading) {
                        ChantBackButton()
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Chant")
                            .font(AppFonts.titleFont(19))
                            .foregroundColor(AppColors.cream)
                        Text("\(ChantCatalog.all.count) recordings")
                            .font(AppFonts.readingItalicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(Motion.crossfade) { searching = true }
                    } label: {
                        AppIcon("ph-magnifying-glass", size: 19)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Search the Chant Library")
                    .accessibilityHint("Find a chant by its name, its words or the prayer it sings")
                }
            }
        }
        .onAppear { Self.forgetLegacySection() }
    }

    // MARK: - The page

    private var library: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 40) {
                tiles
                    .padding(.horizontal, 18)

                if let antiphon = ChantCatalog.antiphonOfTheSeason() {
                    shelfSection("Tonight") { tonight(antiphon) }
                }

                if !played.isEmpty {
                    shelfSection("Played lately") { playedLately }
                }

                shelfSection("Songs to Mary", seeAll: { router.push(.chantBrowse(.songsToMary)) }) {
                    songsToMary
                }

                shelfSection("Sung sets", seeAll: { router.push(.chantSets) }) {
                    sungSets
                }

                browseAll
                    .padding(.horizontal, 18)

                footer
                    .padding(.horizontal, 36)
                    .padding(.bottom, isTabRoot ? 130 : 40)
            }
            .padding(.top, 8)
        }
        .topChromeFade()
    }

    /// A shelf of the page: its name in the display face, SEE ALL beside
    /// it where there is more, and what it holds beneath
    private func shelfSection<Content: View>(
        _ title: String,
        seeAll: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(AppFonts.titleFont(17))
                    .foregroundColor(AppColors.cream)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                if let seeAll {
                    Button(action: seeAll) {
                        Text("SEE ALL")
                            .font(AppFonts.labelFont(9.5))
                            .tracking(2)
                            .foregroundColor(AppColors.gold)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("See all: \(title)")
                }
            }
            .frame(minHeight: 30)
            .padding(.horizontal, 18)

            content()
        }
    }

    // MARK: - Tiles

    /// The six quick ways in. The first is the chant sounding, or the one
    /// last sung, or until anything has been sung the chants learned.
    private var tiles: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            if let chant = lastChant {
                tile(
                    chant.latinTitle,
                    painting: ChantCatalog.painting(for: chant),
                    sounding: player.isPlaying(chant),
                    spoken: chant.spokenName
                ) { openChant(chant) }
            } else {
                tile("Learned", painting: "glorious_coronation", spoken: "Chants you have learned") {
                    router.push(.chantSaved(.learned))
                }
            }

            tile("Your favourites", painting: favouritesPainting, spoken: "Your favourite chants") {
                router.push(.chantSaved(.favorites))
            }

            ForEach(Self.tileOccasionIDs.prefix(2), id: \.self) { id in
                if let occasion = ChantOccasion.occasion(id) { occasionTile(occasion) }
            }

            tile("Mass of the Angels", painting: "sorrowful_crucifixion", spoken: "The Mass of the Angels") {
                router.push(.chantBrowse(.massOfTheAngels))
            }

            ForEach(Self.tileOccasionIDs.dropFirst(2), id: \.self) { id in
                if let occasion = ChantOccasion.occasion(id) { occasionTile(occasion) }
            }
        }
    }

    /// The sets the tiles open, in the grid's order around the Mass
    static let tileOccasionIDs = ["sung_rosary", "benediction", "before_bed"]

    private func occasionTile(_ occasion: ChantOccasion) -> some View {
        tile(
            occasion.title,
            painting: occasion.painting,
            sounding: player.isSinging(ChantQueue.occasion(occasion)) && player.isGoingOn,
            spoken: occasion.title
        ) {
            router.push(.chantSet(.occasion(occasion.id)))
        }
    }

    /// The chant sounding, else the one sung last
    private var lastChant: Chant? {
        if player.isActive { return player.current }
        return shelf.recent.lazy.compactMap { ChantCatalog.chant($0.chantID) }.first
    }

    private var favouritesPainting: String {
        shelf.favorites.lazy.compactMap { ChantCatalog.chant($0) }.first.map { ChantCatalog.painting(for: $0) }
            ?? "glorious_pentecost"
    }

    private func tile(
        _ title: String,
        painting: String,
        sounding: Bool = false,
        spoken: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ChantThumbnail(name: painting, size: 56, radius: 0)
                Text(title)
                    .font(AppFonts.bodyFont(14.5))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if sounding {
                    ChantSoundingBars()
                }
            }
            .padding(.trailing, 10)
            .frame(height: 56)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppColors.gold.opacity(0.16), lineWidth: AppLine.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sounding ? "\(spoken), playing now" : spoken)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Tonight

    /// Tonight's song to Mary as one wide card: its painting, its names
    /// and length, and LISTEN. The card opens the chant; the disc sings it.
    private func tonight(_ chant: Chant) -> some View {
        HStack(spacing: 0) {
            ChantThumbnail(name: Self.tonightPainting(for: chant), size: 150, radius: 0)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("SONG TO MARY")
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold)
                Text(chant.latinTitle)
                    .font(AppFonts.titleFont(20))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text("\(chant.englishTitle) · \(chant.durationLabel)")
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)

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
                .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 150)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: AppLine.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture { openChant(chant) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tonight's song to Mary: \(chant.spokenName), \(ChantPlayer.spoken(chant.duration))")
        .accessibilityAction(named: "Open the chant") { openChant(chant) }
        .chantContextMenu(chant)
        .padding(.horizontal, 18)
    }

    /// Tonight's painting: the chant's own where it has one, else the
    /// night's
    static func tonightPainting(for chant: Chant) -> String {
        ChantLibraryData.paintings[chant.id]
            ?? ChantCatalog.painting(subject: "hour_night", else: ChantCatalog.painting(for: chant))
    }

    // MARK: - Played lately

    /// The three chants sung last, latest first
    private var played: [Chant] {
        Array(shelf.recent.lazy.compactMap { ChantCatalog.chant($0.chantID) }.prefix(3))
    }

    private var playedLately: some View {
        VStack(spacing: 0) {
            ForEach(played) { chant in
                ChantSongRow(chant: chant, player: player) { openChant(chant) }
            }
        }
        .padding(.horizontal, 18)
    }

    // MARK: - Songs to Mary

    private var songsToMary: some View {
        ChantSideScroll {
            HStack(alignment: .top, spacing: 14) {
                ForEach(ChantLibraryData.songsToMary.compactMap { ChantCatalog.chant($0) }) {
                    chant in
                    ChantSquareCard(chant: chant, player: player) { openChant(chant) }
                }
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Sung sets

    /// The occasions sung in order, then the sets the reader made. A set
    /// kept from an occasion stands under the occasion's own card.
    private var sungSets: some View {
        ChantSideScroll {
            HStack(alignment: .top, spacing: 14) {
                ForEach(ChantLibraryData.occasions) { occasion in
                    ChantSetCard(
                        title: occasion.title,
                        painting: occasion.painting,
                        chants: occasion.distinctChants(),
                        duration: occasion.duration(),
                        queue: ChantQueue.occasion(occasion),
                        open: { router.push(.chantSet(.occasion(occasion.id))) },
                        openChant: openChant
                    )
                }
                ForEach(shelf.sets.filter { $0.occasionID == nil && $0.chantCount > 0 }) { set in
                    let chants = set.items.compactMap(\.chant)
                    ChantSetCard(
                        title: set.name,
                        painting: chants.first.map { ChantCatalog.painting(for: $0) } ?? "glorious_coronation",
                        chants: chants,
                        duration: set.duration,
                        queue: ChantQueue.set(set),
                        open: { router.push(.chantSet(.own(set.id))) },
                        openChant: openChant
                    )
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Browse all

    private var browseAll: some View {
        Button {
            router.push(.chantBrowse(.all))
        } label: {
            HStack(spacing: 10) {
                AppIcon("ph-magnifying-glass", size: 16)
                Text("BROWSE ALL \(ChantCatalog.all.count) CHANTS")
                    .font(AppFonts.labelFont(11))
                    .tracking(2.4)
            }
            .foregroundColor(AppColors.gold)
            .frame(maxWidth: .infinity, minHeight: 50)
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline))
            .contentShape(Capsule())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("Browse all \(ChantCatalog.all.count) chants")
    }

    // MARK: - Foot

    /// One line of credit, a link to the singers' site. The licence stands
    /// in full on every chant's own page (`ChantCredit`).
    private var footer: some View {
        Link(destination: ChantCatalog.sourceSite) {
            (Text(ChantCatalog.libraryCredit).underline(color: AppColors.gold.opacity(0.5))
                + Text(" ↗").foregroundColor(AppColors.gold))
                .font(AppFonts.readingItalicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.72))
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(ChantCatalog.libraryCredit)
        .accessibilityHint("Opens Verbum Gloriae's website")
    }

    // MARK: - Doors

    private func openChant(_ chant: Chant) {
        router.push(ChantTap.route(to: chant))
    }
}

// MARK: - ChantBackButton

/// The gold Back every library page draws in its bar
struct ChantBackButton: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
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

// MARK: - ChantSoundingBars

/// Three small bars beside whatever is sounding, as a music app marks the
/// song playing. Still under Reduce Motion.
struct ChantSoundingBars: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            bars([6, 12, 8])
        } else {
            PhaseAnimator([0, 1, 2]) { phase in
                bars([[6, 12, 8], [11, 5, 12], [8, 10, 4]][phase])
            } animation: { _ in
                .easeInOut(duration: 0.32)
            }
        }
    }

    private func bars(_ heights: [CGFloat]) -> some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(heights.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(AppColors.gold)
                    .frame(width: 3, height: heights[index])
            }
        }
        .frame(height: 12, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

// MARK: - ChantSongRow

/// A chant as a music app lists a song: its painting, its names, its
/// length (or the bars while it sounds), and ··· for the hold menu's acts
struct ChantSongRow: View {
    let chant: Chant
    let player: ChantPlayer
    let open: () -> Void

    private var shelf = ChantShelfStore.shared

    init(chant: Chant, player: ChantPlayer, open: @escaping () -> Void) {
        self.chant = chant
        self.player = player
        self.open = open
    }

    var body: some View {
        let sounding = player.isPlaying(chant)
        HStack(spacing: 12) {
            Button(action: open) {
                HStack(spacing: 12) {
                    ChantThumbnail(name: ChantCatalog.painting(for: chant), size: 44, radius: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(chant.latinTitle)
                            .font(AppFonts.readingFont(16.5))
                            .foregroundColor(sounding ? AppColors.goldLight : AppColors.cream)
                            .lineLimit(1)
                        Text(chant.settingMidLine.map { "\(chant.englishTitle) · \($0)" } ?? chant.englishTitle)
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    if sounding {
                        ChantSoundingBars()
                    } else {
                        Text(chant.durationLabel)
                            .font(AppFonts.readingFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .monospacedDigit()
                    }
                }
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "\(chant.spokenName), \(sounding ? "playing now" : ChantPlayer.spoken(chant.duration))"
            )
            .accessibilityHint("Opens the chant with its sheet music")
            .accessibilityAddTraits(.isButton)

            Menu {
                Button {
                    player.toggle(chant)
                } label: {
                    Label(sounding ? "Pause" : "Play", systemImage: sounding ? "pause" : "play")
                }
                Button {
                    shelf.toggleFavorite(chant.id)
                } label: {
                    if shelf.isFavorite(chant.id) {
                        Label("Remove from Favourites", systemImage: "heart.slash")
                    } else {
                        Label("Add to Favourites", systemImage: "heart")
                    }
                }
                if !shelf.sets.isEmpty {
                    Menu {
                        ForEach(shelf.sets) { set in
                            Button(set.name) { shelf.addChant(chant.id, to: set.id) }
                        }
                    } label: {
                        Label("Add to a Set", systemImage: "text.badge.plus")
                    }
                }
            } label: {
                AppIcon("ph-dots-three", size: 18)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 36, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More for \(chant.latinTitle)")
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.12))
                .frame(height: AppLine.hairline)
        }
        .chantContextMenu(chant)
    }
}

// MARK: - ChantSquareCard

/// One chant as a square of its painting, its length on the painting's
/// foot and its play beside it, its names beneath
struct ChantSquareCard: View {
    let chant: Chant
    let player: ChantPlayer
    let open: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ChantThumbnail(name: ChantCatalog.painting(for: chant), size: 142, radius: 16)
                .overlay(alignment: .bottomLeading) {
                    Text(chant.durationLabel)
                        .font(AppFonts.readingFont(12))
                        .foregroundColor(AppColors.cream)
                        .monospacedDigit()
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(AppColors.background.opacity(0.78)))
                        .padding(8)
                        .accessibilityHidden(true)
                }
                .overlay(alignment: .bottomTrailing) {
                    ChantPlayDisc(
                        isPlaying: player.isPlaying(chant),
                        isLoading: player.current.id == chant.id && player.isLoading,
                        size: 30,
                        label: chant.spokenName
                    ) {
                        player.toggle(chant)
                    }
                    .padding(2)
                }
                .onTapGesture(perform: open)

            Button(action: open) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(chant.latinTitle)
                        .font(AppFonts.readingFont(15.5))
                        .foregroundColor(player.isPlaying(chant) ? AppColors.goldLight : AppColors.cream)
                        .lineLimit(1)
                    Text(chant.settingMidLine.map { "\(chant.englishTitle) · \($0)" } ?? chant.englishTitle)
                        .font(AppFonts.readingItalicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 142, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(chant.spokenName), \(ChantPlayer.spoken(chant.duration))")
            .accessibilityHint("Opens the chant with its sheet music")
            .accessibilityAddTraits(.isButton)
        }
        .frame(width: 142)
        .chantContextMenu(chant)
    }
}

// MARK: - ChantSetCard

/// A sung set as a card: its painting, its name, how many chants and how
/// long, its play, and its chants listed in order with their lengths, so
/// what will be heard is seen before play is pressed. The card opens the
/// set; a chant listed on it opens that chant's page (`ChantTap`); only
/// the disc plays, and it plays the whole set.
struct ChantSetCard: View {
    let title: String
    let painting: String
    let chants: [Chant]
    let duration: TimeInterval
    let queue: ChantQueue
    let open: () -> Void
    let openChant: (Chant) -> Void

    private var player = ChantPlayer.shared

    /// How many of its chants the card lists before "and n more"
    static let listed = 4

    init(
        title: String,
        painting: String,
        chants: [Chant],
        duration: TimeInterval,
        queue: ChantQueue,
        open: @escaping () -> Void,
        openChant: @escaping (Chant) -> Void
    ) {
        self.title = title
        self.painting = painting
        self.chants = chants
        self.duration = duration
        self.queue = queue
        self.open = open
        self.openChant = openChant
    }

    var body: some View {
        let singing = player.isSinging(queue)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ChantThumbnail(name: painting, size: 76, radius: 12)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFonts.readingFont(16.5))
                        .foregroundColor(singing ? AppColors.goldLight : AppColors.cream)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Self.summary(count: chants.count, duration: duration))
                        .font(AppFonts.readingFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ChantPlayDisc(
                    isPlaying: singing && player.isGoingOn,
                    isLoading: false,
                    size: 36,
                    label: title
                ) {
                    if singing { player.pauseOrResume() } else { player.play(queue) }
                }
            }
            .padding(.bottom, 10)

            ForEach(Array(chants.prefix(Self.listed).enumerated()), id: \.offset) { index, chant in
                Button {
                    openChant(chant)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1)")
                            .font(AppFonts.titleFont(12))
                            .foregroundColor(Rubric.text)
                            .frame(width: 14, alignment: .leading)
                        Text(chant.latinTitle)
                            .font(AppFonts.readingFont(14.5))
                            .foregroundColor(AppColors.cream.opacity(0.92))
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        Text(chant.durationLabel)
                            .font(AppFonts.readingFont(12.5))
                            .foregroundColor(AppColors.textSecondary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.gold.opacity(index == 0 ? 0.16 : 0.08))
                        .frame(height: AppLine.hairline)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(index + 1). \(chant.spokenName), \(ChantPlayer.spoken(chant.duration))")
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Opens the chant")
            }

            if chants.count > Self.listed {
                Text("and \(chants.count - Self.listed) more")
                    .font(AppFonts.readingItalicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.vertical, 7)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .frame(width: 272, alignment: .topLeading)
        // Every card in the row stands as tall as the tallest
        .frame(maxHeight: .infinity, alignment: .top)
        .background(RoundedRectangle(cornerRadius: 18).fill(AppColors.cardBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture(perform: open)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title), \(Self.summary(count: chants.count, duration: duration))")
        .accessibilityAction(named: "Open the set") { open() }
    }

    /// "4 chants · 7 min": the length of its recordings, never a guess
    static func summary(count: Int, duration: TimeInterval) -> String {
        let minutes = max(1, Int((duration / 60).rounded()))
        return "\(count == 1 ? "1 chant" : "\(count) chants") · \(minutes) min"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChantLibraryView()
            .environment(AppRouter())
    }
}
