//
//  BookPrayerView.swift
//  Lumen Viae
//
//  One prayer of the Prayer Book on a page of its own (the "single
//  prayer" design, option A, Oct 2026, the order page's twin): the
//  prayer's painting run up under the bar and dissolving into the page,
//  its topic, its name and its Latin in the dissolve, where it comes
//  from on one small line; then the prayer itself, when it is said in
//  one italic paragraph beneath it, learning it by heart and hearing it
//  sung as two quiet acts, the orders it is said in, and the steps along
//  its topic. At the foot, fixed as on the order page, PRAY beside the
//  round speaker that says how it will be prayed. The language is a
//  small button in the bar, the ribbon beside it.
//
//  The page once stood as type alone: a numeral and an ornament over the
//  name, a bar of three language chips above the prayer, a kicker over
//  its note and three acts of nearly one weight, eight layers before the
//  first word of the prayer.
//
//  Every door to a prayer in the app lands here (`AppRoute.devotionPrayer`).
//  The foot steps along the prayer's chapter in place, as the library's
//  readings step along their shelf.
//

import SwiftUI

struct BookPrayerView: View {

    let prayerID: String

    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var typeSize

    private let store: PrayerBookStore
    private var voices = NarrationVoiceCatalog.shared

    /// The prayer on the page, which the foot steps along its chapter
    @State private var currentID: String
    @State private var pageOpacity: Double = 1
    @State private var showsLearn = false
    @State private var keptNote: String?
    @State private var footHeight: CGFloat = 0

    /// Whether the page is scrolled far enough that its words travel
    /// under the bar. Measured as a flag, so a scroll redraws the page
    /// only when it flips, never frame by frame.
    @State private var wordsUnderBar = false

    /// Clears the note after its three seconds; restarted by each note,
    /// so a second note in the same words keeps its own three seconds
    @State private var noteClear: Task<Void, Never>?
    /// The last thing the ribbon said, held while its words fade out
    @State private var lastKeptNote = " "

    /// How tall the painting stands at the head of the page, the status
    /// bar's height included, as on the order page: low enough that the
    /// prayer begins on the first screen
    private static let heroHeight: CGFloat = 280

    /// Opened scrolled to its end, for a snapshot of the foot
    private let opensAtEnd: Bool

    /// A store, an end to open at and a note already showing are for the
    /// snapshot tests, which draw a page without walking to it and never
    /// touch the reader's own marks; otherwise the page opens at its head
    init(
        prayerID: String,
        store: PrayerBookStore = .shared,
        opensAtEnd: Bool = false,
        showingNote note: String? = nil
    ) {
        self.prayerID = prayerID
        self.store = store
        self.opensAtEnd = opensAtEnd
        _currentID = State(initialValue: prayerID)
        _keptNote = State(initialValue: note)
        _lastKeptNote = State(initialValue: note ?? " ")
    }

    private var prayer: BookPrayer? {
        PrayerBook.prayer(currentID) ?? BookPrayer.bundled(currentID, origin: nil, note: nil)
    }

    /// The chapter the page belongs to: the one it was first opened in
    private var chapter: PrayerBookChapter? {
        PrayerBook.homeChapter(of: prayerID)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appGradient.ignoresSafeArea()

            if let prayer {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 0).id("top")
                            page(prayer)
                                .opacity(pageOpacity)
                            stepper(proxy: proxy)
                                .padding(.top, 36)
                            // Room to scroll the last line clear of the
                            // foot, measured, as the order page keeps it
                            Color.clear.frame(height: max(240, footHeight))
                                .id("end")
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                    .onAppear {
                        if opensAtEnd { proxy.scrollTo("end", anchor: .bottom) }
                    }
                    .overlay(alignment: .top) { barVeil }
                }

