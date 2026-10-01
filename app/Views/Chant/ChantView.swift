//
//  ChantView.swift
//  Lumen Viae
//
//  One chant on a page of its own — the "Now Playing" board: its name in
//  Latin and in English, its score, the line being sung with its English
//  beneath when the chant's lines have been timed, and a transport made
//  for learning by ear: the line again (or the whole chant again), back
//  and on by the line (or by ten seconds), a slower pace, the cantor and
//  the reader taking turns line by line, the words, and a sleep timer.
//  "Learn this chant" opens its practice, step by step.
//
//  Beneath the fold: the prayer the chant sings, in words, and its other
//  settings (the solemn tone beside the simple), each a door; the credit
//  stands at the foot, as the recordings' licence asks.
//
//  Every line-by-line control stands only for a chant that has lines
//  (`Chant.hasLines`). The rest step by ten seconds and repeat the whole
//  chant: no timing is guessed.
//
//  Reached from the Chant Library, a prayer's own page ("Sing it in
//  chant"), and the Chapel's Chant tile (`AppRoute.chant(id:)`).
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

    private var shelf = ChantShelfStore.shared

    init(chantID: String) {
        self.chantID = chantID
    }

    private var chant: Chant? { ChantCatalog.chant(chantID) }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            if let chant {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        titleBlock(chant)
                            .padding(.horizontal, 28)
                            .devotionalEntrance()

                        scorePanel(chant)
                            .padding(.horizontal, 20)
                            .padding(.top, 22)

                        NowPlayingLine(chant: chant)
                            .padding(.horizontal, 26)
                            .padding(.top, 22)

                        NowPlayingTransport(
                            chant: chant,
                            showWords: { showsWords = true },
                            showSleep: { showsSleep = true }
                        )
                        .padding(.horizontal, 22)
                        .padding(.top, 20)

                        doors(chant)
                            .padding(.horizontal, 28)
                            .padding(.top, 40)

                        ChantCredit()
                            .padding(.horizontal, 36)
                            .padding(.top, 40)
                            .padding(.bottom, 48)
                    }
                    .padding(.top, 8)
                }
                .topChromeFade()
            } else {
                Text("This chant could not be found.")
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.textSecondary)
            }
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
            ToolbarItem(placement: .principal) {
                if let chant { learnButton(chant) }
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

    private func learnButton(_ chant: Chant) -> some View {
        let learned = shelf.isLearned(chant.id)
        let step = shelf.step(of: chant.id)
        return Button {
            practicing = chant
        } label: {
            Text(learned ? "Practise again" : step == nil ? "Learn this chant" : "Continue learning")
                .font(AppFonts.readingFont(14.5))
                .foregroundColor(AppColors.gold)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityHint("Opens a practice, step by step")
    }

    private func moreMenu(_ chant: Chant) -> some View {
        Menu {
            Button {
                shelf.toggleFavorite(chant.id)
            } label: {
                if shelf.isFavorite(chant.id) {
                    Label("Remove from Favourites", systemImage: "heart.slash")
                } else {
                    Label("Add to Favourites", systemImage: "heart")
                }
            }
            Button {
                addingToSet = true
            } label: {
                Label("Add to a Set", systemImage: "text.badge.plus")
            }
            Button {
                showsScore = true
            } label: {
                Label("Enlarge the Score", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            // A chant under way can be put down, and nothing then says it
            // was ever begun
            if shelf.step(of: chant.id) != nil {
                Button {
                    shelf.stopLearning(chant.id)
                } label: {
                    Label("Stop Learning", systemImage: "xmark.circle")
                }
            }
            Link(destination: chant.sourceURL) {
                Label("This Chant at Verbum Gloriae", systemImage: "safari")
            }
        } label: {
            AppIcon("ph-dots-three", size: 22)
                .foregroundColor(AppColors.gold)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More options")
    }

    // MARK: - Title

    private func titleBlock(_ chant: Chant) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text(chant.latinTitle)
                    .font(AppFonts.titleFont(26))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if shelf.isFavorite(chant.id) {
                    AppIcon("ph-heart-fill", size: 13)
                        .foregroundColor(AppColors.gold.opacity(0.8))
                        .accessibilityLabel("A favourite")
                }
            }

            Text(subtitle(chant))
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private func subtitle(_ chant: Chant) -> String {
        if let setting = chant.distinctSetting {
            return "\(chant.englishTitle) · \(setting.lowercased())"
        }
        return chant.englishTitle
    }

    // MARK: - Score

    /// The score in a window: the part being sung when the lines say
    /// which, the opening part otherwise, its foot dissolving. A tap
    /// opens the whole score large.
    private func scorePanel(_ chant: Chant) -> some View {
        Button {
            showsScore = true
        } label: {
            NowPlayingScore(chant: chant)
                .frame(maxWidth: .infinity)
                .frame(height: 210, alignment: .top)
                .clipped()
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.72),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.horizontal, 14)
                .padding(.top, 14)
                // A foot of its own for ENLARGE, beneath the score's
                // dissolve: laid over the last line, it was read through
                // the faded words
                .padding(.bottom, 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                )
                .overlay(alignment: .bottomTrailing) {
                    Text("ENLARGE")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.8))
                        .padding(12)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("The score")
        .accessibilityHint("Opens the score full screen")
    }

    // MARK: - Doors

    @ViewBuilder
    private func doors(_ chant: Chant) -> some View {
        let prayers = chant.prayerIDs.compactMap { id in
            PrayerBook.prayer(id) ?? BookPrayer.bundled(id, origin: nil, note: nil)
        }
        let others = ChantCatalog.otherSettings(of: chant)

        if !prayers.isEmpty || !others.isEmpty {
            VStack(alignment: .leading, spacing: 22) {
                if !prayers.isEmpty {
                    section("The prayer in words") {
                        ForEach(prayers, id: \.id) { prayer in
                            LedgerDoorRow(title: prayer.title, note: prayer.latinTitle, icon: "ch-praying-hands") {
                                router.push(.devotionPrayer(id: prayer.id))
                            }
                        }
                    }
                }

                if !others.isEmpty {
                    section("Also sung") {
                        ForEach(others) { other in
                            LedgerDoorRow(
                                title: other.fullTitle,
                                note: other.detail,
                                icon: "ph-music-note"
                            ) {
                                router.push(.chant(id: other.id))
                            }
                        }
                    }
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(title.uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                Rectangle()
                    .fill(AppColors.gold.opacity(0.18))
                    .frame(height: AppLine.hairline)
            }
            VStack(spacing: 0) {
                content()
            }
        }
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

/// "Your turn": the line the cantor sang is the reader's to sing back,
/// for as long as the cantor took over it
struct ChantYourTurn: View {
    let turn: ChantTurn
    var subtitle = "The cantor sang the line. Now sing it back."

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

/// The page's transport: the scrubber and the time, the five controls,
/// and the practice row. A view of its own so that the recording's
/// progress, read twice a second, redraws the transport alone — read in
/// the page's body, it redrew the title, the doors and the score with it.
private struct NowPlayingTransport: View {
    let chant: Chant
    let showWords: () -> Void
    let showSleep: () -> Void

    private var player = ChantPlayer.shared

    init(chant: Chant, showWords: @escaping () -> Void, showSleep: @escaping () -> Void) {
        self.chant = chant
        self.showWords = showWords
        self.showSleep = showSleep
    }

    var body: some View {
        let holds = player.holds(chant)
        let progress = holds ? player.progress : 0
        let elapsed = holds ? player.currentTime : 0
        let total = holds ? player.duration : chant.duration
        let lines = chant.hasLines

        return VStack(spacing: 18) {
            VStack(spacing: 4) {
                ChantScrubber(progress: progress, duration: total, isEnabled: holds) { fraction in
                    player.seek(toFraction: fraction)
                }
                HStack {
                    Text(ChantPlayer.clock(elapsed))
                        .contentTransition(.numericText())
                    Spacer()
                    if lines {
                        Text("Line \((holds ? player.lineIndex ?? 0 : 0) + 1) of \(chant.lines.count)")
                            .font(AppFonts.readingItalicFont(13))
                            .contentTransition(.numericText())
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

            HStack(spacing: 0) {
                repeatButton(lines: lines, holds: holds)
                Spacer(minLength: 0)
                stepButton(back: true, lines: lines, holds: holds)
                Spacer(minLength: 0)
                // The reader's turn is the chant going on: drawn as pause,
                // and a tap holds it
                ChantGoldPlayButton(
                    isPlaying: player.holds(chant) && player.chantGoesOn,
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 68,
                    label: chant.latinTitle
                ) {
                    player.toggle(chant)
                }
                Spacer(minLength: 0)
                stepButton(back: false, lines: lines, holds: holds)
                Spacer(minLength: 0)
                speedButton
            }

            if let error = player.current.id == chant.id ? player.errorMessage : nil {
                Text(error)
                    .font(AppFonts.italicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
            }

            HStack(spacing: 2) {
                if lines {
                    pill("Take turns", icon: "ph-arrows-left-right", isOn: holds && player.lineEnd == .takeTurns) {
                        if !holds { player.play(chant) }
                        player.setLineEnd(player.lineEnd == .takeTurns ? .goOn : .takeTurns)
                    }
                    .accessibilityHint("The cantor sings a line, then waits while you sing it back")
                }
                pill("Words", icon: "ph-text-align-left", isOn: false, action: showWords)
                pill("Sleep timer", icon: "ph-moon-stars", isOn: player.hasSleepTimer, action: showSleep)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Controls

    private func repeatButton(lines: Bool, holds: Bool) -> some View {
        let isOn = lines ? (holds && player.lineEnd == .again) : player.repeats
        return Button {
            if lines {
                if !holds { player.play(chant) }
                player.setLineEnd(player.lineEnd == .again ? .goOn : .again)
            } else {
                player.repeats.toggle()
            }
        } label: {
            ZStack(alignment: .bottom) {
                AppIcon(lines ? "ph-repeat-once" : "ph-repeat", size: 20)
                    .foregroundColor(isOn ? AppColors.goldLight : AppColors.gold.opacity(0.75))
                    .frame(width: 44, height: 44)
                Circle()
                    .fill(AppColors.goldLight)
                    .frame(width: 4, height: 4)
                    .opacity(isOn ? 1 : 0)
                    .offset(y: -3)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel(lines ? "Repeat this line" : "Repeat the chant")
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
        .sensoryFeedback(.selection, trigger: isOn)
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
            : (back ? "Back ten seconds" : "On ten seconds"))
    }

    private var speedButton: some View {
        // The speed sounding, which the Lock Screen may have changed
        let speed = player.speed
        let slow = speed < 1
        return Button {
            player.setRate(slow ? 1.0 : 0.75)
        } label: {
            Text(ChantPlayer.speedLabel(speed))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .font(AppFonts.readingFont(16))
                .foregroundColor(slow ? AppColors.goldLight : AppColors.gold)
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(AppColors.gold.opacity(slow ? 0.5 : 0), lineWidth: AppLine.hairline).padding(4))
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel(slow ? "Speed, slower" : speed > 1 ? "Speed, faster" : "Speed, normal")
        .accessibilityHint(slow ? "Plays at the normal speed" : "Plays at three-quarters speed, for learning")
    }

    private func pill(_ title: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                AppIcon(icon, size: 15)
                    .foregroundColor(isOn ? AppColors.goldLight : AppColors.gold)
                Text(title)
                    .font(AppFonts.readingFont(14.5))
                    .foregroundColor(isOn ? AppColors.goldLight : AppColors.cream.opacity(0.82))
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(Capsule().fill(isOn ? AppColors.gold.opacity(0.14) : Color.clear))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChantView(chantID: "salve_regina_simple")
            .environment(AppRouter())
    }
}
