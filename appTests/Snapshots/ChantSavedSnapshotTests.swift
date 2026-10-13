//
//  ChantSavedSnapshotTests.swift
//  appTests
//
//  Your Chants, drawn from a shelf of the test's own: favourites, chants
//  learned, two sets and four recent plays, held to one evening so
//  "Tonight" and "Yesterday" never move. Then the shelf with nothing on
//  it, the shelf with no sets, and the page at the app's largest text.
//  Reduce Motion is not drawn: SwiftUI will not let a test set it, and
//  the snapshots already hold every animation still.
//

import SwiftUI
import Testing

@testable import app

@Suite(
    "Your Chants snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct ChantSavedSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
    }

    /// A Monday evening in October, named in one calendar and language
    /// whatever the simulator's
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }()
    static let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 21))!
    static let clock = ChantSavedClock(now: { now }, calendar: calendar, locale: Locale(identifier: "en_US"))

    private func shelf(_ name: String, favorites: Bool = true, learned: Bool = true, sets: Bool = true,
                       recent: Bool = true) -> ChantShelfStore {
        let suite = "ChantSavedSnapshotTests.\(name)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let shelf = ChantShelfStore(defaults: defaults)
        if favorites {
            // Kept last first, so the Salve Regina leads
            for id in ["stabat_mater", "veni_creator", "adoro_te", "ave_maris_stella_feasts", "salve_regina_simple"] {
                shelf.toggleFavorite(id)
            }
        }
        if learned {
            for id in ["salve_regina_simple", "ave_verum", "pater_noster"] {
                shelf.markLearned(id)
            }
        }
        if sets {
            let hour = shelf.newSet(named: "Thursday holy hour", with: "o_salutaris")
            shelf.addChant("adoro_te", to: hour.id)
            shelf.addPause(note: "Silent prayer", seconds: 600, to: hour.id)
            shelf.addChant("tantum_ergo", to: hour.id)
            shelf.addChant("divine_praises", to: hour.id)
            let night = shelf.newSet(named: "Night prayer", with: "lucis_creator")
            shelf.addChant("salve_regina_simple", to: night.id)
        }
        if recent {
            let hour: TimeInterval = 3600
            shelf.notePlayed("tantum_ergo", at: Self.now - 20 * 24 * hour)
            shelf.notePlayed("veni_creator", at: Self.now - 3 * 24 * hour)
            shelf.notePlayed("salve_regina_simple", at: Self.now - 24 * hour)
            shelf.notePlayed("ave_maris_stella_feasts", at: Self.now - hour / 2)
        }
        return shelf
    }

    private func page(_ start: ChantSavedShelf?, shelf: ChantShelfStore) -> some View {
        NavigationStack {
            ChantSavedPage(start: start, shelf: shelf, clock: Self.clock)
        }
    }

    @Test func favourites() {
        ScreenSnapshot.assertScreen(page(.favorites, shelf: shelf("favourites")), named: "chant-saved-favourites")
    }

    @Test func startsOnLearned() {
        ScreenSnapshot.assertScreen(page(.learned, shelf: shelf("learned")), named: "chant-saved-learned")
    }

    /// No shelf named, Favourites empty: the page opens on Learned
    @Test func learnedWhenNoFavourites() {
        let view = page(nil, shelf: shelf("noFavourites", favorites: false))
        ScreenSnapshot.assertScreen(view, named: "chant-saved-no-favourites")
    }

    @Test func everythingEmpty() {
        let view = page(
            .favorites,
            shelf: shelf("empty", favorites: false, learned: false, sets: false, recent: false)
        )
        ScreenSnapshot.assertScreen(view, named: "chant-saved-empty")
    }

    @Test func noSets() {
        let view = page(.favorites, shelf: shelf("noSets", sets: false, recent: false))
        ScreenSnapshot.assertScreen(view, named: "chant-saved-no-sets")
    }

    /// Asked for at an accessibility size, the page draws at the largest
    /// the app draws its text, `DynamicTypeSize.appMaximum`
    @Test func largestAppText() {
        let view = page(.favorites, shelf: shelf("largestText"))
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            .dynamicTypeSize(.accessibility3)
        ScreenSnapshot.assertScreen(view, named: "chant-saved-largest-app-text")
    }

    /// The page's foot, held to the bottom of the glass: Learned empty
    /// while Favourites holds chants, the sets, every recent play with
    /// when it was sung, and the Words line
    @Test func foot() {
        let view = ZStack(alignment: .bottom) {
            AppColors.appGradient.ignoresSafeArea()
            ChantSavedSection(
                choice: .constant(.learned),
                shelf: shelf("foot", learned: false),
                clock: Self.clock
            )
            .padding(.bottom, 48)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .clipped()
        ScreenSnapshot.assertScreen(view, named: "chant-saved-foot")
    }
}
