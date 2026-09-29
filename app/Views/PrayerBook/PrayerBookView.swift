//
//  PrayerBookView.swift
//  Lumen Viae
//
//  The Prayer Book's title page. It opens, as the Office does, on the
//  hour it is: Morning Prayers until eleven, the Angelus through the
//  noon and evening bells, Night Prayers after dark — lit, with the
//  page's one gold act to pray it. Beneath it the day's three hours
//  stand on one line, then the orders kept for an occasion (before Mass,
//  after Confession, at table), Our Lady's prayers led by the antiphon
//  the season sings, the reader's own ribbons, and the book's contents.
//

import SwiftUI

struct PrayerBookView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    private var store = PrayerBookStore.shared

    @State private var now = Date()
    @State private var query = ""
    @FocusState private var searching: Bool

    private static let contentsAnchor = "contents"

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollViewReader { proxy in
            page
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // The book's most common errand is one prayer by
                        // name, and its field stands at the foot of a long
                        // page; the glass goes straight there
                        Button { findAPrayer(proxy) } label: {
                            AppIcon("ph-magnifying-glass", size: 18)
                                .foregroundColor(AppColors.gold)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(QuietGlyphButtonStyle())
                        .accessibilityLabel("Find a prayer")
                    }
                }
        }
    }

    private func findAPrayer(_ proxy: ScrollViewProxy) {
        withAnimation(Motion.ease(0.45)) {
            proxy.scrollTo(Self.contentsAnchor, anchor: UnitPoint(x: 0.5, y: 0.08))
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            searching = true
        }
    }

    private var page: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    masthead
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .devotionalEntrance()

                    hourPlate
                        .padding(.top, 28)
                        .devotionalEntrance(delay: 0.06)

                    PrayerHoursStrip(now: now) { order in
                        router.push(.prayerOrder(id: order.id))
                    }
                    .padding(.top, 22)
                    .padding(.horizontal, 8)
                    .devotionalEntrance(delay: 0.1)

                    prayTogether
                        .padding(.top, 44)

                    ourLady
                        .padding(.top, 44)

                    ribbons
                        .padding(.top, 44)

                    contents
                        .padding(.top, 44)
                        .id(Self.contentsAnchor)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 56)
            }
            .topChromeFade()
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
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = Date() }
        }
        .onAppear { now = Date() }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(spacing: 12) {
            Text("ENCHIRIDION")
                .font(AppFonts.labelFont(9.5))
                .tracking(3.5)
                .foregroundColor(AppColors.gold)

            Text("The Prayer Book")
                .font(AppFonts.titleFont(30))
                .foregroundColor(AppColors.cream)

            OrnamentDivider()
                .frame(width: 150)

            Text("The Church's prayers for every hour and every need.")
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.cream.opacity(0.75))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - The Hour

    /// The order for the hour it is, lit, with the page's one gold act
    private var hourPlate: some View {
        let order = PrayerBook.dayOrder(at: now)
        let offered = store.wasOffered(order.id, on: now)
        let count = order.prayers(on: now).count
        let title = order.title(on: now)

        return VStack(spacing: 12) {
            HStack(spacing: 8) {
                if offered {
                    AppIcon("ph-seal-check-fill", size: 12)
                }
                Text((offered ? "Offered today" : PrayerBook.dayOrderMoment(at: now)).uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.5)
            }
            .foregroundColor(AppColors.gold)

            AppIcon(order.icon, size: 30)
                .foregroundColor(AppColors.goldLight)
                .shadow(color: AppColors.gold.opacity(0.5), radius: 10)

            Text(title)
                .font(AppFonts.titleFont(30))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)

            Text(order.detail)
                .font(AppFonts.readingItalicFont(15.5))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 290)

            GoldCTAButton(title: offered ? "Pray it again" : "Pray \(title)", glyph: .play) {
                router.push(.prayAlong(.order(order, on: now)))
            }
            .padding(.top, 8)

            QuietGoldButton(
                title: count == 1 ? "See the prayer" : "See the \(count) prayers",
                trailingIcon: "ph-caret-right"
            ) {
                router.push(.prayerOrder(id: order.id))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [AppColors.gold.opacity(0.1), AppColors.gold.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline)
        )
        .shadow(color: AppColors.gold.opacity(0.08), radius: 18)
    }

    // MARK: - Pray Together

    private var prayTogether: some View {
        VStack(alignment: .leading, spacing: 14) {
            PrayerBookSectionHeading(
                title: "Pray Together",
                note: "A few prayers said one after another, for the moments that ask for them."
            )

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(PrayerBook.occasionOrders) { order in
                    PrayerOrderTile(order: order) {
                        router.push(.prayerOrder(id: order.id))
                    }
                }
            }
        }
    }

    // MARK: - Our Lady

    private var ourLady: some View {
        let chapter = PrayerBook.ourLady
        let antiphon = PrayerBook.antiphon(on: now)
        let seasonal = PrayerBook.prayer(antiphon.prayerID)
        let others = chapter.prayers.filter { $0.id != antiphon.prayerID }

        return VStack(alignment: .leading, spacing: 14) {
            PrayerBookSectionHeading(
                title: "Our Lady",
                link: ("All \(chapter.prayerIDs.count)", { router.push(.prayerBookChapter(id: chapter.id)) })
            )

            if let seasonal {
                Button {
                    router.push(.devotionPrayer(id: seasonal.id))
                } label: {
                    MarianSeasonCard(prayer: seasonal, season: antiphon.season)
                }
                .buttonStyle(SacredCardButtonStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(others) { prayer in
                        Button {
                            router.push(.devotionPrayer(id: prayer.id))
                        } label: {
                            MarianPrayerCard(prayer: prayer)
                        }
                        .buttonStyle(SacredCardButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .padding(.horizontal, -20)
        }
    }

    // MARK: - Ribbons

    @ViewBuilder
    private var ribbons: some View {
        let kept = store.keptPrayers
        VStack(alignment: .leading, spacing: 8) {
            PrayerBookSectionHeading(title: "Your Ribbons")

            if kept.isEmpty {
                HStack(alignment: .top, spacing: 14) {
                    RibbonMark(kept: true, width: 10, restLength: 20, keptLength: 26)
                    Text("Keep a prayer with its ribbon — the silk marker at the top of any prayer's page — and it waits for you here.")
                        .font(AppFonts.readingItalicFont(14.5))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(kept.enumerated()), id: \.element.id) { i, prayer in
                        BookPrayerRow(prayer: prayer, showsRule: i < kept.count - 1) {
                            router.push(.devotionPrayer(id: prayer.id))
                        }
                    }
                }
            }
        }
        .animation(Motion.crossfade, value: store.ribbons)
    }

    // MARK: - Contents

    private var contents: some View {
        VStack(alignment: .leading, spacing: 12) {
            PrayerBookSectionHeading(title: "Contents")

            searchField

            ZStack(alignment: .top) {
                if trimmedQuery.isEmpty {
                    chapterList
                        .transition(.opacity)
                } else {
                    results
                        .transition(.opacity)
                }
            }
            .animation(Motion.crossfade, value: trimmedQuery.isEmpty)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            AppIcon("ph-magnifying-glass", size: 14)
                .foregroundColor(AppColors.gold.opacity(0.7))
            TextField(
                "",
                text: $query,
                prompt: Text("Find a prayer — Memorare, Salve, St Joseph…")
                    .foregroundColor(AppColors.textSecondary)
            )
            .font(AppFonts.readingFont(16))
            .foregroundColor(AppColors.cream)
            .tint(AppColors.gold)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .focused($searching)

            if !query.isEmpty {
                Button { query = "" } label: {
                    AppIcon("ph-x-circle", size: 15)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear")
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 46)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: AppLine.hairline)
        )
    }

    private var chapterList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PrayerBook.chapters) { chapter in
                Button {
                    router.push(.prayerBookChapter(id: chapter.id))
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text(chapter.numeral)
                                .font(AppFonts.titleFont(14))
                                .foregroundColor(AppColors.gold)
                                .frame(width: 38, alignment: .leading)

                            Text(chapter.title)
                                .font(AppFonts.readingFont(17))
                                .foregroundColor(AppColors.cream)
                                .layoutPriority(1)

                            PrayerBookDotLeader()
                                .frame(minWidth: 16)

                            Text("\(chapter.prayerIDs.count) PRAYERS")
                                .font(AppFonts.labelFont(8.5))
                                .tracking(1.5)
                                .foregroundColor(AppColors.gold.opacity(0.8))
                                .fixedSize()
                        }

                        Text(chapter.latinTitle)
                            .font(AppFonts.readingItalicFont(13))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.leading, 46)
                    }
                    .padding(.vertical, 10)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    @ViewBuilder
    private var results: some View {
        let hits = PrayerBook.search(trimmedQuery)
        if hits.isEmpty {
            Text("No prayer by that name. Try a word from it — \"mercy\", \"Joseph\", \"light\".")
                .font(AppFonts.readingItalicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(hits.enumerated()), id: \.element.id) { i, prayer in
                    BookPrayerRow(prayer: prayer, showsRule: i < hits.count - 1) {
                        router.push(.devotionPrayer(id: prayer.id))
                    }
                }
            }
        }
    }
}

