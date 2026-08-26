//
//  OrdoMissaeView.swift
//  Lumen Viae
//
//  The Ordo Missae — the fixed parts of the Traditional Latin Mass,
//  Asperges through the Last Gospel — served by Missale Meum and read
//  under the same prayer language preference as the daily propers.
//

import SwiftUI

struct OrdoMissaeView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings

    @State private var sections: [MissalSection] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showTextOptions = false

    private var readingFontSize: CGFloat { settings.meditationFontSize + 1 }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            content
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Missal")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showTextOptions = true
                } label: {
                    AppIcon("ph-text-aa", size: 18)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Text options")
            }
        }
        .sheet(isPresented: $showTextOptions) {
            MissalTextSizeSheet()
                .presentationDetents([.height(300)])
        }
        .task { await load() }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 22)

                if isLoading {
                    loadingState
                } else if let error = errorMessage {
                    errorState(error)
                } else if !sections.isEmpty {
                    MissalSectionsView(
                        sections: sections,
                        size: readingFontSize,
                        language: settings.prayerLanguage,
                        layout: settings.missalLayout
                    )

                    footer
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Text("THE ORDER OF MASS")
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.7))

            Text("Ordo Missae")
                .font(AppFonts.headlineFont(23))
                .foregroundColor(AppColors.cream)

            Text("The fixed prayers of the Traditional Latin Mass")
                .font(AppFonts.bodyFont(13))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var footer: some View {
        VStack(spacing: 16) {
            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 28)

            Text("Missale Romanum 1962 · texts served by Missale Meum")
                .font(AppFonts.bodyFont(11))
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 12)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack {
            ProgressView()
                .tint(AppColors.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func errorState(_ error: String) -> some View {
        VStack(spacing: 16) {
            Text(error)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            GoldCTAButton(
                title: "Try again",
                prominence: .inline,
                showsCross: false,
                fullWidth: false
            ) {
                Task { await load() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Loading

    private func load() async {
        guard sections.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await MissalAPIService.shared.fetchOrdo()
            MissalCacheService.shared.saveOrdo(fetched)
            sections = fetched
        } catch {
            // The Ordo never changes — a stored copy serves offline
            if let stored = MissalCacheService.shared.loadOrdo() {
                sections = stored
            } else {
                errorMessage = "The Order of Mass could not be reached. Check your connection and try again."
            }
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OrdoMissaeView()
    }
    .environment(UserSettings.shared)
}
