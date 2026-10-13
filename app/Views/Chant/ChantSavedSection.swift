//
//  ChantSavedSection.swift
//  Lumen Viae
//
//  Your Chants: what the reader keeps from the library, on a page of its
//  own. The painting of the first chant on the shelf chosen hangs at the
//  top; beneath it, one switch between Favourites and Learned, and the
//  shelf chosen as the library lists songs. Then the sets they have made,
//  as covers, with a cover for a new one; what was sung lately, quietly;
//  and at the foot the library's one setting, the words.
//
//  It once opened on a shelf of book spines, where two spines switched
//  the list beneath and the rest opened pages of their own, under a
//  paragraph saying what the page was. The switch now looks like one.
//
//  Everything here is kept on the device (`ChantShelfStore`).
//

import SwiftUI

// MARK: - ChantSavedShelf

/// The shelf the page opens on: the library's tiles name one
enum ChantSavedShelf: Hashable {
    case favorites
    case learned

    /// The shelf shown: the one chosen, else Favourites — or Learned while
    /// Favourites holds nothing and Learned holds something
    static func shown(choice: ChantSavedShelf?, favorites: Int, learned: Int) -> ChantSavedShelf {
        if let choice { return choice }
        return favorites == 0 && learned > 0 ? .learned : .favorites
    }

    var title: String {
        switch self {
        case .favorites: return "Favourites"
        case .learned:   return "Learned"
        }
    }

    /// The one line an empty shelf says
    var emptyLine: String {
        switch self {
        case .favorites: return "Hold any chant to add it to your favourites."
        case .learned:   return "Chants you learn by heart are kept here."
        }
    }

    /// The painting an empty shelf hangs, the one its tile in the library
    /// shows before anything is kept
    var emptyPainting: String {
        switch self {
        case .favorites: return "glorious_pentecost"
        case .learned:   return "psalm_king_david"
        }
    }

    /// The painting in an empty shelf's arch, another than the one at the
    /// head of the page, so the page never hangs one painting twice: the
    /// Visitation for what is kept, the Finding in the Temple, where the
    /// Child was found among the teachers, for what is learned
    var emptyArchPainting: String {
        switch self {
        case .favorites: return "joyful_visitation"
        case .learned:   return "joyful_finding"
        }
    }

    /// The painting at the head of the page: the first chant's, else the
    /// shelf's own
    func painting(of chants: [Chant]) -> String {
        chants.first.map { ChantCatalog.painting(for: $0) } ?? emptyPainting
    }

    /// "5 chants", for VoiceOver; nothing for an empty shelf, which is not
    /// told it has none
    static func spokenCount(_ n: Int) -> String? {
        n > 0 ? (n == 1 ? "1 chant" : "\(n) chants") : nil
    }
}

// MARK: - ChantSavedPage

/// The reader's own chants, pushed from the library's Learned and Your
/// favourites tiles. The app-wide mini player stands at its foot.
struct ChantSavedPage: View {

    @State private var choice: ChantSavedShelf?
    @State private var scroll = ChantSavedScroll()

    private let shelf: ChantShelfStore
    private let clock: ChantSavedClock

    /// `clock` holds the recent plays' "Tonight" and "Yesterday" to one
    /// moment, calendar and language, for a snapshot; left out, they read
    /// the device's
    init(start: ChantSavedShelf?, shelf: ChantShelfStore = .shared, clock: ChantSavedClock = .device) {
        _choice = State(initialValue: start)
        self.shelf = shelf
        self.clock = clock
    }

    private var shown: ChantSavedShelf {
        ChantSavedShelf.shown(choice: choice, favorites: shelf.favorites.count, learned: shelf.learned.count)
    }

    private var shownChants: [Chant] {
        shown == .favorites ? shelf.favoriteChants : shelf.learnedChants
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.appGradient.ignoresSafeArea()

            ChantSavedPainting(name: shown.painting(of: shownChants), scroll: scroll)

            ScrollView(showsIndicators: false) {
                ChantSavedSection(shown: shown, choice: $choice, shelf: shelf, clock: clock)
                    .padding(.top, 4)
                    .padding(.bottom, 48)
            }
            .modifier(ChantSavedScrollReading(scroll: scroll))
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                GoldBackButton()
            }
            ToolbarItem(placement: .principal) {
                Text("Your Chants")
                    .font(AppFonts.titleFont(19))
                    .foregroundColor(AppColors.cream)
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }
}

// MARK: - ChantSavedClock

/// The moment, calendar and language the recent plays are named in
struct ChantSavedClock {
    var now: () -> Date
    var calendar: Calendar
    var locale: Locale

