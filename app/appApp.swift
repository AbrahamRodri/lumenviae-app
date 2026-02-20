//
//  appApp.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  ═══════════════════════════════════════════════════════════════════════════
//  APP ENTRY POINT
//  ═══════════════════════════════════════════════════════════════════════════
//
//  This is the main entry point for the Lumen Viae iOS app.
//
//  ## What is @main?
//  The `@main` attribute tells Swift "start the app here." Every iOS app
//  needs exactly one @main - it's like the front door of a house.
//
//  ## What is App protocol?
//  `App` is a SwiftUI protocol that defines the structure of your application.
//  Think of it as a contract: "I promise to provide a `body` that contains
//  one or more Scenes."
//
//  ## What is a Scene?
//  A Scene is a container for your app's views. On iPhone, you typically
//  have one Scene (WindowGroup). On iPad/Mac, you might have multiple
//  windows, each being a separate Scene.
//
//  ## App Lifecycle
//  SwiftUI handles the app lifecycle automatically. You don't need to write
//  code for launching, backgrounding, or terminating - SwiftUI manages it.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI
import SwiftData

// MARK: - App Entry Point

/// The main entry point for the Lumen Viae application.
///
/// This struct conforms to the `App` protocol, which is required for all
/// SwiftUI applications. The `@main` attribute designates this as the
/// starting point when the app launches.
///
/// ## Structure
/// ```
/// @main           → "This is where the app starts"
/// struct appApp   → The app's main structure
/// : App           → Conforms to the App protocol
/// ```
@main
struct appApp: App {

    // MARK: - State

    /// Whether the app has finished loading (splash screen complete)
    @State private var isLaunched = false

    /// Persisted flag: true after the user completes onboarding once.
    /// Stored in UserDefaults via @AppStorage so it survives app restarts.
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // MARK: - Body

    /// The app's main content, required by the `App` protocol.
    ///
    /// Flow:
    ///   1. LaunchView (splash + image preload)
    ///   2. OnboardingView — shown once on first launch
    ///   3. ContentView — main app (all subsequent launches start here)
    private let userSettings = UserSettings.shared

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
        .modelContainer(for: [PrayerSession.self, JournalEntry.self])
    }
}
