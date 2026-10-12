//
//  ChantSetPage.swift
//  Lumen Viae
//
//  One sung set on a page of its own, laid out as an album is: its
//  painting beside its name, a line saying what it is, how many chants
//  and how long, PLAY ALL, and then its chants in the order they are
//  sung, the notes in red between them saying what happens in between
//  (the "Chant Library shelves" design, option B, Oct 2026).
//
//  Every set opens here, whatever it is: an occasion of the library's
//  (`ChantLibraryData.occasions`: A Sung Rosary, Adoration and Blessing,
//  Before Bed...) or a set the reader made. A new occasion needs only its
//  data. A set once opened as an order of service beneath an index of
//  every other set, so the set asked for stood below the fold.
//
//  An occasion carries the bookmark that keeps it as a set of the
//  reader's own; a set of the reader's own is changed here: its chants and
//  pauses moved and removed from each row's menu, added beneath them,
//  renamed, shared as words and deleted.
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
    private var shelf = ChantShelfStore.shared

    @State private var addingChant: ChantSet?
    @State private var addingPause: ChantSet?
    @State private var renaming: ChantSet?
    @State private var renameText = ""
    @State private var deleting: ChantSet?
    /// A kept set the reader has changed, waiting on their word before
    /// the bookmark lets it go
    @State private var unkeeping: ChantSet?

    init(subject: ChantSetSubject) {
        self.subject = subject
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            if let content {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header(content)
                        actions(content)
                        ChantPausesBetweenRow()
                        order(content)
                        if case .own(let id) = subject, let set = shelf.set(id) {
                            HStack(spacing: 10) {
                                addButton("Add a chant", color: AppColors.gold) { addingChant = set }
                                addButton("Add a pause", color: Rubric.text) { addingPause = set }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
                .topChromeFade()
            } else {
                // A set deleted, or an id no build knows: the page says so
                // rather than stand empty
                Text("This set is no longer here.")
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { ChantBackButton() }
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
        let kicker: String
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
            kicker: "Sung set",
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
            kicker: "Your set",
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

    // MARK: - Header

    private func header(_ content: Content) -> some View {
        HStack(alignment: .bottom, spacing: 16) {
            ChantThumbnail(name: content.painting, size: 136, radius: 14)

            VStack(alignment: .leading, spacing: 5) {
                Text(content.kicker.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold)
                Text(content.title)
                    .font(AppFonts.titleFont(22))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let note = content.note {
                    Text(note)
                        .font(AppFonts.readingItalicFont(14.5))
                        .foregroundColor(AppColors.cream.opacity(0.78))
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Play, and the set's own acts

    private func actions(_ content: Content) -> some View {
        HStack(spacing: 12) {
            playAll(content)
            switch subject {
            case .occasion(let id):
                if let occasion = ChantOccasion.occasion(id) { keepButton(occasion) }
            case .own(let id):
                if let set = shelf.set(id) { ownSetActs(set) }
            }
        }
    }

    /// PLAY ALL, outlined: the library's pages keep no filled gold act. It
    /// pauses and takes up the set once the set is under way.
    private func playAll(_ content: Content) -> some View {
        let queue = content.queue
        let singing = player.isSinging(queue)
        let going = singing && player.isGoingOn
        let word =
            !singing
            ? "Play all"
            : player.waitingForNext
                ? "Play next"
                : going ? "Pause" : "Resume"
        return Button {
            if singing { player.pauseOrResume() } else { player.play(queue) }
        } label: {
            HStack(spacing: 8) {
                AppIcon(going ? "ph-pause-fill" : "ph-play-fill", size: 13)
                Text(word.uppercased())
                    .font(AppFonts.labelFont(11))
                    .tracking(2.2)
                    .contentTransition(.opacity)
            }
            .foregroundColor(AppColors.gold)
            .frame(maxWidth: .infinity, minHeight: 48)
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.55), lineWidth: AppLine.hairline))
            .contentShape(Capsule())
        }
        .buttonStyle(SacredCardButtonStyle())
        .animation(Motion.crossfade, value: word)
        .disabled(content.chantCount == 0)
        .opacity(content.chantCount == 0 ? 0.4 : 1)
        .accessibilityLabel(singing ? word : "Play all of \(content.title)")
    }

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
                .frame(width: 48, height: 48)
                .overlay(Circle().strokeBorder(AppColors.gold.opacity(kept ? 0.7 : 0.35), lineWidth: AppLine.hairline))
                .contentShape(Circle())
        }
        .buttonStyle(SacredCardButtonStyle())
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

    private func ownSetActs(_ set: ChantSet) -> some View {
        HStack(spacing: 8) {
            if !set.items.isEmpty {
                ShareLink(item: Self.shareText(set)) {
                    chip("ph-export")
                }
                .accessibilityLabel("Share this set")
            }
            Menu {
                Button {
                    renameText = set.name
                    renaming = set
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    deleting = set
                } label: {
                    Label("Delete the Set", systemImage: "trash")
                }
            } label: {
                chip("ph-dots-three")
            }
            .accessibilityLabel("More for this set")
        }
    }

    private func chip(_ icon: String) -> some View {
        AppIcon(icon, size: 18)
            .foregroundColor(AppColors.gold)
            .frame(width: 48, height: 48)
            .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline))
            .contentShape(Circle())
    }

    // MARK: - The order

    private func order(_ content: Content) -> some View {
        let sounding = content.queue.source.flatMap { player.origin(singing: $0) }
        return VStack(alignment: .leading, spacing: 0) {
            if content.rows.isEmpty {
                Text(
                    "Add chants in the order you will sing them, and pauses between them for silence or a note in red."
                )
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(content.rows.enumerated()), id: \.element.id) { position, row in
                switch row.kind {
                case .rubric(let text, let seconds):
                    rubricRow(
                        text, seconds: seconds, lit: row.origin != nil && row.origin == sounding, row: row,
                        position: position, content: content)
                case .chant(let chant, let times):
                    chantRow(
                        chant, times: times, lit: row.origin == sounding, row: row, position: position, content: content
                    )
                }
            }
        }
    }

    private func rubricRow(_ text: String, seconds: Int?, lit: Bool, row: Row, position: Int, content: Content)
        -> some View
    {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            ChantRubricText(text: text, size: 15)
            Spacer(minLength: 8)
            if let seconds {
                // A note kept with no silence says so in a word
                Text(seconds > 0 ? ChantPlayer.clock(TimeInterval(seconds)) : "NOTE")
                    .font(AppFonts.labelFont(9))
                    .tracking(1)
                    .foregroundColor(lit ? Rubric.text : AppColors.textSecondary)
                    .monospacedDigit()
            }
            if row.itemID != nil {
                rowMenu(row: row, position: position, content: content, chant: nil)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 6)
        .accessibilityElement(children: .combine)
    }

    private func chantRow(_ chant: Chant, times: Int, lit: Bool, row: Row, position: Int, content: Content) -> some View
    {
        let duration = chant.duration * Double(max(1, times))
        return HStack(spacing: 12) {
            Button {
                router.push(ChantTap.route(to: chant))
            } label: {
                HStack(spacing: 12) {
                    ChantThumbnail(name: ChantCatalog.painting(for: chant), size: 44, radius: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(times > 1 ? "\(chant.latinTitle) ×\(times)" : chant.latinTitle)
                            .font(AppFonts.readingFont(16.5))
                            .foregroundColor(lit ? AppColors.goldLight : AppColors.cream)
                            .lineLimit(2)
                        Text(chant.englishTitle)
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    if lit && player.isGoingOn {
                        ChantSoundingBars()
                    } else {
                        Text(ChantPlayer.clock(duration))
                            .font(AppFonts.readingFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .monospacedDigit()
                    }
                }
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                lit
                    ? "\(chant.spokenEntry(times: times, duration: duration)), playing now"
                    : chant.spokenEntry(times: times, duration: duration)
            )
            .accessibilityHint("Opens the chant")
            .accessibilityAddTraits(.isButton)

            rowMenu(row: row, position: position, content: content, chant: chant)
        }
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
    }

    /// ··· on a row: sing the set from here, and for the reader's own set,
    /// move or remove the row
    private func rowMenu(row: Row, position: Int, content: Content, chant: Chant?) -> some View {
        Menu {
            if let chant, let origin = row.origin {
                Button {
                    player.play(content.queue, from: content.queue.origins.firstIndex(of: origin) ?? 0)
                } label: {
                    Label("Play from Here", systemImage: "play")
                }
                .accessibilityLabel("Play from \(chant.spokenName)")
            }
            if case .own(let setID) = subject, let itemID = row.itemID, let set = shelf.set(setID) {
                let index = set.items.firstIndex { $0.id == itemID } ?? 0
                Button {
                    shelf.moveItem(itemID, by: -1, in: setID)
                } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }
                .disabled(index == 0)
                Button {
                    shelf.moveItem(itemID, by: 1, in: setID)
                } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }
                .disabled(index == set.items.count - 1)
                Button(role: .destructive) {
                    shelf.removeItem(itemID, from: setID)
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }
            }
        } label: {
            AppIcon("ph-dots-three", size: 18)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 36, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(chant.map { "More for \($0.latinTitle)" } ?? "Move or remove")
    }

    private func addButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                AppIcon("ph-plus", size: 12)
                Text(title)
                    .font(AppFonts.readingFont(15))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity, minHeight: 44)
            .overlay(Capsule().strokeBorder(color.opacity(0.5), lineWidth: AppLine.hairline))
            .contentShape(Capsule())
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

// MARK: - ChantPausesBetweenRow

/// Pause between chants, for every set. The whole row is the switch, as
/// Settings' rows are: the switch is drawn but takes no touch of its own,
/// or a tap on it would reach both and flip the setting twice.
struct ChantPausesBetweenRow: View {
    private var shelf = ChantShelfStore.shared

    var body: some View {
        Button {
            withAnimation(Motion.settle) { shelf.pausesBetween.toggle() }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pause between chants")
                        .font(AppFonts.readingFont(16))
                        .foregroundColor(AppColors.cream)
                    Text("The next chant waits until you tap")
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer(minLength: 8)
                Toggle("Pause between chants", isOn: .constant(shelf.pausesBetween))
                    .labelsHidden()
                    .tint(AppColors.gold)
                    .allowsHitTesting(false)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pause between chants")
        .accessibilityValue(shelf.pausesBetween ? "On" : "Off")
        .accessibilityHint("The next chant waits until you tap")
        .accessibilityAddTraits(.isButton)
    }
}