                foot(prayer)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footHeight = $0 }
            } else {
                Text("This prayer could not be found.")
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxHeight: .infinity)
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
                }
            }
            if prayer?.hasLatin == true {
                ToolbarItem(placement: .navigationBarTrailing) {
                    LanguageChoice(language: languageBinding)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                RibbonToggle(prayerID: currentID) { kept in
                    say(kept
                        ? "Saved. Find it under Saved on the Prayers tab."
                        : "Removed from Saved.")
                }
            }
        }
        .sheet(isPresented: $showsLearn) {
            if let prayer {
                LearnByHeartSheet(prayer: prayer)
                    .environment(settings)
                    .presentationDetents([.large])
                    .presentationBackground(AppColors.background)
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            }
        }
    }

    // MARK: - The Page

    @ViewBuilder
    private func page(_ prayer: BookPrayer) -> some View {
        VStack(spacing: 0) {
            hero(prayer)
                .onGeometryChange(for: Bool.self) { proxy in
                    -proxy.frame(in: .global).minY > 70
                } action: { under in
                    withAnimation(Motion.crossfade) { wordsUnderBar = under }
                }

            // On the prayer's own margin, so the name and the words share
            // one left edge
            titleBlock(prayer)
                .padding(.horizontal, 28)
                .padding(.top, -48)
                .devotionalEntrance()

            PrayerText(
                content: prayer.content(for: settings.prayerLanguage),
                size: max(17, settings.meditationFontSize - 1),
                alignment: .leading,
                showsDropCap: true
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 22)
            .animation(Motion.crossfade, value: settings.prayerLanguagePreference)
            .devotionalEntrance(delay: 0.06)

            // When it is said, straight under the words: its place says
            // what it is, so it needs no heading of its own
            if let note = prayer.note {
                Text(note)
                    .font(AppFonts.readingItalicFont(15.5))
                    .foregroundColor(AppColors.cream.opacity(0.8))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 18)
            }

            quietActs(prayer)
                .padding(.horizontal, 20)
                .padding(.top, 26)

            ordersHolding(prayer)
                .padding(.horizontal, 28)
                .padding(.top, 34)
        }
    }

    /// The prayer's painting — its own scene where the book gives it one,
    /// else its topic's, as the Saved shelf hangs it — run to the top of
    /// the glass and dissolving into the page beneath the title
    private func hero(_ prayer: BookPrayer) -> some View {
        let painting = SavedPrayerPainting.of(prayer.id)
        return CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
            .frame(maxWidth: .infinity)
            .frame(height: Self.heroHeight)
            .clipped()
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
            .accessibilityHidden(true)
    }

    /// A veil under the status bar and the bar's Back: light over the
    /// painting at rest, and near opaque down past the bar once the title
    /// travels under it, so no word of the page stands inside the Back
    private var barVeil: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [AppColors.background.opacity(0.55), AppColors.background.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 110)

            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0.99), location: 0),
                    .init(color: AppColors.background.opacity(0.99), location: 0.8),
                    .init(color: AppColors.background.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 172)
            .opacity(wordsUnderBar ? 1 : 0)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    // The small capitals on this page stand at whole points (9, 10, 11):
    // a custom face that small is drawn at a whole point once scaled, so
    // 8.5, 9.5 and 10.5 stayed the same size at the larger text sizes
    // while everything around them grew.
    private func titleBlock(_ prayer: BookPrayer) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let chapter {
                Text((chapter.topic.isEmpty ? chapter.title : chapter.topic).uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2.4)
                    .foregroundColor(AppColors.gold)
                    // Lifted off the painting's dissolve, where a light
                    // passage of the painting can stand behind it
                    .shadow(color: AppColors.background.opacity(0.9), radius: 6)
            }

            Text(prayer.title)
                .font(AppFonts.titleFont(29))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .accessibilityAddTraits(.isHeader)

            if let latin = prayer.secondTitle {
                Text(latin)
                    .font(AppFonts.readingItalicFont(14.5))
                    .foregroundColor(AppColors.cream.opacity(0.55))
            }

            smallPrint(prayer)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.crossfade, value: keptNote)
    }

    /// Where the prayer comes from and the reader's LEARNED mark, on one
    /// small line. What the ribbon says stands in that line's place for a
    /// moment, laid over it rather than under it: given a line of its own
    /// it pushed the whole page down, and back up three seconds later.
    @ViewBuilder
    private func smallPrint(_ prayer: BookPrayer) -> some View {
        let learned = store.isByHeart(prayer.id)
        if prayer.origin != nil || learned {
            OriginLine(origin: prayer.origin, learned: learned)
                .opacity(keptNote == nil ? 1 : 0)
                // Hung from the line's top, so the longest note may take a
                // second line into the gap above the prayer rather than
                // shrink to fit one
                .overlay(alignment: .topLeading) {
                    Text(lastKeptNote)
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.gold.opacity(0.9))
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        // Its own height, not the small print's, or the
                        // line's height scales the words down to fit it
                        .fixedSize(horizontal: false, vertical: true)
                        .offset(y: -2)
                        .opacity(keptNote == nil ? 0 : 1)
                        .accessibilityHidden(true)
                }
        } else if let keptNote {
            Text(keptNote)
                .font(AppFonts.readingItalicFont(13.5))
                .foregroundColor(AppColors.gold.opacity(0.9))
                .transition(.opacity)
                .accessibilityHidden(true)
        }
    }

    /// Learn it by heart and, where the Church sings it, hear it sung:
    /// two quiet acts in words, so neither stands as tall as PRAY
    private func quietActs(_ prayer: BookPrayer) -> some View {
        let learn = QuietGoldButton(
            title: store.isByHeart(prayer.id) ? "Say it by heart again" : "Learn by heart",
            leadingIcon: "ph-heart",
            leadingIconSize: 12,
            size: 11,
            color: AppColors.gold.opacity(0.85),
            horizontalPadding: 10
        ) {
            showsLearn = true
        }
        .accessibilityHint("Opens the steps to learn it by heart")

        // The first setting (a simple tone before a solemn one); the
        // chant's page offers the others
        let chant = ChantCatalog.chants(forPrayer: prayer.id).first
        let sung = chant.map { chant in
            QuietGoldButton(
                title: "Hear it sung",
                leadingIcon: "ph-music-note",
                leadingIconSize: 12,
                size: 11,
                color: AppColors.gold.opacity(0.85),
                horizontalPadding: 10
            ) {
                router.push(.chant(id: chant.id))
            }
            .accessibilityHint("Opens a sung recording, with its sheet music")
        }

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                learn
                if let sung { sung }
            }
            VStack(spacing: 0) {
                learn
                if let sung { sung }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// The orders this prayer is said in, each a door with its painting
    @ViewBuilder
    private func ordersHolding(_ prayer: BookPrayer) -> some View {
        let orders = PrayerBook.orders.filter { $0.prayerIDs(Date()).contains(prayer.id) }
        if !orders.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("SAID IN")
                    .font(AppFonts.labelFont(9))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 0) {
                    ForEach(Array(orders.enumerated()), id: \.element.id) { i, order in
                        SaidInRow(order: order, showsRule: i < orders.count - 1) {
                            router.push(.prayerOrder(id: order.id))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stepping along the chapter

    @ViewBuilder
    private func stepper(proxy: ScrollViewProxy) -> some View {
        if let chapter, let index = chapter.prayerIDs.firstIndex(of: currentID) {
            let ids = chapter.prayerIDs
            let previous = index > 0 ? PrayerBook.prayer(ids[index - 1]) : nil
            let next = index < ids.count - 1 ? PrayerBook.prayer(ids[index + 1]) : nil

            VStack(spacing: 14) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.15))
                    .frame(height: AppLine.hairline)

                // Unreachable while the app holds the text at .xLarge; kept,
                // as other pages keep theirs, in case the cap is lifted
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 14) {
                        if let previous { stepButton(previous, forward: false, proxy: proxy) }
                        if let next { stepButton(next, forward: true, proxy: proxy) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(alignment: .top) {
                        if let previous {
                            stepButton(previous, forward: false, proxy: proxy)
                        }
                        Spacer(minLength: 12)
                        if let next {
                            stepButton(next, forward: true, proxy: proxy)
                        }
                    }
                }

                QuietGoldButton(title: "All \(ids.count) \(Self.doorName(of: chapter))", trailingIcon: "ph-caret-right") {
                    router.push(.prayerBookChapter(id: chapter.id))
                }
            }
            .padding(.horizontal, 28)
        }
    }

    /// The topic as the door to it says it: "All 11 First Prayers", where
    /// the topic's own name, "The First Prayers", read "All 11 The First
    /// Prayers"
    static func doorName(of chapter: PrayerBookChapter) -> String {
        chapter.topic.hasPrefix("The ") ? String(chapter.topic.dropFirst(4)) : chapter.topic
    }

    private func stepButton(_ target: BookPrayer, forward: Bool, proxy: ScrollViewProxy) -> some View {
        Button {
            step(to: target.id, proxy: proxy)
        } label: {
            VStack(alignment: forward ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 5) {
                    if !forward { AppIcon("ph-caret-left", size: 9) }
                    Text(forward ? "NEXT" : "PREVIOUS")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                    if forward { AppIcon("ph-caret-right", size: 9) }
                }
                .foregroundColor(AppColors.gold.opacity(0.8))

                Text(target.title)
                    .font(AppFonts.readingFont(15.5))
                    .foregroundColor(AppColors.cream.opacity(0.9))
                    .multilineTextAlignment(forward ? .trailing : .leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 160, alignment: forward ? .trailing : .leading)
            // Hung from the top, so PREVIOUS and NEXT share a line when
            // one title wraps and the other does not
            .frame(minHeight: 44, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(forward ? "Next" : "Previous"), \(target.title)")
    }

    /// Fades the page out, swaps the prayer and puts the scroll back to
    /// the top unseen, then fades in — never a flash of the old title or
    /// the old painting
    private func step(to id: String, proxy: ScrollViewProxy) {
        withAnimation(.easeIn(duration: 0.14)) { pageOpacity = 0 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            currentID = id
            keptNote = nil
            proxy.scrollTo("top", anchor: .top)
            withAnimation(.easeOut(duration: 0.24)) { pageOpacity = 1 }
        }
    }

    // MARK: - Foot

    /// PRAY, the page's one gold act, beside the round speaker that says
    /// how it will be prayed: the order page's own foot
    private func foot(_ prayer: BookPrayer) -> some View {
        let aloud = store.praysAloud
        let voice = voices.chosenVoice.name.lowercased()

        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(Motion.settle) { store.praysAloud.toggle() }
                } label: {
                    SpeakerGlyph(aloud: aloud)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle().strokeBorder(AppColors.gold.opacity(aloud ? 0.6 : 0.35), lineWidth: 1.2)
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("Pray aloud")
                .accessibilityAddTraits(.isToggle)
                .accessibilityValue(aloud ? "On, the \(voice) voice" : "Off")

                GoldCTAButton(title: "Pray", glyph: .play) {
                    // The speaker stands beside PRAY, so what it shows is
                    // the reader's answer; the pray-along screen won't ask
                    store.chooseAloud(store.praysAloud)
                    router.push(.prayAlong(.prayer(prayer)))
                }
            }

            Text(aloud ? "Aloud, in the \(voice) voice" : "In silence")
                .font(AppFonts.readingItalicFont(13))
                .foregroundColor(AppColors.textSecondary)
                .contentTransition(.opacity)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 24)
        // Clear of the ground's fade, so the page never reads through
        // the speaker
        .padding(.top, 92)
        .padding(.bottom, 16)
        .background(PrayFootGround())
    }

    // MARK: - Language

    /// English, Latin, or both, written to the app's prayer language —
    /// the same choice the Rosary and the Missal read
    private var languageBinding: Binding<PrayerLanguage> {
        Binding(
            get: { settings.prayerLanguage },
            set: { settings.prayerLanguagePreference = $0.rawValue }
        )
    }

    private func say(_ note: String) {
        lastKeptNote = note
        keptNote = note
        // Heard as well as seen: the words above are hidden from
        // VoiceOver, and scrolled down the page they are out of sight
        AccessibilityNotification.Announcement(note).post()
        noteClear?.cancel()
        noteClear = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            keptNote = nil
        }
    }
}

