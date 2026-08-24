//
//  DailyMissalView.swift
//  Lumen Viae
//
//  The Daily Missal: the propers of the Traditional Latin Mass for any
//  day, served by Missale Meum from the 1962 Missale Romanum. A day is
//  stepped like turning pages — yesterday, today, tomorrow — and a day
//  carrying more than one Mass (Christmas) offers each.
//

import SwiftUI

struct DailyMissalView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings

    @State private var viewModel = MissalViewModel()
    @State private var showOrdo = false
    @State private var showAbout = false
    @State private var showTextOptions = false
    @State private var showLayoutChoice = false
    @State private var showCalendar = false

    /// The bilingual order restored when "Both" is re-chosen here, so a
    /// switch to Latin and back never overrides the order set in Account.
    @State private var preferredBilingual: PrayerLanguage = .both

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
                        // Not "Menu": the missal is reached from the
                        // home screen's band as well as from the menu.
                        Text("Back")
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
        // The first-open question: how should the translation read?
        // Undismissable — choosing is the only way through — and asked
        // exactly once; the Aa sheet owns the setting afterward.
        .sheet(isPresented: $showLayoutChoice) {
            MissalLayoutChoiceSheet()
                // One specimen under two toggles fits a fixed height,
                // and a fixed height means the sheet does not resize
                // underneath the very block being compared.
                .presentationDetents([.height(560)])
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showCalendar) {
            MissalCalendarSheet { chosen in
                Task { await viewModel.jump(to: chosen) }
            }
            .presentationDetents([.medium, .large])
        }
        .navigationDestination(isPresented: $showOrdo) {
            OrdoMissaeView()
        }
        .onAppear {
            if !settings.hasChosenMissalLayout {
                showLayoutChoice = true
            }
        }
        .task {
            if settings.prayerLanguage.isBilingual {
                preferredBilingual = settings.prayerLanguage
            }
            await viewModel.load()
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                dateNavigator
                    .padding(.bottom, 18)

                if viewModel.isLoading && viewModel.propers.isEmpty {
                    loadingState
                } else if let error = viewModel.errorMessage {
                    errorState(error)
                } else if let proper = viewModel.selectedProper {
                    dayContent(proper)
                } else if !viewModel.isLoading {
                    emptyState
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private func dayContent(_ proper: MissalProper) -> some View {
        if viewModel.propers.count > 1 {
            celebrationPicker
                .padding(.bottom, 16)
        }

        feastHeader(proper.info)
            .padding(.bottom, 18)

        languageSelector
            .padding(.bottom, 22)

        if let about = nonEmpty(proper.info.description) {
            aboutDisclosure(about)
                .padding(.bottom, 22)
        }

        MissalSectionsView(
            sections: proper.sections,
            size: readingFontSize,
            language: settings.prayerLanguage,
            layout: settings.missalLayout
        )

        endBlock(proper.info)
    }

    // MARK: - Date Navigator

    private var dateNavigator: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                stepButton(icon: "ph-caret-left", label: "Previous day", days: -1)

                // The date is a door to the calendar — the coming
                // feasts, and a jump to any day
                Button {
                    showCalendar = true
                } label: {
                    VStack(spacing: 3) {
                        Text("THE DAILY MISSAL")
                            .font(AppFonts.labelFont(10))
                            .tracking(2.5)
                            .foregroundColor(AppColors.gold.opacity(0.7))

                        HStack(spacing: 7) {
                            Text(viewModel.dateLabel)
                                .font(AppFonts.headlineFont(19))
                                .foregroundColor(AppColors.cream)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            AppIcon("ph-caret-down", size: 9)
                                .foregroundColor(AppColors.gold.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel("Open the calendar")

                stepButton(icon: "ph-caret-right", label: "Next day", days: 1)
            }

            if !viewModel.isToday {
                QuietGoldButton(
                    title: "Return to today",
                    leadingIcon: "ph-arrow-counter-clockwise",
                    leadingIconSize: 10,
                    size: 10
                ) {
                    Task { await viewModel.goToToday() }
                }
            }
        }
        .padding(.top, 8)
    }

    private func stepButton(icon: String, label: String, days: Int) -> some View {
        Button {
            Task { await viewModel.step(by: days) }
        } label: {
            AppIcon(icon, size: 16)
                .foregroundColor(AppColors.gold)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }

    // MARK: - Celebration Picker

    /// A day carrying more than one Mass — Christmas — offers each.
    private var celebrationPicker: some View {
        Menu {
            ForEach(Array(viewModel.propers.enumerated()), id: \.element.id) { index, proper in
                Button {
                    viewModel.selectedIndex = index
                } label: {
                    if index == viewModel.selectedIndex {
                        Label(proper.info.title, systemImage: "checkmark")
                    } else {
                        Text(proper.info.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text("\(viewModel.propers.count) Masses this day")
                    .font(AppFonts.labelFont(10))
                    .tracking(2)

                AppIcon("ph-caret-down", size: 9)
            }
            .foregroundColor(AppColors.gold.opacity(0.7))
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    // MARK: - Feast Header

    private func feastHeader(_ info: MissalInfo) -> some View {
        VStack(spacing: 10) {
            if let tempora = nonEmpty(info.tempora) {
                Text(tempora.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(info.title)
                .font(AppFonts.headlineFont(23))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            metaLine(info)

            if let commemorations = info.commemorations, !commemorations.isEmpty {
                Text("Commemoration of \(commemorations.map(\.title).joined(separator: " and "))")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }

            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }

    /// "II CLASS · RED", with the vestment color as a small mark
    @ViewBuilder
    private func metaLine(_ info: MissalInfo) -> some View {
        let vestment = info.colors?.first.flatMap { MissalVestment(rawValue: $0) }
        let parts = [info.rankLabel, vestment?.name].compactMap { $0 }

        if !parts.isEmpty {
            HStack(spacing: 7) {
                if let vestment {
                    Circle()
                        .fill(vestment.swatch)
                        .frame(width: 7, height: 7)
                }

                Text(parts.joined(separator: " · ").uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Language Selector

    /// English / Latin / Both, bound to the app-wide prayer language —
    /// the same control the consecration prayers use.
    private var languageSelector: some View {
        HStack(spacing: 6) {
            languageCapsule("English", language: .english)
            languageCapsule("Latin", language: .latin)
            languageCapsule("Both", language: .both)
        }
    }

    private func languageCapsule(_ title: String, language: PrayerLanguage) -> some View {
        let isSelected = language.isBilingual
            ? settings.prayerLanguage.isBilingual
            : settings.prayerLanguage == language

        return Button {
            guard !isSelected else { return }
            if language.isBilingual {
                settings.prayerLanguagePreference = preferredBilingual.rawValue
            } else {
                settings.prayerLanguagePreference = language.rawValue
            }
        } label: {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(1.6)
                .foregroundColor(isSelected ? AppColors.goldLight : AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(
                        isSelected ? AppColors.cardElevated : AppColors.background.opacity(0.5)
                    )
                )
                .overlay(
                    Capsule().strokeBorder(
                        AppColors.gold.opacity(isSelected ? 0.7 : 0.15),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - About

    /// The feast's explanation, behind a quiet disclosure so the propers
    /// stay one scroll away.
    private func aboutDisclosure(_ about: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAbout.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("ABOUT THIS DAY")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)

                    AppIcon(showAbout ? "ph-caret-up" : "ph-caret-down", size: 9)

                    Spacer()
                }
                .foregroundColor(AppColors.gold.opacity(0.7))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }

            if showAbout {
                ReadingText(
                    text: about,
                    size: max(14, readingFontSize - 2)
                )
            }
        }
    }

    // MARK: - End Block

    private func endBlock(_ info: MissalInfo) -> some View {
        VStack(spacing: 16) {
            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 28)

            QuietGoldButton(
                title: "The Order of Mass",
                leadingIcon: "ph-book-open",
                trailingIcon: "ph-caret-right",
                size: 10,
                color: AppColors.gold
            ) {
                showOrdo = true
            }

            VStack(spacing: 4) {
                if let tags = info.tags, !tags.isEmpty {
                    Text(tags.joined(separator: "  ·  "))
                        .font(AppFonts.bodyFont(11))
                        .foregroundColor(AppColors.textSecondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                Text("Missale Romanum 1962 · texts served by Missale Meum")
                    .font(AppFonts.bodyFont(11))
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
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
                Task { await viewModel.retry() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No Mass texts for this day.")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            QuietGoldButton(
                title: "Try again",
                leadingIcon: "ph-arrow-counter-clockwise",
                leadingIconSize: 11,
                size: 10,
                color: AppColors.gold
            ) {
                Task { await viewModel.retry() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Helpers

    private func nonEmpty(_ string: String?) -> String? {
        guard let trimmed = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DailyMissalView()
    }
    .environment(UserSettings.shared)
}
