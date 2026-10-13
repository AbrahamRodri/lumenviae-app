//
//  ChantView.swift
//  Lumen Viae
//
//  One chant on a page of its own, its Now Playing: the chant's painting
//  at the head of the page, dissolving into it, its name in Latin and in
//  English over it; then what is being sung, the score and the line with
//  its English beneath when the chant's lines have been timed; the
//  scrubber and three controls around the gold play, back and on by the
//  line (or by ten seconds); and one quiet capsule of the tools used
//  less, the line or the chant again, a slower pace, the singer and the
//  reader taking turns, and a sleep timer. The words, favourite, a set,
//  the score enlarged and the source stand in the ⋯ menu.
//
//  A scroll away: learning the chant by heart, as a card; the prayer the
//  chant sings and its other settings, as the library's rows; the credit
//  at the foot, as the recordings' licence asks.
//
//  Every line-by-line control stands only for a chant that has lines
//  (`Chant.hasLines`). The rest step by ten seconds and repeat the whole
//  chant: no timing is guessed.
//
//  Reached from the Chant Library, a prayer's own page ("Hear it sung"),
//  and the mini player (`AppRoute.chant(id:)`).
//

import SwiftUI

struct ChantView: View {

    let chantID: String

    @Environment(AppRouter.self) private var router

    @State private var showsScore = false
    @State private var showsWords = false
    @State private var showsSleep = false
    @State private var addingToSet = false
    @State private var practicing: Chant?
    @State private var wordsUnderBar = false
    /// Where the bar ends, measured: the top safe area, which inside the
    /// navigation stack runs past the status bar to the bar's foot
    @State private var barFoot: CGFloat = 110

    private var shelf: ChantShelfStore
    /// Opens scrolled to the foot, for a snapshot of what stands there
    private let opensAtFoot: Bool

    init(chantID: String, shelf: ChantShelfStore = .shared, opensAtFoot: Bool = false) {
        self.chantID = chantID
        self.shelf = shelf
        self.opensAtFoot = opensAtFoot
    }

    private var chant: Chant? { ChantCatalog.chant(chantID) }

