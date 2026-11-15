//
//  PrayerPage.swift
//  Lumen Viae
//
//  How the pray-along page sets a prayer, read from its text: the
//  prayer-book page Abraham chose (design option 1, 15 Nov 2026: "1, no in
//  full but litany changes good rest good"). Every repeated prayer stays
//  printed in full; what changes is how the parts read:
//
//  - ℣ and ℟ hang in a red column, and the answer after ℟ is bold.
//  - A mark of three red dots stands between the parts of a prayer.
//  - A direction that names a part ("[The first shedding of His Blood:
//    the Circumcision. Luke 2:21.]", "[The First Day.]") is a heading,
//    its Scripture reference beneath it.
//  - A direction that only names prayers to say ("[Our Father, Hail Mary,
//    Glory Be.]") becomes small marks, each opening that prayer.
//  - "[Here name your request.]" becomes a quiet gold pause.
//  - The closing collect — the ℣ and ℟ before it, "Let us pray", the
//    prayer and its Amen — stands as one block.
//  - A litany's group of calls carries its answer once beside it.
//
//  Pure, so the rules are tested without drawing (PrayerPageTests).
//

import Foundation

// MARK: - The page

/// A prayer's stanzas, gathered into the sections the page draws. A stanza
/// keeps the index `PrayAlongView.stanzas` gives it, which the voice
/// lights by, so nothing here changes what is said or when.
nonisolated struct PrayerPage: Equatable {

    let sections: [Section]

    /// The page carries a litany group, so it says once how to answer
    var hasLitanyGroups: Bool {
        sections.contains { section in
            section.stanzas.contains { stanza in
                stanza.parts.contains { if case .litanyGroup = $0 { return true } else { return false } }
            }
        }
    }

    enum Section: Equatable {
        /// One stanza on the page, after the parts mark when it opens a
        /// new part of the prayer
        case stanza(Stanza, opensPart: Bool)
        /// The closing collect, its stanzas in one block
        case collect([Stanza], opensPart: Bool)

        var stanzas: [Stanza] {
            switch self {
            case .stanza(let stanza, _): return [stanza]
            case .collect(let stanzas, _): return stanzas
            }
        }

        var opensPart: Bool {
            switch self {
            case .stanza(_, let opens), .collect(_, let opens): return opens
            }
        }
    }

    struct Stanza: Equatable {
        let index: Int
        let parts: [Part]
    }

    enum Part: Equatable {
        /// A stanza set as it always was (`PrayAlongStanza`): verse,
        /// prose, a pointed canticle, a bilingual pair
        case classic(String)
        /// Lines with ℣ and ℟ in their red column
        case lines([Line])
        /// The words a prayer opens on to say what it is, in quiet italic
        case intro(String)
        case heading(title: String, reference: String?)
        /// The prayers said here, as small marks
        case said([SaidPrayer])
        /// Where the reader names what they ask for
        case intention
        case litanyGroup(invocations: [String], response: String)
        /// The three red dots, where the text drew a rule
        case mark
        /// A collect's "Let us pray", as the block's small red heading
        case letUsPray(String)
        /// A collect's prayer, as one paragraph
        case paragraph(String)
    }

    enum Line: Equatable {
        case versicle(String)
        case response(String)
        case verse(String)
        case rubric(String)
        case litany(invocation: String, response: String)
    }

    struct SaidPrayer: Equatable, Hashable, Identifiable {
        /// The name as the direction writes it
        let name: String
        /// The book's prayer it opens
        let prayerID: String
        var id: String { "\(prayerID):\(name)" }
    }

    // MARK: - Reading

    init(stanzas: [String]) {
        let parsed = stanzas.enumerated().map {
            Stanza(index: $0.offset, parts: Self.parts(of: $0.element, at: $0.offset))
        }
        let lines = stanzas.map(Self.lines(of:))

        var sections: [Section] = []
        var i = 0
        while i < parsed.count {
            if let range = Self.collectRange(at: i, lines: lines) {
                let members = range.map { Self.collectStanza(parsed[$0], lines: lines[$0]) }
                sections.append(.collect(members, opensPart: Self.opensPart(range.lowerBound, lines: lines)))
                i = range.upperBound + 1
            } else {
                sections.append(.stanza(parsed[i], opensPart: Self.opensPart(i, lines: lines)))
                i += 1
            }
        }
        self.sections = sections
    }

    private static func lines(of stanza: String) -> [String] {
        stanza.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Marks between parts

    /// A part begins at a ℣ that follows the prayers said after the last
    /// one — each ℣ of the Angelus after its Hail Mary — never at the
    /// page's first stanza, and never twice in a row
    private static func opensPart(_ i: Int, lines: [[String]]) -> Bool {
        guard i > 0, let first = lines[i].first, isVersicle(first) else { return false }
        let before = lines[i - 1]
        guard let last = before.last else { return false }
        return !isVersicle(last) && !isResponse(last) && !(before.count == 1 && PrayerMarkup.isRule(last))
    }

    // MARK: - The collect

    private static func isLetUsPray(_ line: String) -> Bool {
        guard PrayerMarkup.isRubric(line) else { return false }
        let words = PrayerMarkup.rubric(line).lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        return ["let us pray", "oremos", "oremus"].contains(words)
    }

    /// The stanzas of a collect beginning at `i`: a stanza holding "Let
    /// us pray" with the ℣ ℟ stanza before it, and the prayer's stanza
    /// after it when the direction stands alone
    private static func collectRange(at i: Int, lines: [[String]]) -> ClosedRange<Int>? {
        func holdsLetUsPray(_ j: Int) -> Bool {
            j < lines.count && lines[j].contains(where: isLetUsPray) && !lines[j].contains { $0.contains("|||") }
        }
        func isVersicles(_ j: Int) -> Bool {
            j < lines.count && !lines[j].isEmpty && lines[j].allSatisfy { isVersicle($0) || isResponse($0) }
        }

        var start = i
        var center = i
        if isVersicles(i), holdsLetUsPray(i + 1) {
            center = i + 1
        } else if !holdsLetUsPray(i) {
            return nil
        }
        start = min(start, center)

        var end = center
        // "Let us pray" stands as the stanza's last line: its prayer is
        // the stanza after
        if let last = lines[center].last, isLetUsPray(last), center + 1 < lines.count,
            !lines[center + 1].contains(where: isLetUsPray)
        {
            end = center + 1
        }
        return start...end
    }

    /// A collect's stanza: its ℣ ℟ lines, "Let us pray" as a heading, and
    /// the prayer after it as one paragraph, its closing Amen answered
    private static func collectStanza(_ stanza: Stanza, lines: [String]) -> Stanza {
        var parts: [Part] = []
        var before: [Line] = []
        var prayer: [String] = []
        var seenLetUsPray = false

        func closePrayer() {
            guard !prayer.isEmpty else { return }
            var text = prayer.joined(separator: " ")
            var amen: String?
            for word in ["Amen.", "Amén.", "Amen"] where text.hasSuffix(" " + word) {
                text = String(text.dropLast(word.count + 1))
                amen = word
                break
            }
            parts.append(.paragraph(text))
            if let amen { parts.append(.lines([.response(amen)])) }
            prayer = []
        }

        for line in lines {
            if isLetUsPray(line) {
                if !before.isEmpty {
                    parts.append(.lines(before))
                    before = []
                }
                closePrayer()
                parts.append(
                    .letUsPray(PrayerMarkup.rubric(line).trimmingCharacters(in: CharacterSet(charactersIn: ". "))))
                seenLetUsPray = true
            } else if isVersicle(line) || isResponse(line) {
                closePrayer()
                before.append(Self.line(line))
            } else if seenLetUsPray || !lines.contains(where: isLetUsPray) {
                if !before.isEmpty {
                    parts.append(.lines(before))
                    before = []
                }
                prayer.append(line)
            } else {
                before.append(Self.line(line))
            }
        }
        if !before.isEmpty { parts.append(.lines(before)) }
        closePrayer()
        return Stanza(index: stanza.index, parts: parts)
    }

    // MARK: - A stanza's parts

    private static func parts(of stanza: String, at index: Int) -> [Part] {
        let lines = Self.lines(of: stanza)
        guard !lines.isEmpty else { return [] }

        // A pair of languages, or a canticle pointed at its mediant, is
        // set as it always was
        if lines.contains(where: { $0.contains("|||") || PrayerMarkup.isPointed($0) }) {
            return [.classic(stanza)]
        }

        if lines.count == 1 {
            let line = lines[0]
            if PrayerMarkup.isRule(line) { return [.mark] }
            if PrayerMarkup.isRubric(line) {
                let words = PrayerMarkup.rubric(line)
                if let said = saidPrayers(in: words) { return [.said(said)] }
                if isIntention(words) { return [.intention] }
                if let heading = heading(words) { return [heading] }
                if index == 0, words.count > 60 { return [.intro(words)] }
            }
        }

        // A litany's group: its first call carries the answer, and the
        // calls beneath it answer the same
        if lines.count > 1, PrayerMarkup.isLitany(lines[0]),
            lines.dropFirst().allSatisfy({ !$0.contains("℟") && !PrayerMarkup.isRubric($0) })
        {
            let first = PrayerMarkup.litanyParts(lines[0])
            return [.litanyGroup(invocations: [first.invocation] + lines.dropFirst(), response: first.response)]
        }

        // Lines with ℣ or ℟ take the red column
        if lines.contains(where: { isVersicle($0) || isResponse($0) }) {
            return [.lines(lines.map(line))]
        }

        return [.classic(stanza)]
    }

    private static func line(_ text: String) -> Line {
        if isVersicle(text) { return .versicle(stripped(text, "℣")) }
        if isResponse(text) { return .response(stripped(text, "℟")) }
        if PrayerMarkup.isRubric(text) { return .rubric(PrayerMarkup.rubric(text)) }
        if PrayerMarkup.isLitany(text) {
            let parts = PrayerMarkup.litanyParts(text)
            return .litany(invocation: parts.invocation, response: parts.response)
        }
        return .verse(text)
    }

    static func isVersicle(_ line: String) -> Bool { line.hasPrefix("℣") }
    static func isResponse(_ line: String) -> Bool { line.hasPrefix("℟") }

    /// The words after the mark and its full stop
    private static func stripped(_ line: String, _ mark: String) -> String {
        var rest = line.dropFirst(mark.count)
        if rest.hasPrefix(".") { rest = rest.dropFirst() }
        return rest.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Directions

    /// The prayers a direction names, in the three languages the book
    /// prays in, longest first so "Hail, Holy Queen" is not read as
    /// "Hail" and the rest
    private static let saidNames: [(name: String, id: String)] = [
        ("Hail, Holy Queen", "hail_holy_queen"),
        ("Our Father", "our_father"),
        ("Hail Mary", "hail_mary"),
        ("Glory Be", "glory_be"),
        ("Glory be to the Father", "glory_be"),
        ("Padre Nuestro", "our_father"),
        ("Padrenuestro", "our_father"),
        ("Avemaría", "hail_mary"),
        ("Ave María", "hail_mary"),
        ("Gloria", "glory_be"),
        ("Pater Noster", "our_father"),
        ("Ave Maria", "hail_mary"),
        ("Gloria Patri", "glory_be"),
    ].sorted { $0.name.count > $1.name.count }

    /// "Our Father, Hail Mary, Glory Be." as the prayers it names, or nil
    /// when the direction says anything else ("Hail Mary, three times")
    static func saidPrayers(in words: String) -> [SaidPrayer]? {
        var rest = Substring(words)
        var found: [SaidPrayer] = []
        let separators = CharacterSet(charactersIn: ",.;· ")
        while true {
            rest = rest.drop { $0.unicodeScalars.allSatisfy(separators.contains) }
            if rest.lowercased().hasPrefix("and ") {
                rest = rest.dropFirst(4)
                continue
            }
            if rest.lowercased().hasPrefix("y ") {
                rest = rest.dropFirst(2)
                continue
            }
            if rest.isEmpty { break }
            guard let match = saidNames.first(where: { rest.lowercased().hasPrefix($0.name.lowercased()) }) else {
                return nil
            }
            let name = String(rest.prefix(match.name.count))
            found.append(SaidPrayer(name: name, prayerID: match.id))
            rest = rest.dropFirst(match.name.count)
        }
        return found.isEmpty ? nil : found
    }

    /// "Here name your request." and the forms the book writes it in
    static func isIntention(_ words: String) -> Bool {
        let folded = words.lowercased()
        let objects = [
            "your request", "the favour asked", "the favor asked", "the need", "the grace", "your intention",
        ]
        guard folded.hasPrefix("here name ") else { return false }
        return objects.contains { folded.contains($0) }
    }

    /// A direction that names a part of the prayer: one ending on a
    /// Scripture reference, a day of a novena, or a title with no full
    /// stop ("The Precepts of the Church")
    static func heading(_ words: String) -> Part? {
        let trimmed = words.trimmingCharacters(in: .whitespaces)
        if let match = trimmed.firstMatch(of: /^(.+?)[.,:;]?\s+((?:[1-4] )?[A-Z][a-zA-Z]+\.? \d+:\d+(?:[-–]\d+)?)\.?$/)
        {
            let title = String(match.1).trimmingCharacters(in: CharacterSet(charactersIn: " ."))
            return .heading(title: title, reference: String(match.2))
        }
        let bare = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let lowered = bare.lowercased()
        if trimmed.count <= 40,
            lowered.hasSuffix(" day") || lowered.hasPrefix("día ") || lowered.hasPrefix("dia ")
        {
            return .heading(title: bare, reference: nil)
        }
        if trimmed.count <= 48, let last = trimmed.last, !".:!?,;".contains(last), trimmed.first?.isUppercase == true {
            return .heading(title: trimmed, reference: nil)
        }
        return nil
    }
}
