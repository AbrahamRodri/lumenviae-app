//
//  OnboardingView.swift
//  Lumen Viae
//
//  First-run tutorial shown once on initial launch.
//  Tracked via @AppStorage so it never appears again after completion.
//
//  Flow (8 slides — Headspace-style: few words, felt experience):
//    1. Welcome           — an invitation, not a manual
//    2. At your own pace  — a live demo of the five mysteries advancing;
//                            meditations are read or played, prayer is
//                            self-paced (no bead-level tracking is implied)
//    3. Intention         — "What draws you here?" (self-segmentation;
//                            creates ownership, personalizes the closing)
//    4. What else is here — the consecration, the journal, the record,
//                            the library. Named once, plainly: they are
//                            what people come back for, and a first run
//                            that only shows the Rosary never finds them
//    5. Sanctuary         — pick a theme; tapping re-themes the whole app
//                            live, so onboarding itself is the preview
//    6. Prayer language   — English, Latin, or bilingual, with a live
//                            preview of the Hail Mary in the chosen format
//    7. Daily reminder    — pick a prayer time with the value explained,
//                            which beats a cold permission prompt
//    8. The threshold     — the crucifix a Rosary is begun on, a closing
//                            line personalized to the intention, and the
//                            one concrete first step it implies
//      • "Begin Prayer"                    → onComplete() → ContentView
//      • "Methods of Praying the Rosary"   → sheet (RosaryMethodsView)
//
//  A quiet Skip rides beside the dots until the last slide. Nothing
//  asked here is required — every choice has a sound default and lives
//  in Account afterwards — so a user who feels held is a user lost for
//  no gain.
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

    /// Selected intentions on the "What draws you here?" slide. Multi-select:
    /// the choice drives which reminder pools the daily notification draws
    /// from, and more than one reason can be true at once. Seeded from
    /// settings so re-running onboarding from Account reflects the choice.
    @State private var selectedIntentions: Set<PrayerIntention> = Set(UserSettings.shared.intentions)

    /// Selected prayer language on the language slide — seeded from settings
    /// so re-running onboarding from Account reflects the current choice
    @State private var selectedLanguage: PrayerLanguage = UserSettings.shared.prayerLanguage

    private let totalPages = 8

    /// The paintings the eight slides are set against — a walk through
    /// the mysteries in their own order, joyful to glorious, chosen for
    /// what each slide is asking rather than for decoration:
    ///
    ///   the Annunciation for a beginning · the Visitation for a journey
    ///   made at its own pace · the Finding in the Temple for what draws
    ///   a soul to look · Cana for more than was asked for · the
    ///   Transfiguration for choosing a light · Pentecost for tongues ·
    ///   the Agony for "could you not watch one hour with me" · the
    ///   Coronation for the send-off.
    private static let backdrops = [
        "joyful_annunciation",
        "joyful_visitation",
        "joyful_finding",
        "luminous_cana",
        "luminous_transfiguration",
        "glorious_pentecost",
        "sorrowful_agony",
        "glorious_coronation"
    ]

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            backdrop

            VStack(spacing: 0) {
                // Where you are in the eight, told on a strand of beads
                // rather than a row of dots — the app counts everything
                // else this way, and a Rosary app's own progress should
                // never look like anybody else's.
                ZStack {
                    RosaryBeadProgress(
                        total: totalPages,
                        completed: currentPage,
                        activeIndex: currentPage,
                        beadSize: 8
                    )
                    .frame(width: 190)
                    .animation(.easeInOut(duration: 0.35), value: currentPage)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Step \(currentPage + 1) of \(totalPages)")

                    HStack {
                        Spacer()
                        skipButton
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 10)

                // Slides
                TabView(selection: $currentPage) {
                    slide1.tag(0)
                    slide2.tag(1)
                    intentionSlide.tag(2)
                    whatsInsideSlide.tag(3)
                    themeSlide.tag(4)
                    languageSlide.tag(5)
                    reminderSlide.tag(6)
                    finalSlide.tag(7)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .sheet(isPresented: $showMethodsSheet) {
            RosaryMethodsView()
        }
    }

    /// The painting behind the slide, crossfading as you move through
    /// the eight.
    ///
    /// Rebuilding the view on every page change is deliberate: each one
    /// arrives at a slight scale and settles over several seconds, so
    /// the artwork keeps drifting after the swipe has finished the way a
    /// held shot does. Nothing loops — the motion belongs to arriving
    /// somewhere, not to the screen sitting there.
    private var backdrop: some View {
        ZStack {
            ForEach(0..<totalPages, id: \.self) { index in
                if index == currentPage {
                    OnboardingBackdrop(imageName: Self.backdrops[index])
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.9), value: currentPage)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// Nothing here is a gate. Someone who would rather look around
    /// than be introduced leaves the setup in one tap and lands on the
    /// last slide, where the app begins — every choice behind it has a
    /// sound default and lives in Account afterwards.
    @ViewBuilder
    private var skipButton: some View {
        if currentPage < totalPages - 1 {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { currentPage = totalPages - 1 }
            } label: {
                Text("Skip")
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .transition(.opacity)
            .accessibilityHint("Skips the rest of the introduction")
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
                    Text("Every soul comes to the Rosary for a reason. Choose as many as are true — yours shape how we welcome you.")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    VStack(spacing: 10) {
                        ForEach(intentionOptions, id: \.intention) { option in
                            SelectableOptionRow(
                                label: option.intention.rawValue,
                                detail: option.detail,
                                isSelected: selectedIntentions.contains(option.intention)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedIntentions.contains(option.intention) {
                                        selectedIntentions.remove(option.intention)
                                    } else {
                                        selectedIntentions.insert(option.intention)
                                    }
                                }
                            }
                        }
                    }
                }
                .multilineTextAlignment(.leading)
            },
            bottomContent: {
                OnboardingNextButton(label: "Continue") {
                    UserSettings.shared.onboardingIntentions =
                        PrayerIntention.allCases
                            .filter { selectedIntentions.contains($0) }
                            .map(\.rawValue)
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 3 }
                }
            }
        )
    }

    // MARK: - Slide 4: What Else Is Here

    /// The parts of the app a first run never meets.
    ///
    /// The Rosary is the front door, and someone who only ever meets the
    /// front door never finds the consecration, the journal, or the
    /// library behind it — the three things people come back for. Named
    /// once here, plainly, and never sold.
    private var whatsInsideSlide: some View {
        OnboardingSlideLayout(
            icon: "ch-church",
            iconIsGradient: true,
            title: "More Than the Rosary",
            isActive: currentPage == 3,
            content: {
                VStack(spacing: 22) {
                    Text("The Rosary is the heart of it. Around it is everything else a devotion asks for.")
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)

                    VStack(spacing: 14) {
                        SessionMomentRow(icon: "ph-crown", text: "The 33-day Consecration, a day at a time")
                        SessionMomentRow(icon: "ph-note-pencil", text: "A journal that never leaves your device")
                        SessionMomentRow(icon: "ph-flame", text: "A quiet record of the days you have prayed")
                        SessionMomentRow(icon: "ch-bible", text: "True Devotion and the Marian library, in full")
                    }

                    Text("Downloaded once, all of it prays without a connection.")
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            },
            bottomContent: {
                OnboardingNextButton(label: "Continue") {
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 4 }
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
            isActive: currentPage == 4,
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
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 5 }
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
            isActive: currentPage == 5,
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Pray in English, in the Church's Latin, or in both together — line by line, one tongue above the other.")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    LanguagePreviewCard(language: selectedLanguage)

                    VStack(spacing: 10) {
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
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 6 }
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
            isActive: currentPage == 6,
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    Text("A consistent hour of prayer is the surest way to make the Rosary a daily habit. When would you like to be reminded?")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    VStack(spacing: 10) {
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

                    // The system prompt is raised by this slide's own button,
                    // so a refusal happens in plain sight. This line keeps it
                    // in sight afterwards rather than letting the user leave
                    // believing an hour was set that can never ring.
                    if UserSettings.shared.notificationAuthorizationDenied {
                        HStack(alignment: .top, spacing: 8) {
                            AppIcon("ph-bell", size: 13)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.top, 2)

                            Text("Notifications are turned off for Lumen Viae. Turn them on in the Settings app, or set an hour later from Settings → Devotion.")
                                .font(AppFonts.italicFont(13))
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(3)
                        }
                    } else {
                        Text("You can change or disable this anytime in Settings.")
                            .font(AppFonts.italicFont(13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .multilineTextAlignment(.leading)
            },
            bottomContent: {
                VStack(spacing: 14) {
                    Button {
                        // Already refused: there is no hour left to set,
                        // so the button's only remaining job is to move on.
                        // Without this it would re-run the sync, be told
                        // "denied" again, and refuse to advance — a slide
                        // with a live button and no way forward.
                        if UserSettings.shared.notificationAuthorizationDenied {
                            withAnimation(.easeInOut(duration: 0.3)) { currentPage = 7 }
                            return
                        }
                        guard let hour = selectedReminderHour else {
                            withAnimation(.easeInOut(duration: 0.3)) { currentPage = 7 }
                            return
                        }
                        // Hold this slide until the system has asked and
                        // been answered. The property observers raise the
                        // same request on their own, but they do it in a
                        // detached Task, so the dialog landed on the *next*
                        // slide — over "In the Name of the Father", with
                        // nothing on screen explaining what was being
                        // asked. Awaiting it here keeps the question on the
                        // slide that poses it, and lets the refusal line
                        // above appear before the user moves on.
                        Task {
                            let settings = UserSettings.shared
                            settings.reminderHour = hour
                            settings.reminderMinute = 0
                            settings.remindersEnabled = true
                            await settings.syncNotifications()
                            // A refusal earns a beat. The line above now
                            // says what happened and where to undo it;
                            // sliding straight on would hide it, which is
                            // how this slide used to send people away
                            // believing an hour was set.
                            guard !settings.notificationAuthorizationDenied else { return }
                            withAnimation(.easeInOut(duration: 0.3)) { currentPage = 7 }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(UserSettings.shared.notificationAuthorizationDenied
                                 ? "Continue" : "Set Reminder")
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
                        withAnimation(.easeInOut(duration: 0.3)) { currentPage = 7 }
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

    // MARK: - Slide 8: The Threshold

    /// The last slide is where the Rosary actually starts, so it is set
    /// as the first moment of the prayer rather than as a summary of the
    /// seven before it: the crucifix struck in gold, and the words said
    /// while holding it.
    ///
    /// It was "Begin Your Journey" over a sunrise glyph — the title every
    /// app in the store uses, under an icon that means nothing to anyone
    /// praying. A Rosary is begun with the cross in your hand and the
    /// Sign; the page can simply say so.

    /// Closing line personalized to the chosen intention — the small
    /// "made for you" payoff at the end of onboarding. With several chosen,
    /// the first in the enum's order speaks for them; the alternative is a
    /// generic line, which is the one thing this slide exists to avoid.
    private var personalizedClosing: String {
        switch PrayerIntention.allCases.first(where: { selectedIntentions.contains($0) }) {
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

    /// Where this particular soul might begin, drawn from what they said
    /// draws them here.
    ///
    /// The intention question earns its keep by changing something the
    /// user can see. A personalized closing line alone was thin payoff
    /// for an answer given three slides earlier — this names the one
    /// place to go next, and where in the app to find it.
    private var firstStep: (icon: String, text: String) {
        switch PrayerIntention.allCases.first(where: { selectedIntentions.contains($0) }) {
        case .peace:
            return ("ph-hands-praying", "One decade is a beginning. The Pray button opens today's mysteries.")
        case .habit:
            return ("ph-flame", "Your Chapel keeps the flame — a record of the days you have prayed. It starts with today.")
        case .devotion:
            return ("ph-crown", "When you are ready, the 33-day Consecration waits under Consecrate.")
        case .learning:
            return ("ch-bible", "Your Chapel's Library holds How to Pray the Rosary. Start there — it takes five minutes.")
        case nil:
            return ("ph-hands-praying", "The Pray button opens today's mysteries whenever you are ready.")
        }
    }

    private var finalSlide: some View {
        OnboardingSlideLayout(
            icon: "",
            iconIsGradient: false,
            usesCross: true,
            title: "In the Name of the Father",
            isActive: currentPage == 7,
            content: {
                VStack(spacing: 22) {
                    Text(personalizedClosing)
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.cream.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)

                    FirstStepCard(icon: firstStep.icon, text: firstStep.text)
                }
            },
            bottomContent: {
                VStack(spacing: 14) {
                    Button {
                        onComplete()
                    } label: {
                        // This opens the app; it does not start a Rosary.
                        // Labelled "Begin Prayer", it landed the user on a
                        // home screen carrying its own "Begin Prayer"
                        // button — the same words twice, the first of them
                        // untrue.
                        Text("Enter")
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

// MARK: - OnboardingBackdrop

/// One painting behind one slide: the canvas, a scrim heavy enough to
/// read against, and a vignette that closes the corners down so the
/// slide sits in a pool of light rather than on a flat field.
///
/// Both the scrim and the vignette are mixed in the *theme's* own
/// deep ground, so the sanctuary chosen on slide five changes the light
/// falling on the artwork immediately — the theme slide previews itself
/// on a Velázquez instead of on three swatches.
private struct OnboardingBackdrop: View {

    let imageName: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Flipped on appear: the painting arrives a touch large and eases
    /// down to its true size over several seconds. One way, once.
    @State private var settled = false

    var body: some View {
        GeometryReader { geometry in
            CachedAssetImage(imageName, focal: UnitPoint(x: 0.5, y: 0.34))
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(settled || reduceMotion ? 1 : 1.12, anchor: .center)
                .animation(reduceMotion ? nil : .easeOut(duration: 11), value: settled)
                .clipped()
                .overlay(scrim)
                .overlay(vignette)
        }
        .onAppear { settled = true }
    }

    /// Weighted the way the home screen's hero weights its own: out of
    /// the way through the top third, where the painting is left to be a
    /// painting, then gathering steadily from the middle down until the
    /// words and the act stand on near-solid ground.
    ///
    /// An even scrim was tried first and is the reason this comment
    /// exists — it left the title sitting across somebody's face, which
    /// is unreadable and disrespectful to the painting at once.
    private var scrim: some View {
        LinearGradient(
            stops: [
                .init(color: AppColors.backgroundDeep.opacity(0.66), location: 0),
                .init(color: AppColors.backgroundDeep.opacity(0.40), location: 0.13),
                .init(color: AppColors.backgroundDeep.opacity(0.46), location: 0.30),
                .init(color: AppColors.backgroundDeep.opacity(0.72), location: 0.45),
                .init(color: AppColors.backgroundDeep.opacity(0.88), location: 0.57),
                .init(color: AppColors.backgroundDeep.opacity(0.95), location: 0.70),
                .init(color: AppColors.backgroundDeep.opacity(0.98), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var vignette: some View {
        RadialGradient(
            colors: [
                AppColors.backgroundDeep.opacity(0),
                AppColors.backgroundDeep.opacity(0.35),
                AppColors.backgroundDeep.opacity(0.78)
            ],
            center: .center,
            startRadius: 90,
            endRadius: 560
        )
    }
}

// MARK: - OnboardingSlideLayout

/// The chrome sizes a slide is set in. A slide takes the roomy metrics
/// when they fit the screen and the tight ones when they don't, so a
/// short phone loses air rather than gaining a scroll bar.
private struct SlideMetrics {
    let glow: CGFloat
    let icon: CGFloat
    let title: CGFloat
    let spacing: CGFloat
    let topPadding: CGFloat

    static let roomy = SlideMetrics(glow: 96, icon: 56, title: 25, spacing: 22, topPadding: 8)
    static let tight = SlideMetrics(glow: 74, icon: 42, title: 22, spacing: 14, topPadding: 0)
}

/// Reusable full-screen slide: icon, title, body, and fixed bottom buttons.
///
/// A slide is meant to be taken in at a glance — read it, choose, move on
/// — so it is sized to the screen rather than scrolled. `ViewThatFits`
/// keeps that promise: the roomy metrics first, the tight ones if the
/// content is taller than the display, and a scroll only as the last
/// resort, which in practice means the large accessibility text sizes.
///
/// When `isActive` first becomes true (the slide is the visible page),
/// the icon, title, body, and buttons fade in one after another —
/// a small moment of theater that keeps each slide feeling alive.
private struct OnboardingSlideLayout<Content: View, Bottom: View>: View {

    let icon: String
    let iconIsGradient: Bool

    /// Strikes the app's own Latin cross in the medallion instead of a
    /// glyph. For the last slide only, where the mark is not a label for
    /// the page but the crucifix a Rosary is actually begun on.
    var usesCross: Bool = false

    let title: String
    var isActive: Bool = true
    @ViewBuilder let content: () -> Content
    @ViewBuilder let bottomContent: () -> Bottom

    /// True once this slide has played its entrance (plays only once)
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .vertical) {
                slideBody(.roomy)
                slideBody(.tight)
                ScrollView(showsIndicators: false) { slideBody(.tight) }
            }

            // Fixed bottom — fades into gradient
            VStack {
                bottomContent()
                    .padding(.horizontal, 28)
                    .padding(.bottom, 20)
                    .padding(.top, 14)
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

    /// The slide above the buttons. The spacers carry no ideal height, so
    /// `ViewThatFits` measures the real content and only the chosen
    /// variant spreads into whatever room is left.
    private func slideBody(_ metrics: SlideMetrics) -> some View {
        VStack(spacing: metrics.spacing) {
            Spacer(minLength: 0)

            iconBadge(metrics)
                .padding(.top, metrics.topPadding)
                .staggeredReveal(revealed, delay: 0)

            Text(title)
                .font(AppFonts.headlineFont(metrics.title))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .staggeredReveal(revealed, delay: 0.12)

            content()
                .padding(.horizontal, 28)
                // Never let a line be squeezed to one row and cut with an
                // ellipsis: a slide is measured by `ViewThatFits`, and
                // without this a body text will silently compress rather
                // than let the tight metrics — or the scroll — be chosen.
                .fixedSize(horizontal: false, vertical: true)
                .staggeredReveal(revealed, delay: 0.24)

            // Capped, unlike the spacer above it: a slide with little on
            // it settles low on the page, near the act, instead of
            // floating in the middle of the painting. A tall slide
            // collapses both and is unaffected.
            Spacer(minLength: 0)
                .frame(maxHeight: 70)
        }
        .frame(maxWidth: .infinity)
    }

    /// Icon over a softly breathing gold glow
    private func iconBadge(_ metrics: SlideMetrics) -> some View {
        ZStack {
            Circle()
                .fill(AppColors.gold.opacity(0.12))
                .frame(width: metrics.glow, height: metrics.glow)
                .blur(radius: 18)
                .phaseAnimator([1.0, 1.18, 1.0]) { view, scale in
                    view.scaleEffect(scale)
                } animation: { _ in
                    .easeInOut(duration: 2.4)
                }

            // A struck disc under the glyph, the same shape the Pray
            // medallion carries in the tab bar. Bare gold line-art over
            // a painting reads as a mistake — on the welcome slide the
            // mark landed in the angel's hand as though it were being
            // offered to Our Lady. On its own ground it reads as a seal
            // set on the page instead.
            Circle()
                .fill(AppColors.backgroundDeep.opacity(0.62))
                .frame(width: metrics.glow * 0.82, height: metrics.glow * 0.82)
                .overlay(
                    Circle()
                        .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: 1)
                )

            if usesCross {
                LatinCross()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: metrics.icon * 0.62, height: metrics.icon * 0.92)
            } else if iconIsGradient {
                AppIcon(icon, size: metrics.icon)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.gold, AppColors.goldLight],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                AppIcon(icon, size: metrics.icon)
                    .foregroundColor(AppColors.gold)
            }
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

/// The last slide's one concrete next step. Set in the same quoted
/// ground as slide 2's demo, so it reads as something the app is
/// telling you rather than another choice to make.
private struct FirstStepCard: View {
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
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
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
        .accessibilityElement(children: .combine)
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
            .padding(.vertical, 12)
            .frame(minHeight: 44)
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
        VStack(spacing: 10) {
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

    /// The opening line of the Ave Maria in both tongues. One line, not
    /// the stanza — it has to show the shape of the format while leaving
    /// the four choices below it on the same screen.
    private static let lines: [(latin: String, english: String)] = [
        ("Ave Maria, gratia plena, Dominus tecum;", "Hail Mary, full of grace, the Lord is with thee;")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        .padding(12)
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
