//
//  ChantSavedSection.swift
//  Lumen Viae
//
//  The Saved board: what the reader has made of the library. A shelf of
//  spines — chants learned, favourites, and every set they have put
//  together, with a place for a new one — and beneath it the list chosen.
//  A set opens on its own page (`ChantSetPage`), where it is changed and
//  sung. Then what was sung lately, and the library's one setting, the
//  words.
//
//  Everything here is kept on the device (`ChantShelfStore`).
//

import SwiftUI

// MARK: - ChantSpineCloth

/// The spines on the Saved shelf, dyed from colours the app already
/// names: chants learned in the rubric's red, favourites in Marian blue,
/// and the reader's own sets in the vestments' green, violet, black and
/// rose, in turn — each laid thin on the dark page so it reads as cloth
enum ChantSpineCloth {
    static var learned: Color { Rubric.red.opacity(0.5) }
    static var favorites: Color { AppColors.marianBlue }
    static var sets: [Color] {
        [MissalVestment.green, .violet, .black, .rose].map { $0.swatch.opacity(0.55) }
    }
}

// MARK: - ChantSavedShelf

/// The shelf the Saved page opens on: the library's Your Chants names one
enum ChantSavedShelf: Hashable {
    case favorites
    case learned
}

// MARK: - ChantSavedPage

/// The reader's own chants on a page of their own, pushed from the
/// library's Your Chants: the spines, the shelf chosen, what was sung
/// lately and the words. The app-wide mini player stands at its foot.
struct ChantSavedPage: View {

    @Environment(AppRouter.self) private var router
    private let start: ChantSavedShelf

    init(start: ChantSavedShelf) {
        self.start = start
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(spacing: 10) {
                        Text("CHANT LIBRARY")
                            .font(AppFonts.labelFont(9.5))
                            .tracking(3)
                            .foregroundColor(AppColors.gold)
                        Text("Your Chants")
                            .font(AppFonts.titleFont(26))
                            .foregroundColor(AppColors.cream)
                            .accessibilityAddTraits(.isHeader)
                        Text("Your favourite chants, the ones you have learned, and sets you have made.")
                            .font(AppFonts.readingItalicFont(16))
                            .foregroundColor(AppColors.cream.opacity(0.78))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)

                    ChantSavedSection(
                        startsOn: start,
                        open: { router.push(ChantTap.route(to: $0)) },
                        openSet: { router.push(.chantSet(.own($0))) }
                    )
                }
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
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
    }
}

// MARK: - ChantSavedSection

struct ChantSavedSection: View {

    let open: (Chant) -> Void
    /// Opens a set of the reader's own on its page
    let openSet: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    private enum Spine: Hashable {
        case learned
        case favorites
    }

    @State private var spineChoice: Spine?
    @State private var namingSet = false
    /// The glass's width, so the shelf runs the whole gutter under a few
    /// spines
    @State private var shelfWidth: CGFloat = 0

    init(startsOn: ChantSavedShelf? = nil, open: @escaping (Chant) -> Void, openSet: @escaping (UUID) -> Void) {
        switch startsOn {
        case .learned:   _spineChoice = State(initialValue: .learned)
        case .favorites: _spineChoice = State(initialValue: .favorites)
        case nil:        break
        }
        self.open = open
        self.openSet = openSet
    }

