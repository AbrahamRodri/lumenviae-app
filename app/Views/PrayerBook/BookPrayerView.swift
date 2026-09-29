//
//  BookPrayerView.swift
//  Lumen Viae
//
//  One prayer of the Prayer Book on a page of its own: its chapter, its
//  name in English and in Latin, who wrote it and when, the prayer set as
//  a printed prayer book sets it, and what can be done with it — prayed
//  aloud on its own screen, kept with a ribbon, learned by heart. The
//  orders it is said in stand beneath it, so a prayer found alone leads
//  to the company it keeps.
//
//  Every door to a prayer in the app lands here (`AppRoute.devotionPrayer`).
//  The foot steps along the prayer's chapter in place, as the library's
//  readings step along their shelf.
//

import SwiftUI

struct BookPrayerView: View {

    let prayerID: String

    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings

    private var store = PrayerBookStore.shared

    /// The prayer on the page, which the foot steps along its chapter
    @State private var currentID: String
    @State private var pageOpacity: Double = 1
    @State private var showsLearn = false
    @State private var keptNote: String?
    /// The last thing the ribbon said, held while its words fade out
    @State private var lastKeptNote = " "

    init(prayerID: String) {
        self.prayerID = prayerID
        _currentID = State(initialValue: prayerID)
    }

    private var prayer: BookPrayer? {
        PrayerBook.prayer(currentID) ?? BookPrayer.bundled(currentID, origin: nil, note: nil)
    }

