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
        // Before the introduction can finish: an install that had not
        // finished it by now is new, and this version is no news to it
        WhatsNewStore.shared.decideAtLaunch()
    }

    var body: some Scene {
        WindowGroup {
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
            // The phone's Larger Text is followed up to the app's cap and
            // no further. Sheets and covers don't inherit this; each one
            // carries the same modifier on its content.
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
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
            }
        }
    }

    /// While the icon picker is disabled, devices that previously chose an
    /// alternate icon fall back to the primary one. Removing this once
    /// `AppIconPickerRows.isEnabled` is true restores their choice.
    private func resetAlternateIconIfNeeded() {
        guard !AppIconPickerRows.isEnabled,
              UIApplication.shared.alternateIconName != nil else { return }
        UIApplication.shared.setAlternateIconName(nil)
    }
}
