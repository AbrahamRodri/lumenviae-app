//
//  ShareText.swift
//  app
//
//  What a reader sends a friend from a meditation or a prayer (App Store
//  item W5): the title, the words as the page shows them (a long reading
//  cut to an excerpt), who wrote them where the app names it, then one
//  line and the App Store link, so the friend can pray it too. Plain text
//  only: the system share sheet takes it, and the reader picks where it
//  goes. No audio and no painting is shared.
//

import Foundation

enum ShareText {

    /// The app on the App Store
    static let appStoreLink = "https://apps.apple.com/app/id6760320749"

    /// About a long paragraph: enough to be read in a message, never pages
    static let excerptLimit = 600

    /// The line over the link, in the app's language
    static var invitation: String {
        String(
            localized: "Prayed with Lumen Viae, a Rosary and prayer companion:",
            comment:
                "Shared text from a meditation or a prayer: the line before the App Store link; Lumen Viae is the app's name"
        )
    }

    /// A meditation: its title, an excerpt of its words, and its author
    /// and book where the set names them (else the set's own name)
    static func meditation(
        title: String, content: String, author: String?, source: String?, setName: String,
        invitation: String = invitation
    ) -> String {
        let byline = [author, source].compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return compose(
            title: title,
            body: excerpt(plain(content)),
            byline: byline.isEmpty ? setName : byline,
            invitation: invitation
        )
    }

    /// A prayer in the language the page sets it in: Latin alone in
    /// Latin, the vernacular alone in the vernacular (Spanish in a Spanish
    /// app), both, one after the other, in the bilingual modes
    static func prayer(_ prayer: BookPrayer, language: PrayerLanguage, invitation: String = invitation) -> String {
        let title: String
        let words: String
        switch (language, prayer.latin) {
        case (.latin, let latin?):
            title = prayer.latinTitle ?? prayer.title
            words = latin
        case (.both, let latin?):
            title = prayer.title
            words = latin + "\n\n" + prayer.english
        case (.latinUnderEnglish, let latin?):
            title = prayer.title
            words = prayer.english + "\n\n" + latin
        default:
            title = prayer.title
            words = prayer.english
        }
        return compose(title: title, body: excerpt(plain(words)), byline: prayer.origin, invitation: invitation)
    }

    static func compose(title: String, body: String, byline: String?, invitation: String = invitation) -> String {
        var parts = [title, body]
        if let byline, !byline.isEmpty { parts.append("— " + byline) }
        parts.append(invitation + "\n" + appStoreLink)
        return parts.joined(separator: "\n\n")
    }

    /// The words cut at a paragraph, else a sentence, else a word, to no
    /// more than `limit` characters, with an ellipsis where they were cut
    static func excerpt(_ text: String, limit: Int = excerptLimit) -> String {
        guard text.count > limit else { return text }
        var kept: [String] = []
        var length = 0
        for paragraph in text.components(separatedBy: "\n\n") {
            let added = paragraph.count + (kept.isEmpty ? 0 : 2)
            guard length + added <= limit else { break }
            kept.append(paragraph)
            length += added
        }
        if !kept.isEmpty { return kept.joined(separator: "\n\n") + " …" }

        let head = String(text.prefix(limit))
        let sentenceEnds = [". ", "? ", "! ", "; "].compactMap { head.range(of: $0, options: .backwards)?.lowerBound }
        if let end = sentenceEnds.max(), head.distance(from: head.startIndex, to: end) > limit / 3 {
            return String(head[...end]) + " …"
        }
        if let space = head.range(of: " ", options: .backwards)?.lowerBound {
            return String(head[..<space]) + " …"
        }
        return head + "…"
    }

    /// The page's markup taken out: a reading's rules and `# ` title, a
    /// prayer's bracketed rubrics and a canticle's ` * ` pointing
    static func plain(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n").compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty, trimmed.allSatisfy({ $0 == "─" || $0 == "-" }) { return nil }
            if trimmed.hasPrefix("["), trimmed.hasSuffix("]") { return nil }
            var line = line.replacingOccurrences(of: " * ", with: " ")
            if line.hasPrefix("# ") { line.removeFirst(2) }
            return line
        }
        var result = lines.joined(separator: "\n")
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
