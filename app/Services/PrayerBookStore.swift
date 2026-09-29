//
//  PrayerBookStore.swift
//  Lumen Viae
//
//  What the reader has made of the Prayer Book, kept on the device: the
//  prayers kept with a ribbon, the prayers they know by heart, which of
//  the orders of prayer have been offered today, whether the book prays
//  aloud, and whether the Angelus bell rings.
//
//  Nothing here counts against anyone. A ribbon is a place, a prayer
//  known by heart is the reader's own mark, and an order offered today is
//  forgotten tomorrow morning — never carried forward as a streak.
//

import Foundation
import UserNotifications

@Observable
final class PrayerBookStore {

    static let shared = PrayerBookStore()

    private let defaults: UserDefaults

    private enum Key {
        static let ribbons = "prayerBook.ribbons"
        static let byHeart = "prayerBook.byHeart"
        static let offered = "prayerBook.offered"
        static let aloud = "prayerBook.aloud"
        static let angelusBell = "prayerBook.angelusBell"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ribbons = defaults.stringArray(forKey: Key.ribbons) ?? []
        byHeart = Set(defaults.stringArray(forKey: Key.byHeart) ?? [])
        offered = (defaults.dictionary(forKey: Key.offered) as? [String: String]) ?? [:]
        praysAloud = defaults.object(forKey: Key.aloud) as? Bool ?? true
        hasChosenAloud = defaults.object(forKey: Key.aloud) != nil
        angelusBell = defaults.bool(forKey: Key.angelusBell)
    }

    // MARK: - Ribbons

    /// The prayers kept with a ribbon, the one kept last first
    private(set) var ribbons: [String] {
        didSet { defaults.set(ribbons, forKey: Key.ribbons) }
    }

    func isKept(_ prayerID: String) -> Bool {
        ribbons.contains(prayerID)
    }

    func toggleRibbon(_ prayerID: String) {
        if let index = ribbons.firstIndex(of: prayerID) {
            ribbons.remove(at: index)
        } else {
            ribbons.insert(prayerID, at: 0)
        }
    }

    /// The kept prayers the book still carries, in the order kept
    var keptPrayers: [BookPrayer] {
        ribbons.compactMap { PrayerBook.prayer($0) }
    }

    // MARK: - By Heart

    /// The prayers the reader has said are theirs by heart. Only ever a
    /// mark they make; the book never asks how many are left.
    private(set) var byHeart: Set<String> {
        didSet { defaults.set(Array(byHeart).sorted(), forKey: Key.byHeart) }
    }

    func isByHeart(_ prayerID: String) -> Bool {
        byHeart.contains(prayerID)
    }

    func setByHeart(_ prayerID: String, _ known: Bool) {
        if known { byHeart.insert(prayerID) } else { byHeart.remove(prayerID) }
    }

    // MARK: - Offered Today

