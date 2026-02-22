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
        if d.object(forKey: "userSettings.remindersEnabled") != nil {
            remindersEnabled = d.bool(forKey: "userSettings.remindersEnabled")
        }
        if d.object(forKey: "userSettings.reminderHour") != nil {
            reminderHour = d.integer(forKey: "userSettings.reminderHour")
        }
        if d.object(forKey: "userSettings.reminderMinute") != nil {
            reminderMinute = d.integer(forKey: "userSettings.reminderMinute")
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

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["lumenviae.dailyReminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to pray the Rosary"
        content.body = "A moment of prayer brings peace to the soul."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "lumenviae.dailyReminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    private func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["lumenviae.dailyReminder"])
    }
}
