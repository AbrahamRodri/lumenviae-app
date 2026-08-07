//
//  MeditationSetResolver.swift
//  Lumen Viae
//
//  The single place that turns a meditation-set ID into a full set:
//  bundled sets resolve locally, the built-in fallback regenerates, and
//  API sets try the network then downloaded offline content. Every flow
//  (picker, quick-pray resume, home resume card) resolves through here so
//  the tiers can never diverge between call sites.
//

import Foundation

enum MeditationSetResolver {

    /// Bundled sets compiled into the binary, keyed by their sentinel IDs.
    /// Add new bundled sets here and every flow picks them up.
    private static let bundledSets: [Int: MeditationSet] = [
        LuminousMeditationData.setID: LuminousMeditationData.set
    ]

    /// Resolves a set ID to a full meditation set.
    ///
    /// - Bundled sentinel IDs (negative) resolve from the binary.
    /// - ID 0 is the built-in fallback; it regenerates deterministically.
    /// - Positive IDs try the API, then downloaded offline content.
    @MainActor
    static func resolve(id: Int, categoryHint: String? = nil) async throws -> MeditationSet {
        if let bundled = bundledSets[id] {
            return bundled
        }

        guard id > 0 else {
            // 0 = built-in fallback set; unknown negatives land here too
            // rather than 404ing the API with a sentinel ID.
            let category = categoryHint.flatMap { MysteryCategory(fromAPIString: $0) } ?? .joyful
            return MockDataService.meditationSet(for: category)
        }

        do {
            return try await APIService.shared.fetchMeditationSet(id: id)
        } catch {
            if let stored = OfflineContentService.shared.storedSet(id: id) {
                return stored
            }
            throw error
        }
    }
}
