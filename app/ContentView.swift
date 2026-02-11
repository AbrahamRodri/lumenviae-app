//
//  ContentView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Content
                Group {
                    switch selectedTab {
                    case .home:
                        HomeView()
                    case .journal:
                        PlaceholderView(title: "Journal")
                    case .progress:
                        PlaceholderView(title: "Progress")
                    case .settings:
                        PlaceholderView(title: "Settings")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

// MARK: - Placeholder View
struct PlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.gold.opacity(0.5))

                Text(title)
                    .font(AppFonts.headlineFont(24))
                    .foregroundColor(AppColors.cream)

                Text("Coming Soon")
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
