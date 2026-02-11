//
//  CustomTabBar.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

enum AppTab: CaseIterable {
    case home, journal, progress, settings

    var title: String {
        switch self {
        case .home: return Constants.homeTab
        case .journal: return Constants.journalTab
        case .progress: return Constants.progressTab
        case .settings: return Constants.settingsTab
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .journal: return "book.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
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
        .padding(.bottom, 28)
        .background(
            AppColors.cardBackground
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: -5)
        )
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppColors.gold : AppColors.textSecondary)

                Text(title)
                    .font(AppFonts.bodyFont(10))
                    .tracking(1)
                    .foregroundColor(isSelected ? AppColors.gold : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.home))
}
