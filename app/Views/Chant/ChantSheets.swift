//
//  ChantSheets.swift
//  Lumen Viae
//
//  The Chant Library's short tasks, each a sheet in the sheet grammar:
//  choosing a chant for a set, adding a pause or a note, putting a chant
//  in a set, the words of the chant sounding, and the sleep timer.
//

import SwiftUI

// MARK: - ChantPickerSheet

/// Chants added to a set, one tap each, until DONE: the book's sections
/// under their paintings, a strip to jump between them, and a search that
/// gives one plain list. Every chant already in the set is marked with how
/// many times it stands there, and the foot counts the set as it grows.
struct ChantPickerSheet: View {
    let set: ChantSet

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    /// The row at the top of the list, which lights its section in the strip
    @State private var topID: String?
    @State private var adds = 0

    private let shelf: ChantShelfStore

    init(set: ChantSet, shelf: ChantShelfStore = .shared) {
        self.set = set
        self.shelf = shelf
    }

    /// The set as it stands now, each chant added included
    private var current: ChantSet { shelf.set(set.id) ?? set }

    private var trimmed: String { query.trimmingCharacters(in: .whitespaces) }

    private var searching: Bool { !trimmed.isEmpty }

    /// The section the list stands in, read off the row at its top
    private var litGroupID: String? {
        guard let topID else { return ChantCatalog.groups.first?.id }
        // "g:<group>" a band, "h:<group>:<part>" a subheading, "c:<chant>" a row
        let parts = topID.split(separator: ":", maxSplits: 2).map(String.init)
        guard parts.count >= 2 else { return ChantCatalog.groups.first?.id }
        switch parts[0] {
        case "g", "h": return parts[1]
        default: return ChantCatalog.chant(parts[1])?.groupID
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(kicker: "Add chants to", title: current.name)

            searchField

            ZStack {
                if searching {
                    results
                        .transition(.opacity)
                } else {
                    VStack(spacing: 0) {
                        strip
                        sections
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .animation(Motion.crossfade, value: searching)

            tally
        }
        .sheetGround()
        .sensoryFeedback(.selection, trigger: adds)
    }

    // MARK: Search

    private var searchField: some View {
        HStack(spacing: 10) {
            AppIcon("ph-magnifying-glass", size: 15)
                .foregroundColor(AppColors.gold)
                .accessibilityHidden(true)
            TextField(
                "",
                text: $query,
                prompt: Text("Search \(ChantCatalog.all.count) chants").foregroundColor(AppColors.textSecondary)
            )
            .font(AppFonts.readingFont(17))
            .foregroundColor(AppColors.cream)
            .tint(AppColors.gold)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
            .accessibilityLabel("Search the chants")

            if searching {
                Button {
                    query = ""
                } label: {
                    AppIcon("ph-x", size: 13)
                        .foregroundColor(AppColors.gold.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("Clear the search")
            }
        }
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.32) }
        .padding(.horizontal, SheetMetrics.gutter)
    }

    // MARK: The book's sections

    /// The sections by their short names; a tap scrolls the list to one,
    /// and the one the list stands in is lit
    private var strip: some View {
        ScrollViewReader { proxy in
            ChantSideScroll {
                HStack(spacing: 20) {
                    ForEach(ChantCatalog.groups) { group in
                        let lit = group.id == litGroupID
                        Button {
                            withAnimation(Motion.travel(0.45)) { topID = "g:\(group.id)" }
                        } label: {
                            Text(group.shortTitle.uppercased())
                                .font(AppFonts.labelFont(10))
                                .tracking(1.8)
                                .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                                .padding(.vertical, 8)
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(AppColors.gold)
                                        .frame(height: AppLine.hairline)
                                        .opacity(lit ? 1 : 0)
                                }
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(QuietGlyphButtonStyle())
                        .id(group.id)
                        .accessibilityLabel(group.title)
                        .accessibilityAddTraits(lit ? [.isSelected] : [])
                    }
                }
                .padding(.horizontal, SheetMetrics.gutter)
            }
            .animation(Motion.crossfade, value: litGroupID)
            .onChange(of: litGroupID) { _, id in
                guard let id else { return }
                withAnimation(Motion.crossfade) { proxy.scrollTo(id, anchor: .center) }
            }
        }
        .padding(.top, 4)
    }

    private var sections: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(ChantCatalog.groups) { group in
                    ChantSectionBand(group: group)
                        .id("g:\(group.id)")
                    ForEach(Array(group.parts.enumerated()), id: \.offset) { index, part in
                        if let title = part.title {
                            ChantPartHeading(title: title)
                                .padding(.horizontal, SheetMetrics.gutter)
                                .padding(.top, 14)
                                .padding(.bottom, 2)
                                .id("h:\(group.id):\(index)")
                        }
                        ForEach(ChantCatalog.chants(in: part)) { chant in
                            row(chant)
                                .id("c:\(chant.id)")
                        }
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.bottom, 12)
        }
        .scrollPosition(id: $topID, anchor: .top)
        .scrollDismissesKeyboard(.immediately)
    }

    private var results: some View {
        let found = ChantCatalog.search(trimmed)
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(found) { chant in
                    row(chant)
                }
                if found.isEmpty {
                    Text("No chant matches \u{201C}\(trimmed)\u{201D}.")
                        .font(AppFonts.readingItalicFont(15))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, SheetMetrics.gutter)
                        .padding(.top, 20)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 12)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func row(_ chant: Chant) -> some View {
        ChantAddRow(chant: chant, count: current.count(of: chant.id)) {
            shelf.addChant(chant.id, to: set.id)
            adds += 1
        }
    }

    // MARK: The foot

    private var tally: some View {
        HStack(spacing: 12) {
            Text(current.tally)
                .font(AppFonts.readingFont(15.5))
                .foregroundColor(AppColors.cream)
                .contentTransition(.numericText())
                .animation(Motion.crossfade, value: current.tally)

            Spacer(minLength: 8)

            Button {
                dismiss()
            } label: {
                Text("DONE")
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .accessibilityLabel("Done")
        }
        .padding(.horizontal, SheetMetrics.gutter)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .overlay(alignment: .top) { ChantRule(opacity: 0.14) }
    }
}

// MARK: - ChantPauseSheet

/// A note between chants, in red, and as long a silence as the reader
/// wants kept there: "Silent prayer · 10 minutes", "Pray for my
/// intentions". The pause is shown beneath as it will read in the set,
/// after its last chant.
struct ChantPauseSheet: View {
    let set: ChantSet

    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @State private var minutes = 0

    private let shelf: ChantShelfStore

    private static let lengths = [0, 1, 2, 5, 10, 15]

    /// What an empty note is saved as when the pause keeps a silence
    private static let silentPrayer = "Silent prayer"

    init(set: ChantSet, shelf: ChantShelfStore = .shared) {
        self.set = set
        self.shelf = shelf
    }

    private var words: String { note.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canAdd: Bool { !words.isEmpty || minutes > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "A pause") {
                SheetHeaderAction(title: "Cancel") { dismiss() }
            }

            TextField("", text: $note, prompt: Text(Self.silentPrayer).foregroundColor(Rubric.text.opacity(0.45)))
                .font(AppFonts.readingItalicFont(22))
                .foregroundColor(Rubric.text)
                .tint(Rubric.text)
                .submitLabel(.done)
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) { ChantRule(opacity: 0.32) }
                .padding(.horizontal, SheetMetrics.gutter)
                .accessibilityLabel("The note, read in red between chants")

            silence
                .padding(.top, 22)

            // Only after a chant: in an empty set the preview would only
            // say the red line above it again
            if let last = lastChant {
                preview(after: last)
                    .padding(.top, 18)
                    .padding(.horizontal, SheetMetrics.gutter)
            }

            Spacer(minLength: 12)

            ZStack {
                if canAdd {
                    GoldCTAButton(title: "Add the pause", trailingIcon: "ph-check", action: add)
                        .transition(.opacity)
                } else {
                    waitingAct
                        .transition(.opacity)
                }
            }
            .animation(Motion.crossfade, value: canAdd)
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.bottom, 20)
        }
        .sheetGround()
        .sensoryFeedback(.selection, trigger: minutes)
    }

