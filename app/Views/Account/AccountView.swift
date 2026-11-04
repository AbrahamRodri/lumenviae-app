//
//  AccountView.swift
//  Lumen Viae
//

import SwiftUI
import UIKit

/// The app's preferences — every toggle and choice, reached from the
/// home masthead's faders. The informational pages (about, privacy,
/// help) live on their own leaf, AboutView, behind the ⓘ beside them.
struct AccountView: View {
    @Environment(UserSettings.self) private var userSettings
    @Environment(AppRouter.self) private var router
    @State private var showSoundPicker = false
    @State private var showIntentionPicker = false
    @State private var showRuleEditor = false
    @State private var showAfterTheRosary = false

    /// One Rosary beta: the prayers chosen after the Rosary, by name, or
    /// that none is
    private var afterTheRosarySummary: String {
        let chosen = RosaryClosingExtra.allCases.filter { userSettings.isChosen($0) }
        return chosen.isEmpty
            ? String(localized: "None chosen · said with the Whole Rosary", comment: "One Rosary beta, Settings: the line under After the Rosary when no prayer is chosen")
            : chosen.map(\.title).joined(separator: " · ")
    }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    AccountHeaderView()

                    // MARK: Appearance
                    AccountSection(title: String(localized: "Appearance", comment: "Settings: a section heading"), icon: "ph-palette") {
                        ThemePickerRows()
                    }
                    .padding(.top, 30)

                    // MARK: App Icon
                    if AppIconPickerRows.isEnabled {
                        AccountSection(title: String(localized: "App Icon", comment: "Settings: a section heading"), icon: "ph-image") {
                            AppIconPickerRows()
                        }
                        .padding(.top, 30)
                    }

                    // MARK: Language
                    // The app follows the phone; this opens the system's
                    // own page for the app, where Español or English is
                    // chosen for Lumen Viae alone. In Spanish the AI
                    // translation notice stands beneath it, always.
                    AccountSection(title: String(localized: "Language", comment: "Settings: a section heading, the language the app's words are shown in"), icon: "ph-globe") {
                        AppLanguageRow()
                    }
                    .padding(.top, 30)

                    // MARK: Prayer Experience
                    // How the words look and who reads them, for every
                    // page that prays: the Rosary's own choices stand
                    // under The Rosary, below, and the Prayers tab's under
                    // its own name, so neither "Audio" is read as the
                    // other's
                    AccountSection(title: String(localized: "Prayer Experience", comment: "Settings: a section heading"), icon: "ph-text-aa") {
                        VStack(spacing: 0) {
                            TextSizeRow(value: Bindable(userSettings).textSizeScale)

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            PrayerLanguageRow(
                                selectedLanguage: Bindable(userSettings).prayerLanguagePreference
                            )

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // Who reads the meditations. The same choice
                            // stands in the player's playback sheet, so a
                            // Rosary need not be left to change it
                            NarrationVoiceRow()
                        }
                    }
                    .padding(.top, 30)

