//
//  OnboardingView.swift
//  Lumen Viae
//
//  First-run tutorial shown once on initial launch.
//  Tracked via @AppStorage so it never appears again after completion.
//
//  Flow (5 slides — Headspace-style: few questions, personalized payoff):
//    1. Welcome           — what the app is
//    2. How it works      — the session flow
//    3. Intention         — "What draws you here?" (self-segmentation;
//                            creates ownership, personalizes the closing)
//    4. Daily reminder    — pick a prayer time with the value explained,
//                            which beats a cold permission prompt
//    5. Begin             — closing line personalized to the intention
//      • "Begin Prayer"                    → onComplete() → ContentView
//      • "Methods of Praying the Rosary"   → sheet (RosaryMethodsView)
//
//  Each slide's content fades in staggered (icon → title → body → buttons)
//  the first time it becomes the active page.
//

import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {

    var onComplete: () -> Void

    @State private var currentPage = 0
    @State private var showMethodsSheet = false

    /// Selected daily reminder hour on the reminder slide (nil = none picked)
    @State private var selectedReminderHour: Int? = nil

    /// Selected intention on the "What draws you here?" slide
    @State private var selectedIntention: PrayerIntention? = nil

    private let totalPages = 5

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator dots
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? AppColors.gold : AppColors.textSecondary.opacity(0.4))
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 8)

                // Slides
                TabView(selection: $currentPage) {
                    slide1.tag(0)
                    slide2.tag(1)
                    intentionSlide.tag(2)
                    reminderSlide.tag(3)
                    finalSlide.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .sheet(isPresented: $showMethodsSheet) {
            RosaryMethodsView()
        }
    }

    // MARK: - Slide 1: What the App Is

    private var slide1: some View {
        OnboardingSlideLayout(
            icon: "ch-rosary",
            iconIsGradient: true,
            title: "Your Rosary Companion",
            isActive: currentPage == 0,
            content: {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Lumen Viae is a Rosary helper — not an audio walkthrough of the entire prayer.")
                        .font(AppFonts.headlineFont(17))
                        .foregroundColor(AppColors.cream)
                        .lineSpacing(5)

                    Text("You pray the words yourself. The app keeps your place, provides a meditation for each mystery, and deepens your focus with scripture and reflection.")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("The app provides:")
                            .font(AppFonts.headlineFont(14))
                            .foregroundColor(AppColors.gold)

                        AppFeatureRow(icon: "ph-bookmark",     label: "Meditations for every mystery")
                        AppFeatureRow(icon: "ph-quotes",   label: "Scripture for each mystery — for study, not recited during prayer")
                        AppFeatureRow(icon: "ph-calendar-dots",     label: "Daily mystery auto-selected by traditional schedule")
                        AppFeatureRow(icon: "ph-book",         label: "Multiple meditation styles — General, Saint, Situational, Contemplative")
                    }
                }
                .multilineTextAlignment(.leading)
            },
            bottomContent: {
                OnboardingNextButton(label: "Next") {
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 1 }
                }
            }
        )
    }

    // MARK: - Slide 2: What the Process Is Like

    private var slide2: some View {
        OnboardingSlideLayout(
            icon: "ph-person-simple-walk",
            iconIsGradient: false,
            title: "How a Session Works",
            isActive: currentPage == 1,
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Each time you open the app, a full Rosary session flows like this:")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    VStack(spacing: 14) {
                        NumberedStepRow(number: "1", icon: "ph-calendar-dots",    title: "Today's mystery is chosen",  detail: "The traditional schedule assigns Joyful, Sorrowful, or Glorious by day. Luminous is available but not in the default rotation — you can always pick any set.")
                        NumberedStepRow(number: "2", icon: "ph-sparkle",    title: "Choose how to meditate",     detail: "General, from a Saint, Situational, or Contemplative — each style brings a different lens to the same mysteries.")
                        NumberedStepRow(number: "3", icon: "ph-book", title: "Pray 5 decades",             detail: "The app guides you through each mystery at your own pace. You pray the prayers; the app holds your place.")
                        NumberedStepRow(number: "4", icon: "ph-heart",       title: "Reflect and journal",        detail: "Close with a moment of reflection and an optional journal entry to capture what moved you.")
                    }
                }
                .multilineTextAlignment(.leading)
            },
            bottomContent: {
                OnboardingNextButton(label: "Next") {
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 2 }
                }
            }
        )
    }

    // MARK: - Slide 3: Intention ("What draws you here?")

    /// Intention presets: the enum case plus a warm detail line.
    private let intentionOptions: [(intention: PrayerIntention, detail: String)] = [
        (.peace, "Quiet moments in a busy life"),
        (.habit, "A faithful daily rhythm of prayer"),
        (.devotion, "Deepen your Marian devotion"),
        (.learning, "New to the Rosary, or returning after a while")
    ]

    private var intentionSlide: some View {
        OnboardingSlideLayout(
            icon: "ph-heart",
            iconIsGradient: true,
            title: "What Draws You Here?",
            isActive: currentPage == 2,
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Every soul comes to the Rosary for a reason. Yours shapes how we welcome you.")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    VStack(spacing: 12) {
                        ForEach(intentionOptions, id: \.intention) { option in
                            SelectableOptionRow(
                                label: option.intention.rawValue,
                                detail: option.detail,
                                isSelected: selectedIntention == option.intention
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedIntention = option.intention
                                }
                            }
                        }
                    }
                }
                .multilineTextAlignment(.leading)
            },
            bottomContent: {
                OnboardingNextButton(label: "Continue") {
                    if let intention = selectedIntention {
                        UserSettings.shared.onboardingIntention = intention.rawValue
                    }
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 3 }
                }
            }
        )
    }

    // MARK: - Slide 4: Daily Reminder

    /// Reminder presets: label, description, and hour (24h).
    private let reminderOptions: [(label: String, detail: String, hour: Int)] = [
        ("Morning", "Begin the day in prayer — 6:00 AM", 6),
        ("Midday", "The Angelus hour — 12:00 PM", 12),
        ("Evening", "Close the day in peace — 8:00 PM", 20)
    ]

    private var reminderSlide: some View {
        OnboardingSlideLayout(
            icon: "ph-bell",
            iconIsGradient: false,
            title: "A Daily Call to Prayer",
            isActive: currentPage == 3,
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    Text("A consistent hour of prayer is the surest way to make the Rosary a daily habit. When would you like to be reminded?")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    VStack(spacing: 12) {
                        ForEach(reminderOptions, id: \.hour) { option in
                            SelectableOptionRow(
                                label: option.label,
                                detail: option.detail,
                                isSelected: selectedReminderHour == option.hour
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedReminderHour = option.hour
                                }
                            }
                        }
                    }

                    Text("You can change or disable this anytime in Account.")
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }
                .multilineTextAlignment(.leading)
            },
            bottomContent: {
                VStack(spacing: 14) {
                    Button {
                        if let hour = selectedReminderHour {
                            let settings = UserSettings.shared
                            settings.reminderHour = hour
                            settings.reminderMinute = 0
                            settings.remindersEnabled = true
                        }
                        withAnimation(.easeInOut(duration: 0.3)) { currentPage = 4 }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Set Reminder")
                                .font(AppFonts.headlineFont(17))
                            AppIcon("ph-caret-right", size: 13)
                        }
                        .foregroundColor(selectedReminderHour == nil ? AppColors.textSecondary : AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Group {
                                if selectedReminderHour == nil {
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(AppColors.cardBackground)
                                } else {
                                    LinearGradient(
                                        colors: [AppColors.gold, AppColors.goldLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 30))
                                }
                            }
                        )
                    }
                    .disabled(selectedReminderHour == nil)

                    Button {
                        UserSettings.shared.remindersEnabled = false
                        withAnimation(.easeInOut(duration: 0.3)) { currentPage = 4 }
                    } label: {
                        Text("Not Now")
                            .font(AppFonts.bodyFont(15))
                            .foregroundColor(AppColors.gold)
                            .padding(.vertical, 12)
                    }
                }
            }
        )
    }

    // MARK: - Slide 5: Begin or Learn More

    /// Closing line personalized to the chosen intention —
    /// the small "made for you" payoff at the end of onboarding.
    private var personalizedClosing: String {
        switch selectedIntention {
        case .peace:
            return "May each decade bring stillness to your day. Your first quiet moment is one tap away."
        case .habit:
            return "Faithfulness grows one day at a time — and your streak begins with today's prayer."
        case .devotion:
            return "Mary walks with you through every mystery. She has been waiting for you."
        case .learning:
            return "Every soul that prays began with a single Ave. The app will hold your place at every bead."
        case nil:
            return "Each prayer is a step closer to grace. Begin now, or take a moment to explore the different ways to pray the Rosary."
        }
    }

    private var finalSlide: some View {
        OnboardingSlideLayout(
            icon: "rays",
            iconIsGradient: false,
            title: "Begin Your Journey",
            isActive: currentPage == 4,
            content: {
                Text(personalizedClosing)
                    .font(AppFonts.italicFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            },
            bottomContent: {
                VStack(spacing: 14) {
                    Button {
                        onComplete()
                    } label: {
                        Text("Begin Prayer")
                            .font(AppFonts.headlineFont(17))
                            .foregroundColor(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [AppColors.gold, AppColors.goldLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(30)
                    }

                    Button {
                        showMethodsSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Text("Methods of Praying the Rosary")
                                .font(AppFonts.bodyFont(15))
                                .foregroundColor(AppColors.gold)
                            AppIcon("ph-caret-right", size: 12)
                                .foregroundColor(AppColors.gold)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        )
    }
}

// MARK: - OnboardingSlideLayout

/// Reusable full-screen slide: icon + title scroll area + fixed bottom buttons.
///
/// When `isActive` first becomes true (the slide is the visible page),
/// the icon, title, body, and buttons fade in one after another —
/// a small moment of theater that keeps each slide feeling alive.
private struct OnboardingSlideLayout<Content: View, Bottom: View>: View {

    let icon: String
    let iconIsGradient: Bool
    let title: String
    var isActive: Bool = true
    @ViewBuilder let content: () -> Content
    @ViewBuilder let bottomContent: () -> Bottom

    /// True once this slide has played its entrance (plays only once)
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Icon over a softly breathing gold glow
                    ZStack {
                        Circle()
                            .fill(AppColors.gold.opacity(0.12))
                            .frame(width: 110, height: 110)
                            .blur(radius: 18)
                            .phaseAnimator([1.0, 1.18, 1.0]) { view, scale in
                                view.scaleEffect(scale)
                            } animation: { _ in
                                .easeInOut(duration: 2.4)
                            }

                        Group {
                            if iconIsGradient {
                                AppIcon(icon, size: 64)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [AppColors.gold, AppColors.goldLight],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            } else {
                                AppIcon(icon, size: 64)
                                    .foregroundColor(AppColors.gold)
                            }
                        }
                    }
                    .padding(.top, 20)
                    .staggeredReveal(revealed, delay: 0)

                    Text(title)
                        .font(AppFonts.headlineFont(26))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .staggeredReveal(revealed, delay: 0.12)

                    content()
                        .padding(.horizontal, 28)
                        .staggeredReveal(revealed, delay: 0.24)

                    Spacer(minLength: 20)
                }
            }

            // Fixed bottom — fades into gradient
            VStack {
                bottomContent()
                    .padding(.horizontal, 28)
                    .padding(.bottom, 44)
                    .padding(.top, 16)
            }
            .background(
                LinearGradient(
                    colors: [Color.clear, AppColors.background.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
            .staggeredReveal(revealed, delay: 0.36)
        }
        .onAppear {
            if isActive { revealed = true }
        }
        .onChange(of: isActive) { _, nowActive in
            if nowActive { revealed = true }
        }
    }
}

// MARK: - Staggered Reveal Modifier

private extension View {
    /// Fades and floats content in after `delay` once `revealed` is true.
    func staggeredReveal(_ revealed: Bool, delay: Double) -> some View {
        self
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 14)
            .animation(.easeOut(duration: 0.55).delay(delay), value: revealed)
    }
}

// MARK: - Supporting Components

private struct OnboardingNextButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(AppFonts.headlineFont(17))
                AppIcon("ph-caret-right", size: 13)
            }
            .foregroundColor(AppColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AppColors.gold, AppColors.goldLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(30)
        }
    }
}

/// Slide 1 — compact icon + label row listing what the app provides.
private struct AppFeatureRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            AppIcon(icon, size: 14)
                .foregroundColor(AppColors.gold)
                .frame(width: 20)

            Text(label)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.cream.opacity(0.8))

            Spacer()
        }
    }
}

/// Selectable option row shared by the intention and reminder slides.
private struct SelectableOptionRow: View {
    let label: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                AppIcon(isSelected ? "ph-check-circle-fill" : "ph-circle", size: 20)
                    .foregroundColor(isSelected ? AppColors.gold : AppColors.textSecondary.opacity(0.6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)

                    Text(detail)
                        .font(AppFonts.bodyFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground.opacity(isSelected ? 1 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? AppColors.gold.opacity(0.6) : AppColors.gold.opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

/// Slide 2 — numbered step with a title and detail line.
private struct NumberedStepRow: View {
    let number: String
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.gold.opacity(0.15))
                    .frame(width: 38, height: 38)
                Text(number)
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(AppColors.gold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppFonts.headlineFont(14))
                    .foregroundColor(AppColors.cream)

                Text(detail)
                    .font(AppFonts.bodyFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