    /// The lengths as beads on one ruled line, the chosen one lit
    private var silence: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(Self.lengths, id: \.self) { length in
                    let lit = length == minutes
                    Button {
                        minutes = length
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(lit ? AppColors.gold : AppColors.background)
                                    .frame(width: lit ? 15 : 9, height: lit ? 15 : 9)
                                    .overlay(
                                        Circle().strokeBorder(
                                            lit ? AppColors.goldLight : AppColors.gold.opacity(0.32),
                                            lineWidth: AppLine.hairline
                                        )
                                    )
                                    .shadow(color: AppColors.gold.opacity(lit ? 0.55 : 0), radius: 6)
                            }
                            .frame(height: 16)
                            Text(length == 0 ? "None" : "\(length)")
                                .font(AppFonts.readingFont(length == 0 ? 15 : 19))
                                .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel(length == 0 ? "No silence" : length == 1 ? "1 minute of silence" : "\(length) minutes of silence")
                    .accessibilityAddTraits(lit ? [.isSelected] : [])
                }
            }
            .background(alignment: .top) {
                // The line the beads are strung on, through their middles
                ChantRule(opacity: 0.32)
                    .padding(.horizontal, 30)
                    .padding(.top, 8)
            }
            .animation(Motion.settle, value: minutes)

            Text("MINUTES OF SILENCE")
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, SheetMetrics.gutter - 8)
    }

    private func add() {
        shelf.addPause(
            note: words.isEmpty ? (minutes > 0 ? Self.silentPrayer : "") : words,
            seconds: minutes * 60,
            to: set.id
        )
        dismiss()
    }

    /// The act while there is no pause to add yet: a hairline capsule with
    /// its words dimmed, so it reads as waiting rather than as the gold
    /// pill washed out. Drawn here, not as the shared button's outline,
    /// whose rim drew stray hairlines past its rounded ends.
    private var waitingAct: some View {
        // The gold button, hidden, sets the size, so the act keeps its
        // edges when it turns gold
        GoldCTAButton(title: "Add the pause", trailingIcon: "ph-check", action: add)
            .hidden()
            .overlay {
                Button(action: add) {
                    HStack(spacing: 10) {
                        Text("ADD THE PAUSE")
                            .font(AppFonts.labelFont(13))
                            .tracking(2.5)
                        AppIcon("ph-check", size: 11)
                    }
                    .foregroundColor(AppColors.gold.opacity(0.45))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        // A radius past half the height rounds the ends
                        // whole, as the capsule's would
                        RoundedRectangle(cornerRadius: 100, style: .circular)
                            .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 100, style: .circular))
                }
                .buttonStyle(.plain)
                .disabled(true)
                .accessibilityLabel("Add the pause")
                .accessibilityHint("Write a note or choose a silence first")
            }
    }

    /// The set's last chant, which the pause will follow
    private var lastChant: Chant? {
        (shelf.set(set.id) ?? set).items.last(where: { $0.chant != nil })?.chant
    }

    /// The pause as it will stand in the set: under the set's last chant,
    /// dimmed, the note in red with its silence beside it
    private func preview(after last: Chant) -> some View {
        let shown = words.isEmpty ? Self.silentPrayer : words
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ChantThumbnail(name: ChantCatalog.painting(for: last), size: 28, radius: 6)
                Text(last.englishTitle)
                    .font(AppFonts.readingFont(15))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
            }
            .opacity(0.55)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(shown)
                    .font(AppFonts.readingItalicFont(17))
                    .foregroundColor(Rubric.text)
                    .lineLimit(2)
                if minutes > 0 {
                    Text("· \(minutes) MIN")
                        .font(AppFonts.labelFont(9))
                        .tracking(1.4)
                        .foregroundColor(Rubric.text)
                        .monospacedDigit()
                }
            }
            .opacity(canAdd ? 1 : 0.45)
            .padding(.leading, 4)
            .animation(Motion.crossfade, value: minutes)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.14), lineWidth: AppLine.hairline)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            canAdd
                ? "In the set it reads: \(shown)"
                    + (minutes > 0 ? ", then \(minutes == 1 ? "a minute" : "\(minutes) minutes") of silence" : "")
                : "Write a note or choose a silence to add a pause"
        )
    }
}

