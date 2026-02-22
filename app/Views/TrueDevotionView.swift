//
//  TrueDevotionView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  TRUE DEVOTION TO MARY - REFERENCE GUIDE
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A comprehensive reference guide displaying the key aspects, principles,
//  and ejaculatory prayers from St. Louis de Montfort's True Devotion to Mary.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - TrueDevotionView

struct TrueDevotionView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings
    @State private var expandedSections: Set<UUID> = []

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    header

                    // Introduction
                    introduction
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Sections
                    VStack(spacing: 16) {
                        ForEach(TrueDevotionData.allSections(prayerLanguage: settings.prayerLanguage)) { section in
                            SectionCard(
                                section: section,
                                isExpanded: expandedSections.contains(section.id),
                                toggleExpanded: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if expandedSections.contains(section.id) {
                                            expandedSections.remove(section.id)
                                        } else {
                                            expandedSections.insert(section.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 36))
                .foregroundColor(AppColors.gold)
                .padding(.top, 24)

            Text("True Devotion to Mary")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            Text("St. Louis de Montfort")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.gold.opacity(0.8))

            Divider()
                .background(AppColors.gold.opacity(0.3))
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Introduction

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About This Devotion")
                .font(AppFonts.headlineFont(18))
                .foregroundColor(AppColors.gold)

            Text("""
True Devotion to Mary is a total consecration to Jesus Christ through the hands of Mary. St. Louis de Montfort describes it as the "shortest, easiest, surest, and most perfect" way to become a saint.

This devotion consists in giving ourselves entirely to Mary, in order to belong entirely to Jesus through her. It is a complete gift of self - body, soul, and all spiritual goods - both present and future.
""")
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - SectionCard

struct SectionCard: View {
    let section: DevotionSection
    let isExpanded: Bool
    let toggleExpanded: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: toggleExpanded) {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.gold)
                        .frame(width: 28)

                    Text(section.title)
                        .font(AppFonts.headlineFont(17))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.gold.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
                .background(AppColors.cardBackground)
                .cornerRadius(12)
            }

            // Section Content
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(section.items) { item in
                        DevotionItemView(item: item)
                    }
                }
                .padding(.top, 12)
            }
        }
    }
}

// MARK: - DevotionItemView

struct DevotionItemView: View {
    let item: DevotionItem
    @Environment(UserSettings.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(AppFonts.headlineFont(16))
                .foregroundColor(AppColors.gold.opacity(0.9))

            formattedContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.cardBackground.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var formattedContent: some View {
        let lines = item.content.components(separatedBy: "\n")

        // Check if this is a bilingual prayer (both or latinUnderEnglish)
        let isBilingual = settings.prayerLanguage == .both || settings.prayerLanguage == .latinUnderEnglish

        if isBilingual {
            // Check if this is The Little Crown (special versicle format)
            if item.title == "The Little Crown" {
                formatLittleCrownBilingual(lines)
            } else {
                // Regular prayers: line-by-line alternating format
                formatRegularBilingualPrayer(lines)
            }
        } else {
            // Single language - display normally
            Text(item.content)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Format The Little Crown with versicle pairs
    @ViewBuilder
    private func formatLittleCrownBilingual(_ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if !trimmed.isEmpty {
                    if trimmed.hasPrefix("V.") || trimmed.hasPrefix("R.") {
                        let isIndented = line.hasPrefix("   ")

                        // For "Latin & English": not indented = primary (Latin)
                        // For "English & Latin": not indented = primary (English)
                        // The indented lines are always secondary
                        formatVersicle(trimmed, isPrimary: !isIndented)
                    }
                }
            }
        }
    }

    /// Format regular prayers with line-by-line alternation
    @ViewBuilder
    private func formatRegularBilingualPrayer(_ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if trimmed.isEmpty {
                    // Empty line - add spacing
                    Spacer()
                        .frame(height: 4)
                } else if trimmed.contains("|||") {
                    // Line contains explicit bilingual marker
                    formatBilingualPair(trimmed)
                } else {
                    // Regular single-language line (shouldn't happen in bilingual mode, but handle it)
                    Text(trimmed)
                        .font(AppFonts.bodyFont(14))
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Format a single line containing both languages separated by |||
    @ViewBuilder
    private func formatBilingualPair(_ line: String) -> some View {
        let parts = line.components(separatedBy: "|||")

        VStack(alignment: .leading, spacing: 2) {
            if parts.count >= 1 {
                // Primary language (first part)
                Text(parts[0].trimmingCharacters(in: .whitespaces))
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if parts.count >= 2 {
                // Secondary language (second part)
                Text(parts[1].trimmingCharacters(in: .whitespaces))
                    .font(AppFonts.bodyFont(13))
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))
                    .italic()
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 8)
            }
        }
    }

    /// Parse content into language blocks separated by empty lines
    private func parseLanguageBlocks(_ lines: [String]) -> [[String]] {
        var blocks: [[String]] = []
        var currentBlock: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                // Empty line - end current block if it has content
                if !currentBlock.isEmpty {
                    blocks.append(currentBlock)
                    currentBlock = []
                }
            } else {
                currentBlock.append(trimmed)
            }
        }

        // Add final block if it has content
        if !currentBlock.isEmpty {
            blocks.append(currentBlock)
        }

        return blocks
    }

    @ViewBuilder
    private func formatVersicle(_ line: String, isPrimary: Bool) -> some View {
        if isPrimary {
            // Primary language versicle
            Text(line)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.cream.opacity(0.95))
                .padding(.leading, 8)
        } else {
            // Secondary language versicle
            Text(line)
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary.opacity(0.75))
                .italic()
                .padding(.leading, 20)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrueDevotionView()
    }
}
