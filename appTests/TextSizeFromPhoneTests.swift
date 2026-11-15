//
//  TextSizeFromPhoneTests.swift
//  appTests
//
//  A new install's Text Size starts from the phone's own text size, so a
//  reader who set large text on the phone reads large from the first prayer.
//

import Testing
import UIKit

@testable import app

struct TextSizeFromPhoneTests {

    @Test func thePhonesDefaultIsTheMiddleAsBefore() {
        #expect(UserSettings.textSizeScale(forPhone: .large) == 0.5)
    }

    @Test func largerOnThePhoneIsLargerHere() {
        let sizes: [UIContentSizeCategory] = [
            .extraSmall, .small, .medium, .large, .extraLarge, .extraExtraLarge, .extraExtraExtraLarge,
            .accessibilityMedium,
        ]
        let scales = sizes.map { UserSettings.textSizeScale(forPhone: $0) }
        #expect(scales == scales.sorted())
        #expect(Set(scales).count == scales.count)
        #expect(scales.allSatisfy { (0...1).contains($0) })
    }

    @Test func everyAccessibilitySizeIsTheTopOfTheRange() {
        for size: UIContentSizeCategory in [.accessibilityMedium, .accessibilityExtraExtraExtraLarge] {
            #expect(UserSettings.textSizeScale(forPhone: size) == 1)
        }
    }
}
