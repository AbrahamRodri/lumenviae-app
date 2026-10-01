//
//  ChantLibraryView.swift
//  Lumen Viae
//
//  The Chant Library: the Church's own songs, each with its recording and
//  its score, to hear, to follow and to learn. The "Chant Library Redesign"
//  boards made it a library with six ways in, set as a strip of sections
//  under its masthead:
//
//    TODAY      what is sung now — the hour, tonight's antiphon of Our
//               Lady, the weekday's devotion, the month's
//    SEASONS    the Church's year as a wheel, the season's chants, the
//               feasts ahead
//    OCCASIONS  chants in the order they are sung: Benediction, a visit,
//               a sung Rosary
//    TYPES      by kind — antiphons, hymns, sequences, litanies — and by
//               length
//    LEARN      the course, chant by chant in four steps
//    SAVED      the reader's own: favourites, chants learned, sets they
//               made, what they sang lately
//
//  The glass opens a search across titles, the words and the prayers
//  sung, and whatever the library is singing stands at the foot of every
//  section as a mini player. Everything here is bundled: a chapel with no
//  signal still has every chant.
//
//  Reached from the Chapel's Chant tile, Explore, and a chant's page.
//

import SwiftUI

// MARK: - ChantLibrarySection

enum ChantLibrarySection: String, CaseIterable, Identifiable {
    case today
    case seasons
    case occasions
    case types
    case learn
    case saved

    var id: String { rawValue }

    /// The strip's word
    var tab: String {
        switch self {
        case .today:     return "Today"
        case .seasons:   return "Seasons"
        case .occasions: return "Occasions"
        case .types:     return "Types"
        case .learn:     return "Learn"
        case .saved:     return "Saved"
        }
    }

    /// The masthead's title
    var title: String {
        switch self {
        case .today:     return "Chants for Today"
        case .seasons:   return "Through the Church Year"
        case .occasions: return "Chants for Occasions"
        case .types:     return "Types of Chant"
        case .learn:     return "Learn by Heart"
        case .saved:     return "Saved"
        }
    }

    /// The masthead's line beneath, when it is not the date
    var lead: String? {
        switch self {
        case .today:
            return nil
        case .seasons:
            return "Different chants belong to different seasons. Here is where we are now."
        case .occasions:
            return "Chants in the order they are sung, so you can follow along or lead a group."
        case .types:
            return "Browse by kind: short chants, hymns, feast poems, litanies and more."
        case .learn:
            return "Learn to sing a chant from memory, a step at a time."
        case .saved:
            return "Your favourite chants, the ones you have learned, and sets you have made."
        }
    }
}

// MARK: - ChantLibraryView

