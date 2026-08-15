//
//  ConsecrationCompletionView.swift
//  Lumen Viae
//
//  The end of the 33 days: the Act of Consecration is made.
//
//  It stands on the consecration day's own ground — the warm gold-dark
//  the last week has been building toward — rather than inverting the
//  app into a light field with dark text, which belonged to no other
//  screen and left its own copy at about 2.4:1.
//

import SwiftUI

// MARK: - ConsecrationCompletionView

struct ConsecrationCompletionView: View {

    // MARK: - Properties

    @Binding var path: [ConsecrationRoute]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sealShown = false

    // MARK: - Body

    var body: some View {
        ZStack {
            ConsecrationPhaseBackground(phase: .consecrationDay)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 50)

                    seal

                    titleSection
                        .devotionalEntrance(delay: 0.35)

                    messageSection
                        .devotionalEntrance(delay: 0.5)

                    returnButton
                        .devotionalEntrance(delay: 0.65)

                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.success, trigger: sealShown)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                sealShown = true
            }
        }
    }

    // MARK: - Seal

    private var seal: some View {
        ZStack {
            Circle()
                .fill(AppColors.gold.opacity(0.16))
                .frame(width: 132, height: 132)
                .blur(radius: 18)

            Circle()
                .fill(AppColors.goldCTAGradient)
                .frame(width: 96, height: 96)

            Circle()
                .strokeBorder(AppColors.goldLight.opacity(0.7), lineWidth: 0.5)
                .frame(width: 96, height: 96)

            AppIcon("ph-seal-check-fill", size: 44)
                .foregroundColor(AppColors.background)
        }
        .haloGlow(AppColors.gold, radius: 16, intensity: 0.3)
        // Reduce Motion keeps the seal, drops the spring
        .scaleEffect(reduceMotion || sealShown ? 1 : 0.6)
        .opacity(reduceMotion || sealShown ? 1 : 0)
        .accessibilityHidden(true)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("CONSECRATED")
                .font(AppFonts.headlineFont(32))
                .tracking(4)
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            OrnamentDivider()
                .frame(width: 170)

            Text("Totus tuus ego sum")
                .font(AppFonts.italicFont(17))
                .foregroundColor(AppColors.goldLight)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Message

    private var messageSection: some View {
        VStack(spacing: 16) {
            Text("You have made the Total Consecration to Jesus through Mary.")
                .font(AppFonts.readingFont(17))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Text("Renew it each year on this feast, and every day in your heart.")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sacredCard()
    }

    // MARK: - Return

    /// The consecration itself was the finishing act, made a screen ago.
    /// Leaving is not another one, so it goes quietly.
    private var returnButton: some View {
        QuietGoldButton(
            title: "Return to the Consecrate tab",
            size: 11,
            color: AppColors.gold
        ) {
            path.removeAll()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationCompletionView(path: .constant([]))
            .environment(ConsecrationViewModel())
    }
}
