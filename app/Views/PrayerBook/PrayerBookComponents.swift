//
//  PrayerBookComponents.swift
//  Lumen Viae
//
//  The Prayer Book's own furniture: the silk ribbon a prayer is kept
//  with, the ruled prayer row, the strip of the day's three hours, and
//  the schedule a surface naming the hour's order redraws on. The
//  Prayers page's own pieces are in PrayersComponents.swift.
//

import SwiftUI

// MARK: - The Ribbon

/// A silk marker hanging from the head of the page, cut in a swallowtail
/// at its foot — what a printed missal keeps its places with.
struct RibbonShape: Shape {
    /// How deep the swallowtail's notch is cut, as a share of the width
    var notch: CGFloat = 0.55

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cut = rect.width * notch
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The ribbon drawn at rest or kept: a faint gold outline when the
/// prayer is not kept, a length of red silk when it is.
struct RibbonMark: View {
    let kept: Bool
    var width: CGFloat = 12
    var restLength: CGFloat = 18
    var keptLength: CGFloat = 28

    var body: some View {
        ZStack(alignment: .top) {
            RibbonShape()
                .fill(Rubric.red.opacity(kept ? 1 : 0))
            RibbonShape()
                .stroke(
                    kept ? AppColors.gold.opacity(0.35) : AppColors.gold.opacity(0.6),
                    lineWidth: AppLine.hairline * 1.5
                )
        }
        .frame(width: width, height: kept ? keptLength : restLength)
        .shadow(color: .black.opacity(kept ? 0.35 : 0), radius: 2, y: 1)
        .frame(height: keptLength, alignment: .top)
    }
}

/// The prayer page's ribbon: tap to keep the prayer, and it drops into
/// the book; tap again to take it out. What a ribbon does is said once
/// in words as it drops.
struct RibbonToggle: View {
    let prayerID: String
    var onChange: (Bool) -> Void = { _ in }

    private var store = PrayerBookStore.shared

    init(prayerID: String, onChange: @escaping (Bool) -> Void = { _ in }) {
        self.prayerID = prayerID
        self.onChange = onChange
    }

    var body: some View {
        let kept = store.isKept(prayerID)
        Button {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                store.toggleRibbon(prayerID)
            }
            onChange(store.isKept(prayerID))
        } label: {
            // Centred as a bookmark in the toolbar's round glass: a
            // ribbon hung from the top of the circle read as a letter
            RibbonMark(kept: kept, width: 12, restLength: 19, keptLength: 22)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .sensoryFeedback(.selection, trigger: kept)
        .accessibilityLabel(kept ? "Saved" : "Save this prayer")
        .accessibilityHint(kept ? "Removes it from Saved" : "Adds it to Saved on the Prayers tab")
    }
}

// MARK: - Prayer Row

/// One prayer in a ruled list: its name, its Latin, and the reader's own
/// marks at the trailing edge — a ribbon if kept, BY HEART if known,
/// and whatever the list wants to say of it (OF THE SEASON).
struct BookPrayerRow: View {
    let prayer: BookPrayer
    var number: Int? = nil
    var badge: String? = nil
    var showsRule: Bool = true
    let action: () -> Void

    private var store = PrayerBookStore.shared

    init(
        prayer: BookPrayer,
        number: Int? = nil,
        badge: String? = nil,
        showsRule: Bool = true,
        action: @escaping () -> Void
    ) {
        self.prayer = prayer
        self.number = number
        self.badge = badge
        self.showsRule = showsRule
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 14) {
                    // The numeral stands on the title's line, as the
                    // contents page sets it — centred on the row, it
                    // floated between the title and its Latin
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        if let number {
                            Text(LiturgicalCalendarFormat.roman(number))
                                .font(AppFonts.titleFont(13))
                                .foregroundColor(AppColors.gold.opacity(0.85))
                                .frame(width: 30, alignment: .leading)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(prayer.title)
                                .font(AppFonts.readingFont(17))
                                .foregroundColor(AppColors.cream)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            if let second = prayer.secondTitle {
                                Text(second)
                                    .font(AppFonts.readingItalicFont(13.5))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 10) {
                        if let badge {
                            Text(badge.uppercased())
                                .font(AppFonts.labelFont(8))
                                .tracking(1.6)
                                .foregroundColor(AppColors.gold)
                                .fixedSize()
                        }
                        if store.isByHeart(prayer.id) {
                            ByHeartMark()
                        }
                        if store.isKept(prayer.id) {
                            RibbonMark(kept: true, width: 7, restLength: 12, keptLength: 16)
                                .accessibilityLabel("Saved")
                        }
                        AppIcon("ph-caret-right", size: 11)
                            .foregroundColor(AppColors.gold.opacity(0.5))
                    }
                }
                .padding(.vertical, 12)
                .frame(minHeight: 56)

                if showsRule {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.12))
                        .frame(height: AppLine.hairline)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// "LEARNED" beside a sealed check — the reader's own mark that they
/// know a prayer by heart, never a score
struct ByHeartMark: View {
    var body: some View {
        HStack(spacing: 4) {
            AppIcon("ph-seal-check-fill", size: 11)
            Text("LEARNED")
                .font(AppFonts.labelFont(7.5))
                .tracking(1.4)
        }
        .foregroundColor(AppColors.gold.opacity(0.85))
        .fixedSize()
        .accessibilityLabel("Learned by heart")
    }
}

// MARK: - When the Hour Turns

/// Redraws a surface that names the book's hour — home's row, the
/// Chapel's tile — at the moments that hour turns (`PrayerBook.nextTurn`).
/// They are not the Office's hours, which `CanonicalClock` wakes for, and
/// read off the canonical clock alone home said THE ANGELUS · AT SIX
/// until midnight while the book itself opened on Night Prayers.
nonisolated struct PrayerBookHourSchedule: TimelineSchedule {
    func entries(from startDate: Date, mode: TimelineScheduleMode) -> UnfoldFirstSequence<Date> {
        sequence(first: startDate) { PrayerBook.nextTurn(after: $0) }
    }
}

// MARK: - The Day's Three Hours

/// Morning, the Angelus and Night as three stations on one line: the
/// hour it is lit, an hour offered today sealed, and each a door.
struct PrayerHoursStrip: View {
    let now: Date
    let onSelect: (PrayerOrder) -> Void

