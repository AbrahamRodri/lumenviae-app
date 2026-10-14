//
//  ScoreFixtures.swift
//  appTests
//
//  The few pages of sheet music the tests draw (the score sheet's and the
//  chant page's snapshots), kept with the tests since the app no longer
//  ships any: `Fixtures/ChantScores/<file>.lvscore`, copied from the
//  server's files and checked against their hashes as they are kept.
//

import Foundation
@testable import app

@MainActor
enum ScoreFixtures {

    static var urls: [URL] {
        Bundle(for: BundleToken.self).urls(forResourcesWithExtension: "lvscore", subdirectory: nil) ?? []
    }

    /// Keeps every fixture whose page a chant names in the app's chant
    /// store, as if it had been fetched
    static func install() {
        let byFile = Dictionary(urls.map { ($0.deletingPathExtension().lastPathComponent, $0) },
                                uniquingKeysWith: { first, _ in first })
        for part in ChantCatalog.all.flatMap(\.score) {
            guard let url = byFile[part.file], ChantAssetStore.shared.localURL(for: part.asset) == nil else { continue }
            try? ChantAssetStore.shared.adopt(url, as: part.asset)
        }
    }

    private final class BundleToken {}
}