                    // MARK: The Rosary
                    // The Rosary's own choices, as its own page sets the
                    // first two, then what is shown before and after the
                    // mysteries
                    AccountSection(title: String(localized: "The Rosary", comment: "Settings: a section heading"), icon: "lv-rosary") {
                        VStack(spacing: 0) {
                            // Audio: the meditation alone, or the Whole
                            // Rosary said aloud in the voice chosen above,
                            // the beads moving with it, for prayer with the
                            // phone put away. First, as the Rosary's own
                            // page sets it, since it decides whether
                            // Counting is offered at all
                            RosaryChoiceSettingsRow(
                                choice: .audio,
                                value: Bindable(userSettings).prayAloud
                            )

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // Counting: the beads on the screen are a way
                            // of praying, not a requirement — on your own
                            // rosary the player moves a mystery at a time.
                            // Moot with the Whole Rosary, whose voice moves
                            // the beads on the screen
                            // With the One Rosary beta the beads always
                            // hang, and Helps stands in Counting's place
                            if userSettings.oneRosaryBeta {
                                RosaryChoiceSettingsRow(
                                    choice: .helps,
                                    value: Bindable(userSettings).rosaryHelps
                                )
                            } else {
                                RosaryChoiceSettingsRow(
                                    choice: .counting,
                                    value: Bindable(userSettings).prayOnBeads,
                                    isAvailable: !userSettings.prayAloud
                                )
                            }

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // The pendant's prayers on a Rosary prayed in
                            // silence (`SilentPendant`). Moot with the
                            // Whole Rosary, whose voice says them
                            RosaryChoiceSettingsRow(
                                icon: OpeningPrayersChoice.icon,
                                title: OpeningPrayersChoice.title,
                                options: OpeningPrayersChoice.options,
                                value: Bindable(userSettings).showsOpeningPrayers,
                                isAvailable: !userSettings.prayAloud,
                                unavailableNote: OpeningPrayersChoice.unavailableNote,
                                note: { OpeningPrayersChoice.note(for: $0) }
                            )

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // After the Rosary: prayers after its closing
                            // prayer, each off until chosen. Only the voice
                            // says them — nothing else reads these
                            // switches — so they stand under their own
                            // name with the set page's note, rather than
                            // among the ways of praying, where they read
                            // as prayers added to every Rosary. The Seven
                            // Sorrows chaplet closes in its own way and
                            // never says them
                            // One Rosary beta: the three prayers after the
                            // Rosary behind one row, which opens them
                            if userSettings.oneRosaryBeta {
                                ActionRow(
                                    icon: "ch-praying-hands",
                                    title: String(localized: "After the Rosary", comment: "One Rosary beta, Settings, The Rosary: the row that opens the prayers said after the Rosary"),
                                    subtitle: afterTheRosarySummary
                                ) {
                                    showAfterTheRosary = true
                                }
                            } else {
                                Text("AFTER THE ROSARY")
                                    .font(AppFonts.labelFont(9))
                                    .tracking(2)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .padding(.bottom, 2)
                                    .accessibilityAddTraits(.isHeader)

                                ForEach(RosaryClosingExtra.allCases, id: \.self) { extra in
                                    ToggleRow(
                                        icon: extra.icon,
                                        title: extra.title,
                                        subtitle: extra.detail,
                                        isOn: Binding(
                                            get: { userSettings.isChosen(extra) },
                                            set: { userSettings.setChosen(extra, $0) }
                                        )
                                    )

                                    Divider()
                                        .background(AppColors.gold.opacity(0.2))
                                }

                                // The set page's note, and while the Whole
                                // Rosary is not chosen, where to choose it
                                Text(userSettings.prayAloud
                                     ? String(localized: "Played after the closing prayer.", comment: "Settings: the line under a row")
                                     : String(localized: "Played after the closing prayer, with the Whole Rosary. Audio is at the top of this section.", comment: "Settings: the line under a row"))
                                    .font(AppFonts.italicFont(13))
                                    .foregroundColor(AppColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                            }

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // The One Rosary beta, off by default, at the
                            // section's foot, under the choices it changes:
                            // off, this section and the Rosary are as they
                            // were
                            ToggleRow(
                                icon: "lv-rosary",
                                title: String(localized: "One Rosary (beta)", comment: "Settings, The Rosary: the switch for the One Rosary beta, a new way to pray the Rosary"),
                                subtitle: String(localized: "Try the new way to pray the Rosary", comment: "Settings, The Rosary: the line under the One Rosary (beta) switch"),
                                isOn: Bindable(userSettings).oneRosaryBeta
                            )
                        }
                    }
                    .padding(.top, 30)

                    // MARK: Prayers Tab
                    // The Prayer Book's own: whether it speaks at all.
                    // Apart from the Rosary's Audio on purpose — that one
                    // says what the voice reads, this one whether the book
                    // makes a sound. Before any answer it shows the default
                    // and says the book will ask; only a tap here answers
                    // the question
                    AccountSection(title: String(localized: "Prayers Tab", comment: "Settings: a section heading"), icon: "lv-prayer-book") {
                        RosaryChoiceSettingsRow(
                            icon: PrayerBookAudio.icon,
                            title: String(localized: "Audio", comment: "Settings: a row\'s name"),
                            options: PrayerBookAudio.options,
                            value: Binding(
                                get: { PrayerBookStore.shared.praysAloud },
                                set: { PrayerBookStore.shared.chooseAloud($0) }
                            ),
                            isAnswered: PrayerBookStore.shared.hasChosenAloud,
                            note: { aloud in
                                PrayerBookAudio.note(
                                    for: aloud,
                                    answered: PrayerBookStore.shared.hasChosenAloud
                                )
                            }
                        )
                    }
                    .padding(.top, 30)

                    // MARK: Devotion
                    AccountSection(title: String(localized: "Devotion", comment: "Settings: a section heading"), icon: "ph-scroll") {
                        VStack(spacing: 0) {
                            // The Chapel page is arranged in place, so
                            // these are the standing doors to the two
                            // things arranging can't reach: what is ON
                            // the rule, and the record of prayer — kept
                            // here so stowing the flame tile never
                            // strands the Prayer Record.
                            //
                            // Only the Chapel reads the daily prayers, so
                            // the row stands down while it is archived.
                            if !ArchivedPages.chapel {
                                ActionRow(
                                    icon: "ph-scroll",
                                    title: String(localized: "Daily Prayers", comment: "Settings: a row\'s name"),
                                    subtitle: userSettings.ruleItems.isEmpty
                                        ? String(localized: "No prayers chosen yet", comment: "Settings: the line under a row")
                                        : userSettings.ruleItems.map(\.title).joined(separator: " · ")
                                ) {
                                    showRuleEditor = true
                                }

                                Divider()
                                    .background(AppColors.gold.opacity(0.2))
                            }

                            // Which mysteries the day brings: the
                            // traditional week, or the modern one with
                            // the Luminous on Thursday
                            MysteryScheduleRow()

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            ActionRow(
                                icon: "ph-flame",
                                title: String(localized: "Prayer Record", comment: "Settings: a row\'s name"),
                                subtitle: String(localized: "Your streaks, history, and milestones", comment: "Settings: the line under a row")
                            ) {
                                router.switchTo(.progress)
                            }

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // The Journal's standing door, with the
                            // Chapel and its Journal tile archived
                            ActionRow(
                                icon: "ph-book-open",
                                title: String(localized: "Journal", comment: "Settings: a row\'s name"),
                                subtitle: String(localized: "Your reflections, kept on this device", comment: "Settings: the line under a row")
                            ) {
                                router.switchTo(.journal)
                            }

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            ToggleRow(
                                icon: "ph-bell",
                                title: String(localized: "Daily Reminders", comment: "Settings: a row\'s name"),
                                subtitle: userSettings.remindersEnabled
                                    ? userSettings.reminderTimeLabel
                                    : String(localized: "Off", comment: "Settings: the line under a row"),
                                isOn: Bindable(userSettings).remindersEnabled
                            )

                            if userSettings.remindersEnabled && userSettings.notificationAuthorizationDenied {
                                Divider()
                                    .background(AppColors.gold.opacity(0.2))

                                ActionRow(
                                    icon: "ph-bell-fill",
                                    title: String(localized: "Turn On in iPhone Settings", comment: "Settings: a row\'s name"),
                                    subtitle: String(localized: "Notifications are turned off for Lumen Viae", comment: "Settings: the line under a row")
                                ) {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            if userSettings.remindersEnabled {
                                Divider()
                                    .background(AppColors.gold.opacity(0.2))

                                ReminderTimeRow(
                                    hour: Bindable(userSettings).reminderHour,
                                    minute: Bindable(userSettings).reminderMinute
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))

                                Divider()
                                    .background(AppColors.gold.opacity(0.2))

                                ActionRow(
                                    icon: "ph-speaker-high",
                                    title: String(localized: "Reminder Sound", comment: "Settings: a row\'s name"),
                                    subtitle: userSettings.reminderSound.displayName
                                ) {
                                    showSoundPicker = true
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // The church bell at six, noon and six, opening
                            // the Angelus when it is tapped — its own
                            // reminder, apart from the daily one above
                            ToggleRow(
                                icon: "lv-bell",
                                title: String(localized: "The Angelus Bell", comment: "Settings: a row\'s name"),
                                subtitle: PrayerBookStore.shared.angelusBellDenied
                                    ? String(localized: "Notifications are turned off for Lumen Viae", comment: "Settings: the line under a row")
                                    : String(localized: "Rings at 6 AM, noon and 6 PM for the Angelus, a short prayer to Mary", comment: "Settings: the line under a row"),
                                isOn: Binding(
                                    get: { PrayerBookStore.shared.angelusBell },
                                    set: { on in Task { await PrayerBookStore.shared.setAngelusBell(on) } }
                                )
                            )

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // Outside the reminders-on block on purpose: it
                            // decides which reminder copy is sent, but it is
                            // first of all something the user said about
                            // themselves, and it has to stay changeable —
                            // whoever came to learn the Rosary eventually has.
                            ActionRow(
                                icon: "ph-heart",
                                title: String(localized: "What Brings You to the Rosary", comment: "Settings: a row\'s name"),
                                subtitle: userSettings.intentions.isEmpty
                                    ? String(localized: "Not set", comment: "Settings: the line under a row")
                                    : userSettings.intentions.map(\.displayName).joined(separator: " · ")
                            ) {
                                showIntentionPicker = true
                            }
                        }
                        .animation(Motion.crossfade, value: userSettings.remindersEnabled)
                        .animation(Motion.crossfade, value: userSettings.notificationAuthorizationDenied)
                    }
                    .padding(.top, 24)

                    // MARK: Offline
                    AccountSection(title: String(localized: "Offline", comment: "Settings: a section heading"), icon: "ph-download-simple") {
                        OfflineContentRows()
                    }
                    .padding(.top, 30)

                    Spacer(minLength: 120)
                }
            }
            .topChromeFade()
        }
        // Settings is a pushed content page: the bar stays, and Back
        // lives in it. Drawn inside the scroll view — as it was — the
        // only way out of a screen this tall scrolled off the top.
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
        .sheet(isPresented: $showSoundPicker) {
            ReminderSoundSheet()
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(isPresented: $showAfterTheRosary) {
            AfterTheRosarySheet()
                .presentationDetents([.medium, .large])
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(isPresented: $showRuleEditor) {
            RuleEditorSheet()
                .environment(userSettings)
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(isPresented: $showIntentionPicker) {
            PrayerIntentionSheet()
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }
}

// MARK: - Theme Picker

/// The three sanctuary themes, each with a swatch preview.
/// Selecting one re-themes the entire app with a soft crossfade.
struct ThemePickerRows: View {

    /// Observed so the checkmark moves the moment the theme changes
    private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            ForEach(AppTheme.allCases) { theme in
                ThemeRow(
                    theme: theme,
                    isSelected: themeManager.current == theme
                ) {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        ThemeManager.shared.current = theme
                    }
                }

                if theme != AppTheme.allCases.last {
                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                }
            }
        }
        .sensoryFeedback(.selection, trigger: themeManager.current)
    }
}

/// A single theme option: overlapping swatches, name, and character line.
private struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Swatch trio: background, card, and gold of the theme
                HStack(spacing: -6) {
                    Circle()
                        .fill(theme.palette.background)
                        .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.5), lineWidth: AppLine.hairline))
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(theme.palette.card)
                        .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline))
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(theme.palette.gold)
                        .frame(width: 20, height: 20)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(isSelected ? AppColors.gold : AppColors.cream)

                    Text(theme.detail)
                        .font(AppFonts.italicFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    AppIcon("ph-check-circle-fill", size: 20)
                        .foregroundColor(AppColors.gold)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - App Icon Picker

/// The custom app icons, switchable at runtime. Selecting one calls
/// `setAlternateIconName`; iOS shows its confirmation and the home
/// screen icon changes immediately.
struct AppIconPickerRows: View {

    /// Hidden until there are alternate icons that match the current
    /// artwork. Flipping this back to `true` restores the picker and
    /// stops the launch-time reset in `appApp`.
    static let isEnabled = false

    private struct IconOption: Identifiable {
        /// Alternate icon name registered in build settings; nil = primary
        let alternateName: String?
        let displayName: String
        let detail: String
        /// Preview imageset in the asset catalog
        let preview: String
        var id: String { alternateName ?? "primary" }
    }

    private static let options: [IconOption] = [
        IconOption(
            alternateName: nil,
            displayName: String(localized: "Painting", comment: "Settings, App Icon: the name of an icon"),
            detail: String(localized: "Our Lady with the Marian monogram", comment: "Settings, App Icon: what the icon looks like"),
            preview: "icon-preview-Candlelit"
        ),
        IconOption(
            alternateName: "AppIconMarianBlue",
            displayName: String(localized: "Marian Blue", comment: "Settings, App Icon: the name of an icon"),
            detail: String(localized: "Gold on Our Lady's blue", comment: "Settings, App Icon: what the icon looks like"),
            preview: "icon-preview-MarianBlue"
        ),
        IconOption(
            alternateName: "AppIconMidnight",
            displayName: String(localized: "Midnight", comment: "Settings, App Icon: the name of an icon"),
            detail: String(localized: "Gold on the night sky", comment: "Settings, App Icon: what the icon looks like"),
            preview: "icon-preview-Midnight"
        ),
        IconOption(
            alternateName: "AppIconSorrowful",
            displayName: String(localized: "Sorrowful", comment: "Settings, App Icon: the name of an icon"),
            detail: String(localized: "Gold on the violet of the Passion", comment: "Settings, App Icon: what the icon looks like"),
            preview: "icon-preview-Sorrowful"
        ),
        IconOption(
            alternateName: "AppIconVellum",
            displayName: String(localized: "Vellum", comment: "Settings, App Icon: the name of an icon"),
            detail: String(localized: "Ink and gold on the page of an old book", comment: "Settings, App Icon: what the icon looks like"),
            preview: "icon-preview-Vellum"
        )
    ]

    @State private var selection: String? = UIApplication.shared.alternateIconName

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.options.enumerated()), id: \.element.id) { index, option in
                Button {
                    select(option)
                } label: {
                    HStack(spacing: 16) {
                        Image(option.preview)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 42, height: 42)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.displayName)
                                .font(AppFonts.bodyFont(16))
                                .foregroundColor(
                                    selection == option.alternateName
                                        ? AppColors.gold
                                        : AppColors.cream
                                )

                            Text(option.detail)
                                .font(AppFonts.italicFont(12))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        if selection == option.alternateName {
                            AppIcon("ph-check-circle-fill", size: 20)
                                .foregroundColor(AppColors.gold)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.displayName) app icon")
                .accessibilityAddTraits(selection == option.alternateName ? .isSelected : [])

                if index < Self.options.count - 1 {
                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                }
            }
        }
    }

    private func select(_ option: IconOption) {
        guard selection != option.alternateName else { return }
        let previous = selection

        withAnimation(Motion.settle) {
            selection = option.alternateName
        }

        UIApplication.shared.setAlternateIconName(option.alternateName) { error in
            if error != nil {
                DispatchQueue.main.async {
                    withAnimation(Motion.settle) { selection = previous }
                }
            }
        }
    }
}

