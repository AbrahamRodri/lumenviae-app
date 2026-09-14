//
//  OfficeReaderComponents.swift
//  Lumen Viae
//
//  The Divine Office reader's own pieces, cut from the missal's: the
//  two sheets the hour's chrome raises — Reading (the Aa settings) and
//  the hour's index (☰) — and the small facts about a day both the
//  ledger and the calendar read it by.
//
//  Everything here stands on `MissalSheetShell` and `MissalSheetChip`,
//  so a setting made in the breviary looks exactly like the same
//  setting made in the missal. What the office has no data for — the
//  vestment colour, posture cues, the Ordinary's tier — is simply
//  absent rather than guessed at.
//

import SwiftUI

// MARK: - Sky Colours

/// Each hour's place in the day, said as a colour — night indigo for
/// Matins, dawn rose for Lauds, the sun's gold through the day hours,
/// dusk violet for Vespers, and night again at Compline. A display
/// concern, so it lives with the pages rather than in the model. The
/// swatches are muted to sit on the dark ground, like the vestment
/// swatches — a mark, not a flag.
extension CanonicalHour {
    var skyColor: Color {
        switch self {
        case .matins:   return Color(hex: "#454568")  // deep night
        case .lauds:    return Color(hex: "#a06b7a")  // first light
        case .prime:    return Color(hex: "#c99a5e")  // early sun
        case .terce:    return Color(hex: "#d9b96a")  // morning gold
        case .sext:     return Color(hex: "#e3cf8a")  // noon
        case .nones:    return Color(hex: "#c98d56")  // afternoon amber
        case .vespers:  return Color(hex: "#8a6b9e")  // dusk violet
        case .compline: return Color(hex: "#3a3a5e")  // night
        }
    }
}

// MARK: - LitHourMark

/// The disc that marks the hour being prayed *now* — on the home
/// ledger's Office row and in the arch's crown.
///
/// Held apart from the eight sky colours deliberately. Those say *which*
/// hour; this one says *now*, and Compline marking itself in its own
/// night blue would leave the one unlit mark on the page it was put
/// there to light.
enum LitHourMark {
    static let disc = Color(hex: "#d9b96a")
}

// MARK: - The Scribe's Close

extension CanonicalHour {

    /// "Here ends Lauds" — the close a scribe wrote under a finished
    /// hour, answering the "Incipit" the engine itself names the first
    /// section by. The verb agrees with its hour: Laudes and Vesperae
    /// are plural and take *expliciunt*.
    var explicit: String {
        let plural = self == .lauds || self == .vespers
        return "\(plural ? "EXPLICIUNT" : "EXPLICIT") \(latinName.uppercased())"
    }
}

// MARK: - OfficeRank

/// The class of a day, read off the engine's own wording ("I. classis",
/// "II. classis", "Feria"). The missal's calendar carries a vestment
/// dot; the office names no colour, so its calendar marks the day's
/// rank instead — the greater feasts standing out of the run of ferias,
/// which is what a finger down the ribbon is looking for.
enum OfficeRank {
    case feria
    case fourth
    case third
    case second
    case first

    init(_ rank: String?) {
        let text = rank?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        if text.hasPrefix("I.") || text.hasPrefix("I ") || text == "I" {
            self = .first
        } else if text.hasPrefix("II.") || text.hasPrefix("II ") || text == "II" {
            self = .second
        } else if text.hasPrefix("III.") || text.hasPrefix("III ") || text == "III" {
            self = .third
        } else if text.hasPrefix("IV.") || text.hasPrefix("IV ") || text == "IV" {
            self = .fourth
        } else {
            self = .feria
        }
    }

    /// How brightly the day's mark burns in the month grid. A feria
    /// carries no mark at all — an unlit dot on every ordinary day is
    /// just noise across the month.
    var markOpacity: Double {
        switch self {
        case .first: return 0.95
        case .second: return 0.62
        case .third: return 0.34
        case .fourth: return 0.2
        case .feria: return 0
        }
    }

    var markSize: CGFloat {
        switch self {
        case .first: return 5.5
        case .second: return 5
        default: return 4
        }
    }

    /// The class in English. The engine answers in Latin ("III.
    /// classis"), and Latin belongs in the prayer text, not in the
    /// chrome above it — so the landing and the reader both name the day
    /// through here rather than printing what arrived.
    var englishLabel: String? {
        switch self {
        case .first: return "First class"
        case .second: return "Second class"
        case .third: return "Third class"
        case .fourth: return "Fourth class"
        case .feria: return nil
        }
    }
}

// MARK: - OfficeReadingSheet

/// The Aa sheet: language, bilingual layout, and the reading size. The
/// missal's sheet with the parts the breviary has no data for taken
/// out — no posture cues, no Ordinary to fold in, no sung form.
///
/// The size and the layout are the missal's own settings, deliberately:
/// the two are the same kind of page, and a reader who sets the type
/// once should not have to set it again in the other book.
struct OfficeReadingSheet: View {

