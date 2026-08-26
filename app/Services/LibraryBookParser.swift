//
//  LibraryBookParser.swift
//  Lumen Viae
//
//  Cuts a Project Gutenberg plain-text edition into the chapters the
//  reader reads, using the per-edition rules carried by the catalog.
//
//  Gutenberg plain text is hard-wrapped at ~72 columns with blank
//  lines between paragraphs, opens with a licensing header, and closes
//  with a licensing footer. The parser trims both, drops the front
//  matter at the edition's `startPattern`, walks the body matching the
//  edition's heading patterns, rejects contents-page lines by body
//  length, lifts each chapter's printed title, unwraps the hard-wrapped
//  lines into whole paragraphs, and lifts the editor's footnotes out of
//  the prose into an apparatus of their own.
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
        var lines = body.components(separatedBy: "\n").map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        // Everything above the book proper — half-title, imprimatur,
        // table of contents, publisher's matter — is dropped before a
        // single pattern is matched. The matching line is kept: it is
        // usually the first heading.
        if let startPattern = rules.startPattern,
           let startRegex = try? NSRegularExpression(pattern: startPattern),
           let first = lines.firstIndex(where: { matches(startRegex, $0) }) {
            lines = Array(lines[first...])
        }

        let chapterRegex = try? NSRegularExpression(pattern: rules.chapterPattern)
        let partRegex = rules.partPattern.flatMap { try? NSRegularExpression(pattern: $0) }
        let stopRegex = rules.stopPattern.flatMap { try? NSRegularExpression(pattern: $0) }
        let dropRegex = rules.dropPattern.flatMap { try? NSRegularExpression(pattern: $0) }

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
            // A printer's mark, not text: dropped wherever it falls, so
            // "END OF THE AUTOBIOGRAPHY" is not set as a paragraph in
            // the middle of the prose.
            if let dropRegex, matches(dropRegex, line) { continue }
            if let partRegex, matches(partRegex, line) {
                if let finished = current { raw.append(finished) }
                part = titleCased(line)
                // The part opens a unit of its own rather than closing
                // the book's ear: everything printed between a part
                // heading and its first chapter used to fall through the
                // `current != nil` guard and be dropped. For three of the
                // Imitation's books that was only a subtitle, which
                // `minimumChapterLength` discards again below — but Book
                // IV opens with à Kempis's own exhortation to Holy
                // Communion, in every printed edition and in none of ours.
                current = (heading: line, part: part, lines: [])
                openLength = 0
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
            //
            // Where the edition sets a title across more than one block
            // (`titleRunsToBlankGap`), keep taking blocks while exactly
            // one blank line separates them — the gap before the body is
            // wider — and join them into one title.
            if title == nil {
                var lifted: [String] = []
                var cursor = contentLines.startIndex

                while true {
                    var index = cursor
                    var gap = 0
                    while index < contentLines.endIndex, contentLines[index].isEmpty {
                        index += 1
                        gap += 1
                    }
                    // A second block only continues the title when the
                    // blank run before it is a single line.
                    if !lifted.isEmpty, !(rules.titleRunsToBlankGap && gap == 1) { break }

                    var block: [String] = []
                    var end = index
                    while end < contentLines.endIndex, !contentLines[end].isEmpty {
                        block.append(contentLines[end])
                        end += 1
                    }
                    let joined = block.joined(separator: " ")
                    guard !joined.isEmpty, joined.count <= 140 else { break }

                    // Each printed block ends with its own full stop;
                    // joined as they stand they read "…Falls of Jesus..
                    // The Daughters of Jerusalem".
                    lifted.append(
                        joined.hasSuffix(".") ? String(joined.dropLast()) : joined
                    )
                    cursor = end
                    if !rules.titleRunsToBlankGap { break }
                }

                if !lifted.isEmpty {
                    title = lifted.joined(separator: ". ")
                    contentLines.removeSubrange(contentLines.startIndex..<cursor)
                }
            }

            if var lifted = title {
                if lifted == lifted.uppercased() { lifted = titleCased(lifted) }
                if lifted.hasSuffix(".") { lifted = String(lifted.dropLast()) }
                title = lifted
            }

            // An edition that prints no titles gets the curated ones,
            // and a misprinted heading gets its correction.
            title = info.title(forChapter: chapters.count, printed: title)
            heading = info.heading(forChapter: chapters.count, printed: heading)

            let (prose, notes) = split(
                paragraphs: paragraphs(from: contentLines),
                notePattern: rules.notePattern
            )

            chapters.append(LibraryChapter(
                id: chapters.count,
                part: candidate.part,
                heading: heading,
                title: title,
                paragraphs: prose,
                notes: notes
            ))
        }

        return LibraryBook(bookID: info.id, chapters: chapters)
    }

    // MARK: - Pieces

    /// Everything between the *** START and *** END licensing markers.
    ///
    /// Gutenberg has served both "OF THE PROJECT GUTENBERG EBOOK" and
    /// "OF THIS PROJECT GUTENBERG EBOOK" over the years, so both are
    /// matched. Missing the end marker appends eighteen kilobytes of
    /// licence to the last chapter.
    private static func stripGutenbergEnvelope(from text: String) -> String {
        var body = text
        if let start = body.range(
            of: #"\*\*\* START OF TH(E|IS) PROJECT GUTENBERG EBOOK"#,
            options: .regularExpression
           ),
           let lineEnd = body.range(of: "\n", range: start.upperBound..<body.endIndex) {
            body = String(body[lineEnd.upperBound...])
        }
        if let end = body.range(
            of: #"\*\*\* END OF TH(E|IS) PROJECT GUTENBERG EBOOK"#,
            options: .regularExpression
           ) {
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

    /// "THE FIRST BOOK" → "The First Book"; "PAULINE ENTERS THE CARMEL"
    /// → "Pauline Enters the Carmel". Roman numerals stand as printed,
    /// and the small words a title-setter leaves lowercase are left
    /// lowercase — unless they open or close the line, where even an
    /// article is capitalized ("A Victim of Divine Love").
    private static func titleCased(_ line: String) -> String {
        let words = line.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return line }

        return words.enumerated().map { index, word -> String in
            if word.range(of: #"^[IVXLC]+\.?,?$"#, options: .regularExpression) != nil {
                return word
            }
            let cased = word.localizedCapitalized
            guard index > 0, index < words.count - 1 else { return cased }

            let bare = cased
                .trimmingCharacters(in: CharacterSet.letters.inverted)
                .lowercased()
            return smallWords.contains(bare) ? cased.lowercased() : cased
        }.joined(separator: " ")
    }

    /// The words a printer sets lowercase inside a title. Conjunctions,
    /// articles, and the short prepositions — nothing longer, so
    /// "Through" and "Against" keep their capitals.
    private static let smallWords: Set<String> = [
        "a", "an", "and", "as", "at", "but", "by", "for", "from", "in",
        "into", "nor", "of", "on", "or", "over", "the", "to", "unto",
        "upon", "with"
    ]

    // MARK: - Footnotes

    /// Separates the editor's apparatus from the author's text.
    ///
    /// A paragraph that opens with this edition's footnote marker is a
    /// note; the rest is the book. Notes keep their printed order, and a
    /// paragraph carrying several notes at once — Benham sets a whole
    /// chapter's citations on one line — is split at each marker.
    private static func split(
        paragraphs: [String],
        notePattern: String?
    ) -> (prose: [String], notes: [String]) {
        guard let notePattern,
              let marker = try? NSRegularExpression(pattern: notePattern),
              let opening = try? NSRegularExpression(pattern: "^(?:\(notePattern))")
        else { return (paragraphs, []) }

        var prose: [String] = []
        var notes: [String] = []

        for paragraph in paragraphs {
            guard matches(opening, paragraph) else {
                prose.append(paragraph)
                continue
            }
            notes.append(contentsOf: divide(paragraph, at: marker))
        }
        return (prose, notes)
    }

    /// Cuts one paragraph at every footnote marker it carries.
    ///
    /// Not at every *match*: Taylor gives the Psalms in both numberings,
    /// so "Ps. 88[89]:1" carries a bracketed number that is no footnote
    /// at all. A real marker opens the paragraph or follows a space, and
    /// its number is the one after the last — footnotes run 1, 2, 3.
    /// Both tests together leave the alternative verse numbers alone.
    private static func divide(_ paragraph: String, at marker: NSRegularExpression) -> [String] {
        let range = NSRange(paragraph.startIndex..., in: paragraph)
        let found = marker.matches(in: paragraph, range: range)
            .compactMap { match -> (start: String.Index, number: Int)? in
                guard let bounds = Range(match.range, in: paragraph) else { return nil }
                let digits = paragraph[bounds].filter(\.isNumber)
                guard let number = Int(digits) else { return nil }
                return (bounds.lowerBound, number)
            }
        guard let opening = found.first, opening.start == paragraph.startIndex else {
            return [paragraph]
        }

        var starts: [String.Index] = [opening.start]
        var expected = opening.number + 1
        for candidate in found.dropFirst() {
            guard candidate.number == expected else { continue }
            let before = paragraph.index(before: candidate.start)
            guard paragraph[before] == " " else { continue }
            starts.append(candidate.start)
            expected += 1
        }
        guard starts.count > 1 else { return [paragraph] }

        var pieces: [String] = []
        for (index, start) in starts.enumerated() {
            let end = index + 1 < starts.count ? starts[index + 1] : paragraph.endIndex
            let piece = String(paragraph[start..<end])
                .trimmingCharacters(in: .whitespaces)
            if !piece.isEmpty { pieces.append(piece) }
        }
        return pieces
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
