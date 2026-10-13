//
//  PrayAlongView.swift
//  Lumen Viae
//
//  Prayers said one after another on a screen of their own — an order
//  of prayer (Morning Prayers, Before Confession) or a single prayer.
//
//  The order's painting hangs behind the words, veiled, as the Prayers
//  page hangs it on the order's card; the page is the prayer, a quiet
//  head (×, the order, its beads, ALOUD or SILENT) and one way on at the
//  foot: NEXT with the next prayer's name, or AMEN on the last.
//
//  Aloud, the voice reads each prayer (the server's ElevenLabs
//  recordings, in the chosen narration voice) and the verse being said
//  is lit and followed down the page; when a prayer ends, the next turns
//  in by itself after a breath, and a pause disc stands beside NEXT. In
//  silence the page is the reader's, and NEXT turns it. The beads take
//  a tap to any prayer, and a swipe left or right turns the page. The
//  last prayer closes on Amen, and an order prayed to its Amen is
//  offered for the day — which the rule of prayer and the Chapel read.
//
//  The Angelus rings the church bell as it begins and as it ends — when
//  it is prayed aloud. In silence the book makes no sound at all, and
//  until the reader has once said which it is to be, it asks before it
//  makes any (`PrayAloudChoiceSheet`).
//

import SwiftUI

struct PrayAlongView: View {

    let launch: PrayAlongLaunch

    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let store: PrayerBookStore
    private let prayers: [BookPrayer]

    @State private var voice = PrayAlongVoice()
    @State private var index: Int
    @State private var litStanza: Int?
    @State private var finished = false
    @State private var bellRings = 0
    @State private var advanceTask: Task<Void, Never>?
    @State private var asksHowToPray = false

    /// Whether the page is on screen. Recordings still being fetched when
    /// it closes, or a prayer still turning in, must not go on to speak
    /// from a page nobody can see: the first fetch can take a while, and
    /// a voice begun after × would pray the whole order on from nowhere
    @State private var isShowing = false

    /// This screen, as the book counts the pray-alongs open
    @State private var screenID = UUID()

    /// The page fades out, the next prayer is put in its place and the
    /// scroll set back to the head unseen, and it fades in — the old
    /// title never flashes over the new prayer
    @State private var pageOpacity: Double = 1

    /// `store` is the book's own except in a test, which brings one of
    /// its own so nothing the simulator has prayed shows through
    init(launch: PrayAlongLaunch, store: PrayerBookStore = .shared) {
        self.launch = launch
        self.store = store
        let resolved = launch.prayerIDs.compactMap { PrayerBook.prayer($0) }
        prayers = resolved
        _index = State(initialValue: min(max(launch.startIndex, 0), max(resolved.count - 1, 0)))
    }

    private var prayer: BookPrayer? {
        prayers.indices.contains(index) ? prayers[index] : nil
    }

    private var isLast: Bool { index >= prayers.count - 1 }

    /// Silent until the reader has said the book may speak
    private var aloud: Bool { store.hasChosenAloud && store.praysAloud }

    /// The head always names what was opened: an order by its name
    /// (the Angelus too, though its one prayer bears the same name), and
    /// a prayer opened alone by the book it is from. The Angelus's head
    /// once said when it is prayed, so one head in three named a time.
    private var kicker: String {
        launch.orderID == nil ? "Prayers" : launch.title
    }

    private var isAngelus: Bool {
        launch.orderID == PrayerBook.angelusOrderID
            || (prayers.count == 1 && ["angelus", "regina_caeli"].contains(prayers.first?.id))
    }

    /// The painting the Prayers page hangs over this order, or over this
    /// prayer: the same one the reader tapped to come here
    private var painting: PrayerBookPainting {
        if let id = launch.orderID, let order = PrayerBook.order(id) {
            return PrayerBookPainting.order(order)
        }
        if isAngelus, let order = PrayerBook.order(PrayerBook.angelusOrderID) {
            return PrayerBookPainting.hour(order)
        }
        return PrayerBookPainting.prayer(prayers.first?.id ?? "")
    }

