//
//  UserSettings.swift
//  Lumen Viae
//
//  Persisted user preferences backed by UserDefaults.
//  Inject into the environment and read from any view.
//

import SwiftUI
import UserNotifications
import Foundation

// MARK: - Prayer Language Preference

enum PrayerLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case latin = "Latin"
    case both = "Latin & English"
    case latinUnderEnglish = "English & Latin"

    var id: String { rawValue }

    /// True when this mode shows a translation beneath each prayer line
    var isBilingual: Bool { self == .both || self == .latinUnderEnglish }
}

// MARK: - Missal Layout

/// How the Daily Missal sets a bilingual passage: the translation
/// beneath each line, or the two languages in facing columns like a
/// printed hand missal.
enum MissalLayout: String, CaseIterable, Identifiable {
    case interlinear = "Line by Line"
    case sideBySide = "Side by Side"

    var id: String { rawValue }
}

// MARK: - Missal Scope

/// What the missal's page carries: the day's propers alone, or the
/// propers with the Ordinary — Kyrie, Gloria, Preface, Canon — let
/// into their places and set one tier quieter.
enum MissalScope: String, CaseIterable, Identifiable {
    case propersOnly = "Propers Only"
    case full = "With the Ordinary"

    var id: String { rawValue }
}


// MARK: - Prayer Intention

/// What draws the user to the Rosary, chosen during onboarding.
/// Used to personalize copy — never to gate features.
enum PrayerIntention: String, CaseIterable, Identifiable {
    case peace = "Peace & Stillness"
    case habit = "A Daily Habit"
    case devotion = "Closer to Our Lady"
    case learning = "Learning the Rosary"

    var id: String { rawValue }
}

// MARK: - Reminder Sound

/// A bundled notification sound. Every recording here is public domain
/// (pdsounds.org / Wikimedia Commons), trimmed, faded, and normalized
/// for use as an iOS notification sound (.caf, mono, under 30s).
struct ReminderSound: Identifiable, Equatable {
    /// Bundle file name including extension, e.g. "church_bell.caf"
    let fileName: String

    /// Name shown in the picker
    let displayName: String

    /// One-line description of the sound's character
    let detail: String

    /// SF Symbol shown next to the sound in the picker
    let icon: String

    var id: String { fileName }

    static let all: [ReminderSound] = [
        ReminderSound(
            fileName: "church_bell.caf",
            displayName: "Church Bells",
            detail: "A full peal of church bells",
            icon: "ph-bell-fill"
        ),
        ReminderSound(
            fileName: "altar_bell.caf",
            displayName: "Altar Bell",
            detail: "A single strike of a small bronze bell",
            icon: "ph-bell"
        ),
        ReminderSound(
            fileName: "harp.caf",
            displayName: "Harp of David",
            detail: "A gentle harp glissando",
            icon: "ph-music-note"
        ),
        ReminderSound(
            fileName: "songbird.caf",
            displayName: "Songbird",
            detail: "A hermit thrush at dawn in Yosemite",
            icon: "ph-bird"
        )
    ]

    static let `default` = all[0]
}

// MARK: - UserSettings

@Observable
final class UserSettings {

    // MARK: - Singleton

    static let shared = UserSettings()

    // MARK: - Text Size

    /// Meditation content font size scale (0.0 = small, 1.0 = large).
    /// Maps to a point-size range of 16–24 pt.
    var textSizeScale: Double = 0.5 {
        didSet { UserDefaults.standard.set(textSizeScale, forKey: "userSettings.textSizeScale") }
    }

    /// Resolved font size for meditation content. The middle of the range
    /// — the default — is 20 pt: reading size, not caption size.
    var meditationFontSize: CGFloat {
        CGFloat(16 + textSizeScale * 8) // 16–24 pt
    }

    // MARK: - Prayer View Mode

    /// Whether the prayer flow opens in full-bleed image mode (vs. reading
    /// mode). Persisted so the preference survives between sessions.
    var prayerImageMode: Bool = true {
        didSet { UserDefaults.standard.set(prayerImageMode, forKey: "userSettings.prayerImageMode") }
    }

    // MARK: - Reader

    /// Whether the reader keeps pace with the narration on its own,
    /// carrying the page from paragraph to paragraph as the voice reads.
    ///
    /// On by default — following along is the point of reading while
    /// listening — but some people hold their own place, so it is a
    /// toggle in the reader's text options rather than a fixed behavior.
    var readerAutoScroll: Bool = true {
        didSet { UserDefaults.standard.set(readerAutoScroll, forKey: "userSettings.readerAutoScroll") }
    }

