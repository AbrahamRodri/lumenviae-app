//
//  HowToPrayRosaryView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  HOW TO PRAY THE ROSARY
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A short course for someone who has never prayed the Rosary.
//
//  The page is the course's front: a drawn rosary as its hero, the beads
//  lighting one after another the way the fingers will travel them; a
//  welcome; and the course itself as a path of three lessons
//  (`RosaryLessonView` — the beads and the order, the prayers, the
//  mysteries) leading to its last step, the guided first Rosary
//  (`GuidedRosaryView`). A lesson once opened is marked on the path, so
//  a reader coming back sees where they were — a mark, never a score —
//  and the first one not yet opened reads as next: its ring lit and
//  NEXT in its kicker. With all three opened, next is the first Rosary.
//
//  Beneath the path: the questions beginners ask, and where to go
//  deeper.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - Lessons

enum RosaryLesson: Int, CaseIterable {
    case beads, prayers, mysteries

    var title: String {
        switch self {
        case .beads:     return "The Beads and the Order"
        case .prayers:   return "The Prayers"
        case .mysteries: return "The Mysteries"
        }
    }

    var summary: String {
        switch self {
        case .beads:     return "What a rosary is, each part of it, and what is said where."
        case .prayers:   return "Eight prayers make the whole Rosary. Read them, then say them with the page until they are yours."
        case .mysteries: return "The scenes from the Gospel you think about while you pray, and which to pray each day."
        }
    }

    var numeral: String { ["I", "II", "III"][rawValue] }

    /// Which lessons have been opened, as a set of raw values
    static let seenKey = "howToPray.seenLessons"

    static func seen(in stored: String) -> Set<Int> {
        Set(stored.split(separator: ",").compactMap { Int($0) })
    }

    static func marking(_ lesson: Int, in stored: String) -> String {
        var set = seen(in: stored)
        set.insert(lesson)
        return set.sorted().map(String.init).joined(separator: ",")
    }
}

// MARK: - HowToPrayRosaryView