    /// The words on the page. Aloud, the voice speaks English, so a
    /// reader who prays in Latin alone sees the English beneath it
    private var displayLanguage: PrayerLanguage {
        if aloud, settings.prayerLanguage == .latin { return .both }
        return settings.prayerLanguage
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if let prayer {
                // Fixed behind the scroll, so a long prayer runs over it
                // and never carries it away
                PrayAlongGround(painting: painting)

                // Under the Amen's veil the page is still drawn, but
                // VoiceOver should find only the Amen
                VStack(spacing: 0) {
                    header
                    pageScroll(prayer)
                }
                // Gone from beneath the Amen rather than dimmed: under the
                // cover alone the prayer's words showed through it
                .opacity(finished ? 0 : 1)
                .accessibilityHidden(finished)

                VStack {
                    Spacer()
                    foot
                }
                .ignoresSafeArea(edges: .bottom)
                .opacity(finished ? 0 : 1)
                .accessibilityHidden(finished)
            } else {
                missing
            }

            if finished {
                closing
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .animation(Motion.crossfade, value: finished)
        // Asked once, before the book's first sound; undismissable, since
        // answering is the only way through, and ALOUD or SILENT at the
        // head of the page owns the choice afterward
        .sheet(isPresented: $asksHowToPray, onDismiss: startSounding) {
            PrayAloudChoiceSheet(painting: painting) { chosen in
                store.chooseAloud(chosen)
                asksHowToPray = false
            }
            .presentationBackground(AppColors.background)
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            .interactiveDismissDisabled()
        }
        .onAppear(perform: begin)
        .onDisappear(perform: end)
        .onChange(of: voice.progress) { _, progress in
            follow(progress)
        }
    }

    // MARK: - Header

    /// ×, the order's name, ALOUD or SILENT; and beneath, the beads
    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(kicker.uppercased())
                    .font(AppFonts.labelFont(10.5))
                    .tracking(2.5)
                    .foregroundColor(AppColors.goldLight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 96)
                    .accessibilityAddTraits(.isHeader)

                HStack {
                    Button {
                        router.pop()
                    } label: {
                        AppIcon("ph-x", size: 18)
                            .foregroundColor(AppColors.cream)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Close")

                    Spacer(minLength: 0)

                    voiceSwitch
                }
            }

            if prayers.count > 1 {
                beads
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 2)
    }

    /// The way of praying, said in a word: a tap switches it. A speaker
    /// glyph read as a volume control and said nothing of silence.
    private var voiceSwitch: some View {
        Button {
            toggleAloud()
        } label: {
            HStack(spacing: 7) {
                if aloud {
                    Circle()
                        .fill(AppColors.gold)
                        .frame(width: 6, height: 6)
                        .shadow(color: AppColors.gold.opacity(0.8), radius: 3)
                }
                Text(aloud ? "ALOUD" : "SILENT")
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2)
                    .foregroundColor(aloud ? AppColors.goldLight : AppColors.cream.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .overlay(
                Capsule()
                    .strokeBorder(AppColors.gold.opacity(aloud ? 0.55 : 0.3), lineWidth: AppLine.hairline)
            )
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .animation(Motion.crossfade, value: aloud)
        .accessibilityLabel(aloud ? "Praying aloud" : "Praying in silence")
        .accessibilityHint(aloud ? "Double-tap to pray in silence" : "Double-tap to have the prayers read aloud")
    }

    /// One bead for each prayer of the order: those prayed filled, the
    /// one under the hand lit, those to come hollow. Each a door, 44
    /// points wide where the width allows it.
    private var beads: some View {
        HStack(spacing: 0) {
            ForEach(prayers.indices, id: \.self) { i in
                Button { goTo(i) } label: {
                    ZStack {
                        // The thread runs from bead to bead, broken
                        // around each, so it never shows through a
                        // hollow one
                        HStack(spacing: 0) {
                            threadSegment.opacity(i > 0 ? 1 : 0)
                            Color.clear.frame(width: 17, height: 1)
                            threadSegment.opacity(i < prayers.count - 1 ? 1 : 0)
                        }
                        bead(i)
                    }
                    .frame(maxWidth: 44)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(i + 1) of \(prayers.count), \(prayers[i].title)")
                .accessibilityAddTraits(i == index ? .isSelected : [])
            }
        }
        .animation(Motion.settle, value: index)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
    }

    private var threadSegment: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.25))
            .frame(height: AppLine.hairline)
    }

