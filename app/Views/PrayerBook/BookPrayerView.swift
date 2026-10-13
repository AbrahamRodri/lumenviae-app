//
//  BookPrayerView.swift
//  Lumen Viae
//
//  One prayer of the Prayer Book as a holy card (the "Holy Cards" pick,
//  option B4, Oct 2026): the card stands from the bar to the foot of the
//  glass, its painting set in an arch at its head, the set and the
//  prayer's place in it, its name and its Latin, then the prayer, the
//  orders it is said in, and its place among the set's prayers as a row
//  of dots. The prayers before and after it peek in at the edges of the
//  glass. The card's words scroll inside it, under its floor: PRAY with
//  Learn by heart and Hear it sung as small rings either side, on a fade
//  of the card's own ground. A drag across turns to the next card, which
//  slides in from the right over this one (the "Chant shelves and prayer
//  cards" pick: no foot, slide over, Oct 2026). The language is a small
//  button in the bar, the ribbon beside it.
//
//  The page once had a foot of its own under the card: two 52-point
//  rings named in small capitals either side of a 56-point PRAY, and a
//  line beneath, "Aloud, in the male voice · tap to change", which took
//  some 200 points from the prayer. Aloud or in silence is the
//  pray-along's choice: it asks before its first sound, and its head
//  says it in a word. The card was dealt away, leaning up to 9 degrees
//  and speeding up as it flew, the next rising from beneath: it read as
//  a card thrown away more than a page turned, and nothing said which
//  way the next one lay.
//
//  The set is the topic or the order the prayer was opened from
//  (`PrayerSet`, `PrayerDeck`): opened from Before Confession, the cards
//  are Before Confession's. From anywhere else they are the prayer's own
//  topic's.
//
//  The page once ended on the prayer's note (when it is said), its
//  source on a line of small capitals, two quiet acts after the words and
//  PREVIOUS · NEXT as two lines of small capitals. The note and the
//  source stay in the book; the page no longer draws them.
//

import SwiftUI

struct BookPrayerView: View {

    let prayerID: String

    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings

    private let store: PrayerBookStore

    /// The day the page reads its orders on: which orders say the prayer,
    /// and an order's prayers in their seasons. Held, as the deck is, so
    /// the page reads one day for its whole life.
    @State private var day: Date

    /// The prayers the cards deal through, read once when the page opens
    /// and held, so a season turning while it is open never moves the
    /// place under the reader
    @State private var deck: PrayerDeck

    /// The place in the deck of the card in front; nil for a prayer
    /// outside every set, which has no neighbours
    @State private var position: Int?
    @State private var showsLearn = false
    /// The orders that say each prayer of the deck, worked out once with it
    @State private var saidIn: [String: [String]]
    /// What the ribbon last said, read only by the note itself, so a Save
    /// redraws the note and nothing else
    @State private var note: RibbonNote
    /// A deal asked for by a tap (a sliver, "Swipe for", VoiceOver), which
    /// the deck plays as it plays a drag
    @State private var dealRequest: DealDirection?


    /// Opened scrolled to its end, for a snapshot of the card's foot
    private let opensAtEnd: Bool
    /// A card part way through its deal, for a snapshot
    private let turnedBy: CGFloat

    /// A store, a day, an end to open at, a note already showing and a
    /// card part way through its deal are for the snapshot tests, which
    /// draw a page without walking to it and never touch the reader's own
    /// marks; otherwise the page opens on its card, at rest, today
    init(
        prayerID: String,
        set: PrayerSet? = nil,
        store: PrayerBookStore = .shared,
        date: Date? = nil,
        opensAtEnd: Bool = false,
        showingNote note: String? = nil,
        turnedBy turn: CGFloat = 0
    ) {
        self.prayerID = prayerID
        self.store = store
        self.opensAtEnd = opensAtEnd
        self.turnedBy = turn
        let day = date ?? Date()
        _day = State(initialValue: day)
        let deck = PrayerDeck.of(prayerID, in: set, on: day)
        _deck = State(initialValue: deck)
        _position = State(initialValue: deck.start)
        _saidIn = State(initialValue: PrayerDeck.ordersSaying(deck.ids + [prayerID], on: day))
        _note = State(initialValue: RibbonNote(showing: note))
    }