    @Environment(UserSettings.self) private var settings

    /// The bilingual order restored when "Both" is re-chosen, owned by
    /// the hour screen so a Latin detour never loses it.
    @Binding var preferredBilingual: PrayerLanguage

    var body: some View {
        @Bindable var settings = settings

        return MissalSheetShell(kicker: "Divine Office", title: "Reading") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    MissalSheetChipGroup("Language") {
                        MissalSheetChip(
                            title: "Latin",
                            isSelected: settings.prayerLanguage == .latin
                        ) { choose(.latin) }

                        MissalSheetChip(
                            title: "English",
                            isSelected: settings.prayerLanguage == .english
                        ) { choose(.english) }

                        MissalSheetChip(
                            title: "Both",
                            isSelected: settings.prayerLanguage.isBilingual
                        ) { chooseBoth() }
                    }

                    MissalSheetChipGroup("Latin and English") {
                        MissalSheetChip(
                            title: "Stacked",
                            isSelected: settings.missalLayout == .interlinear
                        ) {
                            settings.missalLayoutPreference = MissalLayout.interlinear.rawValue
                        }

                        MissalSheetChip(
                            title: "Side by side",
                            isSelected: settings.missalLayout == .sideBySide
                        ) { chooseSideBySide() }
                    }

                    SheetSizeSlider(scale: $settings.missalTextScale)

                    SheetNote("The breviary and the missal are set the same way — these settings belong to both books.")
                        .padding(.top, 8)
                }
                .padding(.bottom, 36)
            }
        }
    }

    // MARK: - Choices

    private func choose(_ language: PrayerLanguage) {
        if settings.prayerLanguage.isBilingual {
            preferredBilingual = settings.prayerLanguage
        }
        settings.prayerLanguagePreference = language.rawValue
    }

    private func chooseBoth() {
        settings.prayerLanguagePreference = preferredBilingual.rawValue
    }

    /// Two columns need two languages: side by side forces Both.
    private func chooseSideBySide() {
        settings.missalLayoutPreference = MissalLayout.sideBySide.rawValue
        if !settings.prayerLanguage.isBilingual {
            settings.prayerLanguagePreference = preferredBilingual.rawValue
        }
    }
}

// MARK: - OfficeIndexSheet

/// The ☰ sheet: the hour's named sections as a ruled ledger — the one
/// being read lit and marked HERE — a tap jumps the page there and
/// puts the sheet away. Matins runs to nine lessons and nine psalms;
/// without this the only way back to the Te Deum is a thumb.
struct OfficeIndexSheet: View {

    @Environment(\.dismiss) private var dismiss

    let hour: CanonicalHour
    let sections: [OfficeReaderSection]
    let activeIndex: Int
    let onJump: (String) -> Void

    var body: some View {
        MissalSheetShell(kicker: "Divine Office", title: hour.latinName) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    let reading = readingIndex
                    ForEach(sections.named) { section in
                        row(section, isActive: section.index == reading)
                    }
                }
                .padding(.bottom, 36)
            }
        }
    }

    /// The section being read, by the one rule the rail reads by too —
    /// resolved once for the sheet rather than re-derived, with its own
    /// filtered copy of the list, for every row drawn.
    private var readingIndex: Int? {
        sections.namedSection(containing: activeIndex)?.index
    }

    private func row(_ section: OfficeReaderSection, isActive: Bool) -> some View {
        let showsBothNames = !section.englishName.isEmpty
            && !section.latinName.isEmpty
            && section.latinName.caseInsensitiveCompare(section.englishName) != .orderedSame

        // No caret on the other rows: the missal's index carries none
        // either, and the two ledgers are one kind of page
        return Button {
            onJump(section.id)
            dismiss()
        } label: {
            SheetRow(
                section.latinName.isEmpty ? section.englishName : section.latinName,
                detail: showsBothNames ? section.englishName : nil,
                accessory: isActive ? .label("Here") : .none,
                isLit: isActive
            )
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            OfficeIndexSheet(
                hour: .lauds,
                sections: OfficeReaderSection.build(from: [
                    OfficeSection(
                        latin: OfficeCell(title: "Incipit", note: nil, lines: ["℣. Deus in adiutórium"]),
                        vernacular: OfficeCell(title: "Start", note: nil, lines: ["℣. O God, come to my assistance"])
                    ),
                    OfficeSection(
                        latin: OfficeCell(title: "Psalmi", note: nil, lines: ["Psalmus 92"]),
                        vernacular: OfficeCell(title: "Psalms", note: nil, lines: ["Psalm 92"])
                    )
                ]),
                activeIndex: 1,
                onJump: { _ in }
            )
            .presentationDetents([.fraction(0.8)])
            .presentationBackground(AppColors.background)
        }
        .environment(UserSettings.shared)
}