// MARK: - ChantAddToSetSheet

/// One chant put in a set of the reader's own, or in a new one. Each set
/// wears its painting, and one that holds the chant already says how many
/// times; a tap adds it again, as it always has.
struct ChantAddToSetSheet: View {
    let chant: Chant

    @Environment(\.dismiss) private var dismiss

    private let shelf: ChantShelfStore

    init(chant: Chant, shelf: ChantShelfStore = .shared) {
        self.chant = chant
        self.shelf = shelf
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(shelf.sets) { set in
                        ChantSetRow(set: set, count: set.count(of: chant.id)) {
                            shelf.addChant(chant.id, to: set.id)
                            dismiss()
                        }
                    }
                    newSet
                }
            }
        }
        .sheetGround()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ChantThumbnail(name: ChantCatalog.painting(for: chant), size: 44, radius: 8)

            VStack(alignment: .leading, spacing: 6) {
                Text(chant.englishTitle.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)
                    .lineLimit(1)
                Text("Add to a set")
                    .font(AppFonts.headlineFont(22))
                    .foregroundColor(AppColors.cream)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            SheetHeaderAction(title: "Cancel") { dismiss() }
        }
        .padding(.horizontal, SheetMetrics.gutter)
        .padding(.top, SheetMetrics.headerTop)
        .padding(.bottom, SheetMetrics.headerBottom)
    }

    private var newSet: some View {
        Button {
            shelf.newSet(with: chant.id)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(AppColors.gold.opacity(0.4), style: StrokeStyle(lineWidth: AppLine.hairline, dash: [3, 3]))
                    .frame(width: 44, height: 44)
                    .overlay(
                        AppIcon("ph-plus", size: 14)
                            .foregroundColor(AppColors.gold)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("A new set")
                        .font(AppFonts.readingFont(16.5))
                        .foregroundColor(AppColors.cream)
                    Text("Begun with this chant")
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("A new set, begun with \(chant.spokenName)")
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ChantNewSetSheet

/// A set of the reader's own, named before it is made: it stands on the
/// shelf only once it is made, so backing out leaves no empty spine. The
/// painting an empty set wears hangs at the head, over the name.
struct ChantNewSetSheet: View {
    let made: (ChantSet) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var focused: Bool

    private let shelf: ChantShelfStore

    init(shelf: ChantShelfStore = .shared, made: @escaping (ChantSet) -> Void) {
        self.shelf = shelf
        self.made = made
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                ChantHeadPainting(name: ChantSet.emptyPainting)
                    .opacity(0.9)

                SheetHeaderAction(title: "Cancel") { dismiss() }
                    .shadow(color: .black.opacity(0.7), radius: 6)
                    .padding(.top, SheetMetrics.headerTop)
                    .padding(.trailing, SheetMetrics.gutter)
            }

            Text("A new set")
                .font(AppFonts.headlineFont(22))
                .foregroundColor(AppColors.cream)
                .shadow(color: .black.opacity(0.6), radius: 6)
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.top, -30)
                .accessibilityAddTraits(.isHeader)

            TextField("", text: $name, prompt: Text(shelf.nextSetName).foregroundColor(AppColors.textSecondary))
                .font(AppFonts.readingFont(26))
                .foregroundColor(AppColors.cream)
                .tint(AppColors.gold)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(make)
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) { ChantRule(opacity: 0.32) }
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.top, 18)
                .accessibilityLabel("The set's name")
                .accessibilityHint("Left empty, it is called \(shelf.nextSetName)")

            Spacer(minLength: 12)

            GoldCTAButton(title: "Make the set", trailingIcon: "ph-check", action: make)
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.bottom, 20)
        }
        .sheetGround()
        .onAppear { focused = true }
    }

    private func make() {
        let set = shelf.newSet(named: name)
        dismiss()
        made(set)
    }
}

