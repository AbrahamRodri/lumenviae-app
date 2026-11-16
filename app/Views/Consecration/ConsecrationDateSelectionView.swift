//
//  ConsecrationDateSelectionView.swift
//  Lumen Viae
//
//  The final onboarding step: choosing the consecration day (Abraham's
//  pick, option A, 16 Nov 2026, as revised the same night). The feasts
//  stand in one list in the order they come, the soonest first, and
//  never move: a tap lights a row in place. A row is the feast's name
//  and the day it is kept this year, SOONEST under the first row's date.
//  Above the one act, two dates side by side say what the choice means,
//  YOU BEGIN and YOU CONSECRATE, each on one line, stacked where they
//  cannot stand side by side; only they and the act change with the
//  choice. The act begins on the chosen feast's Day 1: today, or a later
//  day the consecration then waits for on a page of its own
//  (`ConsecrationScheduledView`).
//
//  It once lifted the chosen feast into a card of its own over the
//  others, so the list reshuffled at every tap, and stood a panel of
//  dates, a countdown and a note above the act; Abraham found both hard
//  to follow ("its kind of confusing with how the dates move around").
//  Then a sentence over the act, a SOONEST pill beside the name and a
//  line saying why the Annunciation had moved: "looks cluttered the text
//  above the begin should not be two lines and the soonest looks weirdly
//  places and the moved from march 25 is also clutter".
//
//  Only a preparation that can still begin on its Day 1 is offered, so
//  each one runs its full 33 days and ends on its feast. Joining partway
//  — praying along with a book or a group — lives in a sheet, so the
//  page itself stays quiet.
//

import SwiftUI

// MARK: - ConsecrationDateSelectionView

struct ConsecrationDateSelectionView: View {

    // MARK: - Properties

    /// Room beneath the act: clear of the tab bar where it stands, and
    /// of the home indicator where it has stepped aside
    var bottomClearance: CGFloat = 104

    @Environment(ConsecrationViewModel.self) private var viewModel

    /// The feast chosen; until one is, the soonest
    @State private var selectedID: String?
    @State private var showCustomStart: Bool = false
    @State private var customStartDay: Int = 1

    // MARK: - Body

    var body: some View {
        let preparations = MarianFeastDay.upcomingPreparations()
        let selected = preparations.first { $0.id == selectedID } ?? preparations.first

        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 8)
                        .devotionalEntrance()

                    if let completed = viewModel.completedProgress {
                        completedNote(completed)
                            .padding(.top, 14)
                    }

                    if let selected {
                        feastList(preparations, selectedID: selected.id)
                            .padding(.top, 26)
                            .devotionalEntrance(delay: 0.08)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            // The list dissolves into the foot rather than ending on an edge
            .mask(scrollFootFade)

            if let selected {
                foot(selected)
                    .devotionalEntrance(delay: 0.16)
            }
        }
        .sheet(isPresented: $showCustomStart) {
            customStartSheet
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            ConsecrationIntroKicker(
                text: String(localized: "Your consecration day", comment: "Consecration feast chooser: kicker over the title Choose your feast")
            )

            Text("Choose your feast")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("The 33 days end on a feast of Mary.")
                .font(AppFonts.italicFont(17))
                .foregroundColor(AppColors.accentSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Completed Note

    /// One quiet line honoring a finished consecration
    private func completedNote(_ progress: ConsecrationProgress) -> some View {
        HStack(spacing: 6) {
            AppIcon("ph-seal-check-fill", size: 13)

            if let date = progress.completedAt {
                Text("Consecrated \(date, style: .date) — renew whenever you wish")
            } else {
                Text("Consecration completed — renew whenever you wish")
            }
        }
        .font(AppFonts.bodyFont(12))
        .foregroundColor(AppColors.gold)
        .multilineTextAlignment(.center)
    }

    // MARK: - The Feasts

    /// Every feast in the order it comes, all nine, the chosen one lit
    /// where it stands; the list scrolls under the foot. No Show more:
    /// rows appearing were part of what Abraham found hard to follow
    /// (design-designer's ruling, 16 Nov 2026).
    private func feastList(_ shown: [FeastPreparation], selectedID: String) -> some View {
        let soonestID = shown.first?.id

        return VStack(spacing: 0) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, preparation in
                let isChosen = preparation.id == selectedID
                let afterChosen = index > 0 && shown[index - 1].id == selectedID
                VStack(spacing: 0) {
                    // A rule between two unlit rows; beside the lit row its
                    // own edge stands in, the rule clear but keeping its
                    // place, so a tap moves nothing
                    if index > 0 {
                        ConsecrationIntroRule(opacity: isChosen || afterChosen ? 0 : 0.12)
                            .padding(.horizontal, 4)
                    }
                    feastRow(preparation, isChosen: isChosen, isSoonest: preparation.id == soonestID)
                }
            }
        }
    }

