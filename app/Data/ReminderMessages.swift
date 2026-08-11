//
//  ReminderMessages.swift
//  Lumen Viae
//
//  The daily reminder copy, in pools keyed to what the user said drew them
//  here. One pool per intention, plus a default for anyone who skipped the
//  question.
//
//  Copy rules, and they are not negotiable: warm, short, invitational.
//  Never mention the streak, never imply the user is behind, never scold.
//  The reminder is a bell for the Angelus, not a debt collector. Titles
//  stay under ~35 characters and bodies under ~75 so neither is truncated
//  on the lock screen, and the body must add to the title rather than
//  restate it — two lines is the whole budget.
//

import Foundation

struct ReminderMessage: Hashable {
    let title: String
    let body: String
}

extension ReminderMessage {

    // MARK: - Pools

    /// Peace & Stillness — rest, quiet, and the day set down for a while.
    static let peace: [ReminderMessage] = [
        ReminderMessage(title: "Set the day down for a while", body: "Twenty minutes of quiet, and nothing else asked of you."),
        ReminderMessage(title: "Nothing here is in a hurry", body: "The beads move at whatever pace you set."),
        ReminderMessage(title: "A pause in the noise", body: "One decade is enough to change the air of a day."),
        ReminderMessage(title: "Come and rest", body: "Sit with a mystery and let the day wait."),
        ReminderMessage(title: "Somewhere quiet to go", body: "The mysteries are open whenever the day gets loud."),
        ReminderMessage(title: "One bead at a time", body: "The app keeps count, so you can just pray."),
        ReminderMessage(title: "Peace, at your own pace", body: "Pray one decade or all five; there is no wrong length.")
    ]

    /// A Daily Habit — rhythm and returning, never a debt owed.
    static let habit: [ReminderMessage] = [
        ReminderMessage(title: "Today's Rosary", body: "The same quiet hour, kept once more."),
        ReminderMessage(title: "Your rhythm, right on time", body: "A few minutes now, and the day has its anchor."),
        ReminderMessage(title: "The hour you set aside", body: "Whatever kind of day it has been, the beads are the same."),
        ReminderMessage(title: "A small, steady thing", body: "Five decades, or one — the habit is in the returning."),
        ReminderMessage(title: "Prayer keeps the day's shape", body: "Begin whenever it suits; the beads keep no clock."),
        ReminderMessage(title: "Same time, same grace", body: "The Rosary asks little and gives much."),
        ReminderMessage(title: "A day with a Rosary in it", body: "That is all today needs to be.")
    ]

    /// Closer to Our Lady — filial, Marian, always ending at her Son.
    static let devotion: [ReminderMessage] = [
        ReminderMessage(title: "Our Lady is waiting", body: "She has all the time in the world for you."),
        ReminderMessage(title: "A word with your Mother", body: "The Rosary is simply time spent with her."),
        ReminderMessage(title: "She holds out her hand", body: "Take up the beads and walk the mysteries with her."),
        ReminderMessage(title: "Totus tuus", body: "Give her these few minutes and she will give them to her Son."),
        ReminderMessage(title: "Through her, to him", body: "Every Ave you pray she carries straight to Jesus."),
        ReminderMessage(title: "The Mother of God knows your name", body: "Come and tell her what the day has held."),
        ReminderMessage(title: "Ave Maria", body: "Fifty of them, and she is nearer than when you began.")
    ]

    /// Learning the Rosary — deliberately small, because this intention
    /// draws from every pool (see `pool(for:)`). Beginner-framed copy goes
    /// stale the moment someone learns the Rosary; these two do not.
    static let learning: [ReminderMessage] = [
        ReminderMessage(title: "Today's mystery is ready", body: "The scene, the scripture, and the prayers, all in one place."),
        ReminderMessage(title: "There is always more in it", body: "Eight centuries of saints have not exhausted the mysteries.")
    ]

    /// Used when the intention question was skipped.
    static let standard: [ReminderMessage] = [
        ReminderMessage(title: "A quiet moment awaits", body: "The Rosary is here whenever you are ready."),
        ReminderMessage(title: "Today's mysteries are ready", body: "A few minutes of stillness amid the day."),
        ReminderMessage(title: "The Rosary is close by", body: "Peace begins with a single Ave."),
        ReminderMessage(title: "The beads are where you left them", body: "Pick them up whenever the day allows."),
        ReminderMessage(title: "Our Lady keeps a place for you", body: "Come sit with the mysteries a while."),
        ReminderMessage(title: "An invitation to stillness", body: "Sit with one mystery and see where it goes."),
        ReminderMessage(title: "Grace in the ordinary", body: "A decade of prayer can change the whole day.")
    ]

    // MARK: - Selection

    private static func messages(for intention: PrayerIntention) -> [ReminderMessage] {
        switch intention {
        case .peace:     return peace
        case .habit:     return habit
        case .devotion:  return devotion
        case .learning:  return learning
        }
    }

    /// The message pool for a set of intentions.
    ///
    /// Someone still learning the Rosary hasn't settled into one way of
    /// praying it yet, so "Learning" opens the whole catalog rather than
    /// narrowing it. Everything else is the union of what was chosen, and
    /// no choice at all falls back to the neutral pool.
    static func pool(for intentions: [PrayerIntention]) -> [ReminderMessage] {
        guard !intentions.isEmpty else { return standard }

        if intentions.contains(.learning) {
            return interleaved([peace, habit, devotion, learning, standard])
        }
        return interleaved(intentions.map { messages(for: $0) })
    }

    /// Round-robins the pools into one list, so any seven-day window drawn
    /// from it hears from every intention the user chose. Concatenating
    /// instead would spend a whole week inside the first pool.
    private static func interleaved(_ pools: [[ReminderMessage]]) -> [ReminderMessage] {
        guard pools.count > 1 else { return pools.first ?? [] }

        var result: [ReminderMessage] = []
        var seen = Set<ReminderMessage>()
        let longest = pools.map(\.count).max() ?? 0

        for index in 0..<longest {
            for pool in pools where index < pool.count {
                if seen.insert(pool[index]).inserted {
                    result.append(pool[index])
                }
            }
        }
        return result
    }
}
