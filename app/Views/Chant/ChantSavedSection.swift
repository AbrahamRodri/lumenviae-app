//
//  ChantSavedSection.swift
//  Lumen Viae
//
//  The Saved board: what the reader has made of the library. A shelf of
//  spines — chants learned, favourites, and every set they have put
//  together, with a place for a new one — and beneath it the spine
//  chosen: a list, or a set laid out as an order of its own, its chants
//  and its pauses moved, removed and added to, and sung as one. Then what
//  was sung lately, and the library's one setting, the words.
//
//  Everything here is kept on the device (`ChantShelfStore`).
//

import SwiftUI

// MARK: - ChantSpineCloth

/// The spines on the Saved shelf, dyed from colours the app already
/// names: chants learned in the rubric's red, favourites in Marian blue,
/// and the reader's own sets in the vestments' green, violet, black and
/// rose, in turn — each laid thin on the dark page so it reads as cloth
enum ChantSpineCloth {
    static var learned: Color { Rubric.red.opacity(0.5) }
    static var favorites: Color { AppColors.marianBlue }
    static var sets: [Color] {
        [MissalVestment.green, .violet, .black, .rose].map { $0.swatch.opacity(0.55) }
    }
}

// MARK: - ChantSavedSection

struct ChantSavedSection: View {

    @Binding var openSetID: UUID?
    let open: (Chant) -> Void

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    private enum Spine: Hashable {
        case learned
        case favorites
        case set(UUID)
    }

    @State private var spineChoice: Spine?
    @State private var addingChant: ChantSet?
    @State private var addingPause: ChantSet?
    @State private var renaming: ChantSet?
    @State private var renameText = ""
    @State private var deleting: ChantSet?

    init(openSetID: Binding<UUID?>, open: @escaping (Chant) -> Void) {
        _openSetID = openSetID
        self.open = open
    }

