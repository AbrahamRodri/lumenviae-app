//
//  BundledContentTests.swift
//  Lumen Viae Tests
//
//  The content compiled into the app for a Rosary with no signal — the
//  five bundled meditation sets — and the journal's starter questions:
//  each set has a meditation for every mystery of its category, in order,
//  under a label the picker knows, and no two bundled things share an id.
//

import Foundation
import Testing

@testable import app

@MainActor
struct BundledMeditationSetTests {

    @Test func everyCategoryHasOneBundledSetWithAMeditationForEveryMystery() throws {
        for category in MysteryCategory.allCases {
            let summaries = BundledMeditationSets.summaries(for: category)
            #expect(summaries.count == 1, "\(category)")
            for summary in summaries {
                let set = try #require(BundledMeditationSets.byID[summary.id])
                let meditations = try #require(set.meditations)
                let mysteries = MysteryData.mysteries(for: category)
                #expect(meditations.count == mysteries.count, "\(set.name)")
                for (meditation, mystery) in zip(meditations, mysteries) {
                    #expect(meditation.mystery == mystery, "\(set.name): \(mystery.name)")
                    #expect(meditation.content.count > 400, "\(set.name): \(mystery.name) is thin")
                    #expect(meditation.author != nil, "\(set.name): \(mystery.name) names no author")
                }
                #expect(set.category == category.rawValue)
            }
        }
    }

    @Test func bundledIdsAreNegativeAndNeverShared() {
        let sets = BundledMeditationSets.all
        #expect(sets.allSatisfy { $0.id < 0 })
        #expect(Set(sets.map(\.id)).count == sets.count)
        let meditationIDs = sets.flatMap { ($0.meditations ?? []).map(\.id) }
        #expect(meditationIDs.allSatisfy { $0 < 0 })
        #expect(Set(meditationIDs).count == meditationIDs.count)
    }

    @Test func everyBundledLabelIsOneOfTheServersVocabulary() {
        let vocabulary: Set<String> = ["Intentions", "Saints", "Scriptural", "Contemplative", "Considerations"]
        for set in BundledMeditationSets.all {
            #expect(!(set.labels ?? []).isEmpty, "\(set.name) carries no label")
            for label in set.labels ?? [] {
                #expect(vocabulary.contains(label), "\(set.name): \(label)")
            }
        }
    }

    @Test func theResolverFindsEveryBundledSet() async throws {
        for set in BundledMeditationSets.all {
            let resolved = try await MeditationSetResolver.resolve(id: set.id)
            #expect(resolved.id == set.id)
            #expect(resolved.meditations?.count == set.meditations?.count)
        }
    }
}

@MainActor
struct JournalPromptTests {

    @Test func everyCategoryHasThreeQuestions() {
        for category in MysteryCategory.allCases {
            let prompts = JournalPrompts.prompts(for: category)
            #expect(prompts.count == 3, "\(category)")
            #expect(Set(prompts).count == 3, "\(category)")
            for prompt in prompts {
                #expect(prompt.hasSuffix("?"), "\(prompt)")
                #expect(prompt.count < 80, "\(prompt) is too long for a row")
            }
        }
        #expect(JournalPrompts.today.count == 3)
    }
}