    // MARK: - Scriptural Rosary

    /// Whether each Hail Mary bead carries its own verse of Scripture —
    /// the slower, more intensive form of the prayer. Off by default;
    /// the plain Rosary is the app's first face.
    var scripturalRosaryEnabled: Bool = false {
        didSet { UserDefaults.standard.set(scripturalRosaryEnabled, forKey: "userSettings.scripturalRosary") }
    }

    /// Whether the swipe-between-mysteries hint has been shown.
    ///
    /// The gesture is a shortcut for something the arrows already do, so
    /// the hint is a courtesy, not an instruction — it appears on a first
    /// Rosary and never again.
    var hasSeenPrayerSwipeHint: Bool = false {
        didSet { UserDefaults.standard.set(hasSeenPrayerSwipeHint, forKey: "userSettings.hasSeenPrayerSwipeHint") }
    }

    // MARK: - Prayer Language

    /// Prayer language preference for devotional prayers
    var prayerLanguagePreference: String = PrayerLanguage.both.rawValue {
        didSet { UserDefaults.standard.set(prayerLanguagePreference, forKey: "userSettings.prayerLanguage") }
    }

    /// Resolved prayer language enum
    var prayerLanguage: PrayerLanguage {
        PrayerLanguage(rawValue: prayerLanguagePreference) ?? .both
    }

    // MARK: - Missal Layout

    /// Empty until the missal's first-open question has been answered,
    /// so the missal knows to ask it
    var missalLayoutPreference: String = "" {
        didSet { UserDefaults.standard.set(missalLayoutPreference, forKey: "userSettings.missalLayout") }
    }

    /// Resolved missal layout enum
    var missalLayout: MissalLayout {
        MissalLayout(rawValue: missalLayoutPreference) ?? .interlinear
    }

    /// Whether the missal's first-open layout choice has been made
    var hasChosenMissalLayout: Bool { !missalLayoutPreference.isEmpty }

    /// Propers alone, or the full Mass with the Ordinary interleaved
    var missalScopeRaw: String = MissalScope.full.rawValue {
        didSet { UserDefaults.standard.set(missalScopeRaw, forKey: "userSettings.missalScope") }
    }

    var missalScope: MissalScope {
        MissalScope(rawValue: missalScopeRaw) ?? .full
    }

    /// The missal reader's own text scale (0 = small, 1 = large),
    /// mapping to 15–21 pt. Its own slider rather than the app-wide one:
    /// a hand missal is dense, and its comfortable sizes sit a step
    /// below the meditation reader's.
    var missalTextScale: Double = 1.0 / 3.0 {
        didSet { UserDefaults.standard.set(missalTextScale, forKey: "userSettings.missalTextScale") }
    }

    /// Resolved missal reading size in points
    var missalFontSize: CGFloat {
        (15 + CGFloat(missalTextScale) * 6).rounded()
    }

    /// Whether the missal marks stand, sit and kneel in the text
    var missalPostureCues: Bool = true {
        didSet { UserDefaults.standard.set(missalPostureCues, forKey: "userSettings.missalPostureCues") }
    }

    /// Whether the missal reads as the sung (High) Mass: the Asperges on
    /// Sundays and the incensing appear, and the Leonine prayers — said
    /// after Low Mass — fall away.
    var missalHighMass: Bool = false {
        didSet { UserDefaults.standard.set(missalHighMass, forKey: "userSettings.missalHighMass") }
    }

    // MARK: - Onboarding Intentions

    /// What drew the user to the app, chosen during onboarding and editable
    /// in Account. May be empty (the slide is skippable). Raw values rather
    /// than enum cases so the stored form survives a rename of the enum.
    var onboardingIntentions: [String] = [] {
        didSet {
            UserDefaults.standard.set(onboardingIntentions, forKey: "userSettings.onboardingIntentions")
            Task { await syncNotifications() }
        }
    }

    /// Resolved intentions, in the enum's own order so the reminder pools
    /// interleave the same way no matter what order the user tapped them.
    var intentions: [PrayerIntention] {
        let chosen = Set(onboardingIntentions)
        return PrayerIntention.allCases.filter { chosen.contains($0.rawValue) }
    }

    func hasIntention(_ intention: PrayerIntention) -> Bool {
        onboardingIntentions.contains(intention.rawValue)
    }

