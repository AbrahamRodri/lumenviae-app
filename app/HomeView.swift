//
//  HomeView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  ============================================================================
//  SWIFT UI BEGINNER'S GUIDE - HOME VIEW
//  ============================================================================
//
//  This is the main home screen of the Lumen Viae app. It demonstrates many
//  core SwiftUI concepts that you'll use throughout iOS development.
//
//  KEY CONCEPTS IN THIS FILE:
//  1. Views & the View protocol
//  2. Layout containers (ZStack, VStack, HStack, ScrollView)
//  3. View modifiers (.padding, .foregroundColor, etc.)
//  4. Computed properties
//  5. Composition (building complex UIs from smaller pieces)
//
//  COMPONENT FILES:
//  This file uses shared components from the Components/ folder:
//  - HeaderView.swift - App header with menu and notifications
//  - MysteryCard.swift - Reusable mystery category cards
//  - QuoteSection.swift - Inspirational quote display
//  - CustomTabBar.swift - Bottom navigation bar
//

import SwiftUI

// MARK: - HomeView (Main Screen)
/// The main home screen that users see when they open the app.
///
/// ## SwiftUI View Basics:
/// - Every screen/component in SwiftUI is a `struct` that conforms to `View`
/// - The `View` protocol requires ONE thing: a `body` property
/// - `body` returns "some View" - this means "some type that is a View"
///   (Swift figures out the exact type automatically)
///
/// ## How SwiftUI Builds UIs:
/// SwiftUI uses a DECLARATIVE approach - you describe WHAT you want,
/// not HOW to build it step by step. Compare:
///
/// ```swift
/// // Imperative (UIKit - the old way):
/// let label = UILabel()
/// label.text = "Hello"
/// label.textColor = .blue
/// view.addSubview(label)
///
/// // Declarative (SwiftUI - what we use):
/// Text("Hello")
///     .foregroundColor(.blue)
/// ```
struct HomeView: View {

    // MARK: Body
    /// The `body` property defines what the view looks like.
    /// This is the ONLY required property for any SwiftUI View.
    var body: some View {

        // ZStack: Layers views on top of each other (like Photoshop layers)
        // - First item = bottom layer (background)
        // - Last item = top layer (foreground)
        ZStack {

            // LAYER 1: Background color that fills the entire screen
            AppColors.background
                .ignoresSafeArea()  // Extends under the notch & home indicator

            // LAYER 2: Scrollable content on top of the background
            // ScrollView: Makes content scrollable when it's too tall for screen
            // showsIndicators: false = hides the scroll bar
            ScrollView(showsIndicators: false) {

                // VStack: Arranges children VERTICALLY (V = Vertical)
                // spacing: 0 = no automatic space between children
                // We add spacing manually with .padding() for more control
                VStack(spacing: 0) {

                    // The app header with menu, title, and bell icon
                    // (defined in Components/HeaderView.swift)
                    HeaderView()

                    // "TUESDAY PRAYER" label with decorative lines
                    DayPrayerLabel()
                        .padding(.top, 16)  // 16 points of space above

                    // The large featured mystery card
                    FeaturedMysteryCard()
                        .padding(.horizontal, 20)  // 20 points on left & right
                        .padding(.top, 16)

                    // "Sacred Mysteries" section with 4 category cards
                    SacredMysteriesSection()
                        .padding(.top, 32)

                    // Inspirational quote at the bottom
                    // (defined in Components/QuoteSection.swift)
                    QuoteSection()
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 100)  // Extra space for tab bar
                }
            }
        }
    }
}

// MARK: - Day Prayer Label
/// Shows the current day + "PRAYER" with decorative gradient lines.
///
/// ## Computed Properties:
/// A computed property calculates its value each time it's accessed.
/// Unlike stored properties (let/var with a value), computed properties
/// run code to determine their value.
///
/// ```swift
/// // Stored property (value is set once):
/// let name = "Abraham"
///
/// // Computed property (value is calculated):
/// var greeting: String {
///     return "Hello, \(name)!"  // Runs each time greeting is accessed
/// }
/// ```
struct DayPrayerLabel: View {

    // MARK: Computed Property
    /// Gets today's day name (e.g., "TUESDAY PRAYER")
    /// `private` means only this struct can access it
    private var todayLabel: String {
        // DateFormatter converts dates to/from strings
        let formatter = DateFormatter()

        // "EEEE" = full day name (Monday, Tuesday, etc.)
        // Other codes: "EEE" = Mon, "MM" = 01, "yyyy" = 2026
        formatter.dateFormat = "EEEE"

        // .now = the current date/time
        // .uppercased() = converts to ALL CAPS
        return formatter.string(from: .now).uppercased() + " PRAYER"
    }

