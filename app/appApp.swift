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

@main
struct appApp: App {

    @Environment(\.scenePhase) private var scenePhase

    /// Whether the app has finished loading (splash screen complete)
    @State private var isLaunched = false

    /// True after the user completes onboarding once
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private let userSettings = UserSettings.shared

    init() {
        FontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            if isLaunched {
                if hasSeenOnboarding {
                    ContentView()
                        .transition(.opacity)
                } else {
                    OnboardingView {
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
        .environment(userSettings)
        .modelContainer(for: [PrayerSession.self, JournalEntry.self, ConsecrationProgress.self])
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                resetAlternateIconIfNeeded()
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
