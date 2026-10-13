//
//  ChantSetPage.swift
//  Lumen Viae
//
//  One sung set on a page of its own, drawn as the library's shelves are
//  (the "simplify the sung set page" design, option A, Oct 2026): its
//  painting run up under the bar and dissolving into the page, the name,
//  one line and "7 chants · 53 min" centred on its foot, one outlined
//  PLAY ALL, and then its chants in the order they are sung, the notes in
//  red over the chants they lead to.
//
//  Every set opens here, whatever it is: an occasion of the library's
//  (`ChantLibraryData.occasions`: A Sung Rosary, Adoration and Blessing,
//  Before Bed...) or a set the reader made. A new occasion needs only its
//  data.
//
//  What is used less stands out of the way. An occasion's bookmark, which
//  keeps it as a set of the reader's own, and the ··· stand in the bar; the
//  ··· holds Pause Between Chants and, for the reader's own set, Share,
//  Rename and Delete. A row's own acts (Play from Here, and in the
//  reader's set Move Up, Move Down and Remove) are on a hold and among its
//  VoiceOver actions. The reader's set ends on two quiet words that add a
//  chant or a pause.
//
//  The page once stacked nine pieces at one weight before the first
//  chant: a side painting under a SUNG SET / YOUR SET kicker, PLAY ALL
//  beside the bookmark or share and ···, a settings row for Pause between
//  chants, and a ··· on every row. The kicker went because the bar's own
//  controls already say which kind of set it is.
//

import SwiftUI

// MARK: - ChantSetSubject

/// Which set a set page shows
enum ChantSetSubject: Hashable {
    /// An occasion of the library's, by its id
    case occasion(String)
    /// A set the reader made, by its id
    case own(UUID)
}

// MARK: - ChantSetPage

struct ChantSetPage: View {

    @Environment(AppRouter.self) private var router
    let subject: ChantSetSubject

    private var player = ChantPlayer.shared
    private var shelf: ChantShelfStore
    /// What sounds, for a snapshot: the player cannot be made to sing in
    /// a test, so a test names the row it would light. Nil reads the player.
    private let drawnSounding: Sounding?

    @State private var scroll = ChantSavedScroll()
    @State private var addingChant: ChantSet?
    @State private var addingPause: ChantSet?
    @State private var renaming: ChantSet?
    @State private var renameText = ""
    @State private var deleting: ChantSet?
    /// A kept set the reader has changed, waiting on their word before
    /// the bookmark lets it go
    @State private var unkeeping: ChantSet?

    /// The row of the set sounding, and whether it is going on
    struct Sounding {
        let origin: Int?
        let goingOn: Bool
    }

