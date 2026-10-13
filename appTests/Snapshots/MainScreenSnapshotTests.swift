//
//  MainScreenSnapshotTests.swift
//  appTests
//
//  The main screens drawn from fixed data and compared with their
//  baselines, so a change to how a page looks is seen in a diff before
//  it is seen on a phone. Only pages that read nothing off the clock or
//  the network are drawn whole: home, the Chapel and the Prayers tab
//  name the day and the hour, so home is drawn as its mysteries
//  sections, which are its body and depend on nothing but the schedule
//  handed to them. See ScreenSnapshot.swift for how to record again.
//

import SwiftUI
import Testing
@testable import app

@Suite(
    "Main screen snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct MainScreenSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
    }

    // MARK: - Home

    @Test func homeMysteries() {
        let page = ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                FeaturedMysteryCard(category: .sorrowful)
                    .padding(.top, 16)
                SacredMysteriesSection(
                    categories: [.joyful, .sorrowful, .glorious, .sevenSorrows]
                )
            }
        }
        .background(AppColors.appGradient.ignoresSafeArea())

        ScreenSnapshot.assertScreen(page, named: "home-mysteries")
    }

    @Test func allMysteries() {
        ScreenSnapshot.assertScreen(AllMysteriesView(), named: "all-mysteries")
    }

    // MARK: - The Rosary

    @Test func mysteriesPage() {
        let view = SelectMeditationView(
            viewModel: MeditationSelectionViewModel(
                category: .joyful,
                favorites: FavoritesService(previewFavorites: [3]),
                preloadedSets: Fixtures.joyfulSets
            )
        )
        ScreenSnapshot.assertScreen(view, named: "mysteries-page")
    }

    @Test func setPage() {
        let view = MeditationSetDetailView(
            viewModel: MeditationSetDetailViewModel(
                summary: Fixtures.sheenSummary,
                favorites: FavoritesService(previewFavorites: []),
                preloadedSet: Fixtures.sheenSet
            )
        )
        ScreenSnapshot.assertScreen(view, named: "set-page")
    }

    @Test func scripturalRosaryPage() {
        // The Seven Sorrows, which no schedule makes today's: drawn on the
        // Glorious, the Mysteries row read "Glorious · today" on a Saturday
        let view = ScripturalRosaryView(category: .sevenSorrows, form: .scriptural)
        ScreenSnapshot.assertScreen(view, named: "scriptural-rosary-page")
    }

    // MARK: - Chant search

    /// A Monday after Pentecost: the Salve Regina is the season's song
    static let chantSearchDay = Calendar(identifier: .gregorian)
        .date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 12))!

    private func chantSearch(_ query: String) -> some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()
            ChantSearchView(today: Self.chantSearchDay, query: query, close: {}, open: { _ in })
        }
    }

    @Test func chantSearchStart() {
        ScreenSnapshot.assertScreen(chantSearch(""), named: "chant-search-start")
    }

    @Test func chantSearchResults() {
        ScreenSnapshot.assertScreen(chantSearch("salve"), named: "chant-search-results")
    }

    @Test func chantSearchNothing() {
        ScreenSnapshot.assertScreen(chantSearch("zebra"), named: "chant-search-nothing")
    }

    // MARK: - The Prayer Book

    /// Prayed in silence, so the foot names no voice
    @Test func prayerPage() {
        let store = Fixtures.prayerBookStore()
        store.praysAloud = false
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "sub_tuum", store: store, date: Fixtures.day),
            named: "prayer-page"
        )
    }

    @Test func savedPrayers() {
        let store = Fixtures.prayerBookStore()
        // Saved newest first, so the page reads Memorare first
        for id in ["the_confession", "angele_dei", "litany_loreto", "anima_christi", "memorare"] {
            store.toggleRibbon(id)
        }
        ScreenSnapshot.assertScreen(PrayerBookSavedView(store: store), named: "saved-prayers")
    }

    @Test func savedPrayersEmpty() {
        ScreenSnapshot.assertScreen(
            PrayerBookSavedView(store: Fixtures.prayerBookStore()),
            named: "saved-prayers-empty"
        )
    }

    /// An order with no season of its own, prayed in silence, so the page
    /// names no voice and no day
    @Test func prayerOrderPage() {
        let store = Fixtures.prayerBookStore()
        store.praysAloud = false
        ScreenSnapshot.assertScreen(
            PrayerOrderView(orderID: "before_confession", store: store, date: Fixtures.day),
            named: "prayer-order-page"
        )
    }

    /// A topic with orders said together: the painting with the name on
    /// it, then the Pray together card, then the first prayers
    @Test func prayerTopicPage() {
        ScreenSnapshot.assertScreen(
            PrayerBookChapterView(chapterID: "mass", store: Fixtures.prayerBookStore(), date: Fixtures.day),
            named: "prayer-topic-page"
        )
    }

    /// A topic with no orders, opening straight on its prayers, with the
    /// reader's marks beside the names: one learned, one saved, and this
    /// season's song to Mary with all three, which have no room beside its
    /// name and its card picture and drop under the name
    @Test func prayerTopicMarks() {
        let store = Fixtures.prayerBookStore()
        store.setByHeart("hail_mary", true)
        store.toggleRibbon("rosary_closing_prayer")
        store.setByHeart("hail_holy_queen", true)
        store.toggleRibbon("hail_holy_queen")
        ScreenSnapshot.assertScreen(
            PrayerBookChapterView(chapterID: PrayerBook.ourLady.id, store: store, date: Fixtures.day),
            named: "prayer-topic-marks"
        )
    }

    /// At the largest text the app allows, a long name leaves its marks no
    /// room beside it, so they drop beneath the name rather than cut it:
    /// St Thomas Aquinas's prayer before Mass, learned and saved, on the
    /// first screen of Holy Mass and Communion
    @Test func prayerTopicMarksUnderName() {
        let store = Fixtures.prayerBookStore()
        store.setByHeart("aquinas_before_mass", true)
        store.toggleRibbon("aquinas_before_mass")
        ScreenSnapshot.assertScreen(
            PrayerBookChapterView(chapterID: "mass", store: store, date: Fixtures.day)
                .dynamicTypeSize(DynamicTypeSize.appMaximum),
            named: "prayer-topic-marks-under-name"
        )
    }
}

