//
//  PrayerIntentionSheet.swift
//  Lumen Viae
//
//  Editor for "What draws you here" — the intentions first chosen during
//  onboarding. They decide which pool of copy the daily reminder draws
//  from (see ReminderMessages.swift), so this has to stay changeable: what
//  drew someone to the Rosary in their first week is rarely what keeps
//  them at it a year on.
//
//  Multi-select, and selecting nothing is allowed — reminders simply fall
//  back to the neutral pool.
//

import SwiftUI

// MARK: - PrayerIntentionSheet

struct PrayerIntentionSheet: View {

    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // Scrolls so the last intention and the note are never cut where
        // the two-line title stands taller than the medium detent
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    kicker: "Reminders",
                    title: "What Brings You to the Rosary",
                    lead: "Choose any that fit. Your reminders follow them."
                )

                ForEach(PrayerIntention.allCases) { intention in
                    let chosen = userSettings.hasIntention(intention)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            userSettings.toggleIntention(intention)
                        }
                    } label: {
                        SheetRow(
                            intention.displayName,
                            detail: intention.detail,
                            accessory: chosen ? .check : .none,
                            isLit: chosen,
                            // The details were free to wrap before; a
                            // narrow phone shouldn't lose their ends
                            detailLineLimit: 2
                        )
                    }
                    .buttonStyle(SacredCardButtonStyle())
                    .accessibilityAddTraits(chosen ? .isSelected : [])
                }

                SheetNote("Choose none and your reminders use a general set of words.")
            }
        }
        .sheetGround()
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    PrayerIntentionSheet()
        .environment(UserSettings.shared)
}