    /// How tall the painting hangs, from the top of the glass
    static let heroHeight: CGFloat = 330
    /// Where the title begins, measured from the top of the glass, so it
    /// stands on the painting's dissolving foot
    static let titleTop: CGFloat = 200

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            if let chant {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // The title gives the column its height; the
                        // painting hangs behind it and takes no room, so
                        // the score stands 22 points under the subtitle
                        // however many lines the names take
                        titleBlock(chant)
                            .padding(.horizontal, 28)
                            // Measured on the names themselves, before the
                            // room above them: under the bar once they rise
                            // past its foot
                            .onGeometryChange(for: Bool.self) { proxy in
                                proxy.frame(in: .global).minY < barFoot
                            } action: { under in
                                withAnimation(Motion.crossfade) { wordsUnderBar = under }
                            }
                            .padding(.top, Self.titleTop)
                            .devotionalEntrance()

                        scorePanel(chant)
                            .padding(.horizontal, 20)
                            .padding(.top, 22)

                        NowPlayingLine(chant: chant)
                            .padding(.horizontal, 26)
                            .padding(.top, 14)

                        NowPlayingTransport(chant: chant)
                            .padding(.horizontal, 22)
                            .padding(.top, 18)

                        NowPlayingTools(chant: chant, showSleep: { showsSleep = true })
                            .padding(.top, 20)

                        learnCard(chant)
                            .padding(.horizontal, 22)
                            .padding(.top, 32)

                        doors(chant)
                            .padding(.horizontal, 22)

                        ChantCredit()
                            .padding(.horizontal, 36)
                            .padding(.top, 36)
                            .padding(.bottom, 48)
                    }
                    .background(alignment: .top) { ChantHero(chant: chant) }
                }
                .ignoresSafeArea(edges: .top)
                .defaultScrollAnchor(opensAtFoot ? .bottom : .top)
                .overlay(alignment: .top) { barVeil }
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.safeAreaInsets.top
                } action: { barFoot = $0 }
            } else {
                Text("This chant could not be found.")
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { router.pop() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                    .modifier(BarControlGround(shape: Capsule(), horizontal: 12))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if let chant { moreMenu(chant) }
            }
        }
        .sheet(isPresented: $showsScore) {
            if let chant {
                ChantScoreSheet(chant: chant)
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            }
        }
        .sheet(isPresented: $showsWords) {
            if let chant {
                ChantWordsSheet(chant: chant)
                    .presentationDetents([.medium, .large])
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            }
        }
        .sheet(isPresented: $showsSleep) {
            ChantSleepSheet()
                .presentationDetents([.medium])
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(isPresented: $addingToSet) {
            if let chant {
                ChantAddToSetSheet(chant: chant)
                    .presentationDetents([.medium, .large])
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            }
        }
        .fullScreenCover(item: $practicing) { chant in
            ChantPracticeView(chant: chant)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
                .presentationBackground(AppColors.background)
        }
    }

    // MARK: - Chrome

    /// A veil under the status bar and the bar's Back and ⋯: light over
    /// the painting at rest, and near opaque down past the bar once the
    /// title travels under it, so no word of the page stands inside them
    /// Both layers are sized from the bar's measured foot, so a phone with
    /// a shorter or a taller bar gets the same veil, never a solid band
    /// over words still in view below the bar.
    private var barVeil: some View {
        let veilHeight = barFoot + 60
        return ZStack(alignment: .top) {
            LinearGradient(
                colors: [AppColors.background.opacity(0.55), AppColors.background.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: barFoot)

            // Opaque to a little past the bar's foot, clear by 60 points
            // past it
            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0.99), location: 0),
                    .init(color: AppColors.background.opacity(0.99), location: (barFoot + 20) / veilHeight),
                    .init(color: AppColors.background.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: veilHeight)
            .opacity(wordsUnderBar ? 1 : 0)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    /// What the ⋯ menu holds, in its order: everything used less, in one
    /// place. Stop Learning stands only while a step is under way.
    enum MoreItem: Equatable {
        case favourite
        case addToSet
        case words
        case enlargeScore
        case stopLearning
        case source

        static func items(stepUnderWay: Bool) -> [MoreItem] {
            [.favourite, .addToSet, .words, .enlargeScore]
                + (stepUnderWay ? [.stopLearning] : [])
                + [.source]
        }
    }

    private func moreMenu(_ chant: Chant) -> some View {
        Menu {
            ForEach(MoreItem.items(stepUnderWay: shelf.step(of: chant.id) != nil), id: \.self) { item in
                moreButton(item, chant: chant)
            }
        } label: {
            AppIcon("ph-dots-three", size: 22)
                .foregroundColor(AppColors.gold)
                .modifier(BarControlGround(shape: Circle(), horizontal: 0))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More options")
    }

    @ViewBuilder
    private func moreButton(_ item: MoreItem, chant: Chant) -> some View {
        switch item {
        case .favourite:
            Button {
                shelf.toggleFavorite(chant.id)
            } label: {
                if shelf.isFavorite(chant.id) {
                    Label("Remove from Favourites", systemImage: "heart.slash")
                } else {
                    Label("Add to Favourites", systemImage: "heart")
                }
            }
        case .addToSet:
            Button {
                addingToSet = true
            } label: {
                Label("Add to a Set", systemImage: "text.badge.plus")
            }
        case .words:
            Button {
                showsWords = true
            } label: {
                Label("Words", systemImage: "textformat")
            }
        case .enlargeScore:
            Button {
                showsScore = true
            } label: {
                Label("Enlarge the Sheet Music", systemImage: "arrow.up.left.and.arrow.down.right")
            }
        case .stopLearning:
            // A chant under way can be put down, and nothing then says it
            // was ever begun
            Button {
                shelf.stopLearning(chant.id)
            } label: {
                Label("Stop Learning", systemImage: "xmark.circle")
            }
        case .source:
            Link(destination: chant.sourceURL) {
                Label("Open on Verbum Gloriae's Site", systemImage: "safari")
            }
        }
    }

    // MARK: - Title

    private func titleBlock(_ chant: Chant) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text(chant.latinTitle)
                    .font(AppFonts.titleFont(28))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.7), radius: 12)
                    .accessibilityAddTraits(.isHeader)
                if shelf.isFavorite(chant.id) {
                    AppIcon("ph-heart-fill", size: 13)
                        .foregroundColor(AppColors.gold.opacity(0.8))
                        .shadow(color: .black.opacity(0.7), radius: 8)
                        .accessibilityLabel("A favourite")
                }
            }

            Text(subtitle(chant))
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.75))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.6), radius: 10)
        }
        .frame(maxWidth: .infinity)
    }

    private func subtitle(_ chant: Chant) -> String {
        if let setting = chant.settingMidLine {
            return "\(chant.englishTitle) · \(setting)"
        }
        return chant.englishTitle
    }

    // MARK: - Score

    /// The score, unboxed: the part being sung when the lines say which,
    /// the opening part otherwise, its foot dissolving, and beneath the
    /// dissolve a small mark that says a tap enlarges it.
    private func scorePanel(_ chant: Chant) -> some View {
        Button {
            showsScore = true
        } label: {
            VStack(spacing: 2) {
                NowPlayingScore(chant: chant)
                    .frame(maxWidth: .infinity)
                    .frame(height: 132, alignment: .top)
                    .clipped()
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.7),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(AppColors.gold.opacity(0.75))
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("The sheet music")
        .accessibilityHint("Opens the sheet music full screen")
    }

    // MARK: - Learn

    /// The Learn card's words: what a tap does, and where the learner
    /// stands. The three labels are the ones the page has always used.
    static func learnWords(learned: Bool, step: ChantLearningStep?) -> (title: String, note: String) {
        if learned {
            return ("Practise again", "Learned")
        }
        if let step {
            return ("Continue learning", "Step \(step.rawValue) of 4 · \(step.title)")
        }
        return ("Learn this chant", "Four steps: listen, read along, sing along, on your own")
    }

    private func learnCard(_ chant: Chant) -> some View {
        let learned = shelf.isLearned(chant.id)
        let step = shelf.step(of: chant.id)
        let words = Self.learnWords(learned: learned, step: step)
        return Button {
            practicing = chant
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    ChantStepBeads(step: step, learned: learned)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(words.title)
                            .font(AppFonts.titleFont(16))
                            .foregroundColor(AppColors.cream)
                        Text(words.note)
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                AppIcon("ph-caret-right", size: 13)
                    .foregroundColor(AppColors.gold)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: AppLine.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
            // One label for the whole card, set on what the button draws
            // so the button stays the one element: set on the button, the
            // beads' own label was read as a second
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(words.title). \(words.note)")
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityHint("Opens a practice, step by step")
    }

    // MARK: - Doors

    @ViewBuilder
    private func doors(_ chant: Chant) -> some View {
        let prayers = chant.prayerIDs.compactMap { id in
            PrayerBook.prayer(id) ?? BookPrayer.bundled(id, origin: nil, note: nil)
        }
        let others = ChantCatalog.otherSettings(of: chant)

        if !prayers.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ChantSectionHeading(kicker: nil, title: "The prayer it sings", titleSize: 17)
                VStack(spacing: 0) {
                    ForEach(prayers, id: \.id) { prayer in
                        ChantPrayerRow(prayer: prayer) {
                            router.push(.devotionPrayer(id: prayer.id))
                        }
                    }
                }
            }
            .padding(.top, 36)
        }

        if !others.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ChantSectionHeading(kicker: nil, title: "Also sung", titleSize: 17)
                VStack(spacing: 0) {
                    ForEach(others) { other in
                        ChantSongRow(chant: other, player: ChantPlayer.shared) {
                            router.push(.chant(id: other.id))
                        }
                    }
                }
            }
            .padding(.top, prayers.isEmpty ? 36 : 28)
        }
    }
}

