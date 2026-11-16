//
//  WidgetSnapshot.swift
//  Lumen Viae
//
//  What the Home Screen and Lock Screen widgets know of the app's own
//  state: the Rosary left off, the novenas under way, the prayer record,
//  the consecration's day and today's feast. The app writes it to the
//  App Group's container whenever it may have changed
//  (`WidgetSnapshotStore`); the widgets read it and what the app bundle
//  ships, and fetch nothing. Plain values only, so the widget extension
//  can decode it without the app's types. Everything the widgets work out
//  from the clock (today's mysteries, the Angelus, the hour of the
//  Office) they work out themselves.
//

import Foundation

nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {

    /// The App Group both the app and the widget extension read
    static let appGroupID = "group.com.lumenviae.app"

    /// The snapshot's file in the App Group's container
    static let fileName = "widget-snapshot.json"

    /// Raised when a field changes meaning, so a widget can tell an older
    /// snapshot from a newer one
    static let currentVersion = 1

    var version = WidgetSnapshot.currentVersion

    /// The Rosary left off today, where it stopped; nil when none is
    var rosary: Rosary?

    /// The novenas under way, the one with a day still to pray today first
    var novenas: [Novena] = []

    /// The prayer record as the app counts it
    var record: Record

    /// The consecration under way or chosen ahead; nil when none is
    var consecration: Consecration?

    /// Today's feast as the Mass's propers name it, when the app has them
    /// on the phone; nil until it has
    var liturgicalDay: LiturgicalDay?

    struct Rosary: Codable, Equatable, Sendable {
        /// `MysteryCategory` raw value ("sorrowful", "seven_sorrows")
        var category: String
        /// "meditation_set", "scriptural_rosary" or "rosary_aloud"
        var form: String
        /// The meditation set's name; empty for the other forms
        var setName: String
        /// 0-based: the mystery the hand was on
        var mysteryIndex: Int
        /// 0-based: the bead of that decade, 0 the Our Father; nil when
        /// the snapshot kept none
        var beadIndex: Int?
        var savedAt: Date
    }

    struct Novena: Codable, Equatable, Sendable {
        var id: String
        var name: String
        var length: Int
        /// The days prayed, 1 to `length`
        var prayedDays: [Int]
        /// Today's day while it is still to pray; nil once prayed, or when
        /// the novena waits to be picked up again
        var todaysDay: Int?
        /// The day the dashes stand on: today's, else the first open one
        var currentDay: Int
        var prayedToday: Bool
    }

    struct Record: Codable, Equatable, Sendable {
        /// Days in a row, as the Prayer Record counts them
        var daysInARow: Int
        var prayedToday: Bool
        /// The prayer days of this week (Sunday to Saturday) with a
        /// Rosary prayed, each named by its midnight
        var thisWeek: [Date]
    }

    struct Consecration: Codable, Equatable, Sendable {
        var startDate: Date
        /// False while it is chosen ahead and Day 1 has not come
        var hasBegun: Bool
        /// 1 to 34; 34 is the day of consecration
        var dayNumber: Int
        /// The day's title ("Humble Subjection")
        var dayTitle: String
        var todayPrayed: Bool
        var isCompleted: Bool
    }

    struct LiturgicalDay: Codable, Equatable, Sendable {
        /// "2026-11-16", the day the feast belongs to
        var day: String
        var title: String
        /// "Lesser Feast", in the app's words
        var rank: String?
        /// The vestment colour's raw value ("white", "red")
        var colour: String?
    }
}
