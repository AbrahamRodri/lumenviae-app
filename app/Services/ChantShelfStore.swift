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
    /// The occasion it was kept from, so the occasion's bookmark knows it
    /// is kept and a second tap lets it go
    var occasionID: String? = nil

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
        let learning = Self.readList(LearningRecord.self, key: Key.learning, from: defaults)
        let sets = Self.readList(ChantSet.self, key: Key.sets, from: defaults)
        let recent = Self.readList(RecentPlay.self, key: Key.recent, from: defaults)
        self.learning = learning.good
        self.sets = sets.good
        self.recent = recent.good
        unreadable = [Key.learning: learning.unreadable, Key.sets: sets.unreadable, Key.recent: recent.unreadable]
        stored = [Key.learning: learning.stored, Key.sets: sets.stored, Key.recent: recent.stored]
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

    var favoriteChants: [Chant] { favorites.compactMap { ChantCatalog.chant($0) } }

    // MARK: - Learning

    struct LearningRecord: Codable, Hashable {
        let chantID: String
        var step: Int
        var touched: Date
    }

    /// The chants being learned, the one touched last first
    private(set) var learning: [LearningRecord] {
        didSet { writeList(learning, key: Key.learning) }
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

    var learnedChants: [Chant] { learned.compactMap { ChantCatalog.chant($0) } }

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

    /// The learner puts a chant down: no step is kept for it, and nothing
    /// says it was ever begun
    func stopLearning(_ chantID: String) {
        learning.removeAll { $0.chantID == chantID }
    }

    // MARK: - Sets

    private(set) var sets: [ChantSet] {
        didSet { writeList(sets, key: Key.sets) }
    }

    func set(_ id: UUID) -> ChantSet? {
        sets.first { $0.id == id }
    }

    /// The next free "My set" name, for a new set's sheet to offer
    var nextSetName: String {
        var proposed = "My set"
        var number = 2
        while sets.contains(where: { $0.name == proposed }) {
            proposed = "My set \(number)"
            number += 1
        }
        return proposed
    }

    /// A new set, named — made when the reader names it, or with its first
    /// chant, so backing out leaves no empty spine on the shelf
    @discardableResult
    func newSet(named name: String? = nil, with chantID: String? = nil) -> ChantSet {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var set = ChantSet(name: trimmed.isEmpty ? nextSetName : trimmed)
        if let chantID {
            set.items.append(ChantSet.Item(kind: .chant(id: chantID, times: 1)))
        }
        sets.append(set)
        return set
    }

    /// The set kept from `occasion`, if it is kept — one kept before a set
    /// said which occasion it came from included, known by its name and the
    /// occasion's rubrics standing as its notes, so the bookmark shows it
    /// kept and a tap never makes a second
    func keptSet(of occasion: ChantOccasion) -> ChantSet? {
        sets.first { $0.occasionID == occasion.id }
            ?? sets.first { $0.occasionID == nil && Self.wasKept(occasion, as: $0) }
    }

    private static func wasKept(_ occasion: ChantOccasion, as set: ChantSet) -> Bool {
        guard set.name == occasion.title else { return false }
        let notes = set.items.compactMap { item -> String? in
            if case .pause(let note, 0) = item.kind { return note }
            return nil
        }
        let rubrics = occasion.blocks.compactMap { $0.rubric }
        return !rubrics.isEmpty && notes == rubrics
    }

    /// What a tap on an occasion's bookmark did
    enum Keeping: Equatable {
        /// The occasion is kept, as a set of the reader's own
        case kept
        /// The kept set, still the occasion's own copy, is let go
        case letGo
        /// The kept set has been changed since — renamed, its chants or
        /// pauses moved, added or taken away — so it is not let go without
        /// asking: the reader's work would go with it
        case askFirst(ChantSet)
    }

    /// Keeps the occasion as a set of the reader's own, or, kept already
    /// and never changed, lets that set go: one set for each occasion,
    /// never two. A kept set the reader has changed is left for them to
    /// let go once asked (`deleteSet`).
    @discardableResult
    func toggleKeeping(_ occasion: ChantOccasion, on date: Date = Date()) -> Keeping {
        guard let kept = keptSet(of: occasion) else {
            saveOccasion(occasion, on: date)
            return .kept
        }
        guard isUntouchedCopy(kept, of: occasion, on: date) else { return .askFirst(kept) }
        deleteSet(kept.id)
        return .letGo
    }

    /// Whether a kept set is still the occasion's own copy: its name, and
    /// the same chants and pauses in the same order
    func isUntouchedCopy(_ set: ChantSet, of occasion: ChantOccasion, on date: Date = Date()) -> Bool {
        set.name == occasion.title && set.items.map(\.kind) == Self.copy(of: occasion, on: date)
    }

    /// An occasion copied to a set of the reader's own, its rubrics
    /// kept as notes, so it can be changed without changing the library
    @discardableResult
    func saveOccasion(_ occasion: ChantOccasion, on date: Date = Date()) -> ChantSet {
        if let kept = keptSet(of: occasion) { return kept }
        let items = Self.copy(of: occasion, on: date).map { ChantSet.Item(kind: $0) }
        let set = ChantSet(name: occasion.title, items: items, occasionID: occasion.id)
        sets.append(set)
        return set
    }

    /// The occasion as a set's items: each rubric a note before its block,
    /// each chant as many times as the occasion sings it
    private static func copy(of occasion: ChantOccasion, on date: Date) -> [ChantSet.Item.Kind] {
        var kinds: [ChantSet.Item.Kind] = []
        for block in occasion.blocks {
            if let rubric = block.rubric {
                kinds.append(.pause(note: rubric, seconds: 0))
            }
            for _ in 0..<max(1, block.rounds) {
                for step in block.steps {
                    guard let chant = step.chant.resolve(on: date) else { continue }
                    kinds.append(.chant(id: chant.id, times: max(1, step.times)))
                }
            }
        }
        return kinds
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
        didSet { writeList(recent, key: Key.recent) }
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

    /// What a list held that this build could not read — an entry written
    /// by a later build, or damaged — kept as it was and written back
    /// beside the entries it could, so nothing stored is lost by reading it
    @ObservationIgnored private var unreadable: [String: [Any]] = [:]

    /// Each entry as it was stored, by list and by the entry's own key, so
    /// the fields a later build gave it — which this build cannot read and
    /// would not write — go back with it when this build writes the list
    @ObservationIgnored private var stored: [String: [String: [String: Any]]] = [:]

    /// A stored list, read an entry at a time: the entries that read, each
    /// one's stored form, and the entries that did not read, as they were.
    /// Data that is no list at all is set aside under its own key rather
    /// than written over.
    private static func readList<T: ShelfEntry>(
        _ type: T.Type,
        key: String,
        from defaults: UserDefaults
    ) -> (good: [T], unreadable: [Any], stored: [String: [String: Any]]) {
        guard let data = defaults.data(forKey: key) else { return ([], [], [:]) }
        guard let elements = (try? JSONSerialization.jsonObject(with: data)) as? [Any] else {
            defaults.set(data, forKey: key + ".unreadable")
            return ([], [], [:])
        }
        var good: [T] = []
        var unreadable: [Any] = []
        var stored: [String: [String: Any]] = [:]
        let decoder = JSONDecoder()
        for element in elements {
            if let elementData = try? JSONSerialization.data(withJSONObject: element, options: [.fragmentsAllowed]),
               let value = try? decoder.decode(T.self, from: elementData) {
                good.append(value)
                if let fields = element as? [String: Any] {
                    stored[value.entryKey] = fields
                }
            } else {
                unreadable.append(element)
            }
        }
        return (good, unreadable, stored)
    }

    private func writeList<T: ShelfEntry>(_ values: [T], key: String) {
        guard let data = try? JSONEncoder().encode(values) else { return }
        let kept = unreadable[key] ?? []
        let storedForms = stored[key] ?? [:]
        guard !kept.isEmpty || !storedForms.isEmpty,
              let encoded = (try? JSONSerialization.jsonObject(with: data)) as? [Any],
              encoded.count == values.count else {
            defaults.set(data, forKey: key)
            return
        }
        var elements: [Any] = []
        for (value, element) in zip(values, encoded) {
            guard var fields = element as? [String: Any], let earlier = storedForms[value.entryKey] else {
                elements.append(element)
                continue
            }
            T.keepUnknownFields(of: earlier, in: &fields)
            elements.append(fields)
        }
        elements.append(contentsOf: kept)
        if let merged = try? JSONSerialization.data(withJSONObject: elements) {
            defaults.set(merged, forKey: key)
        }
    }
}

// MARK: - ShelfEntry

/// An entry of one of the shelf's stored lists
private protocol ShelfEntry: Codable {
    /// What names the entry from one read to the next, to find its stored
    /// form again
    var entryKey: String { get }

    /// The fields this build writes; any other a stored entry carries was
    /// written by a later build
    static var knownFields: Set<String> { get }

    /// Gives `fields`, the entry as this build writes it, every field of
    /// its stored form that this build does not know
    static func keepUnknownFields(of earlier: [String: Any], in fields: inout [String: Any])
}

extension ShelfEntry {
    static func keepUnknownFields(of earlier: [String: Any], in fields: inout [String: Any]) {
        for (name, value) in earlier where !knownFields.contains(name) {
            fields[name] = value
        }
    }
}

extension ChantShelfStore.LearningRecord: ShelfEntry {
    var entryKey: String { chantID }
    static var knownFields: Set<String> { ["chantID", "step", "touched"] }
}

extension ChantShelfStore.RecentPlay: ShelfEntry {
    var entryKey: String { chantID }
    static var knownFields: Set<String> { ["chantID", "at"] }
}

extension ChantSet: ShelfEntry {
    var entryKey: String { id.uuidString }
    static var knownFields: Set<String> { ["id", "name", "items", "occasionID"] }

    /// The set's own unknown fields, and each of its items' too, found by
    /// the item's id
    static func keepUnknownFields(of earlier: [String: Any], in fields: inout [String: Any]) {
        for (name, value) in earlier where !knownFields.contains(name) {
            fields[name] = value
        }
        guard let earlierItems = earlier["items"] as? [[String: Any]],
              let items = fields["items"] as? [[String: Any]] else { return }
        var earlierByID: [String: [String: Any]] = [:]
        for item in earlierItems {
            if let id = item["id"] as? String { earlierByID[id] = item }
        }
        fields["items"] = items.map { item -> [String: Any] in
            guard let id = item["id"] as? String, let before = earlierByID[id] else { return item }
            var merged = item
            for (name, value) in before where !["id", "kind"].contains(name) {
                merged[name] = value
            }
            return merged
        }
    }
}
