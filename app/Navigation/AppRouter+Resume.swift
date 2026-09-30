//
//  AppRouter+Resume.swift
//  Lumen Viae
//
//  Opening an unfinished Rosary where it stopped — the one path Home's
//  card, the Pray button and the Chapel all take, so they can never
//  come back to different places.
//

import Foundation

extension AppRouter {

    /// Opens `session` at its mystery and bead, with the seconds already
    /// prayed. The Scriptural and Holy Rosaries are bundled whole and open
    /// at once, on their own screen, in the form they were prayed in; a
    /// meditation set is resolved first (bundled, the API, then offline),
    /// and nothing is pushed if navigation moved while it loaded.
    ///
    /// - Returns: false only when the set could not be loaded.
    @discardableResult
    func resume(_ session: InProgressPrayer) async -> Bool {
        if let form = session.spokenForm {
            guard let category = MysteryCategory(fromAPIString: session.category) else { return false }
            push(.scripturalRosaryPrayer(ScripturalRosaryLaunch(
                category: category,
                form: form,
                startIndex: session.mysteryIndex,
                startBead: session.beadIndex ?? 0,
                priorSeconds: session.accumulatedSeconds,
                startedAt: session.startedAt
            )))
            return true
        }

        let generation = self.generation
        guard let set = try? await MeditationSetResolver.resolve(
            id: session.meditationSetId,
            categoryHint: session.category
        ) else { return false }

        // The user may have gone elsewhere while the set loaded — never
        // push then. Not a failure: there was nothing to show an error on.
        guard self.generation == generation else { return true }

        navigateToPrayerSession(
            meditationSet: set,
            startAtIndex: session.mysteryIndex,
            startAtBead: session.beadIndex ?? 0,
            priorSeconds: session.accumulatedSeconds,
            startedAt: session.startedAt
        )
        return true
    }
}
