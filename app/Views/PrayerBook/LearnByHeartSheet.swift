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
//  Laid out as a holy card (the "Learn by Heart" redesign, Option A,
//  Oct 2026): the prayer's painting dissolving into the page, its name,
//  the prayer set centred, and at the foot four beads for the four
//  steps with one way on and one way back. The sheet once opened on a
//  sentence of instructions, a bar of four 7.5-point labels and the
//  language chips, three rows of chrome before the first word.
//

import SwiftUI

struct LearnByHeartSheet: View {

    let prayer: BookPrayer

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings

    private let store: PrayerBookStore

    @State private var stage: Stage = .read
    @State private var inLatin: Bool
    @State private var revealed: Set<String> = []
    @State private var sealed = false
    /// Whether the painting has scrolled up under the top bar, which then
    /// takes a ground of its own so the words pass beneath it unseen
    @State private var paintingGone = false

    /// Opens on the first step; a later one, and a store of its own, only
    /// for the snapshot tests, which draw each step without walking to it
    /// and never touch the reader's own Learned marks
    init(prayer: BookPrayer, stage: Stage = .read, store: PrayerBookStore = .shared) {
        self.prayer = prayer
        self.store = store
        _stage = State(initialValue: stage)
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

        /// The one line a step needs, where it needs one: reading needs
        /// no telling, and by the last step the reader knows the way
        var hint: String? {
            switch self {
            case .someHidden:   return "Touch a word to see it."
            case .firstLetters: return "Say it from the first letters."
            case .read, .byHeart: return nil
            }
        }
    }

    /// The painting's height at the head, short enough that a long prayer
    /// (the Creed, the Anima Christi) still has the sheet
    private static let paintingHeight: CGFloat = 196

    private var lines: [[String]] {
        PrayerWords.stanzas(of: inLatin ? (prayer.latin ?? prayer.english) : prayer.english)
    }

    private var isLearned: Bool { sealed || store.isByHeart(prayer.id) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    painting

                    VStack(spacing: 6) {
                        Text("LEARN BY HEART")
                            .font(AppFonts.labelFont(9.5))
                            .tracking(2.5)
                            .foregroundColor(AppColors.gold)
                        Text(prayer.title)
                            .font(AppFonts.titleFont(25))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, -14)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)

