//
//  LibraryBookParser.swift
//  Lumen Viae
//
//  Cuts a Project Gutenberg plain-text edition into the chapters the
//  reader reads, using the per-edition rules carried by the catalog.
//
//  Gutenberg plain text is hard-wrapped at ~72 columns with blank
//  lines between paragraphs, opens with a licensing header, and closes
//  with a licensing footer. The parser trims both, walks the body
//  matching the edition's heading patterns, rejects contents-page
//  lines by body length, lifts each chapter's printed title, and
//  unwraps the hard-wrapped lines into whole paragraphs.
//
//  Deterministic by design: the same text and rules always cut the
//  same chapters, so a chapter index is a stable identity for caching
//  and reading progress.
//

import Foundation

nonisolated enum LibraryBookParser {

    /// Cuts one edition's text into a book.
    static func parse(text: String, info: LibraryBookInfo) -> LibraryBook {
        let rules = info.parsing
        // Gutenberg serves CRLF line endings. `$` happens to match
        // before a trailing \r, but "blank" lines still hold one — and
        // blank lines are what paragraph and title cutting stand on —
        // so normalize before anything looks at a line.
        let body = stripGutenbergEnvelope(from: text)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = body.components(separatedBy: "\n").map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        let chapterRegex = try? NSRegularExpression(pattern: rules.chapterPattern)
        let partRegex = rules.partPattern.flatMap { try? NSRegularExpression(pattern: $0) }
        let stopRegex = rules.stopPattern.flatMap { try? NSRegularExpression(pattern: $0) }

        var raw: [(heading: String, part: String?, lines: [String])] = []
        var current: (heading: String, part: String?, lines: [String])?
        var part: String?

        // Whether the parse has reached the body proper: some heading has
        // gathered more text under it than a contents entry ever could.
        // Once true it stays true.
        var bodyHasBegun = false
        var openLength = 0

        for line in lines {
            // The stop line ends the book — but only once the body has
            // begun, so a contents page naming the epilogue cannot end
            // the parse before the book has started.
            //
            // "A chapter heading is open" would not be enough: a contents
            // page whose entries match the chapter pattern opens one too,
            // and the epilogue it lists sits a few lines below. The test
            // is the same `minimumChapterLength` that separates a contents
            // entry from a chapter below, so the stop line and the chapter
            // filter agree on where the front matter ends.
            if let stopRegex, bodyHasBegun, matches(stopRegex, line) {
                break
            }
            if let partRegex, matches(partRegex, line) {
                if let finished = current { raw.append(finished) }
                current = nil
                openLength = 0
                part = titleCased(line)
                continue
            }
            if let chapterRegex, matches(chapterRegex, line) {
                if let finished = current { raw.append(finished) }
                current = (heading: line, part: part, lines: [])
                openLength = 0
                continue
            }
            if current != nil {
                current?.lines.append(line)
                openLength += line.count
                if openLength >= rules.minimumChapterLength { bodyHasBegun = true }
            }
        }
        if let finished = current { raw.append(finished) }

        var chapters: [LibraryChapter] = []
        for candidate in raw {
            let bodyLength = candidate.lines.reduce(0) { $0 + $1.count }
            // A heading whose body runs this short is the contents page
            // naming a chapter, not the chapter itself.
            guard bodyLength >= rules.minimumChapterLength else { continue }

            var (heading, title) = splitHeading(candidate.heading)
            var contentLines = candidate.lines

            // No inline title: the first short block after the heading
            // is the chapter's printed title. A long first block is
            // simply the body beginning (Confessions prints none).
            if title == nil {
                var index = contentLines.startIndex
                while index < contentLines.endIndex, contentLines[index].isEmpty {
                    index += 1
                }
                var block: [String] = []
                var end = index
                while end < contentLines.endIndex, !contentLines[end].isEmpty {
                    block.append(contentLines[end])
                    end += 1
                }
                let joined = block.joined(separator: " ")
                if !joined.isEmpty, joined.count <= 140 {
                    title = joined
                    contentLines.removeSubrange(contentLines.startIndex..<end)
                }
            }

            if var lifted = title {
                if lifted == lifted.uppercased() { lifted = titleCased(lifted) }
                if lifted.hasSuffix(".") { lifted = String(lifted.dropLast()) }
                title = lifted
            }

            chapters.append(LibraryChapter(
                id: chapters.count,
                part: candidate.part,
                heading: heading,
                title: title,
                paragraphs: paragraphs(from: contentLines)
            ))
        }

        return LibraryBook(bookID: info.id, chapters: chapters)
    }

    // MARK: - Pieces

    /// Everything between the *** START and *** END licensing markers.
    private static func stripGutenbergEnvelope(from text: String) -> String {
        var body = text
        if let start = body.range(of: "*** START OF THE PROJECT GUTENBERG EBOOK"),
           let lineEnd = body.range(of: "\n", range: start.upperBound..<body.endIndex) {
            body = String(body[lineEnd.upperBound...])
        }
        if let end = body.range(of: "*** END OF THE PROJECT GUTENBERG EBOOK") {
            body = String(body[..<end.lowerBound])
        }
        return body
    }

    private static func matches(_ regex: NSRegularExpression, _ line: String) -> Bool {
        guard !line.isEmpty else { return false }
        let range = NSRange(line.startIndex..., in: line)
        return regex.firstMatch(in: line, range: range) != nil
    }

    /// "CHAPTER V VOCATION OF THÉRÈSE" → ("Chapter V", "VOCATION OF
    /// THÉRÈSE"); "BOOK I" → ("Book I", nil); anything else is its own
    /// heading, split at a colon when it carries one.
    private static func splitHeading(_ line: String) -> (heading: String, title: String?) {
        let labelPattern = #"^(CHAPTER|BOOK|PART|SECTION|MEDITATION)\s+([IVXLC]+)\.?(?:\s+(.*))?$"#
        if let regex = try? NSRegularExpression(pattern: labelPattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
            let label = substring(line, match.range(at: 1))?.capitalized ?? ""
            let numeral = substring(line, match.range(at: 2)) ?? ""
            let inline = substring(line, match.range(at: 3))?
                .trimmingCharacters(in: .whitespaces)
            return ("\(label) \(numeral)", (inline?.isEmpty ?? true) ? nil : inline)
        }
        if let colon = line.firstIndex(of: ":") {
            let head = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            let rest = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            return (titleCased(head), rest.isEmpty ? nil : rest)
        }
        return (titleCased(line), nil)
    }

    private static func substring(_ line: String, _ range: NSRange) -> String? {
        guard range.location != NSNotFound, let r = Range(range, in: line) else { return nil }
        return String(line[r])
    }

    /// "THE FIRST BOOK" → "The First Book", leaving roman numerals as
    /// they stand.
    private static func titleCased(_ line: String) -> String {
        line.split(separator: " ").map { word -> String in
            let w = String(word)
            if w.range(of: #"^[IVXLC]+\.?,?$"#, options: .regularExpression) != nil {
                return w
            }
            return w.localizedCapitalized
        }.joined(separator: " ")
    }

    /// Blank-line blocks become paragraphs; the hard-wrapped lines of
    /// each block join back into one. Separator rules (underscores,
    /// asterisks) fall away, and Gutenberg's _underscore emphasis_ is
    /// unwrapped — the reader has no italic markup to give it.
    private static func paragraphs(from lines: [String]) -> [String] {
        var paragraphs: [String] = []
        var block: [String] = []

        func close() {
            guard !block.isEmpty else { return }
            var text = block.joined(separator: " ")
            text = text.replacingOccurrences(
                of: #"_([^_]+)_"#, with: "$1", options: .regularExpression
            )
            text = text.replacingOccurrences(of: "_", with: "")
            paragraphs.append(text)
            block = []
        }

        for line in lines {
            let isSeparator = line.range(
                of: #"^[_\*\s]*$"#, options: .regularExpression
            ) != nil
            if isSeparator {
                close()
            } else {
                block.append(line)
            }
        }
        close()
        return paragraphs
    }
}