    init(subject: ChantSetSubject, shelf: ChantShelfStore = .shared, sounding: Sounding? = nil) {
        self.subject = subject
        self.shelf = shelf
        self.drawnSounding = sounding
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.appGradient.ignoresSafeArea()

            if let content {
                ChantSetPainting(name: content.painting, scroll: scroll)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        head(content)
                            .padding(.top, ChantSetPainting.reach - 62)

                        order(content)
                            .padding(.top, 26)

                        if case .own(let id) = subject, let set = shelf.set(id) {
                            addButtons(set)
                                .padding(.top, 26)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 48)
                }
                .modifier(ChantSavedScrollReading(scroll: scroll))
                .topChromeFade()
                .modifier(ChantSetPlayerRoom())
            } else {
                // A set deleted, or an id no build knows: the page says so
                // rather than stand empty
                Text("This set is no longer here.")
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { ChantBackButton() }
            if content != nil {
                if case .occasion(let id) = subject, let occasion = ChantOccasion.occasion(id) {
                    ToolbarItem(placement: .navigationBarTrailing) { keepButton(occasion) }
                }
                ToolbarItem(placement: .navigationBarTrailing) { moreMenu }
            }
        }
        .sheet(item: $addingChant) { set in
            ChantPickerSheet(set: set)
                .presentationDetents([.large])
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(item: $addingPause) { set in
            ChantPauseSheet(set: set)
                .presentationDetents([.medium, .large])
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .alert(
            "Rename this set",
            isPresented: Binding(
                get: { renaming != nil },
                set: { if !$0 { renaming = nil } }
            )
        ) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let renaming { shelf.rename(renaming.id, to: renameText) }
                renaming = nil
            }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
        .confirmationDialog(
            "Delete \(deleting?.name ?? "this set")?",
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete the Set", role: .destructive) {
                if let deleting { shelf.deleteSet(deleting.id) }
                deleting = nil
                router.pop()
            }
            Button("Cancel", role: .cancel) { deleting = nil }
        } message: {
            Text("Its chants stay in the library; only the set goes.")
        }
    }

    // MARK: - What the page shows

    /// A set as the page lays it out, whichever kind it is
    struct Content {
        let title: String
        let note: String?
        let painting: String
        let chantCount: Int
        let duration: TimeInterval
        let queue: ChantQueue
        let rows: [Row]
    }

    /// One line of the order: a chant, or a note in red between chants
    struct Row: Identifiable {
        enum Kind {
            case chant(Chant, times: Int)
            /// A note in red; `seconds` is the silence it keeps, if any
            case rubric(String, seconds: Int?)
        }

        let id: String
        let kind: Kind
        /// The step of the occasion or the item of the set it stands for,
        /// as the queue numbers them; nil for an occasion's notes, which
        /// are read and never sounded
        let origin: Int?
        /// The reader's own item, for its move and remove
        let itemID: UUID?
    }

    private var content: Content? {
        switch subject {
        case .occasion(let id):
            return ChantOccasion.occasion(id).map { Self.content(of: $0) }
        case .own(let id):
            return shelf.set(id).map { Self.content(of: $0) }
        }
    }

    static func content(of occasion: ChantOccasion) -> Content {
        let numbers = stepNumbers(of: occasion)
        var rows: [Row] = []
        for (blockIndex, block) in occasion.blocks.enumerated() {
            if let rubric = block.rubric {
                rows.append(
                    Row(id: "rubric-\(blockIndex)", kind: .rubric(rubric, seconds: nil), origin: nil, itemID: nil))
            }
            for (stepIndex, step) in block.steps.enumerated() {
                guard let chant = step.chant.resolve() else { continue }
                let number = numbers[blockIndex][stepIndex]
                rows.append(
                    Row(id: "step-\(number)", kind: .chant(chant, times: step.times), origin: number, itemID: nil))
            }
        }
        return Content(
            title: occasion.title,
            note: occasion.note,
            painting: occasion.painting,
            chantCount: occasion.distinctChants().count,
            duration: occasion.duration(),
            queue: ChantQueue.occasion(occasion),
            rows: rows
        )
    }

    static func content(of set: ChantSet) -> Content {
        let rows: [Row] = set.items.enumerated().compactMap { index, item in
            switch item.kind {
            case .chant(let id, let times):
                guard let chant = ChantCatalog.chant(id) else { return nil }
                return Row(id: item.id.uuidString, kind: .chant(chant, times: times), origin: index, itemID: item.id)
            case .pause(let note, let seconds):
                return Row(
                    id: item.id.uuidString,
                    kind: .rubric(note.isEmpty ? "Silence" : note, seconds: seconds),
                    origin: index,
                    itemID: item.id
                )
            }
        }
        return Content(
            title: set.name,
            note: nil,
            painting: set.items.lazy.compactMap(\.chant).first.map { ChantCatalog.painting(for: $0) }
                ?? "glorious_coronation",
            chantCount: set.chantCount,
            duration: set.duration,
            queue: ChantQueue.set(set),
            rows: rows
        )
    }

    /// Each step's number, in the order the occasion writes its steps —
    /// the numbers `ChantQueue.occasion` gives the entries it unrolls
    static func stepNumbers(of occasion: ChantOccasion) -> [[Int]] {
        var number = 0
        return occasion.blocks.map { block in
            block.steps.map { _ in
                defer { number += 1 }
                return number
            }
        }
    }

    // MARK: - What sounds

    private func sounding(_ content: Content) -> Sounding {
        if let drawnSounding { return drawnSounding }
        return Sounding(
            origin: content.queue.source.flatMap { player.origin(singing: $0) },
            goingOn: player.isGoingOn
        )
    }

    // MARK: - The head

    /// The name, its line and its length centred on the painting's foot,
    /// then PLAY ALL while there is a chant to play
    private func head(_ content: Content) -> some View {
        VStack(spacing: 6) {
            Text(content.title)
                .font(AppFonts.titleFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 6) {
                if let note = content.note {
                    Text(note)
                        .font(AppFonts.readingItalicFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(
                    content.chantCount == 0
                        ? "Nothing in it yet"
                        : ChantSetCard.summary(count: content.chantCount, duration: content.duration)
                )
                .font(AppFonts.readingFont(13.5))
                .foregroundColor(AppColors.textSecondary)
                .monospacedDigit()
            }
            .accessibilityElement(children: .combine)

            if content.chantCount > 0 {
                playAll(content)
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
    }

    /// PLAY ALL, outlined: the library's pages keep no filled gold act. It
    /// pauses and takes up the set once the set is under way.
    private func playAll(_ content: Content) -> some View {
        let queue = content.queue
        let singing = drawnSounding.map { $0.origin != nil } ?? player.isSinging(queue)
        let going = singing && sounding(content).goingOn
        let waiting = drawnSounding == nil && player.waitingForNext
        let word =
            !singing
            ? "Play all"
            : waiting
                ? "Play next"
                : going ? "Pause" : "Resume"
        return Button {
            if singing { player.pauseOrResume() } else { player.play(queue) }
        } label: {
            HStack(spacing: 8) {
                AppIcon(going ? "ph-pause-fill" : "ph-play-fill", size: 12)
                Text(word.uppercased())
                    .font(AppFonts.labelFont(11))
                    .tracking(2.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.opacity)
            }
            .foregroundColor(AppColors.gold)
            .padding(.horizontal, 26)
            .frame(minHeight: 46)
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.55), lineWidth: AppLine.hairline))
            .contentShape(Capsule())
        }
        .buttonStyle(SacredCardButtonStyle())
        .animation(Motion.crossfade, value: word)
        .accessibilityLabel(singing ? word : "Play all of \(content.title)")
    }

    // MARK: - The bar

    /// The bookmark: keeps the occasion as a set of the reader's own, and
    /// a second tap lets it go — one kept set for each occasion. A kept set
    /// the reader has changed since is let go only once they say so.
    private func keepButton(_ occasion: ChantOccasion) -> some View {
        let kept = shelf.keptSet(of: occasion) != nil
        return Button {
            if case .askFirst(let set) = shelf.toggleKeeping(occasion) {
                unkeeping = set
            }
        } label: {
            AppIcon(kept ? "ph-bookmark-simple-fill" : "ph-bookmark-simple", size: 18)
                .foregroundColor(AppColors.gold)
                .modifier(ChantSetBarGround())
        }
        .sensoryFeedback(.selection, trigger: kept)
        .accessibilityLabel("Save as your own set")
        .accessibilityValue(kept ? "Saved" : "")
        .accessibilityAddTraits(kept ? [.isSelected] : [])
        // The same question Saved asks before a set is deleted
        .confirmationDialog(
            "Delete \(unkeeping?.name ?? "this set")?",
            isPresented: Binding(get: { unkeeping != nil }, set: { if !$0 { unkeeping = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete the Set", role: .destructive) {
                if let unkeeping { shelf.deleteSet(unkeeping.id) }
                unkeeping = nil
            }
            Button("Cancel", role: .cancel) { unkeeping = nil }
        } message: {
            // True whatever made it differ: the reader's own changes, or a
            // later build's, which this one cannot see
            Text(
                "This set no longer matches the occasion's order. Deleting it removes the set; its chants stay in the library."
            )
        }
    }

    /// What the ··· holds, group by group, in its order: everything about
    /// the set used less, in one place. Saving an occasion is the
    /// bookmark's beside it, never the menu's too.
    enum MoreItem: Equatable {
        case share
        case rename
        case pausesBetween
        case delete

        static func groups(own: Bool, hasItems: Bool) -> [[MoreItem]] {
            guard own else { return [[.pausesBetween]] }
            return [(hasItems ? [.share] : []) + [.rename], [.pausesBetween], [.delete]]
        }
    }

    private var moreMenu: some View {
        let ownSet = ownSet
        let groups = MoreItem.groups(own: ownSet != nil, hasItems: !(ownSet?.items.isEmpty ?? true))
        return Menu {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                Section {
                    ForEach(group, id: \.self) { item in
                        moreButton(item, set: ownSet)
                    }
                }
            }
        } label: {
            AppIcon("ph-dots-three", size: 22)
                .foregroundColor(AppColors.gold)
                .modifier(ChantSetBarGround())
        }
        .accessibilityLabel("More options")
    }

    @ViewBuilder
    private func moreButton(_ item: MoreItem, set: ChantSet?) -> some View {
        switch item {
        case .share:
            if let set {
                ShareLink(item: Self.shareText(set)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        case .rename:
            if let set {
                Button {
                    renameText = set.name
                    renaming = set
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
            }
        case .pausesBetween:
            // The one library-wide switch, with what it does beneath it
            Toggle(isOn: Binding(get: { shelf.pausesBetween }, set: { shelf.pausesBetween = $0 })) {
                Text("Pause Between Chants")
                Text("The next chant waits until you tap")
            }
        case .delete:
            if let set {
                Button(role: .destructive) {
                    deleting = set
                } label: {
                    Label("Delete the Set", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - The order

    private func order(_ content: Content) -> some View {
        let sounding = sounding(content)
        let numbers = Self.chantNumbers(of: content.rows)
        let own = Self.isOwn(subject)
        let items = ownSet?.items ?? []
        return VStack(alignment: .leading, spacing: 0) {
            if content.rows.isEmpty {
                Text(
                    "Add chants in the order you will sing them, and pauses between them for silence or a note in red."
                )
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .padding(.top, -4)
            }
            ForEach(Array(content.rows.enumerated()), id: \.element.id) { position, row in
                let lit = row.origin != nil && row.origin == sounding.origin
                // The reader's rows move among the set's items, as the
                // store counts them
                let place = items.firstIndex { $0.id == row.itemID } ?? position
                let actions = Self.rowActions(
                    for: row, own: own, position: place, count: own ? items.count : content.rows.count)
                switch row.kind {
                case .rubric(let text, let seconds):
                    rubricRow(text, seconds: seconds, lit: lit)
                        .modifier(ChantSetRowActs(actions: actions) { perform($0, row: row, content: content) })
                case .chant(let chant, let times):
                    chantRow(
                        chant, times: times, number: own ? nil : numbers[row.id], lit: lit,
                        goingOn: sounding.goingOn
                    )
                    .modifier(ChantSetRowActs(actions: actions) { perform($0, row: row, content: content) })
                }
            }
        }
    }

    /// A note in red over the chants it leads to; the reader's own pauses
    /// say the silence they keep, or that they are a note alone
    private func rubricRow(_ text: String, seconds: Int?, lit: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            ChantRubricText(text: text, size: 15)
            Spacer(minLength: 8)
            if let seconds {
                Text(seconds > 0 ? ChantPlayer.clock(TimeInterval(seconds)) : "NOTE")
                    .font(AppFonts.labelFont(9))
                    .tracking(1)
                    .foregroundColor(lit ? Rubric.text : AppColors.textSecondary)
                    .monospacedDigit()
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spokenPause(text, seconds: seconds))
    }

    /// A chant in the order: numbered in an occasion, whose chants mostly
    /// share its painting, and hung with its own painting in the reader's
    /// set. A tap opens it.
    private func chantRow(_ chant: Chant, times: Int, number: Int?, lit: Bool, goingOn: Bool) -> some View {
        let duration = chant.duration * Double(max(1, times))
        let spoken = lit
            ? "\(chant.spokenEntry(times: times, duration: duration)), playing now"
            : chant.spokenEntry(times: times, duration: duration)
        return Button {
            router.push(ChantTap.route(to: chant))
        } label: {
            HStack(spacing: 12) {
                if let number {
                    Text("\(number)")
                        .font(AppFonts.titleFont(14))
                        .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                        .monospacedDigit()
                        .frame(width: 24)
                } else {
                    ChantThumbnail(name: ChantCatalog.painting(for: chant), size: 46, radius: 8)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        "\(Text(chant.latinTitle).foregroundColor(lit ? AppColors.goldLight : AppColors.cream))\(Text(times > 1 ? "  ×\(times)" : "").foregroundColor(AppColors.gold))"
                    )
                        .font(AppFonts.readingFont(16.5))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(Motion.crossfade, value: lit)
                    Text(chant.englishTitle)
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if lit && goingOn {
                    ChantSoundingBars()
                } else {
                    Text(ChantPlayer.clock(duration))
                        .font(AppFonts.readingFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                }
            }
            .padding(.vertical, number == nil ? 9 : 11)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.12))
                .frame(height: AppLine.hairline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(number.map { "\($0). \(spoken)" } ?? spoken)
        .accessibilityHint("Opens the chant")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - A row's acts

    /// What a hold on a row offers, and what VoiceOver offers among its
    /// actions: the same acts, in the same order
    enum RowAction: Equatable {
        case playFromHere
        case moveUp
        case moveDown
        case remove

        var title: String {
            switch self {
            case .playFromHere: return "Play from Here"
            case .moveUp:       return "Move Up"
            case .moveDown:     return "Move Down"
            case .remove:       return "Remove"
            }
        }

        var spokenTitle: String {
            switch self {
            case .playFromHere: return "Play from here"
            case .moveUp:       return "Move up"
            case .moveDown:     return "Move down"
            case .remove:       return "Remove"
            }
        }

        var systemImage: String {
            switch self {
            case .playFromHere: return "play"
            case .moveUp:       return "arrow.up"
            case .moveDown:     return "arrow.down"
            case .remove:       return "minus.circle"
            }
        }
    }

    /// A chant can be sung from; in the reader's own set every row can be
    /// moved, but never past either end, and removed. An occasion's notes
    /// have none.
    static func rowActions(for row: Row, own: Bool, position: Int, count: Int) -> [RowAction] {
        var actions: [RowAction] = []
        if case .chant = row.kind, row.origin != nil { actions.append(.playFromHere) }
        if own, row.itemID != nil {
            if position > 0 { actions.append(.moveUp) }
            if position < count - 1 { actions.append(.moveDown) }
            actions.append(.remove)
        }
        return actions
    }

    private func perform(_ action: RowAction, row: Row, content: Content) {
        switch action {
        case .playFromHere:
            guard let origin = row.origin else { return }
            player.play(content.queue, from: content.queue.origins.firstIndex(of: origin) ?? 0)
        case .moveUp, .moveDown, .remove:
            guard case .own(let setID) = subject, let itemID = row.itemID else { return }
            switch action {
            case .moveUp: shelf.moveItem(itemID, by: -1, in: setID)
            case .moveDown: shelf.moveItem(itemID, by: 1, in: setID)
            default: shelf.removeItem(itemID, from: setID)
            }
        }
    }

    /// Each chant row's place among the chant rows, from 1
    static func chantNumbers(of rows: [Row]) -> [String: Int] {
        var numbers: [String: Int] = [:]
        for row in rows {
            if case .chant = row.kind { numbers[row.id] = numbers.count + 1 }
        }
        return numbers
    }

    /// "Silent prayer, 10 minutes of silence", or "Kneel., a note"
    static func spokenPause(_ text: String, seconds: Int?) -> String {
        guard let seconds else { return text }
        return seconds > 0
            ? "\(text), \(ChantPlayer.spoken(TimeInterval(seconds))) of silence"
            : "\(text), a note"
    }

    /// The reader's own set, when the page shows one that is still here
    private var ownSet: ChantSet? {
        guard case .own(let id) = subject else { return nil }
        return shelf.set(id)
    }

    private static func isOwn(_ subject: ChantSetSubject) -> Bool {
        if case .own = subject { return true }
        return false
    }

    // MARK: - Adding

    /// Two quiet words under the reader's own set: a chant in gold, a
    /// pause in the red its notes are set in
    private func addButtons(_ set: ChantSet) -> some View {
        HStack(spacing: 22) {
            addButton("Add a chant", color: AppColors.gold) { addingChant = set }
            addButton("Add a pause", color: Rubric.text) { addingPause = set }
        }
        .frame(maxWidth: .infinity)
    }

    private func addButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                AppIcon("ph-plus", size: 11)
                Text(title.uppercased())
                    .font(AppFonts.labelFont(10.5))
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(color)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(title)
    }

    /// The set as plain words, to send to a prayer group
    static func shareText(_ set: ChantSet) -> String {
        var lines = [set.name, ""]
        var number = 1
        for item in set.items {
            switch item.kind {
            case .chant(let id, let times):
                guard let chant = ChantCatalog.chant(id) else { continue }
                let repeats = times > 1 ? " ×\(times)" : ""
                lines.append(
                    "\(number). \(chant.latinTitle)\(repeats) — \(chant.englishTitle) (\(ChantPlayer.clock(item.duration)))"
                )
                number += 1
            case .pause(let note, let seconds):
                let silence = seconds > 0 ? " (\(ChantPlayer.clock(TimeInterval(seconds))))" : ""
                lines.append("    \(note.isEmpty ? "Silence" : note)\(silence)")
            }
        }
        lines.append("")
        lines.append("Sung by Verbum Gloriae · from Lumen Viae's Chant Library")
        return lines.joined(separator: "\n")
    }
}

// MARK: - A row's acts, on a hold and to VoiceOver

/// The row's acts as its context menu and as its VoiceOver actions; a row
/// with none carries neither
private struct ChantSetRowActs: ViewModifier {
    let actions: [ChantSetPage.RowAction]
    let perform: (ChantSetPage.RowAction) -> Void

    func body(content: Content) -> some View {
        if actions.isEmpty {
            content
        } else {
            content
                .contextMenu {
                    ForEach(actions, id: \.self) { action in
                        Button(role: action == .remove ? .destructive : nil) {
                            perform(action)
                        } label: {
                            Label(action.title, systemImage: action.systemImage)
                        }
                    }
                }
                .accessibilityActions {
                    ForEach(actions, id: \.self) { action in
                        Button(action.spokenTitle) { perform(action) }
                    }
                }
        }
    }
}

// MARK: - The bar's ground

/// A bar control readable over the painting: the system's glass draws its
/// ground from iOS 26; before it, a dark circle with a gold ring
private struct ChantSetBarGround: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        } else {
            content
                .frame(width: 36, height: 36)
                .background(Circle().fill(AppColors.background.opacity(0.55)))
                .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
    }
}

// MARK: - Room for the player

/// Room at the foot of the page for the chant player while it stands
/// there, as the shelves keep it, so the last row is never under it
private struct ChantSetPlayerRoom: ViewModifier {
    @State private var bottomInset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(
                .bottom,
                ChantSavedPage.playerRoom(playerActive: ChantPlayer.shared.isActive, bottomInset: bottomInset)
            )
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { bottomInset = $0 }
    }
}

// MARK: - The set's painting

/// The painting at the head of the set, run up under the bar and the
/// status bar and dissolving into the page beneath the set's name, as a
/// shelf hangs its own. It rises with the page.
private struct ChantSetPainting: View {
    let name: String
    let scroll: ChantSavedScroll

    /// How far the painting reaches below the bar: the name, PLAY ALL and
    /// the first chant still fit on the first screen
    static let reach: CGFloat = 200

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: Self.reach)
            .background(alignment: .bottom) {
                CachedAssetImage(name, focal: ChantBrowseScope.focalPoint(for: name))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .overlay {
                        // A veil under the status bar and the bar's
                        // controls, and under the name where it fades
                        LinearGradient(
                            stops: [
                                .init(color: AppColors.background.opacity(0.7), location: 0),
                                .init(color: AppColors.background.opacity(0.1), location: 0.35),
                                .init(color: AppColors.background.opacity(0.1), location: 0.55),
                                .init(color: AppColors.background.opacity(0.6), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    // Dissolves to clear, so the page's own gradient shows
                    // through beneath it rather than a slab of one colour
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.55),
                                .init(color: .black.opacity(0.35), location: 0.82),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea(edges: .top)
            }
            .offset(y: -scroll.rise)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
