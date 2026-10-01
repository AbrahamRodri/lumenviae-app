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

/// Chants added to a set, one tap each, until DONE. A search at the head,
/// the library in its order beneath.
struct ChantPickerSheet: View {
    let set: ChantSet

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var added: [String] = []

    private var shelf = ChantShelfStore.shared

    init(set: ChantSet) {
        self.set = set
    }

    private var chants: [Chant] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? ChantCatalog.all : ChantCatalog.search(trimmed)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(kicker: "Add to \(set.name)", title: "A chant") {
                SheetHeaderAction(title: "Done") { dismiss() }
            }

            HStack(spacing: 10) {
                AppIcon("ph-magnifying-glass", size: 15)
                    .foregroundColor(AppColors.gold)
                TextField("", text: $query, prompt: Text("Search the chants").foregroundColor(AppColors.textSecondary))
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline))
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(chants) { chant in
                        Button {
                            shelf.addChant(chant.id, to: set.id)
                            added.append(chant.id)
                        } label: {
                            SheetRow(
                                chant.fullTitle,
                                detail: chant.englishTitle,
                                accessory: added.contains(chant.id) ? .label("Added") : .none
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Adds it to the end of the set")
                    }
                }
            }
        }
        .sheetGround()
        .sensoryFeedback(.selection, trigger: added.count)
    }
}

// MARK: - ChantPauseSheet

/// A note between chants, in red, and as long a silence as the reader
/// wants kept there: "Silent prayer · 10 minutes", "Pray for my
/// intentions".
struct ChantPauseSheet: View {
    let set: ChantSet

    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @State private var minutes = 0

    private var shelf = ChantShelfStore.shared

    private static let lengths = [0, 1, 2, 5, 10, 15]

    init(set: ChantSet) {
        self.set = set
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                kicker: "Add to \(set.name)",
                title: "A pause or note",
                lead: "Words in red between chants — what happens, or what to pray for — and silence kept there if you want it."
            ) {
                SheetHeaderAction(title: "Cancel") { dismiss() }
            }

            SheetSectionLabel("The note")
            TextField("", text: $note, prompt: Text("Silent prayer").foregroundColor(AppColors.textSecondary))
                .font(AppFonts.readingItalicFont(17))
                .foregroundColor(Rubric.text)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline))
                .padding(.horizontal, SheetMetrics.gutter)

            SheetSectionLabel("Silence")
            ChantFlowLayout(spacing: 8) {
                ForEach(Self.lengths, id: \.self) { length in
                    let lit = length == minutes
                    Button {
                        minutes = length
                    } label: {
                        Text(length == 0 ? "None" : "\(length) min")
                            .font(AppFonts.readingFont(15))
                            .foregroundColor(lit ? AppColors.goldLight : AppColors.cream.opacity(0.8))
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(Capsule().fill(lit ? AppColors.gold.opacity(0.16) : Color.clear))
                            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(lit ? 0.6 : 0.25), lineWidth: AppLine.hairline))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(SacredCardButtonStyle())
                    .accessibilityLabel(length == 0 ? "No silence" : "\(length) minutes of silence")
                    .accessibilityAddTraits(lit ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, SheetMetrics.gutter)

            SheetNote(minutes == 0
                      ? "The note is read, and the next chant follows."
                      : "The set keeps silence for \(minutes == 1 ? "a minute" : "\(minutes) minutes") here, then goes on.")

            Spacer(minLength: 12)

            GoldCTAButton(title: "Add", trailingIcon: "ph-check") {
                let words = note.trimmingCharacters(in: .whitespacesAndNewlines)
                shelf.addPause(
                    note: words.isEmpty ? (minutes > 0 ? "Silent prayer" : "") : words,
                    seconds: minutes * 60,
                    to: set.id
                )
                dismiss()
            }
            .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && minutes == 0)
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.bottom, 20)
        }
        .sheetGround()
    }
}

// MARK: - ChantAddToSetSheet

/// One chant put in a set of the reader's own, or in a new one
struct ChantAddToSetSheet: View {
    let chant: Chant

    @Environment(\.dismiss) private var dismiss

    private var shelf = ChantShelfStore.shared

    init(chant: Chant) {
        self.chant = chant
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(kicker: chant.latinTitle, title: "Add to a set") {
                SheetHeaderAction(title: "Cancel") { dismiss() }
            }
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(shelf.sets) { set in
                        Button {
                            shelf.addChant(chant.id, to: set.id)
                            dismiss()
                        } label: {
                            SheetRow(set.name, detail: set.summary, icon: "ph-bookmark-simple", accessory: .none)
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        shelf.newSet(with: chant.id)
                        dismiss()
                    } label: {
                        SheetRow("A new set", detail: "Begun with this chant", icon: "ph-plus", accessory: .none, showsDivider: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheetGround()
    }
}

// MARK: - ChantNewSetSheet

/// A set of the reader's own, named before it is made: it stands on the
/// shelf only once it is made, so backing out leaves no empty spine
struct ChantNewSetSheet: View {
    let made: (ChantSet) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var focused: Bool

    private var shelf = ChantShelfStore.shared

    init(made: @escaping (ChantSet) -> Void) {
        self.made = made
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                kicker: "Saved",
                title: "A new set",
                lead: "For a holy hour, a prayer group or family prayer. Its chants and pauses are added once it is made."
            ) {
                SheetHeaderAction(title: "Cancel") { dismiss() }
            }

            SheetSectionLabel("Its name")
            TextField("", text: $name, prompt: Text(shelf.nextSetName).foregroundColor(AppColors.textSecondary))
                .font(AppFonts.readingFont(17))
                .foregroundColor(AppColors.cream)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(make)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline))
                .padding(.horizontal, SheetMetrics.gutter)
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

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    init(chant: Chant) {
        self.chant = chant
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(kicker: chant.latinTitle, title: "The words") {
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
                        SheetNote("The words as the Prayer Book prints them. The chant may sing a versicle or a collect beside them.")
                    } else {
                        SheetNote("The words of this chant have not been set out yet. They stand on its score.")
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
        .accessibilityHint("Sings from this line")
    }
}

// MARK: - ChantSleepSheet

/// The library falls silent after a while, for chant sung to sleep by
struct ChantSleepSheet: View {

    @Environment(\.dismiss) private var dismiss

    private var player = ChantPlayer.shared

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
