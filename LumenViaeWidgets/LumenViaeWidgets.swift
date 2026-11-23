//
//  LumenViaeWidgets.swift
//  Lumen Viae Widgets
//
//  The nine widgets (mission ios-widgets): each brings one part of the
//  day's prayer a tap away, in the app's look.
//

import SwiftUI
import WidgetKit

@main
struct LumenViaeWidgets: WidgetBundle {
    var body: some Widget {
        TodaysMysteriesWidget()
        ContinueRosaryWidget()
        NovenaWidget()
        TodayInChurchWidget()
        AngelusWidget()
        WordForTodayWidget()
        PrayerRecordWidget()
        HoursOfPrayerWidget()
        ConsecrationWidget()
    }
}
