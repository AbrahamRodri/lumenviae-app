//
//  ChantShelfStore.swift
//  Lumen Viae
//
//  What the reader has made of the Chant Library, kept on the device: the
//  chants they love, where they stand in learning each one, the sets of
//  chants they have put together, and what they have sung lately.
//
//  Nothing here counts against anyone. A favourite is a place to come
//  back to; a step of learning is the learner's own to take, and a chant
//  is learned when they say it is — never scored, never chained into a
//  streak. Nothing is sent anywhere.
//

import Foundation

// MARK: - ChantSet

/// A set of chants the reader has made — a Thursday holy hour, night
/// prayer — with pauses and notes between them, played in order.
struct ChantSet: Codable, Identifiable, Hashable {

    struct Item: Codable, Identifiable, Hashable {

        enum Kind: Codable, Hashable {
            /// A chant, sung `times` over
            case chant(id: String, times: Int)
            /// A note in red between chants, with silence of its own when
            /// `seconds` is more than nothing ("Silent prayer · 10:00")
            case pause(note: String, seconds: Int)
        }

        var id = UUID()
        var kind: Kind

        var chant: Chant? {
            if case .chant(let id, _) = kind { return ChantCatalog.chant(id) }
            return nil
        }

        /// How long the item takes, its repeats or its silence included
        var duration: TimeInterval {
            switch kind {
            case .chant(let id, let times):
                return (ChantCatalog.chant(id)?.duration ?? 0) * Double(max(1, times))
            case .pause(_, let seconds):
                return TimeInterval(seconds)
            }
        }
    }

    var id = UUID()
    var name: String
    var items: [Item] = []

    var chantCount: Int { items.filter { $0.chant != nil }.count }
    var pauseCount: Int { items.count - chantCount }
    var duration: TimeInterval { items.reduce(0) { $0 + $1.duration } }

    /// "5 chants and 2 pauses · about 21 minutes"
    var summary: String {
        var parts: [String] = []
        let chants = chantCount == 1 ? "1 chant" : "\(chantCount) chants"
        if pauseCount > 0 {
            parts.append("\(chants) and \(pauseCount == 1 ? "1 pause" : "\(pauseCount) pauses")")
        } else {
            parts.append(chants)
        }
        let minutes = Int((duration / 60).rounded())
        if minutes > 0 {
            parts.append(minutes == 1 ? "about a minute" : "about \(minutes) minutes")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - ChantWordsPreference

/// Which words stand under the chant while it sounds
enum ChantWordsPreference: String, CaseIterable, Identifiable {
    case both
    case latin
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .both:    return "Latin and English"
        case .latin:   return "Latin only"
        case .english: return "English only"
        }
    }

    var showsLatin: Bool { self != .english }
    var showsEnglish: Bool { self != .latin }
}

// MARK: - ChantShelfStore

@Observable
final class ChantShelfStore {

    static let shared = ChantShelfStore()

    private let defaults: UserDefaults

    private enum Key {
        static let favorites = "chantShelf.favorites"
        static let learning = "chantShelf.learning"
        static let learned = "chantShelf.learned"
        static let sets = "chantShelf.sets"
        static let recent = "chantShelf.recent"
        static let words = "chantShelf.words"
        static let pausesBetween = "chantShelf.pausesBetween"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        favorites = defaults.stringArray(forKey: Key.favorites) ?? []
        learned = defaults.stringArray(forKey: Key.learned) ?? []
        learning = Self.decode([LearningRecord].self, from: defaults.data(forKey: Key.learning)) ?? []
        sets = Self.decode([ChantSet].self, from: defaults.data(forKey: Key.sets)) ?? []
        recent = Self.decode([RecentPlay].self, from: defaults.data(forKey: Key.recent)) ?? []
        words = ChantWordsPreference(rawValue: defaults.string(forKey: Key.words) ?? "") ?? .both
        pausesBetween = defaults.bool(forKey: Key.pausesBetween)
    }

    // MARK: - Favourites

    /// The chants kept as favourites, the one kept last first
    private(set) var favorites: [String] {
        didSet { defaults.set(favorites, forKey: Key.favorites) }
    }

    func isFavorite(_ chantID: String) -> Bool {
        favorites.contains(chantID)
    }

    func toggleFavorite(_ chantID: String) {
        if let index = favorites.firstIndex(of: chantID) {
            favorites.remove(at: index)
        } else {
            favorites.insert(chantID, at: 0)
        }
    }

    var favoriteChants: [Chant] { favorites.compactMap(ChantCatalog.chant) }

    // MARK: - Learning

    struct LearningRecord: Codable, Hashable {
        let chantID: String
        var step: Int
        var touched: Date
    }

    /// The chants being learned, the one touched last first
    private(set) var learning: [LearningRecord] {
        didSet { defaults.set(Self.encode(learning), forKey: Key.learning) }
    }

    /// The chants the learner has called learned, the latest first
    private(set) var learned: [String] {
        didSet { defaults.set(learned, forKey: Key.learned) }
    }

    func isLearned(_ chantID: String) -> Bool {
        learned.contains(chantID)
    }

    /// The step the learner stands on, or nil for a chant not begun or
    /// already learned
    func step(of chantID: String) -> ChantLearningStep? {
        guard !isLearned(chantID) else { return nil }
        return learning.first { $0.chantID == chantID }.flatMap { ChantLearningStep(rawValue: $0.step) }
    }

