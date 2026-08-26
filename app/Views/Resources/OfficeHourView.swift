//
//  OfficeHourView.swift
//  Lumen Viae
//
//  One canonical hour, read in full — Lauds at dawn, Compline before
//  sleep — under the same language preference and bilingual layouts as
//  the missal. The neighboring hours wait at the foot of the page, so
//  praying through the day never climbs back to the ledger.
//

import SwiftUI

struct OfficeHourView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings

    let viewModel: OfficeViewModel

    @State var hour: CanonicalHour

    @State private var office: OfficeHour?
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var showTextOptions = false

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
                        Text("Office")
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
        .task(id: hour) {
            if settings.prayerLanguage.isBilingual {
                preferredBilingual = settings.prayerLanguage
            }
            await load()
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    header
                        .id("top")
                        .padding(.bottom, 22)

                    if isLoading {
                        loadingState
                    } else if loadFailed {
                        errorState
                    } else if let office {
                        languageSelector
                            .padding(.bottom, 22)

                        OfficeSectionsView(
                            sections: office.sections,
                            size: readingFontSize,
                            language: settings.prayerLanguage,
                            layout: settings.missalLayout
                        )

                        endBlock
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .onChange(of: hour) {
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Text("\(hour.latinName) · \(viewModel.dateLabel)".uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(hour.label)
                .font(AppFonts.headlineFont(23))
                .foregroundColor(AppColors.cream)

            if let celebration = office?.celebration {
                VStack(spacing: 4) {
                    Text(celebration.title)
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if let rank = celebration.rank {
                        Text(rank.uppercased())
                            .font(AppFonts.labelFont(9))
                            .tracking(1.8)
                            .foregroundColor(AppColors.textSecondary.opacity(0.8))
                    }
                }
            }

            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    // MARK: - Language Selector

    /// English / Latin / Both, bound to the app-wide prayer language —
    /// the same control the missal and the consecration prayers use.
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

    // MARK: - End Block

    /// The neighboring hours, then the attribution the API asks every
    /// reader to carry.
    private var endBlock: some View {
        VStack(spacing: 16) {
            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 28)

            HStack {
                if let previous = hour.previous {
                    QuietGoldButton(
                        title: previous.label,
                        leadingIcon: "ph-caret-left",
                        leadingIconSize: 9,
                        size: 10,
                        color: AppColors.gold,
                        horizontalPadding: 0
                    ) {
                        hour = previous
                    }
                }

                Spacer()

                if let next = hour.next {
                    QuietGoldButton(
                        title: next.label,
                        trailingIcon: "ph-caret-right",
                        size: 10,
                        color: AppColors.gold,
                        horizontalPadding: 0
                    ) {
                        hour = next
                    }
                }
            }

            Text("Breviarium Romanum · texts served by \(office?.source.name ?? "The Divinum Officium Project")")
                .font(AppFonts.bodyFont(11))
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
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

    private var errorState: some View {
        VStack(spacing: 16) {
            Text("\(hour.label) could not be reached. Check your connection and try again.")
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
        office = nil
        isLoading = true
        loadFailed = false

        do {
            office = try await viewModel.loadHour(hour)
        } catch {
            loadFailed = true
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OfficeHourView(viewModel: OfficeViewModel(), hour: .lauds)
    }
    .environment(UserSettings.shared)
}
