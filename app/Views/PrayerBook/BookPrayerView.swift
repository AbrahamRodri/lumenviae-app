//
//  BookPrayerView.swift
//  Lumen Viae
//
//  One prayer of the Prayer Book as a holy card (the "Holy Cards" pick,
//  option B4, Oct 2026): the card stands between the bar and the foot,
//  its painting set in an arch at its head, the set and the prayer's
//  place in it, its name and its Latin, then the prayer, the orders it is
//  said in, and its place among the set's prayers as a row of dots. The
//  prayers before and after it peek in at the edges of the glass. The
//  card's words scroll inside it; a drag across deals the card away, the
//  next one rising from beneath it, as a stack of holy cards is turned.
//  At the foot, Learn by heart and Hear it sung stand either side of
//  PRAY, and one line beneath says how it will be prayed. The language
//  is a small button in the bar, the ribbon beside it.
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
    /// and an order's prayers in their seasons. Fixed for the page's life.
    private let day: Date

    /// The prayers the cards deal through, read once when the page opens
    /// and held, so a season turning while it is open never moves the
    /// place under the reader
    @State private var deck: PrayerDeck

    /// The place in the deck of the card in front; nil for a prayer
    /// outside every set, which has no neighbours
    @State private var position: Int?
    @State private var showsLearn = false
    @State private var keptNote: String?
    /// A deal asked for by a tap (a sliver, "Swipe for", VoiceOver), which
    /// the deck plays as it plays a drag
    @State private var dealRequest: DealDirection?

    /// Clears the note after its three seconds; restarted by each note
    @State private var noteClear: Task<Void, Never>?
    /// The last thing the ribbon said, held while its words fade out
    @State private var lastKeptNote = " "

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
        self.day = day
        let deck = PrayerDeck.of(prayerID, in: set, on: day)
        _deck = State(initialValue: deck)
        _position = State(initialValue: deck.start)
        _keptNote = State(initialValue: note)
        _lastKeptNote = State(initialValue: note ?? " ")
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
                    .overlay(alignment: .top) { savedNote }
                    .padding(.top, 6)

                    PrayerFoot(
                        prayerID: prayer.id,
                        store: store,
                        learn: { showsLearn = true },
                        pray: {
                            // The line beneath PRAY says how it will be prayed,
                            // so it is the reader's answer; the pray-along
                            // screen won't ask
                            store.chooseAloud(store.praysAloud)
                            router.push(.prayAlong(.prayer(prayer)))
                        },
                        hear: { chantID in router.push(.chant(id: chantID)) }
                    )
                    .equatable()
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
        let orders = PrayerBook.orders.filter { $0.prayerIDs(day).contains(prayer.id) }
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
        return HolyCard(facts: facts, actions: actions)
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
        keptNote = nil
        if let prayer = Self.prayer(deck.ids[target]) {
            AccessibilityNotification.Announcement(prayer.title).post()
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

/// The card in front, the card waiting beneath it, and the slivers of the
/// cards before and after at the glass's edges; a drag across deals the
/// card in front away. It holds the drag itself, so a frame of the drag
/// redraws this and nothing above it, and its cards are drawn only when
/// their facts change.
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

    /// How far the card in front has travelled across, in points:
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

    /// How far through a deal the card in front is, 0 at rest and 1 gone
    private var progress: CGFloat {
        min(1, abs(travel) / max(width, 1))
    }

    /// The card waiting beneath the one in front: the next prayer while the
    /// front card goes left, the one before while it goes right
    private var beneath: HolyCard? {
        if travel < 0 { return nextCard }
        if travel > 0 { return previousCard }
        return nil
    }

    var body: some View {
        ZStack {
            if let beneath {
                beneath
                    .equatable()
                    .scaleEffect(reduceMotion ? 1 : 0.94 + 0.06 * progress)
                    .opacity(reduceMotion ? 0 : 0.85 + 0.15 * Double(progress))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            front
                .equatable()
                .id(frontID)
                .offset(x: travel)
                // Leans into the deal, as a card lifted from a stack does
                .rotationEffect(.degrees(reduceMotion ? 0 : Double(travel / max(width, 1)) * 9))
                // Opaque as it goes: the card beneath never reads through it
                .opacity(fade)
        }
        .padding(.horizontal, 28)
        .onGeometryChange(for: CGFloat.self) { $0.size.width - 56 } action: { width = $0 }
        .overlay(alignment: .leading) { edge(previousEdge, leading: true) }
        .overlay(alignment: .trailing) { edge(nextEdge, leading: false) }
        .sensoryFeedback(.impact(weight: .light), trigger: dealt)
        // The card's own scroll keeps the vertical drag; a drag that
        // starts across deals the card
        .simultaneousGesture(
            DragGesture(minimumDistance: 14)
                .updating($dragging) { _, state, _ in state = true }
                .onChanged { value in
                    guard !dealing else { return }
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
            // The edges step back while a card is dealt, so the card in
            // hand never passes beneath them
            .opacity(travel == 0 ? 1 : 0)
            .animation(Motion.crossfade, value: travel == 0)
        }
    }

    /// Deals the card in front away: it flies off, the card beneath it
    /// rises to full and takes its place, opened at its top. Under Reduce
    /// Motion the one card fades into the other.
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

        let away = (direction == .next ? -1 : 1) * width * 1.15
        let flyOff = {
            withAnimation(.easeIn(duration: 0.3)) {
                travel = away
            } completion: {
                done()
            }
        }

        // A turn begun by a tap starts from rest: nudge the card first and
        // let that be drawn, so the card beneath is there at 0.94 to rise
        // as the front one goes
        if travel == 0 {
            var still = Transaction()
            still.disablesAnimations = true
            withTransaction(still) { travel = direction == .next ? -0.5 : 0.5 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(16))
                flyOff()
            }
        } else {
            flyOff()
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
    let next: () -> Void
    let previous: () -> Void
    let all: () -> Void
}

/// A prayer as a holy card: its painting in an arch at the head, the set
/// and its place, the name and the Latin, a gold rule, the prayer, the
/// orders it is said in, and its place in the set. A gold rim with a
/// second rule inside it, on the card's own ground. The words scroll
/// inside the card.
private struct HolyCard: View, Equatable {
    let facts: HolyCardFacts
    let actions: HolyCardActions

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

                        Color.clear.frame(height: 10).id("end")
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
                            swipeFor(next, minHeight: 36)
                        }
                        all
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func swipeFor(_ next: String, minHeight: CGFloat = 44) -> some View {
        Button(action: actions.next) {
            Text("Swipe for \(next)")
                .font(AppFonts.readingItalicFont(13.5))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: minHeight)
                // Drawn close to All on two lines, it still answers a
                // touch 44 points tall
                .contentShape(Rectangle().inset(by: -max(0, 44 - minHeight) / 2))
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

// MARK: - The foot

/// Learn by heart and Hear it sung either side of PRAY, the page's one
/// gold act, and beneath them how it will be prayed. Redrawn for its
/// prayer and the store's own changes, never for a frame of the deal.
private struct PrayerFoot: View, Equatable {
    let prayerID: String
    let store: PrayerBookStore
    let learn: () -> Void
    let pray: () -> Void
    let hear: (String) -> Void

    private var voices = NarrationVoiceCatalog.shared

    init(
        prayerID: String,
        store: PrayerBookStore,
        learn: @escaping () -> Void,
        pray: @escaping () -> Void,
        hear: @escaping (String) -> Void
    ) {
        self.prayerID = prayerID
        self.store = store
        self.learn = learn
        self.pray = pray
        self.hear = hear
    }

    static func == (a: PrayerFoot, b: PrayerFoot) -> Bool {
        a.prayerID == b.prayerID && a.store === b.store
    }

    var body: some View {
        let aloud = store.praysAloud
        let voice = voices.chosenVoice.name.lowercased()
        let learned = store.isByHeart(prayerID)
        // The first setting (a simple tone before a solemn one); the
        // chant's page offers the others
        let chant = ChantCatalog.chants(forPrayer: prayerID).first

        VStack(spacing: 2) {
            HStack(alignment: .top, spacing: 8) {
                FootAct(
                    icon: learned ? "ph-seal-check-fill" : "ph-heart",
                    label: learned ? "Learned" : "Learn by heart",
                    action: learn
                )
                .accessibilityLabel("Learn by heart")
                .accessibilityValue(learned ? "Learned" : "")
                .accessibilityHint("Opens the steps to learn it by heart")

                GoldCTAButton(title: "Pray", glyph: .play, action: pray)

                // A prayer with no chant keeps the place empty, so PRAY
                // stands where it stood on the card before
                if let chant {
                    FootAct(icon: "ph-music-note", label: "Hear it sung") {
                        hear(chant.id)
                    }
                    .accessibilityLabel("Hear it sung")
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
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .accessibilityLabel("Pray aloud")
            .accessibilityAddTraits(.isToggle)
            .accessibilityValue(aloud ? "On, the \(voice) voice" : "Off")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }
}

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