struct ChantLibraryView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("chantLibrary.section") private var sectionRaw = ChantLibrarySection.today.rawValue
    @State private var searching = false
    @State private var practicing: Chant?
    @State private var openOccasionID: String?
    @State private var openSetID: UUID?

    /// Where the page should come to rest once the section arriving has
    /// been laid out: the occasion's order, when Today opened one
    @State private var pendingAnchor: String?

    private var player = ChantPlayer.shared

    init() {}

    private var section: ChantLibrarySection {
        ChantLibrarySection(rawValue: sectionRaw) ?? .today
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            // The library stays where it is while the search stands over
            // it, hidden, so Cancel comes back to the same section at the
            // same place on the page
            ZStack {
                library
                    .opacity(searching ? 0 : 1)
                    .allowsHitTesting(!searching)
                    .accessibilityHidden(searching)
                if searching {
                    ChantSearchView(
                        close: { withAnimation(Motion.crossfade) { searching = false } },
                        open: openChant
                    )
                    .transition(.opacity)
                }
            }
            .animation(Motion.crossfade, value: searching)
            // The mini player stands in room of its own at the page's
            // foot, so every section's scroll, and the search's, runs on
            // beneath it and still brings its last row clear of it, at
            // any text size: laid over the page with a fixed 112 points
            // left at the foot, it was a guess at its height
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if player.isActive {
                    miniPlayer
                        .transition(reduceMotion ? AnyTransition.opacity : AnyTransition.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(reduceMotion ? Motion.crossfade : Motion.panel, value: player.isActive)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !searching {
                    Button(action: { router.pop() }) {
                        HStack(spacing: 6) {
                            AppIcon("ph-caret-left", size: 14)
                            Text("Back")
                                .font(AppFonts.bodyFont(16))
                        }
                        .foregroundColor(AppColors.gold)
                    }
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !searching {
                    Button {
                        withAnimation(Motion.crossfade) { searching = true }
                    } label: {
                        AppIcon("ph-magnifying-glass", size: 19)
                            .foregroundColor(AppColors.gold)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Search the Chant Library")

                    Button {
                        choose(.saved)
                    } label: {
                        AppIcon(section == .saved ? "ph-bookmark-simple-fill" : "ph-bookmark-simple", size: 19)
                            .foregroundColor(AppColors.gold)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Saved chants")
                }
            }
        }
        .fullScreenCover(item: $practicing) { chant in
            ChantPracticeView(chant: chant)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
                .presentationBackground(AppColors.background)
        }
    }

    // MARK: - The library

    private var library: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    masthead
                        .padding(.horizontal, 28)
                        .id("top")

                    sectionStrip(proxy: proxy)
                        .padding(.top, 22)

                    ZStack(alignment: .top) {
                        sectionBody(proxy: proxy)
                            .id(section)
                            .transition(.opacity)
                    }
                    .animation(Motion.crossfade, value: section)
                    .padding(.top, 26)

                    footer
                        .padding(.horizontal, 36)
                        .padding(.top, 44)
                        .padding(.bottom, 48)
                }
                .padding(.top, 8)
            }
            .topChromeFade()
            // A section chosen from far down the page — the glass's Saved —
            // opens at its head, under the masthead that names it; an
            // occasion opened from Today, at its order of service. On the
            // next turn, once the section arriving has been laid out.
            .onChange(of: sectionRaw) { _, _ in
                let anchor = pendingAnchor ?? "top"
                pendingAnchor = nil
                DispatchQueue.main.async {
                    withAnimation(Motion.crossfade) { proxy.scrollTo(anchor, anchor: .top) }
                }
            }
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(spacing: 12) {
            Text("CHANT LIBRARY")
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            // The ornament stands on Today's masthead alone, as the boards
            // draw it
            if section == .today {
                OrnamentDivider()
                    .frame(width: 150)
                    .transition(.opacity)
            }

            Text(section.title)
                .font(AppFonts.titleFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .accessibilityAddTraits(.isHeader)

            Text(section.lead ?? ChantDates.spelled(Date()))
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity)
        .animation(Motion.crossfade, value: section)
    }

    // MARK: - The strip of sections

    private func sectionStrip(proxy: ScrollViewProxy) -> some View {
        ScrollViewReader { strip in
            ChantSideScroll {
                HStack(spacing: 24) {
                    ForEach(ChantLibrarySection.allCases) { each in
                        let lit = each == section
                        Button {
                            choose(each)
                        } label: {
                            VStack(spacing: 6) {
                                Text(each.tab.uppercased())
                                    .font(AppFonts.labelFont(9.5))
                                    .tracking(1.5)
                                    .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                                    .lineLimit(1)
                                    .fixedSize()
                                Rectangle()
                                    .fill(AppColors.gold)
                                    .frame(width: 5, height: 5)
                                    .rotationEffect(.degrees(45))
                                    .opacity(lit ? 1 : 0)
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(QuietGlyphButtonStyle())
                        .id(each)
                        .accessibilityLabel(each.tab)
                        .accessibilityAddTraits(lit ? [.isSelected, .isButton] : [.isButton])
                    }
                }
                .padding(.horizontal, 24)
            }
            .onChange(of: section) { _, now in
                withAnimation(Motion.crossfade) { strip.scrollTo(now, anchor: .center) }
            }
            .onAppear { strip.scrollTo(section, anchor: .center) }
        }
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.18) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Browse the library")
    }

    private func choose(_ next: ChantLibrarySection) {
        guard next != section else { return }
        sectionRaw = next.rawValue
    }

    // MARK: - Sections

    @ViewBuilder
    private func sectionBody(proxy: ScrollViewProxy) -> some View {
        switch section {
        case .today:
            ChantTodaySection(
                open: openChant,
                learn: learn,
                openOccasion: { occasion in
                    openOccasionID = occasion.id
                    pendingAnchor = ChantOccasionsSection.orderAnchor
                    choose(.occasions)
                }
            )
        case .seasons:
            ChantSeasonsSection(open: openChant, learn: learn)
        case .occasions:
            ChantOccasionsSection(
                openID: $openOccasionID,
                open: openChant,
                madeSet: { set in
                    openSetID = set.id
                    choose(.saved)
                },
                reveal: { id in
                    withAnimation(Motion.crossfade) { proxy.scrollTo(id, anchor: .top) }
                }
            )
        case .types:
            ChantTypesSection(open: openChant)
        case .learn:
            ChantLearnSection(open: openChant, learn: learn)
        case .saved:
            ChantSavedSection(openSetID: $openSetID, open: openChant)
        }
    }

    // MARK: - Foot

    private var footer: some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { _ in
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.8))
                        .frame(width: 5, height: 5)
                        .rotationEffect(.degrees(45))
                }
            }
            .accessibilityHidden(true)

            Text(ChantCatalog.offlineNote)
                .font(AppFonts.readingItalicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            ChantCredit()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Mini player

    private var miniPlayer: some View {
        // Waiting between chants, the next one: its page's play goes on
        // with the set
        ChantMiniPlayer {
            openChant(player.shown)
        }
        .padding(.horizontal, 12)
        .padding(.top, 36)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                stops: [
                    .init(color: AppColors.backgroundDeep.opacity(0), location: 0),
                    .init(color: AppColors.backgroundDeep.opacity(0.92), location: 0.4),
                    .init(color: AppColors.backgroundDeep, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        )
    }

    // MARK: - Doors

    private func openChant(_ chant: Chant) {
        router.push(.chant(id: chant.id))
    }

    /// The practice, which keeps the chant as under way only once the
    /// learner takes a step in it
    private func learn(_ chant: Chant) {
        practicing = chant
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChantLibraryView()
            .environment(AppRouter())
    }
}