// MARK: - Account Header

struct AccountHeaderView: View {
    /// The page's plate, set in the Chapel's own voice: a large Cinzel
    /// title over one italic line, closed with the ornament rule. Back
    /// is not drawn here: Settings is a pushed content page, so its Back
    /// belongs in the navigation bar, where it stays put however far
    /// down the page the reader is.
    var body: some View {
        VStack(spacing: 10) {
            Text("Settings")
                .font(AppFonts.headlineFont(30))
                .foregroundColor(AppColors.cream)

            Text("Choose how the app looks, sounds and reminds you.")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)

            OrnamentDivider()
                .frame(width: 120)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}

// MARK: - Account Section Container

/// A settings section in the Chapel's outlined register: a glyph-led
/// kicker in engraved caps, the rows behind a bare gold hairline — no
/// filled card surfaces, same as the page the settings serve.
struct AccountSection<Content: View>: View {
    let title: String
    var icon: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                if let icon {
                    AppIcon(icon, size: 12)
                        .foregroundColor(AppColors.gold.opacity(0.75))
                        .accessibilityHidden(true)
                }

                Text(title.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.75))
            }

            content
                // The card fill is gone, but the corner still has to
                // cut: rows carry their own highlights, and the reminder
                // rows slide in and out on a transition. `cornerRadius`
                // was doing this clipping as a side effect — dropping it
                // for the outlined register left square fills inside a
                // rounded hairline and let the animating rows escape the
                // section entirely.
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Offline Content Rows