// MARK: - Our Lady's cards

/// The Marian blue of the Marian Library's dogma tiles, so Our Lady's
/// prayers and her library read as one
enum PrayerBookMarian {
    static let blue = Color(hex: "2e3d66")
}

/// The antiphon the Church sings to Our Lady at the close of the day in
/// this part of the year, set large
struct MarianSeasonCard: View {
    let prayer: BookPrayer
    let season: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("OF THE SEASON")
                    .font(AppFonts.labelFont(8.5))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold)

                Text(prayer.latinTitle ?? prayer.title)
                    .font(AppFonts.titleFont(23))
                    .foregroundColor(AppColors.cream)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)

                Text(prayer.title)
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.8))

                Text("Sung at the close of the day · \(season)")
                    .font(AppFonts.readingItalicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
            AppIcon("ch-lily", size: 34)
                .foregroundColor(AppColors.gold.opacity(0.85))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(
                    colors: [PrayerBookMarian.blue, PrayerBookMarian.blue.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the prayer")
    }
}

/// One of Our Lady's prayers on the shelf: its Latin incipit large, its
/// English name beneath
struct MarianPrayerCard: View {
    let prayer: BookPrayer

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AppIcon("ch-lily", size: 15)
                .foregroundColor(AppColors.gold.opacity(0.8))

            Spacer(minLength: 6)

            Text(prayer.latinTitle ?? prayer.title)
                .font(AppFonts.headlineFont(14.5))
                .foregroundColor(AppColors.cream)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)

            if prayer.latinTitle != nil {
                Text(prayer.title)
                    .font(AppFonts.readingItalicFont(12.5))
                    .foregroundColor(AppColors.cream.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(width: 148, height: 142, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(PrayerBookMarian.blue.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrayerBookView()
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
