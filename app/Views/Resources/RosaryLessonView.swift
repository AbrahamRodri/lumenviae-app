//
//  RosaryLessonView.swift
//  Lumen Viae
//
//  One lesson of How to Pray the Rosary, each built for what it teaches:
//
//  I   The Beads and the Order — what the Rosary is; a large drawn
//      rosary whose parts light as they are chosen from a row of chips;
//      then the order as a chain of steps, each opening on its prayer.
//  II  The Prayers — the eight prayers as cards, each with how often it
//      is said, its words in full, and "Say it with me": the prayer
//      given a line at a time, so it can be said from memory with the
//      page as a prompt.
//  III The Mysteries — the four sets as painted cards with their five
//      scenes and their days, how to dwell on a mystery, and this week.
//      A set, or a day of the week, opens your first Rosary on those
//      mysteries: the course's own last step, never a page outside it.
//
//  The foot moves on to the next lesson — replacing this one, so the
//  course never stacks — and after the last, to the first Rosary. The
//  destination carries the lesson as its identity (ContentView), and a
//  lesson is marked seen whenever the lesson shown changes, so one that
//  arrives by Continue gets its check like one opened from the path.
//

import SwiftUI

struct RosaryLessonView: View {

    let lesson: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings

    @AppStorage(RosaryLesson.seenKey) private var seenLessons: String = ""

    // Lesson I
    @State private var anatomyID = RosaryMap.anatomy[0].id
    @State private var activeStep = 1

    // Lesson II — how many lines of each prayer are showing, keyed by
    // prayer id; absent means the prayer is shown whole
    @State private var practice: [String: Int] = [:]

    private var current: RosaryLesson { RosaryLesson(rawValue: lesson) ?? .beads }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .devotionalEntrance()

                    Group {
                        switch current {
                        case .beads:     beadsLesson
                        case .prayers:   prayersLesson
                        case .mysteries: mysteriesLesson
                        }
                    }
                    .devotionalEntrance(delay: 0.08)

