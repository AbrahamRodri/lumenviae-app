//
//  BookPrayerView.swift
//  Lumen Viae
//
//  One prayer of the Prayer Book as a holy card (the "Holy Cards" pick,
//  option B4, Oct 2026): the card stands between the bar and the foot,
//  its painting set in an arch at its head, the topic and the prayer's
//  place in it, its name and its Latin, then the prayer, the orders it is
//  said in, and its place among the topic's prayers as a row of dots. The
//  prayers before and after it peek in at the edges of the glass. The
//  card's words scroll inside it; a drag across deals the card away, the
//  next one rising from beneath it, as a stack of holy cards is turned.
//  At the foot, Learn by heart and Hear it sung stand either side of
//  PRAY, and one line beneath says how it will be prayed. The language
//  is a small button in the bar, the ribbon beside it.
//
//  The page once ended on the prayer's note (when it is said), its
//  source on a line of small capitals, two quiet acts after the words and
//  PREVIOUS · NEXT as two lines of small capitals. The note and the
//  source stay in the book; the page no longer draws them.
//
//  Every door to a prayer in the app lands here (`AppRoute.devotionPrayer`).
//  The cards are the prayers of the topic the page was opened in.
//

import SwiftUI

struct BookPrayerView: View {

    let prayerID: String

    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let store: PrayerBookStore
    private var voices = NarrationVoiceCatalog.shared

    /// The prayer on the card in front, which the deal moves along the topic
    @State private var currentID: String
    @State private var showsLearn = false
    @State private var keptNote: String?

    /// How far the card in front has travelled across, in points:
    /// negative toward the next prayer, positive toward the one before
    @State private var travel: CGFloat
    /// Whether the drag under way was taken as a deal or left to the scroll
    @State private var dragIsAcross: Bool?
    /// A card on its way out: no drag is taken until it has gone
    @State private var dealing = false
    /// The card's opacity during a turn made under Reduce Motion
    @State private var fade: Double = 1
    /// Counts the cards dealt, for the tick each one gives
    @State private var dealt = 0
    @State private var deckWidth: CGFloat = 337

    /// Clears the note after its three seconds; restarted by each note
    @State private var noteClear: Task<Void, Never>?
    /// The last thing the ribbon said, held while its words fade out
    @State private var lastKeptNote = " "

    /// Opened scrolled to its end, for a snapshot of the card's foot
    private let opensAtEnd: Bool

    /// A store, an end to open at, a note already showing and a card part
    /// way through its deal are for the snapshot tests, which draw a page
    /// without walking to it and never touch the reader's own marks;
    /// otherwise the page opens on its card, at rest
    init(
        prayerID: String,
        store: PrayerBookStore = .shared,
        opensAtEnd: Bool = false,
        showingNote note: String? = nil,
        turnedBy turn: CGFloat = 0
    ) {
        self.prayerID = prayerID
        self.store = store
        self.opensAtEnd = opensAtEnd
        _currentID = State(initialValue: prayerID)
        _keptNote = State(initialValue: note)
        _lastKeptNote = State(initialValue: note ?? " ")
        _travel = State(initialValue: turn)
    }

    private static func prayer(_ id: String) -> BookPrayer? {
        PrayerBook.prayer(id) ?? BookPrayer.bundled(id, origin: nil, note: nil)
    }

    private var prayer: BookPrayer? { Self.prayer(currentID) }

    /// The chapter the page belongs to: the one it was first opened in
    private var chapter: PrayerBookChapter? {
        PrayerBook.homeChapter(of: prayerID)
    }

    private var ids: [String] { chapter?.prayerIDs ?? [] }
    private var index: Int? { ids.firstIndex(of: currentID) }

    private var previousID: String? {
        guard let index, index > 0 else { return nil }
        return ids[index - 1]
    }

