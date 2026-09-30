//
//  PrayTrayTests.swift
//  Lumen Viae Tests
//
//  The Pray button's press-and-hold tray as an install is first given
//  it: a new install finds Today's Mysteries second, under Today's
//  Rosary; an install that has been showing the earlier default keeps
//  it; and neither is given a one-time act it already holds.
//

import Foundation
import Testing
@testable import app

@MainActor
struct PrayTrayTests {

    @Test func aNewInstallFindsTodaysMysteriesUnderTodaysRosary() {
        let tray = UserSettings.unsavedPrayTray(hasSeenOnboarding: false)
        #expect(tray == UserSettings.defaultPrayTray)
        #expect(Array(tray.prefix(2)) == [
            PrayerShortcut.todaysRosary.rawValue,
            PrayerShortcut.chooseMeditation.rawValue,
        ])
    }

    @Test func theRestKeepTheirOrder() {
        let moved = PrayerShortcut.chooseMeditation.rawValue
        #expect(
            UserSettings.defaultPrayTray.filter { $0 != moved }
                == UserSettings.earlierDefaultPrayTray.filter { $0 != moved }
        )
        #expect(Set(UserSettings.defaultPrayTray) == Set(UserSettings.earlierDefaultPrayTray))
    }

    @Test func anInstallThatHasBeenShowingTheEarlierDefaultKeepsIt() {
        #expect(UserSettings.unsavedPrayTray(hasSeenOnboarding: true)
            == UserSettings.earlierDefaultPrayTray)
    }

    /// The one-time offers insert an act only into a tray that lacks it,
    /// so a default that holds all three is never given one twice or has
    /// one moved
    @Test(arguments: [UserSettings.defaultPrayTray, UserSettings.earlierDefaultPrayTray])
    func everyDefaultAlreadyHoldsTheActsOfferedOnce(tray: [String]) {
        for act in [PrayerShortcut.scripturalRosary, .rosaryAloud, .angelus] {
            #expect(tray.filter { $0 == act.rawValue }.count == 1)
        }
    }
}