    static var device: ChantSavedClock {
        ChantSavedClock(now: { Date() }, calendar: .current, locale: .current)
    }
}

// MARK: - ChantSavedScroll

/// How far the page has scrolled, read only by the painting, so a scroll
/// frame redraws the painting and not the page
@Observable
final class ChantSavedScroll {
    /// How far the content has risen, never more than nothing when pulled
    /// down
    private(set) var rise: CGFloat = 0

    func set(rise risen: CGFloat) {
        let risen = max(0, risen)
        if risen != rise { rise = risen }
    }
}

/// Reads the scroll from the scroll view itself: its offset past its
/// resting inset, whatever the bar's height settles to. Before iOS 18,
/// which cannot read it, the painting stands still and the page scrolls
/// over it.
struct ChantSavedScrollReading: ViewModifier {
    let scroll: ChantSavedScroll

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, risen in
                scroll.set(rise: risen)
            }
        } else {
            content
        }
    }
}

// MARK: - ChantSavedPainting

/// The painting at the head of the page, run to the top of the glass and
/// dissolving into the page beneath the switch, as a Prayer Book topic's
/// does. A veil under the bar and the switch keeps their words readable.
/// It rises with the page, and crossfades when the shelf changes, Reduce
/// Motion or not, since a crossfade is not travel.
struct ChantSavedPainting: View {
    let name: String
    let scroll: ChantSavedScroll

    /// How far the painting reaches below the bar: past the switch and no
    /// further, so the chants beneath stand on the bare page
    static let reach: CGFloat = 110

    var body: some View {
        // A band as tall as the reach, from the bar's foot down, whose
        // painting runs on up under the bar and the status bar: drawn as
        // its background with the top safe area ignored, so its height
        // never waits on a measurement
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: Self.reach)
            .background(alignment: .bottom) {
                painting
                    .ignoresSafeArea(edges: .top)
            }
            .offset(y: -scroll.rise)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var painting: some View {
        ZStack {
            CachedAssetImage(name, focal: ChantThumbnail.focalPoint(for: name))
                .id(name)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .overlay {
            // A veil under the status bar, the title and the switch
            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0.7), location: 0),
                    .init(color: AppColors.background.opacity(0.45), location: 0.55),
                    .init(color: AppColors.background.opacity(0.2), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        // Dissolves to clear, so the page's own gradient shows through
        // beneath it rather than a slab of one colour
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.5),
                    .init(color: .black.opacity(0.35), location: 0.8),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(Motion.crossfade, value: name)
    }
}

// MARK: - ChantSavedSection

/// The page beneath its painting: the switch, the shelf chosen, the
/// reader's sets, what was sung lately, and the words
struct ChantSavedSection: View {

    /// The shelf shown, which the page works out (`ChantSavedShelf.shown`)
    let shown: ChantSavedShelf
    @Binding var choice: ChantSavedShelf?
    let shelf: ChantShelfStore
    let clock: ChantSavedClock

    @Environment(AppRouter.self) private var router

    private var player = ChantPlayer.shared

    @State private var namingSet = false

    init(
        shown: ChantSavedShelf,
        choice: Binding<ChantSavedShelf?>,
        shelf: ChantShelfStore = .shared,
        clock: ChantSavedClock = .device
    ) {
        self.shown = shown
        _choice = choice
        self.shelf = shelf
        self.clock = clock
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 18) {
                ChantShelfSwitch(
                    shown: shown,
                    favorites: shelf.favorites.count,
                    learned: shelf.learned.count
                ) { chosen in
                    withAnimation(Motion.choice) { choice = chosen }
                }
                .padding(.horizontal, 18)

                // One slot the shelves crossfade in, so the one leaving and
                // the one arriving are never laid out one above the other
                ZStack(alignment: .top) {
                    switch shown {
                    case .favorites:
                        list(.favorites, chants: shelf.favoriteChants)
                            .transition(.opacity)
                    case .learned:
                        list(.learned, chants: shelf.learnedChants)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 18)
                .animation(Motion.crossfade, value: shown)
            }

            sets

            if !shelf.recent.isEmpty {
                recentlyPlayed
                    .padding(.horizontal, 18)
            }

            words
                .padding(.horizontal, 18)
        }
        .sheet(isPresented: $namingSet) {
            ChantNewSetSheet(shelf: shelf) { set in router.push(.chantSet(.own(set.id))) }
                .presentationDetents([.medium])
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }

    private func open(_ chant: Chant) {
        router.push(ChantTap.route(to: chant))
    }

    // MARK: - The shelf chosen

