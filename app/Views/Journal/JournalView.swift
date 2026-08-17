//
//  JournalView.swift
//  Lumen Viae
//
//  Lists all journal entries grouped by month. Users can:
//  - Browse past reflections
//  - Tap an entry to read it in full
//  - Tap the pencil button to write a new general reflection
//  - Delete entries via long-press, or from the entry's detail view
//
//  Design mirrors the app's navy/gold palette — NOT the light design in the
//  screenshot mockup. Drop-cap first letters on each entry match the preview.
//

import SwiftUI
import SwiftData

// MARK: - JournalView

struct JournalView: View {

    // MARK: - Data

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    // MARK: - State

    @State private var showingNewEntry = false
    @State private var selectedEntry: JournalEntry? = nil
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var entryPendingDelete: JournalEntry? = nil

    /// Gallery (the drop-capped cards) or list (one line an entry).
    /// Persisted, because it is a reading preference rather than a mood
    /// — a long journal is browsed the same way every time.
    @AppStorage("journal.usesListLayout") private var usesListLayout = false

    // MARK: - Computed

    private var filteredEntries: [JournalEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.text.localizedCaseInsensitiveContains(searchText) ||
            ($0.mysteryTitle ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Entries grouped by "Month Year" label, in reverse chronological order
    private var groupedEntries: [(month: String, entries: [JournalEntry])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var groups: [(month: String, entries: [JournalEntry])] = []
        var seen: [String: Int] = [:]

        for entry in filteredEntries {
            let key = formatter.string(from: entry.createdAt).uppercased()
            if let idx = seen[key] {
                groups[idx].entries.append(entry)
            } else {
                seen[key] = groups.count
                groups.append((month: key, entries: [entry]))
            }
        }
        return groups
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation header
                journalHeader

                if entries.isEmpty {
                    emptyState
                } else {
                    journalList
                }
            }
        }
        // New entry sheet
        .sheet(isPresented: $showingNewEntry) {
            JournalEntryEditorView(isMidPrayer: false)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        // Detail / edit sheet
        .sheet(item: $selectedEntry) { entry in
            JournalDetailView(entry: entry)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        // Long-press delete confirmation
        .confirmationDialog(
            "Delete this reflection?",
            isPresented: Binding(
                get: { entryPendingDelete != nil },
                set: { if !$0 { entryPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let entry = entryPendingDelete {
                    deleteEntry(entry)
                }
                entryPendingDelete = nil
            }
            Button("Cancel", role: .cancel) { entryPendingDelete = nil }
        }
    }

    // MARK: - Header

    private var journalHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("SPIRITUAL")
                        .font(AppFonts.bodyFont(11))
                        .tracking(4)
                        .foregroundColor(AppColors.gold.opacity(0.7))
                    Text("Journal")
                        .font(AppFonts.italicFont(30))
                        .foregroundColor(AppColors.cream)
                }

                Spacer()

                HStack(spacing: 18) {
                    layoutToggle

                    // Search toggle
                    Button(action: { withAnimation { showingSearch.toggle() } }) {
                        AppIcon("ph-magnifying-glass", size: 18)
                            .foregroundColor(AppColors.gold)
                    }

                    // New general entry
                    Button(action: { showingNewEntry = true }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.gold)
                                .frame(width: 40, height: 40)
                            AppIcon("ph-pencil-simple", size: 16)
                                .foregroundColor(AppColors.background)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Search bar
            if showingSearch {
                HStack(spacing: 8) {
                    AppIcon("ph-magnifying-glass", size: 14)
                        .foregroundColor(AppColors.textSecondary)

                    TextField("Search reflections…", text: $searchText)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream)
                        .tint(AppColors.gold)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            AppIcon("ph-x-circle", size: 16)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Gold divider
            Rectangle()
                .fill(AppColors.gold.opacity(0.25))
                .frame(height: 1)
        }
    }

    /// Gallery and list, as a pair of glyphs where the lit one is the
    /// layout you are looking at.
    private var layoutToggle: some View {
        HStack(spacing: 12) {
            layoutButton(
                icon: "ph-list",
                label: "List view",
                isSelected: usesListLayout
            ) {
                usesListLayout = true
            }

            layoutButton(
                icon: "ph-cards",
                label: "Gallery view",
                isSelected: !usesListLayout
            ) {
                usesListLayout = false
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func layoutButton(
        icon: String,
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            guard !isSelected else { return }
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        } label: {
            AppIcon(icon, size: 17)
                .foregroundColor(isSelected ? AppColors.gold : AppColors.textSecondary.opacity(0.55))
                .frame(width: 30, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - List

    private var journalList: some View {
        ScrollView(showsIndicators: false) {
            if filteredEntries.isEmpty {
                noResultsState
            } else {
                VStack(spacing: 32) {
                    ForEach(groupedEntries, id: \.month) { group in
                        monthSection(group)
                    }

                    Spacer(minLength: 120)
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
            }
        }
    }

    /// Shown when a search matches nothing: name the query, offer a hint,
    /// and give a way back out — never a silently blank page.
    private var noResultsState: some View {
        VStack(spacing: 16) {
            AppIcon("ph-magnifying-glass", size: 40)
                .foregroundColor(AppColors.gold.opacity(0.35))

            VStack(spacing: 6) {
                Text("Nothing matches \u{201C}\(searchText)\u{201D}")
                    .font(AppFonts.semiboldBodyFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .multilineTextAlignment(.center)

                Text("Try a shorter word, or search by a mystery's name.")
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { searchText = "" }
            } label: {
                Text("Clear Search")
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.gold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .overlay(
                        Capsule().strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
        .padding(.horizontal, 32)
    }

    private func monthSection(_ group: (month: String, entries: [JournalEntry])) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month header with decorative lines
            HStack(spacing: 12) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.4))
                    .frame(height: 1)
                    .frame(maxWidth: 40)

                Text(group.month)
                    .font(AppFonts.headlineFont(14))
                    .tracking(3)
                    .foregroundColor(AppColors.gold)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.4))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
            }

            // Entry cards (swipe actions only work inside List, so
            // deletion lives in a long-press menu + the detail view)
            VStack(spacing: usesListLayout ? 0 : 16) {
                ForEach(group.entries) { entry in
                    Group {
                        if usesListLayout {
                            JournalEntryRow(entry: entry)
                        } else {
                            JournalEntryCard(entry: entry)
                        }
                    }
                    .onTapGesture { selectedEntry = entry }
                    .contextMenu {
                        Button(role: .destructive) {
                            entryPendingDelete = entry
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            AppIcon("ph-book", size: 52)
                .foregroundColor(AppColors.gold.opacity(0.3))

            VStack(spacing: 8) {
                Text("Your journal awaits")
                    .font(AppFonts.italicFont(22))
                    .foregroundColor(AppColors.cream.opacity(0.8))

                Text("Record thoughts during or after\nyour Rosary prayers.")
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: { showingNewEntry = true }) {
                HStack(spacing: 8) {
                    AppIcon("ph-note-pencil", size: 16)
                    Text("Write First Entry")
                        .tracking(1)
                }
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.background)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(AppColors.goldLight)
                )
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func deleteEntry(_ entry: JournalEntry) {
        withAnimation {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}

// MARK: - JournalEntryCard

struct JournalEntryCard: View {
    let entry: JournalEntry

    private var dateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(entry.createdAt) { return "TODAY" }
        if calendar.isDateInYesterday(entry.createdAt) { return "YESTERDAY" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: entry.createdAt).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Entry metadata row
            HStack(spacing: 8) {
                AppIcon(entry.categoryIcon, size: 12)
                    .foregroundColor(AppColors.gold)

                Text(dateLabel)
                    .font(AppFonts.bodyFont(11))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)

                Text("•")
                    .foregroundColor(AppColors.textSecondary)

                Text(entry.subjectLabel)
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.cream.opacity(0.8))
                    .lineLimit(1)

                Spacer()

                if entry.isMidPrayer {
                    Text("mid-prayer")
                        .font(AppFonts.bodyFont(10))
                        .tracking(1)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            // Drop-cap styled text preview
            JournalDropCapText(text: entry.text)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Journal Entry Row

/// The list layout: one line an entry. Enough to find something —
/// when it was written, what it was about, how it opens — and nothing
/// more. The gallery card is where an entry is actually read from.
struct JournalEntryRow: View {
    let entry: JournalEntry

    private var dateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(entry.createdAt) { return "TODAY" }
        if calendar.isDateInYesterday(entry.createdAt) { return "YESTERDAY" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: entry.createdAt).uppercased()
    }

    /// The opening of the entry on a single line, with the newlines
    /// flattened so a line break can't blank the preview.
    private var opening: String {
        entry.text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                AppIcon(entry.categoryIcon, size: 13)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(entry.subjectLabel)
                            .font(AppFonts.italicFont(15))
                            .foregroundColor(AppColors.cream)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(dateLabel)
                            .font(AppFonts.bodyFont(10))
                            .tracking(1.5)
                            .foregroundColor(AppColors.gold.opacity(0.8))
                            .fixedSize()
                    }

                    Text(opening)
                        .font(AppFonts.bodyFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 13)
            .frame(minHeight: 56)
            .contentShape(Rectangle())

            Rectangle()
                .fill(AppColors.gold.opacity(0.12))
                .frame(height: 0.5)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Drop Cap Text

struct JournalDropCapText: View {
    let text: String

    private var firstLetter: String {
        guard let first = text.first else { return "" }
        return String(first).uppercased()
    }

    private var remainingText: String {
        guard text.count > 1 else { return "" }
        return String(text.dropFirst())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Drop cap letter — fixedSize lets it breathe to its natural width
            Text(firstLetter)
                .font(.system(size: 24, weight: .light, design: .serif))
                .foregroundColor(AppColors.gold)
                .fixedSize()
                .padding(.trailing, 6)
                .padding(.bottom, 2)

            // Rest of the text
            Text(remainingText)
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.cream.opacity(0.85))
                .lineSpacing(4)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - JournalDetailView

struct JournalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry

    @State private var showingEditor = false
    @State private var showingDeleteConfirm = false

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: entry.createdAt)
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        AppIcon("ph-caret-left", size: 16)
                            .foregroundColor(AppColors.gold)
                    }

                    Spacer()

                    HStack(spacing: 20) {
                        Button(action: { showingEditor = true }) {
                            AppIcon("ph-pencil-simple", size: 16)
                                .foregroundColor(AppColors.gold)
                        }

                        Button(action: { showingDeleteConfirm = true }) {
                            AppIcon("ph-trash", size: 16)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.2))
                    .frame(height: 1)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Mystery / subject info
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                AppIcon(entry.categoryIcon, size: 13)
                                    .foregroundColor(AppColors.gold)

                                Text(entry.subjectLabel)
                                    .font(AppFonts.italicFont(20))
                                    .foregroundColor(AppColors.cream)
                            }

                            Text(dateString)
                                .font(AppFonts.bodyFont(12))
                                .foregroundColor(AppColors.textSecondary)

                            if entry.isMidPrayer {
                                Text("Written during prayer")
                                    .font(AppFonts.bodyFont(12))
                                    .foregroundColor(AppColors.gold.opacity(0.7))
                            }
                        }
                        .padding(.top, 24)

                        Rectangle()
                            .fill(AppColors.gold.opacity(0.2))
                            .frame(height: 1)

                        // Full text with drop cap
                        JournalDropCapText(text: entry.text)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            JournalEntryEditorView(
                category: entry.category,
                mysteryTitle: entry.mysteryTitle,
                mysteryIndex: entry.mysteryIndex,
                isMidPrayer: entry.isMidPrayer,
                existingEntry: entry
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Delete this reflection?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Preview

#Preview("Journal (empty)") {
    JournalView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
}

#Preview("Journal (with entries)") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: JournalEntry.self, configurations: config)

    // Seed sample entries
    let entries: [JournalEntry] = [
        JournalEntry(text: "I felt a profound sense of peace today contemplating the empty tomb. The silence of the morning reminded me that hope often starts quietly, in the stillness before the dawn breaks. It is not always a shout, but a whisper of grace.",
                     category: .glorious, mysteryTitle: "The Resurrection", mysteryIndex: 0, isMidPrayer: false,
                     createdAt: Date()),
        JournalEntry(text: "Struggled with distractions, but realized that Christ also felt alone and burdened. My distraction became a prayer for patience.",
                     category: .sorrowful, mysteryTitle: "Agony in the Garden", mysteryIndex: 0, isMidPrayer: true,
                     createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        JournalEntry(text: "Thinking about Mary's 'Yes' and how I can say yes to God in my daily work, even when the path isn't clear. Her fiat was not given in perfect certainty.",
                     category: .joyful, mysteryTitle: "The Annunciation", mysteryIndex: 0, isMidPrayer: false,
                     createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!)
    ]
    entries.forEach { container.mainContext.insert($0) }

    return JournalView()
        .modelContainer(container)
}