    private var selected: Spine {
        if let openSetID, shelf.set(openSetID) != nil { return .set(openSetID) }
        if let spineChoice { return spineChoice }
        return shelf.favorites.isEmpty && !shelf.learned.isEmpty ? .learned : .favorites
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            spines

            // One slot the shelves crossfade in, so the one leaving and the
            // one arriving are never laid out one above the other
            ZStack(alignment: .top) {
                switch selected {
                case .learned:
                    list(
                        title: "Learned",
                        kicker: "By heart",
                        chants: shelf.learnedChants,
                        empty: "When you have learned a chant by heart and said so, it stands here."
                    )
                    .transition(.opacity)
                case .favorites:
                    list(
                        title: "Favourites",
                        kicker: "Kept close",
                        chants: shelf.favoriteChants,
                        empty: "Hold a chant down anywhere in the library, or add it from the ⋯ on its page, to keep it here."
                    )
                    .transition(.opacity)
                case .set(let id):
                    if let set = shelf.set(id) {
                        setCard(set)
                            .transition(.opacity)
                    }
                }
            }
            .padding(.horizontal, 20)
            .animation(Motion.crossfade, value: selected)

            if !shelf.recent.isEmpty {
                recentlyPlayed
                    .padding(.horizontal, 20)
            }

            settings
                .padding(.horizontal, 20)
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
        .alert("Rename this set", isPresented: Binding(
            get: { renaming != nil },
            set: { if !$0 { renaming = nil } }
        )) {
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
                if let deleting {
                    if openSetID == deleting.id { openSetID = nil }
                    if spineChoice == .set(deleting.id) { spineChoice = nil }
                    shelf.deleteSet(deleting.id)
                }
                deleting = nil
            }
            Button("Cancel", role: .cancel) { deleting = nil }
        } message: {
            Text("Its chants stay in the library; only the set goes.")
        }
    }

    // MARK: - The shelf of spines

    private var spines: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 8) {
                spine("Learned", note: "\(shelf.learned.count)", cloth: ChantSpineCloth.learned, height: 150, lit: selected == .learned) {
                    openSetID = nil
                    spineChoice = .learned
                }
                spine("Favourites", note: "\(shelf.favorites.count)", cloth: ChantSpineCloth.favorites, height: 166, lit: selected == .favorites) {
                    openSetID = nil
                    spineChoice = .favorites
                }
                ForEach(Array(shelf.sets.enumerated()), id: \.element.id) { index, set in
                    spine(
                        set.name,
                        note: "my set",
                        cloth: ChantSpineCloth.sets[index % ChantSpineCloth.sets.count],
                        height: [180, 158, 172, 162][index % 4],
                        lit: selected == .set(set.id)
                    ) {
                        spineChoice = nil
                        openSetID = set.id
                    }
                }
                newSpine
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(alignment: .bottom) {
                // The shelf they stand on
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.gold.opacity(0.45), AppColors.gold.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 6)
                    .padding(.horizontal, 12)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your shelf")
    }

    private func spine(
        _ title: String,
        note: String,
        cloth: Color,
        height: CGFloat,
        lit: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(cloth)
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(AppColors.gold.opacity(lit ? 0.85 : 0.35), lineWidth: lit ? 1 : AppLine.hairline)
                // Two tooled bands, as a book's spine carries
                VStack {
                    Rectangle().fill(AppColors.gold.opacity(0.35)).frame(height: 1).padding(.top, 10)
                    Spacer()
                    Rectangle().fill(AppColors.gold.opacity(0.35)).frame(height: 1).padding(.bottom, 26)
                }
                .padding(.horizontal, 6)

                Text(title.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.8)
                    .foregroundColor(AppColors.goldLight.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: height - 52)
                    .rotationEffect(.degrees(-90))
                    .offset(y: -6)

                VStack {
                    Spacer()
                    Text(note)
                        .font(AppFonts.readingItalicFont(10.5))
                        .foregroundColor(AppColors.cream.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.bottom, 8)
                }
            }
            .frame(width: 46, height: height)
            .offset(y: lit ? -8 : 0)
            .shadow(color: lit ? AppColors.gold.opacity(0.35) : .black.opacity(0.4), radius: lit ? 10 : 4, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .animation(Motion.settle, value: lit)
        .accessibilityLabel("\(title), \(note)")
        .accessibilityAddTraits(lit ? [.isSelected, .isButton] : .isButton)
    }

    private var newSpine: some View {
        Button {
            let set = shelf.newSet()
            spineChoice = nil
            openSetID = set.id
        } label: {
            AppIcon("ph-plus", size: 16)
                .foregroundColor(AppColors.gold)
                .frame(width: 46, height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(AppColors.gold.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("Make a new set")
    }

    // MARK: - A list

    private func list(title: String, kicker: String, chants: [Chant], empty: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ChantSectionHeading(kicker: kicker, title: title)
            ChantRule()
            if chants.isEmpty {
                Text(empty)
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(chants) { chant in
                        ChantLibraryRow(chant: chant, player: player) {
                            open(chant)
                        }
                    }
                }
            }
        }
    }

    // MARK: - A set

    private func setCard(_ set: ChantSet) -> some View {
        let queue = ChantQueue.set(set)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("YOUR SET")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                    Text(set.name)
                        .font(AppFonts.titleFont(22))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(set.items.isEmpty ? "Nothing in it yet" : set.summary)
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !set.items.isEmpty {
                    ShareLink(item: shareText(set)) {
                        AppIcon("ph-export", size: 18)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
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
                    AppIcon("ph-dots-three", size: 20)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("More for this set")
            }

            ChantRule(opacity: 0.2)

            if set.items.isEmpty {
                Text("Add chants in the order you will sing them, and pauses between them for silence or a note in red.")
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(set.items.enumerated()), id: \.element.id) { index, item in
                        itemRow(item, index: index, in: set, sounding: isSounding(item, index: index, in: set))
                    }
                }
            }

            HStack(spacing: 10) {
                addButton("A chant", color: AppColors.gold) { addingChant = set }
                addButton("A pause or note", color: Rubric.red) { addingPause = set }
            }

            GoldCTAButton(title: "Play the set", glyph: .play) {
                player.play(queue)
            }
            .disabled(set.chantCount == 0)
            .padding(.top, 4)
        }
        .chantShell(padding: 18)
    }

    /// Whether the item is what the set being sung is on
    private func isSounding(_ item: ChantSet.Item, index: Int, in set: ChantSet) -> Bool {
        guard let queue = player.queue, queue.title == set.name, let entry = queue.entry else { return false }
        // The queue unrolls repeats; find the item the entry came from
        var cursor = 0
        for (position, each) in set.items.enumerated() {
            let count: Int
            switch each.kind {
            case .chant(let id, let times): count = ChantCatalog.chant(id) == nil ? 0 : max(1, times)
            case .pause(_, let seconds): count = seconds > 0 ? 1 : 0
            }
            if queue.index < cursor + count {
                return position == index && (entry.chant != nil || item.chant == nil)
            }
            cursor += count
        }
        return false
    }

    private func itemRow(_ item: ChantSet.Item, index: Int, in set: ChantSet, sounding: Bool) -> some View {
        HStack(spacing: 10) {
            Menu {
                Button {
                    shelf.moveItem(item.id, by: -1, in: set.id)
                } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }
                .disabled(index == 0)
                Button {
                    shelf.moveItem(item.id, by: 1, in: set.id)
                } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }
                .disabled(index == set.items.count - 1)
                Button(role: .destructive) {
                    shelf.removeItem(item.id, from: set.id)
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }
            } label: {
                AppIcon("ph-dots-six-vertical", size: 16)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Move or remove")
            .padding(.horizontal, -6)

            switch item.kind {
            case .chant(let id, let times):
                if let chant = ChantCatalog.chant(id) {
                    Button {
                        open(chant)
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(times > 1 ? "\(chant.latinTitle) ×\(times)" : chant.latinTitle)
                                    .font(AppFonts.readingFont(17))
                                    .foregroundColor(sounding ? AppColors.goldLight : AppColors.cream)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(chant.englishTitle)
                                    .font(AppFonts.readingItalicFont(13.5))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer(minLength: 8)
                            Text(ChantPlayer.clock(item.duration))
                                .font(AppFonts.labelFont(9))
                                .tracking(1)
                                .foregroundColor(AppColors.textSecondary)
                                .monospacedDigit()
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Opens the chant")
                }
            case .pause(let note, let seconds):
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    ChantRubricText(text: note.isEmpty ? "Silence" : note, size: 15.5)
                    Spacer(minLength: 8)
                    Text(seconds > 0 ? ChantPlayer.clock(TimeInterval(seconds)) : "—")
                        .font(AppFonts.labelFont(9))
                        .tracking(1)
                        .foregroundColor(sounding ? Rubric.red : AppColors.textSecondary)
                        .monospacedDigit()
                }
                .frame(minHeight: 44)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
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
        .accessibilityLabel("Add \(title.lowercased())")
    }

    /// The set as plain words, to send to a prayer group
    private func shareText(_ set: ChantSet) -> String {
        var lines = [set.name, ""]
        var number = 1
        for item in set.items {
            switch item.kind {
            case .chant(let id, let times):
                guard let chant = ChantCatalog.chant(id) else { continue }
                let repeats = times > 1 ? " ×\(times)" : ""
                lines.append("\(number). \(chant.latinTitle)\(repeats) — \(chant.englishTitle) (\(ChantPlayer.clock(item.duration)))")
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

    // MARK: - Recently played

    private var recentlyPlayed: some View {
        VStack(alignment: .leading, spacing: 10) {
            ChantSectionHeading(kicker: nil, title: "Recently played")
            ChantRule()
            VStack(spacing: 0) {
                ForEach(shelf.recent, id: \.chantID) { play in
                    if let chant = ChantCatalog.chant(play.chantID) {
                        Button {
                            open(chant)
                        } label: {
                            HStack(spacing: 14) {
                                Text(Self.when(play.at).uppercased())
                                    .font(AppFonts.labelFont(8))
                                    .tracking(1.5)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(width: 82, alignment: .leading)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(chant.latinTitle)
                                        .font(AppFonts.readingFont(16))
                                        .foregroundColor(AppColors.cream)
                                    Text(chant.englishTitle)
                                        .font(AppFonts.readingItalicFont(13))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 8)
                            .frame(minHeight: 48)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    /// "Tonight", "This morning", "Yesterday", "Tuesday", "12 Sep"
    static func when(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            let hour = calendar.component(.hour, from: date)
            switch hour {
            case ..<12: return "This morning"
            case 12..<18: return "This afternoon"
            default: return "Tonight"
            }
        }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day,
           days < 7 {
            return date.formatted(.dateTime.weekday(.wide))
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }

    // MARK: - Settings

    private var settings: some View {
        VStack(alignment: .leading, spacing: 10) {
            ChantSectionHeading(kicker: nil, title: "Settings")
            ChantRule()

            Menu {
                Picker("Words", selection: Binding(get: { shelf.words }, set: { shelf.words = $0 })) {
                    ForEach(ChantWordsPreference.allCases) { preference in
                        Text(preference.title).tag(preference)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text("Words")
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                    Spacer(minLength: 8)
                    Text(shelf.words.title)
                        .font(AppFonts.readingItalicFont(15))
                        .foregroundColor(AppColors.textSecondary)
                    AppIcon("ph-caret-down", size: 10)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                }
                .frame(minHeight: 48)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Words: \(shelf.words.title)")
            .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }

            Text("All \(ChantCatalog.all.count) chants are kept on this phone, so they play even in a church with no signal.")
                .font(AppFonts.readingItalicFont(13.5))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }
}
