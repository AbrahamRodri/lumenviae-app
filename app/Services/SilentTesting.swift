//
//  SilentTesting.swift
//  app
//
//  Testing makes no sound. Abraham, 15 Nov 2026: "are you able to do
//  testing without audio from now on so I dont hear it". A debug build
//  launched with -LVMuteAudio, and the app while it hosts the unit tests,
//  plays every recording, bell and preview at no volume. Everything else
//  runs as it would, so the player's timing, the Lock Screen and the
//  words still behave as they do for a reader. Never in a release build.
//

import Foundation

enum SilentTesting {

    static let isOn: Bool = {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            return arguments.contains("-LVMuteAudio")
                || UserDefaults.standard.bool(forKey: "LVMuteAudio")
                || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        #else
            return false
        #endif
    }()
}
