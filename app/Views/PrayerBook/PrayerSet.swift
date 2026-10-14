//
//  PrayerSet.swift
//  Lumen Viae
//
//  The topic or order of prayer a prayer was opened from, and its place
//  in it. Opened from an order, the pray-along prays the order from that
//  prayer on (`PrayAlongLaunch.opening`); from anywhere else, the prayer
//  alone.
//

import Foundation

/// The topic or order a prayer was opened from
enum PrayerSet: Hashable {
    case topic(String)
    /// The order, and the place among its ids of the prayer tapped: an
    /// order may say a prayer twice, and the prayers must go on from the
    /// one tapped
    case order(String, at: Int)
}
