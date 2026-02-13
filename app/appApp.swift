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

    // MARK: - Body

    /// The app's main content, required by the `App` protocol.
    ///
    /// `body` returns a `Scene` - in this case, a `WindowGroup` which
    /// represents the main window of our app. WindowGroup automatically
    /// handles creating windows on different platforms (iPhone, iPad, Mac).
    ///
    /// ## What's happening here:
    /// 1. `WindowGroup` creates the app's window
    /// 2. `ContentView()` is placed inside as the root view
    /// 3. SwiftUI handles all the rendering and lifecycle
    ///
    /// ## some Scene
    /// The `some` keyword means "returns something that conforms to Scene,
    /// but we won't specify exactly what type." This is called an "opaque
    /// return type" and is common in SwiftUI.
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: PrayerSession.self)
    }
}
