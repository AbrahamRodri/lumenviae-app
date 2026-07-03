//
//  MenuView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/13/26.
//

import SwiftUI

struct MenuView: View {
    @Binding var isPresented: Bool
    @Environment(AppRouter.self) private var router
    @State private var showTrueDevotionView = false
    @State private var showHowToPrayView = false
    @State private var showMysteriesInScriptureView = false
    @State private var showMarianLibraryView = false
    @State private var showCarloAcutisView = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appGradient
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("MENU")
                        .font(AppFonts.bodyFont(14))
                        .tracking(3)
                        .foregroundColor(AppColors.gold)

                    Spacer()

                    Button(action: { isPresented = false }) {
                        AppIcon("ph-x", size: 16)
                            .foregroundColor(AppColors.gold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.2))
                    .frame(height: 1)
                    .padding(.bottom, 24)

                // Menu Items
                VStack(alignment: .leading, spacing: 0) {
                    MenuItemButton(
                        icon: "ph-crown",
                        title: "True Devotion to Mary",
                        subtitle: "St. Louis de Montfort",
                        action: {
                            showTrueDevotionView = true
                        }
                    )

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.horizontal, 20)

                    MenuItemButton(
                        icon: "ph-book",
                        title: "How to Pray the Rosary",
                        action: {
                            showHowToPrayView = true
                        }
                    )

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.horizontal, 20)

                    MenuItemButton(
                        icon: "ph-sparkle",
                        title: "Finding the Mysteries in Scripture",
                        action: {
                            showMysteriesInScriptureView = true
                        }
                    )

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.horizontal, 20)

                    MenuItemButton(
                        icon: "ph-heart",
                        title: "Marian Theology Library",
                        action: {
                            showMarianLibraryView = true
                        }
                    )

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.horizontal, 20)

                    MenuItemButton(
                        icon: "ph-flame",
                        title: "St. Carlo Acutis",
                        subtitle: "Digital Altar",
                        action: {
                            showCarloAcutisView = true
                        }
                    )
                }

                Spacer()

                // Footer with version
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.2))
                        .frame(height: 1)

                    Text("Lumen Viae v1.0.0")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)

                    Text("Ad Majorem Dei Gloriam")
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.gold.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                }
            }
            .navigationDestination(isPresented: $showTrueDevotionView) {
                TrueDevotionView()
            }
            .navigationDestination(isPresented: $showHowToPrayView) {
                HowToPrayRosaryView()
            }
            .navigationDestination(isPresented: $showMysteriesInScriptureView) {
                MysteriesInScriptureView()
            }
            .navigationDestination(isPresented: $showMarianLibraryView) {
                MarianLibraryView()
            }
            .navigationDestination(isPresented: $showCarloAcutisView) {
                CarloAcutisView()
            }
        }
    }
}

// MARK: - MenuItem Button

struct MenuItemButton: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                AppIcon(icon, size: 18)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(AppColors.cream)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppFonts.bodyFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                AppIcon("ph-caret-right", size: 14)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    MenuView(isPresented: .constant(true))
        .environment(AppRouter())
}
