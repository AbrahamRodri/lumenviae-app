//
//  FamilyPrayersSeed.swift
//  Lumen Viae
//
//  The app maker's family's morning prayers, given to the TestFlight build
//  only (its testers are the family): nine prayers in their own words and
//  the playlist that says them in order, added once to My Prayers. An
//  App Store build never adds them. Once added they are the reader's
//  like any others, to change or delete, and never added again.
//
//  TestFlight is told from the App Store by the app's own transaction
//  (`AppTransaction`), whose environment is the sandbox on TestFlight. A
//  Debug build adds them only when launched with `-seedFamilyPrayers`.
//

import Foundation
import StoreKit

enum FamilyPrayersSeed {

    static let doneKey = "myPrayers.familyMorningSeeded"

    static let playlistName = "Family Morning Prayer"

    /// At launch: adds the prayers if this is the family's build and they
    /// were never added. Waits on the App Store's answer off the launch
    /// path; with no answer (offline at first launch), it asks again next
    /// launch.
    static func seedIfDue(store: MyPrayersStore = .shared, defaults: UserDefaults = .standard) {
        guard !LibraryContent.hostsTests, !defaults.bool(forKey: doneKey) else { return }
        Task {
            guard await isFamilyBuild() else { return }
            seed(into: store, defaults: defaults)
        }
    }

    /// Adds the prayers and the playlist, once
    static func seed(into store: MyPrayersStore, defaults: UserDefaults) {
        guard !defaults.bool(forKey: doneKey) else { return }
        defer { defaults.set(true, forKey: doneKey) }
        // Already made by hand, under the same name: left as it is
        guard !store.playlists.contains(where: { $0.name == playlistName }) else { return }

        let made = prayers.map { prayer -> CustomPrayer in
            let custom = CustomPrayer(title: prayer.title, text: prayer.text, art: prayer.art)
            store.save(custom)
            return custom
        }
        // The Sign of the Cross opens and closes, the same prayer twice
        let ids = made.map(\.prayerID) + [made[0].prayerID]
        store.save(PrayerPlaylist(name: playlistName, prayerIDs: ids, art: "hour_morning"))
    }

    private static func isFamilyBuild() async -> Bool {
        #if DEBUG
            return ProcessInfo.processInfo.arguments.contains("-seedFamilyPrayers")
        #else
            guard let result = try? await AppTransaction.shared else { return false }
            switch result {
            case .verified(let transaction), .unverified(let transaction, _):
                return transaction.environment == .sandbox
            }
        #endif
    }

    // MARK: - The words

    struct Prayer {
        let title: String
        let text: String
        let art: String
    }

    /// In the order prayed, the closing Sign of the Cross apart. The words
    /// are the family's, as they gave them.
    static let prayers: [Prayer] = [
        Prayer(
            title: "Sign of the Cross",
            text: "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
            art: "devotion_holy_trinity"
        ),
        Prayer(
            title: "Glory Be",
            text:
                "Glory be to the Father, and to the Son, and to the Holy Spirit, as it was in the beginning, is now, and ever shall be, world without end. Amen.",
            art: "topic_holy_trinity"
        ),
        Prayer(
            title: "Morning Offering (Suscipe of St. Ignatius)",
            text:
                "Take, Lord, and receive all my liberty, my memory, my understanding, and my entire will, all I have and call my own. You have given all to me; to You, Lord, I return it. Everything is Yours; do with it what You will. Give me only Your love and Your grace; that is enough for me. Amen.",
            art: "saint_ignatius"
        ),
        Prayer(
            title: "Direct, O Lord, All Our Actions",
            text:
                "Direct, we beseech Thee, O Lord, all our actions by Thy holy inspirations, and carry them on by Thy gracious assistance, that every prayer and work of ours may begin always from Thee, and through Thee be happily ended. Through Christ our Lord. Amen.",
            art: "glorious_pentecost"
        ),
        Prayer(
            title: "Family Consecration to Mary",
            text:
                "Blessed Mother, we consecrate ourselves and our children to you this day. We offer all that we are and all that we have to your Immaculate and Sorrowful Heart. Give us your maternal blessing, that we may be able to do the will of your Son, and wrap us in your mantle to protect us from the snares of the devil, the world, and our own flesh. Amen.",
            art: "mary_mother_of_mercy"
        ),
        Prayer(
            title: "The Memorare",
            text:
                "Remember, O most gracious Virgin Mary, that never was it known that anyone who fled to thy protection, implored thy help, or sought thy intercession was left unaided. Inspired by this confidence, I fly unto thee, O Virgin of virgins, my Mother. To thee do I come, before thee I stand, sinful and sorrowful. O Mother of the Word Incarnate, despise not my petitions, but in thy mercy hear and answer me. Amen.",
            art: "mary_sistine_madonna"
        ),
        Prayer(
            title: "Prayer to St. Joseph",
            text:
                "O glorious St. Joseph, spouse of the Immaculate Virgin, obtain for us a pure, humble, and charitable mind, and perfect resignation to the divine Will. Be our guide, father, and model through life, that we may merit to die as you did, in the arms of Jesus and Mary. Amen.",
            art: "devotion_st_joseph"
        ),
        Prayer(
            title: "Guardian Angel Prayer",
            text:
                "Angels of God, our guardians dear, to whom God\u{2019}s love commits us here, ever this day be at our side, to light and guard, to rule and guide. Amen.",
            art: "devotion_guardian_angels"
        ),
        Prayer(
            title: "Short Litany",
            text: """
                Most Sacred Heart of Jesus, have mercy on us.
                Most Sacred Heart of Jesus, have mercy on us.
                Most Sacred Heart of Jesus, have mercy on us.
                All you holy Angels and Saints, pray for us.
                """,
            art: "jesus_anima_christi"
        ),
    ]
}
