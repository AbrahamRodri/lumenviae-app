//
//  JournalEntryEditorView.swift
//  Lumen Viae
//
//  Used in three contexts:
//  1. Mid-prayer (isMidPrayer: true)  — subject locked to current mystery
//  2. Post-prayer completion           — subject locked to category
//  3. From journal tab                 — subject is a free-form editable field,
//     empty under "Title (optional)"; user can type any title they want
//

import SwiftUI
import SwiftData

struct JournalEntryEditorView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Parameters (locked context, set by caller)

    /// Mystery category — locked when opened from prayer flow, nil from journal tab
    let lockedCategory: MysteryCategory?

    /// Title of the specific mystery — locked when mid-prayer
    let lockedMysteryTitle: String?

    /// 0-based mystery index — locked when mid-prayer
    let lockedMysteryIndex: Int?

    /// Whether opened during an active prayer session
    let isMidPrayer: Bool

    /// Optional existing entry to edit
    let existingEntry: JournalEntry?

    // MARK: - State

    @State private var text: String = ""

    /// Editable subject — only active when NOT opened from prayer flow
    @State private var subjectText: String = ""

    @FocusState private var bodyFocused: Bool
    @FocusState private var subjectFocused: Bool

    // MARK: - Computed

    /// True when the subject/category is pre-determined by the calling context
    private var isSubjectLocked: Bool {
        isMidPrayer || lockedCategory != nil
    }

    private var displayedSubject: String {
        if let title = lockedMysteryTitle { return title }
        if let cat = lockedCategory { return cat.displayName }
        return subjectText.isEmpty ? "Reflection" : subjectText
    }

    private var placeholderText: String {
        isMidPrayer
            ? "What is stirring in your heart during this mystery…"
            : "Record your thoughts…"
    }

    // Same source of truth as JournalEntry.categoryIcon — categories
    // always render MysteryCategory.iconName
    private var categoryIcon: String {
        lockedCategory?.iconName ?? "ph-book"
    }

    // MARK: - Init

    init(
        category: MysteryCategory? = nil,
        mysteryTitle: String? = nil,
        mysteryIndex: Int? = nil,
        isMidPrayer: Bool = false,
        existingEntry: JournalEntry? = nil
    ) {
        self.lockedCategory = category
        self.lockedMysteryTitle = mysteryTitle
        self.lockedMysteryIndex = mysteryIndex
        self.isMidPrayer = isMidPrayer
        self.existingEntry = existingEntry
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                editorHeader

                subjectRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                Divider()
                    .background(AppColors.gold.opacity(0.1))

                // Text editor
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholderText)
                            .font(AppFonts.italicFont(18))
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            .padding(.horizontal, 24)
                            .padding(.top, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $text)
                        .font(AppFonts.bodyFont(18))
                        .foregroundColor(AppColors.cream)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 20)
                        .focused($bodyFocused)
                        .lineSpacing(6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Said only once something is written: "0 characters"
                // stood under an empty page, and "1 characters" under one
                // letter. The row keeps its height either way.
                HStack {
                    Spacer()
                    Text(text.count == 1 ? "1 character" : "\(text.count) characters")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary.opacity(0.4))
                        .padding(.trailing, 24)
                        .padding(.bottom, 8)
                        .opacity(text.isEmpty ? 0 : 1)
                        .accessibilityHidden(text.isEmpty)
                }
            }
        }
        .onAppear {
            // A new reflection's title starts empty, under its placeholder:
            // typed into the field, "General Reflection" was saved as the
            // title of every reflection not renamed
            if let entry = existingEntry {
                text = entry.text
                subjectText = entry.mysteryTitle ?? ""
            }
            // Always go straight to the body field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                bodyFocused = true
            }
        }
    }

    // MARK: - Header

    /// The sheet grammar's header: when it is written over what it is,
    /// CANCEL and SAVE beside them. It once read Cancel · DEVOTION · Save
    /// in a bar of its own, and DEVOTION named nothing a new reflection is
    private var editorHeader: some View {
        SheetHeader(kicker: headerKicker, title: existingEntry == nil ? "New Reflection" : "Reflection") {
            HStack(spacing: 4) {
                SheetHeaderAction(title: "Cancel") { dismiss() }

                SheetHeaderAction(title: "Save", action: saveEntry)
                    .disabled(hasNoText)
                    .opacity(hasNoText ? 0.35 : 1)
            }
        }
    }

    /// The day it is written, "Thursday, 1 October" (an entry's own when it
    /// is edited), or, opened from a mystery being prayed, that it is
    private var headerKicker: String {
        if existingEntry == nil, isMidPrayer { return "During prayer" }
        let date = existingEntry?.createdAt ?? Date()
        let weekday = date.formatted(.dateTime.weekday(.wide))
        let day = date.formatted(.dateTime.day())
        let month = date.formatted(.dateTime.month(.wide))
        return "\(weekday), \(day) \(month)"
    }

    private var hasNoText: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Subject Row

    @ViewBuilder
    private var subjectRow: some View {
        HStack(spacing: 10) {
            AppIcon(categoryIcon, size: 13)
                .foregroundColor(AppColors.gold.opacity(0.8))

            if isSubjectLocked {
                // Pre-filled, read-only subject from prayer context
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayedSubject)
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.cream)

                    Text(isMidPrayer ? "During prayer" : "After prayer")
                        .font(AppFonts.bodyFont(11))
                        .foregroundColor(AppColors.textSecondary)
                }
            } else {
                // Free-form editable subject. Italic text alone reads as
                // a label, not a field — so it is written *on* something:
                // a hairline that brightens under the caret, and a hint
                // line led by a pencil that says what to do with it.
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Title (optional)", text: $subjectText)
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.cream)
                        .tint(AppColors.gold)
                        .focused($subjectFocused)
                        .submitLabel(.next)
                        .onSubmit { bodyFocused = true }
                        .padding(.bottom, 3)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(AppColors.gold.opacity(subjectFocused ? 0.75 : 0.3))
                                .frame(height: subjectFocused ? 1.5 : 1)
                        }

                    HStack(spacing: 5) {
                        AppIcon("ph-pencil-simple", size: 10)
                        Text(subjectFocused ? "Mystery, topic, or leave blank" : "Tap to add a title")
                            .font(AppFonts.bodyFont(11))
                    }
                    .foregroundColor(
                        subjectFocused
                            ? AppColors.textSecondary.opacity(0.6)
                            : AppColors.gold.opacity(0.75)
                    )
                }
            }

            // No date here: the header names the day above the row
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSubjectLocked
                                ? AppColors.gold.opacity(0.15)
                                : AppColors.gold.opacity(subjectFocused ? 0.5 : 0.2),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.15), value: subjectFocused)
    }

    // MARK: - Actions

    private func saveEntry() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Resolve final subject title
        let finalTitle: String? = {
            if let locked = lockedMysteryTitle { return locked }
            // A subject locked to a set of mysteries is named by them.
            // The free-form field is never shown, so nothing it holds is
            // the reader's — saved, the "General Reflection" it was once
            // filled with stood in the journal over every reflection
            // written after a Rosary
            if isSubjectLocked { return nil }
            let s = subjectText.trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : s
        }()

        if let entry = existingEntry {
            entry.text = trimmed
            entry.mysteryTitle = finalTitle
        } else {
            let entry = JournalEntry(
                text: trimmed,
                category: lockedCategory,
                mysteryTitle: finalTitle,
                mysteryIndex: lockedMysteryIndex,
                isMidPrayer: isMidPrayer
            )
            modelContext.insert(entry)
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Previews

#Preview("From journal tab (free-form)") {
    JournalEntryEditorView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
}

#Preview("Mid-prayer (locked)") {
    JournalEntryEditorView(
        category: .glorious,
        mysteryTitle: "The Resurrection",
        mysteryIndex: 0,
        isMidPrayer: true
    )
    .modelContainer(for: JournalEntry.self, inMemory: true)
}
