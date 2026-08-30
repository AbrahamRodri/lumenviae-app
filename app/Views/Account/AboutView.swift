//
//  AboutView.swift
//  Lumen Viae
//
//  The app's colophon — everything about the app rather than for the
//  user's practice: what Lumen Viae is, the introduction, the privacy
//  policy, help, and feedback. Reached from the Chapel day strip's ☰,
//  the way the faders reach Settings, so neither page has to be the
//  other's attic.
//

import SwiftUI

struct AboutView: View {

    @Environment(AppRouter.self) private var router

    @State private var showOnboarding = false
    @State private var showAbout = false
    @State private var showPrivacyPolicy = false
    @State private var showHelpSupport = false
    @State private var showFeedback = false

    /// Set by Help & Support's own feedback link. Presenting the form
    /// into that sheet's dismissal drops it, so it is opened from
    /// `onDismiss` instead — the same handoff the prayer tray uses.
    @State private var feedbackAfterHelp = false

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    masthead

                    ledger
                        .padding(.top, 30)

                    AccountFooter()
                        .padding(.top, 48)

                    Spacer(minLength: 120)
                }
            }
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { router.pop() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(onComplete: { showOnboarding = false })
        }
        .sheet(isPresented: $showAbout) {
            AboutSheet()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicySheet()
        }
        .sheet(isPresented: $showHelpSupport, onDismiss: {
            guard feedbackAfterHelp else { return }
            feedbackAfterHelp = false
            showFeedback = true
        }) {
            HelpSupportSheet(onGiveFeedback: {
                feedbackAfterHelp = true
                showHelpSupport = false
            })
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
        }
    }

    // MARK: - Masthead

    /// The wordmark, as the home header sets it — this page is about
    /// the app itself, so the app's own name takes the plate.
    private var masthead: some View {
        VStack(spacing: 10) {
            Text("LUMEN VIAE")
                .font(AppFonts.titleFont(26))
                .tracking(6)
                .foregroundColor(AppColors.gold)

            Text("Light of the Way")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)

            OrnamentDivider()
                .frame(width: 120)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }

    // MARK: - The doors

    private var ledger: some View {
        AccountSection(title: "About", icon: "ph-info") {
            VStack(spacing: 0) {
                ActionRow(icon: "ph-info", title: "About Lumen Viae") {
                    showAbout = true
                }

                Divider()
                    .background(AppColors.gold.opacity(0.2))

                ActionRow(icon: "ph-book-open", title: "App Introduction") {
                    showOnboarding = true
                }

                Divider()
                    .background(AppColors.gold.opacity(0.2))

                ActionRow(icon: "ph-shield", title: "Privacy Policy") {
                    showPrivacyPolicy = true
                }

                Divider()
                    .background(AppColors.gold.opacity(0.2))

                ActionRow(icon: "ph-question", title: "Help & Support") {
                    showHelpSupport = true
                }

                Divider()
                    .background(AppColors.gold.opacity(0.2))

                ActionRow(
                    icon: "ph-chat-teardrop-text",
                    title: "Send Feedback",
                    subtitle: "Report a problem or share an idea"
                ) {
                    showFeedback = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutView()
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