/// Download/remove controls for offline meditations and audio, driven by
/// `OfflineContentService.state`.
struct OfflineContentRows: View {

    private var service = OfflineContentService.shared

    /// Which of the four the rows are in, ignoring the live count
    private static func stage(of state: OfflineContentService.State) -> Int {
        switch state {
        case .idle: return 0
        case .downloading: return 1
        case .downloaded: return 2
        case .failed: return 3
        }
    }

    @State private var showRemoveConfirm = false

    /// What the download is doing, said whole for each stage so each line
    /// translates as a sentence. The stage names are the service's ids;
    /// the first gets the list of what there is to download, and is not
    /// itself a download.
    private static func progressLine(forStage stage: String) -> String {
        switch stage {
        case "Preparing": return String(localized: "Preparing…", comment: "Settings, Save for Offline: finding what there is to download")
        case "Meditations": return String(localized: "Downloading Meditations…", comment: "Settings, Save for Offline: progress")
        case "Paintings": return String(localized: "Downloading Paintings…", comment: "Settings, Save for Offline: progress")
        case "Meditation Audio": return String(localized: "Downloading Meditation Audio…", comment: "Settings, Save for Offline: progress")
        case "Rosary Audio": return String(localized: "Downloading Rosary Audio…", comment: "Settings, Save for Offline: progress, the recorded prayers of the Rosary")
        case "Prayers Audio": return String(localized: "Downloading Prayers Audio…", comment: "Settings, Save for Offline: progress, the recordings of the Prayers tab")
        case "Chants": return String(localized: "Downloading Chants…", comment: "Settings, Save for Offline: progress")
        default: return String(localized: "Downloading \(stage)…", comment: "Settings, Save for Offline: progress for a stage named by the app")
        }
    }

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    var body: some View {
        // One slot for the four states, so idle → downloading → available
        // crossfade over one another rather than the rows being torn
        // down and rebuilt around a live count
        VStack(spacing: 0) {
            stateRows

            Divider()
                .background(AppColors.gold.opacity(0.2))

            ChantsSavedLine()
        }
        .confirmationDialog(
            "Remove offline downloads?",
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove Downloads", role: .destructive) {
                service.removeAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Meditations and audio will stream when you're online. You can download everything again at any time.")
        }
    }

