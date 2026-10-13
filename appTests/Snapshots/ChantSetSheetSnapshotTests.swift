//
//  ChantSetSheetSnapshotTests.swift
//  appTests
//
//  The four sheets that build a sung set, drawn from a shelf of their own
//  (never the reader's) holding one set: two chants, one of them twice.
//  The sheets that open at half height are drawn on the lower half of the
//  frame, as they stand over the page. See ScreenSnapshot.swift for how
//  to record again.
//

import SwiftUI
import Testing

@testable import app

@Suite(
    "Chant set sheet snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct ChantSetSheetSnapshotTests {

    private let shelf: ChantShelfStore
    private let set: ChantSet

    init() async {
        await ScreenSnapshot.preloadPaintings()
        let defaults = UserDefaults(suiteName: "ChantSetSheetSnapshotTests")!
        defaults.removePersistentDomain(forName: "ChantSetSheetSnapshotTests")
        shelf = ChantShelfStore(defaults: defaults)
        let made = shelf.newSet(named: "Thursday holy hour", with: "asperges_me")
        shelf.addChant("vidi_aquam", to: made.id)
        shelf.addChant("asperges_me", to: made.id)
        set = shelf.set(made.id)!
    }

    @Test func picker() {
        ScreenSnapshot.assertScreen(ChantPickerSheet(set: set, shelf: shelf), named: "chant-picker")
    }

    @Test func pause() {
        ScreenSnapshot.assertScreen(halfSheet(ChantPauseSheet(set: set, shelf: shelf)), named: "chant-pause")
    }

    @Test func newSet() {
        ScreenSnapshot.assertScreen(halfSheet(ChantNewSetSheet(shelf: shelf) { _ in }), named: "chant-new-set")
    }

    @Test func addToSet() {
        let chant = ChantCatalog.chant("asperges_me")!
        ScreenSnapshot.assertScreen(
            halfSheet(ChantAddToSetSheet(chant: chant, shelf: shelf)), named: "chant-add-to-set")
    }

    /// A sheet at its half-height detent, over the page's dark ground
    private func halfSheet(_ sheet: some View) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            sheet
                .frame(height: 440)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 38, topTrailingRadius: 38))
        }
        .background(AppColors.backgroundDeep.ignoresSafeArea())
    }
}