    /// The chapter the page belongs to: the one it was first opened in
    private var chapter: PrayerBookChapter? {
        PrayerBook.homeChapter(of: prayerID)
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            if let prayer {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 0).id("top")
                            page(prayer)
                                .opacity(pageOpacity)
                            stepper(proxy: proxy)
                                .padding(.top, 36)
                                .padding(.bottom, 48)
                        }
                    }
                    .topChromeFade()
                }
            } else {
                Text("This prayer could not be found.")
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { router.pop() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                RibbonToggle(prayerID: currentID) { kept in
                    say(kept
                        ? "Kept. It waits on the Prayer Book's first page."
                        : "The ribbon is taken out.")
                }
            }
        }
        .sheet(isPresented: $showsLearn) {
            if let prayer {
                LearnByHeartSheet(prayer: prayer)
                    .environment(settings)
                    .presentationDetents([.large])
                    .presentationBackground(AppColors.background)
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            }
        }
    }

    // MARK: - The Page

    @ViewBuilder
    private func page(_ prayer: BookPrayer) -> some View {
        VStack(spacing: 0) {
            titleBlock(prayer)
                .padding(.horizontal, 28)
                .devotionalEntrance()

            if prayer.hasLatin {
                LanguageChips(language: languageBinding)
                    .padding(.top, 22)
            }

            PrayerText(
                content: prayer.content(for: settings.prayerLanguage),
                size: max(17, settings.meditationFontSize - 1),
                alignment: .leading,
                showsDropCap: true
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .animation(Motion.crossfade, value: settings.prayerLanguagePreference)
            .devotionalEntrance(delay: 0.08)

            if let note = prayer.note {
                whenItIsSaid(note)
                    .padding(.horizontal, 28)
                    .padding(.top, 30)
            }

            acts(prayer)
                .padding(.horizontal, 24)
                .padding(.top, 30)

            ordersHolding(prayer)
                .padding(.horizontal, 28)
                .padding(.top, 34)
        }
        .padding(.top, 8)
    }

    private func titleBlock(_ prayer: BookPrayer) -> some View {
        VStack(spacing: 14) {
            if let chapter {
                Text("\(chapter.numeral) · \(chapter.title)".uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(3)
                    .foregroundColor(AppColors.gold)
            }

            OrnamentDivider()
                .frame(width: 150)

            Text(prayer.title)
                .font(AppFonts.titleFont(27))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)

            if let latin = prayer.latinTitle, latin != prayer.title {
                Text(latin)
                    .font(AppFonts.readingItalicFont(17))
                    .foregroundColor(AppColors.cream.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            if let origin = prayer.origin {
                // What the ribbon says stands in the origin's place for a
                // moment, laid over it rather than under it. Given a line
                // of its own it pushed the whole page down, and back up
                // three seconds later — under a reader scrolled to PRAY,
                // who then touched the wrong act.
                Text(origin.uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(1.8)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .opacity(keptNote == nil ? 1 : 0)
                    .overlay {
                        Text(lastKeptNote)
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.gold.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(keptNote == nil ? 0 : 1)
                            .accessibilityHidden(true)
                    }
            } else if let keptNote {
                Text(keptNote)
                    .font(AppFonts.readingItalicFont(13.5))
                    .foregroundColor(AppColors.gold.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

            if store.isByHeart(prayer.id) {
                ByHeartMark()
            }
        }
        .frame(maxWidth: .infinity)
        .animation(Motion.crossfade, value: keptNote)
    }

    /// When the prayer is said, set apart under a small rule
    private func whenItIsSaid(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("WHEN IT IS SAID")
                    .font(AppFonts.labelFont(8.5))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                Rectangle()
                    .fill(AppColors.gold.opacity(0.18))
                    .frame(height: AppLine.hairline)
            }
            Text(note)
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Pray it — the page's one gold act — learn it by heart, and, where
    /// the Church sings it, hear it sung with its score beside it
    private func acts(_ prayer: BookPrayer) -> some View {
        VStack(spacing: 6) {
            GoldCTAButton(title: "Pray", glyph: .play) {
                router.push(.prayAlong(.prayer(prayer)))
            }

            QuietGoldButton(
                title: store.isByHeart(prayer.id) ? "Say it by heart again" : "Learn it by heart",
                leadingIcon: "ph-heart",
                leadingIconSize: 12
            ) {
                showsLearn = true
            }

            // The first setting (a simple tone before a solemn one); the
            // chant's page offers the others
            if let chant = ChantCatalog.chants(forPrayer: prayer.id).first {
                QuietGoldButton(
                    title: "Sing it in chant",
                    leadingIcon: "ph-music-note",
                    leadingIconSize: 12
                ) {
                    router.push(.chant(id: chant.id))
                }
                .accessibilityHint("Opens the Gregorian chant, with its recording and its score")
            }
        }
    }

    /// "Said in: Morning Prayers · Before Mass" — the orders this prayer
    /// belongs to, each a door
    @ViewBuilder
    private func ordersHolding(_ prayer: BookPrayer) -> some View {
        let orders = PrayerBook.orders.filter { $0.prayerIDs(Date()).contains(prayer.id) }
        if !orders.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text("PRAYED TOGETHER IN")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.75))
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.18))
                        .frame(height: AppLine.hairline)
                }

                VStack(spacing: 0) {
                    ForEach(orders) { order in
                        LedgerDoorRow(title: order.title(on: Date()), note: order.occasion, icon: order.icon) {
                            router.push(.prayerOrder(id: order.id))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stepping along the chapter

    @ViewBuilder
    private func stepper(proxy: ScrollViewProxy) -> some View {
        if let chapter, let index = chapter.prayerIDs.firstIndex(of: currentID) {
            let ids = chapter.prayerIDs
            let previous = index > 0 ? PrayerBook.prayer(ids[index - 1]) : nil
            let next = index < ids.count - 1 ? PrayerBook.prayer(ids[index + 1]) : nil

            VStack(spacing: 14) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.15))
                    .frame(height: AppLine.hairline)

                HStack(alignment: .top) {
                    if let previous {
                        stepButton(previous, forward: false, proxy: proxy)
                    }
                    Spacer(minLength: 12)
                    if let next {
                        stepButton(next, forward: true, proxy: proxy)
                    }
                }

                QuietGoldButton(title: "\(chapter.title) · all \(ids.count)", trailingIcon: "ph-caret-right") {
                    router.push(.prayerBookChapter(id: chapter.id))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func stepButton(_ target: BookPrayer, forward: Bool, proxy: ScrollViewProxy) -> some View {
        Button {
            step(to: target.id, proxy: proxy)
        } label: {
            VStack(alignment: forward ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 5) {
                    if !forward { AppIcon("ph-caret-left", size: 9) }
                    Text(forward ? "NEXT" : "BEFORE")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                    if forward { AppIcon("ph-caret-right", size: 9) }
                }
                .foregroundColor(AppColors.gold.opacity(0.8))

                Text(target.title)
                    .font(AppFonts.readingFont(15.5))
                    .foregroundColor(AppColors.cream.opacity(0.9))
                    .multilineTextAlignment(forward ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 160, alignment: forward ? .trailing : .leading)
            // Hung from the top, so BEFORE and NEXT share a line when
            // one title wraps and the other does not
            .frame(minHeight: 44, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    /// Fades the page out, swaps the prayer and puts the scroll back to
    /// the top unseen, then fades in — never a flash of the old title
    private func step(to id: String, proxy: ScrollViewProxy) {
        withAnimation(.easeIn(duration: 0.14)) { pageOpacity = 0 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            currentID = id
            keptNote = nil
            proxy.scrollTo("top", anchor: .top)
            withAnimation(.easeOut(duration: 0.24)) { pageOpacity = 1 }
        }
    }

    // MARK: - Language

    /// English, Latin, or both, written to the app's prayer language —
    /// the same choice the Rosary and the Missal read
    private var languageBinding: Binding<PrayerLanguage> {
        Binding(
            get: { settings.prayerLanguage },
            set: { settings.prayerLanguagePreference = $0.rawValue }
        )
    }

    private func say(_ note: String) {
        lastKeptNote = note
        keptNote = note
        // Heard as well as seen: the words above are hidden from
        // VoiceOver, and scrolled down the page they are out of sight
        AccessibilityNotification.Announcement(note).post()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if keptNote == note { keptNote = nil }
        }
    }
}

// MARK: - Language Chips

/// ENGLISH · LATIN · BOTH, the choice a prayer book with facing pages
/// gives by being opened wider
struct LanguageChips: View {
    @Binding var language: PrayerLanguage

    /// Off where one language at a time is the point — learning by heart
    var showsBoth: Bool = true

    private enum Choice: CaseIterable {
        case english, latin, both

        var label: String {
            switch self {
            case .english: return "English"
            case .latin:   return "Latin"
            case .both:    return "Both"
            }
        }
    }

    private var chosen: Choice {
        switch language {
        case .english: return .english
        case .latin: return .latin
        case .both, .latinUnderEnglish: return .both
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Choice.allCases.filter { showsBoth || $0 != .both }, id: \.self) { choice in
                let on = choice == chosen
                Button {
                    withAnimation(Motion.settle) {
                        switch choice {
                        case .english: language = .english
                        case .latin: language = .latin
                        case .both:
                            if !language.isBilingual { language = .latinUnderEnglish }
                        }
                    }
                } label: {
                    // Side room so the names never run together at the
                    // larger text sizes, and the whole 44-point band
                    // answers a touch, not only the 32-point chip
                    Text(choice.label.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(on ? AppColors.goldLight : AppColors.gold.opacity(0.65))
                        .padding(.horizontal, 8)
                        .frame(minWidth: 74, minHeight: 32)
                        .background(
                            Capsule().fill(on ? AppColors.gold.opacity(0.16) : Color.clear)
                        )
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(choice.label)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, 4)
        .overlay(
            Capsule()
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
                .frame(height: 38)
        )
        .sensoryFeedback(.selection, trigger: chosen)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookPrayerView(prayerID: "sub_tuum")
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