// MARK: - Where it comes from

/// "WESTERN CHURCH · 11TH CENTURY · ✓ LEARNED": the prayer book's small
/// print, and the reader's own mark after it
private struct OriginLine: View {
    let origin: String?
    let learned: Bool

    var body: some View {
        // On one line where it fits; else LEARNED takes a line of its own
        // rather than being cut, as the order page sets PRAYED TODAY
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                if let origin {
                    originText(origin)
                        .fixedSize()
                    if learned {
                        Text("·").foregroundColor(AppColors.textSecondary)
                    }
                }
                if learned { mark }
            }

            VStack(alignment: .leading, spacing: 6) {
                if let origin {
                    originText(origin)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if learned { mark }
            }
        }
        .font(AppFonts.labelFont(9))
        .tracking(1.8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [origin, learned ? "Learned by heart" : nil].compactMap { $0 }.joined(separator: ". ")
        )
    }

    private func originText(_ origin: String) -> some View {
        Text(origin.uppercased())
            .foregroundColor(AppColors.textSecondary)
    }

    private var mark: some View {
        HStack(spacing: 5) {
            AppIcon("ph-seal-check-fill", size: 11)
            Text("LEARNED")
        }
        .foregroundColor(AppColors.gold.opacity(0.9))
        .fixedSize()
    }
}

