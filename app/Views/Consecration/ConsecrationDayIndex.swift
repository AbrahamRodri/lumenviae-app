//
//  ConsecrationDayIndex.swift
//  Lumen Viae
//
//  The day's index: every prayer by name, the reading, and the
//  reflection — reachable from any of them, and in the order the day
//  itself walks them.
//
//  The dashboard lets you enter a day anywhere, so the day itself has to
//  let you go anywhere once you're inside it. Without this the only way
//  from the reading back to the first prayer is four taps of PREV, and
//  the only way to the reflection is to walk to the end.
//
//  It hangs off the progress dots in each screen's header, which are the
//  natural thing to reach for when you want to know — or change — where
//  you are in the day.
//

import SwiftUI

// MARK: - ConsecrationDayDestination

/// Anywhere within a day that the index can send you.
enum ConsecrationDayDestination: Hashable {
    case prayer(Int)
    case reading
    case reflection
}

// MARK: - ConsecrationDayIndexSheet

struct ConsecrationDayIndexSheet: View {

    let dayNumber: Int
    let prayers: [ConsecrationPrayer]

    /// Where the calling screen currently is, so the index can say so
    let current: ConsecrationDayDestination

    /// Whether the day has is already complete — the reflection row says
    /// so rather than implying there is something still owed.
    let isComplete: Bool

    let onSelect: (ConsecrationDayDestination) -> Void

    @Environment(\.dismiss) private var dismiss

    private var day: ConsecrationDay? {
        ConsecrationData.day(dayNumber)
    }

    private var phase: ConsecrationPhase? {
        day?.phase
    }

    private var dayLabel: String {
        phase == .consecrationDay ? "CONSECRATION DAY" : "DAY \(dayNumber) OF 33"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 26)
                        .padding(.bottom, 18)

                    ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                        row(
                            title: prayer.title,
                            detail: prayer.latinTitle.flatMap {
                                $0.caseInsensitiveCompare(prayer.title) == .orderedSame ? nil : $0
                            },
                            icon: "ch-praying-hands",
                            destination: .prayer(index)
                        )
                    }

                    row(
                        title: "The reading",
                        detail: day?.title,
                        icon: "ph-book-open",
                        destination: .reading
                    )

                    row(
                        title: "The reflection",
                        detail: isComplete ? "Completed" : day?.journalPrompt,
                        icon: "ph-note-pencil",
                        destination: .reflection
                    )

                    Spacer(minLength: 30)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dayLabel)
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)

            Text(day?.title ?? "")
                .font(AppFonts.headlineFont(22))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Row

    private func row(
        title: String,
        detail: String?,
        icon: String,
        destination: ConsecrationDayDestination
    ) -> some View {
        let isCurrent = destination == current

        return Button {
            // Dismiss first: the caller's own navigation runs against a
            // stack this sheet is no longer sitting over.
            dismiss()
            onSelect(destination)
        } label: {
            HStack(spacing: 14) {
                AppIcon(icon, size: 15)
                    .foregroundColor(isCurrent ? AppColors.goldLight : AppColors.gold.opacity(0.55))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(isCurrent ? AppColors.goldLight : AppColors.cream)
                        .multilineTextAlignment(.leading)

                    if let detail, !detail.isEmpty {
                        Text(detail)
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                if isCurrent {
                    Text("HERE")
                        .font(AppFonts.labelFont(8))
                        .tracking(1.5)
                        .foregroundColor(AppColors.goldLight)
                } else {
                    AppIcon("ph-caret-right", size: 10)
                        .foregroundColor(AppColors.gold.opacity(0.4))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .frame(minHeight: 52)
            .background(
                isCurrent ? AppColors.gold.opacity(0.07) : Color.clear
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.1))
                    .frame(height: 0.5)
                    .padding(.horizontal, 24)
            }
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isCurrent ? "Currently here" : "")
    }
}

// MARK: - Day Index Button

/// The header control that opens the index: the day's label over its
/// progress dots, with a caret to say it does something.
struct ConsecrationDayIndexButton: View {

    let dayLabel: String
    let stepCount: Int
    let currentStep: Int

    /// Spoken instead of the dots, which carry no meaning to VoiceOver
    let accessibleValue: String

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                // A struck capsule rather than bare type: the label is
                // the way into the day's index, and a caret alone under
                // a line of grey tracking doesn't read as a control.
                HStack(spacing: 6) {
                    Text(dayLabel)
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

                HStack(spacing: 6) {
                    ForEach(0..<max(stepCount, 1), id: \.self) { index in
                        Capsule()
                            .fill(index <= currentStep ? AppColors.gold : AppColors.cardBackground)
                            .frame(width: index == currentStep ? 20 : 8, height: 4)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.7),
                                value: currentStep
                            )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(dayLabel)
        .accessibilityValue(accessibleValue)
        .accessibilityHint("Opens the day's index")
    }
}

// MARK: - Preview

#Preview {
    ConsecrationDayIndexSheet(
        dayNumber: 3,
        prayers: ConsecrationData.prayers(for: .preparatory, language: .latinUnderEnglish),
        current: .prayer(1),
        isComplete: false,
        onSelect: { _ in }
    )
}