    var body: some View {
        // HStack: Arranges children HORIZONTALLY (H = Horizontal)
        HStack(spacing: 12) {

            // Left decorative line (gradient from transparent to gold)
            Rectangle()
                .fill(
                    // LinearGradient: Smoothly transitions between colors
                    LinearGradient(
                        colors: [AppColors.gold.opacity(0), AppColors.gold],
                        startPoint: .leading,   // Start from left
                        endPoint: .trailing     // End at right
                    )
                )
                .frame(height: 1)  // 1 point tall (thin line)

            // The day label text
            Text(todayLabel)
                .font(AppFonts.bodyFont(12))
                .tracking(3)  // Letter spacing (spread letters apart)
                .foregroundColor(AppColors.gold)
                .fixedSize()  // Prevents text from wrapping to multiple lines

            // Right decorative line (gradient from gold to transparent)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gold, AppColors.gold.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Featured Mystery Card
/// The large card showing today's recommended mystery with a "Begin Prayer" button.
///
/// ## View Modifiers:
/// Modifiers change how a view looks or behaves. They're called with dot syntax
/// and return a NEW modified view (they don't change the original).
///
/// ```swift
/// Text("Hello")           // Original view
///     .bold()             // Returns a new bold text view
///     .foregroundColor(.red)  // Returns a new red text view
///     .padding()          // Returns a view with padding
/// ```
///
/// ORDER MATTERS! Each modifier wraps the previous result:
/// ```swift
/// Text("Hi")
///     .padding()          // Adds padding FIRST
///     .background(.red)   // Background includes the padding
///
/// Text("Hi")
///     .background(.red)   // Background is just around text
///     .padding()          // Padding is OUTSIDE the background
/// ```
struct FeaturedMysteryCard: View {
    var body: some View {
        // ZStack with alignment: .bottom = children align to bottom edge
        ZStack(alignment: .bottom) {

            // LAYER 1: Card background with gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "2d3a4a"),  // Lighter at top
                            Color(hex: "1a2433"),  // Medium in middle
                            Color(hex: "0f1a26")   // Darker at bottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 380)
                // .overlay adds content ON TOP of the view
                .overlay(
                    // Placeholder icon (will be replaced with actual art)
                    ZStack {
                        Image(systemName: "photo")  // SF Symbol icon
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.textSecondary.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )

            // LAYER 2: Content overlay with text and button
            VStack(spacing: 16) {

                // Category badge (pill-shaped)
                Text("SORROWFUL MYSTERIES")
                    .font(AppFonts.bodyFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.goldLight)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()  // Pill/capsule shape
                            .fill(AppColors.background.opacity(0.8))
                    )
                    .overlay(
                        Capsule()
                            // strokeBorder = outline only, not filled
                            .strokeBorder(AppColors.goldLight.opacity(0.8), lineWidth: 0.5)
                    )

                // Mystery title (split into two lines for design)
                VStack(spacing: 4) {
                    Text("The Agony in the")
                        .font(AppFonts.headlineFont(28))
                        .foregroundColor(AppColors.cream)

                    Text("Garden")
                        .font(AppFonts.headlineFont(28))
                        .foregroundColor(AppColors.cream)
                }

                // Scripture quote
                // \n = line break (new line)
                Text("\"Father, if you are willing, take this\ncup from me...\"")
                    .font(AppFonts.italicFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.9))
                    .multilineTextAlignment(.center)  // Center-align multi-line text
                    .lineSpacing(4)  // Space between lines

                // "Begin Prayer" button
                Button(action: {
                    // TODO: Add navigation to prayer screen
                    // This closure runs when button is tapped
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))

                        Text("BEGIN PRAYER")
                            .font(AppFonts.bodyFont(14))
                            .tracking(2)
                    }
                    .foregroundColor(AppColors.background)  // Dark text on light button
                    .frame(maxWidth: .infinity)  // Stretch to fill width
                    .padding(.vertical, 16)
                    .background(AppColors.goldLight)
                    .cornerRadius(30)  // Rounded corners
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.gold.opacity(0.6), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            // Gradient overlay to make text readable over image
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,  // Transparent at top
                        AppColors.background.opacity(0.7),
                        AppColors.background.opacity(0.95)  // Solid at bottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        // clipShape: Masks the view to a shape (cuts off anything outside)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        // Border around the entire card
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Sacred Mysteries Section
/// Section showing the 4 mystery categories in a 2x2 grid.
///
/// ## LazyVGrid:
/// Creates a grid layout that only renders visible items (efficient for long lists).
/// - `columns`: Defines how many columns and their sizing
/// - `GridItem(.flexible())`: Column that expands to fill available space
/// - `spacing`: Space between items
struct SacredMysteriesSection: View {
    var body: some View {
        VStack(spacing: 20) {

            // Section header row
            HStack {
                Text("Sacred Mysteries")
                    .font(AppFonts.headlineFont(22))
                    .foregroundColor(AppColors.goldLight)

                Spacer()  // Pushes "VIEW ALL" to the right edge

                Button(action: {}) {
                    Text("VIEW ALL")
                        .font(AppFonts.bodyFont(12))
                        .tracking(1)
                        .foregroundColor(AppColors.gold)
                }
            }
            .padding(.horizontal, 20)

            // 2x2 Grid of mystery cards
            // MysteryCard is defined in Components/MysteryCard.swift
            LazyVGrid(
                columns: [
                    // Two flexible columns with 16pt gap between them
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16  // Vertical space between rows
            ) {
                // Each MysteryCard is a reusable component
                // We pass different data to customize each one
                MysteryCard(
                    title: "Joyful",
                    subtitle: "The Incarnation",
                    imageName: "figure.stand",  // SF Symbol name
                    gradientColors: [Color(hex: "3d3522"), Color(hex: "2a2518")]
                )

                MysteryCard(
                    title: "Glorious",
                    subtitle: "The Resurrection",
                    imageName: "sunrise.fill",
                    gradientColors: [Color(hex: "2a3a4a"), Color(hex: "1a2a3a")]
                )

                MysteryCard(
                    title: "Luminous",
                    subtitle: "The Light",
                    imageName: "light.max",
                    gradientColors: [Color(hex: "4a3a2a"), Color(hex: "3a2a1a")]
                )

                MysteryCard(
                    title: "Seven\nSorrows",  // \n creates a line break
                    subtitle: "Mater Dolorosa",
                    imageName: "heart.fill",
                    gradientColors: [Color(hex: "3a3040"), Color(hex: "2a2030")]
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Preview
/// #Preview is a macro that creates a live preview in Xcode's canvas.
/// This lets you see your UI without running the full app on a simulator.
///
/// To see previews: Open this file and press Option+Command+Return
/// Or click the "Resume" button in the canvas panel.
#Preview {
    HomeView()
}