// MARK: - Said in

/// One order the prayer is said in: its painting, its name, when it is
/// said, a caret
private struct SaidInRow: View {
    let order: PrayerOrder
    let showsRule: Bool
    let action: () -> Void

    var body: some View {
        let painting = PrayerBookPainting.order(order)
        let title = order.title(on: Date())

        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline)
                        )
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(AppColors.cream)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(order.occasion)
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    AppIcon("ph-caret-right", size: 11)
                        .foregroundColor(AppColors.gold.opacity(0.5))
                }
                .padding(.vertical, 12)
                .frame(minHeight: 60)

                if showsRule {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.12))
                        .frame(height: AppLine.hairline)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        // Combined and named on the Button itself: made an element of
        // its own with the button's trait added, the row was found twice
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(order.occasion)")
    }
}

// MARK: - The speaker

/// The speaker on the foot's disc: sounding when the prayer will be read
/// aloud, struck through and dimmed when it will be prayed in silence.
/// The order page's own, which it keeps to itself.
private struct SpeakerGlyph: View {
    let aloud: Bool

    var body: some View {
        ZStack {
            AppIcon(aloud ? "ph-speaker-high-fill" : "ph-speaker-high", size: 19)
                .foregroundColor(AppColors.gold.opacity(aloud ? 1 : 0.55))
            Capsule()
                .fill(AppColors.gold)
                .frame(width: 1.4, height: 26)
                .rotationEffect(.degrees(-45))
                .opacity(aloud ? 0 : 1)
        }
    }
}

