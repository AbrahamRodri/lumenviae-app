//
//  OnboardingView.swift
//  Lumen Viae
//
//  First-run tutorial shown once on initial launch.
//  Tracked via @AppStorage so it never appears again after completion.
//
//  Flow (7 slides — Headspace-style: few words, felt experience):
//    1. Welcome           — an invitation, not a manual
//    2. At your own pace  — a live demo of the five mysteries advancing;
//                            meditations are read or played, prayer is
//                            self-paced (no bead-level tracking is implied)
//    3. Intention         — "What draws you here?" (self-segmentation;
//                            creates ownership, personalizes the closing)
//    4. Sanctuary         — pick a theme; tapping re-themes the whole app
//                            live, so onboarding itself is the preview
//    5. Prayer language   — English, Latin, or bilingual, with a live
//                            preview of the Hail Mary in the chosen format
//    6. Daily reminder    — pick a prayer time with the value explained,
//                            which beats a cold permission prompt
//    7. Begin             — closing line personalized to the intention
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

    /// Selected prayer language on the language slide — seeded from settings
    /// so re-running onboarding from Account reflects the current choice
    @State private var selectedLanguage: PrayerLanguage = UserSettings.shared.prayerLanguage

    private let totalPages = 7

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
                    themeSlide.tag(3)
                    languageSlide.tag(4)
                    reminderSlide.tag(5)
                    finalSlide.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .sheet(isPresented: $showMethodsSheet) {
            RosaryMethodsView()
        }
    }

    // MARK: - Slide 1: Welcome (an invitation, not a manual)

    private var slide1: some View {
        OnboardingSlideLayout(
            icon: "ch-rosary",
            iconIsGradient: true,
            title: "Lumen Viae",
            isActive: currentPage == 0,
            content: {
                VStack(spacing: 18) {
                    Text("LIGHT OF THE WAY")
                        .font(AppFonts.labelFont(11))
                        .tracking(4)
                        .foregroundColor(AppColors.gold)

                    Text("A quiet place to pray the Rosary — scripture, meditation, and stillness, one mystery at a time.")
                        .font(AppFonts.italicFont(17))
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 8)
                }
            },
            bottomContent: {
                OnboardingNextButton(label: "Begin") {
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 1 }
                }
            }
        )
    }

    // MARK: - Slide 2: At Your Own Pace (shown, not told)

    private var slide2: some View {
        OnboardingSlideLayout(
            icon: "ph-hands-praying",
            iconIsGradient: false,
            title: "At Your Own Pace",
            isActive: currentPage == 1,
            content: {
                VStack(spacing: 26) {
                    Text("Each mystery brings its meditation. You pray, and move on when you're ready.")
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)

                    MysteryPaceDemoView(isActive: currentPage == 1)

                    VStack(spacing: 14) {
                        SessionMomentRow(icon: "ph-calendar-dots", text: "Today's mystery, chosen for you")
                        SessionMomentRow(icon: "ph-book-open",     text: "A meditation for each — read or listen")
                        SessionMomentRow(icon: "ph-note-pencil",   text: "A quiet reflection to close")
                    }
                }
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

    // MARK: - Slide 4: Theme ("Choose Your Sanctuary")

    private var themeSlide: some View {
        OnboardingSlideLayout(
            icon: "ch-window",
            iconIsGradient: true,
            title: "Choose Your Sanctuary",
            isActive: currentPage == 3,
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Every chapel has its own light. Choose the palette your prayers will live in — the whole app changes the moment you tap.")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    OnboardingThemePicker()
                }
                .multilineTextAlignment(.leading)
            },
            bottomContent: {
                OnboardingNextButton(label: "Continue") {
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 4 }
                }
            }
        )
    }

    // MARK: - Slide 5: Prayer Language ("The Language of Prayer")

    /// Language presets: the enum case plus a one-line description of the format.
    private let languageOptions: [(language: PrayerLanguage, detail: String)] = [
        (.english, "Every prayer in English"),
        (.latin, "The Church's ancient tongue"),
        (.both, "Latin leads, English beneath each line"),
        (.latinUnderEnglish, "English leads, Latin beneath each line")
    ]

    private var languageSlide: some View {
        OnboardingSlideLayout(
            icon: "ph-globe",
            iconIsGradient: false,
            title: "The Language of Prayer",
            isActive: currentPage == 4,
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Pray in English, in the Church's Latin, or in both together — line by line, one tongue above the other.")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    LanguagePreviewCard(language: selectedLanguage)

                    VStack(spacing: 12) {
                        ForEach(languageOptions, id: \.language) { option in
                            SelectableOptionRow(
                                label: option.language.rawValue,
                                detail: option.detail,
                                isSelected: selectedLanguage == option.language
                            ) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedLanguage = option.language
                                }
                            }
                        }
                    }
                    .sensoryFeedback(.selection, trigger: selectedLanguage)
                }
                .multilineTextAlignment(.leading)
            },
            bottomContent: {
                OnboardingNextButton(label: "Continue") {
                    UserSettings.shared.prayerLanguagePreference = selectedLanguage.rawValue
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 5 }
                }
            }
        )
    }

    // MARK: - Slide 6: Daily Reminder

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
            isActive: currentPage == 5,
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
                        withAnimation(.easeInOut(duration: 0.3)) { currentPage = 6 }
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
                        withAnimation(.easeInOut(duration: 0.3)) { currentPage = 6 }
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

    // MARK: - Slide 7: Begin or Learn More

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
            icon: "ph-sun-horizon",
            iconIsGradient: false,
            title: "Begin Your Journey",
            isActive: currentPage == 6,
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