    private static func prayer(_ id: String) -> BookPrayer? {
        PrayerBook.prayer(id) ?? BookPrayer.bundled(id, origin: nil, note: nil)
    }

    private var currentID: String { position.map { deck.ids[$0] } ?? prayerID }
    private var prayer: BookPrayer? { Self.prayer(currentID) }

    private var previous: Int? {
        guard let position, position > 0 else { return nil }
        return position - 1
    }

    private var next: Int? {
        guard let position, position < deck.ids.count - 1 else { return nil }
        return position + 1
    }

    /// The painting a prayer's card hangs, here and on the topic's rows:
    /// its own scene (`PrayerBookPainting.prayer`) where the book gives it
    /// one, else its topic's
    static func painting(of prayerID: String) -> PrayerBookPainting {
        SavedPrayerPainting.of(prayerID)
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            if let prayer {
                VStack(spacing: 0) {
                    // The drag lives in the deck, so a frame of it redraws
                    // the deck alone, never this page or its cards
                    DealDeck(
                        front: holyCard(prayer, at: position, opensAtEnd: opensAtEnd),
                        previousCard: previous.flatMap(card(at:)),
                        nextCard: next.flatMap(card(at:)),
                        previousEdge: previous.map(edge(at:)),
                        nextEdge: next.map(edge(at:)),
                        frontID: "\(position ?? -1)",
                        request: $dealRequest,
                        turnedBy: turnedBy,
                        settle: settle(_:)
                    )
                    .overlay(alignment: .top) { SavedNote(note: note) }
                    .padding(.top, 6)
                    .padding(.bottom, 8)
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
                // A new card is a new ribbon: dealt from a saved prayer to
                // one not saved, it must not tick as though it were untied
                .id(currentID)
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

    // MARK: - The cards

    /// The card at a place in the deck, for the deck to hold beneath
    private func card(at index: Int) -> HolyCard? {
        Self.prayer(deck.ids[index]).map { holyCard($0, at: index, opensAtEnd: false) }
    }

    /// One prayer's card, drawn from plain values
    private func holyCard(_ prayer: BookPrayer, at index: Int?, opensAtEnd: Bool) -> HolyCard {
        let count = deck.ids.count
        let nextIndex = index.flatMap { $0 < count - 1 ? $0 + 1 : nil }
        let previousIndex = index.flatMap { $0 > 0 ? $0 - 1 : nil }
        let orders = (saidIn[prayer.id] ?? []).compactMap { PrayerBook.order($0) }
        let facts = HolyCardFacts(
            prayerID: prayer.id,
            title: prayer.title,
            secondTitle: prayer.secondTitle,
            content: prayer.content(for: settings.prayerLanguage),
            textSize: max(17, settings.meditationFontSize - 2),
            kicker: deck.name.isEmpty ? nil : index.map { "\(deck.name) · \($0 + 1) OF \(count)" } ?? deck.name,
            saidIn: orders.map { SaidIn(id: $0.id, title: $0.title(on: day)) },
            position: index,
            count: count,
            nextTitle: nextIndex.flatMap { Self.prayer(deck.ids[$0])?.title },
            hasPrevious: previousIndex != nil,
            allLabel: "All \(count), \(deck.doorName)",
            opensAtEnd: opensAtEnd
        )
        let actions = HolyCardActions(
            openOrder: { id in router.push(.prayerOrder(id: id)) },
            learn: { showsLearn = true },
            pray: { router.push(.prayAlong(.prayer(prayer))) },
            hear: { chantID in router.push(.chant(id: chantID)) },
            next: { dealRequest = .next },
            previous: { dealRequest = .previous },
            all: {
                // Opened from its set's own page, Back already goes there
                if let topic = deck.topicToOpen {
                    router.push(.prayerBookChapter(id: topic))
                } else {
                    router.pop()
                }
            }
        )
        return HolyCard(facts: facts, actions: actions, store: store)
    }

    /// The painting of the card before or after this one, for the sliver
    /// at the glass's edge
    private func edge(at index: Int) -> PrayerBookPainting {
        Self.painting(of: deck.ids[index])
    }

    /// The deck has dealt a card: the one it was dealt toward is the page
    private func settle(_ direction: DealDirection) {
        guard let target = direction == .next ? next : previous else { return }
        position = target
        note.clear()
        if let prayer = Self.prayer(deck.ids[target]) {
            AccessibilityNotification.Announcement(prayer.title).post()
        }
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

    private func say(_ words: String) {
        // Heard as well as seen: the words are hidden from VoiceOver
        AccessibilityNotification.Announcement(words).post()
        note.say(words)
    }
}

// MARK: - The ribbon's note

/// What the ribbon says, for three seconds. Observed only by the note
/// drawn on the card, so a Save never redraws the page or its cards.
@Observable
private final class RibbonNote {
    /// Showing now, or nil once its three seconds are up
    private(set) var words: String?
    /// The last thing said, held while its words fade out
    private(set) var lastWords = " "

    @ObservationIgnored private var clearing: Task<Void, Never>?

    init(showing words: String?) {
        self.words = words
        lastWords = words ?? " "
    }

    func say(_ words: String) {
        lastWords = words
        self.words = words
        clearing?.cancel()
        clearing = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.words = nil
        }
    }

    func clear() {
        clearing?.cancel()
        words = nil
    }
}

/// The ribbon's words on a dark capsule at the head of the card
private struct SavedNote: View {
    let note: RibbonNote

    var body: some View {
        Text(note.lastWords)
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
            .opacity(note.words == nil ? 0 : 1)
            .animation(Motion.crossfade, value: note.words)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - The deck

/// Which way a card is dealt: toward the next prayer or the one before
enum DealDirection: Equatable {
    case next, previous

    /// Where a drag that has let go sends the card: the way it went, if it
    /// went a third of the width or was flung on that way, and there is a
    /// card that way; else nowhere, and it comes back to rest
    static func of(
        dx: CGFloat,
        flung: CGFloat,
        width: CGFloat,
        hasNext: Bool,
        hasPrevious: Bool
    ) -> DealDirection? {
        guard dx != 0 else { return nil }
        let direction: DealDirection = dx < 0 ? .next : .previous
        guard direction == .next ? hasNext : hasPrevious else { return nil }
        let farEnough = abs(dx) > width / 3
        // A flick counts only the way the card is going: a drag left and
        // a flick back right is no deal
        let flungOn = flung * dx > 0 && abs(flung) > width * 0.6
        return farEnough || flungOn ? direction : nil
    }
}

/// The card in front, the card it is turning to, and the slivers of the
/// cards before and after at the glass's edges. A drag across turns the
/// page as a pushed page slides in: toward the next prayer, the next card
/// slides in from the right over this one, which steps back a third of
/// the way and dims; toward the one before, this card slides off to the
/// right and the one before comes forward from beneath it. The card in
/// hand follows the finger, and the turn finishes on an ease-out with no
/// lean and no bounce, so the eye can follow where it went. It holds the
/// drag itself, so a frame of the drag redraws this and nothing above it,
/// and its cards are drawn only when their facts change.
private struct DealDeck: View {
    let front: HolyCard
    let previousCard: HolyCard?
    let nextCard: HolyCard?
    let previousEdge: PrayerBookPainting?
    let nextEdge: PrayerBookPainting?
    /// Names the card in front, so a dealt card is a new card, opened at
    /// its top
    let frontID: String
    @Binding var request: DealDirection?
    let turnedBy: CGFloat
    /// Told once a card has gone, with the way it went
    let settle: (DealDirection) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far the turn has gone, in points of the finger's travel:
    /// negative toward the next prayer, positive toward the one before
    @State private var travel: CGFloat
    /// Whether the drag under way was taken as a deal or left to the scroll
    @State private var dragIsAcross: Bool?
    /// True while a finger is on the deck; a drag the system cancels, which
    /// never ends, lets go of it all the same
    @GestureState private var dragging = false
    /// A card on its way out: no drag is taken until it has gone
    @State private var dealing = false
    /// The card's opacity during a turn made under Reduce Motion
    @State private var fade: Double = 1
    /// Counts the cards dealt, for the tick each one gives
    @State private var dealt = 0
    @State private var width: CGFloat = 337

    init(
        front: HolyCard,
        previousCard: HolyCard?,
        nextCard: HolyCard?,
        previousEdge: PrayerBookPainting?,
        nextEdge: PrayerBookPainting?,
        frontID: String,
        request: Binding<DealDirection?>,
        turnedBy: CGFloat,
        settle: @escaping (DealDirection) -> Void
    ) {
        self.front = front
        self.previousCard = previousCard
        self.nextCard = nextCard
        self.previousEdge = previousEdge
        self.nextEdge = nextEdge
        self.frontID = frontID
        self._request = request
        self.turnedBy = turnedBy
        self.settle = settle
        _travel = State(initialValue: turnedBy)
    }

    /// How far a card travels to leave the glass: its width and the
    /// margins either side of it
    private var reach: CGFloat { width + 56 }

    /// How far through a turn the deck is, 0 at rest and 1 turned
    private var progress: CGFloat {
        min(1, abs(travel) / max(reach, 1))
    }

    /// The card the deck is turning to: the next prayer while the drag goes
    /// left, the one before while it goes right
    private var beneath: HolyCard? {
        if travel < 0 { return nextCard }
        if travel > 0 { return previousCard }
        return nil
    }

    /// The card stepped back under the other, a third of the way over and
    /// dimmed, as a page is when another is pushed over it
    private static let stepBack: CGFloat = 0.33
    private static let dimmed: Double = 0.45

    var body: some View {
        let p = progress
        let towardNext = travel < 0
        let turning = beneath != nil && !reduceMotion

        ZStack {
            if let beneath {
                beneath
                    .equatable()
                    // Toward the next: it slides in from the right, over
                    // the card in front. Toward the one before: it waits a
                    // third of the way to the left, dimmed, and comes
                    // forward as the card in front leaves
                    .offset(x: reduceMotion ? 0 : (towardNext ? reach * (1 - p) : -reach * Self.stepBack * (1 - p)))
                    .opacity(reduceMotion ? 0 : (towardNext ? 1 : Self.dimmed + (1 - Self.dimmed) * Double(p)))
                    .zIndex(towardNext ? 1 : 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            front
                .equatable()
                .id(frontID)
                .offset(x: turning ? (towardNext ? -reach * Self.stepBack * p : reach * p) : travel)
                .opacity((turning && towardNext ? 1 - (1 - Self.dimmed) * Double(p) : 1) * fade)
                .zIndex(towardNext ? 0 : 1)
        }
        .padding(.horizontal, 28)
        .onGeometryChange(for: CGFloat.self) { $0.size.width - 56 } action: { width = $0 }
        .overlay(alignment: .leading) { edge(previousEdge, leading: true) }
        .overlay(alignment: .trailing) { edge(nextEdge, leading: false) }
        .sensoryFeedback(.impact(weight: .light), trigger: dealt)
        // The card's own scroll keeps the vertical drag; a drag that
        // starts across turns the card
        .simultaneousGesture(
            DragGesture(minimumDistance: 14)
                .updating($dragging) { _, state, _ in state = true }
                .onChanged { value in
                    // A finger down while a card is turning is let be for
                    // the rest of its drag, or the next card would leap
                    // under it once the turn is done
                    guard !dealing else {
                        dragIsAcross = false
                        return
                    }
                    if dragIsAcross == nil {
                        dragIsAcross = abs(value.translation.width) > abs(value.translation.height)
                    }
                    guard dragIsAcross == true else { return }
                    let dx = value.translation.width
                    // Toward no card, it gives a little and comes back
                    let hasCard = dx < 0 ? nextCard != nil : previousCard != nil
                    travel = hasCard ? dx : dx * 0.25
                }
                .onEnded { value in
                    defer { dragIsAcross = nil }
                    guard dragIsAcross == true, !dealing else { return }
                    if let direction = DealDirection.of(
                        dx: value.translation.width,
                        flung: value.predictedEndTranslation.width,
                        width: width,
                        hasNext: nextCard != nil,
                        hasPrevious: previousCard != nil
                    ) {
                        deal(direction)
                    } else {
                        withAnimation(Motion.settle) { travel = 0 }
                    }
                }
        )
        // A drag the system took away (the scroll, a call, a sheet) never
        // ends; when the finger is gone, the card comes back to rest
        .onChange(of: dragging) { _, isDragging in
            guard !isDragging else { return }
            dragIsAcross = nil
            if !dealing, travel != 0 {
                withAnimation(Motion.settle) { travel = 0 }
            }
        }
        .onChange(of: request) { _, asked in
            guard let asked else { return }
            request = nil
            deal(asked)
        }
    }

    /// The edge of the card before or after this one, peeking in at the
    /// side of the glass: its painting in a sliver, which a touch deals to.
    /// Not a button, and hidden from VoiceOver, which has the card's own
    /// Next prayer and Previous prayer.
    @ViewBuilder
    private func edge(_ painting: PrayerBookPainting?, leading: Bool) -> some View {
        if let painting {
            let shape = UnevenRoundedRectangle(
                topLeadingRadius: leading ? 0 : 12,
                bottomLeadingRadius: leading ? 0 : 12,
                bottomTrailingRadius: leading ? 12 : 0,
                topTrailingRadius: leading ? 12 : 0,
                style: .continuous
            )
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
            // Answers a touch 44 points across, the sliver drawn at 14
            .frame(width: 44, alignment: leading ? .leading : .trailing)
            .contentShape(Rectangle())
            .onTapGesture { deal(leading ? .previous : .next) }
            .accessibilityHidden(true)
            // The edges step back while a card turns, so the card in hand
            // never passes beneath them
            .opacity(travel == 0 ? 1 : 0)
            .animation(Motion.crossfade, value: travel == 0)
        }
    }

    /// Turns to the card before or after: the turn finishes from wherever
    /// the finger left it, on an ease-out, and the card it turned to
    /// becomes the page, opened at its top. Under Reduce Motion the one
    /// card fades into the other.
    private func deal(_ direction: DealDirection) {
        guard !dealing else { return }
        guard (direction == .next ? nextCard : previousCard) != nil else {
            withAnimation(Motion.settle) { travel = 0 }
            return
        }
        dealing = true

        let done = {
            var still = Transaction()
            still.disablesAnimations = true
            withTransaction(still) {
                settle(direction)
                travel = 0
            }
            dealt += 1
            dealing = false
        }

        if reduceMotion {
            withAnimation(.easeIn(duration: 0.14)) {
                fade = 0
                travel = 0
            } completion: {
                done()
                withAnimation(.easeOut(duration: 0.24)) { fade = 1 }
            }
            return
        }

        let turned = (direction == .next ? -1 : 1) * reach
        let turn = {
            withAnimation(Motion.pageTurn) {
                travel = turned
            } completion: {
                done()
            }
        }

        // A turn begun by a tap starts from rest: set the card it turns to
        // in place first and let that be drawn, so it slides in rather
        // than appearing mid-turn
        if travel == 0 {
            var still = Transaction()
            still.disablesAnimations = true
            withTransaction(still) { travel = direction == .next ? -0.5 : 0.5 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(16))
                turn()
            }
        } else {
            turn()
        }
    }
}

// MARK: - The holy card

/// An order the prayer is said in, as the card lists it
private struct SaidIn: Equatable {
    let id: String
    let title: String
}

/// Everything a card shows, as plain values, so a card is redrawn only
/// when one of them changes
private struct HolyCardFacts: Equatable {
    let prayerID: String
    let title: String
    let secondTitle: String?
    let content: String
    let textSize: CGFloat
    let kicker: String?
    let saidIn: [SaidIn]
    let position: Int?
    let count: Int
    let nextTitle: String?
    let hasPrevious: Bool
    let allLabel: String
    let opensAtEnd: Bool
}

/// What a card's doors do
private struct HolyCardActions {
    let openOrder: (String) -> Void
    let learn: () -> Void
    let pray: () -> Void
    let hear: (String) -> Void
    let next: () -> Void
    let previous: () -> Void
    let all: () -> Void
}

/// A prayer as a holy card: its painting in an arch at the head, the set
/// and its place, the name and the Latin, a gold rule, the prayer, the
/// orders it is said in, and its place in the set. A gold rim with a
/// second rule inside it, on the card's own ground. The words scroll
/// inside the card, under its floor, where PRAY stands.
private struct HolyCard: View, Equatable {
    let facts: HolyCardFacts
    let actions: HolyCardActions
    let store: PrayerBookStore

    /// The card's height, which the arch gives way to on a short card
    @State private var height: CGFloat = 0

    private static var corner: CGFloat { 20 }

    static func == (a: HolyCard, b: HolyCard) -> Bool { a.facts == b.facts }

    /// The arch stands 250 points, giving way on a short card (a smaller
    /// phone, the chant player up) so the name and the first lines of the
    /// prayer stand on the first sight of it
    private var archHeight: CGFloat {
        height == 0 ? 250 : min(250, max(170, height * 0.42))
    }

    var body: some View {
        let painting = BookPrayerView.painting(of: facts.prayerID)

        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                        .frame(maxWidth: .infinity)
                        .frame(height: archHeight)
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
                        titles

                        Rectangle()
                            .fill(AppColors.gold.opacity(0.25))
                            .frame(height: AppLine.hairline)
                            .padding(.vertical, 14)

                        PrayerText(
                            content: facts.content,
                            size: facts.textSize,
                            alignment: .leading,
                            showsDropCap: true
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(turnActions)

                        VStack(alignment: .leading, spacing: 22) {
                            saidIn
                            place
                        }
                        .padding(.top, 26)

                        // Room for the last line to scroll clear of the floor
                        Color.clear.frame(height: CardFloor.height).id("end")
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, -22)
                    .padding(.bottom, 12)
                }
            }
            .onAppear {
                if facts.opensAtEnd { proxy.scrollTo("end", anchor: .bottom) }
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
        .overlay(alignment: .bottom) {
            CardFloor(
                prayerID: facts.prayerID,
                store: store,
                learn: actions.learn,
                pray: actions.pray,
                hear: actions.hear
            )
            .equatable()
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
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let kicker = facts.kicker {
                Text(kicker)
                    .font(AppFonts.labelFont(10))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold)
                    .shadow(color: AppColors.cardBackground.opacity(0.9), radius: 6)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(facts.title)
                .font(AppFonts.titleFont(24))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .accessibilityAddTraits(.isHeader)
                .modifier(turnActions)

            if let latin = facts.secondTitle {
                Text(latin)
                    .font(AppFonts.readingItalicFont(14.5))
                    .foregroundColor(AppColors.cream.opacity(0.55))
                    .padding(.top, 3)
            }
        }
    }

    private var turnActions: TurnActions {
        TurnActions(
            onNext: facts.nextTitle == nil ? nil : actions.next,
            onPrevious: facts.hasPrevious ? actions.previous : nil
        )
    }

    /// The orders this prayer is said in, each a door with its painting
    @ViewBuilder
    private var saidIn: some View {
        if !facts.saidIn.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text("SAID IN")
                    .font(AppFonts.labelFont(9))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .accessibilityAddTraits(.isHeader)

                ForEach(facts.saidIn, id: \.id) { order in
                    SaidInRow(orderID: order.id, title: order.title) {
                        actions.openOrder(order.id)
                    }
                }
            }
        }
    }

    /// The set's prayers as a row of dots, this one lit, over "Swipe for
    /// the next · All 32"
    @ViewBuilder
    private var place: some View {
        if let position = facts.position {
            let all = QuietGoldButton(title: "All \(facts.count)", trailingIcon: "ph-caret-right", size: 10) {
                actions.all()
            }
            .accessibilityLabel(facts.allLabel)

            VStack(spacing: 8) {
                PlaceDots(count: facts.count, current: position)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        if let next = facts.nextTitle {
                            swipeFor(next)
                            Text("·")
                                .font(AppFonts.readingItalicFont(13.5))
                                .foregroundColor(AppColors.textSecondary)
                                .accessibilityHidden(true)
                        }
                        all
                    }
                    // On two lines, the dot between them goes, and the two
                    // stand close enough to read as one
                    VStack(spacing: 0) {
                        if let next = facts.nextTitle {
                            swipeFor(next, onTwoLines: true)
                        }
                        all
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// "Swipe for the next", a door to it 44 points tall. On two lines its
    /// words sit at the foot of that height, close over All, and the
    /// height it keeps stands above them, never over All's own.
    private func swipeFor(_ next: String, onTwoLines: Bool = false) -> some View {
        Button(action: actions.next) {
            Text("Swipe for \(next)")
                .font(AppFonts.readingItalicFont(13.5))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44, alignment: onTwoLines ? .bottom : .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("Next prayer, \(next)")
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

// MARK: - The place in the set

/// The set's prayers as dots, the one on the card lit and those before
/// it half lit. A long set shows the 24 around this one.
struct PlaceDots: View {
    let count: Int
    let current: Int

    static let most = 24

    /// The dots drawn: every one in a set of 24 or fewer, else 24 with the
    /// current one near their middle, held inside the set at either end
    static func visibleRange(count: Int, current: Int) -> ClosedRange<Int> {
        guard count > most else { return 0...max(0, count - 1) }
        let first = min(max(0, current - most / 2), count - most)
        return first...(first + most - 1)
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(Self.visibleRange(count: count, current: current)), id: \.self) { i in
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

// MARK: - The card's floor

/// PRAY, the page's one gold act, with Learn by heart and Hear it sung as
/// small rings either side, standing on the card's own floor over a fade
/// of its ground, so the words scroll away beneath them. Redrawn for its
/// prayer and the store's own changes, never for a frame of the turn.
private struct CardFloor: View, Equatable {
    let prayerID: String
    let store: PrayerBookStore
    let learn: () -> Void
    let pray: () -> Void
    let hear: (String) -> Void

    /// The floor's height, fade included, which the card's words keep
    /// room for at their end
    static let height: CGFloat = 92

    static func == (a: CardFloor, b: CardFloor) -> Bool {
        a.prayerID == b.prayerID && a.store === b.store
    }

    var body: some View {
        let learned = store.isByHeart(prayerID)
        // The first setting (a simple tone before a solemn one); the
        // chant's page offers the others
        let chant = ChantCatalog.chants(forPrayer: prayerID).first

        HStack(spacing: 12) {
            FloorAct(icon: learned ? "ph-seal-check-fill" : "ph-heart", action: learn)
                .accessibilityLabel("Learn by heart")
                .accessibilityValue(learned ? "Learned" : "")
                .accessibilityHint("Opens the steps to learn it by heart")

            GoldCTAButton(title: "Pray", prominence: .inline, glyph: .play, action: pray)

            // A prayer with no chant keeps the place empty, so PRAY
            // stands where it stood on the card before
            if let chant {
                FloorAct(icon: "ph-music-note") { hear(chant.id) }
                    .accessibilityLabel("Hear it sung")
                    .accessibilityHint("Opens a sung recording, with its sheet music")
            } else {
                Color.clear.frame(width: FloorAct.size, height: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 34)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                stops: [
                    .init(color: AppColors.cardBackground.opacity(0), location: 0),
                    .init(color: AppColors.cardBackground, location: 0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
    }
}

/// Learn by heart or Hear it sung: a small ringed disc with its glyph,
/// named to VoiceOver
private struct FloorAct: View {
    let icon: String
    let action: () -> Void

    static let size: CGFloat = 44

    var body: some View {
        Button(action: action) {
            AppIcon(icon, size: 17)
                .foregroundColor(AppColors.gold.opacity(0.85))
                .frame(width: Self.size, height: Self.size)
                .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1.2))
                .contentShape(Circle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
    }
}

// MARK: - Said in

/// One order the prayer is said in: its painting, its name, a caret
private struct SaidInRow: View {
    let orderID: String
    let title: String
    let action: () -> Void

    var body: some View {
        let painting = PrayerBook.order(orderID).map { PrayerBookPainting.order($0) } ?? PrayerBookPainting.saved

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


// MARK: - Preview

#Preview {
    NavigationStack {
        BookPrayerView(prayerID: "hail_holy_queen")
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