    @ViewBuilder
    private func list(_ which: ChantSavedShelf, chants: [Chant]) -> some View {
        if chants.isEmpty {
            ChantSavedEmpty(painting: which.emptyArchPainting, line: which.emptyLine)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        } else {
            VStack(spacing: 0) {
                ForEach(chants) { chant in
                    // The library's song row, with the disc that plays the
                    // chant where it stands laid over its painting, as a
                    // square card's is: beside the row, it cut the English
                    // line short
                    ChantSongRow(chant: chant, player: player) { open(chant) }
                        .overlay(alignment: .leading) {
                            ChantPlayDisc(
                                isPlaying: player.isPlaying(chant),
                                isLoading: player.current.id == chant.id && player.isLoading,
                                size: 26,
                                label: chant.spokenNameAndSetting
                            ) {
                                player.toggle(chant)
                            }
                            .frame(width: 44)
                            // A hold on the painting is a hold on the row
                            .chantContextMenu(chant)
                        }
                }
            }
        }
    }

    // MARK: - Your sets

    private var sets: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your sets")
                    .font(AppFonts.titleFont(17))
                    .foregroundColor(AppColors.cream)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                // While covers stand on the shelf the new one may be off
                // the glass's edge, so the heading offers it too
                if !shelf.sets.isEmpty {
                    Button {
                        namingSet = true
                    } label: {
                        HStack(spacing: 5) {
                            AppIcon("ph-plus", size: 10)
                            Text("NEW SET")
                                .font(AppFonts.labelFont(10))
                                .tracking(2)
                        }
                        .foregroundColor(AppColors.gold)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    // The dashed cover at the shelf's end is VoiceOver's
                    // one door to a new set, so it is not heard twice
                    .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 30)
            .padding(.horizontal, 18)

            ChantSideScroll {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(shelf.sets) { set in
                        ChantSavedSetCover(set: set) {
                            router.push(.chantSet(.own(set.id)))
                        }
                    }
                    ChantNewSetCover { namingSet = true }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    // MARK: - Played lately

    private var recentlyPlayed: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Played lately")
                .font(AppFonts.titleFont(17))
                .foregroundColor(AppColors.cream)
                .frame(minHeight: 30)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ForEach(shelf.recent, id: \.chantID) { play in
                    if let chant = ChantCatalog.chant(play.chantID) {
                        let when = Self.when(play.at, now: clock.now(), calendar: clock.calendar, locale: clock.locale)
                        Button {
                            open(chant)
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 14) {
                                Text(when)
                                    .font(AppFonts.readingItalicFont(14))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.86)
                                    .frame(width: 112, alignment: .leading)
                                // A Latin title never stands alone: the
                                // English beneath it, quieter
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(chant.latinTitle)
                                        .font(AppFonts.readingFont(16))
                                        .foregroundColor(AppColors.cream.opacity(0.9))
                                        .lineLimit(1)
                                    Text(chant.englishTitle)
                                        .font(AppFonts.readingItalicFont(13.5))
                                        .foregroundColor(AppColors.textSecondary)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 8)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(when), \(chant.spokenName)")
                        .accessibilityHint("Opens the chant")
                        .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
    }

    /// "Tonight", "This morning", "Yesterday", "Tuesday", "Sep 12"
    static func when(_ date: Date, now: Date = Date(), calendar: Calendar = .current,
                     locale: Locale = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            let hour = calendar.component(.hour, from: date)
            switch hour {
            case ..<12: return "This morning"
            case 12..<18: return "This afternoon"
            default: return "Tonight"
            }
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        var style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        if let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day,
           (0..<7).contains(days) {
            // A play dated after now, the clock turned back, takes its date
            style = style.weekday(.wide)
        } else {
            style = style.day().month(.abbreviated)
        }
        return date.formatted(style)
    }

    // MARK: - Words

    /// The library's one setting, as one line at the foot
    private var words: some View {
        Menu {
            Picker("Words", selection: Binding(get: { shelf.words }, set: { shelf.words = $0 })) {
                ForEach(ChantWordsPreference.allCases) { preference in
                    Text(preference.title).tag(preference)
                }
            }
        } label: {
            HStack(spacing: 8) {
                AppIcon("ph-text-aa", size: 15)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                Text("Words")
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                Text(shelf.words.title)
                    .font(AppFonts.readingFont(15))
                    .foregroundColor(AppColors.goldLight)
                AppIcon("ph-caret-down", size: 10)
                    .foregroundColor(AppColors.gold.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Words: \(shelf.words.title)")
    }
}

// MARK: - ChantShelfSwitch

/// Favourites or Learned: a pill of two halves, the lit one on a raised
/// ground ringed in gold, as a Rosary's own choices are drawn. Each half
/// is a button that says its count to VoiceOver.
struct ChantShelfSwitch: View {
    let shown: ChantSavedShelf
    let favorites: Int
    let learned: Int
    let choose: (ChantSavedShelf) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A count rolls its digits to a new number, but under Reduce Motion
    /// it only changes, as every crossfade on the page still fades
    static func countTransition(reduceMotion: Bool) -> ContentTransition {
        .chantCount(reduceMotion: reduceMotion)
    }

    var body: some View {
        HStack(spacing: 0) {
            segment(.favorites, count: favorites)
            segment(.learned, count: learned)
        }
        .padding(3)
        // One capsule, filled and ringed together, so no edge of the
        // fill shows past the ring
        .background {
            Capsule()
                .fill(AppColors.background.opacity(0.72))
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline))
        }
        .sensoryFeedback(.selection, trigger: shown)
    }

    private func segment(_ shelf: ChantSavedShelf, count: Int) -> some View {
        let on = shelf == shown
        return Button {
            choose(shelf)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(shelf.title.uppercased())
                    .font(AppFonts.labelFont(12))
                    .tracking(1.6)
                // A count stands only once there is something to count
                if count > 0 {
                    Text("\(count)")
                        .font(AppFonts.readingFont(15))
                        .monospacedDigit()
                        .contentTransition(Self.countTransition(reduceMotion: reduceMotion))
                        .animation(Motion.crossfade, value: count)
                        .transition(.opacity)
                }
            }
            .animation(Motion.crossfade, value: count > 0)
            .foregroundColor(on ? AppColors.goldLight : AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if on {
                    Capsule()
                        .fill(AppColors.cardElevated)
                        .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.7), lineWidth: 1))
                }
            }
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([shelf.title, ChantSavedShelf.spokenCount(count)].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - ChantSavedEmpty

/// An empty shelf: its painting, faded, under an arch, and one line
struct ChantSavedEmpty: View {
    let painting: String
    let line: String

    var body: some View {
        VStack(spacing: 16) {
            CachedAssetImage(painting, focal: ChantThumbnail.focalPoint(for: painting))
                .frame(width: 132, height: 166)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 66, bottomLeadingRadius: 12,
                                                  bottomTrailingRadius: 12, topTrailingRadius: 66))
                .opacity(0.35)
                .accessibilityHidden(true)
            Text(line)
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.78))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - ChantSavedSetCover

/// One of the reader's sets as a square cover — its first chant's
/// painting, as the library's Sets of Chants draw it — over its name and how
/// many chants and minutes. It opens the set's page.
struct ChantSavedSetCover: View {
    let set: ChantSet
    let open: () -> Void

    static let side: CGFloat = 150

    var body: some View {
        Button(action: open) {
            VStack(alignment: .leading, spacing: 7) {
                ChantThumbnail(
                    name: self.set.painting,
                    size: Self.side,
                    radius: 14
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(set.name)
                        .font(AppFonts.readingFont(15.5))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Self.summary(of: set))
                        .font(AppFonts.readingItalicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                }
            }
            .frame(width: Self.side, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spoken(set))
        .accessibilityHint("Opens the set")
        .accessibilityAddTraits(.isButton)
    }

    /// "4 chants · 20 min" — the length of its recordings and silences,
    /// never a guess — or, for a set with nothing in it yet, just that
    static func summary(of set: ChantSet) -> String {
        guard set.chantCount > 0 else { return "No chants yet" }
        return ChantSetCard.summary(count: set.chantCount, duration: set.duration)
    }

    /// "Thursday holy hour, 4 chants, 20 minutes"
    static func spoken(_ set: ChantSet) -> String {
        guard let chants = ChantSavedShelf.spokenCount(set.chantCount) else { return "\(set.name), no chants yet" }
        return "\(set.name), \(chants), \(spokenMinutes(set.duration))"
    }

    /// "20 minutes": the length rounded to the minute, never under one
    static func spokenMinutes(_ duration: TimeInterval) -> String {
        let whole = max(1, Int((duration / 60).rounded()))
        return whole == 1 ? "1 minute" : "\(whole) minutes"
    }
}

// MARK: - ChantNewSetCover

/// The last cover on the sets' shelf, dashed: a new set, named first
struct ChantNewSetCover: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                AppIcon("ph-plus", size: 22)
                Text("NEW SET")
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
            }
            .foregroundColor(AppColors.gold)
            .frame(width: ChantSavedSetCover.side, height: ChantSavedSetCover.side)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("Make a new set")
    }
}
