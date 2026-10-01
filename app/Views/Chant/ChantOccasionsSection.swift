//
//  ChantOccasionsSection.swift
//  Lumen Viae
//
//  The Occasions board: chants in the order they are sung, for someone
//  who would follow along or lead a group — Benediction, a visit to the
//  Blessed Sacrament, a sung Rosary, before bed, before work, for the
//  dead. The occasions stand as a numbered index; the one chosen opens
//  beneath as an order of service, what happens between the chants in
//  red, each chant on a thread that lights as the set is sung.
//
//  A set can be sung straight through, or wait for a tap between chants
//  (Pause between chants), and can be kept as a set of the reader's own,
//  to change as they like.
//

import SwiftUI

struct ChantOccasionsSection: View {

    @Binding var openID: String?
    let open: (Chant) -> Void
    let madeSet: (ChantSet) -> Void

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    init(openID: Binding<String?>, open: @escaping (Chant) -> Void, madeSet: @escaping (ChantSet) -> Void) {
        _openID = openID
        self.open = open
        self.madeSet = madeSet
    }

    private var chosen: ChantOccasion {
        ChantLibraryData.occasions.first { $0.id == openID } ?? ChantLibraryData.occasions[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            index
                .padding(.horizontal, 12)

            // The order of service crossfades in a slot of its own: as a
            // re-identified block in this column, the leaving one and the
            // arriving one stood one above the other while they faded
            ZStack(alignment: .top) {
                order(chosen)
                    .id(chosen.id)
                    .transition(.opacity)
            }
            .padding(.horizontal, 20)

            makeYourOwn
                .padding(.horizontal, 20)
        }
        .animation(Motion.crossfade, value: chosen.id)
    }

    // MARK: - Index

