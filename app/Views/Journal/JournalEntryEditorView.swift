//
//  JournalEntryEditorView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  JOURNAL ENTRY EDITOR - WRITE OR EDIT A REFLECTION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Used in three contexts:
//  1. Mid-prayer (isMidPrayer: true)  — subject locked to current mystery
//  2. Post-prayer completion           — subject locked to category
//  3. From journal tab                 — subject is a free-form editable field
//     defaulting to "General Reflection"; user can type any title they want
//
//  ═══════════════════════════════════════════════════════════════════════════

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
        return subjectText.isEmpty ? "General Reflection" : subjectText
    }

    private var placeholderText: String {
        isMidPrayer
            ? "What is stirring in your heart during this mystery…"
            : "Record your thoughts…"
    }

    private var categoryIcon: String {
        switch lockedCategory {
        case .joyful:    return "sun.max.fill"
        case .sorrowful: return "cloud.rain.fill"
        case .glorious:  return "sparkles"
        case .luminous:  return "rays"
        case .none:      return "book.fill"
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: existingEntry?.createdAt ?? Date())
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

                Divider()
                    .background(AppColors.gold.opacity(0.2))

                subjectRow
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
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

                HStack {
                    Spacer()
                    Text("\(text.count) characters")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary.opacity(0.4))
                        .padding(.trailing, 24)
                        .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            if let entry = existingEntry {
                text = entry.text
                subjectText = entry.mysteryTitle ?? "General Reflection"
            } else if subjectText.isEmpty {
                subjectText = "General Reflection"
            }
            // Always go straight to the body field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                bodyFocused = true
            }
        }
    }

    // MARK: - Header

    private var editorHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Text(isMidPrayer ? "REFLECTION" : "DEVOTION")
                .font(AppFonts.bodyFont(11))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            Spacer()

            Button(action: saveEntry) {
                Text("Save")
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? AppColors.gold.opacity(0.3)
                            : AppColors.gold
                    )
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Subject Row

    @ViewBuilder
    private var subjectRow: some View {
        HStack(spacing: 10) {
            Image(systemName: categoryIcon)
                .font(.system(size: 13))
                .foregroundColor(AppColors.gold.opacity(0.8))

            if isSubjectLocked {
                // Pre-filled, read-only subject from prayer context
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayedSubject)
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.cream)

                    Text(isMidPrayer ? "During prayer" : "Post-prayer reflection")
                        .font(AppFonts.bodyFont(11))
                        .foregroundColor(AppColors.textSecondary)
                }
            } else {
                // Free-form editable subject
                VStack(alignment: .leading, spacing: 2) {
                    TextField("General Reflection", text: $subjectText)
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.cream)
                        .tint(AppColors.gold)
                        .focused($subjectFocused)
                        .submitLabel(.next)
                        .onSubmit { bodyFocused = true }

                    Text("Mystery, topic, or leave blank")
                        .font(AppFonts.bodyFont(11))
                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                }
            }

            Spacer()

            Text(formattedDate)
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)
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
