//
//  ChantComponents.swift
//  Lumen Viae
//
//  The small pieces every chant surface shares: headings and rules, the
//  sideways strip, the setting pill and the step beads, the credit the
//  recordings carry, the rubric red and the long dates. The score, the
//  play controls, the mini player, the rows and the paintings each have
//  a file of their own beside this one.
//

import SwiftUI

// MARK: - ChantCredit

/// Who sang it, on what terms. The licence asks no attribution; the app
/// gives it, and says the adapted files are shared on the same terms,
/// which the licence does ask.
struct ChantCredit: View {
    var compact = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: compact ? .leading : .center, spacing: 8) {
            Text(ChantCatalog.credit)
                .font(AppFonts.readingItalicFont(compact ? 12.5 : 14))
                .foregroundColor(AppColors.cream.opacity(0.75))
                .multilineTextAlignment(compact ? .leading : .center)

            if !compact {
                Text(ChantCatalog.licenceNote)
                    .font(AppFonts.readingItalicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // One above the other under the accessibility sizes, where
                // side by side broke the site's name mid-word
                let links = dynamicTypeSize >= .accessibility1
                    ? AnyLayout(VStackLayout(spacing: 0))
                    : AnyLayout(HStackLayout(spacing: 18))
                links {
                    creditLink("VERBUMGLORIAE.ES", to: ChantCatalog.sourceSite)
                        .accessibilityLabel("Verbum Gloriae's website")
                    creditLink("READ THE LICENCE", to: ChantCatalog.licenceURL)
                        .accessibilityLabel("Read the licence")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: compact ? .leading : .center)
    }

    private func creditLink(_ title: String, to url: URL) -> some View {
        Link(destination: url) {
            Text(title)
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(minHeight: 44)
        }
    }
}

// MARK: - ChantSectionHeading

/// A section of a library board: a small gold kicker over its title in
/// the display face, and a line of what it is. Left-aligned, as every
/// section beneath the masthead stands.
struct ChantSectionHeading: View {
    let kicker: String?
    let title: String
    var note: String? = nil
    var titleSize: CGFloat = 21

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let kicker {
                Text(kicker.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)
            }
            Text(title)
                .font(AppFonts.titleFont(titleSize))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let note {
                Text(note)
                    .font(AppFonts.readingItalicFont(14.5))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ChantPartHeading

/// A subheading inside a section, as the Parish Book of Chant sets its
/// Masses and seasons: the name in small gold capitals with a hairline
/// running beside it to the edge, and when it is sung beneath.
struct ChantPartHeading: View {
    let title: String
    var note: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Text(title.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(1.8)
                    .foregroundColor(AppColors.gold)
                    .fixedSize(horizontal: false, vertical: true)
                ChantRule(opacity: 0.24)
            }
            if let note {
                Text(note)
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([title, note].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - ChantRule

/// The hairline under a section's heading, and between rows
struct ChantRule: View {
    var opacity: Double = 0.3

    var body: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(opacity))
            .frame(height: AppLine.hairline)
            .accessibilityHidden(true)
    }
}

// MARK: - ChantSideScroll

/// A row that runs past the glass sideways — the strip of sections, the
/// season's chips, the search's filters, the shelf of spines — fading out
/// at whichever edge has more to show, and only while it has. The
/// Office's rail fades its trailing edge for good; a row scrolled to its
/// end, or one that fits, has nothing there to hint at, and one opened on
/// its middle (the Seasons chips, centred on the season) has something at
/// both. A fade, not a scrollbar: cut by the edge, "SA…" read as a word
/// misprinted rather than a row that goes on.
struct ChantSideScroll<Content: View>: View {
    /// The fade's breadth, the Office rail's
    var fade: CGFloat = 52
    @ViewBuilder var content: Content

    @State private var more = ChantSideScrollMore()

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            content
                .onGeometryChange(for: ChantSideScrollMore.self) { geometry in
                    // Where the row stands against the scroll view's own
                    // bounds, read again as it scrolls
                    let row = geometry.frame(in: .named(ChantSideScrollMore.space))
                    let glass = geometry.bounds(of: .named(ChantSideScrollMore.space))?.width ?? row.width
                    return ChantSideScrollMore(leading: row.minX < -1, trailing: row.maxX > glass + 1)
                } action: { now in
                    withAnimation(Motion.crossfade) { more = now }
                }
        }
        .coordinateSpace(.named(ChantSideScrollMore.space))
        .mask {
            HStack(spacing: 0) {
                edge(more.leading, from: .leading)
                Color.black
                edge(more.trailing, from: .trailing)
            }
        }
    }

    /// One end of the mask: clear at the glass's edge and whole a fade's
    /// breadth in while the row goes on past it; whole throughout when
    /// it does not
    private func edge(_ goesOn: Bool, from side: HorizontalEdge) -> some View {
        ZStack {
            LinearGradient(
                colors: [.clear, .black],
                startPoint: side == .leading ? .leading : .trailing,
                endPoint: side == .leading ? .trailing : .leading
            )
            Color.black.opacity(goesOn ? 0 : 1)
        }
        .frame(width: fade)
    }
}

/// Which edges of a `ChantSideScroll` have more beyond them. Measured
/// off the main actor, so nonisolated
nonisolated struct ChantSideScrollMore: Equatable {
    static let space = "ChantSideScroll.space"

    var leading = false
    var trailing = false
}

// MARK: - ChantSettingPill

/// A work sung in more than one setting — the simple and the solemn Salve
/// Regina — as a pill of its settings, each with its length. A segmented
/// picker to VoiceOver.
struct ChantSettingPill: View {
    let settings: [Chant]
    let selected: String
    let choose: (Chant) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(settings) { chant in
                let lit = chant.id == selected
                Button {
                    choose(chant)
                } label: {
                    HStack(spacing: 6) {
                        Text(chant.settingName ?? chant.latinTitle)
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                            .lineLimit(1)
                        Text(chant.durationLabel)
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1)
                            .foregroundColor(AppColors.textSecondary)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    // 38 inside a 3pt rim: the pill stands 44 tall, a
                    // finger's reach, as drawn
                    .frame(height: 38)
                    .background(Capsule().fill(lit ? AppColors.gold.opacity(0.16) : Color.clear))
                    .contentShape(Capsule())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel("\(chant.settingName ?? chant.latinTitle), \(ChantPlayer.spoken(chant.duration))")
                .accessibilityAddTraits(lit ? [.isSelected] : [])
            }
        }
        .padding(3)
        .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline))
        .animation(Motion.choice, value: selected)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Melody")
    }
}