    private var index: some View {
        VStack(spacing: 2) {
            ForEach(Array(ChantLibraryData.occasions.enumerated()), id: \.element.id) { number, occasion in
                indexRow(occasion, numeral: Self.numeral(number + 1), lit: occasion.id == chosen.id)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Occasions")
    }

    private func indexRow(_ occasion: ChantOccasion, numeral: String, lit: Bool) -> some View {
        let chants = occasion.distinctChants().count
        return Button {
            openID = occasion.id
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(numeral)
                    .font(AppFonts.titleFont(13))
                    .foregroundColor(Rubric.red)
                    .frame(width: 26, alignment: .center)

                VStack(alignment: .leading, spacing: 3) {
                    Text(occasion.title)
                        .font(AppFonts.titleFont(16))
                        .foregroundColor(lit ? AppColors.goldLight : AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(occasion.note)
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(Self.minutes(occasion.duration()).uppercased())
                        .font(AppFonts.labelFont(8.5))
                        .tracking(1)
                        .foregroundColor(AppColors.textSecondary)
                    Text(chants == 1 ? "1 chant" : "\(chants) chants")
                        .font(AppFonts.readingItalicFont(12.5))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.gold.opacity(lit ? 0.07 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(lit ? [.isSelected] : [])
    }

    // MARK: - The order of service

    private func order(_ occasion: ChantOccasion) -> some View {
        let queue = ChantQueue.occasion(occasion)
        let singing = player.isSinging(queue)
        let sungIndex = singing ? player.queue?.index : nil
        let positions = Self.positions(of: occasion)
        let count = occasion.distinctChants().count

        return VStack(alignment: .leading, spacing: 0) {
            ChantPainting(name: occasion.painting, height: 170, dissolveFrom: 0.25)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text((count == 1 ? "A set of 1 chant" : "Set of \(count) chants").uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                    Text(occasion.title)
                        .font(AppFonts.titleFont(24))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }

                Text("Sung in this order. The notes in red tell you what happens in between.")
                    .font(AppFonts.readingItalicFont(14.5))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(occasion.blocks.enumerated()), id: \.offset) { blockIndex, block in
                        VStack(alignment: .leading, spacing: 4) {
                            if let rubric = block.rubric {
                                ChantRubricText(text: rubric)
                                    .padding(.leading, 36)
                                    .padding(.top, 10)
                            }
                            ForEach(Array(block.steps.enumerated()), id: \.offset) { stepIndex, step in
                                if let chant = step.chant.resolve() {
                                    stepRow(
                                        chant,
                                        times: step.times,
                                        state: state(
                                            of: positions[blockIndex][stepIndex],
                                            sung: sungIndex
                                        ),
                                        isLast: blockIndex == occasion.blocks.count - 1 && stepIndex == block.steps.count - 1,
                                        playFrom: {
                                            player.play(queue, from: positions[blockIndex][stepIndex].first?.lowerBound ?? 0)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }

                ChantRule(opacity: 0.18)
                    .padding(.top, 4)

                pausesBetween

                HStack(spacing: 10) {
                    GoldCTAButton(title: "Play all \(count)", glyph: .play) {
                        player.play(queue)
                    }
                    Button {
                        madeSet(shelf.saveOccasion(occasion))
                    } label: {
                        AppIcon("ph-bookmark-simple", size: 18)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(SacredCardButtonStyle())
                    .accessibilityLabel("Keep as a set of your own")
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
            .padding(.top, -28)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
        )
    }

    private enum StepState { case done, sounding, ahead }

    /// A step sounding in any of its rounds is lit; one whose last round
    /// is behind the set is done
    private func state(of ranges: [Range<Int>], sung: Int?) -> StepState {
        guard let sung else { return .ahead }
        if ranges.contains(where: { $0.contains(sung) }) { return .sounding }
        if let last = ranges.last, last.upperBound <= sung { return .done }
        return .ahead
    }

    private func stepRow(
        _ chant: Chant,
        times: Int,
        state: StepState,
        isLast: Bool,
        playFrom: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: playFrom) {
                ZStack {
                    Circle()
                        .fill(state == .ahead ? AppColors.background : AppColors.gold.opacity(state == .done ? 0.3 : 0.95))
                    Circle()
                        .strokeBorder(AppColors.gold.opacity(state == .ahead ? 0.5 : 0.9), lineWidth: 1)
                    switch state {
                    case .done:
                        AppIcon("ph-check", size: 10).foregroundColor(AppColors.goldLight)
                    case .sounding:
                        AppIcon(player.isPlaying ? "ph-pause-fill" : "ph-play-fill", size: 9)
                            .foregroundColor(AppColors.background)
                    case .ahead:
                        EmptyView()
                    }
                }
                .frame(width: 22, height: 22)
                .shadow(color: state == .sounding ? AppColors.gold.opacity(0.45) : .clear, radius: 6)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .padding(.leading, -11)
            .padding(.vertical, -6)
            .accessibilityLabel(state == .sounding ? "Sounding: \(chant.latinTitle)" : "Sing from \(chant.latinTitle)")

            Button {
                open(chant)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(times > 1 ? "\(chant.latinTitle) ×\(times)" : chant.latinTitle)
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(state == .sounding ? AppColors.goldLight : AppColors.cream.opacity(state == .done ? 0.7 : 0.95))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(chant.englishTitle)
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Text(ChantPlayer.clock(chant.duration * Double(max(1, times))))
                        .font(AppFonts.labelFont(9))
                        .tracking(1)
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                }
                .padding(.bottom, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the chant")
        }
        // The thread the beads hang on
        .background(alignment: .topLeading) {
            if !isLast {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.3))
                    .frame(width: 1)
                    .padding(.top, 22)
                    .padding(.leading, 10.5)
                    .padding(.bottom, -12)
                    .accessibilityHidden(true)
            }
        }
    }

    /// The whole row is the switch, as Settings' rows are: the switch is
    /// drawn but takes no touch of its own, or a tap on it would reach
    /// both and flip the setting twice
    private var pausesBetween: some View {
        Button {
            withAnimation(Motion.settle) { shelf.pausesBetween.toggle() }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pause between chants")
                        .font(AppFonts.readingFont(16))
                        .foregroundColor(AppColors.cream)
                    Text("The next chant waits until you tap")
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer(minLength: 8)
                Toggle("Pause between chants", isOn: .constant(shelf.pausesBetween))
                    .labelsHidden()
                    .tint(AppColors.gold)
                    .allowsHitTesting(false)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pause between chants")
        .accessibilityValue(shelf.pausesBetween ? "On" : "Off")
        .accessibilityHint("The next chant waits until you tap")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Make your own

    private var makeYourOwn: some View {
        Button {
            madeSet(shelf.newSet())
        } label: {
            HStack(spacing: 14) {
                AppIcon("ph-plus", size: 16)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.5), lineWidth: AppLine.hairline))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Make your own set")
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                    Text("Choose chants for a holy hour, a prayer group or family prayer")
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Arithmetic

    /// Where each step of each block stands in the queue an occasion
    /// unrolls to: one range of entries for each round it is sung in,
    /// its repeats inside it — the decade's Ave Maria, ten entries, five
    /// times over
    static func positions(of occasion: ChantOccasion) -> [[[Range<Int>]]] {
        var cursor = 0
        var positions: [[[Range<Int>]]] = []
        for block in occasion.blocks {
            var steps = Array(repeating: [Range<Int>](), count: block.steps.count)
            for _ in 0..<max(1, block.rounds) {
                for (index, step) in block.steps.enumerated() {
                    let count = step.chant.resolve() == nil ? 0 : max(1, step.times)
                    steps[index].append(cursor..<(cursor + count))
                    cursor += count
                }
            }
            positions.append(steps)
        }
        return positions
    }

    static func numeral(_ n: Int) -> String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
        return numerals.indices.contains(n - 1) ? numerals[n - 1] : "\(n)"
    }

    static func minutes(_ duration: TimeInterval) -> String {
        "\(max(1, Int((duration / 60).rounded()))) min"
    }
}