/// Slide 2 — one quiet moment of the session: circled icon + a short line.
private struct SessionMomentRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.gold.opacity(0.12))
                    .frame(width: 34, height: 34)
                AppIcon(icon, size: 15)
                    .foregroundColor(AppColors.gold)
            }

            Text(text)
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream.opacity(0.85))

            Spacer()
        }
    }
}

/// Slide 2's show-don't-tell: the five mysteries advancing one by one,
/// the way a session actually moves — a meditation per mystery, prayed
/// at your own pace. Loops while the slide is visible; holds a still
/// frame when inactive or Reduce Motion is on.
private struct MysteryPaceDemoView: View {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Seconds each mystery lingers in the demo
    private static let mysteryInterval: Double = 2.4

    /// The Joyful mysteries, as a familiar example set
    private static let mysteries = [
        "The Annunciation",
        "The Visitation",
        "The Nativity",
        "The Presentation",
        "Finding Jesus in the Temple"
    ]

    private static let ordinals = ["FIRST", "SECOND", "THIRD", "FOURTH", "FIFTH"]

    var body: some View {
        Group {
            if isActive && !reduceMotion {
                TimelineView(.periodic(from: .now, by: Self.mysteryInterval)) { context in
                    let tick = Int(context.date.timeIntervalSinceReferenceDate / Self.mysteryInterval)
                    demo(current: tick % 5)
                }
            } else {
                demo(current: 1)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.quoteBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }

    private func demo(current: Int) -> some View {
        VStack(spacing: 14) {
            // Five mystery markers — prayed ones filled, the current one lit
            HStack(spacing: 14) {
                ForEach(0..<5, id: \.self) { index in
                    let isReached = index <= current
                    let isCurrent = index == current

                    Circle()
                        .fill(isReached ? AnyShapeStyle(AppColors.goldGradient) : AnyShapeStyle(AppColors.cardElevated))
                        .overlay(
                            Circle().strokeBorder(
                                AppColors.gold.opacity(isReached ? 0.8 : 0.25),
                                lineWidth: 1
                            )
                        )
                        .frame(width: 13, height: 13)
                        .scaleEffect(isCurrent ? 1.3 : 1)
                        .shadow(color: AppColors.gold.opacity(isCurrent ? 0.6 : 0), radius: 6)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: current)

            // The mystery now open, as the prayer screen presents it
            VStack(spacing: 4) {
                Text("THE \(Self.ordinals[current]) MYSTERY")
                    .font(AppFonts.labelFont(9))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)

                Text(Self.mysteries[current])
                    .font(AppFonts.headlineFont(17))
                    .foregroundColor(AppColors.cream)
            }
            .id(current)
            .transition(.opacity.combined(with: .offset(y: 6)))

            Text("Meditate, pray the decade, continue when ready")
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.textSecondary)
        }
        .animation(.easeOut(duration: 0.4), value: current)
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
                if isSelected {
                    AppIcon("ph-check-circle-fill", size: 20)
                        .foregroundColor(AppColors.gold)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    AppIcon("ph-circle", size: 20)
                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                }

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
                    .shadow(color: AppColors.gold.opacity(isSelected ? 0.22 : 0), radius: 12, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? AppColors.gold.opacity(0.6) : AppColors.gold.opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(SacredCardButtonStyle())
    }
}

/// Theme slide — the three sanctuary palettes. Selecting one re-themes
/// the entire app instantly (ThemeManager is @Observable and every color
/// flows through AppColors), so the onboarding itself is the live preview.
private struct OnboardingThemePicker: View {

    /// Observed so the checkmark moves the moment the theme changes
    private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 12) {
            ForEach(AppTheme.allCases) { theme in
                OnboardingThemeRow(
                    theme: theme,
                    isSelected: themeManager.current == theme
                ) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        ThemeManager.shared.current = theme
                    }
                }
            }

