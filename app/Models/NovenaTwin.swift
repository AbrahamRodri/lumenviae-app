//
//  NovenaTwin.swift
//  Lumen Viae
//
//  A novena's twin — the Prayer Book prayer holding the whole novena as
//  text — cut into its days, so the pray-along page shows one day at a
//  time (design option A, Abraham 15 Nov 2026: "A"). The days are read
//  from the twin's own headings ("[The Fourth Day.]", "[Día cuarto.]");
//  what stands before the first day (how each day goes) and after the
//  last (the prayer said every day) is the CLOSING page.
//
//  A twin whose headings do not name every day (a novena that prays the
//  same words each day) is not cut, and is read whole as before.
//

import Foundation

nonisolated struct NovenaTwin: Equatable {

    /// The stanza indices of each day, the first day first
    let days: [[Int]]
    /// What stands before the first day and after the last, read on the
    /// CLOSING page; empty when the twin has neither
    let closing: [Int]

    /// The stanzas of the page shown: a day (1-based), or the closing
    /// with `day` nil
    func stanzas(day: Int?) -> Set<Int> {
        guard let day else { return Set(closing) }
        return days.indices.contains(day - 1) ? Set(days[day - 1]) : []
    }

    /// Cuts a twin's stanzas into `length` days, or nil when its headings
    /// do not name them all
    init?(stanzas: [String], length: Int) {
        let rubrics: [String?] = stanzas.map { stanza in
            let lines = stanza.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            guard lines.count == 1, PrayerMarkup.isRubric(lines[0]) else { return nil }
            return PrayerMarkup.rubric(lines[0])
        }
        let starts = rubrics.indices.filter { rubrics[$0].map(Self.namesADay) ?? false }
        guard length > 1, starts.count == length else { return nil }

        // The last day runs to the next part the twin names after it
        // ("[Closing prayer, each day.]", "[The Act of Consecration to the
        // Holy Spirit.]"): a direction that only names prayers to say, the
        // request's pause or "Let us pray" belongs to the day
        let afterLast = (starts[starts.count - 1] + 1)..<stanzas.count
        let end = afterLast.first { i in
            guard let words = rubrics[i] else { return false }
            let bare = words.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ". "))
            return PrayerPage.saidPrayers(in: words) == nil && !PrayerPage.isIntention(words)
                && !["let us pray", "oremos", "oremus"].contains(bare)
        } ?? stanzas.count

        var days: [[Int]] = []
        for (n, start) in starts.enumerated() {
            let next = n + 1 < starts.count ? starts[n + 1] : end
            days.append(Array(start..<next))
        }
        self.days = days
        self.closing = Array(0..<starts[0]) + Array(end..<stanzas.count)
    }

    private static let ordinals = [
        "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth",
        "primer", "primero", "segundo", "tercer", "tercero", "cuarto", "quinto", "sexto", "séptimo", "septimo",
        "octavo", "noveno",
    ]

    /// "The Fourth Day.", "The Eighth Day, December 6.", "Día cuarto.",
    /// "Cuarto día."
    static func namesADay(_ words: String) -> Bool {
        let folded = words.lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        var tokens = folded.split(whereSeparator: { " ,:".contains($0) }).map(String.init)
        if tokens.first == "the" { tokens.removeFirst() }
        guard tokens.count >= 2 else { return false }
        let isDay = { (word: String) in word == "day" || word == "día" || word == "dia" }
        return (ordinals.contains(tokens[0]) && isDay(tokens[1]))
            || (isDay(tokens[0]) && (ordinals.contains(tokens[1]) || Int(tokens[1]) != nil))
    }
}