                    words
                        .padding(.horizontal, 26)
                        .padding(.top, 28)
                        .padding(.bottom, 28)
                }
                .onGeometryChange(for: Bool.self) { proxy in
                    proxy.frame(in: .scrollView).minY < -(Self.paintingHeight - 90)
                } action: { gone in
                    paintingGone = gone
                }
            }
            // The words dissolve into the foot rather than being cut
            .mask(
                VStack(spacing: 0) {
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 22)
                }
            )
            .overlay(alignment: .top) {
                ZStack(alignment: .top) {
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.backgroundDeep, location: 0),
                            .init(color: AppColors.backgroundDeep, location: 0.65),
                            .init(color: AppColors.backgroundDeep.opacity(0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 86)
                    .opacity(paintingGone ? 1 : 0)
                    .animation(Motion.crossfade, value: paintingGone)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                    topBar
                }
            }

            foot
                .padding(.horizontal, 22)
                .padding(.top, 6)
                .padding(.bottom, 14)
        }
        .sheetGround()
        .sensoryFeedback(.success, trigger: sealed)
        .sensoryFeedback(.selection, trigger: stage)
    }

    // MARK: - Head

    /// The prayer's own painting, dissolving into the page. It brightens a
    /// little once the prayer is learned, its veil lifted.
    private var painting: some View {
        let painting = PrayerBookPainting.prayer(prayer.id)
        return CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
            .overlay(AppColors.background.opacity(isLearned ? 0 : 0.22))
            .frame(maxWidth: .infinity)
            .frame(height: Self.paintingHeight)
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.5),
                        .init(color: .black.opacity(0.35), location: 0.8),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .animation(.easeInOut(duration: 0.8), value: isLearned)
            .accessibilityHidden(true)
    }

    /// The language, where the prayer has Latin, and DONE: each on a dark
    /// capsule, so they read over any painting and over the words beneath
    private var topBar: some View {
        HStack {
            if prayer.hasLatin {
                Button {
                    withAnimation(Motion.crossfade) {
                        inLatin.toggle()
                        revealed = []
                    }
                } label: {
                    HStack(spacing: 7) {
                        Text("EN").foregroundColor(inLatin ? AppColors.cream.opacity(0.8) : AppColors.gold)
                        Text("·").foregroundColor(AppColors.cream.opacity(0.5))
                        Text("LA").foregroundColor(inLatin ? AppColors.gold : AppColors.cream.opacity(0.8))
                    }
                    .font(AppFonts.labelFont(10))
                    .tracking(1.8)
                    .modifier(BarCapsule())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel(inLatin ? "Learning in Latin" : "Learning in English")
                .accessibilityHint(inLatin ? "Switches to English" : "Switches to Latin")
            }

            Spacer()

            Button { dismiss() } label: {
                Text("DONE")
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.goldLight)
                    .modifier(BarCapsule())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .accessibilityLabel("Done")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    // MARK: - The Words

    private var words: some View {
        VStack(spacing: 22) {
            ForEach(Array(lines.enumerated()), id: \.offset) { s, stanza in
                VStack(spacing: 10) {
                    ForEach(Array(stanza.enumerated()), id: \.offset) { l, line in
                        let whole = !hidesAny(line, keyPrefix: "\(s).\(l)")
                        WordFlow(spacing: 6, lineSpacing: 8, centred: true) {
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
        .frame(maxWidth: .infinity)
        .animation(Motion.crossfade, value: stage)
        .animation(Motion.crossfade, value: inLatin)
    }

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

    // MARK: - The Foot

    private func go(to step: Stage) {
        withAnimation(Motion.settle) {
            stage = step
            revealed = []
        }
    }

    /// The four beads and the step's name, then the way on — or, at the
    /// last step, the reader's own mark that they know it
    private var foot: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                beads
                Text(stage.label.uppercased())
                    .font(AppFonts.labelFont(10.5))
                    .tracking(2.2)
                    .foregroundColor(AppColors.goldLight)
                    .contentTransition(.opacity)
                    .accessibilityHidden(true)
                // The line keeps its room when a step has none, so the
                // foot never moves from step to step
                Text(stage.hint ?? " ")
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .opacity(stage.hint == nil ? 0 : 1)
                    .contentTransition(.opacity)
                    .padding(.top, 2)
                    .accessibilityHidden(stage.hint == nil)
            }
            .animation(Motion.crossfade, value: stage)

            acts
                .frame(minHeight: 58)
                .animation(Motion.crossfade, value: stage)
                .animation(Motion.crossfade, value: isLearned)
        }
    }

    private var beads: some View {
        HStack(spacing: 0) {
            ForEach(Stage.allCases) { step in
                Button { go(to: step) } label: {
                    StepBead(state: step == stage ? .current : (step.rawValue < stage.rawValue ? .past : .ahead))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Step \(step.rawValue + 1) of \(Stage.allCases.count), \(step.label)")
                .accessibilityAddTraits(step == stage ? .isSelected : [])
            }
        }
        // The thread the beads hang on, run from the first bead's centre to
        // the last's beneath them, so each bead keeps a 44-point target
        .background(
            Rectangle()
                .fill(AppColors.gold.opacity(0.4))
                .frame(height: AppLine.hairline)
                .padding(.horizontal, 22)
        )
        .animation(Motion.settle, value: stage)
    }

    @ViewBuilder
    private var acts: some View {
        if stage == .byHeart, isLearned {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    AppIcon("ph-seal-check-fill", size: 18)
                    Text("LEARNED")
                        .font(AppFonts.labelFont(12))
                        .tracking(2.6)
                }
                .foregroundColor(AppColors.gold)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Learned by heart")

                Text("Kept as yours. Practise it here any time.")
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                // Not offered in the moment of sealing, which closes the
                // sheet on its own
                if !sealed {
                    Button {
                        store.setByHeart(prayer.id, false)
                    } label: {
                        Text("UNMARK")
                            .font(AppFonts.labelFont(9.5))
                            .tracking(2)
                            .foregroundColor(AppColors.gold.opacity(0.65))
                            .frame(minWidth: 88, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Remove the Learned mark")
                }
            }
            .frame(maxWidth: .infinity)
            .transition(.opacity)
        } else if stage == .byHeart {
            HStack(spacing: 14) {
                StepDisc(direction: .back) { go(to: .firstLetters) }
                GoldCTAButton(title: "I know it by heart", trailingIcon: "ph-check") {
                    store.setByHeart(prayer.id, true)
                    sealed = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1.2))
                        dismiss()
                    }
                }
            }
            .transition(.opacity)
        } else {
            HStack {
                StepDisc(direction: .back) {
                    if let previous = Stage(rawValue: stage.rawValue - 1) { go(to: previous) }
                }
                // Kept in its place on the first step, so nothing shifts
                .opacity(stage == .read ? 0 : 1)
                .disabled(stage == .read)
                .accessibilityHidden(stage == .read)

                Spacer()

                if let next = Stage(rawValue: stage.rawValue + 1) {
                    Button { go(to: next) } label: {
                        HStack(spacing: 12) {
                            Text(next.label.uppercased())
                                .font(AppFonts.labelFont(10.5))
                                .tracking(2)
                                .foregroundColor(AppColors.gold)
                                .contentTransition(.opacity)
                            StepDiscFace(direction: .next)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SacredCardButtonStyle())
                    .accessibilityLabel("Next step, \(next.label)")
                }
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Pieces

/// DONE and the language sit on these: opaque, so neither the painting's
/// sky nor the words scrolled beneath can wash them out
private struct BarCapsule: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(Capsule().fill(AppColors.background))
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline))
            .shadow(color: .black.opacity(0.45), radius: 8, y: 2)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// One of the four beads: the step being said lit and a size larger, the
/// steps behind filled, the steps ahead an empty ring
private struct StepBead: View {
    enum Look { case past, current, ahead }
    let state: Look

    var body: some View {
        let size: CGFloat = state == .current ? 15 : 11
        Circle()
            .fill(fill)
            .overlay(Circle().strokeBorder(AppColors.gold.opacity(state == .ahead ? 0.55 : 0), lineWidth: 1.2))
            .frame(width: size, height: size)
            .haloGlow(AppColors.gold, radius: 8, intensity: state == .current ? 0.45 : 0)
    }

    private var fill: Color {
        switch state {
        case .current: return AppColors.gold
        case .past: return AppColors.gold.opacity(0.6)
        case .ahead: return AppColors.background
        }
    }
}

/// The way on and the way back: a ring with a caret, gold and lit for
/// the way on, quiet for the way back
private struct StepDiscFace: View {
    enum Direction { case back, next }
    let direction: Direction

    var body: some View {
        let next = direction == .next
        AppIcon(next ? "ph-caret-right" : "ph-caret-left", size: 15)
            .foregroundColor(AppColors.gold.opacity(next ? 1 : 0.7))
            .frame(width: 44, height: 44)
            .overlay(Circle().strokeBorder(AppColors.gold.opacity(next ? 1 : 0.35), lineWidth: 1.2))
            .haloGlow(AppColors.gold, radius: 10, intensity: next ? 0.22 : 0)
    }
}

private struct StepDisc: View {
    let direction: StepDiscFace.Direction
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            StepDiscFace(direction: direction)
                .contentShape(Circle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(direction == .back ? "Back a step" : "Next step")
    }
}

// MARK: - WordFlow

/// Words laid out as running text wraps them, each a view of its own so
/// a hidden one can take a touch; centred, each row stands in the middle
/// of the measure as a prayer card sets its lines
nonisolated struct WordFlow: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 8
    var centred = false

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = self.rows(subviews, width: width)
        let widest = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(subviews, width: bounds.width) {
            var x = bounds.minX + (centred ? (bounds.width - row.width) / 2 : 0)
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let needed = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if !row.indices.isEmpty, needed > width {
                rows.append(row)
                row = Row()
            }
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
        }
        if !row.indices.isEmpty { rows.append(row) }
        return rows
    }
}