struct HowToPrayRosaryView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @AppStorage(RosaryLesson.seenKey) private var seenLessons: String = ""

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero
                        .devotionalEntrance()

                    Text("If you have never prayed the Rosary, begin here. You need no beads — your fingers will do — and nothing by heart. Three short lessons, and then your first Rosary, with every word in front of you.")
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .lineSpacing(ReadingTypography.lineSpacing(for: 17) - 2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 30)
                        .padding(.top, 22)
                        .devotionalEntrance(delay: 0.08)

                    coursePath
                        .padding(.horizontal, 20)
                        .padding(.top, 36)
                        .devotionalEntrance(delay: 0.12)

                    questions
                        .padding(.top, 56)

                    deeper
                        .padding(.top, 48)
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
    }

    // MARK: - Hero

    /// The rosary itself, the beads lighting one after another in the
    /// order they are prayed — the whole course in one picture
    private var hero: some View {
        VStack(spacing: 14) {
            Text("FOR THE FIRST TIME")
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            Text("How to Pray\nthe Rosary")
                .font(AppFonts.titleFont(32))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            TravellingRosary()
                .frame(width: 200)
                .background {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppColors.gold.opacity(0.14), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 170
                            )
                        )
                        .frame(width: 340, height: 340)
                        .offset(y: -30)
                        .allowsHitTesting(false)
                }
                .padding(.top, 12)
        }
        .padding(.top, 10)
    }

    // MARK: - The Course

    /// The lessons as stations on one path, the last a gold one: the
    /// first Rosary
    private var coursePath: some View {
        let seen = RosaryLesson.seen(in: seenLessons)
        let next = RosaryLesson.allCases.first { !seen.contains($0.rawValue) }

        return VStack(alignment: .leading, spacing: 0) {
            Text("THE COURSE")
                .font(AppFonts.labelFont(9.5))
                .tracking(2.8)
                .foregroundColor(AppColors.gold.opacity(0.85))
                .padding(.leading, 4)
                .padding(.bottom, 16)

            ForEach(RosaryLesson.allCases, id: \.rawValue) { lesson in
                let isNext = lesson == next

                station(
                    marker: seen.contains(lesson.rawValue) ? .done : .numeral(lesson.numeral),
                    kicker: isNext ? "Next · Lesson \(lesson.numeral)" : "Lesson \(lesson.numeral)",
                    title: lesson.title,
                    summary: lesson.summary,
                    isNext: isNext,
                    opened: seen.contains(lesson.rawValue)
                ) {
                    router.push(.rosaryLesson(lesson.rawValue))
                }
            }

            finalStation(isNext: next == nil)
        }
    }

    private enum Marker {
        case numeral(String)
        case done
    }

    private func station(
        marker: Marker,
        kicker: String,
        title: String,
        summary: String,
        isNext: Bool,
        opened: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppColors.background)
                        .frame(width: 48, height: 48)
                        .overlay(Circle().fill(AppColors.gold.opacity(isNext ? 0.14 : 0)))
                        .overlay(
                            Circle().strokeBorder(
                                isNext ? AppColors.goldLight : AppColors.gold.opacity(0.7),
                                lineWidth: isNext ? 1.5 : AppLine.hairline
                            )
                        )
                        .shadow(color: AppColors.gold.opacity(isNext ? 0.35 : 0), radius: 8)

                    switch marker {
                    case .numeral(let numeral):
                        Text(numeral)
                            .font(AppFonts.titleFont(17))
                            .foregroundColor(AppColors.goldLight)
                    case .done:
                        AppIcon("ph-check", size: 18)
                            .foregroundColor(AppColors.goldLight)
                    }
                }
                .frame(width: 48)

                VStack(alignment: .leading, spacing: 5) {
                    Text(kicker.uppercased())
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                        .foregroundColor(isNext ? AppColors.goldLight : AppColors.gold.opacity(0.8))

                    Text(title)
                        .font(AppFonts.titleFont(18))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(summary)
                        .font(AppFonts.readingItalicFont(14.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
                .padding(.bottom, 30)

                Spacer(minLength: 4)

                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.gold.opacity(0.6))
                    .padding(.top, 18)
            }
            .background(alignment: .topLeading) {
                // The path, from this station down to the next
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.gold.opacity(0.5), AppColors.gold.opacity(0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: AppLine.hairline)
                    .padding(.top, 48)
                    .padding(.leading, 24 - AppLine.hairline / 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(opened ? "Opened" : "Not yet opened")
    }

    /// The course's end: the first Rosary, the page's one gold act —
    /// named next once all three lessons have been opened
    private func finalStation(isNext: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.goldGradient)
                    .frame(width: 48, height: 48)
                    .shadow(color: AppColors.gold.opacity(0.5), radius: 10)

                AppIcon("ch-rosary", size: 20)
                    .foregroundColor(AppColors.background)
            }
            .frame(width: 48)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(isNext ? "NEXT" : "THEN")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.8))

                    Text("Your First Rosary")
                        .font(AppFonts.titleFont(20))
                        .foregroundColor(AppColors.goldLight)

                    Text("Prayed with a guide: every step, every word, and the beads drawn so you always know where you are.")
                        .font(AppFonts.readingItalicFont(14.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                GoldCTAButton(title: "Begin", glyph: .play, fullWidth: false) {
                    router.push(.guidedRosary(ScheduleService.categoryForToday()))
                }
                .padding(.top, 4)
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Questions

    private var questions: some View {
        let shelf = HowToPrayData.questions

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("QUESTIONS")
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.8)
                    .foregroundColor(AppColors.gold.opacity(0.85))

                Text("What people wonder before their first Rosary")
                    .font(AppFonts.titleFont(20))
                    .foregroundColor(AppColors.cream)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 0) {
                ForEach(Array(shelf.entries.enumerated()), id: \.element.id) { index, question in
                    Button {
                        router.push(.libraryReading(id: question.id))
                    } label: {
                        HStack(alignment: .center, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(question.title)
                                    .font(AppFonts.readingFont(17))
                                    .foregroundColor(AppColors.cream)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(question.detail)
                                    .font(AppFonts.readingItalicFont(14))
                                    .foregroundColor(AppColors.goldLight.opacity(0.85))
                            }

                            Spacer(minLength: 8)

                            AppIcon("ph-caret-right", size: 11)
                                .foregroundColor(AppColors.gold.opacity(0.5))
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .contentShape(Rectangle())
                        .overlay(alignment: .bottom) {
                            if index < shelf.entries.count - 1 {
                                Rectangle()
                                    .fill(AppColors.gold.opacity(0.12))
                                    .frame(height: AppLine.hairline)
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.cardBackground.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(AppColors.gold.opacity(0.18), lineWidth: AppLine.hairline)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Deeper

    /// For after the first Rosary: Montfort's counsel, the Rosary's
    /// history, and Scripture on the beads
    private var deeper: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("GOING DEEPER")
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.8)
                    .foregroundColor(AppColors.gold.opacity(0.85))

                Text("When the beads are familiar")
                    .font(AppFonts.titleFont(20))
                    .foregroundColor(AppColors.cream)
            }
            .padding(.horizontal, 24)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(HowToPrayData.methods.entries) { reading in
                    deeperTile(icon: "ch-rosary", title: reading.title, note: reading.detail) {
                        router.push(.libraryReading(id: reading.id))
                    }
                }
                deeperTile(icon: "ch-lily", title: "Our Lady's Psalter", note: "How the Rosary came to be") {
                    router.push(.libraryReading(id: "psalter"))
                }
                deeperTile(icon: "ch-bible", title: "The Scriptural Rosary", note: "A verse for every bead") {
                    router.push(.scripturalRosary)
                }
                deeperTile(icon: "lv-breviary", title: "In Scripture", note: "Each mystery's passage") {
                    router.push(.scripture)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func deeperTile(icon: String, title: String, note: String, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        return Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                AppIcon(icon, size: 18)
                    .foregroundColor(AppColors.gold)

                Spacer(minLength: 14)

                Text(title)
                    .font(AppFonts.readingFont(16))
                    .foregroundColor(AppColors.cream)
                    .fixedSize(horizontal: false, vertical: true)

                Text(note)
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .padding(14)
            .overlay(shape.strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline))
            .contentShape(shape)
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - TravellingRosary

/// The drawn rosary with a light travelling its beads in the order they
/// are prayed, round and round. Still under Reduce Motion.
private struct TravellingRosary: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            RosaryDiagram()
        } else {
            TimelineView(.periodic(from: .now, by: 0.22)) { context in
                let steps = RosaryMap.traversal.count
                let index = Int(context.date.timeIntervalSinceReferenceDate / 0.22) % steps
                RosaryDiagram(highlighted: [RosaryMap.traversal[index]])
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HowToPrayRosaryView()
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