// MARK: - ChantStepBeads

/// The four steps of learning a chant as four beads on a thread: those
/// taken in gold, the one under way ringed, the rest at rest.
struct ChantStepBeads: View {
    let step: ChantLearningStep?
    var learned = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ChantLearningStep.allCases) { each in
                let taken = learned || (step.map { each.rawValue < $0.rawValue } ?? false)
                let here = !learned && step == each
                ZStack {
                    Circle()
                        .fill(taken ? AppColors.gold : Color.clear)
                    Circle()
                        .strokeBorder(here ? AppColors.goldLight : AppColors.gold.opacity(taken ? 0 : 0.35),
                                      lineWidth: here ? 1.5 : 1)
                }
                .frame(width: here ? 13 : 9, height: here ? 13 : 9)
                .shadow(color: here ? AppColors.gold.opacity(0.4) : .clear, radius: 4)

                if each != .onYourOwn {
                    Rectangle()
                        .fill(AppColors.gold.opacity(taken ? 0.6 : 0.2))
                        .frame(width: 14, height: 1)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(learned ? "Learned" : step.map { "Step \($0.rawValue) of 4, \($0.title)" } ?? "Not begun")
    }
}

// MARK: - ChantFlowLayout

/// Lays its subviews out in rows, wrapping to the width it is given: the
/// Types board's chants under a minute, the search filters.
nonisolated struct ChantFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let arrangement = arrange(subviews, in: proposal.width ?? .infinity)
        if let width = proposal.width, width.isFinite {
            return CGSize(width: width, height: arrangement.size.height)
        }
        return arrangement.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews, in: proposal.width ?? bounds.width)
        for (subview, origin) in zip(subviews, arrangement.origins) {
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(_ subviews: Subviews, in width: CGFloat) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}

// MARK: - Counts

extension ContentTransition {
    /// A count or a time rolls its digits to a new number, but under
    /// Reduce Motion it only changes, as every crossfade still fades
    static func chantCount(reduceMotion: Bool) -> ContentTransition {
        reduceMotion ? .identity : .numericText()
    }
}

// MARK: - ChantRubricText

/// A note in red between chants, as a printed order of service sets what
/// happens between its texts
struct ChantRubricText: View {
    let text: String
    var size: CGFloat = 14.5

    var body: some View {
        Text(text)
            .font(AppFonts.readingItalicFont(size))
            .foregroundColor(Rubric.text)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Long dates

enum ChantDates {

    private static let ordinals = [
        "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth",
        "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth",
        "eighteenth", "nineteenth", "twentieth", "twenty-first", "twenty-second", "twenty-third",
        "twenty-fourth", "twenty-fifth", "twenty-sixth", "twenty-seventh", "twenty-eighth",
        "twenty-ninth", "thirtieth", "thirty-first"
    ]

    /// "Thursday, the first of October"
    static func spelled(_ date: Date, calendar: Calendar = .current) -> String {
        let weekday = calendar.component(.weekday, from: date)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let weekdays = calendar.standaloneWeekdaySymbols
        let months = calendar.standaloneMonthSymbols
        guard weekdays.indices.contains(weekday - 1),
              months.indices.contains(month - 1),
              ordinals.indices.contains(day - 1) else {
            return date.formatted(date: .complete, time: .omitted)
        }
        return "\(weekdays[weekday - 1]), the \(ordinals[day - 1]) of \(months[month - 1])"
    }

    /// "Wednesday, October 7"
    static func feastDay(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    /// "7" and "OCT"
    static func dayAndMonth(_ date: Date) -> (day: String, month: String) {
        (date.formatted(.dateTime.day()), date.formatted(.dateTime.month(.abbreviated)).uppercased())
    }
}

// MARK: - ChantShell

extension View {
    /// The library's outline: a 16pt hairline at gold@0.24 on the bare
    /// page, no fill
    func chantShell(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
            )
    }
}
