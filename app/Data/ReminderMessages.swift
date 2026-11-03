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
        ReminderMessage(
            title: String(
                localized: "Set the day down for a while",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "A little quiet, and nothing else asked of you.",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Nothing here is in a hurry",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The beads move at whatever pace you set.",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "A pause in the noise",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Ten Hail Marys are enough to change the air of a day.",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Come and rest",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Sit with a mystery and let the day wait.",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Somewhere quiet to go",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The mysteries are open whenever the day gets loud.",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "One bead at a time",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The app keeps count, so you can just pray.",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Peace, at your own pace",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Ten Hail Marys or the whole Rosary; there is no wrong length.",
                comment: "Daily prayer reminder notification for readers drawn by peace and stillness: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        )
    ]

    /// A Daily Habit — rhythm and returning, never a debt owed.
    static let habit: [ReminderMessage] = [
        ReminderMessage(
            title: String(
                localized: "Today's Rosary",
                comment: "Daily prayer reminder notification for readers building a daily habit: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The same quiet hour, kept once more.",
                comment: "Daily prayer reminder notification for readers building a daily habit: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Your time to pray",
                comment: "Daily prayer reminder notification for readers building a daily habit: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "A few minutes now, and the day has its anchor.",
                comment: "Daily prayer reminder notification for readers building a daily habit: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The hour you set aside",
                comment: "Daily prayer reminder notification for readers building a daily habit: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Whatever kind of day it has been, the beads are the same.",
                comment: "Daily prayer reminder notification for readers building a daily habit: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "A small, steady thing",
                comment: "Daily prayer reminder notification for readers building a daily habit: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The whole Rosary, or ten Hail Marys — the habit is in the returning.",
                comment: "Daily prayer reminder notification for readers building a daily habit: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Prayer keeps the day's shape",
                comment: "Daily prayer reminder notification for readers building a daily habit: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Begin whenever it suits; the beads keep no clock.",
                comment: "Daily prayer reminder notification for readers building a daily habit: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Same time, same grace",
                comment: "Daily prayer reminder notification for readers building a daily habit: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The Rosary asks little and gives much.",
                comment: "Daily prayer reminder notification for readers building a daily habit: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "A day with a Rosary in it",
                comment: "Daily prayer reminder notification for readers building a daily habit: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "That is all today needs to be.",
                comment: "Daily prayer reminder notification for readers building a daily habit: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        )
    ]

    /// Closer to Mary — filial, Marian, always ending at her Son.
    static let devotion: [ReminderMessage] = [
        ReminderMessage(
            title: String(
                localized: "Mary is waiting",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "She has all the time in the world for you.",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "A word with your Mother",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The Rosary is simply time spent with her.",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "She holds out her hand",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Take up the beads and walk the mysteries with her.",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "A few minutes for Mary",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Give her these few minutes and she will give them to her Son.",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Through her, to him",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Every Hail Mary you pray she carries straight to Jesus.",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The Mother of God knows your name",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Come and tell her what the day has held.",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Hail Mary",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Fifty of them, and she is nearer than when you began.",
                comment: "Daily prayer reminder notification for readers wanting to grow closer to Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        )
    ]

    /// Learning the Rosary — kept small, because this intention draws
    /// from every pool (see `pool(for:)`). Beginner-framed copy goes
    /// stale the moment someone learns the Rosary; these do not: each is
    /// as true in the tenth year as in the first week.
    static let learning: [ReminderMessage] = [
        ReminderMessage(
            title: String(
                localized: "Today's mysteries are ready",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The scene, the scripture, and the prayers, all in one place.",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "There is always more in it",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Eight centuries of saints have not exhausted the mysteries.",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Five scenes from the Gospel",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "That is all a Rosary is: look at each one with Mary.",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "One Hail Mary, then the next",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The whole Rosary is only ever one bead at a time.",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Where Mary was",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Nazareth, Bethlehem, Calvary: pray your way through her story.",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The mysteries need no expert",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "A beginner's Rosary is a Rosary. Pray it as you can.",
                comment: "Daily prayer reminder notification for readers learning the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        )
    ]

    /// Used when the intention question was skipped.
    static let standard: [ReminderMessage] = [
        ReminderMessage(
            title: String(
                localized: "A quiet moment awaits",
                comment: "Daily prayer reminder notification for readers who gave no reason: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The Rosary is here whenever you are ready.",
                comment: "Daily prayer reminder notification for readers who gave no reason: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Today's mysteries are ready",
                comment: "Daily prayer reminder notification for readers who gave no reason: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "A few minutes of stillness amid the day.",
                comment: "Daily prayer reminder notification for readers who gave no reason: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The Rosary is close by",
                comment: "Daily prayer reminder notification for readers who gave no reason: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Peace begins with a single Hail Mary.",
                comment: "Daily prayer reminder notification for readers who gave no reason: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The beads are where you left them",
                comment: "Daily prayer reminder notification for readers who gave no reason: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Pick them up whenever the day allows.",
                comment: "Daily prayer reminder notification for readers who gave no reason: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Mary keeps a place for you",
                comment: "Daily prayer reminder notification for readers who gave no reason: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Come sit with the mysteries a while.",
                comment: "Daily prayer reminder notification for readers who gave no reason: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "An invitation to stillness",
                comment: "Daily prayer reminder notification for readers who gave no reason: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Sit with one mystery and see where it goes.",
                comment: "Daily prayer reminder notification for readers who gave no reason: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Grace in the ordinary",
                comment: "Daily prayer reminder notification for readers who gave no reason: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Ten Hail Marys can change the whole day.",
                comment: "Daily prayer reminder notification for readers who gave no reason: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        )
    ]

    // MARK: - The seasons

    /// Advent — the Joyful Mysteries' own weeks, waiting with Mary.
    static let advent: [ReminderMessage] = [
        ReminderMessage(
            title: String(
                localized: "Advent: she is waiting too",
                comment: "Daily prayer reminder notification in Advent: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Walk the last weeks before Bethlehem with Mary.",
                comment: "Daily prayer reminder notification in Advent: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Make room in the inn",
                comment: "Daily prayer reminder notification in Advent: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "A decade tonight clears a little space for Him.",
                comment: "Daily prayer reminder notification in Advent: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The Joyful Mysteries fit the season",
                comment: "Daily prayer reminder notification in Advent: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Nazareth, the hill country, Bethlehem: they are near.",
                comment: "Daily prayer reminder notification in Advent: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Come, Lord Jesus",
                comment: "Daily prayer reminder notification in Advent: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The whole of Advent is in that one prayer, and in the beads.",
                comment: "Daily prayer reminder notification in Advent: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "A light in the dark of the year",
                comment: "Daily prayer reminder notification in Advent: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Pray a decade by the Advent candle.",
                comment: "Daily prayer reminder notification in Advent: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
    ]

    /// Lent — the Sorrowful Mysteries, walked with her to Calvary.
    static let lent: [ReminderMessage] = [
        ReminderMessage(
            title: String(
                localized: "Forty days, one decade at a time",
                comment: "Daily prayer reminder notification in Lent: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Lent is long enough to learn the Sorrowful Mysteries by heart.",
                comment: "Daily prayer reminder notification in Lent: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Walk to Calvary with her",
                comment: "Daily prayer reminder notification in Lent: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Mary went the whole way. The beads go with you.",
                comment: "Daily prayer reminder notification in Lent: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "A quiet Lenten offering",
                comment: "Daily prayer reminder notification in Lent: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The Rosary asks for no fasting, only a little time.",
                comment: "Daily prayer reminder notification in Lent: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The garden, the pillar, the cross",
                comment: "Daily prayer reminder notification in Lent: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Five scenes of His love, this evening.",
                comment: "Daily prayer reminder notification in Lent: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Keep Lent with Mary",
                comment: "Daily prayer reminder notification in Lent: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "She stood by the cross. Stand with her a while.",
                comment: "Daily prayer reminder notification in Lent: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
    ]

    /// Eastertide — from Easter to Pentecost, the Glorious Mysteries.
    static let eastertide: [ReminderMessage] = [
        ReminderMessage(
            title: String(
                localized: "He is risen",
                comment: "Daily prayer reminder notification in the Easter season: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The Glorious Mysteries are the season's own prayer.",
                comment: "Daily prayer reminder notification in the Easter season: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Fifty days of joy",
                comment: "Daily prayer reminder notification in the Easter season: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Easter is not one day. Keep it with a decade.",
                comment: "Daily prayer reminder notification in the Easter season: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Queen of Heaven, rejoice",
                comment: "Daily prayer reminder notification in the Easter season: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The Church sings it to Mary till Pentecost. Say it with the beads.",
                comment: "Daily prayer reminder notification in the Easter season: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The empty tomb is still open",
                comment: "Daily prayer reminder notification in the Easter season: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Begin a Rosary at the Resurrection tonight.",
                comment: "Daily prayer reminder notification in the Easter season: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "From Easter to Pentecost",
                comment: "Daily prayer reminder notification in the Easter season: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Pray with the Apostles, waiting for the Spirit.",
                comment: "Daily prayer reminder notification in the Easter season: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
    ]

    /// May — Mary's month.
    static let may: [ReminderMessage] = [
        ReminderMessage(
            title: String(
                localized: "May is Mary's month",
                comment: "Daily prayer reminder notification in May, the month of Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "A Rosary a day is the oldest way to keep it.",
                comment: "Daily prayer reminder notification in May, the month of Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Bring her flowers",
                comment: "Daily prayer reminder notification in May, the month of Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Each Hail Mary is a rose. Fifty make a crown.",
                comment: "Daily prayer reminder notification in May, the month of Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The month of Mary",
                comment: "Daily prayer reminder notification in May, the month of Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The saints kept May with the beads. So can you.",
                comment: "Daily prayer reminder notification in May, the month of Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "A May evening with Mary",
                comment: "Daily prayer reminder notification in May, the month of Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The mysteries, read slowly, as the light goes.",
                comment: "Daily prayer reminder notification in May, the month of Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Her month, your Rosary",
                comment: "Daily prayer reminder notification in May, the month of Mary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Nothing pleases her more than her Son's story told again.",
                comment: "Daily prayer reminder notification in May, the month of Mary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
    ]

    /// October — the month of the Rosary.
    static let october: [ReminderMessage] = [
        ReminderMessage(
            title: String(
                localized: "October, the month of the Rosary",
                comment: "Daily prayer reminder notification in October, the month of the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Our Lady of the Rosary is kept on the seventh.",
                comment: "Daily prayer reminder notification in October, the month of the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The Rosary's own month",
                comment: "Daily prayer reminder notification in October, the month of the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The beads were made for days like this one.",
                comment: "Daily prayer reminder notification in October, the month of the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "Our Lady of the Rosary",
                comment: "Daily prayer reminder notification in October, the month of the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Pope Leo asked for a Rosary a day in October. One decade is a start.",
                comment: "Daily prayer reminder notification in October, the month of the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "An October Rosary",
                comment: "Daily prayer reminder notification in October, the month of the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "The mysteries, with the leaves turning outside.",
                comment: "Daily prayer reminder notification in October, the month of the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
        ReminderMessage(
            title: String(
                localized: "The Church's month of beads",
                comment: "Daily prayer reminder notification in October, the month of the Rosary: its title, shown in bold. Warm and inviting, never scolding; under about 35 characters"
            ),
            body: String(
                localized: "Join her. Today's mysteries are ready.",
                comment: "Daily prayer reminder notification in October, the month of the Rosary: its text under the title. Warm and inviting, never scolding; under about 75 characters"
            )
        ),
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
