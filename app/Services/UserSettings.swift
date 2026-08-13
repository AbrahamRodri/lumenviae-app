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
    /// Maps to a point-size range of 14–22 pt.
    var textSizeScale: Double = 0.5 {
        didSet { UserDefaults.standard.set(textSizeScale, forKey: "userSettings.textSizeScale") }
    }

    /// Resolved font size for meditation content
    var meditationFontSize: CGFloat {
        CGFloat(14 + textSizeScale * 8) // 14–22 pt
    }

    // MARK: - Prayer View Mode

    /// Whether the prayer flow opens in full-bleed image mode (vs. reading
    /// mode). Persisted so the preference survives between sessions.
    var prayerImageMode: Bool = true {
        didSet { UserDefaults.standard.set(prayerImageMode, forKey: "userSettings.prayerImageMode") }
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

    /// Human-readable reminder time string, e.g. "6:00 AM"
    var reminderTimeLabel: String {
        let hour = reminderHour % 12 == 0 ? 12 : reminderHour % 12
        let minute = String(format: "%02d", reminderMinute)
        let period = reminderHour < 12 ? "AM" : "PM"
        return "\(hour):\(minute) \(period)"
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
        if d.object(forKey: "userSettings.prayerImageMode") != nil {
            prayerImageMode = d.bool(forKey: "userSettings.prayerImageMode")
        }
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
