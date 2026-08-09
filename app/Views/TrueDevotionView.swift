//
//  TrueDevotionView.swift
//  Lumen Viae
//
//  A comprehensive reference guide displaying the key aspects, principles,
//  and ejaculatory prayers from St. Louis de Montfort's True Devotion to Mary.
//

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
                        .devotionalEntrance()

                    // Introduction
                    introduction
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .devotionalEntrance(delay: 0.08)

                    // Read the complete book
                    readFullBookCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .devotionalEntrance(delay: 0.12)

                    // Words of the saint (tappable, cycles quotes)
                    MontfortQuoteCard()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                        .devotionalEntrance(delay: 0.16)

                    // Sections
                    VStack(spacing: 16) {
                        ForEach(Array(TrueDevotionData.allSections(prayerLanguage: settings.prayerLanguage).enumerated()), id: \.element.id) { index, section in
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
                            .devotionalEntrance(delay: 0.2 + Double(index) * 0.06)
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
                        AppIcon("ph-caret-left", size: 14)
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
            AppIcon("ph-crown-fill", size: 36)
                .foregroundColor(AppColors.gold)
                .breathingGlow(AppColors.gold)
                .padding(.top, 24)

            Text("True Devotion to Mary")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            Text("St. Louis de Montfort")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.gold.opacity(0.8))

            OrnamentDivider()
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

            DropCapText(
                text: "True Devotion to Mary is a total consecration to Jesus Christ through the hands of Mary. St. Louis de Montfort describes it as an easy, short, perfect, and secure way to union with Our Lord — the path by which we become saints.",
                bodySize: 15
            )

            Text("This devotion consists in giving ourselves entirely to Mary, in order to belong entirely to Jesus through her. It is a complete gift of self — body, soul, and all spiritual goods — both present and future, without reserve, and forever.")
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
        .overlay(OrnateCornersOverlay(inset: 8, length: 12, opacity: 0.4))
    }
}

// MARK: - Read Full Book Card

extension TrueDevotionView {

    /// Entry into the complete Faber translation with saved reading progress
    private var readFullBookCard: some View {
        NavigationLink {
            TrueDevotionReaderView()
        } label: {
            HStack(spacing: 14) {
                AppIcon("ph-book-open-fill", size: 24)
                    .foregroundColor(AppColors.background)

                VStack(alignment: .leading, spacing: 2) {
                    Text("READ THE FULL BOOK")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.background.opacity(0.7))

                    Text("The complete text, chapter by chapter")
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.background)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                AppIcon("ph-caret-right", size: 16)
                    .foregroundColor(AppColors.background.opacity(0.7))
            }
            .padding(16)
            .goldCTABackground()
        }
        .buttonStyle(SacredCardButtonStyle())
    }
}

// MARK: - MontfortQuoteCard

/// A tappable card that cycles through well-known lines of St. Louis
/// de Montfort with a gentle cross-fade. Tap to hear another word.
private struct MontfortQuoteCard: View {

    private struct SaintQuote {
        let text: String
        let source: String
    }

    private static let quotes: [SaintQuote] = [
        SaintQuote(
            text: "It was through the Blessed Virgin Mary that Jesus Christ came into the world, and it is also through her that He must reign in the world.",
            source: "True Devotion, n. 1"
        ),
        SaintQuote(
            text: "God the Father gathered all the waters together and called them the seas; He gathered all His graces together and called them Mary.",
            source: "True Devotion, n. 23"
        ),
        SaintQuote(
            text: "Mary is the safest, easiest, shortest and most perfect way of approaching Jesus.",
            source: "True Devotion, n. 55"
        ),
        SaintQuote(
            text: "Happy, indeed sublimely happy, is the person to whom the Holy Spirit reveals the secret of Mary.",
            source: "The Secret of Mary, n. 20"
        ),
        SaintQuote(
            text: "Totus tuus ego sum, et omnia mea tua sunt. — I am all Thine, and all that I have is Thine.",
            source: "The Formula of Consecration"
        )
    ]

    @State private var index: Int = 0

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.45)) {
                index = (index + 1) % Self.quotes.count
            }
        } label: {
            VStack(spacing: 10) {
                Text("WORDS OF THE SAINT")
                    .font(AppFonts.labelFont(10))
                    .tracking(3)
                    .foregroundColor(AppColors.gold.opacity(0.7))

                Text("\u{201C}\(Self.quotes[index].text)\u{201D}")
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(index)
                    .transition(.opacity)

                Text("— \(Self.quotes[index].source)")
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .id("src\(index)")
                    .transition(.opacity)

                HStack(spacing: 5) {
                    ForEach(0..<Self.quotes.count, id: \.self) { i in
                        Circle()
                            .fill(i == index ? AppColors.gold : AppColors.gold.opacity(0.25))
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.cardBackground.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 0.5)
            )
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityHint("Tap to read another quote")
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
                    AppIcon(section.icon, size: 20)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 28)

                    Text(section.title)
                        .font(AppFonts.headlineFont(17))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    AppIcon("ph-caret-right", size: 14)
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
            // All prayers use the same line-by-line alternating format with ||| separator
            formatRegularBilingualPrayer(lines)
        } else {
            // Single language - display normally
            Text(item.content)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrueDevotionView()
    }
}
