//
//  ConsecrationCompletionView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION COMPLETION VIEW - DAY 34 CELEBRATION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Shown after completing Day 34 - the Act of Consecration.
//  Celebrates the user's completion of the 33-Day journey.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - ConsecrationCompletionView

struct ConsecrationCompletionView: View {

    // MARK: - Properties

    @Binding var path: NavigationPath

    @State private var showConfetti: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "#D4AF37"),
                    Color(hex: "#E8C547"),
                    Color(hex: "#D4AF37"),
                    AppColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)

                    // Celebration Icon
                    celebrationIcon

                    // Title
                    titleSection

                    // Message
                    messageSection

                    // Stats
                    statsSection

                    // Return Button
                    returnButton

                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                showConfetti = true
            }
        }
    }

    // MARK: - Celebration Icon

    private var celebrationIcon: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(AppColors.goldLight.opacity(0.3))
                .frame(width: 140, height: 140)
                .blur(radius: 20)

            // Inner circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.cream, AppColors.goldLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)

            // Icon
            Image(systemName: "seal.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.gold)
        }
        .scaleEffect(showConfetti ? 1.0 : 0.5)
        .opacity(showConfetti ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("CONSECRATED")
                .font(AppFonts.headlineFont(32))
                .tracking(4)
                .foregroundColor(AppColors.background)

            Text("Total Consecration Complete")
                .font(AppFonts.italicFont(18))
                .foregroundColor(AppColors.background.opacity(0.8))
        }
        .opacity(showConfetti ? 1.0 : 0.0)
        .offset(y: showConfetti ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: showConfetti)
    }

    // MARK: - Message

    private var messageSection: some View {
        VStack(spacing: 16) {
            Text("You have completed the 33-Day Total Consecration to Jesus through Mary.")
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.background)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("May this consecration bear fruit in your life and draw you ever closer to Christ through the intercession of the Blessed Virgin Mary.")
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.background.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cream.opacity(0.2))
        )
        .opacity(showConfetti ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: showConfetti)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 24) {
            statItem(value: "34", label: "Days")
            statItem(value: "4", label: "Phases")
            statItem(value: "1", label: "Consecration")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background.opacity(0.3))
        )
        .opacity(showConfetti ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(0.8), value: showConfetti)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFonts.headlineFont(28))
                .foregroundColor(AppColors.cream)

            Text(label)
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.cream.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Return Button

    private var returnButton: some View {
        Button {
            // Return to the root of the consecration tab
            path.removeLast(path.count)
        } label: {
            HStack {
                Image(systemName: "house.fill")

                Text("Return Home")
                    .font(AppFonts.headlineFont(16))
            }
            .foregroundColor(AppColors.gold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.background)
            )
        }
        .opacity(showConfetti ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(1.0), value: showConfetti)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationCompletionView(path: .constant(NavigationPath()))
            .environment(ConsecrationViewModel())
    }
}
