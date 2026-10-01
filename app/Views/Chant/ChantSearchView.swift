//
//  ChantSearchView.swift
//  Lumen Viae
//
//  Search across the Chant Library: a chant's titles in Latin and in
//  English, the words it sings, and the prayer it is a sung form of —
//  accents and case aside, so "caeli" finds Cæli. Titles come back as one
//  result for each work, its settings a pill (the simple and the solemn
//  Salve Regina), grouped by whether it is in season now; the words come
//  back as the line they stand in, with the place in the recording when
//  the chant's lines have been timed, and none when they have not.
//
//  It stands in the library's place while it is open, its field at the
//  head and Cancel beside it.
//

import SwiftUI

struct ChantSearchView: View {

    let close: () -> Void
    let open: (Chant) -> Void

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    enum Scope: String, CaseIterable, Identifiable {
        case all, titles, words, prayers
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all:     return "All"
            case .titles:  return "Titles"
            case .words:   return "Words"
            case .prayers: return "Prayers"
            }
        }
    }

    @State private var query = ""
    @State private var scope: Scope = .all
    @State private var inSeason = false
    @State private var short = false
    @State private var stillToLearn = false
    @State private var form: ChantForm?
    @State private var chosenSettings: [String: String] = [:]
    @State private var showsAllWords = false
    @FocusState private var focused: Bool

    init(close: @escaping () -> Void, open: @escaping (Chant) -> Void) {
        self.close = close
        self.open = open
    }

    private var needle: String { ChantSearch.fold(query.trimmingCharacters(in: .whitespaces)) }

    var body: some View {
        VStack(spacing: 0) {
            field
                .padding(.horizontal, 12)
                .padding(.top, 4)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 12) {
                        scopes
                        filters
                    }
                    .padding(.top, 14)

                    results
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, player.isActive ? 112 : 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear { focused = true }
        .onChange(of: query) { _, _ in showsAllWords = false }
    }

    // MARK: - Field

    private var field: some View {
        HStack(spacing: 8) {
            HStack(spacing: 10) {
                AppIcon("ph-magnifying-glass", size: 17)
                    .foregroundColor(AppColors.gold)
                TextField("", text: $query, prompt: Text("Search the Chant Library").foregroundColor(AppColors.textSecondary))
                    .font(AppFonts.bodyFont(17))
                    .foregroundColor(AppColors.cream)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .focused($focused)
                    .accessibilityLabel("Search the Chant Library")
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        AppIcon("ph-x", size: 13)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 36, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Clear")
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 4)
            .frame(height: 46)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: AppLine.hairline)
            )

            Button {
                focused = false
                close()
            } label: {
                Text("Cancel")
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.gold)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
        }
    }

    // MARK: - Scopes and filters

    private var scopes: some View {
        HStack(spacing: 22) {
            ForEach(Scope.allCases) { each in
                let lit = each == scope
                Button {
                    scope = each
                } label: {
                    Text(each.title.uppercased())
                        .font(AppFonts.labelFont(9.5))
                        .tracking(1.5)
                        .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                        .frame(minHeight: 40)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(AppColors.gold)
                                .frame(height: 1)
                                .opacity(lit ? 1 : 0)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityAddTraits(lit ? [.isSelected] : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.18) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search in")
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Picker("Type", selection: $form) {
                        Text("Every type").tag(ChantForm?.none)
                        ForEach(ChantForm.allCases) { each in
                            Text(each.title).tag(ChantForm?.some(each))
                        }
                    }
                } label: {
                    AppIcon("ph-funnel", size: 15)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Type of chant")

                if let form {
                    chip(form.title, isOn: true) { self.form = nil }
                }
                chip("In season", isOn: inSeason) { inSeason.toggle() }
                chip("Under 3 min", isOn: short) { short.toggle() }
                chip("Still to learn", isOn: stillToLearn) { stillToLearn.toggle() }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.readingFont(14))
                .foregroundColor(isOn ? AppColors.goldLight : AppColors.cream.opacity(0.75))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 13)
                .frame(height: 34)
                .background(Capsule().fill(isOn ? AppColors.gold.opacity(0.16) : Color.clear))
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(isOn ? 0.6 : 0.25), lineWidth: AppLine.hairline))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
        .sensoryFeedback(.selection, trigger: isOn)
    }

    // MARK: - Results

    private var filtering: Bool { inSeason || short || stillToLearn || form != nil }

    private func passes(_ chant: Chant) -> Bool {
        if form != nil, chant.form != form { return false }
        if short, chant.duration >= 180 { return false }
        if stillToLearn, shelf.isLearned(chant.id) { return false }
        if inSeason, !chant.seasons.contains(ChantSeason.season(on: Date())) { return false }
        return true
    }

    @ViewBuilder
    private var results: some View {
        if needle.isEmpty && !filtering {
            hint
        } else {
            let titleWorks = (scope == .all || scope == .titles) ? ChantSearch.works(matching: needle, where: passes) : []
            let prayerWorks = (scope == .all || scope == .prayers) ? ChantSearch.works(singingPrayerMatching: needle, where: passes)
                .filter { work in !titleWorks.contains { $0.key == work.key } } : []
            let wordHits = (scope == .all || scope == .words) && !needle.isEmpty
                ? ChantSearch.wordHits(matching: needle, where: passes) : []

            if titleWorks.isEmpty && prayerWorks.isEmpty && wordHits.isEmpty {
                Text(needle.isEmpty ? "No chant fits every filter chosen." : "Nothing in the library matches “\(query)”.")
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 8)
                accentNote
            } else {
                VStack(alignment: .leading, spacing: 28) {
                    let season = ChantSeason.season(on: Date())
                    let now = titleWorks.filter { $0.chants[0].seasons.contains(season) }
                    let always = titleWorks.filter { $0.chants[0].seasons.isEmpty }
                    let other = titleWorks.filter { !$0.chants[0].seasons.isEmpty && !$0.chants[0].seasons.contains(season) }

                    if !now.isEmpty { workGroup("In season now", now) }
                    if !always.isEmpty { workGroup(now.isEmpty && other.isEmpty ? "Chants" : "Any time of year", always) }
                    if !other.isEmpty { workGroup("Other times of year", other) }
                    if !prayerWorks.isEmpty { workGroup("Sung prayers", prayerWorks) }
                    if !wordHits.isEmpty { wordGroup(wordHits) }

                    accentNote
                }
            }
        }
    }

    private var hint: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Search a chant's name in Latin or in English, the words it sings, or the prayer it is a sung form of.")
                .font(AppFonts.readingItalicFont(15.5))
                .foregroundColor(AppColors.cream.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
            accentNote
        }
        .padding(.top, 8)
    }

    private var accentNote: some View {
        Text("No need to type accents: caeli finds Cæli.")
            .font(AppFonts.readingItalicFont(13.5))
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.top, 6)
    }

    private func groupHeading(_ title: String, count: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            Text(count)
                .font(AppFonts.readingItalicFont(13))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) { ChantRule() }
    }

    // MARK: - Works

    private func workGroup(_ title: String, _ works: [ChantSearch.Work]) -> some View {
        let versions = works.reduce(0) { $0 + $1.chants.count }
        let count = works.count == 1 ? "1 chant" : "\(works.count) chants"
        return VStack(alignment: .leading, spacing: 0) {
            groupHeading(title, count: versions > works.count ? "\(count), \(versions) settings" : count)
            ForEach(works, id: \.key) { work in
                workRow(work)
            }
        }
    }

    private func workRow(_ work: ChantSearch.Work) -> some View {
        let chosen = work.chants.first { $0.id == chosenSettings[work.key] } ?? work.chants[0]
        let when = chosen.seasonLine()

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ChantPlayDisc(
                    isPlaying: player.isPlaying(chosen),
                    isLoading: player.current.id == chosen.id && player.isLoading,
                    size: 34,
                    label: chosen.latinTitle
                ) {
                    player.toggle(chosen)
                }

                Button {
                    open(chosen)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ChantSearch.highlighted(chosen.latinTitle, needle: needle))
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(player.isPlaying(chosen) ? AppColors.goldLight : AppColors.cream)
                        Text(ChantSearch.highlighted(
                            [chosen.englishTitle, work.chants.count == 1 ? chosen.distinctSetting?.lowercased() : nil, when]
                                .compactMap { $0 }
                                .joined(separator: " · "),
                            needle: needle
                        ))
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens the chant")
            }

            if work.chants.count > 1 {
                ChantSettingPill(settings: work.chants, selected: chosen.id) { setting in
                    let wasSounding = player.isPlaying(chosen)
                    chosenSettings[work.key] = setting.id
                    if wasSounding { player.play(setting) }
                }
                .padding(.leading, 46)
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
        .chantContextMenu(chosen)
    }

    // MARK: - Words

    private func wordGroup(_ hits: [ChantSearch.WordHit]) -> some View {
        let shown = showsAllWords ? hits : Array(hits.prefix(3))
        let chants = Set(hits.map(\.chant.id)).count
        let count = "\(hits.count == 1 ? "1 match" : "\(hits.count) matches") in \(chants == 1 ? "1 chant" : "\(chants) chants")"
        return VStack(alignment: .leading, spacing: 0) {
            groupHeading("In the words", count: count)
            ForEach(shown) { hit in
                wordRow(hit)
            }
            if !showsAllWords, hits.count > 3 {
                Button {
                    withAnimation(Motion.crossfade) { showsAllWords = true }
                } label: {
                    Text("Show all \(hits.count)")
                        .font(AppFonts.readingFont(15))
                        .foregroundColor(AppColors.gold)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
            }
        }
    }

    private func wordRow(_ hit: ChantSearch.WordHit) -> some View {
        Button {
            if let line = hit.line {
                player.playLine(line, of: hit.chant, then: .goOn)
            }
            open(hit.chant)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(hit.chant.latinTitle)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                    Spacer(minLength: 8)
                    if let start = hit.start {
                        Text("AT \(ChantPlayer.clock(start))")
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1)
                            .foregroundColor(AppColors.textSecondary)
                            .monospacedDigit()
                    }
                }
                Text(ChantSearch.highlighted(hit.snippet, needle: needle))
                    .font(AppFonts.readingFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.82))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(AppColors.gold.opacity(0.3))
                            .frame(width: 1)
                    }
                Text(hit.chant.englishTitle)
                    .font(AppFonts.readingItalicFont(13))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
        .accessibilityElement(children: .combine)
        .accessibilityHint(hit.line != nil ? "Sings from this line" : "Opens the chant")
    }
}

