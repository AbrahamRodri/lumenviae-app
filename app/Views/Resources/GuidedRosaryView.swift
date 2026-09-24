//
//  GuidedRosaryView.swift
//  Lumen Viae
//
//  A whole Rosary for someone who has never prayed one: a step at a
//  time, with nothing to know in advance.
//
//  It opens on a welcome — that nothing need be known, which mysteries
//  (today's chosen, the choice high enough to be seen before Begin),
//  then what to hold — and then walks the traditional order bead by bead
//  (`GuidedRosary.steps`). Every step says, in plain words, where the
//  fingers are and what to do there, and sets every prayer said there
//  in full. The rosary is drawn above the words (`RosaryDiagram`), the
//  bead under the fingers lit and the beads behind it gold, so the
//  object in the hand and the picture agree. Each mystery is introduced
//  on its own step, with its painting, what it is, and the grace to ask
//  for, before its decade begins.
//
//  Movement is two plain buttons, Back and Next — no gesture to discover.
//  Under Reduce Motion the steps still crossfade; only movement falls
//  away. The last step's act is Amen, which records the Rosary like any
//  other (it counts as the day's Rosary) and opens the completion screen.
//
//  The course calls this page "Your First Rosary", and so does every
//  word on it but the header's kicker, A GUIDED ROSARY.
//

import SwiftUI

struct GuidedRosaryView: View {

    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings

    @State private var category: MysteryCategory

    /// Nil on the welcome; the step under the fingers after it
    @State private var index: Int?

    @State private var startedAt = Date()
    @State private var confirmingLeave = false

    private static let topAnchor = "guided-top"

    init(category: MysteryCategory) {
        _category = State(initialValue: GuidedRosary.isGuidable(category) ? category : .joyful)
    }

    private var steps: [GuidedStep] { GuidedRosary.steps(for: category) }

    private var step: GuidedStep? {
        guard let index, steps.indices.contains(index) else { return nil }
        return steps[index]
    }

    private var isLast: Bool { index == steps.count - 1 }

    private var readingSize: CGFloat { max(17, settings.meditationFontSize - 1) }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppColors.appGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    RosaryDiagram(current: step?.part, completed: step?.isClosing ?? false)
                        .frame(height: min(geometry.size.height * 0.24, 220))
                        .padding(.top, 2)

                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(height: 1)
                                    .id(Self.topAnchor)