// MARK: - Language Choice

/// The language in the bar: what is chosen, "EN", "LA" or "EN · LA",
/// beside the ribbon in the bar's glass (on a dark capsule of its own
/// before iOS 26), opening a choice of the three. It stood as a bar of three
/// chips above the prayer, the heaviest thing over the words, for a choice
/// made once.
private struct LanguageChoice: View {
    @Binding var language: PrayerLanguage

    private enum Choice: String, CaseIterable, Identifiable {
        case english = "English", latin = "Latin", both = "Both"
        var id: Self { self }
    }

    private var chosen: Choice {
        switch language {
        case .english: return .english
        case .latin: return .latin
        case .both, .latinUnderEnglish: return .both
        }
    }

    private var choice: Binding<Choice> {
        Binding(
            get: { chosen },
            set: { choice in
                withAnimation(Motion.settle) {
                    switch choice {
                    case .english: language = .english
                    case .latin: language = .latin
                    case .both:
                        if !language.isBilingual { language = .latinUnderEnglish }
                    }
                }
            }
        )
    }

    private var shortName: String {
        switch chosen {
        case .english: return "EN"
        case .latin: return "LA"
        case .both: return "EN · LA"
        }
    }

    @ViewBuilder
    private var label: some View {
        let name = Text(shortName)
            .font(AppFonts.labelFont(12))
            .tracking(1.6)
            .foregroundColor(AppColors.gold)
            .fixedSize()
        // From iOS 26 the bar's own glass is the capsule, shared with
        // the ribbon; a dark one inside it stood as a second rim
        if #available(iOS 26.0, *) {
            name
                .padding(.horizontal, 8)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        } else {
            name
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Capsule().fill(AppColors.background.opacity(0.85)))
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
    }

    @State private var choosing = false

    var body: some View {
        // A button opening the three, not a Menu: the bar makes a Menu
        // its own button and names it from the words it shows ("EN"),
        // whatever name it is given, and once stood a second, unnamed
        // button beside it
        Button {
            choosing = true
        } label: {
            label
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("Language")
        .accessibilityValue(chosen.rawValue)
        .accessibilityHint("Choose English, Latin or both")
        .sensoryFeedback(.selection, trigger: chosen)
        .confirmationDialog("Language", isPresented: $choosing, titleVisibility: .visible) {
            ForEach(Choice.allCases) { option in
                Button(option.rawValue) {
                    choice.wrappedValue = option
                }
            }
        } message: {
            Text(chosen == .both ? "Shown now in English and Latin." : "Shown now in \(chosen.rawValue).")
        }
    }
}

