//
//  ChantPracticeView.swift
//  Lumen Viae
//
//  Learning a chant by heart — the "Learn · Practice" board. A chant is
//  learned in four steps, the learner's own to take:
//
//    1 Listen        hear the choir
//    2 Read along    follow the words as the choir sings them
//    3 Sing along    the choir sings, then you sing it back
//    4 On your own   you sing first, then the choir sings it to you
//
//  For a chant whose lines have been timed (`Chant.lines`), each step goes
//  a line at a time — the line sung, again if asked, three times if
//  asked, slower if asked, and the next when the learner says they have
//  it. For every other chant each step is the whole chant, with its words
//  from the Prayer Book; no timing is guessed.
//
//  Nothing is scored. The last step ends on the learner's own word that
//  they know it by heart, which is kept on their shelf.
//
//  Presented full screen over the library or a chant's page; it carries
//  its own ✕.
//

import SwiftUI

struct ChantPracticeView: View {

    let chant: Chant

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    @State private var step: ChantLearningStep = .listen
    @State private var line = 0
    @State private var repeatsWanted = 1
    @State private var timesSung = 0
    @State private var hidden: Hiding = .none
    @State private var learnedNow = false

    /// How much of the words is hidden, for singing from memory
    enum Hiding: CaseIterable {
        case none, half, all

        var title: String {
            switch self {
            case .none: return "None"
            case .half: return "Half"
            case .all:  return "All"
            }
        }

        var next: Hiding {
            switch self {
            case .none: return .half
            case .half: return .all
            case .all:  return .none
            }
        }
    }

    init(chant: Chant) {
        self.chant = chant
    }