// MARK: - BarControlGround

/// A dark ground behind the bar's Back and ⋯ where the system draws no
/// glass of its own (before iOS 26), so both read over any painting.
/// iOS 26 draws its glass capsule, and a second inside it would be a
/// capsule in a capsule.
private struct BarControlGround<S: Shape>: ViewModifier {
    let shape: S
    let horizontal: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content
                .padding(.horizontal, horizontal)
                .frame(minWidth: 36, minHeight: 36)
                .background(shape.fill(AppColors.background.opacity(0.55)))
        }
    }
}

// MARK: - ChantHero

/// The chant's own painting, the one the library's rows show, run to the
/// top of the glass and dissolving into the page beneath the title
private struct ChantHero: View {
    let chant: Chant

    var body: some View {
        let name = ChantCatalog.painting(for: chant)
        CachedAssetImage(name, focal: ChantThumbnail.focalPoint(for: name))
            .frame(maxWidth: .infinity)
            .frame(height: ChantView.heroHeight)
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.45),
                        .init(color: .black.opacity(0.35), location: 0.72),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .accessibilityHidden(true)
    }
}

// MARK: - ChantPrayerRow

/// The prayer a chant sings, as a row beside the library's song rows: its
/// glyph where they hang a painting, its name over its Latin, a caret
private struct ChantPrayerRow: View {
    let prayer: BookPrayer
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                AppIcon("ch-praying-hands", size: 20)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(prayer.title)
                        .font(AppFonts.readingFont(16.5))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                    if let latin = prayer.secondTitle {
                        Text(latin)
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.gold)
            }
            .padding(.vertical, 9)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.12))
                .frame(height: AppLine.hairline)
        }
        .accessibilityHint("Opens the prayer in words")
    }
}

