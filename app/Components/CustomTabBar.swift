//
//  CustomTabBar.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CUSTOM TAB BAR - BOTTOM NAVIGATION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A custom tab bar that matches the app's design system.
//  Uses gold highlighting for the selected tab.
//
//  ## Why Custom Instead of SwiftUI's TabView?
//  1. Full control over appearance (colors, fonts, spacing)
//  2. Can hide during prayer flow (TabView doesn't support this easily)
//  3. Consistent with the app's elegant, dark theme
//
//  ## Components
//  - `AppTab`: Enum defining available tabs
//  - `CustomTabBar`: The container view with all tabs
//  - `TabBarItem`: Individual tab button
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - AppTab

/// Defines the available tabs in the bottom navigation.
///
/// ## CaseIterable
/// Allows iterating over all tabs with `AppTab.allCases`.
/// Used to dynamically create tab items in the bar.
///
enum AppTab: CaseIterable {
    case home
    case consecration
    case journal
    case progress
    case account

    /// Tab title text (from Constants for potential localization)
    var title: String {
        switch self {
        case .home:         return Constants.homeTab
        case .consecration: return Constants.consecrationTab
        case .journal:      return Constants.journalTab
        case .progress:     return Constants.progressTab
        case .account:      return Constants.accountTab
        }
    }

    /// SF Symbol name for the tab icon
    var icon: String {
        switch self {
        case .home:         return "house.fill"
        case .consecration: return "flame.fill"
        case .journal:      return "book.fill"
        case .progress:     return "chart.line.uptrend.xyaxis"
        case .account:      return "person.fill"
        }
    }
}

// MARK: - CustomTabBar

/// The bottom tab bar containing navigation tabs.
///
/// ## @Binding
/// `@Binding` creates a two-way connection to a value owned by a parent view.
/// When `selectedTab` changes here, the parent's value changes too.
/// When the parent changes it, this view updates automatically.
///
struct CustomTabBar: View {

    /// The currently selected tab (two-way binding to parent)
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            // Create a tab item for each case in AppTab
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarItem(
                    icon: tab.icon,
                    title: tab.title,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.top, 12)
        .background(
            AppColors.cardBackground
                .ignoresSafeArea()
                .shadow(color: Color.black.opacity(0.3), radius: 10)
        )
    }
}

// MARK: - TabBarItem

/// A single tab button in the tab bar.
///
/// Shows an icon and title, highlighted in gold when selected.
struct TabBarItem: View {

    /// SF Symbol name for the icon
    let icon: String

    /// Title text below the icon
    let title: String

    /// Whether this tab is currently selected
    let isSelected: Bool

    /// Action to perform when tapped
    let action: () -> Void

    /// Color based on selection state
    private var foregroundColor: Color {
        isSelected ? AppColors.gold : AppColors.textSecondary
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(foregroundColor)

                Text(title)
                    .font(AppFonts.bodyFont(10))
                    .tracking(1)
                    .foregroundColor(foregroundColor)
            }
            .frame(maxWidth: .infinity)  // Equal width for all tabs
        }
    }
}

// MARK: - Preview

#Preview {
    CustomTabBar(selectedTab: .constant(.home))
}