    private var lines: Bool { chant.hasLines }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 8)

                if learnedNow {
                    learnedPage
                        .transition(.opacity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 26) {
                            stepBar
                                .padding(.horizontal, 24)
                                .padding(.top, 12)

                            score
                                .padding(.horizontal, 20)

                            // A slot of its own, so a line leaving and the
                            // next arriving crossfade over one another
                            ZStack(alignment: .top) {
                                words
                            }
                            .padding(.horizontal, 22)

                            status
                                .padding(.horizontal, 20)

                            options
                                .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 24)
                    }

                    foot
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
            }
        }
        .animation(Motion.crossfade, value: learnedNow)
        .onAppear {
            step = shelf.step(of: chant.id) ?? .listen
            if shelf.isLearned(chant.id) { step = .onYourOwn }
            hidden = step == .onYourOwn ? .half : .none
            begin()
        }
        .onDisappear {
            player.setLineEnd(.goOn)
        }
        .onChange(of: player.linesFinished) { _, _ in
            lineSung()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                AppIcon("ph-x", size: 18)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .accessibilityLabel("Close")

            Spacer()

            Text("Learning \(chant.latinTitle)")
                .font(AppFonts.readingFont(16))
                .foregroundColor(AppColors.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 6)
    }

    // MARK: - Steps

    private var stepBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("Step \(step.rawValue) of 4: ")
                        .foregroundColor(AppColors.cream)
                    Text(step.title)
                        .foregroundColor(AppColors.goldLight)
                }
                .font(AppFonts.readingFont(16))
                .accessibilityElement(children: .combine)
                Spacer(minLength: 8)
                if lines {
                    Text("Line \(line + 1) of \(chant.lines.count)")
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .contentTransition(.numericText())
                }
            }
            HStack(spacing: 4) {
                ForEach(ChantLearningStep.allCases) { each in
                    Button {
                        go(to: each)
                    } label: {
                        Capsule()
                            .fill(each.rawValue < step.rawValue ? AppColors.gold
                                  : each == step ? AppColors.goldLight
                                  : AppColors.textSecondary.opacity(0.35))
                            .frame(height: 3)
                            .shadow(color: each == step ? AppColors.gold.opacity(0.5) : .clear, radius: 5)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Step \(each.rawValue), \(each.title)")
                    .accessibilityAddTraits(each == step ? [.isSelected] : [])
                }
            }
            Text(step.note)
                .font(AppFonts.readingItalicFont(13.5))
                .foregroundColor(AppColors.textSecondary)
        }
        .animation(Motion.crossfade, value: step)
    }

    // MARK: - Score

    private var score: some View {
        let partIndex = lines ? (chant.lines[line].part ?? 0) : 0
        let part = chant.score.indices.contains(partIndex) ? chant.score[partIndex] : chant.score.first
        return ZStack {
            if let part {
                ChantScoreImage(part: part)
                    .id(part.file)
                    .transition(.opacity)
            }
        }
        .frame(height: lines ? 120 : 170, alignment: .top)
        .frame(maxWidth: .infinity)
        .clipped()
        .mask(
            LinearGradient(
                stops: [.init(color: .black, location: 0.7), .init(color: .clear, location: 1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .padding(12)
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline))
        .accessibilityLabel("The score")
    }

    // MARK: - Words

    @ViewBuilder
    private var words: some View {
        if lines {
            let current = chant.lines[line]
            VStack(spacing: 6) {
                if step != .listen {
                    Text(Self.hide(current.latin, hidden))
                        .font(AppFonts.readingFont(24))
                        .foregroundColor(isSounding ? AppColors.goldLight : AppColors.cream)
                        .lineSpacing(4)
                }
                Text(current.english)
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.72))
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .id(line)
            .transition(.opacity)
            .animation(Motion.words, value: line)
            .accessibilityElement(children: .combine)
        } else if let text = chant.words {
            VStack(spacing: 10) {
                if step != .listen, let latin = text.latin {
                    Text(Self.hide(Self.plain(latin), hidden))
                        .font(AppFonts.readingFont(19))
                        .foregroundColor(AppColors.cream)
                        .lineSpacing(4)
                }
                if let english = text.english, step == .listen || step == .readAlong || text.latin == nil {
                    Text(Self.plain(english))
                        .font(AppFonts.readingItalicFont(16))
                        .foregroundColor(AppColors.cream.opacity(0.72))
                        .lineSpacing(3)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("The words of this chant stand on its score.")
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private var isSounding: Bool {
        player.holds(chant) && player.isPlaying && player.lineIndex == line
    }

    // MARK: - Status

    @ViewBuilder
    private var status: some View {
        if let turn = player.turn, player.holds(chant) {
            ChantYourTurn(
                turn: turn,
                subtitle: step == .onYourOwn
                    ? "Sing the line from memory. The choir will answer."
                    : "The choir sang the line. Now sing it back."
            )
            .transition(.opacity)
        } else {
            HStack(spacing: 12) {
                ChantPlayDisc(
                    isPlaying: player.isPlaying(chant),
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 40,
                    label: chant.latinTitle
                ) {
                    if lines, !player.holds(chant) || !player.isPlaying {
                        singLine()
                    } else {
                        player.toggle(chant)
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(statusTitle)
                        .font(AppFonts.readingFont(16))
                        .foregroundColor(AppColors.cream)
                    Text(statusNote)
                        .font(AppFonts.readingItalicFont(12.5))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 56)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline))
            .transition(.opacity)
        }
    }

    private var statusTitle: String {
        if player.isPlaying(chant) { return "The choir is singing" }
        switch step {
        case .listen:    return "Listen to the choir"
        case .readAlong: return "Follow the words"
        case .singAlong: return "Sing with the choir"
        case .onYourOwn: return "Sing it on your own"
        }
    }

    private var statusNote: String {
        if lines {
            switch step {
            case .listen, .readAlong: return "Tap to hear the line."
            case .singAlong: return "The choir sings the line, then you sing it back."
            case .onYourOwn: return "You sing first, then the choir answers."
            }
        }
        switch step {
        case .listen:    return "Hear the whole chant, as many times as you like."
        case .readAlong: return "Follow the words as the choir sings them."
        case .singAlong: return "Sing with the choir, slower if it helps."
        case .onYourOwn: return "Sing from memory, then play it to check."
        }
    }

    // MARK: - Options

    private var options: some View {
        HStack(spacing: 8) {
            if lines {
                option(repeatsWanted == 1 ? "Once" : "3 times", label: "Repeat") {
                    repeatsWanted = repeatsWanted == 1 ? 3 : 1
                }
                .accessibilityLabel("Repeat each line: \(repeatsWanted == 1 ? "once" : "three times")")
            } else {
                option(player.repeats ? "On" : "Off", label: "Repeat") {
                    player.repeats.toggle()
                }
                .accessibilityLabel("Repeat the chant: \(player.repeats ? "on" : "off")")
            }
            option(player.rate < 1 ? "Slower" : "Normal", label: "Speed") {
                player.setRate(player.rate < 1 ? 1.0 : 0.75)
            }
            .accessibilityLabel("Speed: \(player.rate < 1 ? "slower" : "normal")")
            option(hidden.title, label: "Hide words") {
                hidden = hidden.next
            }
            .disabled(step == .listen)
            .accessibilityLabel("Hide the words: \(hidden.title)")
        }
    }

    private func option(_ value: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(value)
                    .font(AppFonts.readingFont(15))
                    .foregroundColor(AppColors.cream)
                    .contentTransition(.opacity)
                Text(label)
                    .font(AppFonts.readingItalicFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppColors.gold.opacity(0.25), lineWidth: AppLine.hairline))
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    // MARK: - Foot

    private var foot: some View {
        HStack(spacing: 10) {
            Button {
                again()
            } label: {
                HStack(spacing: 8) {
                    AppIcon(lines ? "ph-repeat-once" : "ph-arrow-counter-clockwise", size: 15)
                    Text("Again")
                        .font(AppFonts.readingFont(16))
                }
                .foregroundColor(AppColors.gold)
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AppColors.gold.opacity(0.5), lineWidth: AppLine.hairline))
                .contentShape(Rectangle())
            }
            .buttonStyle(SacredCardButtonStyle())
            .frame(maxWidth: 130)
            .accessibilityLabel(lines ? "Sing the line again" : "From the top")

            GoldCTAButton(
                title: forwardTitle,
                silhouette: .rounded(14),
                trailingIcon: isLastOfAll ? "ph-check" : nil
            ) {
                forward()
            }
        }
    }

    private var isLastLine: Bool { !lines || line == chant.lines.count - 1 }
    private var isLastOfAll: Bool { step == .onYourOwn && isLastLine }

    private var forwardTitle: String {
        if isLastOfAll { return "I know it by heart" }
        if lines, !isLastLine { return "Got it — next line" }
        return "Next step"
    }

    // MARK: - Learned

    private var learnedPage: some View {
        VStack(spacing: 18) {
            Spacer()
            AppIcon("ph-seal-check-fill", size: 44)
                .foregroundColor(AppColors.gold)
            Text(chant.latinTitle)
                .font(AppFonts.titleFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
            Text("Learned by heart. It is kept on your shelf, under Saved.")
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.78))
                .multilineTextAlignment(.center)
            Spacer()
            GoldCTAButton(title: "Done") {
                dismiss()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Acts

    /// Opens the step: a timed chant's line sung at once; a whole chant
    /// begun for listening and reading, and left for the learner to start
    /// when they sing it themselves
    private func begin() {
        timesSung = 0
        if lines {
            singLine()
        } else if step == .listen || step == .readAlong {
            if !player.isPlaying(chant) {
                if player.holds(chant) { player.restart() } else { player.play(chant) }
            }
        }
    }

    /// The line under the hand, as the step sings it
    private func singLine() {
        guard lines else { return }
        switch step {
        case .listen, .readAlong:
            player.playLine(line, of: chant, then: .stop)
        case .singAlong:
            player.playLine(line, of: chant, then: .yourTurnThenStop)
        case .onYourOwn:
            player.yourTurnFirst(line, of: chant)
        }
    }

    /// A line has been sung to its end: again, if the learner asked for it
    /// more than once
    private func lineSung() {
        guard lines, player.holds(chant) else { return }
        timesSung += 1
        if timesSung < repeatsWanted, step == .listen || step == .readAlong {
            singLine()
        }
    }

    private func again() {
        timesSung = 0
        if lines {
            singLine()
        } else {
            if player.holds(chant) { player.restart() } else { player.play(chant) }
        }
    }

    private func forward() {
        if isLastOfAll {
            player.setLineEnd(.goOn)
            shelf.markLearned(chant.id)
            withAnimation(reduceMotion ? nil : Motion.crossfade) { learnedNow = true }
            return
        }
        if lines, !isLastLine {
            line += 1
            timesSung = 0
            singLine()
            return
        }
        if let next = step.next {
            go(to: next)
        }
    }

    private func go(to next: ChantLearningStep) {
        step = next
        line = 0
        hidden = next == .onYourOwn ? .half : .none
        // A chant learned and practised again keeps its mark
        if !shelf.isLearned(chant.id) {
            shelf.setStep(next, for: chant.id)
        }
        if lines {
            begin()
        } else if next == .onYourOwn, player.isPlaying(chant) {
            // From memory: the choir rests until it is asked
            player.togglePlayback()
        } else {
            begin()
        }
    }

    // MARK: - Words, hidden

    /// The words with every other one, or every one, cut to its first
    /// letter — as the Prayer Book's learning by heart does
    static func hide(_ text: String, _ hiding: Hiding) -> String {
        guard hiding != .none else { return text }
        var index = 0
        return text.components(separatedBy: "\n").map { line in
            line.components(separatedBy: " ").map { word -> String in
                defer { index += 1 }
                guard word.count > 1, hiding == .all || index % 2 == 1 else { return word }
                let letters = word.filter(\.isLetter)
                guard let first = letters.first else { return word }
                let trailing = word.last.map { $0.isLetter ? "" : String($0) } ?? ""
                return String(first) + String(repeating: "·", count: max(1, letters.count - 1)) + trailing
            }
            .joined(separator: " ")
        }
        .joined(separator: "\n")
    }

    /// The Prayer Book's grammar as plain lines to sing from
    static func plain(_ text: String) -> String {
        text.components(separatedBy: "\n")
            .map(ChantSearch.clean)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
