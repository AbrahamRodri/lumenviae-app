//
//  JournalView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  JOURNAL VIEW - SPIRITUAL DIARY OF PRAYER REFLECTIONS
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Lists all journal entries grouped by month. Users can:
//  - Browse past reflections
//  - Tap an entry to read it in full
//  - Tap the pencil button to write a new general reflection
//  - Delete entries by swiping
//
//  Design mirrors the app's navy/gold palette — NOT the light design in the
//  screenshot mockup. Drop-cap first letters on each entry match the preview.
//
//  ═══════════════════════════════════════════════════════════════════════════

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
            LinearGradient(
                colors: [
                    Color(hex: "0d0d1a"),
                    Color(hex: "1a1a2e"),
                    Color(hex: "0d0d1a")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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
                    // Search toggle
                    Button(action: { withAnimation { showingSearch.toggle() } }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.gold)
                    }

                    // New general entry
                    Button(action: { showingNewEntry = true }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.gold)
                                .frame(width: 40, height: 40)
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .medium))
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
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.system(size: 14))

                    TextField("Search reflections…", text: $searchText)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream)
                        .tint(AppColors.gold)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
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

    // MARK: - List

    private var journalList: some View {
        ScrollView(showsIndicators: false) {
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

            // Entry cards
            ForEach(group.entries) { entry in
                JournalEntryCard(entry: entry)
                    .onTapGesture { selectedEntry = entry }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 52))
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
                    Image(systemName: "pencil.line")
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
                Image(systemName: entry.categoryIcon)
                    .font(.system(size: 12))
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
            DropCapText(text: entry.text)
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

// MARK: - Drop Cap Text

struct DropCapText: View {
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
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.gold)
                    }

                    Spacer()

                    HStack(spacing: 20) {
                        Button(action: { showingEditor = true }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.gold)
                        }

                        Button(action: { showingDeleteConfirm = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
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
                                Image(systemName: entry.categoryIcon)
                                    .font(.system(size: 13))
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
                        DropCapText(text: entry.text)
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
