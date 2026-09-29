//
//  LearnByHeartSheet.swift
//  Lumen Viae
//
//  A prayer learned the way a child learns it at a mother's knee — said
//  over with fewer and fewer of its words in sight. Four steps: the
//  whole prayer; some words hidden; only first letters; nothing but the
//  shape of the lines. A hidden word shows itself when touched, so no
//  step can be failed, only gone back over. At the last the reader may
//  mark the prayer as theirs by heart; nothing is scored, and nothing
//  counts the prayers not yet learned.
//
//  In English, or in Latin where the prayer has it — the language a
//  prayer is learned in is the one it will be said in for life.
//

import SwiftUI

struct LearnByHeartSheet: View {

    let prayer: BookPrayer

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings

    private var store = PrayerBookStore.shared

    @State private var stage: Stage = .read
    @State private var inLatin: Bool
    @State private var revealed: Set<String> = []
    @State private var sealed = false

    init(prayer: BookPrayer) {
        self.prayer = prayer
        _inLatin = State(initialValue: prayer.hasLatin && UserSettings.shared.prayerLanguage == .latin)
    }

    enum Stage: Int, CaseIterable, Identifiable {
        case read, someHidden, firstLetters, byHeart

        var id: Int { rawValue }

        var label: String {
            switch self {
            case .read:         return "Read"
            case .someHidden:   return "Some hidden"
            case .firstLetters: return "First letters"
            case .byHeart:      return "By heart"
            }
        }

        var instruction: String {
            switch self {
            case .read:
                return "Read it through slowly, aloud if you can, two or three times."
            case .someHidden:
                return "Say it again. Where a word is missing, say it from memory — touch it if it will not come."
            case .firstLetters:
                return "Only the first letter of each word is left. Say the prayer from them."
            case .byHeart:
                return "Now the lines alone. Say it all; touch any word you need."
            }
        }
    }

    private var lines: [[String]] {
        PrayerWords.stanzas(of: inLatin ? (prayer.latin ?? prayer.english) : prayer.english)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(kicker: "Learn by heart", title: prayer.title, lead: stage.instruction) {
                SheetHeaderAction(title: "Done") { dismiss() }
            }
            .animation(Motion.crossfade, value: stage)

            stages
                .padding(.horizontal, SheetMetrics.gutter)

            if prayer.hasLatin {
                HStack {
                    LanguageChips(language: Binding(
                        get: { inLatin ? .latin : .english },
                        set: { language in
                            inLatin = language == .latin
                            revealed = []
                        }
                    ), showsBoth: false)
                    .fixedSize()
                    Spacer()
                }
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.top, 10)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { s, stanza in
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(stanza.enumerated()), id: \.offset) { l, line in
                                let whole = !hidesAny(line, keyPrefix: "\(s).\(l)")
                                WordFlow(spacing: 6, lineSpacing: 8) {
                                    ForEach(Array(words(line).enumerated()), id: \.offset) { w, word in
                                        wordView(word, key: "\(s).\(l).\(w)", position: w)
                                    }
                                }
                                // A line with nothing hidden is read as a
                                // line; word by word, VoiceOver made the
                                // reader step through every word of it
                                .accessibilityElement(children: whole ? .ignore : .contain)
                                .accessibilityLabel(whole ? line : "")
                            }
                        }
                    }
                }
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.top, 22)
                .padding(.bottom, 40)
                .animation(Motion.crossfade, value: stage)
                .animation(Motion.crossfade, value: inLatin)
            }

            foot
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.bottom, 18)
        }
        .sheetGround()
        .sensoryFeedback(.success, trigger: sealed)
    }

    // MARK: - Stages

    private var stages: some View {
        HStack(spacing: 6) {
            ForEach(Stage.allCases) { step in
                let on = step == stage
                let past = step.rawValue < stage.rawValue
                Button {
                    withAnimation(Motion.settle) {
                        stage = step
                        revealed = []
                    }
                } label: {
                    VStack(spacing: 6) {
                        Capsule()
                            .fill(on || past ? AppColors.gold.opacity(on ? 1 : 0.55) : AppColors.gold.opacity(0.15))
                            .frame(height: 3)
                        Text(step.label.uppercased())
                            .font(AppFonts.labelFont(7.5))
                            .tracking(1.2)
                            .foregroundColor(on ? AppColors.goldLight : AppColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Step \(step.rawValue + 1), \(step.label)")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: stage)
    }

    // MARK: - Words

    private func words(_ line: String) -> [String] {
        line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    /// Which words step two hides: every third, and never a word of one
    /// or two letters, which gives nothing to remember
    private func hides(_ word: String, position: Int) -> Bool {
        switch stage {
        case .read: return false
        case .someHidden: return position % 3 == 1 && letters(word).count > 2
        case .firstLetters, .byHeart: return true
        }
    }

    private func letters(_ word: String) -> String {
        word.filter { $0.isLetter }
    }

    /// Whether any word of the line is still hidden
    private func hidesAny(_ line: String, keyPrefix: String) -> Bool {
        words(line).enumerated().contains { w, word in
            hides(word, position: w) && !revealed.contains("\(keyPrefix).\(w)")
        }
    }

    @ViewBuilder
    private func wordView(_ word: String, key: String, position: Int) -> some View {
        let hidden = hides(word, position: position) && !revealed.contains(key)
        let size = max(17, settings.meditationFontSize - 1)

        if hidden {
            Button {
                withAnimation(Motion.crossfade) { _ = revealed.insert(key) }
            } label: {
                ZStack(alignment: .bottomLeading) {
                    Text(word)
                        .font(AppFonts.readingFont(size))
                        .opacity(0)
                    if stage == .firstLetters, let first = letters(word).first {
                        Text(String(first))
                            .font(AppFonts.readingFont(size))
                            .foregroundColor(AppColors.cream)
                    }
                    Capsule()
                        .fill(AppColors.gold.opacity(0.45))
                        .frame(height: 1.5)
                        .offset(y: 1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(stage == .firstLetters ? "Hidden word beginning \(letters(word).prefix(1))" : "Hidden word")
            .accessibilityHint("Shows the word")
        } else {
            Text(word)
                .font(AppFonts.readingFont(size))
                .foregroundColor(revealed.contains(key) ? AppColors.goldLight : AppColors.cream)
        }
    }

    // MARK: - Foot

    @ViewBuilder
    private var foot: some View {
        if stage == .byHeart {
            if store.isByHeart(prayer.id) || sealed {
                VStack(spacing: 4) {
                    ByHeartMark()
                        .scaleEffect(1.3)
                        .padding(.vertical, 12)
                    if !sealed {
                        QuietGoldButton(title: "Take the mark away") {
                            store.setByHeart(prayer.id, false)
                        }
                    }
                }
            } else {
                GoldCTAButton(title: "I know it by heart", trailingIcon: "ph-check") {
                    store.setByHeart(prayer.id, true)
                    sealed = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1.2))
                        dismiss()
                    }
                }
            }
        } else if let next = Stage(rawValue: stage.rawValue + 1) {
            QuietGoldButton(title: "Next · \(next.label)", trailingIcon: "ph-caret-right") {
                withAnimation(Motion.settle) {
                    stage = next
                    revealed = []
                }
            }
        }
    }
}

// MARK: - WordFlow

/// Words laid out as running text wraps them, each a view of its own so
/// a hidden one can take a touch
nonisolated struct WordFlow: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: proposal.width ?? widest, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += lineHeight + lineSpacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