    private var store = PrayerBookStore.shared

    init(now: Date, onSelect: @escaping (PrayerOrder) -> Void) {
        self.now = now
        self.onSelect = onSelect
    }

    /// The station's disc, which the links between stations meet
    private static let disc: CGFloat = 40

    var body: some View {
        let current = PrayerBook.dayOrder(at: now)
        // Hung from the top, so each link meets the discs at their
        // centres however tall the names beneath them grow
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(PrayerBook.dayOrders.enumerated()), id: \.element.id) { index, order in
                if index > 0 {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.18))
                        .frame(height: AppLine.hairline)
                        .frame(minWidth: 16, maxWidth: .infinity)
                        .padding(.top, (Self.disc - AppLine.hairline) / 2)
                }
                // Before the links: the names take the width they need,
                // less a little air between them, and the links have
                // what is left
                station(order, lit: order.id == current.id)
                    .layoutPriority(1)
            }
        }
    }

    private func station(_ order: PrayerOrder, lit: Bool) -> some View {
        let offered = store.wasOffered(order.id, on: now)
        return Button { onSelect(order) } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(AppColors.gold.opacity(lit ? 0.9 : 0.3), lineWidth: lit ? 1.2 : AppLine.hairline)
                        .background(Circle().fill(AppColors.gold.opacity(lit ? 0.12 : 0)))
                        .frame(width: Self.disc, height: Self.disc)
                        .shadow(color: AppColors.gold.opacity(lit ? 0.45 : 0), radius: 8)
                    AppIcon(offered ? "ph-seal-check-fill" : order.icon, size: 17)
                        .foregroundColor(AppColors.gold.opacity(lit || offered ? 1 : 0.55))
                }
                // Gives way at the larger text sizes rather than running
                // off the edge of the screen and into its neighbour
                Text(shortName(order).uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(1.6)
                    .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(minWidth: 64, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("\(order.title(on: now))\(lit ? ", now" : "")\(offered ? ", prayed today" : "")")
    }

    /// Named as the Prayers page's strip names its stations — MORNING,
    /// NOON or EVENING, NIGHT — never by a prayer's Latin name
    private func shortName(_ order: PrayerOrder) -> String {
        PrayerBook.hourName(of: order, at: now)
    }
}

// MARK: - Plain words

/// A prayer's words with the book's marks taken out — for learning it by
/// heart, where a ℣ or a rubric is not something to memorise.
enum PrayerWords {

    /// The prayer's lines as they are said, stanza by stanza: rubrics
    /// dropped, ℣ ℟ ✠ and the mediant's asterisk removed, and a litany's
    /// response said after every invocation beneath its head.
    static func stanzas(of text: String) -> [[String]] {
        var result: [[String]] = []
        var current: [String] = []
        var response: String?

        func flush() {
            if !current.isEmpty { result.append(current) }
            current = []
            response = nil
        }

        for raw in text.components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { flush(); continue }
            if PrayerMarkup.isRubric(line) { continue }

            if PrayerMarkup.isLitany(line) {
                let parts = PrayerMarkup.litanyParts(line)
                response = parts.response
                current.append(clean("\(parts.invocation) \(parts.response)"))
            } else if let response, !line.hasPrefix("℣"), !line.hasPrefix("℟") {
                current.append(clean("\(line) \(response)"))
            } else {
                current.append(clean(line))
            }
        }
        flush()
        return result.filter { !$0.isEmpty }
    }

    private static func clean(_ line: String) -> String {
        line
            .replacingOccurrences(of: "℣.", with: "")
            .replacingOccurrences(of: "℟.", with: "")
            .replacingOccurrences(of: "℣", with: "")
            .replacingOccurrences(of: "℟", with: "")
            .replacingOccurrences(of: "✠", with: "")
            .replacingOccurrences(of: " * ", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}
