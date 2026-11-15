//
//  SilentTestingTests.swift
//  Lumen Viae Tests
//
//  The tests make no sound: the app hosting them plays everything at no
//  volume (Abraham, 15 Nov 2026).
//

import Testing

@testable import app

struct SilentTestingTests {

    @Test func theTestHostIsSilent() {
        #expect(SilentTesting.isOn)
    }
}