// MARK: - Language Chips

/// ENGLISH · LATIN · BOTH, the choice a prayer book with facing pages
/// gives by being opened wider
struct LanguageChips: View {
    @Binding var language: PrayerLanguage

    /// Off where one language at a time is the point — learning by heart
    var showsBoth: Bool = true

    private enum Choice: CaseIterable {
        case english, latin, both

        var label: String {
            switch self {
            case .english: return "English"
            case .latin:   return "Latin"
            case .both:    return "Both"
            }
        }
    }

    private var chosen: Choice {
        switch language {
        case .english: return .english
        case .latin: return .latin
        case .both, .latinUnderEnglish: return .both
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Choice.allCases.filter { showsBoth || $0 != .both }, id: \.self) { choice in
                let on = choice == chosen
                Button {
                    withAnimation(Motion.settle) {
                        switch choice {
                        case .english: language = .english
                        case .latin: language = .latin
                        case .both:
                            if !language.isBilingual { language = .latinUnderEnglish }
                        }
                    }
                } label: {
                    // Side room so the names never run together at the
                    // larger text sizes, and the whole 44-point band
                    // answers a touch, not only the 32-point chip
                    Text(choice.label.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(on ? AppColors.goldLight : AppColors.gold.opacity(0.65))
                        .padding(.horizontal, 8)
                        .frame(minWidth: 74, minHeight: 32)
                        .background(
                            Capsule().fill(on ? AppColors.gold.opacity(0.16) : Color.clear)
                        )
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(choice.label)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, 4)
        .overlay(
            Capsule()
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
                .frame(height: 38)
        )
        .sensoryFeedback(.selection, trigger: chosen)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookPrayerView(prayerID: "hail_holy_queen")
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