    private var nextID: String? {
        guard let index, index < ids.count - 1 else { return nil }
        return ids[index + 1]
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            if let prayer {
                VStack(spacing: 0) {
                    deck(prayer)
                        .padding(.top, 6)
                    foot(prayer)
                }
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
        .sensoryFeedback(.impact(weight: .light), trigger: dealt)
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

    // MARK: - The deck

    /// How far through a deal the card in front is, 0 at rest and 1 gone
    private var progress: CGFloat {
        min(1, abs(travel) / max(deckWidth, 1))
    }

    /// The card waiting beneath the one in front: the next prayer while the
    /// front card goes left, the one before while it goes right
    private var beneathID: String? {
        if travel < 0 { return nextID }
        if travel > 0 { return previousID }
        return nil
    }

    private func deck(_ prayer: BookPrayer) -> some View {
        ZStack {
            if let beneathID, let beneath = Self.prayer(beneathID) {
                card(beneath, opensAtEnd: false)
                    .scaleEffect(reduceMotion ? 1 : 0.94 + 0.06 * progress)
                    .opacity(reduceMotion ? 0 : 0.85 + 0.15 * Double(progress))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            card(prayer, opensAtEnd: opensAtEnd)
                .id(currentID)
                .offset(x: travel)
                // Leans into the deal, as a card lifted from a stack does
                .rotationEffect(.degrees(reduceMotion ? 0 : Double(travel / max(deckWidth, 1)) * 9))
                // Opaque as it goes: the card beneath never reads through it
                .opacity(fade)
        }
        .padding(.horizontal, 28)
        .onGeometryChange(for: CGFloat.self) { $0.size.width - 56 } action: { deckWidth = $0 }
        // The edges step back while a card is dealt, so the card in hand
        // never passes beneath them
        .overlay(alignment: .leading) { peek(previousID, leading: true).opacity(travel == 0 ? 1 : 0) }
        .overlay(alignment: .trailing) { peek(nextID, leading: false).opacity(travel == 0 ? 1 : 0) }
        .animation(Motion.crossfade, value: travel == 0)
        .overlay(alignment: .top) { savedNote }
        // The card's own scroll keeps the vertical drag; a drag that
        // starts across deals the card
        .simultaneousGesture(
            DragGesture(minimumDistance: 14)
                .onChanged { value in
                    guard !dealing else { return }
                    if dragIsAcross == nil {
                        dragIsAcross = abs(value.translation.width) > abs(value.translation.height)
                    }
                    guard dragIsAcross == true else { return }
                    let dx = value.translation.width
                    // Toward no card, it gives a little and comes back
                    let hasCard = dx < 0 ? nextID != nil : previousID != nil
                    travel = hasCard ? dx : dx * 0.25
                }
                .onEnded { value in
                    defer { dragIsAcross = nil }
                    guard dragIsAcross == true, !dealing else { return }
                    let dx = value.translation.width
                    let flung = value.predictedEndTranslation.width
                    let target = dx < 0 ? nextID : previousID
                    if let target, abs(dx) > deckWidth / 3 || abs(flung) > deckWidth * 0.6 {
                        deal(to: target)
                    } else {
                        withAnimation(Motion.settle) { travel = 0 }
                    }
                }
        )
    }

    /// One prayer's card, the one in front or the one beneath it
    private func card(_ prayer: BookPrayer, opensAtEnd: Bool) -> some View {
        let position = ids.firstIndex(of: prayer.id)
        let kicker = chapter.map { chapter -> String in
            let topic = (chapter.topic.isEmpty ? chapter.title : chapter.topic).uppercased()
            guard let position else { return topic }
            return "\(topic) · \(position + 1) OF \(ids.count)"
        }
        return HolyCard(
            prayer: prayer,
            kicker: kicker,
            content: prayer.content(for: settings.prayerLanguage),
            textSize: max(17, settings.meditationFontSize - 2),
            opensAtEnd: opensAtEnd,
            onNext: nextID.map { id in { deal(to: id) } },
            onPrevious: previousID.map { id in { deal(to: id) } }
        ) {
            cardFoot(prayer, position: position)
        }
        .animation(Motion.crossfade, value: settings.prayerLanguagePreference)
    }

    /// What closes the card: the orders it is said in, then its place
    /// among the topic's prayers and the way on
    @ViewBuilder
    private func cardFoot(_ prayer: BookPrayer, position: Int?) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            ordersHolding(prayer)
            if let chapter, let position {
                place(in: chapter, at: position)
            }
        }
    }

    /// The orders this prayer is said in, each a door with its painting
    @ViewBuilder
    private func ordersHolding(_ prayer: BookPrayer) -> some View {
        let orders = PrayerBook.orders.filter { $0.prayerIDs(Date()).contains(prayer.id) }
        if !orders.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text("SAID IN")
                    .font(AppFonts.labelFont(9))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .accessibilityAddTraits(.isHeader)

                ForEach(orders) { order in
                    SaidInRow(order: order) {
                        router.push(.prayerOrder(id: order.id))
                    }
                }
            }
        }
    }

    /// The topic's prayers as a row of dots, this one lit, over "Swipe for
    /// the next · All 32"
    private func place(in chapter: PrayerBookChapter, at position: Int) -> some View {
        let next = position < ids.count - 1 ? Self.prayer(ids[position + 1]) : nil
        let all = QuietGoldButton(title: "All \(ids.count)", trailingIcon: "ph-caret-right", size: 10) {
            router.push(.prayerBookChapter(id: chapter.id))
        }
        .accessibilityLabel("All \(ids.count) \(Self.doorName(of: chapter))")

        return VStack(spacing: 8) {
            PlaceDots(count: ids.count, current: position)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    if let next { swipeFor(next) }
                    all
                }
                VStack(spacing: 0) {
                    if let next { swipeFor(next) }
                    all
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func swipeFor(_ next: BookPrayer) -> some View {
        Button {
            deal(to: next.id)
        } label: {
            Text("Swipe for \(next.title) ·")
                .font(AppFonts.readingItalicFont(13.5))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("Next prayer, \(next.title)")
    }

    /// The topic as the door to it says it: "All 11 First Prayers", where
    /// the topic's own name, "The First Prayers", read "All 11 The First
    /// Prayers"
    static func doorName(of chapter: PrayerBookChapter) -> String {
        chapter.topic.hasPrefix("The ") ? String(chapter.topic.dropFirst(4)) : chapter.topic
    }

    /// The edge of the card before or after this one, peeking in at the
    /// side of the glass: its painting in a sliver, a door to it
    @ViewBuilder
    private func peek(_ id: String?, leading: Bool) -> some View {
        if let id {
            let painting = SavedPrayerPainting.of(id)
            let shape = UnevenRoundedRectangle(
                topLeadingRadius: leading ? 0 : 12,
                bottomLeadingRadius: leading ? 0 : 12,
                bottomTrailingRadius: leading ? 12 : 0,
                topTrailingRadius: leading ? 12 : 0,
                style: .continuous
            )
            Button {
                deal(to: id)
            } label: {
                CachedAssetImage(
                    painting.resolvedAsset,
                    focal: UnitPoint(x: leading ? 0.8 : 0.2, y: painting.focal.y)
                )
                .frame(width: 14)
                .frame(maxHeight: 470)
                .clipShape(shape)
                .overlay(shape.strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline))
                .opacity(0.6)
                .padding(.vertical, 40)
                // Answers a touch across the gutter, clear of the card
                .padding(leading ? .trailing : .leading, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .accessibilityHidden(true)
        }
    }

    /// What the ribbon says, on a dark capsule at the head of the card for
    /// three seconds; heard as well, since the bar's ribbon is far from it
    private var savedNote: some View {
        Text(lastKeptNote)
            .font(AppFonts.readingItalicFont(13.5))
            .foregroundColor(AppColors.gold)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(AppColors.background.opacity(0.92)))
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline))
            .padding(.horizontal, 44)
            .padding(.top, 14)
            .opacity(keptNote == nil ? 0 : 1)
            .animation(Motion.crossfade, value: keptNote)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: - Dealing

    /// Deals the card in front away toward `id`'s side: it flies off, the
    /// card beneath it rises to full, and takes its place, opened at its
    /// top. Under Reduce Motion the one card fades into the other.
    private func deal(to id: String) {
        guard !dealing, let target = Self.prayer(id) else { return }
        let forward = id == nextID
        dealing = true

        let settle = {
            var still = Transaction()
            still.disablesAnimations = true
            withTransaction(still) {
                currentID = id
                travel = 0
            }
            keptNote = nil
            dealt += 1
            dealing = false
            AccessibilityNotification.Announcement(target.title).post()
        }

        if reduceMotion {
            withAnimation(.easeIn(duration: 0.14)) {
                fade = 0
                travel = 0
            } completion: {
                settle()
                withAnimation(.easeOut(duration: 0.24)) { fade = 1 }
            }
            return
        }

        // A turn begun by a tap starts from rest: nudge the card first, so
        // the one beneath is there to rise as it goes
        if travel == 0 {
            var still = Transaction()
            still.disablesAnimations = true
            withTransaction(still) { travel = forward ? -0.5 : 0.5 }
        }
        withAnimation(.easeIn(duration: 0.3)) {
            travel = (forward ? -1 : 1) * deckWidth * 1.15
        } completion: {
            settle()
        }
    }

    // MARK: - Foot

    /// Learn by heart and Hear it sung either side of PRAY, the page's one
    /// gold act, and beneath them how it will be prayed
    private func foot(_ prayer: BookPrayer) -> some View {
        let aloud = store.praysAloud
        let voice = voices.chosenVoice.name.lowercased()
        let learned = store.isByHeart(prayer.id)
        // The first setting (a simple tone before a solemn one); the
        // chant's page offers the others
        let chant = ChantCatalog.chants(forPrayer: prayer.id).first

        return VStack(spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                FootAct(
                    icon: learned ? "ph-seal-check-fill" : "ph-heart",
                    label: learned ? "Learned" : "Learn by heart"
                ) {
                    showsLearn = true
                }
                .accessibilityLabel("Learn by heart")
                .accessibilityValue(learned ? "Learned" : "")
                .accessibilityHint("Opens the steps to learn it by heart")

                GoldCTAButton(title: "Pray", glyph: .play) {
                    // The line beneath says how it will be prayed, so it is
                    // the reader's answer; the pray-along screen won't ask
                    store.chooseAloud(store.praysAloud)
                    router.push(.prayAlong(.prayer(prayer)))
                }

                // A prayer with no chant keeps the place empty, so PRAY
                // stands where it stood on the card before
                if let chant {
                    FootAct(icon: "ph-music-note", label: "Hear it sung") {
                        router.push(.chant(id: chant.id))
                    }
                    .accessibilityHint("Opens a sung recording, with its sheet music")
                } else {
                    Color.clear.frame(width: FootAct.width, height: 1)
                }
            }

            Button {
                withAnimation(Motion.settle) { store.praysAloud.toggle() }
            } label: {
                HStack(spacing: 6) {
                    AppIcon(aloud ? "ph-speaker-high-fill" : "ph-speaker-high", size: 12)
                        .foregroundColor(AppColors.gold.opacity(aloud ? 0.9 : 0.55))
                    Text(aloud ? "Aloud, in the \(voice) voice · tap to change" : "In silence · tap to change")
                        .font(AppFonts.readingItalicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .contentTransition(.opacity)
                }
                .frame(minHeight: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .accessibilityLabel("Pray aloud")
            .accessibilityAddTraits(.isToggle)
            .accessibilityValue(aloud ? "On, the \(voice) voice" : "Off")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
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
        // Heard as well as seen: the words are hidden from VoiceOver
        AccessibilityNotification.Announcement(note).post()
        noteClear?.cancel()
        noteClear = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            keptNote = nil
        }
    }
}

// MARK: - The holy card

/// A prayer as a holy card: its painting in an arch at the head, the
/// topic and its place, the name and the Latin, a gold rule, the prayer,
/// then whatever closes it. A gold rim with a second rule inside it, on
/// the card's own ground. The words scroll inside the card.
private struct HolyCard<Foot: View>: View {
    let prayer: BookPrayer
    let kicker: String?
    let content: String
    let textSize: CGFloat
    let opensAtEnd: Bool
    let onNext: (() -> Void)?
    let onPrevious: (() -> Void)?
    @ViewBuilder let foot: () -> Foot

    private static var corner: CGFloat { 20 }

    var body: some View {
        let painting = SavedPrayerPainting.of(prayer.id)

        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 150,
                                bottomLeadingRadius: 10,
                                bottomTrailingRadius: 10,
                                topTrailingRadius: 150,
                                style: .continuous
                            )
                        )
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
                        .padding([.horizontal, .top], 12)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 0) {
                        if let kicker {
                            Text(kicker)
                                .font(AppFonts.labelFont(10))
                                .tracking(2.2)
                                .foregroundColor(AppColors.gold)
                                .shadow(color: AppColors.cardBackground.opacity(0.9), radius: 6)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text(prayer.title)
                            .font(AppFonts.titleFont(24))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                            .accessibilityAddTraits(.isHeader)
                            .modifier(TurnActions(onNext: onNext, onPrevious: onPrevious))

                        if let latin = prayer.secondTitle {
                            Text(latin)
                                .font(AppFonts.readingItalicFont(14.5))
                                .foregroundColor(AppColors.cream.opacity(0.55))
                                .padding(.top, 3)
                        }

                        Rectangle()
                            .fill(AppColors.gold.opacity(0.25))
                            .frame(height: AppLine.hairline)
                            .padding(.vertical, 14)

                        PrayerText(
                            content: content,
                            size: textSize,
                            alignment: .leading,
                            showsDropCap: true
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(TurnActions(onNext: onNext, onPrevious: onPrevious))

                        foot()
                            .padding(.top, 26)

                        Color.clear.frame(height: 10).id("end")
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, -22)
                    .padding(.bottom, 12)
                }
            }
            .onAppear {
                if opensAtEnd { proxy.scrollTo("end", anchor: .bottom) }
            }
            // The words dissolve at the card's edges as they scroll,
            // never cut by the rim
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 14)
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 14)
                }
            )
        }
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Self.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
                .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline)
        )
        // The second rule inside the rim, as a printed holy card has
        .overlay(
            RoundedRectangle(cornerRadius: Self.corner - 5, style: .continuous)
                .strokeBorder(AppColors.gold.opacity(0.16), lineWidth: AppLine.hairline)
                .padding(5)
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(0.5), radius: 18, y: 12)
    }
}

