//
//  appApp.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  Launch flow: LaunchView (splash + image preload) → OnboardingView
//  (first launch only) → ContentView.
//

import SwiftUI
import SwiftData
import UIKit
import UserNotifications

@main
struct appApp: App {

    @Environment(\.scenePhase) private var scenePhase

    /// Whether the app has finished loading (splash screen complete)
    @State private var isLaunched = false

    /// True after the user completes onboarding once
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    /// The step onboarding's last button named, handed to the app to take
    @State private var onboardingFirstStep: OnboardingFirstStep?

    private let userSettings = UserSettings.shared

    /// Whether this launch has asked the server for the library yet
    @State private var libraryChecked = false

    init() {
        FontRegistrar.registerBundledFonts()
        TrueDevotionLibrary.preload()
        // Before launch finishes, so a tap on the Angelus bell that
        // launched the app is heard
        UNUserNotificationCenter.current().delegate = PrayerNotificationRouter.shared
        PrayerBookStore.shared.refreshAngelusBell()
        // Once: the unlicensed chants earlier builds saved offline go,
        // whether or not the offline library is ever opened again
        OfflineContentService.retireUnlicensedChants()
        // A newer chant library kept from the server has its files
        // fetched before the next launch reads it
        LibraryContentSync.shared.onChantLibraryKept = { document in
            ChantAssetStore.shared.libraryKept(document)
        }
        // Before the introduction can finish: an install that had not
        // finished it by now is new, and this version is no news to it
        WhatsNewStore.shared.decideAtLaunch()
        // Before any editor can be open: photos picked and never saved go
        MyPrayersStore.shared.sweepUnusedPhotos()
        // The family's morning prayers, on the TestFlight build only, once
        FamilyPrayersSeed.seedIfDue()
    }

    var body: some Scene {
        WindowGroup {
            PhoneTypeSizeRoot {
            Group {
                if isLaunched {
                    if hasSeenOnboarding {
                        ContentView(onboardingFirstStep: $onboardingFirstStep)
                            .transition(.opacity)
                    } else {
                        OnboardingView { step in
                            onboardingFirstStep = step
                            FirstUseTour.shared.markDue()
                            withAnimation(.easeInOut(duration: 0.4)) {
                                hasSeenOnboarding = true
                            }
                        }
                        .transition(.opacity)
                    }
                } else {
                    LaunchView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isLaunched = true
                        }
                    }
                }
            }
            // The Spanish notice is never laid over the introduction: a new
            // reader meets it on the home page once the welcome is done,
            // ahead of the tour (ContentView.presentFirstLook), where it
            // once stood over the welcome's first slide and the tour
            // followed straight after, three introductions in a row
            .onChange(of: isLaunched) { _, launched in
                // A new install reads at the phone's own text size
                if launched, !hasSeenOnboarding {
                    userSettings.startTextSizeFromPhone(UIApplication.shared.preferredContentSizeCategory)
                }
            }
            // The phone's Larger Text is followed up to the app's cap and
            // no further. Sheets and covers don't inherit this; each one
            // carries the same modifier on its content.
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            }
        }
        .environment(userSettings)
        .modelContainer(for: [PrayerSession.self, JournalEntry.self, ConsecrationProgress.self, TrueDevotionReadingProgress.self, BookReadingProgress.self])
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                resetAlternateIconIfNeeded()
                // Fires at launch too: keeps scheduled reminders in step
                // with stored settings and OS-level permission changes.
                Task { await userSettings.refreshNotificationsWithoutPrompting() }
                // The voice picker's list, kept current the same way: a
                // voice added on the server appears on the next foreground
                Task { await NarrationVoiceCatalog.shared.refresh() }
                // A clock asleep through a suspension may wake late: the
                // prayer day must be right the moment the page is seen
                PrayerDayClock.shared.refresh()
                // The Prayer Book's words and the chant library: asked of
                // the server at launch, then once a day; a newer copy is
                // read at the next launch
                // (never while the app only hosts the tests: a hundred
                // megabytes of chant on every simulator they run on)
                if !LibraryContent.hostsTests {
                    LibraryContentSync.shared.refreshIfDue(force: !libraryChecked)
                    libraryChecked = true
                    // The chants' recordings and sheet music, on Wi-Fi,
                    // taking up whatever a run before could not finish
                    ChantAssetStore.shared.syncInBackground()
                    ChantAssetStore.shared.watchConnection()
                }
            }
        }
    }

    /// While the icon picker is disabled, devices that previously chose an
    /// alternate icon fall back to the primary one. Removing this once
    /// `AppIconPickerRows.isEnabled` is true restores their choice.
    ///
    /// An icon the App Store sets is left alone: the gilded icon is a
    /// Product Page Optimization treatment (Abraham, 16 Nov 2026: "Yes,
    /// test this against the painting icon"), and someone who installs
    /// from the treatment's page gets the app with it already set. Put
    /// back, their icon would change on first launch under iOS's alert.
    private func resetAlternateIconIfNeeded() {
        guard !AppIconPickerRows.isEnabled,
              let name = UIApplication.shared.alternateIconName,
              !Self.storeTestIcons.contains(name) else { return }
        UIApplication.shared.setAlternateIconName(nil)
    }

    /// Alternate icons in the binary for an App Store product page test,
    /// never offered by the picker and never reset at launch
    static let storeTestIcons: Set<String> = ["AppIconGilded"]
}
