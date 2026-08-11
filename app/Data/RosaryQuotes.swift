//
//  RosaryQuotes.swift
//  Lumen Viae
//
//  The daily quotation on the home screen — saints, popes, and Our Lady
//  herself on the Rosary. One is shown per day, chosen by day of the year.
//
//  Attribution rules: name the person as the Church now names them (St.,
//  Bl., Ven.), and cite the work only where the line is genuinely traceable
//  to it. Several of the most-circulated Rosary quotations have traditional
//  rather than documented attributions; those carry the name alone rather
//  than a source we cannot stand behind.
//

import Foundation

struct RosaryQuote: Hashable {
    let text: String
    let author: String

    /// The work it comes from, where it can be cited with confidence.
    var source: String? = nil
}

enum RosaryQuotes {

    static let all: [RosaryQuote] = [
        RosaryQuote(
            text: "The Rosary is the most beautiful and the most rich in graces of all prayers; it is the prayer that touches most the Heart of the Mother of God.",
            author: "St. Pius X"
        ),
        RosaryQuote(
            text: "Give me an army saying the Rosary and I will conquer the world.",
            author: "Bl. Pius IX"
        ),
        RosaryQuote(
            text: "The Rosary is a powerful weapon to put the demons to flight.",
            author: "St. Padre Pio"
        ),
        RosaryQuote(
            text: "Never will anyone who says his Rosary every day be led astray.",
            author: "Bl. Alan de la Roche"
        ),
        RosaryQuote(
            text: "The Rosary is the scourge of the devil.",
            author: "Pope Adrian VI"
        ),
        RosaryQuote(
            text: "Say the Rosary every day to obtain peace for the world.",
            author: "Our Lady of Fatima"
        ),
        RosaryQuote(
            text: "The holy Rosary is the storehouse of countless blessings.",
            author: "Bl. Alan de la Roche"
        ),
        RosaryQuote(
            text: "There is no problem, I tell you, no matter how difficult it is, that we cannot resolve by the prayer of the Holy Rosary.",
            author: "Sr. Lucia of Fatima"
        ),
        RosaryQuote(
            text: "I am the Lady of the Rosary. Continue to pray the Rosary every day.",
            author: "Our Lady of Fatima",
            source: "October 13, 1917"
        ),
        RosaryQuote(
            text: "The Rosary is a compendium of the entire Gospel.",
            author: "Bl. Paul VI",
            source: "Marialis Cultus"
        ),
        RosaryQuote(
            text: "When the Rosary is said well, it gives Jesus and Mary more glory and is more meritorious than any other prayer.",
            author: "St. Louis de Montfort",
            source: "The Secret of the Rosary"
        ),
        RosaryQuote(
            text: "If you say the Rosary faithfully until death, I do assure you that you shall receive a never-fading crown of glory.",
            author: "St. Louis de Montfort",
            source: "The Secret of the Rosary"
        ),
        RosaryQuote(
            text: "Recite your Rosary with faith, with humility, with confidence, and with perseverance.",
            author: "St. Louis de Montfort",
            source: "The Secret of the Rosary"
        ),
        RosaryQuote(
            text: "Love the Madonna and pray the Rosary, for her Rosary is the weapon against the evils of the world today.",
            author: "St. Padre Pio"
        ),
        RosaryQuote(
            text: "The Rosary is the weapon for these times.",
            author: "St. Padre Pio"
        ),
        RosaryQuote(
            text: "Blessed be that monotony of Hail Marys which purifies the monotony of your sins.",
            author: "St. Josemaría Escrivá",
            source: "The Way"
        ),
        RosaryQuote(
            text: "The Holy Rosary is a powerful weapon. Use it with confidence and you will be amazed at the results.",
            author: "St. Josemaría Escrivá"
        ),
        RosaryQuote(
            text: "The Rosary is the book of the blind, where souls see and there enact the greatest drama of love the world has ever known.",
            author: "Ven. Fulton J. Sheen",
            source: "The World's First Love"
        ),
        RosaryQuote(
            text: "The greatest method of praying is to pray the Rosary.",
            author: "St. Francis de Sales"
        ),
        RosaryQuote(
            text: "Among all the devotions approved by the Church, none has been so favored by so many miracles as the devotion of the Most Holy Rosary.",
            author: "Bl. Pius IX"
        ),
        RosaryQuote(
            text: "The Rosary is the most excellent form of prayer and the most efficacious means of attaining eternal life.",
            author: "Pope Leo XIII"
        ),
        RosaryQuote(
            text: "The family that prays together stays together.",
            author: "Ven. Patrick Peyton"
        )
    ]

    /// Today's quote. Day-of-year rather than random so the home screen is
    /// steady through the day and everyone praying today shares the same line.
    static var today: RosaryQuote {
        quote(offset: 0)
    }

    /// The quote for the completion screen, drawn half the catalog away from
    /// the home screen's so a single session never shows the same line twice.
    static var afterPraying: RosaryQuote {
        quote(offset: all.count / 2)
    }

    private static func quote(offset: Int) -> RosaryQuote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return all[(dayOfYear + offset) % all.count]
    }
}
