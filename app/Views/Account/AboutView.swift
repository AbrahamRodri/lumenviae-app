//
//  AboutView.swift
//  Lumen Viae
//
//  The app's colophon — everything about the app rather than for the
//  user's practice: what Lumen Viae is, the introduction (debug builds
//  only), the privacy policy, help, and feedback. Reached from the home
//  masthead's ⓘ, beside the faders that reach Settings, so neither page
//  has to be the other's attic.
//

import SwiftUI

struct AboutView: View {

    @Environment(AppRouter.self) private var router

    @State private var showOnboarding = false

    /// The step the re-run introduction ended on, taken once it has gone
    @State private var onboardingFirstStep: OnboardingFirstStep?

    @State private var showAbout = false
    @State private var showPrivacyPolicy = false
    @State private var showSourcesCredits = false
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
                        .devotionalEntrance()

                    ledger
                        .padding(.top, 30)
                        .devotionalEntrance(delay: 0.08)

                    AccountFooter()
                        .padding(.top, 48)
                        .devotionalEntrance(delay: 0.16)

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
        // Full screen, not a sheet: the introduction is the app's first
        // face, and behind a sheet's inset top, rounded rim and drag-away
        // it read as a panel over the settings rather than the thing a
        // new reader sees. Re-running it shows what first run shows.
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
            // The introduction's last button names a first step; it is
            // taken from the root once the cover has gone, since this page
            // sits on the stack and today's Rosary only starts from home
            guard let step = onboardingFirstStep else { return }
            onboardingFirstStep = nil
            router.popToRoot()
            step.perform(with: router)
        }) {
            OnboardingView(onComplete: { step in
                onboardingFirstStep = step
                showOnboarding = false
            })
            .presentationBackground(AppColors.background)
            // A cover takes its text size from the phone, not from this
            // page, so it carries the app's cap itself
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(isPresented: $showAbout) {
            AboutSheet()
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicySheet()
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(isPresented: $showSourcesCredits) {
            SourcesCreditsSheet()
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
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
            .presentationBackground(AppColors.background)
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
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

                // The introduction is the first run's own screen, kept
                // here for development only: a reader has seen it, and a
                // door to see it again is a door they have no use for.
                #if DEBUG
                Divider()
                    .background(AppColors.gold.opacity(0.2))

                ActionRow(icon: "ph-book-open", title: "App Introduction") {
                    showOnboarding = true
                }
                #endif

                Divider()
                    .background(AppColors.gold.opacity(0.2))

                ActionRow(
                    icon: "ph-scroll",
                    title: "Sources & Credits",
                    subtitle: "The paintings, books and recordings, and where they come from"
                ) {
                    showSourcesCredits = true
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

// MARK: - Sources & Credits

/// The app's sources, in the sheet grammar: the paintings in the order
/// the Rosary prays them, then every text, recording and typeface, each
/// with its maker, edition and licence. The list is generated from
/// Tools/ContentSourcing/sources.py (`SourcesAndCredits`), so a painting
/// taken through fetch.py is credited the same day.
struct SourcesCreditsSheet: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    kicker: "Lumen Viae",
                    title: "Sources & Credits",
                    lead: "Everything in the app that is not our own writing, and the people and places it comes from. Every painting is by a painter dead more than a hundred years, and every text is in the public domain or used under an open licence."
                )

                SheetSectionLabel("The Paintings")
                    .padding(.top, 8)
                ForEach(SourcesAndCredits.paintings) { work in
                    creditRow(work)
                }

                SheetSectionLabel("Texts, Recordings and Type")
                    .padding(.top, 28)
                ForEach(SourcesAndCredits.texts) { work in
                    creditRow(work)
                }

                Text("Lumen Viae is made by one person, for the greater glory of God. If a credit here is wrong or missing, write through Send Feedback and it will be put right.")
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
                    .padding(.horizontal, SheetMetrics.gutter)
                    .padding(.top, 32)
                    .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheetGround()
    }

    /// One work: its name, its maker, where and when, and its terms
    private func creditRow(_ work: CreditedWork) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(work.title)
                .font(AppFonts.semiboldBodyFont(16))
                .foregroundColor(AppColors.cream)
            Text(work.maker)
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.cream.opacity(0.8))
            if !work.detail.isEmpty {
                Text(work.detail)
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
            }
            Text(work.licence.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(1.5)
                .foregroundColor(AppColors.gold.opacity(0.7))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SheetMetrics.gutter)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.16))
                .frame(height: AppLine.hairline)
                .padding(.horizontal, SheetMetrics.gutter)
        }
        .accessibilityElement(children: .combine)
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
