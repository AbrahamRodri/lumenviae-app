//
//  MeditationCacheService.swift
//  Lumen Viae
//
//  Prefetches and caches full meditation sets so the Pray button can start
//  instantly. The API runs on Fly.io, where a cold machine can take many
//  seconds to spin up — prefetching during the launch screen both warms
//  the server and has today's sets ready before the home screen appears.
//

import Foundation

@MainActor
@Observable
final class MeditationCacheService {

    static let shared = MeditationCacheService()

    // MARK: - State

    /// Fully loaded meditation sets, keyed by category.
    private var cachedSets: [MysteryCategory: [MeditationSet]] = [:]

    /// In-flight prefetch, retained so callers can await its completion
    /// instead of racing it with a duplicate request.
    private var prefetchTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let apiService: APIService

    init(apiService: APIService? = nil) {
        self.apiService = apiService ?? .shared
    }

    // MARK: - Prefetching

    /// Starts prefetching all meditation sets for a category (fire-and-forget).
    ///
    /// Call during the launch screen with today's category. Safe to call
    /// repeatedly — a fresh prefetch only starts if nothing is cached or
    /// already in flight.
    func startPrefetch(category: MysteryCategory) {
        guard cachedSets[category] == nil, prefetchTask == nil else { return }

        prefetchTask = Task { [weak self] in
            await self?.prefetch(category: category)
            self?.prefetchTask = nil
        }
    }

    /// Fetches every meditation set summary for the category, then loads
    /// the full sets concurrently and caches them.
    private func prefetch(category: MysteryCategory) async {
        do {
            let summaries = try await apiService.fetchMeditationSets(category: category)

            // Each set is fetched independently and a failure yields nil
            // rather than throwing: one 404 or timed-out set must not
            // discard every set that loaded, which is what a throwing
            // group did — it propagated the first error and left the
            // cache empty even when most of the catalog had arrived.
            let sets = await withTaskGroup(of: MeditationSet?.self) { group in
                for summary in summaries {
                    group.addTask { [apiService] in
                        try? await apiService.fetchMeditationSet(id: summary.id)
                    }
                }

                var results: [MeditationSet] = []
                for await set in group {
                    if let set { results.append(set) }
                }
                return results
            }

            if !sets.isEmpty {
                cachedSets[category] = sets
            }
        } catch {
            // Leave the cache empty; randomSet(for:) will retry on demand.
        }
    }

    // MARK: - Random Selection

    /// Returns a random fully-loaded meditation set for the category.
    ///
    /// Waits for an in-flight prefetch first, retries the network if the
    /// prefetch failed, and falls back to the built-in traditional set so
    /// the Pray button always works offline.
    func randomSet(for category: MysteryCategory) async -> MeditationSet {
        // If a prefetch is running, its result is moments away — wait for it.
        await prefetchTask?.value

        if let sets = cachedSets[category], let set = sets.randomElement() {
            return set
        }

        // The launch prefetch failed or missed this category. Downloaded
        // content answers instantly (and off the main actor) — check it
        // BEFORE a second network attempt, which can burn 30s+ against a
        // cold or unreachable server.
        if let stored = await OfflineContentService.shared.storedRandomSet(category: category) {
            return stored
        }

        // Nothing on disk — retry the network now.
        await prefetch(category: category)

        if let sets = cachedSets[category], let set = sets.randomElement() {
            return set
        }

        return MockDataService.meditationSet(for: category)
    }
}
