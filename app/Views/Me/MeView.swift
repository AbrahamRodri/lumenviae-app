//
//  MeView.swift
//  Lumen Viae
//
//  The user's own page — "My Oratory" — in the tab slot Account held.
//
//  An oratory is a private chapel: a room arranged by the one who prays
//  in it. The page is a column of sections the user chooses and orders
//  themselves (rule of prayer, the vigil flame, consecration, journal,
//  devotion counts, intentions), with settings folded behind a single
//  quiet control. Removing a section never deletes what it shows — a
//  hidden streak keeps counting, hidden reflections keep saving.
//
//  The same arranger that lays out this page also decides what the
//  raised Pray button does on a tap and what its press-and-hold tray
//  offers — the button is this page in miniature.
//

import SwiftUI
import SwiftData

struct MeView: View {

    @Environment(UserSettings.self) private var settings
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    /// Re-renders the page as sessions land, same as Sacred Record
    @Query(sort: \PrayerSession.completedAt, order: .reverse)
    private var sessions: [PrayerSession]

    @State private var historyService: PrayerHistoryService?
    @State private var showCustomize = false

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header

                    if settings.meWidgets.isEmpty {
                        emptyPage
                    } else {
                        ForEach(settings.meWidgets) { widget in
                            section(for: widget)
                        }
                    }

                    QuietGoldButton(
                        title: "Edit page",
                        leadingIcon: "ph-pencil-simple",
                        size: 10,
                        color: AppColors.gold.opacity(0.8)
                    ) {
                        showCustomize = true
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 120)
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            if historyService == nil {
                historyService = PrayerHistoryService(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showCustomize) {
            MePageEditorSheet()
        }
    }

    // MARK: - Header

    private var greeting: String {
        settings.displayName.isEmpty ? "Faithful Pilgrim" : settings.displayName
    }

    /// "Praying since June 2026" — from the first recorded session.
    /// Absent until there is one; the page never invents a history.
    private var prayingSince: String? {
        guard let first = sessions.last else { return nil }
        return "Praying since " + first.completedAt.formatted(.dateTime.month(.wide).year())
    }

    /// Compact and left-aligned, like a book's flyleaf: the name, one
    /// quiet line under it, the gear. The page's presence comes from the
    /// cards below, not from a tall masthead.
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greeting)
                    .font(AppFonts.italicFont(24))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)

                if let prayingSince {
                    Text(prayingSince)
                        .font(AppFonts.italicFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            // SF's gearshape: the icon catalog carries no Phosphor gear,
            // and a gear is the one glyph users read as "settings"
            // without a label.
            Button(action: { router.navigateToSettings() }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    // MARK: - Sections

    @ViewBuilder
    private func section(for widget: MeWidget) -> some View {
        switch widget {
        case .rule:
            RuleOfPrayerCard(
                historyService: historyService,
                onArrange: { showCustomize = true }
            )
            .padding(.horizontal, 20)

        case .streak:
            // The streak card took over from the home header's flame, so
            // it also carries the door the flame used to be: the Sacred
            // Record, up in its kicker row.
            if let historyService {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("PRAYER STREAK")
                            .font(AppFonts.labelFont(10))
                            .tracking(2.5)
                            .foregroundColor(AppColors.gold.opacity(0.75))

                        Spacer()

                        QuietGoldButton(
                            title: "Sacred Record",
                            trailingIcon: "ph-caret-right",
                            size: 9,
                            color: AppColors.gold.opacity(0.8),
                            horizontalPadding: 0
                        ) {
                            router.selectedTab = .progress
                        }
                        .padding(.vertical, -10)
                    }

                    StreakWidget(
                        streak: historyService.currentStreak(),
                        hasPrayedToday: historyService.hasPrayedToday(),
                        weekStatus: historyService.weeklyPrayerStatus()
                    )
                }
                .padding(.horizontal, 20)
            }

        case .library:
            LibraryCard()
                .padding(.horizontal, 20)

        case .consecration:
            ConsecrationCard()
                .padding(.horizontal, 20)

        case .journal:
            JournalCard()
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Empty page

    /// Everything removed. The page stays gentle about it and offers the
    /// way back — never a hollow screen with no door.
    private var emptyPage: some View {
        VStack(spacing: 14) {
            AppIcon("ch-window", size: 34)
                .foregroundColor(AppColors.gold.opacity(0.5))

            Text("Your page is empty")
                .font(AppFonts.headlineFont(18))
                .foregroundColor(AppColors.cream)

            Text("Use Edit page below to add your rule, streak, and more.")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
        .padding(.vertical, 36)
    }
}

// MARK: - MeSection

/// Card container for a Me page section: kicker label above, card below —
/// the same ledger language Account's sections use. `washed` lays a
/// faint gold light down from the card's top edge (the votive treatment
/// from the CTA system) so one card on the page can carry more warmth
/// than its neighbors without breaking the shared silhouette.
struct MeSection<Content: View, Accessory: View>: View {
    let title: String
    var washed: Bool = false
    @ViewBuilder let content: Content
    @ViewBuilder let accessory: Accessory

    init(
        title: String,
        washed: Bool = false,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.washed = washed
        self.content = content()
        self.accessory = accessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.75))

                Spacer()

                accessory
            }

            content
                .background(
                    ZStack {
                        AppColors.cardBackground
                        if washed {
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.gold.opacity(0.14), location: 0),
                                    .init(color: AppColors.gold.opacity(0.04), location: 0.45),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    }
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            AppColors.gold.opacity(washed ? 0.35 : 0.15),
                            lineWidth: washed ? 1 : 0.5
                        )
                )
        }
    }
}

// MARK: - Preview

#Preview {
    MeView()
        .environment(UserSettings.shared)
        .environment(AppRouter())
        .modelContainer(for: [PrayerSession.self, JournalEntry.self, ConsecrationProgress.self], inMemory: true)
}