    private var selected: Spine {
        if let spineChoice { return spineChoice }
        return shelf.favorites.isEmpty && !shelf.learned.isEmpty ? .learned : .favorites
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            spines

            // One slot the shelves crossfade in, so the one leaving and the
            // one arriving are never laid out one above the other
            ZStack(alignment: .top) {
                switch selected {
                case .learned:
                    list(
                        title: "Learned",
                        kicker: "By heart",
                        chants: shelf.learnedChants,
                        empty: "Chants you mark as learned by heart appear here."
                    )
                    .transition(.opacity)
                case .favorites:
                    list(
                        title: "Favourites",
                        kicker: "Saved",
                        chants: shelf.favoriteChants,
                        empty: "Press and hold any chant, or tap ⋯ on its page, to add it to your favourites."
                    )
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
            .animation(Motion.crossfade, value: selected)

            if !shelf.recent.isEmpty {
                recentlyPlayed
                    .padding(.horizontal, 20)
            }

            settings
                .padding(.horizontal, 20)
        }
        .sheet(isPresented: $namingSet) {
            ChantNewSetSheet { set in openSet(set.id) }
            .presentationDetents([.medium])
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }

    // MARK: - The shelf of spines

    private var spines: some View {
        ChantSideScroll {
            HStack(alignment: .bottom, spacing: 8) {
                // A count stands on a spine only once there is something to
                // count: an empty shelf is not told it has none
                spine(
                    "Learned",
                    note: Self.count(shelf.learned.count),
                    spokenNote: Self.spokenCount(shelf.learned.count),
                    cloth: ChantSpineCloth.learned,
                    height: 150,
                    lit: selected == .learned
                ) {
                    spineChoice = .learned
                }
                spine(
                    "Favourites",
                    note: Self.count(shelf.favorites.count),
                    spokenNote: Self.spokenCount(shelf.favorites.count),
                    cloth: ChantSpineCloth.favorites,
                    height: 166,
                    lit: selected == .favorites
                ) {
                    spineChoice = .favorites
                }
                ForEach(Array(shelf.sets.enumerated()), id: \.element.id) { index, set in
                    spine(
                        set.name,
                        note: "your set",
                        cloth: ChantSpineCloth.sets[index % ChantSpineCloth.sets.count],
                        height: [180, 158, 172, 162][index % 4],
                        lit: false
                    ) {
                        openSet(set.id)
                    }
                }
                newSpine
            }
            // As tall as the tallest spine chosen, whichever is, so the
            // page beneath never moves when another is taken down
            .frame(height: Self.tallest + Self.chosenRise, alignment: .bottom)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 6)
            // The shelf runs the gutter whatever stands on it, and on past
            // the glass with the spines once they outrun it
            .frame(minWidth: shelfWidth, alignment: .leading)
            .background(alignment: .bottom) {
                // The shelf they stand on
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.gold.opacity(0.45), AppColors.gold.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 6)
                    .padding(.horizontal, 12)
                    .accessibilityHidden(true)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { shelfWidth = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your saved chants and sets")
    }

    /// The tallest spine on the shelf, a set's
    private static let tallest: CGFloat = 180
    /// How much taller the chosen spine stands than its neighbours
    private static let chosenRise: CGFloat = 12

    private static func count(_ n: Int) -> String? {
        n > 0 ? "\(n)" : nil
    }

    private static func spokenCount(_ n: Int) -> String? {
        n > 0 ? (n == 1 ? "1 chant" : "\(n) chants") : nil
    }

    private func spine(
        _ title: String,
        note: String?,
        spokenNote: String? = nil,
        cloth: Color,
        height: CGFloat,
        lit: Bool,
        action: @escaping () -> Void
    ) -> some View {
        // The spine chosen stands taller than its neighbours, on the same
        // shelf; under Reduce Motion it is lit where it stands
        let tall = height + (lit && !reduceMotion ? Self.chosenRise : 0)
        return Button(action: action) {
            RoundedRectangle(cornerRadius: 4)
                .fill(cloth)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(AppColors.gold.opacity(lit ? 0.85 : 0.35), lineWidth: lit ? 1 : AppLine.hairline)
                }
                .overlay {
                    // Two tooled bands, as a book's spine carries
                    VStack {
                        Rectangle().fill(AppColors.gold.opacity(0.35)).frame(height: 1).padding(.top, 10)
                        Spacer()
                        Rectangle().fill(AppColors.gold.opacity(0.35)).frame(height: 1).padding(.bottom, 26)
                    }
                    .padding(.horizontal, 6)
                }
                .overlay {
                    // The title runs up the spine. Laid over the cloth, so
                    // the line it is set on before it turns never widens
                    // it: set in the spine's own stack, that line made every
                    // spine a hundred points wide, standing over its
                    // neighbours like a cover
                    Text(title.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(1.8)
                        .foregroundColor(AppColors.goldLight.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: tall - 52)
                        .rotationEffect(.degrees(-90))
                        .offset(y: -6)
                }
                .overlay(alignment: .bottom) {
                    if let note {
                        Text(note)
                            .font(AppFonts.readingItalicFont(10.5))
                            .foregroundColor(AppColors.cream.opacity(0.75))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 8)
                    }
                }
                .frame(width: 46, height: tall)
                .shadow(color: lit ? AppColors.gold.opacity(0.35) : .black.opacity(0.4), radius: lit ? 10 : 4, y: 3)
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .animation(Motion.settle, value: lit)
        .accessibilityLabel([title, spokenNote ?? note].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(lit ? [.isSelected, .isButton] : [.isButton])
    }

    private var newSpine: some View {
        Button {
            namingSet = true
        } label: {
            AppIcon("ph-plus", size: 16)
                .foregroundColor(AppColors.gold)
                .frame(width: 46, height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(AppColors.gold.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("Make a new set")
    }

    // MARK: - A list

    private func list(title: String, kicker: String, chants: [Chant], empty: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ChantSectionHeading(kicker: kicker, title: title)
            ChantRule()
            if chants.isEmpty {
                Text(empty)
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(chants) { chant in
                        ChantLibraryRow(chant: chant, player: player) {
                            open(chant)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recently played

    private var recentlyPlayed: some View {
        VStack(alignment: .leading, spacing: 10) {
            ChantSectionHeading(kicker: nil, title: "Recently played")
            ChantRule()
            VStack(spacing: 0) {
                ForEach(shelf.recent, id: \.chantID) { play in
                    if let chant = ChantCatalog.chant(play.chantID) {
                        Button {
                            open(chant)
                        } label: {
                            HStack(spacing: 14) {
                                Text(Self.when(play.at).uppercased())
                                    .font(AppFonts.labelFont(8))
                                    .tracking(1.5)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(width: 82, alignment: .leading)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(chant.latinTitle)
                                        .font(AppFonts.readingFont(16))
                                        .foregroundColor(AppColors.cream)
                                    Text(chant.englishTitle)
                                        .font(AppFonts.readingItalicFont(13))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 8)
                            .frame(minHeight: 48)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    /// "Tonight", "This morning", "Yesterday", "Tuesday", "12 Sep"
    static func when(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            let hour = calendar.component(.hour, from: date)
            switch hour {
            case ..<12: return "This morning"
            case 12..<18: return "This afternoon"
            default: return "Tonight"
            }
        }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day,
           days < 7 {
            return date.formatted(.dateTime.weekday(.wide))
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }

    // MARK: - Settings

    private var settings: some View {
        VStack(alignment: .leading, spacing: 10) {
            ChantSectionHeading(kicker: nil, title: "Settings")
            ChantRule()

            Menu {
                Picker("Words", selection: Binding(get: { shelf.words }, set: { shelf.words = $0 })) {
                    ForEach(ChantWordsPreference.allCases) { preference in
                        Text(preference.title).tag(preference)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text("Words")
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                    Spacer(minLength: 8)
                    Text(shelf.words.title)
                        .font(AppFonts.readingItalicFont(15))
                        .foregroundColor(AppColors.textSecondary)
                    AppIcon("ph-caret-down", size: 10)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                }
                .frame(minHeight: 48)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Words: \(shelf.words.title)")
            .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
        }
    }
}