                                // One slot: the leaving step and the
                                // arriving one crossfade over each other
                                // and nothing below them moves.
                                ZStack(alignment: .top) {
                                    if let step {
                                        stepContent(step)
                                            .id(step.id)
                                            .transition(.opacity)
                                    } else {
                                        welcome
                                            .transition(.opacity)
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.top, 18)
                                .padding(.bottom, 40)
                            }
                        }
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.04),
                                    .init(color: .black, location: 0.92),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .onChange(of: index) {
                            proxy.scrollTo(Self.topAnchor, anchor: .top)
                        }
                    }

                    foot
                }
            }
        }
        .navigationBarHidden(true)
        .sensoryFeedback(trigger: index) { old, new in
            guard let new, let old, steps.indices.contains(new), steps.indices.contains(old) else {
                return .selection
            }
            // A new mystery lands with more weight than a bead
            return steps[new].isAnnouncement && new > old ? .impact(weight: .medium) : .selection
        }
        // An alert rather than a confirmation dialog: a dialog may drop
        // its cancel button for a tap outside, and a beginner should see
        // "Keep praying" said as plainly as "Leave"
        .alert("Leave your first Rosary?", isPresented: $confirmingLeave) {
            Button("Keep praying", role: .cancel) {}
            Button("Leave", role: .destructive) { router.pop() }
        } message: {
            Text("You can begin it again from How to Pray at any time.")
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            PrayerHeaderButton(icon: "ph-x", size: 18, label: "Leave your first Rosary", tint: AppColors.gold) {
                if let index, index > 1 {
                    confirmingLeave = true
                } else {
                    router.pop()
                }
            }

            Spacer()

            Text("A GUIDED ROSARY")
                .font(AppFonts.labelFont(10))
                .tracking(2.6)
                .foregroundColor(AppColors.gold.opacity(0.85))

            Spacer()

            // Balances the close button so the title sits centred
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    /// Back and Next, always in the same place. Back is missing on the
    /// welcome rather than greyed.
    private var foot: some View {
        HStack(spacing: 12) {
            if index != nil {
                QuietGoldButton(
                    title: "Back",
                    leadingIcon: "ph-caret-left",
                    leadingIconSize: 10,
                    horizontalPadding: 8
                ) {
                    move(by: -1)
                }
                .transition(.opacity)
            }

            Spacer()

            // Begin wears play, as the course's Begin does: a prayer begins
            GoldCTAButton(
                title: index == nil ? "Begin" : (isLast ? "Amen" : "Next"),
                prominence: .inline,
                trailingIcon: index == nil ? "ph-play-fill" : (isLast ? "ph-check" : "ph-caret-right"),
                fullWidth: false
            ) {
                if isLast {
                    finish()
                } else {
                    move(by: 1)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .animation(Motion.crossfade, value: index == nil)
    }

    private func move(by delta: Int) {
        withAnimation(Motion.crossfade) {
            switch (index, delta) {
            case (nil, 1):
                startedAt = Date()
                index = 0
            case (0, -1):
                index = nil
            case (let current?, _):
                index = min(max(current + delta, 0), steps.count - 1)
            default:
                break
            }
        }
    }

    private func finish() {
        router.navigateToCompletion(CompletedPrayer(
            category: category,
            devotionName: GuidedRosary.devotionName,
            durationSeconds: Int(Date().timeIntervalSince(startedAt))
        ))
    }

    // MARK: - Welcome

    /// The choice of mysteries stands second, straight after the promise
    /// that nothing need be known, so it is on the first screen above
    /// Begin; what to hold and the drawing are said after it
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("BEFORE YOU BEGIN")
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.4)
                    .foregroundColor(AppColors.gold)

                Text("Your First Rosary")
                    .font(AppFonts.titleFont(26))
                    .foregroundColor(AppColors.cream)
            }

            ReadingText(
                text: "You do not need to know anything by heart. Every step will tell you where you are and what to do, and every word is written out.",
                size: readingSize - 1,
                showsDropCap: true
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("THE MYSTERIES YOU WILL PRAY")
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.85))

                Text("The Rosary is five decades — sets of ten Hail Marys — each spent with one scene from the life of Jesus and Mary. Today's are chosen for you; you may pick others.")
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                mysteryPicker
            }

            ReadingText(
                text: "Hold a rosary if you have one; if not, your ten fingers will count the beads. Pray aloud or silently, as you like.\n\nThe drawing above is a rosary. The bead you are on will light up as you go, so you can always find your place.",
                size: readingSize - 1
            )
        }
    }

    private var mysteryPicker: some View {
        let today = ScheduleService.categoryForToday()

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(MysteryCategory.allCategories.filter { GuidedRosary.isGuidable($0) }, id: \.self) { candidate in
                let chosen = candidate == category

                Button {
                    withAnimation(Motion.crossfade) { category = candidate }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        RosaryBead(state: chosen ? .prayed : .ahead, size: 8)
                            .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(candidate.devotionTitle)
                                .font(AppFonts.readingFont(16))
                                .foregroundColor(chosen ? AppColors.goldLight : AppColors.cream.opacity(0.92))

                            Text(candidate.subtitle)
                                .font(AppFonts.readingItalicFont(14))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer(minLength: 8)

                        if candidate == today {
                            Text("TODAY")
                                .font(AppFonts.labelFont(10))
                                .tracking(2)
                                .foregroundColor(AppColors.gold.opacity(0.7))
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(chosen ? [.isSelected, .isButton] : .isButton)
            }
        }
    }

    // MARK: - A Step

    @ViewBuilder
    private func stepContent(_ step: GuidedStep) -> some View {
        if step.isAnnouncement, let decade = step.decade {
            announcement(step, decade: decade)
        } else {
            VStack(alignment: .leading, spacing: 18) {
                Text(step.place.uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold)
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.instruction)
                    .font(AppFonts.readingItalicFont(readingSize - 1))
                    .foregroundColor(AppColors.cream.opacity(0.78))
                    .lineSpacing(ReadingTypography.lineSpacing(for: readingSize - 1) - 2)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(step.prayerIDs, id: \.self) { id in
                    if let prayer = DevotionPrayers.find(id) {
                        VStack(alignment: .leading, spacing: 10) {
                            prayerHeading(prayer.displayTitle(for: settings.prayerLanguage))

                            PrayerText(
                                content: prayer.formattedContent(for: settings.prayerLanguage),
                                size: readingSize,
                                alignment: .leading
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// A mystery named before its decade: the painting, the ordinal,
    /// the name, what happened, and the grace to ask for
    private func announcement(_ step: GuidedStep, decade: Int) -> some View {
        let mystery = MysteryData.mysteries(for: category)[decade]
        let fruit = MysteryData.traditionalFruits["\(category.rawValue)_\(mystery.order)"]
        let arch = GothicArchShape(riseRatio: 0.34)

        return VStack(spacing: 16) {
            if let painting = Constants.mysteryImageURL(category: category.rawValue, index: decade) {
                arch
                    .fill(AppColors.cardBackground)
                    .frame(width: 132, height: 132 * 1.22)
                    .overlay(CachedAssetImage(painting))
                    .clipShape(arch)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 8) {
                Text(step.place.uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold)

                Text(mystery.name)
                    .font(AppFonts.titleFont(25))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let reference = mystery.scriptureReference {
                    Text(reference)
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.gold.opacity(0.8))
                }
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 14) {
                if let description = mystery.description {
                    ReadingText(text: description, size: readingSize)
                }

                Text(step.instruction)
                    .font(AppFonts.readingItalicFont(readingSize - 1))
                    .foregroundColor(AppColors.cream.opacity(0.78))
                    .lineSpacing(ReadingTypography.lineSpacing(for: readingSize - 1) - 2)
                    .fixedSize(horizontal: false, vertical: true)

                if let fruit {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("ASK FOR")
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1.8)
                            .foregroundColor(AppColors.gold.opacity(0.8))

                        Text(fruit)
                            .font(AppFonts.readingFont(readingSize - 1))
                            .foregroundColor(AppColors.goldLight)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func prayerHeading(_ title: String) -> some View {
        HStack(spacing: 12) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(8.5))
                .tracking(1.8)
                .foregroundColor(AppColors.gold.opacity(0.85))
                .fixedSize()

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gold.opacity(0.35), AppColors.gold.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppLine.hairline)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    NavigationStack {
        GuidedRosaryView(category: .joyful)
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