    private func bead(_ i: Int) -> some View {
        let now = i == index
        return ZStack {
            Circle()
                .fill(now ? AppColors.gold : i < index ? AppColors.gold.opacity(0.85) : Color.clear)
            if i > index {
                Circle()
                    .strokeBorder(AppColors.gold.opacity(0.55), lineWidth: AppLine.hairline * 1.5)
            }
        }
        .frame(width: now ? 11 : 7, height: now ? 11 : 7)
        .shadow(color: AppColors.gold.opacity(now ? 0.7 : 0), radius: 5)
    }

    // MARK: - The Page

    private func pageScroll(_ prayer: BookPrayer) -> some View {
        let stanzas = Self.stanzas(prayer.content(for: displayLanguage))
        let following = aloud && voice.isPlaying

        return ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: 0).id("top")

                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 10) {
                            if isAngelus {
                                // Hangs upright, and swings only while it
                                // rings: it once rested at one end of its
                                // swing, so in silence it hung askew
                                AppIcon("lv-bell", size: 26)
                                    .foregroundColor(AppColors.gold)
                                    .keyframeAnimator(initialValue: 0.0, trigger: bellRings) { bell, angle in
                                        bell.rotationEffect(.degrees(angle), anchor: .top)
                                    } keyframes: { _ in
                                        KeyframeTrack {
                                            CubicKeyframe(14, duration: 0.3)
                                            CubicKeyframe(-14, duration: 0.55)
                                            CubicKeyframe(14, duration: 0.55)
                                            CubicKeyframe(-12, duration: 0.55)
                                            CubicKeyframe(8, duration: 0.5)
                                            CubicKeyframe(-4, duration: 0.45)
                                            CubicKeyframe(0, duration: 0.4)
                                        }
                                    }
                                    .padding(.bottom, 4)
                                    .accessibilityHidden(true)
                            }

                            if let latin = prayer.secondTitle {
                                Text(latin.uppercased())
                                    .font(AppFonts.labelFont(9))
                                    .tracking(2.5)
                                    .foregroundColor(AppColors.gold.opacity(0.8))
                            }

                            Text(prayer.title)
                                .font(AppFonts.titleFont(27))
                                .foregroundColor(AppColors.cream)
                                .minimumScaleFactor(0.7)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 22)

                        VStack(alignment: .leading, spacing: ReadingTypography.stanzaSpacing(for: textSize)) {
                            ForEach(Array(stanzas.enumerated()), id: \.offset) { i, stanza in
                                PrayAlongStanza(
                                    content: stanza,
                                    size: textSize,
                                    showsDropCap: i == 0,
                                    opacity: stanzaOpacity(i, following: following)
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .animation(Motion.crossfade, value: litStanza)
                                .id(i)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                    // The veil goes with the words, so the painting reads
                    // clear in the room a short prayer leaves beneath it
                    .background(WordsVeil())

                    // Clear of the foot, so the last line can be read
                    // above NEXT
                    Color.clear.frame(height: 220)
                }
                .opacity(pageOpacity)
            }
            .scrollBounceBehavior(.basedOnSize)
            // The words dissolve as they pass under the head and the
            // beads rather than being cut through mid-line at the scroll's
            // edge. No inset: the title already stands 22pt down, clear
            // of the band at rest.
            .topChromeFade(height: 22, inset: 0)
            // A swipe across turns the page, as a book's does; the scroll
            // keeps the vertical drag
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        let dx = value.translation.width
                        guard abs(dx) > 70, abs(dx) > abs(value.translation.height) * 1.6 else { return }
                        if dx < 0, !isLast {
                            goTo(index + 1)
                        } else if dx > 0, index > 0 {
                            goTo(index - 1)
                        }
                    }
            )
            .onChange(of: litStanza) { _, lit in
                guard let lit, aloud else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.7)) {
                    proxy.scrollTo(lit, anchor: UnitPoint(x: 0.5, y: 0.3))
                }
            }
            .onChange(of: index) { _, _ in
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }

    /// A point under the reading size, as the prayer's own page sets it,
    /// so more of each line of a prayer fits the measure
    private var textSize: CGFloat {
        max(17, settings.meditationFontSize - 1)
    }

    /// The verse under the voice full, what has been said dimmed, what is
    /// to come a little brighter — only while the voice is reading. Over
    /// the painting the dimmed verses stay readable.
    private func stanzaOpacity(_ i: Int, following: Bool) -> Double {
        guard following, let lit = litStanza else { return 1 }
        if i == lit { return 1 }
        return i < lit ? 0.5 : 0.7
    }

    // MARK: - Foot

    /// One way on, the same aloud and in silence: NEXT with the next
    /// prayer's name, or AMEN on the last. Aloud, the pause disc stands
    /// beside it, and a note above it while the recordings are fetched
    /// or when a prayer has none.
    private var foot: some View {
        VStack(spacing: 12) {
            if aloud {
                aloudNote
            }

            HStack(spacing: 12) {
                if showsPlayDisc {
                    playDisc
                        .transition(.opacity)
                }

                if isLast {
                    GoldCTAButton(title: "Amen", trailingIcon: "ph-check", fullWidth: true) {
                        finish()
                    }
                } else if let next = prayers[safe: index + 1] {
                    nextButton(next)
                }
            }
            .animation(Motion.crossfade, value: showsPlayDisc)
        }
        .padding(.horizontal, 22)
        .padding(.top, 64)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0), location: 0),
                    .init(color: AppColors.background.opacity(0.92), location: 0.4),
                    .init(color: AppColors.background, location: 0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // A view set as a background stops at the safe area; the words
            // must not show beneath the act, under the home indicator
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        )
    }

    /// The voice can pause this prayer: the recordings are in, and this
    /// one has its own
    private var showsPlayDisc: Bool {
        guard aloud, case .ready = voice.state, let prayer else { return false }
        return voice.hasRecording(prayer.id)
    }

    @ViewBuilder
    private var aloudNote: some View {
        switch voice.state {
        case .idle, .preparing:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(AppColors.gold)
                footNote(preparingLine)
            }
        case .unavailable(let message):
            footNote(message)
        case .ready:
            if !showsPlayDisc {
                footNote("This prayer has no recording yet. Pray it in silence, then go on.")
            }
        }
    }

    private func footNote(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.readingItalicFont(13.5))
            .foregroundColor(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var preparingLine: String {
        if case .preparing(let done, let total) = voice.state, total > 0 {
            return "Fetching the recordings · \(done) of \(total)"
        }
        return "Fetching the recordings"
    }

    private var playDisc: some View {
        Button {
            playPause()
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.background.opacity(0.4))
                Circle()
                    .strokeBorder(AppColors.gold.opacity(0.75), lineWidth: 1.2)
                AppIcon(voice.isPlaying ? "ph-pause-fill" : "ph-play-fill", size: 20)
                    .foregroundColor(AppColors.goldLight)
                    .offset(x: voice.isPlaying ? 0 : 2)
            }
            .frame(width: 58, height: 58)
            .shadow(color: AppColors.gold.opacity(0.25), radius: 10)
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel(voice.isPlaying ? "Pause" : "Play")
    }

    /// The next prayer named and a tap away: an outlined pill, since the
    /// page's one gold act is the Amen
    private func nextButton(_ next: BookPrayer) -> some View {
        Button { goTo(index + 1) } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.8))
                    Text(next.title)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .contentTransition(.opacity)
                }
                Spacer(minLength: 8)
                AppIcon("ph-caret-right", size: 14)
                    .foregroundColor(AppColors.gold)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Capsule().fill(AppColors.background.opacity(0.35)))
            .overlay(
                Capsule()
                    .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(SacredCardButtonStyle())
        .animation(Motion.crossfade, value: index)
        .accessibilityLabel("Next prayer, \(next.title)")
    }

    // MARK: - Closing

    /// The order's painting comes forward in full over the Amen, where a
    /// seal once stood
    private var closing: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                AppColors.background

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: proxy.size.height * 0.68 + proxy.safeAreaInsets.top)
                        .overlay {
                            CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                        }
                        .clipped()
                        .overlay(
                            // The status bar stays legible over a bright sky
                            LinearGradient(
                                colors: [AppColors.background.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: 0.25)
                            )
                        )
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .black, location: 0.5),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Spacer(minLength: 0)
                }
                .accessibilityHidden(true)

                VStack(spacing: 10) {
                    // The day's three orders close on a line of their own;
                    // any other's closing line already names it, prayed
                    if closingNamesNoOrder {
                        Text("\(launch.title.uppercased()) · PRAYED")
                            .font(AppFonts.labelFont(10))
                            .tracking(2.5)
                            .foregroundColor(AppColors.goldLight)
                            .multilineTextAlignment(.center)
                    }

                    Text("Amen.")
                        .font(AppFonts.titleFont(40))
                        .foregroundColor(AppColors.cream)
                        .accessibilityAddTraits(.isHeader)

                    Text(closingLine)
                        .font(AppFonts.readingItalicFont(17))
                        .foregroundColor(AppColors.cream.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 290)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 4) {
                        GoldCTAButton(title: "Done", fullWidth: false) {
                            router.pop()
                        }
                        .padding(.top, 14)

                        if launch.orderID == nil, let only = prayers.first, !store.isKept(only.id) {
                            QuietGoldButton(title: "Save this prayer", leadingIcon: "ph-push-pin") {
                                store.toggleRibbon(only.id)
                            }
                        }

                        QuietGoldButton(title: "Pray again", leadingIcon: "ph-arrow-counter-clockwise") {
                            finished = false
                            goTo(0)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 16) + 8)
            }
            .ignoresSafeArea()
        }
        .sensoryFeedback(.success, trigger: finished)
    }

    private var closingNamesNoOrder: Bool {
        [PrayerBook.morningOrderID, PrayerBook.nightOrderID, PrayerBook.angelusOrderID]
            .contains(launch.orderID ?? "")
    }

    private var closingLine: String {
        guard let orderID = launch.orderID else { return "\(launch.title), prayed." }
        switch orderID {
        case PrayerBook.morningOrderID: return "The day is offered before it is begun."
        case PrayerBook.nightOrderID: return "The day is given back. Rest in His peace."
        case PrayerBook.angelusOrderID: return "The Word was made flesh, and dwelt among us."
        default: return "\(launch.title), prayed today."
        }
    }

    private var missing: some View {
        VStack(spacing: 16) {
            Text("These prayers could not be found.")
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.textSecondary)
            QuietGoldButton(title: "Close", leadingIcon: "ph-x") { router.pop() }
        }
    }

    // MARK: - Moving

    private func begin() {
        isShowing = true
        store.prayAlongOpened(screenID)
        UIApplication.shared.isIdleTimerDisabled = true
        voice.onFinish = { scheduleAdvance() }
        voice.onNext = { if !isLast { goTo(index + 1) } }
        voice.onPrevious = { if index > 0 { goTo(index - 1) } }

        if store.hasChosenAloud {
            startSounding()
        } else {
            asksHowToPray = true
        }
    }

    /// The page's first sound, once the reader has said the book may
    /// make one: the Angelus's bell, then the voice. In silence, nothing.
    private func startSounding() {
        guard isShowing, aloud, !finished else { return }
        if isAngelus { ringBell() }
        startVoice()
    }

    private func end() {
        isShowing = false
        store.prayAlongClosed(screenID)
        advanceTask?.cancel()
        voice.stop()
        AngelusBellSound.shared.silence()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func startVoice() {
        Task { @MainActor in
            if case .ready = voice.state {} else {
                await voice.prepare(prayers)
            }
            guard isShowing, aloud, !finished else { return }
            await playCurrent()
        }
    }

    private func playCurrent() async {
        guard let prayer else { return }
        litStanza = 0
        await voice.play(prayer, in: launch.title, index: index, of: prayers.count)
    }

    private func toggleAloud() {
        store.chooseAloud(!aloud)
        advanceTask?.cancel()
        if aloud {
            startVoice()
        } else {
            voice.stop()
            litStanza = nil
        }
    }

    private func playPause() {
        if voice.isPlaying {
            voice.pause()
        } else if voice.ownsPlayer, voice.currentPrayerID == prayer?.id {
            voice.resume()
        } else {
            Task { await playCurrent() }
        }
    }

    /// A breath after a prayer ends, then the next — or Amen
    private func scheduleAdvance() {
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1100))
            guard !Task.isCancelled, aloud else { return }
            if isLast { finish() } else { goTo(index + 1) }
        }
    }

    private func goTo(_ target: Int) {
        guard prayers.indices.contains(target) else { return }
        advanceTask?.cancel()
        litStanza = nil
        if aloud { voice.pause() }
        withAnimation(.easeIn(duration: 0.14)) { pageOpacity = 0 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            index = target
            withAnimation(.easeOut(duration: 0.26)) { pageOpacity = 1 }
            if isShowing, aloud, case .ready = voice.state {
                await playCurrent()
            }
        }
    }

    private func finish() {
        advanceTask?.cancel()
        voice.stop()
        if let orderID = launch.orderID {
            store.markOffered(orderID)
        }
        if isAngelus, aloud { ringBell() }
        finished = true
    }

    private func ringBell() {
        AngelusBellSound.shared.ring()
        if !reduceMotion { bellRings += 1 }
    }

    // MARK: - Following the voice

    /// Lights the stanza the voice has reached, by how far through the
    /// recording it is against how much each stanza has to say — the
    /// recordings carry no timings, so the measure is proportional, as
    /// the book readers' is
    private func follow(_ progress: Double) {
        guard aloud, let prayer, voice.currentPrayerID == prayer.id else { return }
        let weights = Self.spokenWeights(prayer.english)
        let total = weights.reduce(0, +)
        guard total > 0 else { return }
        var running = 0
        let reached = progress * Double(total)
        var lit = weights.count - 1
        for (i, weight) in weights.enumerated() {
            running += weight
            if Double(running) > reached { lit = i; break }
        }
        let displayed = Self.stanzas(prayer.content(for: displayLanguage)).count
        lit = min(lit, max(displayed - 1, 0))
        if lit != litStanza { litStanza = lit }
    }

    // MARK: - Reading the text

    /// A prayer's text cut at its blank lines, each stanza kept whole
    static func stanzas(_ text: String) -> [String] {
        var result: [String] = []
        var current: [String] = []
        for line in text.components(separatedBy: "\n") {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if !current.isEmpty { result.append(current.joined(separator: "\n")) }
                current = []
            } else {
                current.append(line)
            }
        }
        if !current.isEmpty { result.append(current.joined(separator: "\n")) }
        return result
    }

    /// How much the voice says in each stanza of the English: every
    /// letter, a rubric's words included (the narrator reads "Let us
    /// pray"), and a litany's response once for every invocation, since
    /// the recording says it after each one
    static func spokenWeights(_ english: String) -> [Int] {
        stanzas(english).map { stanza in
            var response: String?
            var count = 0
            for line in stanza.components(separatedBy: "\n") {
                let text = line.trimmingCharacters(in: .whitespaces)
                if PrayerMarkup.isLitany(text) {
                    let parts = PrayerMarkup.litanyParts(text)
                    response = parts.response
                    count += parts.invocation.count + parts.response.count
                } else if let response, !text.hasPrefix("℣"), !text.hasPrefix("℟"), !PrayerMarkup.isRubric(text) {
                    count += text.count + response.count
                } else {
                    count += text.count
                }
            }
            return max(count, 1)
        }
    }
}

