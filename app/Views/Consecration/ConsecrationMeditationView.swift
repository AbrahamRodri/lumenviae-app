//
//  ConsecrationMeditationView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION MEDITATION VIEW - IMMERSIVE DAILY SPIRITUAL READING
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Displays the day's meditation/spiritual writing in an immersive format.
//  After reading, the user continues to the journal view.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - ConsecrationMeditationView

struct ConsecrationMeditationView: View {

    // MARK: - Properties

    @Binding var path: NavigationPath

    let dayNumber: Int

    // MARK: - Computed Properties

    private var day: ConsecrationDay? {
        ConsecrationData.day(dayNumber)
    }

    private var phase: ConsecrationPhase? {
        day?.phase
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background - use app gradient
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                topBar
                    .padding(.top, 8)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 40)

                        // Title Section
                        titleSection

                        // Decorative Divider
                        decorativeDivider
                            .padding(.vertical, 24)

                        // Meditation Text
                        meditationText

                        Spacer()
                            .frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                }
                .mask(
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 30)

                        Rectangle()
                            .fill(Color.black)

                        LinearGradient(
                            colors: [.black, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)
                    }
                )

                // Bottom Controls
                bottomControls
                    .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            // Back Button
            Button {
                path.removeLast()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.cream.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppColors.cardBackground)
                    )
            }

            Spacer()

            // Label
            VStack(spacing: 4) {
                Text("DAY \(dayNumber)")
                    .font(AppFonts.bodyFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 10))
                    Text("SPIRITUAL READING")
                        .font(AppFonts.bodyFont(10))
                        .tracking(1)
                }
                .foregroundColor(AppColors.gold)
            }

            Spacer()

            // Spacer for symmetry
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(day?.meditationTitle ?? "Meditation")
                .font(AppFonts.headlineFont(24))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            if let source = day?.meditationSource {
                Text(source)
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Divider

    private var decorativeDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, AppColors.gold.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundColor(AppColors.gold.opacity(0.6))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gold.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Text

    private var meditationText: some View {
        Text(day?.meditationText ?? "")
            .font(AppFonts.bodyFont(17))
            .foregroundColor(AppColors.cream.opacity(0.92))
            .lineSpacing(10)
            .multilineTextAlignment(.leading)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Continue Button
            Button {
                path.append(ConsecrationRoute.journal(dayNumber: dayNumber))
            } label: {
                HStack(spacing: 10) {
                    Text("Continue to Journal")
                        .font(AppFonts.headlineFont(16))

                    Image(systemName: "pencil.line")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [AppColors.gold, AppColors.goldLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationMeditationView(path: .constant(NavigationPath()), dayNumber: 1)
            .environment(ConsecrationViewModel())
    }
}