    /// Order id → the day it was last prayed through to its Amen
    private var offered: [String: String] {
        didSet { defaults.set(offered, forKey: Key.offered) }
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// The book's day, not the calendar's: it turns at four in the
    /// morning, so Night Prayers said at half past twelve are offered for
    /// the night they close, and the next evening's page still asks for
    /// that evening's.
    private static func stamp(_ date: Date) -> String {
        let calendar = Calendar.current
        var day = date
        if calendar.component(.hour, from: date) < PrayerBook.dayBeginsAtHour,
           let before = calendar.date(byAdding: .day, value: -1, to: date) {
            day = before
        }
        dayFormatter.timeZone = .current
        return dayFormatter.string(from: day)
    }

    /// An order prayed through to its Amen. The rule of prayer asks
    /// about the day's three by this.
    func markOffered(_ orderID: String, on date: Date = Date()) {
        offered[orderID] = Self.stamp(date)
    }

    func wasOffered(_ orderID: String, on date: Date = Date()) -> Bool {
        offered[orderID] == Self.stamp(date)
    }

    // MARK: - Praying Aloud

    /// Whether the pray-along screen speaks the prayers. Aloud until the
    /// reader says otherwise; the last choice stands.
    var praysAloud: Bool {
        didSet {
            defaults.set(praysAloud, forKey: Key.aloud)
            hasChosenAloud = true
        }
    }

    /// Whether the reader has ever said how the book should pray. Until
    /// they have, the pray-along screen asks before it makes a sound —
    /// these are prayers said in the pew, before the tabernacle and
    /// beside someone asleep, and a voice nobody asked for is no way to
    /// begin them.
    private(set) var hasChosenAloud: Bool

    /// The reader's answer, from the question itself, the order page's
    /// switch, or the speaker at the head of the pray-along page
    func chooseAloud(_ aloud: Bool) {
        praysAloud = aloud
    }

    // MARK: - The Angelus Bell

    /// Whether the Angelus rings at six, noon and six
    private(set) var angelusBell: Bool

    /// Asked for once, when the bell is first turned on
    private(set) var angelusBellDenied = false

    /// Set when the Angelus bell's notification is tapped; ContentView
    /// opens the Angelus and clears it
    var angelusRequested = false

    static let angelusHours = [6, 12, 18]
    static let angelusCategory = "LUMEN_ANGELUS"

    /// Turns the bell on or off. Turning it on asks leave to notify if
    /// none has been given; refused, the bell stays silent and says so.
    @MainActor
    func setAngelusBell(_ on: Bool) async {
        let center = UNUserNotificationCenter.current()
        guard on else {
            angelusBell = false
            defaults.set(false, forKey: Key.angelusBell)
            center.removePendingNotificationRequests(withIdentifiers: Self.angelusIdentifiers)
            return
        }

        let settings = await center.notificationSettings()
        var allowed = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
        if settings.authorizationStatus == .notDetermined {
            allowed = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }

        angelusBellDenied = !allowed
        angelusBell = allowed
        defaults.set(allowed, forKey: Key.angelusBell)
        if allowed { scheduleAngelus() }
    }

    /// Re-lays the three bells — at launch, so a changed wording or a
    /// restored backup never leaves them stale
    func refreshAngelusBell() {
        guard angelusBell else { return }
        scheduleAngelus()
    }

    private static var angelusIdentifiers: [String] {
        angelusHours.map { "angelus.\($0)" }
    }

    private func scheduleAngelus() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: Self.angelusIdentifiers)

        for hour in Self.angelusHours {
            let content = UNMutableNotificationContent()
            content.title = "The Angelus"
            content.body = hour == 12
                ? "The noon bell. The Angel of the Lord declared unto Mary."
                : "The Angel of the Lord declared unto Mary."
            content.sound = UNNotificationSound(named: UNNotificationSoundName("church_bell.caf"))
            content.categoryIdentifier = Self.angelusCategory
            content.threadIdentifier = "angelus"

            var when = DateComponents()
            when.hour = hour
            when.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
            center.add(UNNotificationRequest(identifier: "angelus.\(hour)", content: content, trigger: trigger))
        }
    }
}

// MARK: - Opening the Angelus from its bell

/// Hears a tap on the Angelus bell's notification and leaves word for
/// ContentView to open the Angelus. It claims the Angelus's own
/// notifications only: every other notification is presented and
/// answered exactly as it was before there was a delegate — not shown
/// while the app is open, and opening the app where it was.
final class PrayerNotificationRouter: NSObject, UNUserNotificationCenterDelegate {

    static let shared = PrayerNotificationRouter()

    nonisolated private static let angelusCategory = "LUMEN_ANGELUS"

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.notification.request.content.categoryIdentifier == Self.angelusCategory else { return }
        await MainActor.run { PrayerBookStore.shared.angelusRequested = true }
    }

    /// The bell rings over an open app too, with its banner
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        notification.request.content.categoryIdentifier == Self.angelusCategory ? [.banner, .sound] : []
    }
}
