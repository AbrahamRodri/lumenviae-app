//
//  ConsecrationDateSelectionView.swift
//  Lumen Viae
//
//  The final onboarding step: choosing the consecration day (Abraham's
//  pick, option A with the one-sentence panel, 16 Nov 2026). The feasts
//  stand in one list in the order they come, the soonest first, and
//  never move: a tap lights a row in place. A feast moved this time says
//  so under its name. Above the one act, one sentence says what the
//  choice means ("33 days, from Saturday, January 9 to Thursday,
//  February 11."), and only it and the act change with the choice. The
//  act begins on the chosen feast's Day 1: today, or a later day the
//  consecration then waits for on a page of its own
//  (`ConsecrationScheduledView`).
//
//  It once lifted the chosen feast into a card of its own over the
//  others, so the list reshuffled at every tap, and stood a panel of
//  dates, a countdown and a note above the act; Abraham found both hard
//  to follow ("its kind of confusing with how the dates move around").
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
        let moved = Self.movedNote(preparation)

        return Button {
            withAnimation(Motion.choice) {
                selectedID = preparation.id
            }
        } label: {
            HStack(spacing: 14) {
                FeastRadio(isOn: isChosen)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    // The badge beside the name where both fit, beneath it
                    // where they do not (a long name, Spanish, large text)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            feastName(preparation)
                            if isSoonest { soonestBadge }
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            feastName(preparation)
                            if isSoonest { soonestBadge }
                        }
                    }

                    if let moved {
                        Text(moved)
                            .font(AppFonts.readingItalicFont(15))
                            .foregroundColor(AppColors.goldLight)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                Text(Self.rowDate(preparation.feastDate))
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(isChosen ? AppColors.cream : AppColors.accentSoft)
                    .lineLimit(1)
                    .fixedSize()
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
        .accessibilityLabel(Self.rowLabel(preparation, isSoonest: isSoonest, moved: moved))
        .accessibilityAddTraits(isChosen ? [.isButton, .isSelected] : [.isButton])
    }

    private func feastName(_ preparation: FeastPreparation) -> some View {
        Text(preparation.feast.name)
            .font(AppFonts.bodyFont(17))
            .foregroundColor(AppColors.cream)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Outlined, not filled: the page's one filled gold shape is its act
    private var soonestBadge: some View {
        Text("SOONEST")
            .font(AppFonts.labelFont(10))
            .tracking(2.5)
            .foregroundColor(AppColors.goldLight)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.6), lineWidth: AppLine.hairline))
    }

    /// The feast, its date, and why it moved; "the soonest" when it is
    static func rowLabel(_ preparation: FeastPreparation, isSoonest: Bool, moved: String?) -> String {
        let feast = preparation.feast.name
        let date = spanDate(preparation.feastDate)
        let named = isSoonest
            ? String(
                localized: "\(feast), \(date), the soonest.",
                comment: "VoiceOver, consecration feast chooser: a feast's row (name, then date), the soonest of the feasts")
            : String(
                localized: "\(feast), \(date).",
                comment: "VoiceOver, consecration feast chooser: a feast's row (name, then date)")
        guard let moved else { return named }
        return named + " " + moved + "."
    }

    // MARK: - Foot

    /// One sentence saying what the choice means, the page's one act, and
    /// the way to begin partway. Only the sentence and the act change
    /// with the feast chosen.
    private func foot(_ preparation: FeastPreparation) -> some View {
        let days = preparation.daysUntilStart()

        return VStack(spacing: 14) {
            spanSentence(preparation)
                .font(AppFonts.bodyFont(17))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
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

    /// "33 days, from Saturday, January 9 to Thursday, February 11", the
    /// two days in the page's brighter cream
    private func spanSentence(_ preparation: FeastPreparation) -> Text {
        // Each date on one line: its spaces do not break
        let start = Text(Self.spanDate(preparation.start).replacingOccurrences(of: " ", with: "\u{00A0}"))
            .foregroundColor(AppColors.cream)
        let end = Text(Self.spanDate(preparation.feastDate).replacingOccurrences(of: " ", with: "\u{00A0}"))
            .foregroundColor(AppColors.cream)
        return Text(
            "33 days, from \(start) to \(end)",
            comment: "Consecration feast chooser, over Begin: what the chosen feast means, Day 1's date then the feast's, each with its weekday, like 33 days, from Saturday, January 9 to Thursday, February 11.")
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

    /// A day in the sentence over Begin: "Saturday, January 9"; in
    /// Spanish "sábado 9 de enero", without the comma the system puts
    /// after the weekday, as the sentence reads ("del sábado 9 de enero")
    static func spanDate(_ date: Date) -> String {
        let words = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        guard AppLanguage.isSpanish, let comma = words.range(of: ", ") else { return words }
        return words.replacingCharacters(in: comma, with: " ")
    }

    /// Why a feast falls off its own day this time, under its name:
    /// "Moved from March 25, which is Holy Thursday in 2027". Only the
    /// Annunciation moves (`MarianFeastDay.date(for:)`); nil for a feast
    /// on its own day.
    static func movedNote(_ preparation: FeastPreparation, calendar: Calendar = .current) -> String? {
        let feast = preparation.feast
        let year = calendar.component(.year, from: preparation.feastDate)
        guard let ownDay = calendar.date(from: DateComponents(year: year, month: feast.month, day: feast.day)),
              !calendar.isDate(ownDay, inSameDayAs: preparation.feastDate),
              let easter = ScheduleService.easterSunday(year: year, calendar: calendar)
        else { return nil }
        let fromEaster = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: easter), to: calendar.startOfDay(for: ownDay)
        ).day ?? 0
        let day: String
        switch fromEaster {
        case -7: day = String(localized: "Palm Sunday", comment: "Consecration feast chooser, why a feast moved: the day its own date falls on that year")
        case -6: day = String(localized: "Monday of Holy Week", comment: "Consecration feast chooser, why a feast moved: the day its own date falls on that year")
        case -5: day = String(localized: "Tuesday of Holy Week", comment: "Consecration feast chooser, why a feast moved: the day its own date falls on that year")
        case -4: day = String(localized: "Wednesday of Holy Week", comment: "Consecration feast chooser, why a feast moved: the day its own date falls on that year")
        case -3: day = String(localized: "Holy Thursday", comment: "Consecration feast chooser, why a feast moved: the day its own date falls on that year")
        case -2: day = String(localized: "Good Friday", comment: "Consecration feast chooser, why a feast moved: the day its own date falls on that year")
        case -1: day = String(localized: "Holy Saturday", comment: "Consecration feast chooser, why a feast moved: the day its own date falls on that year")
        case 0: day = String(localized: "Easter Sunday", comment: "Consecration feast chooser, why a feast moved: the day its own date falls on that year")
        case 1...6: day = String(localized: "in Easter Week", comment: "Consecration feast chooser, why a feast moved: its own date falls in the week after Easter Sunday that year; stands after which is, like which is in Easter Week in 2035")
        case 7: day = String(localized: "the Sunday after Easter", comment: "Consecration feast chooser, why a feast moved: the day its own date falls on that year")
        default: day = String(localized: "a Sunday of Lent", comment: "Consecration feast chooser, why a feast moved: the day its own date falls on that year")
        }
        let from = ownDay.formatted(.dateTime.month(.wide).day())
        return String(
            localized: "Moved from \(from), which is \(day) in \(String(year))",
            comment: "Consecration feast chooser, under a feast's name: its own date, the day that date falls on, and the year, like Moved from March 25, which is Holy Thursday in 2027"
        )
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