    private var stateRows: some View {
        ZStack(alignment: .top) {
            switch service.state {
            case .idle:
                VStack(spacing: 0) {
                    ActionRow(
                        icon: "ph-download-simple",
                        title: String(localized: "Save for Offline", comment: "Settings, Offline: a row's name"),
                        subtitle: String(localized: "Every meditation and audio file, ready without a connection", comment: "Settings, Offline: the line under a row")
                    ) {
                        Task { await service.downloadAll() }
                    }

                    // Leftover files with no manifest should still be removable
                    if service.hasContentOnDisk {
                        removeRow
                    }
                }

            case .downloading(let stage, let completed, let total):
                HStack(spacing: 16) {
                    ProgressView()
                        .tint(AppColors.gold)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        // The first stage gets the list of what there is
                        // to download, and is not itself a download
                        Text(Self.progressLine(forStage: stage))
                            .font(AppFonts.bodyFont(16))
                            .foregroundColor(AppColors.cream)

                        Text("\(completed) of \(total)")
                            .font(AppFonts.bodyFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Text("\(total > 0 ? Int(Double(completed) / Double(total) * 100) : 0)%")
                        .font(AppFonts.headlineFont(15))
                        .foregroundColor(AppColors.gold)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(Motion.crossfade, value: completed)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

            case .downloaded(let date, let bytes):
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        AppIcon("ph-check-circle-fill", size: 18)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Available Offline")
                                .font(AppFonts.bodyFont(16))
                                .foregroundColor(AppColors.cream)

                            Text("\(Self.byteFormatter.string(fromByteCount: bytes)) · \(date.formatted(date: .abbreviated, time: .omitted))")
                                .font(AppFonts.bodyFont(12))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    Divider()
                        .background(AppColors.gold.opacity(0.2))

                    ActionRow(
                        icon: "ph-arrow-counter-clockwise",
                        title: String(localized: "Update Download", comment: "Settings, Offline: a row's name"),
                        subtitle: String(localized: "Gets the latest meditations; saved audio stays", comment: "Settings, Offline: the line under a row")
                    ) {
                        Task { await service.downloadAll(refreshText: true) }
                    }

                    Divider()
                        .background(AppColors.gold.opacity(0.2))

                    removeRow
                }

            case .failed(let message):
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        AppIcon("ph-x-circle", size: 18)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 24)

                        Text(message)
                            .font(AppFonts.bodyFont(13))
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    Divider()
                        .background(AppColors.gold.opacity(0.2))

                    ActionRow(
                        icon: "ph-arrow-counter-clockwise",
                        title: String(localized: "Try Again", comment: "Settings, Offline: a row's name"),
                        subtitle: String(localized: "Already-downloaded files are kept", comment: "Settings, Offline: the line under a row")
                    ) {
                        Task { await service.downloadAll() }
                    }

                    // A partial download must always be reclaimable
                    if service.hasContentOnDisk {
                        Divider()
                            .background(AppColors.gold.opacity(0.2))

                        removeRow
                    }
                }
            }
        }
        .animation(Motion.crossfade, value: Self.stage(of: service.state))
    }

    private var removeRow: some View {
        ActionRow(
            icon: "ph-trash",
            title: String(localized: "Remove Downloads", comment: "Settings, Offline: a row's name"),
            subtitle: String(localized: "Frees storage; streaming still works online", comment: "Settings, Offline: the line under a row")
        ) {
            showRemoveConfirm = true
        }
    }
}

// MARK: - Chants Saved Line

/// How many of the chants are on the phone. They come down by themselves
/// on Wi-Fi, and stream until they do, so this only says how far that has
/// gone: never a control, never a count of what is missing.
struct ChantsSavedLine: View {
    private var assets = ChantAssetStore.shared

    var body: some View {
        let total = ChantCatalog.all.count
        let saved = assets.savedCount(of: ChantCatalog.all)
        Text(saved >= total ? "All chants saved" : "Chants: \(saved) of \(total) saved")
            .font(AppFonts.bodyFont(13))
            .foregroundColor(AppColors.textSecondary)
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(Motion.crossfade, value: saved)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        // The whole row is the switch: a tap on the words once did
        // nothing, which read as a setting that would not change. The
        // switch is drawn but takes no touches of its own — left live
        // inside a row that also answered taps, a tap on it reached both,
        // and the setting flipped twice and stayed where it was.
        Button {
            withAnimation(Motion.settle) { isOn.toggle() }
        } label: {
            HStack(spacing: 16) {
                AppIcon(icon, size: 18)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppFonts.bodyFont(12))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                Toggle(title, isOn: $isOn)
                    .labelsHidden()
                    .tint(AppColors.gold)
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? Text("On", comment: "VoiceOver: a switch is on") : Text("Off", comment: "VoiceOver: a switch is off"))
        .accessibilityHint(subtitle ?? "")
        .accessibilityAddTraits(.isToggle)
    }
}

