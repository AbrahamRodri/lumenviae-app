//
//  ScreenSnapshot.swift
//  appTests
//
//  The one way a screen is drawn for a snapshot test: on an iPhone 17
//  Pro's frame, in the Candlelit theme, with the settings that change a
//  page's look held at their defaults, nothing breathing or pulsing,
//  and every animation finished.
//  The baselines are PNGs in `__Snapshots__/` beside each suite.
//
//  To record them again after a deliberate change, run the tests with
//  SNAPSHOT_TESTING_RECORD=failed (only the ones that differ) or =all:
//
//    TEST_RUNNER_SNAPSHOT_TESTING_RECORD=failed xcodebuild test ...
//
//  then look at the new images before committing them.
//

import SnapshotTesting
import SwiftUI
import Testing
import UIKit
@testable import app

enum ScreenSnapshot {

    /// The runtime the baselines were recorded on. Text is drawn a little
    /// differently from one iOS release to the next, so on another one
    /// the snapshot suites are skipped rather than failed.
    static let recordedOn = (major: 26, minor: 2)

    static var isRecordedRuntime: Bool {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return version.majorVersion == recordedOn.major
            && version.minorVersion == recordedOn.minor
    }

    static let skipReason: Comment =
        "Snapshot baselines are recorded on the iOS \(recordedOn.major).\(recordedOn.minor) simulator"

    /// iPhone 17 Pro: 402 x 874 points at 3x, as the phone draws it.
    static let iPhone17Pro = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 402, height: 874),
        traits: UITraitCollection { traits in
            traits.displayScale = 3
            // sRGB, so a wide-gamut painting is drawn the same on every run
            traits.displayGamut = .SRGB
            traits.userInterfaceStyle = .dark
            traits.userInterfaceIdiom = .phone
            traits.horizontalSizeClass = .compact
            traits.verticalSizeClass = .regular
            traits.preferredContentSizeCategory = .large
        }
    )

    private static var paintingsPreloaded = false

    /// Waits for the paintings the app preloads at launch. Until they are in
    /// `ImageCacheService` a page draws the asset as loaded, after it the
    /// re-rendered copy, and the two differ by a shade, so a suite's first
    /// snapshot would depend on which it raced.
    static func preloadPaintings() async {
        guard !paintingsPreloaded else { return }
        await ImageCacheService.shared.preloadImages()
        paintingsPreloaded = true
    }

    /// Snapshots `view` as a whole screen and compares it with its baseline.
    /// A pixel may differ by a hair of colour (antialiasing), and no more
    /// than one in ten thousand by more than that, so a changed word fails.
    static func assertScreen(
        _ view: some View,
        named name: String,
        fileID: StaticString = #fileID,
        file filePath: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let saved = DefaultLook.apply()
        defer { saved.restore() }

        let screen = view
            .environment(AppRouter())
            .environment(UserSettings.shared)
            // The gold act's breathing glow held at its steady look,
            // and every other animation finished at once
            .environment(\.drawsMotionAtRest, true)
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }

        assertSnapshot(
            of: UIHostingController(rootView: screen),
            as: screenImage,
            named: name,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }

    /// The page drawn on the phone's frame, given a moment for its
    /// `onAppear` work to land, then stored at 2x in 8-bit sRGB: a 3x
    /// wide-colour PNG of a painted page runs to 12 MB, this to a fifth.
    private static let screenImage: Snapshotting<UIViewController, UIImage> = {
        let drawn = Snapshotting<UIViewController, UIImage>.wait(
            for: 0.3,
            on: .image(on: iPhone17Pro)
        )
        return Snapshotting(
            pathExtension: "png",
            diffing: .image(precision: 0.9999, perceptualPrecision: 0.98, scale: storedScale),
            asyncSnapshot: { controller in drawn.snapshot(controller).map(stored) }
        )
    }()

    private nonisolated static let storedScale: CGFloat = 2

    private nonisolated static func stored(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = storedScale
        format.opaque = true
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

/// The settings a page is drawn with, held at their defaults for the
/// length of one snapshot and put back after, so neither the simulator's
/// own use nor another test changes what a baseline shows.
private struct DefaultLook {

    let theme: AppTheme
    let textSizeScale: Double
    let readingTextScale: Double
    let prayerImageMode: Bool
    let prayOnBeads: Bool
    let prayAloud: Bool
    let narrationVoiceSlug: String?
    let mysteryScheduleRaw: String
    let hasSeenPrayerSwipeHint: Bool
    let prayerLanguagePreference: String

    static func apply() -> DefaultLook {
        let settings = UserSettings.shared
        let saved = DefaultLook(
            theme: ThemeManager.shared.current,
            textSizeScale: settings.textSizeScale,
            readingTextScale: settings.readingTextScale,
            prayerImageMode: settings.prayerImageMode,
            prayOnBeads: settings.prayOnBeads,
            prayAloud: settings.prayAloud,
            narrationVoiceSlug: settings.narrationVoiceSlug,
            mysteryScheduleRaw: settings.mysteryScheduleRaw,
            hasSeenPrayerSwipeHint: settings.hasSeenPrayerSwipeHint,
            prayerLanguagePreference: settings.prayerLanguagePreference
        )
        ThemeManager.shared.current = .candlelit
        settings.textSizeScale = 0.5
        settings.readingTextScale = 0.4
        settings.prayerImageMode = true
        settings.prayOnBeads = true
        settings.prayAloud = false
        settings.narrationVoiceSlug = nil
        settings.mysteryScheduleRaw = MysterySchedule.traditional.rawValue
        settings.hasSeenPrayerSwipeHint = true
        settings.prayerLanguagePreference = PrayerLanguage.english.rawValue
        return saved
    }

    func restore() {
        let settings = UserSettings.shared
        ThemeManager.shared.current = theme
        settings.textSizeScale = textSizeScale
        settings.readingTextScale = readingTextScale
        settings.prayerImageMode = prayerImageMode
        settings.prayOnBeads = prayOnBeads
        settings.prayAloud = prayAloud
        settings.narrationVoiceSlug = narrationVoiceSlug
        settings.mysteryScheduleRaw = mysteryScheduleRaw
        settings.hasSeenPrayerSwipeHint = hasSeenPrayerSwipeHint
        settings.prayerLanguagePreference = prayerLanguagePreference
    }
}