// MARK: - The ground

/// The page's ground: the order's painting veiled, as Chant practice sets
/// its chant's, and a scrim of the theme's own ground, light at the head
/// where the painting shows and even below it. The words carry a veil of
/// their own (`WordsVeil`), so they read over the brightest sky while the
/// room a short prayer leaves beneath it shows the painting rather than a
/// flat dark field. Hidden from VoiceOver, which reads the words.
private struct PrayAlongGround: View {
    let painting: PrayerBookPainting

    var body: some View {
        ZStack {
            // The painting hangs off a clear view, so its fill never
            // widens the page it stands behind
            Color.clear
                .overlay {
                    CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                }
                .clipped()
                .opacity(0.55)

            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0.4), location: 0),
                    .init(color: AppColors.background.opacity(0.1), location: 0.1),
                    .init(color: AppColors.background.opacity(0.45), location: 0.22),
                    .init(color: AppColors.background.opacity(0.55), location: 0.4),
                    .init(color: AppColors.background.opacity(0.55), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The veil behind the title and the prayer, scrolling with them: the
/// theme's ground, feathered above and below so it has no edge
private struct WordsVeil: View {
    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, AppColors.background.opacity(0.62)], startPoint: .top, endPoint: .bottom)
                .frame(height: 44)
            AppColors.background.opacity(0.62)
            LinearGradient(colors: [AppColors.background.opacity(0.62), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 72)
        }
        .padding(.top, -44)
        .padding(.bottom, -72)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - A stanza on the page

/// One stanza of the prayer. A stanza of plain verse — lines and rubrics,
/// no litany, canticle or translation — is set here a line at a time, so
/// a line too long for the measure hangs its overflow in, as a prayer book
/// sets it, rather than wrapping to look like a line of its own; and its
/// rubrics stand apart from the verse, at full strength while the verse
/// beside them is dimmed under the voice. Every other stanza is
/// `PrayerText`'s, dimmed whole.
private struct PrayAlongStanza: View {
    let content: String
    let size: CGFloat
    let showsDropCap: Bool
    let opacity: Double

