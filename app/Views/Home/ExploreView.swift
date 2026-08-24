//
//  ExploreView.swift
//  Lumen Viae
//
//  Explore: one page that can reach everything, opened from the home
//  screen's search bar. Empty, it browses — the mysteries, the library,
//  every meditation set. Typed into, it searches all three at once.
//
//  The meditation index is fetched per category from the API and held
//  only as long as this page; a failed fetch simply leaves the browse
//  sections, so the page never looks broken offline.
//

import SwiftUI

struct ExploreView: View {

    @Environment(AppRouter.self) private var router

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    /// Every category's set summaries, fetched once per visit
    @State private var sets: [MeditationSetSummary] = []
    @State private var isLoadingSets = false

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                searchHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        if trimmedQuery.isEmpty {
                            browseContent
                        } else {
                            searchResults
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .task { await loadSets() }
    }

    // MARK: - Search header

    private var searchHeader: some View {
        HStack(spacing: 10) {
            Button(action: { router.pop() }) {
                AppIcon("ph-arrow-left", size: 18)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            HStack(spacing: 10) {
                AppIcon("ph-magnifying-glass", size: 15)
                    .foregroundColor(AppColors.textSecondary)

                TextField(
                    "",
                    text: $query,
                    prompt: Text("Search mysteries, meditations, the library")
                        .font(AppFonts.bodyFont(14))
                        .foregroundColor(AppColors.textSecondary.opacity(0.8))
                )
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream)
                .tint(AppColors.gold)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()

                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        AppIcon("ph-x-circle", size: 15)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Capsule().fill(AppColors.cardBackground))
            .overlay(
                Capsule().strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 0.5)
            )
        }
        .padding(.leading, 8)
        .padding(.trailing, 20)
        .padding(.top, 8)
        .onAppear { searchFocused = true }
    }

    // MARK: - Browse

    @ViewBuilder
    private var browseContent: some View {
        section("The Mysteries") {
            tileGrid(MysteryCategory.allCases.map { category in
                ExploreTile(icon: category.iconName, title: category.devotionTitle) {
                    router.navigateToMeditationSelection(category: category)
                }
            })
        }

        section("The Library") {
            tileGrid(libraryTiles)
        }

        section("Meditations") {
            if isLoadingSets && sets.isEmpty {
                ProgressView()
                    .tint(AppColors.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if sets.isEmpty {
                Text("Meditation sets appear here once loaded.")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                setRows(sets)
            }
        }
    }

    // MARK: - Search results

    @ViewBuilder
    private var searchResults: some View {
        let needle = trimmedQuery.lowercased()

        let categories = MysteryCategory.allCases.filter {
            $0.devotionTitle.lowercased().contains(needle)
                || $0.subtitle.lowercased().contains(needle)
        }
        let libraryHits = libraryEntries.filter { $0.matchText.lowercased().contains(needle) }
        let setHits = sets.filter { matches($0, needle: needle) }

        if categories.isEmpty && libraryHits.isEmpty && setHits.isEmpty {
            VStack(spacing: 8) {
                Text("Nothing found")
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(AppColors.cream)

                Text("Try a mystery, a set's name, or a saint.")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            if !categories.isEmpty {
                section("The Mysteries") {
                    tileGrid(categories.map { category in
                        ExploreTile(icon: category.iconName, title: category.devotionTitle) {
                            router.navigateToMeditationSelection(category: category)
                        }
                    })
                }
            }

            if !libraryHits.isEmpty {
                section("The Library") {
                    tileGrid(libraryHits.map { entry in
                        ExploreTile(icon: entry.icon, title: entry.title, action: entry.action)
                    })
                }
            }

            if !setHits.isEmpty {
                section("Meditations") {
                    setRows(setHits)
                }
            }
        }
    }

    private func matches(_ summary: MeditationSetSummary, needle: String) -> Bool {
        if summary.name.lowercased().contains(needle) { return true }
        if let author = summary.author, author.lowercased().contains(needle) { return true }
        if let source = summary.source, source.lowercased().contains(needle) { return true }
        if let labels = summary.labels, labels.contains(where: { $0.lowercased().contains(needle) }) { return true }
        if let category = MysteryCategory(rawValue: summary.category),
           category.devotionTitle.lowercased().contains(needle) { return true }
        return false
    }

    // MARK: - Library entries

    private struct LibraryEntry {
        let icon: String
        let title: String
        let matchText: String
        let action: () -> Void
    }

    private var libraryEntries: [LibraryEntry] {
        [
            LibraryEntry(icon: "ch-altar", title: "Daily Missal",
                         matchText: "daily missal mass 1962 propers latin") { router.push(.missal) },
            LibraryEntry(icon: "ch-candle", title: "Divine Office",
                         matchText: "divine office breviary hours matins lauds prime terce sext none vespers compline") { router.push(.office) },
            LibraryEntry(icon: "ph-crown", title: "True Devotion",
                         matchText: "true devotion to mary montfort book") { router.push(.trueDevotion) },
            LibraryEntry(icon: "ch-rosary", title: "How to Pray",
                         matchText: "how to pray the rosary guide montfort methods") { router.push(.howToPray) },
            LibraryEntry(icon: "ch-bible", title: "In Scripture",
                         matchText: "mysteries in scripture bible verses") { router.push(.scripture) },
            LibraryEntry(icon: "ph-heart", title: "Marian Library",
                         matchText: "marian theology library dogmas apparitions saints") { router.push(.marianLibrary) },
            LibraryEntry(icon: "ch-monstrance", title: "Carlo Acutis",
                         matchText: "carlo acutis eucharist digital altar saint") { router.push(.carloAcutis) },
            LibraryEntry(icon: "ph-flame", title: "Sacred Record",
                         matchText: "sacred record progress streak history calendar") { router.selectedTab = .progress }
        ]
    }

    private var libraryTiles: [ExploreTile] {
        libraryEntries.map { ExploreTile(icon: $0.icon, title: $0.title, action: $0.action) }
    }

    // MARK: - Pieces

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.75))

            content()
        }
    }

    private func tileGrid(_ tiles: [ExploreTile]) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in
                tile
            }
        }
    }

    private func setRows(_ summaries: [MeditationSetSummary]) -> some View {
        VStack(spacing: 0) {
            ForEach(summaries) { summary in
                Button {
                    router.navigateToMeditationSetDetail(summary)
                } label: {
                    HStack(spacing: 14) {
                        AppIcon("ph-cards", size: 16)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(summary.name)
                                .font(AppFonts.bodyFont(15))
                                .foregroundColor(AppColors.cream)

                            Text(setSubtitle(summary))
                                .font(AppFonts.bodyFont(12))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        AppIcon("ph-caret-right", size: 13)
                            .foregroundColor(AppColors.textSecondary.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if summary.id != summaries.last?.id {
                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
        )
    }

    private func setSubtitle(_ summary: MeditationSetSummary) -> String {
        let category = MysteryCategory(rawValue: summary.category)?.devotionTitle ?? summary.category
        // A set named for its author would read the same line twice
        if let author = summary.author, !author.isEmpty, author != summary.name {
            return "\(author) · \(category)"
        }
        return category
    }

    // MARK: - Data

    /// Every category's summaries, fetched concurrently. A category that
    /// fails just contributes nothing — browse still stands.
    private func loadSets() async {
        guard sets.isEmpty, !isLoadingSets else { return }
        isLoadingSets = true
        defer { isLoadingSets = false }

        let fetched = await withTaskGroup(of: [MeditationSetSummary].self) { group in
            for category in MysteryCategory.allCases {
                group.addTask {
                    (try? await APIService.shared.fetchMeditationSets(category: category)) ?? []
                }
            }

            var all: [MeditationSetSummary] = []
            for await summaries in group {
                all.append(contentsOf: summaries)
            }
            return all
        }

        sets = fetched.sorted { $0.name < $1.name }
    }
}

// MARK: - ExploreTile

/// A small door: icon and name in a quiet cell, the same shelf language
/// as the Me page's Library card.
private struct ExploreTile: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                AppIcon(icon, size: 16)
                    .foregroundColor(AppColors.gold)

                Text(title)
                    .font(AppFonts.bodyFont(13))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExploreView()
            .environment(AppRouter())
    }
}
