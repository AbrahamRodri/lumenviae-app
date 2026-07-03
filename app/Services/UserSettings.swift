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
            icon: "bell.fill"
        ),
        ReminderSound(
            fileName: "altar_bell.caf",
            displayName: "Altar Bell",
            detail: "A single strike of a small bronze bell",
            icon: "bell"
        ),
        ReminderSound(
            fileName: "harp.caf",
            displayName: "Harp of David",
            detail: "A gentle harp glissando",
            icon: "music.note"
        ),
        ReminderSound(
            fileName: "songbird.caf",
            displayName: "Songbird",
            detail: "A hermit thrush at dawn in Yosemite",
            icon: "bird"
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

    // MARK: - Prayer Language

    /// Prayer language preference for devotional prayers
    var prayerLanguagePreference: String = PrayerLanguage.both.rawValue {
        didSet { UserDefaults.standard.set(prayerLanguagePreference, forKey: "userSettings.prayerLanguage") }
    }

    /// Resolved prayer language enum
    var prayerLanguage: PrayerLanguage {
        PrayerLanguage(rawValue: prayerLanguagePreference) ?? .both
    }

    // MARK: - Onboarding Intention

    /// What drew the user to the app, chosen during onboarding (may be empty).
    var onboardingIntention: String = "" {
        didSet { UserDefaults.standard.set(onboardingIntention, forKey: "userSettings.onboardingIntention") }
    }

    /// Resolved intention enum, if one was chosen
    var intention: PrayerIntention? {
        PrayerIntention(rawValue: onboardingIntention)
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

    // MARK: - Initialization

    private init() {
        let d = UserDefaults.standard

        if d.object(forKey: "userSettings.textSizeScale") != nil {
            textSizeScale = d.double(forKey: "userSettings.textSizeScale")
        }
        if d.object(forKey: "userSettings.prayerLanguage") != nil {
            prayerLanguagePreference = d.string(forKey: "userSettings.prayerLanguage") ?? PrayerLanguage.both.rawValue
        }
        if d.object(forKey: "userSettings.onboardingIntention") != nil {
            onboardingIntention = d.string(forKey: "userSettings.onboardingIntention") ?? ""
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

        if remindersEnabled {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                notificationAuthorizationGranted = granted
                if !granted {
                    remindersEnabled = false
                    return
                }
            } else {
                notificationAuthorizationGranted =
                    settings.authorizationStatus == .authorized ||
                    settings.authorizationStatus == .provisional
            }
            scheduleDailyReminder()
        } else {
            cancelDailyReminder()
        }
    }

    /// Reminder copy rules: warm, short, invitational. Never mention the
    /// streak, never imply the user is behind, never scold. The reminder
    /// is a bell for the Angelus, not a debt collector.
    private static let reminderMessages: [(title: String, body: String)] = [
        ("A quiet moment awaits", "The Rosary is here whenever you are ready."),
        ("The mysteries await", "A few minutes of stillness amid the day."),
        ("Time for prayer, if you wish", "Peace begins with a single Ave."),
        ("Your candle is ready", "Light it with a moment of prayer."),
        ("Our Lady keeps a place for you", "Come sit with the mysteries a while."),
        ("An invitation to stillness", "The beads are waiting, without hurry."),
        ("Grace in the ordinary", "A decade of prayer can change the whole day.")
    ]

    /// One request per weekday so the message varies day to day
    /// instead of repeating the same line every morning.
    private var reminderIdentifiers: [String] {
        (1...7).map { "lumenviae.dailyReminder.\($0)" }
    }

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers + ["lumenviae.dailyReminder"])

        for weekday in 1...7 {
            let message = Self.reminderMessages[(weekday - 1) % Self.reminderMessages.count]

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
        // Includes the legacy single-reminder identifier from earlier versions
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: reminderIdentifiers + ["lumenviae.dailyReminder"])
    }
}
