//
//  ChantSetPageSnapshotTests.swift
//  appTests
//
//  A sung set's page: an occasion at rest and with a row being sung, a
//  set of the reader's own with chants, a silence and a note, an empty
//  one, a set that is gone, and the occasion at the app's largest text.
//  The player cannot be made to sing in a test, so the lit row is named
//  to the page (`ChantSetPage.Sounding`). The bar's Back, bookmark and ···
//  are not drawn here.
//

import SwiftUI
import Testing

@testable import app

@Suite(
    "Chant set page snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct ChantSetPageSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
    }

    private func shelf(_ name: String) -> ChantShelfStore {
        let suite = "ChantSetPageSnapshotTests.\(name)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return ChantShelfStore(defaults: defaults)
    }

    private func page(
        _ subject: ChantSetSubject, shelf: ChantShelfStore, sounding: ChantSetPage.Sounding? = nil
    ) -> some View {
        NavigationStack {
            ChantSetPage(subject: subject, shelf: shelf, sounding: sounding)
        }
    }

    @Test func anOccasion() {
        ScreenSnapshot.assertScreen(
            page(.occasion("sung_rosary"), shelf: shelf("occasion")), named: "chant-set-occasion")
    }

    /// The first Ave Maria ×3 sounding: step 3 of the Sung Rosary
    @Test func anOccasionBeingSung() {
        let view = page(
            .occasion("sung_rosary"), shelf: shelf("sung"),
            sounding: ChantSetPage.Sounding(origin: 3, goingOn: true))
        ScreenSnapshot.assertScreen(view, named: "chant-set-occasion-sung")
    }

    @Test func aSetOfOnesOwn() {
        let shelf = shelf("own")
        let set = shelf.newSet(named: "Thursday holy hour", with: "adoro_te")
        shelf.addPause(note: "Silent prayer", seconds: 300, to: set.id)
        shelf.addChant("ave_verum", to: set.id)
        shelf.addPause(note: "Read the Gospel of the day.", seconds: 0, to: set.id)
        shelf.addChant("salve_regina_simple", to: set.id)
        ScreenSnapshot.assertScreen(page(.own(set.id), shelf: shelf), named: "chant-set-own")
    }

    @Test func anEmptySetOfOnesOwn() {
        let shelf = shelf("empty")
        let set = shelf.newSet(named: "Night prayer")
        ScreenSnapshot.assertScreen(page(.own(set.id), shelf: shelf), named: "chant-set-own-empty")
    }

    @Test func aSetThatIsGone() {
        ScreenSnapshot.assertScreen(
            page(.own(UUID()), shelf: shelf("gone")), named: "chant-set-not-found")
    }

    @Test func anOccasionAtTheLargestText() {
        let view = page(.occasion("sung_rosary"), shelf: shelf("largest"))
            .dynamicTypeSize(DynamicTypeSize.appMaximum)
        ScreenSnapshot.assertScreen(view, named: "chant-set-occasion-xlarge")
    }
}