            // A verse in the voice of the chosen sanctuary — the small
            // reward for trying each one.
            Text(verse(for: themeManager.current))
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.accentSoft)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .id(themeManager.current)
                .transition(.opacity.combined(with: .offset(y: 6)))
        }
        .sensoryFeedback(.selection, trigger: themeManager.current)
    }

    private func verse(for theme: AppTheme) -> String {
        switch theme {
        case .marianBlue: return "“Tota pulchra es, Maria” — you are all fair, O Mary."
        case .midnight:   return "“Be still, and know that I am God.” — Psalm 46"
        case .candlelit:  return "“Your word is a lamp to my feet.” — Psalm 119"
        }
    }
}

/// A single theme choice: swatch trio, name, character line, and check —
/// the same card treatment as SelectableOptionRow.
private struct OnboardingThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Swatch trio: background, card, and gold — the stack
                // fans open and the gold "lights" when this theme is chosen
                HStack(spacing: isSelected ? 3 : -8) {
                    swatch(theme.palette.background)
                    swatch(theme.palette.card)
                    swatch(theme.palette.gold)
                        .shadow(color: theme.palette.gold.opacity(isSelected ? 0.7 : 0), radius: 6)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.65), value: isSelected)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)

                    Text(theme.detail)
                        .font(AppFonts.bodyFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    AppIcon("ph-check-circle-fill", size: 20)
                        .foregroundColor(AppColors.gold)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    AppIcon("ph-circle", size: 20)
                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground.opacity(isSelected ? 1 : 0.5))
                    .shadow(color: AppColors.gold.opacity(isSelected ? 0.22 : 0), radius: 12, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? AppColors.gold.opacity(0.6) : AppColors.gold.opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("\(theme.displayName) theme")
    }

    private func swatch(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay(Circle().strokeBorder(AppColors.cream.opacity(0.25), lineWidth: 1))
    }
}

/// Language slide — live preview of the Hail Mary's opening lines,
/// rendered in the same line-by-line format the prayer screens use,
/// so each option shows exactly what it means before it's chosen.
private struct LanguagePreviewCard: View {
    let language: PrayerLanguage

    /// Opening lines of the Ave Maria in both tongues
    private static let lines: [(latin: String, english: String)] = [
        ("Ave Maria, gratia plena, Dominus tecum;", "Hail Mary, full of grace, the Lord is with thee;"),
        ("benedicta tu in mulieribus,", "blessed art thou among women,")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                AppIcon("ph-hands-praying", size: 13)
                    .foregroundColor(AppColors.gold.opacity(0.85))

                Text("The Hail Mary")
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                // Mode chip — the dot order mirrors which tongue leads
                Text(badge)
                    .font(AppFonts.headlineFont(10))
                    .tracking(1.1)
                    .foregroundColor(AppColors.gold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppColors.gold.opacity(0.12)))
                    .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 1))
                    .id(language)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(Self.lines.enumerated()), id: \.offset) { _, line in
                    linePair(latin: line.latin, english: line.english)
                }
            }
            .id(language)
            .transition(.opacity.combined(with: .offset(y: 8)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.quoteBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.3), value: language)
    }

    /// Compact label for the active mode, e.g. "LATIN · ENGLISH"
    private var badge: String {
        switch language {
        case .english:           return "ENGLISH"
        case .latin:             return "LATIN"
        case .both:              return "LATIN · ENGLISH"
        case .latinUnderEnglish: return "ENGLISH · LATIN"
        }
    }

    /// One line of the prayer in the chosen format
    @ViewBuilder
    private func linePair(latin: String, english: String) -> some View {
        switch language {
        case .english:
            singleLine(english)
        case .latin:
            singleLine(latin)
        case .both:
            bilingualPair(primary: latin, secondary: english)
        case .latinUnderEnglish:
            bilingualPair(primary: english, secondary: latin)
        }
    }

    private func singleLine(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.bodyFont(15))
            .foregroundColor(AppColors.cream)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func bilingualPair(primary: String, secondary: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(primary)
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)

            Text(secondary)
                .font(AppFonts.bodyFont(13))
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .italic()
                .padding(.leading, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