// MARK: - ChantSearch

/// The library's search, apart from its page so it can be tested: the
/// folding, the grouping into works, the hits in the words, and the
/// highlighting.
enum ChantSearch {

    /// The chants of one work, its settings in the catalog's order
    struct Work {
        let key: String
        let chants: [Chant]
    }

    /// A match in a chant's words: the line it stands in, and where that
    /// line sounds when the chant's lines are timed
    struct WordHit: Identifiable {
        let id: String
        let chant: Chant
        let snippet: String
        /// The line's index in `Chant.lines`, for a timed chant
        let line: Int?
        let start: TimeInterval?
    }

    /// Case, accents and the ligatures aside: "Cæli" and "caeli" fold alike
    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "œ", with: "oe")
    }

    private static func group(_ chants: [Chant]) -> [Work] {
        var order: [String] = []
        var byKey: [String: [Chant]] = [:]
        for chant in chants {
            if byKey[chant.workKey] == nil { order.append(chant.workKey) }
            byKey[chant.workKey, default: []].append(chant)
        }
        return order.map { Work(key: $0, chants: byKey[$0] ?? []) }
    }

    /// Works whose Latin or English title holds `needle`, or every work
    /// when it is empty, the chants the filter passes
    static func works(matching needle: String, where passes: (Chant) -> Bool) -> [Work] {
        let chants = ChantCatalog.all.filter { chant in
            guard passes(chant) else { return false }
            guard !needle.isEmpty else { return true }
            return fold(chant.latinTitle).contains(needle) || fold(chant.englishTitle).contains(needle)
        }
        return group(chants)
    }

    /// Works that sing a prayer whose name, in the Prayer Book, holds
    /// `needle`: "glory be" finds the Gloria Patri
    static func works(singingPrayerMatching needle: String, where passes: (Chant) -> Bool) -> [Work] {
        guard !needle.isEmpty else { return [] }
        let chants = ChantCatalog.all.filter { chant in
            guard passes(chant), let prayer = chant.bookPrayer else { return false }
            return fold(prayer.title).contains(needle) || fold(prayer.latinTitle ?? "").contains(needle)
        }
        return group(chants)
    }

    /// Every line of every chant's words holding `needle`: a timed
    /// chant's own lines, with their place; else the lines of the Prayer
    /// Book's text, with none
    static func wordHits(matching needle: String, where passes: (Chant) -> Bool) -> [WordHit] {
        guard needle.count >= 3 else { return [] }
        var hits: [WordHit] = []
        var seenTexts = Set<String>()
        for chant in ChantCatalog.all where passes(chant) {
            if chant.hasLines {
                for (index, line) in chant.lines.enumerated() {
                    let latin = fold(line.latin).contains(needle)
                    let english = fold(line.english).contains(needle)
                    guard latin || english else { continue }
                    hits.append(WordHit(
                        id: "\(chant.id)#\(index)",
                        chant: chant,
                        snippet: latin ? line.latin : line.english,
                        line: index,
                        start: line.start
                    ))
                }
            } else if let prayer = chant.bookPrayer {
                // A prayer sung in two settings is quoted once, under the
                // first, rather than twice in the same words
                guard !seenTexts.contains(prayer.id) else { continue }
                let lines = ((prayer.latin ?? "") + "\n" + prayer.english).components(separatedBy: "\n")
                var found = false
                for (index, raw) in lines.enumerated() {
                    let text = clean(raw)
                    guard !text.isEmpty, fold(text).contains(needle) else { continue }
                    hits.append(WordHit(id: "\(chant.id)~\(index)", chant: chant, snippet: text, line: nil, start: nil))
                    found = true
                }
                if found { seenTexts.insert(prayer.id) }
            }
        }
        return hits
    }

    /// A line of the Prayer Book's grammar as plain words: the marks of
    /// versicle and response, the pointing and a rubric's brackets gone
    static func clean(_ line: String) -> String {
        var text = line
        for mark in ["℣.", "℟.", "℣", "℟", "✠", "|||"] {
            text = text.replacingOccurrences(of: mark, with: " ")
        }
        text = text.replacingOccurrences(of: " * ", with: " ")
        if text.hasPrefix("["), text.hasSuffix("]") { return "" }
        return text
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// `text` with every match of the folded `needle` underlined in gold
    static func highlighted(_ text: String, needle: String) -> AttributedString {
        guard !needle.isEmpty else { return AttributedString(text) }

        // Each folded character remembers the character it came from, so
        // a match on "caeli" can be drawn under "Cæli"
        var folded: [Character] = []
        var origin: [String.Index] = []
        for index in text.indices {
            for character in fold(String(text[index])) {
                folded.append(character)
                origin.append(index)
            }
        }
        let pattern = Array(needle)
        guard !pattern.isEmpty, folded.count >= pattern.count else { return AttributedString(text) }

        var ranges: [Range<String.Index>] = []
        var i = 0
        while i <= folded.count - pattern.count {
            if Array(folded[i..<(i + pattern.count)]) == pattern {
                let lower = origin[i]
                let upper = text.index(after: origin[i + pattern.count - 1])
                ranges.append(lower..<upper)
                i += pattern.count
            } else {
                i += 1
            }
        }

        var result = AttributedString()
        var cursor = text.startIndex
        for range in ranges where range.lowerBound >= cursor {
            result += AttributedString(String(text[cursor..<range.lowerBound]))
            var match = AttributedString(String(text[range]))
            // Typed, so the attributes are SwiftUI's and not UIKit's
            match.foregroundColor = AppColors.goldLight as Color
            match.underlineStyle = Text.LineStyle(pattern: .solid)
            result += match
            cursor = range.upperBound
        }
        result += AttributedString(String(text[cursor...]))
        return result
    }
}
