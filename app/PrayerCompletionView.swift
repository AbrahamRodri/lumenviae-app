//
//  PrayerCompletionView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  PRAYER COMPLETION VIEW - CELEBRATION & SESSION RECORDING
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Displayed after completing all 5 mysteries of the Rosary.
//  Automatically records the completed prayer session to SwiftData and displays:
//  - Completion badge with checkmark
//  - Inspirational scripture quote
//  - Options to record reflection or return home
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI
import SwiftData

struct PrayerCompletionView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    let meditationSet: MeditationSet

    /// Whether the session has been recorded (to prevent duplicates)
    @State private var hasRecordedSession = false

    /// Controls the post-prayer journal editor sheet
    @State private var showingJournalEditor = false

    // Quote from MockDataService
    private var quote: (text: String, author: String) {
        MockDataService.todaysQuote
    }

    var body: some View {
        ZStack {
            // Full-screen background image
            CompletionBackgroundImage(
                gradientColors: meditationSet.mysteryCategory?.gradientColors ?? []
            )

            // Content overlay
            VStack(spacing: 0) {
                // Header
                CompletionHeader(onClose: { router.popToRoot() })

                Spacer()

                // Completion badge and title
                CompletionBadge()
                    .padding(.bottom, 24)

                // Quote card
                CompletionQuoteCard(
                    quote: quote.text,
                    author: quote.author
                )
                .padding(.horizontal, 20)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    // Record Devotion (Journal) - Primary
                    Button(action: { showingJournalEditor = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.line")
                                .font(.system(size: 18))

                            Text("RECORD DEVOTION")
                                .font(AppFonts.bodyFont(16))
                                .tracking(2)
                        }
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppColors.goldLight)
                        .cornerRadius(30)
                    }

                    // Return Home - Secondary
                    Button(action: { router.popToRoot() }) {
                        Text("RETURN HOME")
                            .font(AppFonts.bodyFont(16))
                            .tracking(2)
                            .foregroundColor(AppColors.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            recordPrayerSession()
        }
        .sheet(isPresented: $showingJournalEditor) {
            JournalEntryEditorView(
                category: meditationSet.mysteryCategory,
                mysteryTitle: nil,
                mysteryIndex: nil,
                isMidPrayer: false
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    /// Records the completed prayer session to SwiftData.
    private func recordPrayerSession() {
        guard !hasRecordedSession else { return }
        guard let category = meditationSet.mysteryCategory else { return }

        let session = PrayerSession(
            category: category,
            completedAt: Date(),
            meditationType: meditationSet.name
        )
        modelContext.insert(session)
        hasRecordedSession = true
    }
}

// MARK: - Background Image

struct CompletionBackgroundImage: View {
    var gradientColors: [Color] = []

    var body: some View {
        ZStack {
            // Base gradient with category colors if available
            LinearGradient(
                colors: gradientColors.isEmpty
                    ? [Color(hex: "0d0d1a"), Color(hex: "1a1a2e"), Color(hex: "0d0d1a")]
                    : gradientColors + [Color(hex: "1a1a2e"), Color(hex: "0d0d1a")],
                startPoint: .top,
                endPoint: .bottom
            )

            // Gradient overlay for text readability
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(hex: "1a1a2e").opacity(0.6),
                    Color(hex: "1a1a2e").opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Header

struct CompletionHeader: View {
    var onClose: () -> Void = {}

    var body: some View {
        HStack {
            Text("LUMEN VIAE")
                .font(AppFonts.bodyFont(12))
                .tracking(4)
                .foregroundColor(AppColors.cream.opacity(0.8))

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.gold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Completion Badge

struct CompletionBadge: View {
    var body: some View {
        VStack(spacing: 16) {
            // Checkmark circle
            ZStack {
                Circle()
                    .strokeBorder(AppColors.gold.opacity(0.6), lineWidth: 1)
                    .frame(width: 56, height: 56)

                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.gold)
            }

            // Title
            VStack(spacing: 4) {
                Text("THE ROSARY")
                    .font(AppFonts.headlineFont(28))
                    .foregroundColor(AppColors.gold)

                Text("IS COMPLETED")
                    .font(AppFonts.headlineFont(28))
                    .foregroundColor(AppColors.gold)
            }
        }
    }
}

// MARK: - Quote Card

struct CompletionQuoteCard: View {
    let quote: String
    let author: String

    var body: some View {
        VStack(spacing: 16) {
            // Opening quote mark
            Text("\u{201C}")
                .font(.system(size: 48, weight: .light, design: .serif))
                .foregroundColor(AppColors.gold.opacity(0.5))
                .offset(y: 10)

            // Quote text
            Text(quote)
                .font(AppFonts.italicFont(18))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            // Author with decorative lines
            HStack(spacing: 12) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.5))
                    .frame(width: 24, height: 1)

                Text(author.uppercased())
                    .font(AppFonts.bodyFont(12))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.5))
                    .frame(width: 24, height: 1)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.background.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    PrayerCompletionView(meditationSet: MockDataService.meditationSet(for: .joyful))
        .environment(AppRouter())
}
