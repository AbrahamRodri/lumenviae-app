//
//  CustomTabBar.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  Custom tab bar (instead of TabView) so it can match the design system
//  and hide during the prayer flow.
//
//  Layout: four tabs (Home, Consecrate, Journal, Account) plus a raised
//  "Pray" button in the bottom-right — the prime action position. It
//  starts today's Rosary directly, no selection screens. Progress has no
//  tab; it opens via the streak flame in the home header.
//

import SwiftUI

// MARK: - AppTab

/// The available tabs in the bottom navigation.
enum AppTab: CaseIterable {
    case home
    case consecration
    case journal
    case progress
    case account

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

struct CustomTabBar: View {

    @Binding var selectedTab: AppTab

    /// Starts today's Rosary directly (invoked by the raised Pray button)
    var onPrayNow: () -> Void = {}

    /// Tabs shown in the bar. Progress is reachable via the home header's
    /// streak flame instead of a tab.
    private let visibleTabs: [AppTab] = [.home, .consecration, .journal, .account]

    var body: some View {
        VStack(spacing: 0) {
            // Gold line above tab bar
            Rectangle()
                .fill(AppColors.gold.opacity(0.5))
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(visibleTabs, id: \.self) { tab in
                    TabBarItem(
                        icon: tab.icon,
                        title: tab.title,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }

                // Reserved space beneath the raised Pray button
                // (fixed height — an unconstrained Color would expand
                // vertically and stretch the whole bar)
                Color.clear
                    .frame(width: 78, height: 1)
            }
            .padding(.top, 12)
        }
        .background(
            AppColors.cardBackground
                .ignoresSafeArea()
                .shadow(color: Color.black.opacity(0.3), radius: 10)
        )
        .overlay(alignment: .topTrailing) {
            PrayNowButton(action: onPrayNow)
                .padding(.trailing, 12)
                .offset(y: -20)
        }
    }
}

// MARK: - PrayNowButton

/// The standing invitation to pray — a dark votive medallion with a gold
/// rim and Latin cross, raised out of the bar's bottom-right corner.
/// One tap starts today's Rosary (the mystery set for the current
/// weekday), skipping every selection screen.
///
/// Deliberately understated: it matches the app's dark-card / gold-line
/// language instead of competing with the gold prayer CTAs above it.
struct PrayNowButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack {
                // Faint, steady candle glow — presence, not pulsing
                Circle()
                    .fill(AppColors.gold.opacity(0.20))
                    .frame(width: 72, height: 72)
                    .blur(radius: 10)

                // Dark medallion face, lit slightly from the upper left
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "2e2e52"), AppColors.cardBackground],
                            center: UnitPoint(x: 0.35, y: 0.3),
                            startRadius: 2,
                            endRadius: 46
                        )
                    )
                    .frame(width: 62, height: 62)

                // Gold rim and inner hairline, like a struck medal
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 62, height: 62)

                Circle()
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 0.5)
                    .frame(width: 53, height: 53)

                VStack(spacing: 4) {
                    LatinCross()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.goldLight, AppColors.gold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 14, height: 20)

                    Text("PRAY")
                        .font(AppFonts.bodyFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                }
            }
            .shadow(color: Color.black.opacity(0.4), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pray today's Rosary")
    }
}

// MARK: - LatinCross

/// A Latin cross drawn by hand — SF Symbols' "cross" is the medical
/// cross, which reads as first-aid rather than faith.
struct LatinCross: Shape {
    func path(in rect: CGRect) -> Path {
        let bar = rect.width * 0.28
        let corner = CGSize(width: bar * 0.3, height: bar * 0.3)
        var path = Path()

        // Upright
        path.addRoundedRect(
            in: CGRect(x: rect.midX - bar / 2, y: rect.minY, width: bar, height: rect.height),
            cornerSize: corner
        )

        // Crossbar, set at a third of the height
        path.addRoundedRect(
            in: CGRect(x: rect.minX, y: rect.minY + rect.height * 0.3 - bar / 2, width: rect.width, height: bar),
            cornerSize: corner
        )

        return path
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
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(.home))
    }
    .background(AppColors.background)
}