    private var lines: [String] {
        content.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var isPlainVerse: Bool {
        let lines = self.lines
        guard !lines.isEmpty else { return false }
        if lines.allSatisfy(PrayerMarkup.isRubric) { return true }
        guard lines.count > 1 else { return false }
        return !lines.contains {
            $0.contains("|||") || PrayerMarkup.isLitany($0) || PrayerMarkup.isPointed($0) || PrayerMarkup.isRule($0)
        }
    }

    var body: some View {
        if isPlainVerse {
            let lines = self.lines
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                    let rubric = PrayerMarkup.isRubric(line)
                    let afterRubric = i > 0 && PrayerMarkup.isRubric(lines[i - 1])
                    Group {
                        if rubric {
                            Text(PrayerMarkup.rubric(line))
                                .font(AppFonts.readingItalicFont(max(12, size - 2)))
                                .foregroundColor(Rubric.red)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(max(opacity, 0.85))
                        } else {
                            PrayAlongVerseLine(text: line, size: size)
                                .opacity(opacity)
                        }
                    }
                    .padding(.top, i == 0 ? 0 : (rubric || afterRubric)
                        ? ReadingTypography.verseSpacing(for: size)
                        : ReadingTypography.quoteLineSpacing(for: size))
                }
            }
        } else {
            PrayerText(content: content, size: size, alignment: .leading, showsDropCap: showsDropCap)
                .opacity(opacity)
        }
    }
}

