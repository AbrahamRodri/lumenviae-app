//
//  CustomTabBar.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  Custom tab bar (instead of TabView) so it can match the design system
//  and hide during the prayer flow.
//

import SwiftUI

// MARK: - AppTab

/// The available tabs in the bottom navigation.
enum AppTab: CaseIterable {
    case home
    // case consecration  // Hidden for v1.0 — feature not yet complete
    case journal
    case progress
    case account

    var title: String {
        switch self {
        case .home:         return Constants.homeTab
        // case .consecration: return Constants.consecrationTab
        case .journal:      return Constants.journalTab
        case .progress:     return Constants.progressTab
        case .account:      return Constants.accountTab
        }
    }

    /// SF Symbol name for the tab icon
    var icon: String {
        switch self {
        case .home:         return "house.fill"
        // case .consecration: return "flame.fill"
        case .journal:      return "book.fill"
        case .progress:     return "chart.line.uptrend.xyaxis"
        case .account:      return "person.fill"
        }
    }
}

// MARK: - CustomTabBar

struct CustomTabBar: View {

    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(spacing: 0) {
            // Gold line above tab bar
            Rectangle()
                .fill(AppColors.gold.opacity(0.5))
                .frame(height: 1)

            HStack(spacing: 0) {
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
        }
        .background(
            AppColors.cardBackground
                .ignoresSafeArea()
                .shadow(color: Color.black.opacity(0.3), radius: 10)
        )
    }
}

// MARK: - TabBarItem

/// A single tab button, highlighted in gold when selected.
struct TabBarItem: View {

    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

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
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    CustomTabBar(selectedTab: .constant(.home))
}
