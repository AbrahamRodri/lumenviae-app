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
    /// Scrolls the library to a view of this section, by its id
    let reveal: (String) -> Void

    /// The order of service's place on the page, for the library to
    /// scroll to when an occasion is chosen — here, or from Today
    static let orderAnchor = "chantLibrary.occasionOrder"

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    @State private var namingSet = false

    /// A kept set the reader has changed, waiting on their word before
    /// the bookmark lets it go
    @State private var unkeeping: ChantSet?

    init(
        openID: Binding<String?>,
        open: @escaping (Chant) -> Void,
        madeSet: @escaping (ChantSet) -> Void,
        reveal: @escaping (String) -> Void
    ) {
        _openID = openID
        self.open = open
        self.madeSet = madeSet
        self.reveal = reveal
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
            .id(Self.orderAnchor)

            makeYourOwn
                .padding(.horizontal, 20)
        }
        .animation(Motion.crossfade, value: chosen.id)
        // The order chosen is brought up, or the tap would seem to have
        // done nothing: it opens below the fold of the index
        .onChange(of: openID) { _, _ in
            reveal(Self.orderAnchor)
        }
        .sheet(isPresented: $namingSet) {
            ChantNewSetSheet { set in madeSet(set) }
                .presentationDetents([.medium])
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        // The same question Saved asks before a set is deleted
        .confirmationDialog(
            "Delete \(unkeeping?.name ?? "this set")?",
            isPresented: Binding(get: { unkeeping != nil }, set: { if !$0 { unkeeping = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete the Set", role: .destructive) {
                if let unkeeping { shelf.deleteSet(unkeeping.id) }
                unkeeping = nil
            }
            Button("Cancel", role: .cancel) { unkeeping = nil }
        } message: {
            // True whatever made it differ: the reader's own changes, or a
            // later build's, which this one cannot see
            Text("This set no longer matches the occasion's order. Deleting it removes the set; its chants stay in the library.")
        }
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
                    .foregroundColor(Rubric.text)
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
                        .accessibilityLabel(Self.spokenMinutes(occasion.duration()))
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
        let sung = player.isSinging(queue) ? player.queue : nil
        let numbers = Self.stepNumbers(of: occasion)
        let count = occasion.distinctChants().count

        return VStack(alignment: .leading, spacing: 0) {
            ChantPainting(name: occasion.painting, height: 170, dissolveFrom: 0.25)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text((count == 1 ? "1 chant, in order" : "\(count) chants, in order").uppercased())
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
                                        state: state(of: numbers[blockIndex][stepIndex], in: sung),
                                        isLast: blockIndex == occasion.blocks.count - 1 && stepIndex == block.steps.count - 1,
                                        playFrom: {
                                            let number = numbers[blockIndex][stepIndex]
                                            // The bead sounding pauses and takes up
                                            // the set; any other sings from there
                                            if state(of: number, in: player.isSinging(queue) ? player.queue : nil) == .sounding {
                                                player.pauseOrResume()
                                            } else {
                                                player.play(queue, from: queue.origins.firstIndex(of: number) ?? 0)
                                            }
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
                    ChantSetPlayButton(queue: queue, title: "Play all \(count)")
                    keepButton(occasion)
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

    /// The bookmark: keeps the occasion as a set of the reader's own, and
    /// a second tap lets it go — one kept set for each occasion. A kept set
    /// the reader has changed since is let go only once they say so.
    private func keepButton(_ occasion: ChantOccasion) -> some View {
        let kept = shelf.keptSet(of: occasion) != nil
        return Button {
            if case .askFirst(let set) = shelf.toggleKeeping(occasion) {
                unkeeping = set
            }
        } label: {
            AppIcon(kept ? "ph-bookmark-simple-fill" : "ph-bookmark-simple", size: 18)
                .foregroundColor(AppColors.gold)
                .frame(width: 52, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.gold.opacity(kept ? 0.7 : 0.4), lineWidth: AppLine.hairline)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .sensoryFeedback(.selection, trigger: kept)
        .accessibilityLabel("Save as your own set")
        .accessibilityValue(kept ? "Saved" : "")
        .accessibilityAddTraits(kept ? [.isSelected] : [])
    }

    private enum StepState { case done, sounding, ahead }

    /// What a tap on the bead does, as VoiceOver says it
    private func beadLabel(_ chant: Chant, state: StepState) -> String {
        guard state == .sounding else { return "Play from \(chant.spokenName)" }
        let act = player.isGoingOn ? "Pause the set at" : "Resume the set at"
        return "\(act) \(chant.spokenName)"
    }

    /// A step sounding in any of its rounds is lit; one whose last round
    /// is behind the set is done — read from the queue's own record of
    /// which step each entry came from
    private func state(of number: Int, in sung: ChantQueue?) -> StepState {
        guard let sung else { return .ahead }
        if sung.origin == number { return .sounding }
        if let last = sung.origins.lastIndex(of: number), last < sung.index { return .done }
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
                        AppIcon(player.isGoingOn ? "ph-pause-fill" : "ph-play-fill", size: 9)
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
            .accessibilityLabel(beadLabel(chant, state: state))

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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(chant.spokenEntry(times: times, duration: chant.duration * Double(max(1, times))))
            .accessibilityAddTraits(.isButton)
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
            namingSet = true
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
                    Text("Choose chants for an hour of prayer in church, a prayer group or family prayer")
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

    /// Each step's number, in the order the occasion writes its steps —
    /// the numbers `ChantQueue.occasion` gives the entries it unrolls
    static func stepNumbers(of occasion: ChantOccasion) -> [[Int]] {
        var number = 0
        return occasion.blocks.map { block in
            block.steps.map { _ in
                defer { number += 1 }
                return number
            }
        }
    }

    /// The index's number, in figures: it is counted, not titled
    static func numeral(_ n: Int) -> String {
        "\(n)"
    }

    static func minutes(_ duration: TimeInterval) -> String {
        "\(max(1, Int((duration / 60).rounded()))) min"
    }

    static func spokenMinutes(_ duration: TimeInterval) -> String {
        let whole = max(1, Int((duration / 60).rounded()))
        return whole == 1 ? "1 minute" : "\(whole) minutes"
    }
}