/// A line of verse in `PrayerText`'s face, its ℣ ℟ ✠ in red, whose
/// overflow hangs in by about an em
private struct PrayAlongVerseLine: View {
    let text: String
    let size: CGFloat

    private var indent: CGFloat { (size * 1.1).rounded() }

    var body: some View {
        let line = Text(Rubric.rubricated(text))
            .font(AppFonts.bodyFont(size))
            .foregroundColor(AppColors.cream.opacity(0.92))
            .lineSpacing(ReadingTypography.quoteLineSpacing(for: size))
        if #available(iOS 18.0, *) {
            // Measured an indent short, then every line after the first
            // drawn an indent in, so the overflow still fits the measure
            line
                .textRenderer(HangingIndentRenderer(indent: indent))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, indent)
        } else {
            line
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@available(iOS 18.0, *)
private struct HangingIndentRenderer: TextRenderer {
    let indent: CGFloat

    var displayPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: indent)
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for (i, line) in layout.enumerated() {
            var lineContext = context
            if i > 0 { lineContext.translateBy(x: indent, y: 0) }
            lineContext.draw(line)
        }
    }
}

// MARK: - Aloud, or in silence

/// The book's one question, asked the first time it would speak: read
/// aloud, or kept to the page. The order's painting at its head, then two
/// rows and nothing to confirm — the row is the answer. It cannot be
/// dragged away, so it shows no grabber.
///
/// Answering is the only way out, so both answers must always be in
/// reach: at the accessibility text sizes the sheet stands full height,
/// and it scrolls. Held to 340 points there, its header was cut off and
/// the two rows were drawn over each other.
struct PrayAloudChoiceSheet: View {
    let painting: PrayerBookPainting?
    let onChoose: (Bool) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private var voices = NarrationVoiceCatalog.shared