                    foot
                        .padding(.horizontal, 24)
                        .padding(.top, 44)
                        .padding(.bottom, 56)
                }
            }
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
        .task(id: lesson) {
            seenLessons = RosaryLesson.marking(lesson, in: seenLessons)
        }
    }

    // MARK: - Header

    /// The lesson's place in the course as three segments, its numeral,
    /// and its name
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(RosaryLesson.allCases, id: \.rawValue) { each in
                    Capsule()
                        .fill(each.rawValue <= lesson ? AppColors.gold : AppColors.gold.opacity(0.18))
                        .frame(height: 3)
                }
            }
            .accessibilityHidden(true)

            Text("LESSON \(current.numeral) OF III")
                .font(AppFonts.labelFont(9.5))
                .tracking(2.8)
                .foregroundColor(AppColors.gold)
                .padding(.top, 10)

            Text(current.title)
                .font(AppFonts.titleFont(30))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func sectionLabel(_ title: String) -> some View {
        HStack(spacing: 12) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(9.5))
                .tracking(2.6)
                .foregroundColor(AppColors.gold.opacity(0.9))
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
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 18)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Lesson I: The Beads and the Order

    private var beadsLesson: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReadingText(
                text: "The Rosary is a prayer of the Gospel. It is prayed in five decades — sets of ten Hail Marys. For each decade we call to mind one scene from the life of Jesus and His Mother — a mystery — and while we think about it, we pray: an Our Father, ten Hail Marys, a Glory Be, and the Fatima Prayer.\n\nThe words are simple and the same each time, and that is the point. They become a quiet rhythm under the heart, leaving the mind free to look at Christ. The beads keep the count, so you do not have to.",
                size: 17,
                showsDropCap: true
            )
            .padding(.horizontal, 24)
            .padding(.top, 22)

            sectionLabel("Meet the beads")
            anatomy

            sectionLabel("The order")
            steps
                .padding(.horizontal, 24)
        }
    }

    /// The rosary large, and a row of its parts; choosing one lights it
    private var anatomy: some View {
        let chosen = RosaryMap.anatomy.first { $0.id == anatomyID } ?? RosaryMap.anatomy[0]

        return VStack(spacing: 18) {
            RosaryDiagram(highlighted: chosen.parts)
                .frame(width: 250)
                .frame(maxWidth: .infinity)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RosaryMap.anatomy) { part in
                        let isChosen = part.id == anatomyID

                        Button {
                            withAnimation(Motion.crossfade) { anatomyID = part.id }
                        } label: {
                            Text(part.name)
                                .font(AppFonts.readingFont(15))
                                .foregroundColor(isChosen ? AppColors.background : AppColors.cream.opacity(0.9))
                                .padding(.horizontal, 14)
                                .frame(height: 38)
                                .background(
                                    Capsule().fill(isChosen ? AnyShapeStyle(AppColors.goldGradient) : AnyShapeStyle(AppColors.cardBackground.opacity(0.6)))
                                )
                                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(isChosen ? 0 : 0.25), lineWidth: AppLine.hairline))
                                .frame(minHeight: 44)
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(part.name). \(part.prayed)")
                        .accessibilityAddTraits(isChosen ? [.isSelected, .isButton] : .isButton)
                    }
                }
                .padding(.horizontal, 24)
            }

            ZStack(alignment: .topLeading) {
                Text(chosen.prayed)
                    .font(AppFonts.readingItalicFont(17))
                    .foregroundColor(AppColors.cream.opacity(0.9))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(chosen.id)
                    .transition(.opacity)
            }
            .frame(minHeight: 76, alignment: .topLeading)
            .padding(.horizontal, 24)
        }
        .animation(Motion.crossfade, value: anatomyID)
    }

    /// The steps strung as beads on one chain; the lit step carries its
    /// prayer in full
    private var steps: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tap a step to see its words.")
                .font(AppFonts.readingItalicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .padding(.bottom, 6)

            ForEach(HowToPrayData.steps) { step in
                stepRow(step)
            }
        }
    }

    private func stepRow(_ step: RosaryStep) -> some View {
        let isActive = step.id == activeStep
        let isDone = step.id < activeStep
        let isLast = step.id == HowToPrayData.steps.count

        return Button {
            withAnimation(Motion.crossfade) { activeStep = step.id }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isDone ? AppColors.gold : AppColors.background)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().fill(isActive ? AppColors.gold.opacity(0.25) : .clear))
                        .overlay(
                            Circle().strokeBorder(
                                isActive ? AppColors.goldLight : AppColors.gold.opacity(0.5),
                                lineWidth: isActive ? 1.5 : AppLine.hairline
                            )
                        )

                    Text("\(step.id)")
                        .font(AppFonts.labelFont(9))
                        .foregroundColor(isDone ? AppColors.background : AppColors.gold)
                }
                .padding(.top, 10)

                VStack(alignment: .leading, spacing: 5) {
                    Text(step.title)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(isActive ? AppColors.goldLight : AppColors.cream.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(step.detail)
                        .font(AppFonts.readingItalicFont(14.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if isActive, !step.prayerIDs.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(step.prayerIDs, id: \.self) { id in
                                if let prayer = DevotionPrayers.find(id) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(prayer.displayTitle(for: settings.prayerLanguage).uppercased())
                                            .font(AppFonts.labelFont(8.5))
                                            .tracking(1.8)
                                            .foregroundColor(AppColors.gold.opacity(0.8))

                                        PrayerText(
                                            content: prayer.formattedContent(for: settings.prayerLanguage),
                                            size: 16,
                                            alignment: .leading
                                        )
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppColors.cardBackground.opacity(0.55))
                        )
                        .padding(.top, 8)
                        .transition(.opacity)
                    }
                }
                .padding(.vertical, 10)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .background(alignment: .topLeading) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.25))
                    .frame(width: AppLine.hairline)
                    .frame(maxHeight: isLast ? 22 : .infinity)
                    .padding(.leading, 12 - AppLine.hairline / 2)
                    .padding(.top, step.id == 1 ? 22 : 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Lesson II: The Prayers

    private var prayersLesson: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReadingText(
                text: "Eight prayers make the whole Rosary, and most of them you may already half know. Read each one through. Then try \u{201C}Say it with me\u{201D}: the prayer comes a line at a time, so you can say each line before you see it.\n\nStart with the Hail Mary. It is said fifty-three times in one Rosary, and after a week it will be yours.",
                size: 17,
                showsDropCap: true
            )
            .padding(.horizontal, 24)
            .padding(.top, 22)

            VStack(spacing: 14) {
                ForEach(Self.prayerOrder, id: \.self) { id in
                    if let prayer = DevotionPrayers.find(id) {
                        prayerCard(prayer)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
        }
    }

    /// The Hail Mary first, because it is learnt first; the rest in the
    /// order they are said
    private static let prayerOrder = [
        "hail_mary", "our_father", "glory_be", "sign_of_cross",
        "apostles_creed", "fatima_prayer", "hail_holy_queen", "rosary_closing_prayer"
    ]

    private func prayerCard(_ prayer: BilingualConsecrationPrayer) -> some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let isFirst = prayer.id == "hail_mary"
        let revealed = practice[prayer.id]

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    if isFirst {
                        Text("LEARN THIS ONE FIRST")
                            .font(AppFonts.labelFont(8.5))
                            .tracking(2)
                            .foregroundColor(AppColors.goldLight)
                    }

                    Text(prayer.englishTitle)
                        .font(AppFonts.titleFont(19))
                        .foregroundColor(AppColors.cream)

                    Text(prayer.latinTitle)
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.gold.opacity(0.75))
                }

                Spacer(minLength: 8)
            }

            if let count = HowToPrayData.prayerCounts[prayer.id] {
                Text(count)
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
            }

            ZStack(alignment: .topLeading) {
                if let revealed {
                    practiceLines(prayer, revealed: revealed)
                        .transition(.opacity)
                } else {
                    PrayerText(
                        content: prayer.formattedContent(for: settings.prayerLanguage),
                        size: 17,
                        alignment: .leading
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
                }
            }
            .animation(Motion.crossfade, value: revealed)

            // A prayer of one line — the Sign of the Cross — has nothing
            // to give a line at a time
            if practiceLineList(prayer).count > 1 {
                HStack(spacing: 10) {
                    if revealed == nil {
                        practiceButton("Say it with me", icon: "ph-hands-praying", outlined: true) {
                            practice[prayer.id] = 1
                        }
                    } else {
                        let total = practiceLineList(prayer).count
                        if (revealed ?? 0) < total {
                            practiceButton("Next line", icon: "ph-caret-down", outlined: true) {
                                practice[prayer.id] = (revealed ?? 0) + 1
                            }
                        } else {
                            practiceButton("Again", icon: "ph-arrow-counter-clockwise", outlined: true) {
                                practice[prayer.id] = 1
                            }
                        }
                        practiceButton("Show all", icon: nil, outlined: false) {
                            practice[prayer.id] = nil
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            shape.fill(
                isFirst
                    ? AnyShapeStyle(LinearGradient(colors: [AppColors.gold.opacity(0.14), AppColors.cardBackground.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(AppColors.cardBackground.opacity(0.5))
            )
        )
        .overlay(shape.strokeBorder(AppColors.gold.opacity(isFirst ? 0.45 : 0.18), lineWidth: AppLine.hairline))
    }

    /// The lines practised: the reader's own language, or English when
    /// the prayer language is bilingual — one voice at a time to learn by.
    /// Only what is said aloud: a [rubric] line is an instruction, not a
    /// line to learn, and the book's marks — ℣ ℟ ✠, a canticle's
    /// pointing asterisk — are for the eye, so they fall away here.
    private func practiceLineList(_ prayer: BilingualConsecrationPrayer) -> [String] {
        let text = settings.prayerLanguage == .latin ? prayer.content.latin : prayer.content.english
        return text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !($0.hasPrefix("[") && $0.hasSuffix("]")) }
            .map { Self.spoken($0) }
            .filter { !$0.isEmpty }
    }

    /// A line of prayer-book markup as it is said
    private static func spoken(_ line: String) -> String {
        var line = line
        for mark in ["℣.", "℟.", "℣", "℟", "✠"] {
            line = line.replacingOccurrences(of: mark, with: "")
        }
        line = line.replacingOccurrences(of: " * ", with: " ")
        return line
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
    }

    /// The lines given so far, the next one waiting as a veiled bar
    private func practiceLines(_ prayer: BilingualConsecrationPrayer, revealed: Int) -> some View {
        let lines = practiceLineList(prayer)

        return VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if index < revealed {
                    Text(line)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(index == revealed - 1 ? AppColors.goldLight : AppColors.cream.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                } else if index == revealed {
                    HStack(spacing: 8) {
                        Capsule()
                            .fill(AppColors.gold.opacity(0.18))
                            .frame(height: 12)
                        Text("say it, then reveal")
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(AppColors.textSecondary.opacity(0.8))
                            .fixedSize()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.crossfade, value: revealed)
    }

    /// Practice is never the page's act — the foot's Continue is the one
    /// filled gold — so its buttons are a gold rim at most, and bare type
    /// for the way back to the whole prayer
    private func practiceButton(_ title: String, icon: String?, outlined: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(Motion.crossfade) { action() }
        } label: {
            HStack(spacing: 6) {
                if let icon { AppIcon(icon, size: 11) }
                Text(title.uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(1.6)
                    .contentTransition(.opacity)
            }
            .foregroundColor(outlined ? AppColors.goldLight : AppColors.gold.opacity(0.75))
            .padding(.horizontal, 14)
            .frame(height: 36)
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(outlined ? 0.5 : 0), lineWidth: AppLine.hairline))
            .frame(minHeight: 44)
            .contentShape(Capsule())
        }
        .buttonStyle(GoldCTAButtonStyle())
    }

    // MARK: - Lesson III: The Mysteries

    private var mysteriesLesson: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReadingText(
                text: "A mystery is a moment in the life of Jesus and Mary — His birth, His agony in the garden, His rising. There are twenty, in four sets of five, and one set is prayed each day. While your lips say the Hail Marys of a decade, your mind stays with its mystery.",
                size: 17,
                showsDropCap: true
            )
            .padding(.horizontal, 24)
            .padding(.top, 22)

            sectionLabel("The four sets")
            VStack(spacing: 16) {
                ForEach([MysteryCategory.joyful, .sorrowful, .glorious, .luminous], id: \.self) { category in
                    mysteryCard(category)
                }
            }
            .padding(.horizontal, 20)

            sectionLabel("How to dwell on a mystery")
            VStack(alignment: .leading, spacing: 22) {
                dwell("I", "Name it", "Say the mystery's name before the decade: \u{201C}The first Joyful Mystery, the Annunciation.\u{201D}")
                dwell("II", "Picture it", "Place yourself in the scene. Where is Mary? What does she see, and hear? What would you say to her Son?")
                dwell("III", "Ask for its grace", "Each mystery teaches a virtue — humility, patience, faith. Ask for it as you begin the ten Hail Marys.")
            }
            .padding(.horizontal, 24)

            sectionLabel("This week")
            week
                .padding(.horizontal, 20)
        }
    }

    /// A set of mysteries in its painting: its name, what it holds, its
    /// five scenes, and the days it is prayed
    private func mysteryCard(_ category: MysteryCategory) -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let mysteries = MysteryData.mysteries(for: category)

        return Button {
            router.push(.guidedRosary(category))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    CachedAssetImage(category.cardImageName, focal: category.cardFocalPoint)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(Self.days(for: category).uppercased())
                            .font(AppFonts.labelFont(8.5))
                            .tracking(2)
                            .foregroundColor(AppColors.goldLight)

                        Text(category.devotionTitle)
                            .font(AppFonts.titleFont(22))
                            .foregroundColor(.white)

                        Text(category.subtitle)
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(16)
                }
                .frame(height: 150)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(mysteries.enumerated()), id: \.offset) { index, mystery in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1)")
                                .font(AppFonts.titleFont(13))
                                .foregroundColor(AppColors.gold)
                                .frame(width: 16, alignment: .leading)

                            Text(mystery.name)
                                .font(AppFonts.readingFont(16))
                                .foregroundColor(AppColors.cream.opacity(0.9))

                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(16)

                // What a tap does, said on the card: it prays these
                // mysteries as your first Rosary
                HStack(spacing: 8) {
                    AppIcon("ph-play-fill", size: 10)
                    Text("PRAY THESE")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                    Spacer(minLength: 0)
                    AppIcon("ph-caret-right", size: 11)
                }
                .foregroundColor(AppColors.gold.opacity(0.8))
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.14))
                        .frame(height: AppLine.hairline)
                }
            }
            .background(shape.fill(AppColors.cardBackground.opacity(0.55)))
            .clipShape(shape)
            .overlay(shape.strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline))
            .contentShape(shape)
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Prays the \(category.devotionTitle) as your first Rosary")
    }

    /// The weekdays a set is prayed on, read from the schedule the app keeps
    private static func days(for category: MysteryCategory) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let sunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) ?? today
        let names = (1..<7).compactMap { offset -> String? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: sunday),
                  ScheduleService.category(for: day) == category else { return nil }
            return weekdayFormatter.string(from: day)
        }
        if category == .luminous { return "Any day you choose" }
        let sundays: String
        switch category {
        case .joyful:    sundays = "Sundays of Advent"
        case .sorrowful: sundays = "Sundays of Lent"
        case .glorious:  sundays = "most Sundays"
        default:         sundays = ""
        }
        return (names + [sundays]).filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private func dwell(_ numeral: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(numeral)
                .font(AppFonts.titleFont(24))
                .foregroundColor(AppColors.goldLight)
                .frame(width: 42, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.titleFont(17))
                    .foregroundColor(AppColors.cream)

                Text(text)
                    .font(AppFonts.readingFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.8))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// This week, Sunday to Saturday, a day to a row: the day, the set's
    /// glyph and its name in full, today ringed in gold — a ring, not a
    /// fill, since the foot's gold act stands just beneath. A day opens
    /// your first Rosary on its mysteries.
    private var week: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let sunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) ?? today
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: sunday) }

        return VStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                let category = ScheduleService.category(for: day)
                let isToday = calendar.isDate(day, inSameDayAs: today)
                let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

                Button {
                    router.push(.guidedRosary(category))
                } label: {
                    HStack(spacing: 12) {
                        Text(Self.weekdayFormatter.string(from: day))
                            .font(AppFonts.readingFont(16))
                            .foregroundColor(isToday ? AppColors.goldLight : AppColors.cream.opacity(0.75))
                            .frame(width: 96, alignment: .leading)

                        AppIcon(category.iconName, size: 15)
                            .foregroundColor(AppColors.gold.opacity(isToday ? 1 : 0.75))

                        Text(category.devotionTitle)
                            .font(AppFonts.readingFont(16))
                            .foregroundColor(isToday ? AppColors.goldLight : AppColors.cream.opacity(0.92))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Spacer(minLength: 6)

                        if isToday {
                            Text("TODAY")
                                .font(AppFonts.labelFont(10))
                                .tracking(2)
                                .foregroundColor(AppColors.gold)
                        }

                        AppIcon("ph-caret-right", size: 11)
                            .foregroundColor(AppColors.gold.opacity(0.55))
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)
                    .overlay(shape.strokeBorder(AppColors.gold.opacity(isToday ? 0.7 : 0), lineWidth: AppLine.hairline))
                    .overlay(alignment: .bottom) {
                        // Rules between the days, left off beside the ring
                        if index < days.count - 1, !isToday,
                           !calendar.isDate(days[index + 1], inSameDayAs: today) {
                            Rectangle()
                                .fill(AppColors.gold.opacity(0.12))
                                .frame(height: AppLine.hairline)
                                .padding(.horizontal, 14)
                        }
                    }
                    .contentShape(shape)
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(Self.weekdayFormatter.string(from: day)): the \(category.devotionTitle)\(isToday ? ", today" : "")")
                .accessibilityHint("Prays them as your first Rosary")
            }
        }
    }

    // MARK: - Foot

    /// On to the next lesson — in place of this one — or, after the
    /// last, the first Rosary
    private var foot: some View {
        VStack(spacing: 14) {
            OrnamentDivider()
                .frame(width: 120)

            if let next = RosaryLesson(rawValue: lesson + 1) {
                Text("NEXT · LESSON \(next.numeral)")
                    .font(AppFonts.labelFont(9))
                    .tracking(2.4)
                    .foregroundColor(AppColors.gold.opacity(0.8))

                Text(next.title)
                    .font(AppFonts.titleFont(20))
                    .foregroundColor(AppColors.cream)

                GoldCTAButton(title: "Continue", glyph: .chevron, fullWidth: false) {
                    router.pop()
                    router.push(.rosaryLesson(next.rawValue))
                }
                .padding(.top, 4)
            } else {
                Text("THE COURSE IS DONE")
                    .font(AppFonts.labelFont(9))
                    .tracking(2.4)
                    .foregroundColor(AppColors.gold.opacity(0.8))

                Text("Your First Rosary")
                    .font(AppFonts.titleFont(20))
                    .foregroundColor(AppColors.cream)

                GoldCTAButton(title: "Begin", glyph: .play, fullWidth: false) {
                    router.pop()
                    router.push(.guidedRosary(ScheduleService.categoryForToday()))
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        RosaryLessonView(lesson: 1)
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
