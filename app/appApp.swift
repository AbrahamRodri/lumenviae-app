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

@main
struct appApp: App {

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
    }
}
