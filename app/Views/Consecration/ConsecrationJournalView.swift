//
//  ConsecrationJournalView.swift
//  Lumen Viae
//
//  The day's reflection, written on the same surface as every other
//  journal entry in the app: the flat page, the tracked kicker, the
//  subject chip, and the full-bleed writing area of
//  `JournalEntryEditorView` — not a stack of cards of its own.
//
//  The one thing it keeps that the journal editor doesn't is the act at
//  the foot. Saving a reflection and keeping a day of the consecration
//  are not the same thing, and the day is completed whether or not a single
//  word was written.
//
//  In the stack, this screen stands *in place of* the day's readings and
//  prayers rather than on top of them: the reflection is where a day
//  ends, so leaving it leaves the day. The header's index still opens
//  any reading or prayer of the day directly.
//

import SwiftUI

// MARK: - ConsecrationJournalView

struct ConsecrationJournalView: View {

    // MARK: - Properties

    @Binding var path: [ConsecrationRoute]

    @Environment(ConsecrationViewModel.self) private var viewModel
    @FocusState private var bodyFocused: Bool

    let dayNumber: Int

    @State private var text: String = ""

    /// Flipped once the day is completed, so the haptic fires on the act
    /// rather than on every keystroke
    @State private var didCompleteDay = false

    /// The day's index — the reflection is a place in the day like any
    /// other, so it can be left for any other.
    @State private var showDayIndex = false

    @Environment(UserSettings.self) private var settings

    // MARK: - Computed Properties

    private var day: ConsecrationDay? {
        ConsecrationData.day(dayNumber)
    }

    private var phase: ConsecrationPhase? {
        day?.phase
    }

    private var isConsecrationDay: Bool {
        dayNumber == 34
    }

    private var isAlreadyComplete: Bool {
        viewModel.isDayCompleted(dayNumber)
    }

    /// The day's own question, in the slot the journal editor keeps for
    /// its invitation to write
    private var placeholderText: String {
        day?.journalPrompt ?? "Record your thoughts…"
    }

    private var subjectLine: String {
        day?.title ?? "Reflection"
    }

    private var contextLine: String {
        guard let phase else { return "Day \(dayNumber)" }
        if phase == .consecrationDay { return "Consecration Day" }
        return "Day \(dayNumber) · \(phase.displayName)"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private var formattedDate: String {
        Self.dateFormatter.string(from: Date())
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                editorHeader

                Divider()
                    .background(AppColors.gold.opacity(0.2))

                subjectRow
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                Divider()
                    .background(AppColors.gold.opacity(0.1))

                editor

                characterCount

                completeButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    bodyFocused = false
                }
            }
        }
        .sensoryFeedback(.success, trigger: didCompleteDay)
        .sheet(isPresented: $showDayIndex) {
            ConsecrationDayIndexSheet(
                dayNumber: dayNumber,
                prayers: dayPrayers,
                current: .reflection,
                isComplete: isAlreadyComplete,
                onSelect: open
            )
        }
        .onAppear {
            text = viewModel.journalText

            // Straight to the body field, as the journal editor does —
            // but only when there is nothing written yet, so returning to
            // a completed day doesn't throw the keyboard over your own words.
            guard text.isEmpty else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                bodyFocused = true
            }
        }
    }

    // MARK: - Header

    private var editorHeader: some View {
        HStack {
            // The reflection stands in the day's place in the stack
            // rather than on top of its prayers, so this leaves the day
            // outright — the same act, and the same glyph, the day flow
            // carries. Walking back to a prayer or the reading is the
            // index's job, one tap away in the middle of this header.
            PrayerHeaderButton(icon: "ph-x", size: 16, label: "Leave the day") {
                // A second tap during the pop animation would call
                // removeLast() on an empty path and crash
                if !path.isEmpty { path.removeLast() }
            }

            Spacer()

            // The same struck capsule the day flow's header carries, so
            // the way into the day's index looks the same wherever you
            // are in the day.
            Button {
                showDayIndex = true
            } label: {
                HStack(spacing: 6) {
                    Text("REFLECTION")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.cream.opacity(0.9))

                    AppIcon("ph-caret-down", size: 9)
                        .foregroundColor(AppColors.gold)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .background(Capsule().fill(AppColors.background.opacity(0.55)))
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.35), lineWidth: 1))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(SacredCardButtonStyle())
            .accessibilityLabel("Reflection")
            .accessibilityHint("Opens the day's index")

            Spacer()

            // Balances the back button so the kicker stays centered
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Subject Row

    private var subjectRow: some View {
        HStack(spacing: 10) {
            AppIcon("ph-note-pencil", size: 13)
                .foregroundColor(AppColors.gold.opacity(0.8))

            VStack(alignment: .leading, spacing: 2) {
                Text(subjectLine)
                    .font(AppFonts.italicFont(16))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.leading)

                Text(contextLine)
                    .font(AppFonts.bodyFont(11))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer(minLength: 8)

            Text(formattedDate)
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Editor

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholderText)
                    .font(AppFonts.italicFont(18))
                    .foregroundColor(AppColors.textSecondary.opacity(0.5))
                    .lineSpacing(5)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(AppFonts.bodyFont(18))
                .foregroundColor(AppColors.cream)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 20)
                .focused($bodyFocused)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var characterCount: some View {
        HStack {
            Spacer()
            Text("\(text.count) characters")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary.opacity(0.4))
                .padding(.trailing, 24)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Day Index

    private var dayPrayers: [ConsecrationPrayer] {
        guard let phase else { return [] }
        return ConsecrationData.prayers(for: phase, language: settings.prayerLanguage)
    }

    /// Leaving the reflection for somewhere else in the day. Whatever
    /// has been written is saved on the way out — walking back to a
    /// prayer should never cost the user their words.
    private func open(_ destination: ConsecrationDayDestination) {
        guard destination != .reflection else { return }

        let step: ConsecrationDayStep = {
            if case .prayer(let index) = destination { return .prayer(index) }
            return .reading(0)
        }()

        viewModel.saveReflectionDraft(text, for: dayNumber)

        // Drop this reflection, then open the step in its place. The day
        // holds one place in the stack however you move around inside
        // it, so the stack never grows from using the index.
        if !path.isEmpty { path.removeLast() }

        if case .dayFlow(let existingDay, _) = path.last, existingDay == dayNumber {
            path[path.count - 1] = .dayFlow(dayNumber: dayNumber, step: step)
        } else {
            path.append(.dayFlow(dayNumber: dayNumber, step: step))
        }
    }

    // MARK: - Complete

    /// The day's finishing act, and the only filled gold shape in the
    /// day's flow. Unlike the journal editor's Save, it is never
    /// disabled: a day prayed without words written is still a day completed.
    private var completeButton: some View {
        GoldCTAButton(title: completeTitle, showsCross: !isAlreadyComplete) {
            viewModel.completeDay(dayNumber: dayNumber, journalEntry: text)
            didCompleteDay = true

            if isConsecrationDay {
                path.append(.completion)
            } else {
                // Back to the day, which now shows itself as complete
                path.removeAll()
            }
        }
    }

    private var completeTitle: String {
        if isConsecrationDay { return "Make my consecration" }
        return isAlreadyComplete ? "Save this reflection" : "Complete this day"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationJournalView(path: .constant([]), dayNumber: 1)
            .environment(ConsecrationViewModel())
            .environment(UserSettings.shared)
    }
}
