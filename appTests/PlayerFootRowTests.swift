//
//  PlayerFootRowTests.swift
//  appTests
//
//  The row under Back, play and Next fits the smallest phone: on a
//  375 pt glass, inside the footer's 22 pt inset, it has 331 points, and
//  four items (READ first) once asked for 344.
//

import SwiftUI
import Testing
import UIKit

@testable import app

@MainActor
struct PlayerFootRowTests {

    private func width(of items: [OneRosaryUtility], in room: CGFloat) -> CGFloat {
        let host = UIHostingController(rootView: OneRosaryUtilityRow(items: items).environment(UserSettings.shared))
        return host.sizeThatFits(in: CGSize(width: room, height: 200)).width
    }

    @Test func fourItemsFitASmallPhone() {
        let items = [
            OneRosaryUtilityRow.read {}, OneRosaryUtilityRow.voice {},
            OneRosaryUtilityRow.text {}, OneRosaryUtilityRow.more {},
        ]
        #expect(width(of: items, in: 331) <= 331)
    }

    @Test func threeItemsFitASmallPhone() {
        let items = [OneRosaryUtilityRow.voice {}, OneRosaryUtilityRow.text {}, OneRosaryUtilityRow.more {}]
        #expect(width(of: items, in: 331) <= 331)
    }
}