// MARK: - NowPlayingScore

/// The score part the line under the hand is engraved on — or the first,
/// for a chant whose lines name no part
private struct NowPlayingScore: View {
    let chant: Chant

    private var player = ChantPlayer.shared

    init(chant: Chant) {
        self.chant = chant
    }

    var body: some View {
        let index = player.holds(chant) ? (player.currentLine?.part ?? 0) : 0
        let part = chant.score.indices.contains(index) ? chant.score[index] : chant.score.first
        ZStack(alignment: .top) {
            if let part {
                // Drawn at the window's full width and its own height, so a
                // tall score is cut by the window rather than shrunk to fit
                // inside it
                ChantScoreImage(part: part)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(part.file)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(Motion.crossfade, value: part?.file)
    }
}

// MARK: - NowPlayingLine

/// The line being sung, the Latin over its English, crossfading whole
/// as the next comes; or, for a chant whose lines have not been timed,
/// when it is sung. The reader's turn, while it lasts, is said here.
private struct NowPlayingLine: View {
    let chant: Chant

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    init(chant: Chant) {
        self.chant = chant
    }

    var body: some View {
        let line = chant.hasLines
            ? (player.holds(chant) ? player.currentLine : chant.lines.first)
            : nil

        VStack(spacing: 14) {
            lineSlot(line)
            // The reader's turn stands under the line it asks for
            if let turn = player.turn, player.holds(chant) {
                ChantYourTurn(turn: turn)
                    .transition(.opacity)
            }
        }
        .animation(Motion.crossfade, value: player.turn)
    }

    private func lineSlot(_ line: ChantLine?) -> some View {
        ZStack {
            if let line {
                VStack(spacing: 5) {
                    if shelf.words.showsLatin {
                        Text(line.latin)
                            .font(AppFonts.readingFont(21))
                            .foregroundColor(AppColors.goldLight)
                            .lineSpacing(3)
                    }
                    if shelf.words.showsEnglish {
                        Text(line.english)
                            .font(AppFonts.readingItalicFont(16))
                            .foregroundColor(AppColors.cream.opacity(0.72))
                    }
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id(line)
                .transition(.opacity)
                .accessibilityElement(children: .combine)
            } else {
                Text(chant.detail)
                    .font(AppFonts.readingItalicFont(16.5))
                    .foregroundColor(AppColors.cream.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: chant.hasLines ? 76 : 0)
        .animation(Motion.words, value: line)
    }
}

// MARK: - ChantYourTurn

/// "Your turn": the line the singer sang is the reader's to sing back,
/// for as long as the singer took over it
struct ChantYourTurn: View {
    let turn: ChantTurn
    var subtitle = "The singer sang the line. Now sing it back."

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Your turn")
                    .font(AppFonts.readingFont(16))
                    .foregroundColor(AppColors.goldLight)
                Text(subtitle)
                    .font(AppFonts.readingItalicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            // Paused, the turn keeps what was left of it, and says so still
            TimelineView(.animation(minimumInterval: 0.1, paused: turn.endsAt == nil)) { context in
                let left = turn.endsAt.map { max(0, $0.timeIntervalSince(context.date)) } ?? turn.remaining
                Text(String(format: "%.0f", left.rounded(.up)))
                    .font(AppFonts.titleFont(20))
                    .foregroundColor(AppColors.goldLight.opacity(turn.endsAt == nil ? 0.55 : 1))
                    .monospacedDigit()
                    .frame(minWidth: 28)
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.gold.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AppColors.gold.opacity(0.6), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - NowPlayingTransport

/// The page's transport: the scrubber and the time, and three controls,
/// back, the gold play and on. A view of its own so that the recording's
/// progress, read twice a second, redraws the transport alone — read in
/// the page's body, it redrew the title, the doors and the score with it.
private struct NowPlayingTransport: View {
    let chant: Chant

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var player = ChantPlayer.shared

    init(chant: Chant) {
        self.chant = chant
    }

    var body: some View {
        let holds = player.holds(chant)
        let progress = holds ? player.progress : 0
        let elapsed = holds ? player.currentTime : 0
        let total = holds ? player.duration : chant.duration
        let lines = chant.hasLines

        return VStack(spacing: 16) {
            VStack(spacing: 4) {
                ChantScrubber(progress: progress, duration: total, isEnabled: holds) { fraction in
                    player.seek(toFraction: fraction)
                }
                HStack {
                    Text(ChantPlayer.clock(elapsed))
                        .contentTransition(.chantCount(reduceMotion: reduceMotion))
                    Spacer()
                    if lines {
                        Text("Line \((holds ? player.lineIndex ?? 0 : 0) + 1) of \(chant.lines.count)")
                            .font(AppFonts.readingItalicFont(13))
                            .contentTransition(.chantCount(reduceMotion: reduceMotion))
                        Spacer()
                    }
                    Text(ChantPlayer.clock(total))
                }
                .font(AppFonts.labelFont(9))
                .tracking(1.5)
                .foregroundColor(AppColors.textSecondary)
                .monospacedDigit()
                .accessibilityHidden(true)
            }

            HStack(spacing: 34) {
                stepButton(back: true, lines: lines, holds: holds)
                // The reader's turn is the chant going on: drawn as pause,
                // and a tap holds it
                ChantGoldPlayButton(
                    isPlaying: player.holds(chant) && player.chantGoesOn,
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 68,
                    label: chant.spokenName
                ) {
                    player.toggle(chant)
                }
                stepButton(back: false, lines: lines, holds: holds)
            }

            if let error = player.current.id == chant.id ? player.errorMessage : nil {
                Text(error)
                    .font(AppFonts.italicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private func stepButton(back: Bool, lines: Bool, holds: Bool) -> some View {
        Button {
            if lines {
                if back { player.previousLine() } else { player.nextLine() }
            } else {
                player.skip(by: back ? -10 : 10)
            }
        } label: {
            Group {
                if lines {
                    AppIcon(back ? "ph-skip-back" : "ph-skip-forward", size: 22)
                } else {
                    // The system's own glyph, since it carries its number
                    Image(systemName: back ? "gobackward.10" : "goforward.10")
                        .font(.system(size: 21, weight: .light))
                }
            }
            .foregroundColor(AppColors.gold.opacity(holds ? 1 : 0.35))
            .frame(width: 48, height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .disabled(!holds)
        .accessibilityLabel(lines
            ? (back ? "Previous line" : "Next line")
            : (back ? "Back ten seconds" : "Forward ten seconds"))
    }
}

// MARK: - NowPlayingTools

/// The tools used less, in one quiet capsule under the transport: the
/// line (or the chant) again, the slower pace, taking turns with the
/// singer, and the sleep timer. Each a button of its own to VoiceOver.
struct NowPlayingTools: View {
    let chant: Chant
    let showSleep: () -> Void

    private var player = ChantPlayer.shared

    init(chant: Chant, showSleep: @escaping () -> Void) {
        self.chant = chant
        self.showSleep = showSleep
    }

    enum Tool: Equatable {
        case again
        case speed
        case takeTurns
        case sleep
    }

    /// The capsule's tools, in order. Taking turns asks for the chant's
    /// lines, so it stands only where they are timed.
    static func tools(for chant: Chant) -> [Tool] {
        chant.hasLines ? [.again, .speed, .takeTurns, .sleep] : [.again, .speed, .sleep]
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Self.tools(for: chant), id: \.self) { tool in
                switch tool {
                case .again: repeatButton
                case .speed: speedButton
                case .takeTurns: takeTurnsButton
                case .sleep: sleepButton
                }
            }
        }
        .padding(3)
        .background(Capsule(style: .circular).strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline))
    }

    private var repeatButton: some View {
        let holds = player.holds(chant)
        let lines = chant.hasLines
        let isOn = lines ? (holds && player.lineEnd == .again) : player.repeats
        return Button {
            if lines {
                if !holds { player.play(chant) }
                player.setLineEnd(player.lineEnd == .again ? .goOn : .again)
            } else {
                player.repeats.toggle()
            }
        } label: {
            segment(isOn: isOn) {
                AppIcon(lines ? "ph-repeat-once" : "ph-repeat", size: 20)
            }
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel(lines ? "Repeat this line" : "Repeat the chant")
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
        .sensoryFeedback(.selection, trigger: isOn)
    }

    private var speedButton: some View {
        // The speed sounding, which the Lock Screen may have changed
        let speed = player.speed
        let slow = speed < 1
        return Button {
            player.setRate(slow ? 1.0 : 0.75)
        } label: {
            segment(isOn: slow) {
                Text(ChantPlayer.speedLabel(speed))
                    .font(AppFonts.readingFont(16))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel(slow ? "Speed, slower" : speed > 1 ? "Speed, faster" : "Speed, normal")
        .accessibilityAddTraits(slow ? [.isSelected] : [])
        .accessibilityHint(slow ? "Plays at the normal speed" : "Plays at three-quarters speed, for learning")
    }

    private var takeTurnsButton: some View {
        let holds = player.holds(chant)
        let isOn = holds && player.lineEnd == .takeTurns
        return Button {
            if !holds { player.play(chant) }
            player.setLineEnd(player.lineEnd == .takeTurns ? .goOn : .takeTurns)
        } label: {
            segment(isOn: isOn) {
                AppIcon("ph-arrows-left-right", size: 20)
            }
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("Take turns")
        .accessibilityHint("The singer sings a line, then waits while you sing it back")
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private var sleepButton: some View {
        let isOn = player.hasSleepTimer
        return Button(action: showSleep) {
            segment(isOn: isOn) {
                AppIcon("ph-moon-stars", size: 20)
            }
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("Sleep timer")
        .accessibilityValue(isOn ? "On" : "")
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    /// One segment: a 44-point touch, lit on a wash of gold while on,
    /// never filled
    private func segment(isOn: Bool, @ViewBuilder content: () -> some View) -> some View {
        content()
            .foregroundColor(isOn ? AppColors.goldLight : AppColors.gold)
            .frame(minWidth: 52, minHeight: 44)
            .padding(.horizontal, 2)
            .background(Capsule().fill(AppColors.gold.opacity(isOn ? 0.15 : 0)))
            .contentShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChantView(chantID: "salve_regina_simple")
            .environment(AppRouter())
    }
}