// MARK: - App Language Row

/// The language the app's words are shown in, with the system's page for
/// this app behind it; in Spanish, the AI translation notice beneath
struct AppLanguageRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ActionRow(
                icon: "ph-globe",
                title: String(localized: "App Language", comment: "Settings: row naming the language the app's words are shown in; a tap opens the iPhone's settings page for this app, where the language is chosen"),
                subtitle: AppLanguage.name,
                action: AppLanguage.openLanguageSettings
            )
            .accessibilityHint(Text("Opens this app's page in the iPhone's Settings, where its language is chosen", comment: "VoiceOver hint, Settings: what a tap on the App Language row does"))

            if AppLanguage.isSpanish {
                Text(AppLanguage.translationNotice)
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
        }
    }
}

// MARK: - Action Row (tappable, no navigation value)

struct ActionRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                AppIcon(icon, size: 18)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(AppColors.cream)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppFonts.bodyFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                AppIcon("ph-caret-right", size: 13)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Text Size Row

struct TextSizeRow: View {
    @Binding var value: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                AppIcon("ph-text-aa", size: 18)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Text Size")
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(AppColors.cream)

                    Text("The words of prayers and meditations")
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Text("A")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(AppColors.textSecondary)

                Slider(value: $value, in: 0...1)
                    .tint(AppColors.gold)

                Text("A")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Prayer Language Row

struct PrayerLanguageRow: View {
    @Binding var selectedLanguage: String

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                AppIcon("ph-globe", size: 18)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)

                Text("Prayer Language")
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(PrayerLanguage.allCases) { language in
                    Button(action: {
                        selectedLanguage = language.rawValue
                    }) {
                        HStack {
                            Text(Self.displayName(of: language))
                                .font(AppFonts.bodyFont(15))
                                .foregroundColor(
                                    selectedLanguage == language.rawValue
                                        ? AppColors.gold
                                        : AppColors.cream
                                )

                            Spacer()

                            if selectedLanguage == language.rawValue {
                                AppIcon("ph-check", size: 14)
                                    .foregroundColor(AppColors.gold)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    selectedLanguage == language.rawValue
                                        ? AppColors.gold.opacity(0.15)
                                        : AppColors.cardBackground.opacity(0.3)
                                )
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    /// What a language is called here: the one name onboarding uses too
    static func displayName(of language: PrayerLanguage) -> String {
        language.displayName
    }
}

// MARK: - Narration Voice Row

/// The voice the meditations are read in, set like the prayer language:
/// the name over the choices, each a row with a check on the chosen one.
/// The list is the server's (`NarrationVoiceCatalog`), so a voice added
/// there appears here without an app update.
struct NarrationVoiceRow: View {

    private var catalog: NarrationVoiceCatalog { .shared }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                AppIcon("ph-speaker-high", size: 18)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)

                Text(UserSettings.narrationVoiceTitle)
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(catalog.voices) { voice in
                    let selected = catalog.chosenSlug == voice.slug
                    Button(action: {
                        catalog.choose(voice)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(voice.displayName)
                                    .font(AppFonts.bodyFont(15))
                                    .foregroundColor(selected ? AppColors.gold : AppColors.cream)

                                if let description = voice.plainDescription, !description.isEmpty {
                                    Text(description)
                                        .font(AppFonts.bodyFont(13))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }

                            Spacer()

                            if selected {
                                AppIcon("ph-check", size: 14)
                                    .foregroundColor(AppColors.gold)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    selected
                                        ? AppColors.gold.opacity(0.15)
                                        : AppColors.cardBackground.opacity(0.3)
                                )
                        )
                    }
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .task { await catalog.refresh() }
    }
}

// MARK: - Reminder Time Row

struct ReminderTimeRow: View {
    @Binding var hour: Int
    @Binding var minute: Int

    // Build a Date from current hour/minute for the DatePicker
    private var reminderDate: Binding<Date> {
        Binding(
            get: {
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                comps.hour = hour
                comps.minute = minute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                hour = comps.hour ?? 6
                minute = comps.minute ?? 0
            }
        )
    }

    var body: some View {
        HStack(spacing: 16) {
            AppIcon("ph-clock", size: 18)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 24)

            Text("Reminder Time")
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.cream)

            Spacer()

            DatePicker(
                "",
                selection: reminderDate,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .colorScheme(.dark)
            .accentColor(AppColors.gold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Account Footer

struct AccountFooter: View {
    var body: some View {
        VStack(spacing: 10) {
            OrnamentDivider()
                .frame(width: 170)
                .padding(.bottom, 4)

            AppIcon("ch-church", size: 28)
                .foregroundColor(AppColors.gold.opacity(0.5))

            Text("Lumen Viae v\(Bundle.main.appVersion)")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)

            Text("For the greater glory of God")
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.gold.opacity(0.6))
        }
    }
}

// MARK: - About Sheet

struct AboutSheet: View {
    var body: some View {
        // The app's colophon keeps its centred masthead rather than a
        // sheet header: the wordmark is the page's subject, not a label
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Icon
                VStack(spacing: 16) {
                    AppIcon("lv-rosary", size: 52)
                        .foregroundColor(AppColors.gold)

                    Text("Lumen Viae")
                        .font(AppFonts.headlineFont(28))
                        .foregroundColor(AppColors.cream)

                    Text("Light of the Way")
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.gold.opacity(0.8))
                }
                // The room the hand-drawn grabber and its gap once took
                .padding(.top, 48)

                // Description
                VStack(alignment: .leading, spacing: 16) {
                    InfoBlock(
                        title: String(localized: "Our Mission", comment: "About Lumen Viae: a section heading"),
                        text: String(localized: "Lumen Viae helps you pray the Rosary each day, with a short reading for every mystery, and keeps the Church's other prayers close at hand. The mysteries are scenes from the lives of Jesus and Mary: the Joyful, Sorrowful, Glorious and Luminous, and the Seven Sorrows of Mary.", comment: "About Lumen Viae: a section's text")
                    )

                    InfoBlock(
                        title: String(localized: "How to Pray the Rosary", comment: "About Lumen Viae: a section heading"),
                        text: String(localized: "A Rosary has five mysteries. For each one, think on its scene and pray one Our Father, ten Hail Marys, a Glory Be and the Fatima Prayer, together called a decade. The app guides you through all five, with an optional meditation for each: a short reading from a saint or from Scripture.", comment: "About Lumen Viae: a section's text")
                    )

                    InfoBlock(
                        title: String(localized: "Daily Schedule", comment: "About Lumen Viae: a section heading"),
                        text: String(localized: "The traditional schedule assigns a set of mysteries to each day of the week: Joyful on Monday and Thursday; Sorrowful on Tuesday and Friday; Glorious on Wednesday and Saturday. Sunday follows the season — Joyful in Advent, Sorrowful in Lent, and Glorious the rest of the year. The modern schedule, St. John Paul II's, gives Thursday to the Luminous and Saturday to the Joyful; choose it in Settings, under Devotion.", comment: "About Lumen Viae: a section's text")
                    )
                }
                .padding(.horizontal, SheetMetrics.gutter)

                // Version
                VStack(spacing: 4) {
                    Text("Version \(Bundle.main.appVersion)")
                        .font(AppFonts.bodyFont(13))
                        .foregroundColor(AppColors.textSecondary)

                    Text("For the greater glory of God")
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.gold.opacity(0.6))
                }
                .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity)
        }
        .sheetGround()
    }
}