// MARK: - ChantWordsSheet

/// The words the chant sings, Latin over English as the reader chose:
/// its own lines when they have been timed, each a door to that line;
/// else the Prayer Book's text of the prayer it sings.
struct ChantWordsSheet: View {
    let chant: Chant

    @Environment(\.dismiss) private var dismiss

    private let player = ChantPlayer.shared
    private let shelf = ChantShelfStore.shared

    init(chant: Chant) {
        self.chant = chant
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(kicker: chant.englishTitle, title: "The words") {
                SheetHeaderAction(title: "Done") { dismiss() }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if chant.hasLines {
                        ForEach(Array(chant.lines.enumerated()), id: \.offset) { index, line in
                            lineRow(line, index: index)
                        }
                    } else if let prayer = chant.bookPrayer {
                        PrayerText(content: prayer.content(for: language(for: prayer)), size: 17)
                            .padding(.horizontal, SheetMetrics.gutter)
                            .padding(.vertical, 8)
                        SheetNote("The words as they appear in Prayers. The chant may add a short verse and response, or a closing prayer.")
                    } else {
                        SheetNote("The words of this chant aren't written out here yet. You can read them on its sheet music.")
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .sheetGround()
    }

    private func language(for prayer: BookPrayer) -> PrayerLanguage {
        switch shelf.words {
        case .both:    return .both
        case .latin:   return prayer.hasLatin ? .latin : .english
        case .english: return .english
        }
    }

    private func lineRow(_ line: ChantLine, index: Int) -> some View {
        let here = player.holds(chant) && player.lineIndex == index
        return Button {
            if player.holds(chant) {
                player.seek(toLine: index)
            } else {
                player.playLine(index, of: chant, then: .goOn)
            }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                if shelf.words.showsLatin {
                    Text(line.latin)
                        .font(AppFonts.readingFont(18))
                        .foregroundColor(here ? AppColors.goldLight : AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if shelf.words.showsEnglish {
                    Text(line.english)
                        .font(AppFonts.readingItalicFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.vertical, 10)
            .background(here ? AppColors.gold.opacity(0.07) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Plays from this line")
    }
}

// MARK: - ChantSleepSheet

/// The library falls silent after a while, for chant sung to sleep by
struct ChantSleepSheet: View {

    @Environment(\.dismiss) private var dismiss

    private let player = ChantPlayer.shared

    private static let choices = [5, 10, 15, 30, 45, 60]

    init() {}

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(kicker: "The Chant Library", title: "Sleep timer", lead: lead) {
                SheetHeaderAction(title: "Done") { dismiss() }
            }
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Self.choices, id: \.self) { minutes in
                        Button {
                            player.sleep(afterMinutes: minutes)
                            dismiss()
                        } label: {
                            SheetRow("In \(minutes) minutes", icon: "ph-moon-stars", accessory: .none)
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        player.sleepAtEndOfChant()
                        dismiss()
                    } label: {
                        SheetRow(
                            "When this chant ends",
                            icon: "ph-music-note",
                            accessory: player.sleepsAtEndOfChant ? .check : .none,
                            isLit: player.sleepsAtEndOfChant
                        )
                    }
                    .buttonStyle(.plain)
                    if player.hasSleepTimer {
                        Button {
                            player.cancelSleep()
                            dismiss()
                        } label: {
                            SheetRow("Turn off the timer", icon: "ph-x", accessory: .none, showsDivider: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheetGround()
    }

    private var lead: String? {
        if let ends = player.sleepEndsAt {
            return "Falls silent at \(ends.formatted(date: .omitted, time: .shortened))."
        }
        if player.sleepsAtEndOfChant {
            return "Falls silent when this chant ends."
        }
        return nil
    }
}
