//
//  PrayAlongView.swift
//  Lumen Viae
//
//  Prayers said one after another on a screen of their own — an order
//  of prayer (Morning Prayers, Before Confession) or a single prayer.
//
//  Aloud, the voice reads each prayer (the server's ElevenLabs
//  recordings, in the chosen narration voice) and the verse being said
//  is lit and followed down the page; when a prayer ends, the next turns
//  in by itself after a breath. In silence the page is the reader's, and
//  NEXT turns it. A row of beads at the head says where the order
//  stands and takes a tap to any prayer in it. The last prayer closes
//  on Amen, and an order prayed to its Amen is offered for the day —
//  which the rule of prayer and the Chapel read.
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

    private var store = PrayerBookStore.shared
    private let prayers: [BookPrayer]

    @State private var voice = PrayAlongVoice()
    @State private var index: Int
    @State private var litStanza: Int?
    @State private var finished = false
    @State private var bellRings = 0
    @State private var advanceTask: Task<Void, Never>?
    @State private var asksHowToPray = false

    /// The page fades out, the next prayer is put in its place and the
    /// scroll set back to the head unseen, and it fades in — the old
    /// title never flashes over the new prayer
    @State private var pageOpacity: Double = 1

    init(launch: PrayAlongLaunch) {
        self.launch = launch
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

    /// A single prayer is named once, by its own title on the page; the
    /// head says whose book it is instead of saying the title twice
    private var kicker: String {
        prayers.count > 1 ? launch.title : "The Prayer Book"
    }

    private var isAngelus: Bool {
        launch.orderID == PrayerBook.angelusOrderID
            || (prayers.count == 1 && ["angelus", "regina_caeli"].contains(prayers.first?.id))
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
            AppColors.appGradient.ignoresSafeArea()

            // A low glow at the head of the page, the light a prayer
            // book is read by
            RadialGradient(
                colors: [AppColors.gold.opacity(0.1), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 420
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            if let prayer {
                // Under the Amen's veil the page is still drawn, but
                // VoiceOver should find only the Amen
                VStack(spacing: 0) {
                    header
                    if prayers.count > 1 {
                        beads
                            .padding(.top, 6)
                    }
                    pageScroll(prayer)
                }
                .accessibilityHidden(finished)

                VStack {
                    Spacer()
                    foot
                }
                .ignoresSafeArea(edges: .bottom)
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
        // answering is the only way through, and the speaker at the head
        // of the page owns the choice afterward
        .sheet(isPresented: $asksHowToPray, onDismiss: startSounding) {
            PrayAloudChoiceSheet { chosen in
                store.chooseAloud(chosen)
                asksHowToPray = false
            }
            .presentationBackground(AppColors.background)
            .interactiveDismissDisabled()
        }
        .onAppear(perform: begin)
        .onDisappear(perform: end)
        .onChange(of: voice.progress) { _, progress in
            follow(progress)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            PrayerHeaderButton(icon: "ph-x", size: 16, label: "Close", tint: AppColors.cream) {
                router.pop()
            }

            Spacer(minLength: 8)

            VStack(spacing: 3) {
                Text(kicker.uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if prayers.count > 1 {
                    Text("\(index + 1) of \(prayers.count)")
                        .font(AppFonts.readingItalicFont(12.5))
                        .foregroundColor(AppColors.textSecondary)
                        .contentTransition(.numericText())
                        .animation(Motion.crossfade, value: index)
                }
            }

            Spacer(minLength: 8)

            PrayerHeaderButton(
                icon: aloud ? "ph-speaker-high-fill" : "ph-speaker-high",
                size: 16,
                label: aloud ? "Praying aloud. Tap to pray in silence" : "Pray aloud",
                tint: aloud ? AppColors.gold : AppColors.cream.opacity(0.7)
            ) {
                toggleAloud()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }

    /// One bead for each prayer of the order: those prayed filled, the
    /// one under the hand ringed, those to come hollow. Each a door.
    private var beads: some View {
        HStack(spacing: 0) {
            ForEach(prayers.indices, id: \.self) { i in
                if i > 0 {
                    // Links give way before beads do, so a long order
                    // still fits the width
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.25))
                        .frame(minWidth: 4, maxWidth: 18)
                        .frame(height: AppLine.hairline)
                }
                Button { goTo(i) } label: {
                    ZStack {
                        Circle()
                            .fill(i < index ? AppColors.gold.opacity(0.85) : Color.clear)
                        Circle()
                            .strokeBorder(AppColors.gold.opacity(i == index ? 1 : 0.45),
                                          lineWidth: i == index ? 1.4 : AppLine.hairline * 1.5)
                        if i == index {
                            Circle()
                                .fill(AppColors.gold)
                                .padding(3)
                        }
                    }
                    .frame(width: i == index ? 13 : 9, height: i == index ? 13 : 9)
                    .shadow(color: AppColors.gold.opacity(i == index ? 0.6 : 0), radius: 5)
                    .frame(width: 22, height: 30)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(prayers[i].title)\(i == index ? ", now" : "")")
            }
        }
        .animation(Motion.settle, value: index)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - The Page

    private func pageScroll(_ prayer: BookPrayer) -> some View {
        let stanzas = Self.stanzas(prayer.content(for: displayLanguage))
        let following = aloud && voice.isPlaying

        return ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 0).id("top")

                    VStack(spacing: 12) {
                        if isAngelus {
                            // Hangs upright, and swings only while it
                            // rings: it once rested at one end of its
                            // swing, so in silence it hung askew
                            AppIcon("ph-bell", size: 26)
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
                                .padding(.bottom, 2)
                                .accessibilityHidden(true)
                        }

                        if let latin = prayer.latinTitle, latin != prayer.title {
                            Text(latin.uppercased())
                                .font(AppFonts.labelFont(9))
                                .tracking(2.5)
                                .foregroundColor(AppColors.gold.opacity(0.75))
                                .multilineTextAlignment(.center)
                        }

                        Text(prayer.title)
                            .font(AppFonts.titleFont(26))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)

                        OrnamentDivider()
                            .frame(width: 120)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 26)

                    VStack(alignment: .leading, spacing: ReadingTypography.stanzaSpacing(for: textSize)) {
                        ForEach(Array(stanzas.enumerated()), id: \.offset) { i, stanza in
                            PrayerText(
                                content: stanza,
                                size: textSize,
                                alignment: .leading,
                                showsDropCap: i == 0
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .opacity(stanzaOpacity(i, following: following))
                            .animation(Motion.crossfade, value: litStanza)
                            .id(i)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 28)

                    Color.clear.frame(height: 280)
                }
                .opacity(pageOpacity)
            }
            .scrollBounceBehavior(.basedOnSize)
            // The words dissolve as they pass under the head and the
            // beads rather than being cut through mid-line at the scroll's
            // edge. No inset: the title already stands 26pt down, clear
            // of the band at rest.
            .topChromeFade(height: 22, inset: 0)
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

    private var textSize: CGFloat {
        max(18, settings.meditationFontSize)
    }

    /// The verse under the voice full, what has been said dimmed, what is
    /// to come a little brighter — only while the voice is reading
    private func stanzaOpacity(_ i: Int, following: Bool) -> Double {
        guard following, let lit = litStanza else { return 1 }
        if i == lit { return 1 }
        return i < lit ? 0.4 : 0.62
    }

    // MARK: - Foot

    private var foot: some View {
        VStack(spacing: 10) {
            if aloud {
                aloudFoot
            } else {
                silentFoot
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 92)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity)
        .background(PrayFootGround())
    }

    @ViewBuilder
    private var aloudFoot: some View {
        switch voice.state {
        case .idle, .preparing:
            VStack(spacing: 8) {
                ProgressView()
                    .tint(AppColors.gold)
                Text(preparingLine)
                    .font(AppFonts.readingItalicFont(13))
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(minHeight: 88)

        case .unavailable(let message):
            VStack(spacing: 10) {
                Text(message)
                    .font(AppFonts.readingItalicFont(13.5))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                silentFoot
            }

        case .ready:
            VStack(spacing: 12) {
                progressLine
                transport
                if !(prayer.map { voice.hasRecording($0.id) } ?? false) {
                    Text("This prayer has no recording yet — pray it in silence, then go on.")
                        .font(AppFonts.readingItalicFont(12.5))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var preparingLine: String {
        if case .preparing(let done, let total) = voice.state, total > 0 {
            return "Fetching the recordings · \(done) of \(total)"
        }
        return "Fetching the recordings"
    }

    private var progressLine: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.gold.opacity(0.15))
                Capsule()
                    .fill(AppColors.gold.opacity(0.8))
                    .frame(width: geo.size.width * voice.progress)
            }
        }
        .frame(height: 2)
        .padding(.horizontal, 30)
        .accessibilityHidden(true)
    }

    private var transport: some View {
        HStack(spacing: 34) {
            if prayers.count > 1 {
                transportButton("ph-skip-forward-fill", flipped: true, label: "Previous prayer", enabled: index > 0) {
                    goTo(index - 1)
                }
            } else {
                // A single prayer has nowhere to go back to; the space
                // stays so the play disc keeps the middle
                Color.clear.frame(width: 48, height: 48)
                    .accessibilityHidden(true)
            }

            Button {
                playPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColors.gold.opacity(0.14))
                    Circle()
                        .strokeBorder(AppColors.gold.opacity(0.7), lineWidth: 1.2)
                    AppIcon(voice.isPlaying ? "ph-pause-fill" : "ph-play-fill", size: 22)
                        .foregroundColor(AppColors.goldLight)
                        .offset(x: voice.isPlaying ? 0 : 2)
                }
                .frame(width: 64, height: 64)
                .shadow(color: AppColors.gold.opacity(0.35), radius: 10)
            }
            .buttonStyle(GoldCTAButtonStyle())
            .accessibilityLabel(voice.isPlaying ? "Pause" : "Play")

            if isLast {
                transportButton("ph-check", flipped: false, label: "Amen", enabled: true) {
                    finish()
                }
            } else {
                transportButton("ph-skip-forward-fill", flipped: false, label: "Next prayer", enabled: true) {
                    goTo(index + 1)
                }
            }
        }
    }

    private func transportButton(
        _ icon: String,
        flipped: Bool,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            AppIcon(icon, size: 20)
                .foregroundColor(AppColors.gold.opacity(enabled ? 0.9 : 0.25))
                .scaleEffect(x: flipped ? -1 : 1)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    /// In silence: the next prayer named and a tap away, and Amen at the
    /// last — the one gold act of this screen
    @ViewBuilder
    private var silentFoot: some View {
        if isLast {
            // The way back stays beside Amen, as it stands beside NEXT
            HStack(spacing: 12) {
                if index > 0 {
                    transportButton("ph-caret-left", flipped: false, label: "Previous prayer", enabled: true) {
                        goTo(index - 1)
                    }
                }
                GoldCTAButton(title: "Amen", trailingIcon: "ph-check", fullWidth: true) {
                    finish()
                }
            }
        } else if let next = prayers[safe: index + 1] {
            HStack(spacing: 12) {
                if index > 0 {
                    transportButton("ph-caret-left", flipped: false, label: "Previous prayer", enabled: true) {
                        goTo(index - 1)
                    }
                }

                Button { goTo(index + 1) } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("NEXT")
                                .font(AppFonts.labelFont(8.5))
                                .tracking(2)
                                .foregroundColor(AppColors.gold.opacity(0.75))
                            Text(next.title)
                                .font(AppFonts.readingFont(17))
                                .foregroundColor(AppColors.cream)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: 8)
                        AppIcon("ph-caret-right", size: 14)
                            .foregroundColor(AppColors.gold)
                    }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel("Next prayer, \(next.title)")
            }
        }
    }

    // MARK: - Closing

    private var closing: some View {
        ZStack {
            AppColors.background.opacity(0.94).ignoresSafeArea()

            VStack(spacing: 18) {
                AppIcon("ph-seal-check-fill", size: 46)
                    .foregroundColor(AppColors.gold)
                    .shadow(color: AppColors.gold.opacity(0.5), radius: 14)

                Text("Amen.")
                    .font(AppFonts.titleFont(36))
                    .foregroundColor(AppColors.cream)

                Text(closingLine)
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)

                VStack(spacing: 4) {
                    GoldCTAButton(title: "Done", fullWidth: false) {
                        router.pop()
                    }
                    .padding(.top, 14)

                    if launch.orderID == nil, let only = prayers.first, !store.isKept(only.id) {
                        QuietGoldButton(title: "Keep it with a ribbon", leadingIcon: "ph-push-pin") {
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
        }
        .sensoryFeedback(.success, trigger: finished)
    }

    private var closingLine: String {
        guard let orderID = launch.orderID else { return "\(launch.title), prayed." }
        switch orderID {
        case PrayerBook.morningOrderID: return "The day is offered before it is begun."
        case PrayerBook.nightOrderID: return "The day is given back. Rest in His peace."
        case PrayerBook.angelusOrderID: return "The Word was made flesh, and dwelt among us."
        default: return "\(launch.title), offered for today."
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
        guard aloud, !finished else { return }
        if isAngelus { ringBell() }
        startVoice()
    }

    private func end() {
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
            guard aloud, !finished else { return }
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
            if aloud, case .ready = voice.state {
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

// MARK: - Aloud, or in silence

/// The book's one question, asked the first time it would speak: read
/// aloud, or kept to the page. Two rows and nothing to confirm — the
/// row is the answer. It cannot be dragged away, so it shows no grabber.
///
/// Answering is the only way out, so both answers must always be in
/// reach: at the accessibility text sizes the sheet stands full height,
/// and it scrolls. Held to 340 points there, its header was cut off and
/// the two rows were drawn over each other.
struct PrayAloudChoiceSheet: View {
    let onChoose: (Bool) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private var voices = NarrationVoiceCatalog.shared

    init(onChoose: @escaping (Bool) -> Void) {
        self.onChoose = onChoose
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    kicker: "The Prayer Book",
                    title: "Aloud, or in silence?",
                    lead: "The book can read each prayer to you, the page following the voice, or leave the words to you."
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
                        detail: "For the pew, or beside someone asleep",
                        icon: "ph-book-open",
                        showsDivider: false,
                        detailLineLimit: nil
                    )
                }
                .buttonStyle(SacredCardButtonStyle())

                SheetNote("The speaker at the top of the page changes this whenever you like.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The sheets' ground without `sheetGround()`'s indicator, as the
        // missal's first question is set
        .background(AppColors.appGradient.ignoresSafeArea())
        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.height(340)])
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