// MARK: - Privacy Policy Sheet

struct PrivacyPolicySheet: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    kicker: "Lumen Viae",
                    title: String(localized: "Privacy Policy", comment: "Privacy Policy: a heading, or the date the policy was last changed"),
                    lead: String(localized: "Last updated: September 2026", comment: "Privacy Policy: a heading, or the date the policy was last changed")
                )

                // Keep in step with PrivacyInfo.xcprivacy and App Store
                // Connect's App Privacy answers: what reaches us is
                // APIService.recordCompletion, and nothing else.
                VStack(alignment: .leading, spacing: 28) {
                    InfoBlock(
                        title: String(localized: "What Stays on Your Phone", comment: "Privacy Policy: a heading, or the date the policy was last changed"),
                        text: String(localized: "Almost everything. Your journal, your prayer record and streak, your place in every book and your settings are kept on this device and never sent to us. They leave it only in your iPhone's own iCloud Backup, if you have it on, under Apple's privacy policy.", comment: "Privacy Policy: a section's text; keep it as plain and exact as the English")
                    )

                    InfoBlock(
                        title: String(localized: "What Reaches Us", comment: "Privacy Policy: a heading, or the date the policy was last changed"),
                        text: String(localized: "One short note, when you finish a Rosary prayed with meditations: which meditations they were, and whether you listened to the Whole Rosary. Our server keeps it with the time and an approximate city, region and country, looked up through ipapi.co from the address your phone connects from, and keeps that address only in a shortened form. No name, account or device identifier goes with it, so two Rosaries prayed on one phone look like two prayed by strangers. We use these notes only to learn which meditations are prayed, and roughly where. The Scriptural Rosary, the Audio Rosary and the guided Rosary send nothing, and nothing else reaches us unless you write to us.", comment: "Privacy Policy: a section's text; keep it as plain and exact as the English")
                    )

                    InfoBlock(
                        title: String(localized: "What the App Fetches", comment: "Privacy Policy: a heading, or the date the policy was last changed"),
                        text: String(localized: "Meditations, narration, the Hours of Prayer (the Divine Office), the words of the prayers, and the chants' recordings and sheet music come from our own server; the Mass texts from Missale Meum; the books and recordings under Spiritual Reading from Project Gutenberg and LibriVox. Each receives the request itself, as any website does, and nothing more. The app carries no analytics or advertising code from anyone else, and nothing is used to track you.", comment: "Privacy Policy: a section's text; keep it as plain and exact as the English")
                    )

                    InfoBlock(
                        title: String(localized: "Reminders", comment: "Privacy Policy: a heading, or the date the policy was last changed"),
                        text: String(localized: "Daily reminders and the Angelus bell are scheduled on your phone by iOS. We send no push notifications.", comment: "Privacy Policy: a section's text; keep it as plain and exact as the English")
                    )

                    InfoBlock(
                        title: String(localized: "Children's Privacy", comment: "Privacy Policy: a heading, or the date the policy was last changed"),
                        text: String(localized: "The app is suitable for all ages. It asks no one for a name, an email or an account, and nothing it sends can tell us who you are.", comment: "Privacy Policy: a section's text; keep it as plain and exact as the English")
                    )

                    InfoBlock(
                        title: String(localized: "Contact", comment: "Privacy Policy: a heading, or the date the policy was last changed"),
                        text: String(localized: "Questions about privacy? Reach us at \(Constants.supportEmail)", comment: "Privacy Policy: a section's text; keep it as plain and exact as the English")
                    )
                }
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .sheetGround()
    }
}

// MARK: - Help & Support Sheet

struct HelpSupportSheet: View {

