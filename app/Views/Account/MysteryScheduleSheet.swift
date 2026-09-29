//
//  MysteryScheduleSheet.swift
//  Lumen Viae
//
//  The choice between the two weekly schedules of mysteries: the
//  traditional one, the default, and St. John Paul II's, which gives
//  Thursday to the Luminous. Everything that names or opens "today's
//  mysteries" reads the choice through ScheduleService.
//
//  The row carries its own sheet, so Settings holds it as one line.
//

import SwiftUI

// MARK: - MysteryScheduleRow

/// Settings' row for the schedule: its name, the schedule kept, and the
/// two days that make it that schedule.
struct MysteryScheduleRow: View {

    @Environment(UserSettings.self) private var userSettings
    @State private var showSheet = false

    var body: some View {
        let schedule = userSettings.mysterySchedule

        ActionRow(
            icon: "ph-calendar-dots",
            title: MysteryScheduleSheet.title,
            subtitle: "\(schedule.title) · \(schedule.detail)"
        ) {
            showSheet = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MysteryScheduleSheet.title)
        .accessibilityValue("\(schedule.title). \(schedule.detail)")
        .accessibilityAddTraits(.isButton)
        .sheet(isPresented: $showSheet) {
            MysteryScheduleSheet()
        }
    }
}

// MARK: - MysteryScheduleSheet

struct MysteryScheduleSheet: View {

    /// What the setting is called, in Settings and on the sheet
    static let title = "Daily Mysteries"

    @Environment(UserSettings.self) private var userSettings

    var body: some View {
        // Scrolls so the note is never cut at the larger text sizes,
        // where the header and rows stand taller than the medium detent
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    kicker: "Devotion",
                    title: Self.title,
                    lead: "Which mysteries each day brings. The two schedules differ only on Thursday and Saturday."
                )

                ForEach(MysterySchedule.allCases) { schedule in
                    let chosen = userSettings.mysterySchedule == schedule

                    Button {
                        withAnimation(Motion.settle) {
                            userSettings.mysteryScheduleRaw = schedule.rawValue
                        }
                    } label: {
                        SheetRow(
                            schedule.title,
                            detail: schedule.detail,
                            accessory: chosen ? .check : .none,
                            isLit: chosen,
                            // One line on most phones; a narrow one, or
                            // the largest text, shouldn't lose Saturday
                            detailLineLimit: 2
                        )
                    }
                    .buttonStyle(SacredCardButtonStyle())
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(chosen ? [.isButton, .isSelected] : .isButton)
                }

                SheetNote("The modern schedule is St. John Paul II's, from his letter on the Rosary, Rosarium Virginis Mariae (2002). Both keep Sunday by the season: Joyful in Advent, Sorrowful in Lent, Glorious the rest of the year.")
            }
        }
        .sheetGround()
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    MysteryScheduleSheet()
        .environment(UserSettings.shared)
}