    init(painting: PrayerBookPainting? = nil, onChoose: @escaping (Bool) -> Void) {
        self.painting = painting
        self.onChoose = onChoose
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if let painting {
                    Color.clear
                        .frame(height: 112)
                        .overlay {
                            CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                        }
                        .clipped()
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .black, location: 0.25),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.bottom, -18)
                        .accessibilityHidden(true)
                }

                SheetHeader(
                    kicker: "Prayers",
                    title: "Aloud, or in silence?",
                    lead: "The app can read each prayer aloud to you, or leave you to say the words yourself."
                )

                Button { onChoose(true) } label: {
                    SheetRow(
                        "Aloud",
                        detail: "Read to you in the \(voices.chosenVoice.name.lowercased()) voice",
                        icon: "ph-speaker-high",
                        detailLineLimit: nil
                    )
                }
                .buttonStyle(SacredCardButtonStyle())

                Button { onChoose(false) } label: {
                    SheetRow(
                        "In silence",
                        detail: "No sound. The words stay on screen for you to say.",
                        icon: "ph-book-open",
                        showsDivider: false,
                        detailLineLimit: nil
                    )
                }
                .buttonStyle(SacredCardButtonStyle())

                SheetNote("Change this any time with ALOUD or SILENT at the top of the page, or in Settings.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The sheets' ground without `sheetGround()`'s indicator, as the
        // missal's first question is set
        .background(AppColors.appGradient.ignoresSafeArea())
        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.height(painting == nil ? 340 : 436)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Safe index

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrayAlongView(launch: .order(PrayerBook.order("morning")!))
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