    /// The chant being learned most lately, for a "Continue learning" door
    var latestInProgress: (chant: Chant, step: ChantLearningStep)? {
        for record in learning where !isLearned(record.chantID) {
            if let chant = ChantCatalog.chant(record.chantID),
               let step = ChantLearningStep(rawValue: record.step) {
                return (chant, step)
            }
        }
        return nil
    }

    var learnedChants: [Chant] { learned.compactMap(ChantCatalog.chant) }

    var inProgressCount: Int {
        learning.filter { !isLearned($0.chantID) }.count
    }

    /// Stands the learner on `step`, beginning the chant if it was not
    func setStep(_ step: ChantLearningStep, for chantID: String) {
        learned.removeAll { $0 == chantID }
        learning.removeAll { $0.chantID == chantID }
        learning.insert(LearningRecord(chantID: chantID, step: step.rawValue, touched: Date()), at: 0)
    }

    /// Begins a chant at its first step, or touches it where it stands.
    /// A chant already learned keeps its mark: practising it again is
    /// not unlearning it.
    func begin(_ chantID: String) {
        guard !isLearned(chantID) else { return }
        setStep(step(of: chantID) ?? .listen, for: chantID)
    }

    /// The learner's own word that they know it by heart
    func markLearned(_ chantID: String) {
        learning.removeAll { $0.chantID == chantID }
        if !learned.contains(chantID) {
            learned.insert(chantID, at: 0)
        }
    }

    /// Takes the mark back, and stands them on the last step again
    func unmarkLearned(_ chantID: String) {
        learned.removeAll { $0 == chantID }
        setStep(.onYourOwn, for: chantID)
    }

    // MARK: - Sets

    private(set) var sets: [ChantSet] {
        didSet { defaults.set(Self.encode(sets), forKey: Key.sets) }
    }

    func set(_ id: UUID) -> ChantSet? {
        sets.first { $0.id == id }
    }

    /// A new, empty set, named with the next free "My set"
    @discardableResult
    func newSet(named name: String? = nil) -> ChantSet {
        var proposed = name ?? "My set"
        if name == nil {
            var number = 2
            while sets.contains(where: { $0.name == proposed }) {
                proposed = "My set \(number)"
                number += 1
            }
        }
        let set = ChantSet(name: proposed)
        sets.append(set)
        return set
    }

    /// An occasion copied to a set of the reader's own, its rubrics
    /// kept as notes, so it can be changed without changing the library
    @discardableResult
    func saveOccasion(_ occasion: ChantOccasion, on date: Date = Date()) -> ChantSet {
        var items: [ChantSet.Item] = []
        for block in occasion.blocks {
            if let rubric = block.rubric {
                items.append(ChantSet.Item(kind: .pause(note: rubric, seconds: 0)))
            }
            for _ in 0..<max(1, block.rounds) {
                for step in block.steps {
                    guard let chant = step.chant.resolve(on: date) else { continue }
                    items.append(ChantSet.Item(kind: .chant(id: chant.id, times: max(1, step.times))))
                }
            }
        }
        let set = ChantSet(name: occasion.title, items: items)
        sets.append(set)
        return set
    }

    func rename(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        update(id) { $0.name = trimmed }
    }

    func deleteSet(_ id: UUID) {
        sets.removeAll { $0.id == id }
    }

    func addChant(_ chantID: String, to id: UUID) {
        update(id) { $0.items.append(ChantSet.Item(kind: .chant(id: chantID, times: 1))) }
    }

    func addPause(note: String, seconds: Int, to id: UUID) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        update(id) { $0.items.append(ChantSet.Item(kind: .pause(note: trimmed, seconds: max(0, seconds)))) }
    }

    func removeItem(_ itemID: UUID, from id: UUID) {
        update(id) { $0.items.removeAll { $0.id == itemID } }
    }

    /// Moves an item one place up (-1) or down (+1)
    func moveItem(_ itemID: UUID, by offset: Int, in id: UUID) {
        update(id) { set in
            guard let index = set.items.firstIndex(where: { $0.id == itemID }) else { return }
            let target = index + offset
            guard set.items.indices.contains(target) else { return }
            set.items.swapAt(index, target)
        }
    }

    private func update(_ id: UUID, _ change: (inout ChantSet) -> Void) {
        guard let index = sets.firstIndex(where: { $0.id == id }) else { return }
        var set = sets[index]
        change(&set)
        sets[index] = set
    }

    // MARK: - Recently played

    struct RecentPlay: Codable, Hashable {
        let chantID: String
        let at: Date
    }

    /// The chants sung lately, the latest first, each once
    private(set) var recent: [RecentPlay] {
        didSet { defaults.set(Self.encode(recent), forKey: Key.recent) }
    }

    private static let recentLimit = 8

    func notePlayed(_ chantID: String, at date: Date = Date()) {
        recent.removeAll { $0.chantID == chantID }
        recent.insert(RecentPlay(chantID: chantID, at: date), at: 0)
        if recent.count > Self.recentLimit {
            recent.removeLast(recent.count - Self.recentLimit)
        }
    }

    // MARK: - Preferences

    var words: ChantWordsPreference {
        didSet { defaults.set(words.rawValue, forKey: Key.words) }
    }

    /// Whether a set waits for a tap before its next chant
    var pausesBetween: Bool {
        didSet { defaults.set(pausesBetween, forKey: Key.pausesBetween) }
    }

    // MARK: - Coding

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }
}