    /// Opens the feedback form. Run by the host once this sheet has
    /// finished leaving.
    let onGiveFeedback: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(kicker: "Lumen Viae", title: String(localized: "Help & Support", comment: "The Help & Support sheet's title"))

                VStack(alignment: .leading, spacing: 28) {
                    InfoBlock(
                        title: String(localized: "How do I begin praying?", comment: "Help & Support: a question, or a button"),
                        text: String(localized: "From the home screen, tap \"Pray the Rosary\" under today's mysteries, or tap any mystery in the grid below. On the page that opens, choose a meditation (a short reading on each mystery), or another way to pray: the Scriptural Rosary, with a Bible verse for every Hail Mary, or the Audio Rosary, where you listen and pray along. The next page shows how you'll pray, the audio and the counting, just above Pray.", comment: "Help & Support: the answer to the question above it; names of buttons and settings must match the app's own words")
                    )

                    InfoBlock(
                        title: String(localized: "What are the different mysteries?", comment: "Help & Support: a question, or a button"),
                        text: String(localized: "The mysteries are scenes from the lives of Jesus and Mary, five to a Rosary. There are four sets of them. On the traditional schedule: Joyful (Monday, Thursday), Sorrowful (Tuesday, Friday), and Glorious (Wednesday, Saturday). Sunday takes Joyful in Advent, Sorrowful in Lent, and Glorious otherwise. The Luminous Mysteries, added by St. John Paul II in 2002, can be prayed any day from View All beside the home grid. The modern schedule (Settings, under Devotion) gives them Thursday and moves the Joyful to Saturday. The Seven Sorrows of Mary can be prayed on any day too.", comment: "Help & Support: the answer to the question above it; names of buttons and settings must match the app's own words")
                    )

                    InfoBlock(
                        title: String(localized: "How does audio work?", comment: "Help & Support: a question, or a button"),
                        text: String(localized: "Choose it on the Rosary's own page before you pray, or in Settings under The Rosary: with Meditation Only you hear the meditation and say the prayers yourself, and with Whole Rosary you hear every prayer, the beads moving with the voice. During the prayer, the play button starts and pauses the voice, and the buttons beside it move 10 seconds, or a whole prayer with Whole Rosary.", comment: "Help & Support: the answer to the question above it; names of buttons and settings must match the app's own words")
                    )

                    InfoBlock(
                        title: String(localized: "Why are some meditations unavailable?", comment: "Help & Support: a question, or a button"),
                        text: String(localized: "Meditations come from our server. If you're offline, or they haven't been added yet, some meditations may not be available. Check your internet connection and try again.", comment: "Help & Support: the answer to the question above it; names of buttons and settings must match the app's own words")
                    )

                    InfoBlock(
                        title: String(localized: "How do I adjust text size?", comment: "Help & Support: a question, or a button"),
                        text: String(localized: "On the home screen, tap the sliders at the top left, then Prayer Experience → Text Size. Drag the slider toward the larger \"A\" to increase the meditation text size.", comment: "Help & Support: the answer to the question above it; names of buttons and settings must match the app's own words")
                    )

                    InfoBlock(
                        title: String(localized: "Daily reminders aren't working", comment: "Help & Support: a question, or a button"),
                        text: String(localized: "Make sure notifications are enabled for Lumen Viae in your iPhone's Settings → Notifications. Then toggle Daily Reminders off and back on in the app to reschedule.", comment: "Help & Support: the answer to the question above it; names of buttons and settings must match the app's own words")
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        InfoBlock(
                            title: String(localized: "Contact Us", comment: "Help & Support: a question, or a button"),
                            text: String(localized: "Didn't find it here? Write to us in the app — we read every note.", comment: "Help & Support: the answer to the question above it; names of buttons and settings must match the app's own words")
                        )

                        QuietGoldButton(
                            title: String(localized: "Send feedback", comment: "Help & Support: a question, or a button"),
                            leadingIcon: "ph-chat-teardrop-text",
                            horizontalPadding: 0,
                            action: onGiveFeedback
                        )
                    }
                }
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .sheetGround()
    }
}

// MARK: - Info Block (shared by sheets)

private struct InfoBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.headlineFont(16))
                .foregroundColor(AppColors.gold)

            Text(text)
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    AccountView()
        .environment(UserSettings.shared)
        .environment(AppRouter())
}

// MARK: - AfterTheRosarySheet

/// One Rosary beta: the prayers said after the Rosary's closing prayer,
/// each off until chosen, in a sheet of their own so the Rosary's section
/// of Settings stays short
struct AfterTheRosarySheet: View {
    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: String(localized: "After the Rosary", comment: "One Rosary beta, Settings: the title of the sheet of prayers said after the Rosary")) {
                    SheetHeaderAction(title: String(localized: "Done", comment: "Sheet header button that closes the sheet")) { dismiss() }
                }

                ForEach(RosaryClosingExtra.allCases, id: \.self) { extra in
                    ToggleRow(
                        icon: extra.icon,
                        title: extra.title,
                        subtitle: extra.detail,
                        isOn: Binding(
                            get: { userSettings.isChosen(extra) },
                            set: { userSettings.setChosen(extra, $0) }
                        )
                    )

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                }

                Text(userSettings.prayAloud
                     ? String(localized: "Played after the closing prayer.", comment: "Settings: the line under a row")
                     : String(localized: "Played after the closing prayer, when the Whole Rosary is chosen.", comment: "One Rosary beta, Settings, the After the Rosary sheet: the line under the prayers while the Whole Rosary is not chosen"))
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .padding(.bottom, 20)
        }
        .sheetGround()
    }
}