    func toggleIntention(_ intention: PrayerIntention) {
        if let index = onboardingIntentions.firstIndex(of: intention.rawValue) {
            onboardingIntentions.remove(at: index)
        } else {
            onboardingIntentions.append(intention.rawValue)
        }
    }

    // MARK: - Daily Reminders

    var remindersEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(remindersEnabled, forKey: "userSettings.remindersEnabled")
            Task { await syncNotifications() }
        }
    }

    var reminderHour: Int = 6 {
        didSet {
            UserDefaults.standard.set(reminderHour, forKey: "userSettings.reminderHour")
            Task { await syncNotifications() }
        }
    }

    var reminderMinute: Int = 0 {
        didSet {
            UserDefaults.standard.set(reminderMinute, forKey: "userSettings.reminderMinute")
            Task { await syncNotifications() }
        }
    }

    /// Reused; also follows the device's 12/24-hour setting and locale,
    /// which the hand-rolled "h:mm AM/PM" string this replaced could not —
    /// it showed "6:00 PM" to a user whose phone reads 18:00 everywhere
    /// else, and left "AM"/"PM" in English in every language.
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    /// Human-readable reminder time string, e.g. "6:00 AM" or "18:00"
    var reminderTimeLabel: String {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        guard let date = Calendar.current.date(from: components) else {
            return "\(reminderHour):\(String(format: "%02d", reminderMinute))"
        }
        return Self.timeFormatter.string(from: date)
    }

    /// Bundle file name of the chosen reminder sound
    var reminderSoundFile: String = ReminderSound.default.fileName {
        didSet {
            UserDefaults.standard.set(reminderSoundFile, forKey: "userSettings.reminderSound")
            Task { await syncNotifications() }
        }
    }

    /// Resolved reminder sound (falls back to the default if the stored
    /// file name no longer exists in the catalog)
    var reminderSound: ReminderSound {
        ReminderSound.all.first { $0.fileName == reminderSoundFile } ?? .default
    }

    // MARK: - Personal Page (Me)

    /// The name the Me page greets. Empty means the default salutation.
    var displayName: String = "" {
        didSet { UserDefaults.standard.set(displayName, forKey: "userSettings.displayName") }
    }

    /// The sections on the Me page, in the user's order. Only enabled
    /// sections are stored; removing one deletes nothing underneath it —
    /// a hidden streak keeps counting, hidden reflections keep saving.
    var meWidgetsRaw: [String] = MeWidget.defaultOrder.map(\.rawValue) {
        didSet { UserDefaults.standard.set(meWidgetsRaw, forKey: "userSettings.meWidgets") }
    }

    var meWidgets: [MeWidget] { MeWidget.decode(meWidgetsRaw) }

    func setMeWidgets(_ widgets: [MeWidget]) {
        meWidgetsRaw = widgets.map(\.rawValue)
    }

    // MARK: - Pray Button

    /// What a quick tap of the raised Pray button does. Today's Rosary
    /// unless the user chooses otherwise.
    var prayQuickActionRaw: String = PrayerShortcut.todaysRosary.rawValue {
        didSet { UserDefaults.standard.set(prayQuickActionRaw, forKey: "userSettings.prayQuickAction") }
    }

    var prayQuickAction: PrayerShortcut {
        PrayerShortcut(rawValue: prayQuickActionRaw) ?? .todaysRosary
    }

    /// The acts in the Pray button's press-and-hold tray, in order.
    var prayTrayRaw: [String] = [
        PrayerShortcut.todaysRosary.rawValue,
        PrayerShortcut.chooseMeditation.rawValue,
        PrayerShortcut.mass.rawValue,
        PrayerShortcut.office.rawValue
    ] {
        didSet { UserDefaults.standard.set(prayTrayRaw, forKey: "userSettings.prayTray") }
    }

    var prayTrayShortcuts: [PrayerShortcut] { PrayerShortcut.decode(prayTrayRaw) }

    func setPrayTray(_ shortcuts: [PrayerShortcut]) {
        prayTrayRaw = shortcuts.map(\.rawValue)
    }

    // MARK: - Rule of Prayer

    /// The devotions in the user's daily rule, in order.
    var ruleItemsRaw: [String] = [
        PrayerShortcut.todaysRosary.rawValue,
        PrayerShortcut.mass.rawValue
    ] {
        didSet { UserDefaults.standard.set(ruleItemsRaw, forKey: "userSettings.ruleItems") }
    }

    var ruleItems: [PrayerShortcut] { PrayerShortcut.decode(ruleItemsRaw) }

    func setRuleItems(_ items: [PrayerShortcut]) {
        ruleItemsRaw = items.map(\.rawValue)
    }

    /// Day stamp the manual rule checks belong to. Checks from an earlier
    /// day are ignored rather than erased — the rule starts each morning
    /// unmarked, and yesterday is never called a failure.
    private var ruleCheckedDate: String = "" {
        didSet { UserDefaults.standard.set(ruleCheckedDate, forKey: "userSettings.ruleCheckedDate") }
    }

    /// Raw values of rule items hand-checked today (the acts the app
    /// cannot see finish on its own, like the Mass or an Office hour).
    private var ruleCheckedRaw: [String] = [] {
        didSet { UserDefaults.standard.set(ruleCheckedRaw, forKey: "userSettings.ruleChecked") }
    }

    private static let dayStampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var todayStamp: String {
        Self.dayStampFormatter.string(from: Date())
    }

    func isRuleChecked(_ item: PrayerShortcut) -> Bool {
        ruleCheckedDate == todayStamp && ruleCheckedRaw.contains(item.rawValue)
    }

    func setRuleChecked(_ item: PrayerShortcut, _ done: Bool) {
        if ruleCheckedDate != todayStamp {
            ruleCheckedDate = todayStamp
            ruleCheckedRaw = []
        }
        if done {
            if !ruleCheckedRaw.contains(item.rawValue) {
                ruleCheckedRaw.append(item.rawValue)
            }
        } else {
            ruleCheckedRaw.removeAll { $0 == item.rawValue }
        }
    }

    /// Whether notification permission has been granted
    var notificationAuthorizationGranted: Bool = false

    /// Whether the user has denied notifications at the OS level.
    /// Drives the "enable in Settings" affordance when reminders are on
    /// but nothing can actually fire.
    var notificationAuthorizationDenied: Bool = false

    // MARK: - Initialization

    private init() {
        let d = UserDefaults.standard

        if d.object(forKey: "userSettings.textSizeScale") != nil {
            textSizeScale = d.double(forKey: "userSettings.textSizeScale")
        }
        if d.object(forKey: "userSettings.prayerLanguage") != nil {
            prayerLanguagePreference = d.string(forKey: "userSettings.prayerLanguage") ?? PrayerLanguage.both.rawValue
        }
        hasSeenPrayerSwipeHint = d.bool(forKey: "userSettings.hasSeenPrayerSwipeHint")
        if d.object(forKey: "userSettings.readerAutoScroll") != nil {
            readerAutoScroll = d.bool(forKey: "userSettings.readerAutoScroll")
        }
        if d.object(forKey: "userSettings.prayerImageMode") != nil {
            prayerImageMode = d.bool(forKey: "userSettings.prayerImageMode")
        }
        scripturalRosaryEnabled = d.bool(forKey: "userSettings.scripturalRosary")
        if d.object(forKey: "userSettings.missalLayout") != nil {
            missalLayoutPreference = d.string(forKey: "userSettings.missalLayout") ?? ""
        }
        if let scope = d.string(forKey: "userSettings.missalScope") {
            missalScopeRaw = scope
        }
        if d.object(forKey: "userSettings.missalTextScale") != nil {
            missalTextScale = d.double(forKey: "userSettings.missalTextScale")
        }
        if d.object(forKey: "userSettings.missalPostureCues") != nil {
            missalPostureCues = d.bool(forKey: "userSettings.missalPostureCues")
        }
        missalHighMass = d.bool(forKey: "userSettings.missalHighMass")
        if let stored = d.stringArray(forKey: "userSettings.onboardingIntentions") {
            onboardingIntentions = stored
        } else if let legacy = d.string(forKey: "userSettings.onboardingIntention"), !legacy.isEmpty {
            // Migration: the intention used to be a single choice.
            onboardingIntentions = [legacy]
        }
        if d.object(forKey: "userSettings.remindersEnabled") != nil {
            remindersEnabled = d.bool(forKey: "userSettings.remindersEnabled")
        }
        if d.object(forKey: "userSettings.reminderHour") != nil {
            reminderHour = d.integer(forKey: "userSettings.reminderHour")
        }
        if d.object(forKey: "userSettings.reminderMinute") != nil {
            reminderMinute = d.integer(forKey: "userSettings.reminderMinute")
        }
        if d.object(forKey: "userSettings.reminderSound") != nil {
            reminderSoundFile = d.string(forKey: "userSettings.reminderSound") ?? ReminderSound.default.fileName
        }
        if let name = d.string(forKey: "userSettings.displayName") {
            displayName = name
        }
        if let widgets = d.stringArray(forKey: "userSettings.meWidgets") {
            meWidgetsRaw = widgets
        }
        if let quick = d.string(forKey: "userSettings.prayQuickAction") {
            prayQuickActionRaw = quick
        }
        if let tray = d.stringArray(forKey: "userSettings.prayTray") {
            prayTrayRaw = tray
        }
        if let rule = d.stringArray(forKey: "userSettings.ruleItems") {
            ruleItemsRaw = rule
        }
        ruleCheckedDate = d.string(forKey: "userSettings.ruleCheckedDate") ?? ""
        ruleCheckedRaw = d.stringArray(forKey: "userSettings.ruleChecked") ?? []

        // One-time: the Library card replaced the home screen's menu
        // button, so a page saved before it existed gains it once —
        // after that, removing it is the user's choice and sticks.
        if !d.bool(forKey: "userSettings.libraryCardMigrated") {
            d.set(true, forKey: "userSettings.libraryCardMigrated")
            if !meWidgetsRaw.contains(MeWidget.library.rawValue) {
                let at = min(2, meWidgetsRaw.count)
                meWidgetsRaw.insert(MeWidget.library.rawValue, at: at)
            }
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationAuthorizationGranted =
                    settings.authorizationStatus == .authorized ||
                    settings.authorizationStatus == .provisional
            }
        }
    }

    // MARK: - Notifications

    @MainActor
    func syncNotifications() async {
        let center = UNUserNotificationCenter.current()

        guard remindersEnabled else {
            cancelDailyReminder()
            return
        }

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            notificationAuthorizationGranted = granted
            notificationAuthorizationDenied = !granted
            if !granted {
                remindersEnabled = false
                return
            }
        case .denied:
            // Keep the user's intent (toggle stays on) but don't schedule
            // requests that can never fire; Account surfaces the fix.
            notificationAuthorizationGranted = false
            notificationAuthorizationDenied = true
            return
        default:
            notificationAuthorizationGranted = true
            notificationAuthorizationDenied = false
        }

        scheduleDailyReminder()
    }

    /// Re-syncs scheduled reminders with stored settings at launch and on
    /// foreground. Never prompts for permission — the request stays where
    /// the user can see why (onboarding or the Account toggle). Needed
    /// because property observers don't fire during `init`, so nothing
    /// else schedules reminders for a user who never touches the toggle.
    @MainActor
    func syncNotificationsAtLaunch() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationAuthorizationGranted =
            settings.authorizationStatus == .authorized ||
            settings.authorizationStatus == .provisional
        notificationAuthorizationDenied = settings.authorizationStatus == .denied

        guard remindersEnabled else {
            cancelDailyReminder()
            return
        }
        if notificationAuthorizationGranted {
            scheduleDailyReminder()
        }
    }

    /// One request per weekday so the message varies day to day
    /// instead of repeating the same line every morning.
    private var reminderIdentifiers: [String] {
        (1...7).map { "lumenviae.dailyReminder.\($0)" }
    }

    /// The week's messages, drawn from the pools the user's intentions
    /// select. Seven slots; the pool is sampled round-robin so a
    /// multi-intention week hears from each of them, and `offset` walks the
    /// selection forward as the days pass so no weekday ossifies onto one
    /// line. Falls back to the default pool when nothing was chosen.
    private func reminderWeek(offset: Int) -> [ReminderMessage] {
        let pool = ReminderMessage.pool(for: intentions)
        guard !pool.isEmpty else { return [] }
        return (0..<7).map { pool[(offset + $0) % pool.count] }
    }

    /// Days elapsed since the reference date — a rotation counter that needs
    /// no storage and advances exactly once a day.
    private var rotationOffset: Int {
        Int(Date().timeIntervalSinceReferenceDate / 86_400)
    }

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)

        let week = reminderWeek(offset: rotationOffset)
        guard week.count == 7 else { return }

        for weekday in 1...7 {
            let message = week[weekday - 1]

            let content = UNMutableNotificationContent()
            content.title = message.title
            content.body = message.body
            content.sound = UNNotificationSound(
                named: UNNotificationSoundName(reminderSound.fileName)
            )

            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = reminderHour
            dateComponents.minute = reminderMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "lumenviae.dailyReminder.\(weekday)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
    }
}