/// Next prayer and Previous prayer for VoiceOver, which cannot drag
private struct TurnActions: ViewModifier {
    let onNext: (() -> Void)?
    let onPrevious: (() -> Void)?

    func body(content: Content) -> some View {
        content.accessibilityActions {
            if let onNext {
                Button("Next prayer", action: onNext)
            }
            if let onPrevious {
                Button("Previous prayer", action: onPrevious)
            }
        }
    }
}

// MARK: - The place in the topic

/// The topic's prayers as dots, the one on the card lit and those before
/// it half lit. A long topic shows the 24 around this one.
private struct PlaceDots: View {
    let count: Int
    let current: Int

    private static let most = 24

    var body: some View {
        let first = count <= Self.most ? 0 : min(max(0, current - Self.most / 2), count - Self.most)
        let last = min(count, first + Self.most) - 1

        HStack(spacing: 4) {
            ForEach(first...last, id: \.self) { i in
                Circle()
                    .fill(
                        i == current
                            ? AppColors.gold
                            : AppColors.gold.opacity(i < current ? 0.5 : 0.22)
                    )
                    .frame(width: i == current ? 6 : 5, height: i == current ? 6 : 5)
            }
        }
        .frame(minHeight: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Prayer \(current + 1) of \(count)")
    }
}

// MARK: - The foot's acts

/// Learn by heart or Hear it sung: a ringed disc with its glyph, the act
/// named beneath it in small capitals
private struct FootAct: View {
    let icon: String
    let label: String
    let action: () -> Void

    static let width: CGFloat = 76

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                AppIcon(icon, size: 19)
                    .foregroundColor(AppColors.gold.opacity(0.85))
                    .frame(width: 52, height: 52)
                    .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1.2))
                Text(label.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.2)
                    .foregroundColor(AppColors.gold)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: Self.width)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
    }
}

// MARK: - Said in

/// One order the prayer is said in: its painting, its name, a caret
private struct SaidInRow: View {
    let order: PrayerOrder
    let action: () -> Void

    var body: some View {
        let painting = PrayerBookPainting.order(order)
        let title = order.title(on: Date())

        Button(action: action) {
            HStack(spacing: 14) {
                CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline)
                    )
                    .accessibilityHidden(true)

                Text(title)
                    .font(AppFonts.readingFont(17))
                    .foregroundColor(AppColors.cream)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                AppIcon("ph-caret-right", size: 11)
                    .foregroundColor(AppColors.gold.opacity(0.5))
            }
            .padding(.vertical, 8)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        // Combined and named on the Button itself: made an element of
        // its own with the button's trait added, the row was found twice
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
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
