//
//  ReminderMessages.swift
//  Lumen Viae
//
//  The daily reminder copy, in pools keyed to what the user said drew them
//  here. One pool per intention, plus a default for anyone who skipped the
//  question, and a pool for each season of the year that has a Rosary of
//  its own — Advent, Lent, Eastertide, May and October — mixed into the
//  week while the season lasts.
//
//  Copy rules, and they are not negotiable: warm, short, invitational.
//  Never mention the streak, never imply the user is behind, never scold.
//  The reminder is a bell for the Angelus, not a debt collector. Titles
//  stay under ~35 characters and bodies under ~75 so neither is truncated
//  on the lock screen, and the body must add to the title rather than
//  restate it — two lines is the whole budget. No reminder promises a
//  length of time.
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
        ReminderMessage(title: "A pause in the noise", body: "Ten Hail Marys are enough to change the air of a day."),
        ReminderMessage(title: "Come and rest", body: "Sit with a mystery and let the day wait."),
        ReminderMessage(title: "Somewhere quiet to go", body: "The mysteries are open whenever the day gets loud."),
        ReminderMessage(title: "One bead at a time", body: "The app keeps count, so you can just pray."),
        ReminderMessage(title: "Peace, at your own pace", body: "Ten Hail Marys or the whole Rosary; there is no wrong length.")
    ]

    /// A Daily Habit — rhythm and returning, never a debt owed.
    static let habit: [ReminderMessage] = [
        ReminderMessage(title: "Today's Rosary", body: "The same quiet hour, kept once more."),
        ReminderMessage(title: "Your rhythm, right on time", body: "A few minutes now, and the day has its anchor."),
        ReminderMessage(title: "The hour you set aside", body: "Whatever kind of day it has been, the beads are the same."),
        ReminderMessage(title: "A small, steady thing", body: "The whole Rosary, or ten Hail Marys — the habit is in the returning."),
        ReminderMessage(title: "Prayer keeps the day's shape", body: "Begin whenever it suits; the beads keep no clock."),
        ReminderMessage(title: "Same time, same grace", body: "The Rosary asks little and gives much."),
        ReminderMessage(title: "A day with a Rosary in it", body: "That is all today needs to be.")
    ]

    /// Closer to Mary — filial, Marian, always ending at her Son.
    static let devotion: [ReminderMessage] = [
        ReminderMessage(title: "Mary is waiting", body: "She has all the time in the world for you."),
        ReminderMessage(title: "A word with your Mother", body: "The Rosary is simply time spent with her."),
        ReminderMessage(title: "She holds out her hand", body: "Take up the beads and walk the mysteries with her."),
        ReminderMessage(title: "All yours, Mary", body: "Give her these few minutes and she will give them to her Son."),
        ReminderMessage(title: "Through her, to him", body: "Every Hail Mary you pray she carries straight to Jesus."),
        ReminderMessage(title: "The Mother of God knows your name", body: "Come and tell her what the day has held."),
        ReminderMessage(title: "Hail Mary", body: "Fifty of them, and she is nearer than when you began.")
    ]

    /// Learning the Rosary — kept small, because this intention draws
    /// from every pool (see `pool(for:)`). Beginner-framed copy goes
    /// stale the moment someone learns the Rosary; these do not: each is
    /// as true in the tenth year as in the first week.
    static let learning: [ReminderMessage] = [
        ReminderMessage(title: "Today's mystery is ready", body: "The scene, the scripture, and the prayers, all in one place."),
        ReminderMessage(
            title: "There is always more in it", body: "Eight centuries of saints have not exhausted the mysteries."),
        ReminderMessage(
            title: "Five scenes from the Gospel", body: "That is all a Rosary is: look at each one with Mary."),
        ReminderMessage(
            title: "One Hail Mary, then the next", body: "The whole Rosary is only ever one bead at a time."),
        ReminderMessage(
            title: "Where Mary was", body: "Nazareth, Bethlehem, Calvary: pray your way through her story."),
        ReminderMessage(
            title: "The mysteries need no expert", body: "A beginner's Rosary is a Rosary. Pray it as you can.")
    ]

    /// Used when the intention question was skipped.
    static let standard: [ReminderMessage] = [
        ReminderMessage(title: "A quiet moment awaits", body: "The Rosary is here whenever you are ready."),
        ReminderMessage(title: "Today's mysteries are ready", body: "A few minutes of stillness amid the day."),
        ReminderMessage(title: "The Rosary is close by", body: "Peace begins with a single Hail Mary."),
        ReminderMessage(title: "The beads are where you left them", body: "Pick them up whenever the day allows."),
        ReminderMessage(title: "Mary keeps a place for you", body: "Come sit with the mysteries a while."),
        ReminderMessage(title: "An invitation to stillness", body: "Sit with one mystery and see where it goes."),
        ReminderMessage(title: "Grace in the ordinary", body: "Ten Hail Marys can change the whole day.")
    ]

    // MARK: - The seasons

    /// Advent — the Joyful Mysteries' own weeks, waiting with Mary.
    static let advent: [ReminderMessage] = [
        ReminderMessage(title: "Advent: she is waiting too", body: "Walk the last weeks before Bethlehem with Mary."),
        ReminderMessage(title: "Make room in the inn", body: "A decade tonight clears a little space for Him."),
        ReminderMessage(
            title: "The Joyful Mysteries fit the season", body: "Nazareth, the hill country, Bethlehem: they are near."),
        ReminderMessage(
            title: "Come, Lord Jesus", body: "The whole of Advent is in that one prayer, and in the beads."),
        ReminderMessage(title: "A light in the dark of the year", body: "Pray a decade by the Advent candle."),
    ]

    /// Lent — the Sorrowful Mysteries, walked with her to Calvary.
    static let lent: [ReminderMessage] = [
        ReminderMessage(
            title: "Forty days, one decade at a time",
            body: "Lent is long enough to learn the Sorrowful Mysteries by heart."),
        ReminderMessage(title: "Walk to Calvary with her", body: "Mary went the whole way. The beads go with you."),
        ReminderMessage(title: "A quiet Lenten offering", body: "The Rosary asks for no fasting, only a little time."),
        ReminderMessage(title: "The garden, the pillar, the cross", body: "Five scenes of His love, this evening."),
        ReminderMessage(title: "Keep Lent with Mary", body: "She stood by the cross. Stand with her a while."),
    ]

    /// Eastertide — from Easter to Pentecost, the Glorious Mysteries.
    static let eastertide: [ReminderMessage] = [
        ReminderMessage(title: "He is risen", body: "The Glorious Mysteries are the season's own prayer."),
        ReminderMessage(title: "Fifty days of joy", body: "Easter is not one day. Keep it with a decade."),
        ReminderMessage(
            title: "Queen of Heaven, rejoice",
            body: "The Church sings it to Mary till Pentecost. Say it with the beads."),
        ReminderMessage(title: "The empty tomb is still open", body: "Begin a Rosary at the Resurrection tonight."),
        ReminderMessage(title: "From Easter to Pentecost", body: "Pray with the Apostles, waiting for the Spirit."),
    ]

    /// May — Mary's month.
    static let may: [ReminderMessage] = [
        ReminderMessage(title: "May is Mary's month", body: "A Rosary a day is the oldest way to keep it."),
        ReminderMessage(title: "Bring her flowers", body: "Each Hail Mary is a rose. Fifty make a crown."),
        ReminderMessage(title: "The month of Mary", body: "The saints kept May with the beads. So can you."),
        ReminderMessage(title: "A May evening with Mary", body: "The mysteries, read slowly, as the light goes."),
        ReminderMessage(
            title: "Her month, your Rosary", body: "Nothing pleases her more than her Son's story told again."),
    ]

    /// October — the month of the Rosary.
    static let october: [ReminderMessage] = [
        ReminderMessage(
            title: "October, the month of the Rosary", body: "Our Lady of the Rosary is kept on the seventh."),
        ReminderMessage(title: "The Rosary's own month", body: "The beads were made for days like this one."),
        ReminderMessage(
            title: "Our Lady of the Rosary",
            body: "Pope Leo asked for a Rosary a day in October. One decade is a start."),
        ReminderMessage(title: "An October Rosary", body: "The mysteries, with the leaves turning outside."),
        ReminderMessage(title: "The Church's month of beads", body: "Join her. Today's mysteries are ready."),
    ]

    /// The season a day falls in, where the season has a pool of its own.
    /// Lent and Advent come first, since they are the Church's own
    /// seasons; Eastertide outranks May where the two overlap; October
    /// is the Rosary's month by Leo XIII's wish.
    static func seasonPool(on date: Date, calendar: Calendar = .current) -> [ReminderMessage]? {
        switch ScheduleService.season(for: date, calendar: calendar) {
        case .lent: return lent
        case .advent: return advent
        case .ordinary: break
        }
        let day = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: day)
        if let easter = ScheduleService.easterSunday(year: year, calendar: calendar),
            let pentecost = ScheduleService.pentecost(year: year, calendar: calendar),
            day >= easter, day <= pentecost
        {
            return eastertide
        }
        switch calendar.component(.month, from: day) {
        case 5: return may
        case 10: return october
        default: return nil
        }
    }

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

    /// The pool for a set of intentions on a given day: the intentions'
    /// own pool, with the season's lines woven in while the season
    /// lasts, so an Advent week hears of Advent without losing the voice
    /// the reader chose.
    static func pool(for intentions: [PrayerIntention], on date: Date, calendar: Calendar = .current)
        -> [ReminderMessage]
    {
        let own = pool(for: intentions)
        guard let season = seasonPool(on: date, calendar: calendar) else { return own }
        return interleaved([own, season])
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
