//
//  PrayerBookSaints2.swift
//  Lumen Viae
//
//  Prayers to St Joseph, for a holy death and in work.
//  Sources: The Raccolta (English edition, 1910), for the Memorare to St Joseph and the prayer for a happy death
//  St Pius X, "Glorioso San Giuseppe, modello di tutti quelli che sono consacrati al lavoro" (1906)
//  English: our own literal rendering from the Latin of the Raccolta's Memento, from the Italian of St Pius X,
//  and from the Raccolta's prayer for a happy death
//

import Foundation

extension PrayerBookTexts {

    static let saints2: [BookPrayer] = [
        BookPrayer(
            id: "memorare_st_joseph",
            title: "The Memorare to St Joseph",
            latinTitle: "Memento, o castissime sponse Virginis Mariæ",
            origin: "The Raccolta · 19th century",
            note: "Said in any need, and above all on Wednesdays and through March, St Joseph's month.",
            english: """
Remember, O most chaste spouse of the Virgin Mary, that it has never been heard that anyone who ran to thy protection, or begged thy help, was left without comfort.

Moved by this trust, I come to thee, and commend myself to thee with all my heart. Do not despise my prayer, O thou who art called the father of the Redeemer, but in thy kindness hear it and grant it. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "st_joseph_workers",
            title: "To St Joseph, Model of Workers",
            latinTitle: nil,
            origin: "St Pius X · 1906",
            note: "Said before the day's work begins, and on May 1, the feast of St Joseph the Worker.",
            english: """
Glorious St Joseph, model of all who are given to labour, obtain for me the grace to work in a spirit of penance, in expiation of my many sins;

to work with a good conscience, putting the call of duty above my own inclinations; to work with thankfulness and joy, counting it an honour to use and to increase, by my labour, the gifts I have received from God;

to work with order, peace, moderation and patience, never shrinking from weariness or trouble; to work above all with a pure intention and with detachment from self, keeping always before my eyes death, and the account I must give of time lost, of talents unused, of good left undone, and of empty pride in success, so fatal to the work of God.

All for Jesus, all through Mary, all after thine example, O Patriarch Joseph. Such shall be my watchword in life and in death. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "st_joseph_happy_death",
            title: "To St Joseph for a Happy Death",
            latinTitle: nil,
            origin: "The Raccolta",
            note: "St Joseph died with Jesus and Mary beside him, and is asked for the same grace at the hour of death.",
            english: """
O blessed Joseph, who didst breathe thy last in the arms of Jesus and Mary, obtain for me this grace, I beseech thee: that I may die as thou didst, with Jesus and Mary beside me.

Be with me in my last struggle, keep me from the snares of the enemy, and when my soul goes forth from this life, present it to my Saviour, that I may praise Him with thee for ever. Amen.

Jesus, Mary and Joseph, I give you my heart and my soul.
Jesus, Mary and Joseph, assist me in my last agony.
Jesus, Mary and Joseph, may I breathe forth my soul in peace with you.
""",
            latin: nil
        ),
    ]
}