// MARK: - Fixtures

/// Sets as the server serves them, with no painting, so a page falls
/// back to its mysteries' bundled one and nothing is fetched.
private enum Fixtures {

    /// The Prayers tab's store on a defaults suite of its own, empty
    static func prayerBookStore() -> PrayerBookStore {
        let suite = "MainScreenSnapshotTests.\(UUID().uuidString)"
        return PrayerBookStore(defaults: UserDefaults(suiteName: suite)!)
    }

    /// A fixed weekday in ordinary time
    static let day = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 15))!

    static let joyfulSets: [MeditationSetSummary] = [
        MeditationSetSummary(
            id: 1, name: "Blessed Anne Catherine Emmerich", category: "joyful",
            description: "The mysteries as she was given to see them.",
            labels: ["Contemplative"]
        ),
        MeditationSetSummary(
            id: 2, name: "St. Alphonsus Liguori", category: "joyful",
            description: "Affections and resolutions from the Doctor of prayer.",
            labels: ["Saints"]
        ),
        MeditationSetSummary(
            id: 3, name: "Blessed Fulton J. Sheen", category: "joyful",
            description: "Short considerations on each mystery.",
            labels: ["Considerations"]
        ),
        MeditationSetSummary(
            id: 4, name: "The Gospel of St. Luke", category: "joyful",
            description: "The evangelist's own words for each mystery.",
            labels: ["Scriptural"]
        )
    ]

    static let sheenSummary = MeditationSetSummary(
        id: 27,
        name: "Blessed Fulton J. Sheen",
        category: "sorrowful",
        description: "Meditations on the Sorrowful Mysteries from Bishop Fulton J. Sheen",
        labels: ["Considerations"],
        author: "Bishop Fulton J. Sheen",
        source: "The Fifteen Mysteries of the Rosary"
    )

    static let sheenSet = MeditationSet(
        id: 27,
        name: sheenSummary.name,
        category: "sorrowful",
        description: sheenSummary.description,
        labels: sheenSummary.labels,
        meditations: [
            Meditation(
                id: 126,
                title: nil,
                content: "As a kind person in the face of pain seeks to relieve the sufferings of his friend, so does moral kindness in the face of evil take on the punishment which evil deserves. Every mother would willingly, if she could, bear the aches of her child.",
                author: "Bishop Fulton J. Sheen",
                source: "The Fifteen Mysteries of the Rosary",
                audioUrl: nil,
                mystery: MysteryData.sorrowful[0]
            )
        ]
    )
}