    private func feastRow(_ preparation: FeastPreparation, isChosen: Bool, isSoonest: Bool) -> some View {
        Button {
            withAnimation(Motion.choice) {
                selectedID = preparation.id
            }
        } label: {
            HStack(spacing: 14) {
                FeastRadio(isOn: isChosen)
                    .frame(width: 22)

                feastName(preparation)
                // The name takes the width up to 12 pt before the date before
                // it wraps; beside a Spacer it was given only half the room
                // left, and "Nuestra Señora de Lourdes" broke after Señora
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 12)
                .layoutPriority(1)

                Text(Self.rowDate(preparation.feastDate))
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(isChosen ? AppColors.cream : AppColors.accentSoft)
                    .lineLimit(1)
                    .fixedSize()
                    // Hung under the date and given no width of its own,
                    // so LA MÁS PRÓXIMA never narrows the feast's name
                    .overlay(alignment: .topTrailing) {
                        if isSoonest {
                            soonestWord.offset(y: 26)
                        }
                    }
                    .padding(.bottom, isSoonest ? 14 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 60)
            .background {
                if isChosen {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppColors.gold.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(AppColors.gold.opacity(0.6), lineWidth: AppLine.hairline)
                        )
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.rowLabel(preparation, isSoonest: isSoonest))
        .accessibilityAddTraits(isChosen ? [.isButton, .isSelected] : [.isButton])
    }

    private func feastName(_ preparation: FeastPreparation) -> some View {
        Text(preparation.feast.name)
            .font(AppFonts.bodyFont(17))
            .foregroundColor(AppColors.cream)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// A small word under the first row's date, with no pill, so the
    /// feast's name stands alone on its line
    private var soonestWord: some View {
        Text("SOONEST")
            .font(AppFonts.labelFont(8))
            .tracking(1.6)
            .foregroundColor(AppColors.gold)
            .lineLimit(1)
            .fixedSize()
    }

    /// The feast and its date; "the soonest" when it is. A moved feast is
    /// read by the day it is kept, with nothing said of its own day
    static func rowLabel(_ preparation: FeastPreparation, isSoonest: Bool) -> String {
        let feast = preparation.feast.name
        let date = footDate(preparation.feastDate)
        return isSoonest
            ? String(
                localized: "\(feast), \(date), the soonest.",
                comment: "VoiceOver, consecration feast chooser: a feast's row (name, then date), the soonest of the feasts")
            : String(
                localized: "\(feast), \(date).",
                comment: "VoiceOver, consecration feast chooser: a feast's row (name, then date)")
    }

    // MARK: - Foot

    /// The two dates the choice means, the page's one act, and the way to
    /// begin partway. Only the dates and the act change with the feast
    /// chosen.
    private func foot(_ preparation: FeastPreparation) -> some View {
        let days = preparation.daysUntilStart()

        return VStack(spacing: 16) {
            FeastSpan(
                begin: Self.footDate(preparation.start),
                consecrate: Self.footDate(preparation.feastDate)
            )
            .animation(Motion.crossfade, value: preparation.id)

            VStack(spacing: 4) {
                GoldCTAButton(title: Self.beginTitle(preparation, days: days), glyph: .chevron) {
                    viewModel.startConsecration(on: preparation.start)
                }
                .animation(Motion.crossfade, value: preparation.id)

                customStartLink
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, bottomClearance)
    }

    // MARK: - Custom Start Link

    private var customStartLink: some View {
        Button {
            showCustomStart = true
        } label: {
            HStack(spacing: 6) {
                Text("Start at any day instead")
                    .font(AppFonts.bodyFont(15))
                AppIcon("ph-caret-right", size: 11)
            }
            .foregroundColor(AppColors.textSecondary)
            .frame(minHeight: 44)
        }
        .accessibilityHint("For praying along with a book or a group")
    }

    private var scrollFootFade: some View {
        VStack(spacing: 0) {
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 24)
        }
    }

    // MARK: - Words for Dates

    /// "Saturday, November 21" — the year only when it is not this one
    static func longDate(_ date: Date, weekday: Bool, today: Date = Date()) -> String {
        var style = Date.FormatStyle.dateTime.month(.wide).day()
        if weekday { style = style.weekday(.wide) }
        if !Calendar.current.isDate(date, equalTo: today, toGranularity: .year) {
            style = style.year()
        }
        return date.formatted(style)
    }

    /// "in 12 days", "tomorrow", "today"
    static func countdown(_ days: Int) -> String {
        if days <= 0 {
            return String(localized: "today", comment: "Consecration: how far off Day 1 is, when it is today; lower case, stands after a date or alone")
        }
        if days == 1 {
            return String(localized: "tomorrow", comment: "Consecration: how far off Day 1 is, when it is tomorrow; lower case, stands after a date or alone")
        }
        return String(
            localized: "in \(days) days",
            comment: "Consecration: how far off Day 1 is, two days or more, like in 12 days; lower case, stands after a date"
        )
    }

    /// "Begin today", or "Begin on October 19": no year, since every
    /// feast offered falls within the twelve months ahead
    static func beginTitle(_ preparation: FeastPreparation, days: Int) -> String {
        days <= 0
            ? String(localized: "Begin today", comment: "Consecration feast chooser: the gold act when the chosen preparation's Day 1 is today")
            : String(
                localized: "Begin on \(preparation.start.formatted(.dateTime.month(.wide).day()))",
                comment: "Consecration feast chooser: the gold act naming the date Day 1 falls on, like Begin on October 19"
            )
    }

    /// A feast's date on its row: "Thu, Feb 11"; in Spanish "jue, 11 feb".
    /// No year: the list runs in the order the feasts come, within the
    /// twelve months ahead.
    static func rowDate(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// A day in the foot, standing alone under its label: "Saturday,
    /// January 9"; in Spanish "Miércoles 3 de marzo", without the comma
    /// the system puts after the weekday and with a capital, since it
    /// begins its line
    static func footDate(_ date: Date) -> String {
        let words = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        guard AppLanguage.isSpanish else { return words }
        let joined = words.replacingOccurrences(of: ", ", with: " ")
        return joined.prefix(1).uppercased() + joined.dropFirst()
    }

    // MARK: - Custom Start Sheet

    private var customStartSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                kicker: String(localized: "Consecration to Mary", comment: "Consecration, Start at Any Day sheet: kicker over the title"),
                title: String(localized: "Start at Any Day", comment: "Consecration: title of the sheet for joining the 33 days partway"),
                lead: String(
                    localized: "Praying along with a book or a group? Begin wherever they are.",
                    comment: "Consecration, Start at Any Day sheet: one line under the title saying who it is for"
                )
            )

            VStack(spacing: 14) {
                Picker("Start Day", selection: $customStartDay) {
                    ForEach(1...33, id: \.self) { day in
                        Text("Day \(day)")
                            .font(AppFonts.bodyFont(16))
                            .foregroundColor(AppColors.cream)
                            .tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .colorScheme(.dark)

                VStack(spacing: 6) {
                    if let phase = ConsecrationPhase.phase(for: customStartDay) {
                        Text("\(phase.displayName) — \(phase.subtitle)")
                            .font(AppFonts.italicFont(13))
                            .foregroundColor(AppColors.gold.opacity(0.8))
                    }

                    Text("Consecration Day: \(consecrationDate(startingAt: customStartDay), style: .date)")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }

                GoldCTAButton(
                    title: String(
                        localized: "Begin today at Day \(customStartDay)",
                        comment: "Consecration, Start at Any Day sheet: the gold act, beginning today on the chosen day of the 33"
                    ),
                    glyph: .chevron
                ) {
                    showCustomStart = false
                    viewModel.startConsecration(startingAt: customStartDay)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SheetMetrics.gutter)

            Spacer(minLength: 0)
        }
        .sheetGround()
        // Taller than the 440 it had: the sheet header keeps room above
        // its kicker for the drag indicator
        .presentationDetents([.height(490)])
    }

    /// The date Day 34 lands on when today counts as `day`.
    private func consecrationDate(startingAt day: Int) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: 34 - day,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date()
    }
}

// MARK: - FeastSpan

/// YOU BEGIN over Day 1's date, a thin gold arrow, YOU CONSECRATE over the
/// feast's, right-aligned. Each date stays on one line; where the two
/// cannot stand side by side (the largest text, a narrow phone) they are
/// stacked, left-aligned, and the arrow is left out.
private struct FeastSpan: View {
    let begin: String
    let consecrate: String

    private var beginLabel: String {
        String(localized: "You begin", comment: "Consecration feast chooser, over Begin: small capitals over Day 1's date")
    }

    private var consecrateLabel: String {
        String(localized: "You consecrate", comment: "Consecration feast chooser, over Begin: small capitals over the feast's date, the day of consecration")
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                part(beginLabel, begin, alignment: .leading)
                Spacer(minLength: 0)
                AppIcon("ph-arrow-right", size: 22)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .alignmentGuide(.lastTextBaseline) { $0[.bottom] - 2 }
                Spacer(minLength: 0)
                part(consecrateLabel, consecrate, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: 12) {
                part(beginLabel, begin, alignment: .leading)
                part(consecrateLabel, consecrate, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(
                localized: "You begin \(begin). You consecrate \(consecrate).",
                comment: "VoiceOver, consecration feast chooser: the two dates over Begin, Day 1's then the feast's"))
    }

    private func part(_ label: String, _ date: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(label.uppercased())
                .font(AppFonts.labelFont(9.5))
                .tracking(2.1)
                .foregroundColor(AppColors.gold)
                .lineLimit(1)
                .fixedSize()

            Text(date)
                .font(AppFonts.bodyFont(17))
                .foregroundColor(AppColors.cream)
                .lineLimit(1)
                .fixedSize()
                .contentTransition(.opacity)
        }
    }
}

// MARK: - FeastRadio

/// The chooser's radio: a gold ring with its dot for the feast chosen,
/// a faint empty ring for each of the others
private struct FeastRadio: View {
    let isOn: Bool

    var body: some View {
        let size: CGFloat = isOn ? 22 : 18

        Circle()
            .strokeBorder(
                isOn ? AppColors.gold : AppColors.textSecondary.opacity(0.5),
                lineWidth: isOn ? 1.5 : 1
            )
            .frame(width: size, height: size)
            .overlay {
                if isOn {
                    Circle()
                        .fill(AppColors.gold)
                        .frame(width: 10, height: 10)
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.appGradient.ignoresSafeArea()
        ConsecrationDateSelectionView()
            .environment(ConsecrationViewModel())
    }
}
